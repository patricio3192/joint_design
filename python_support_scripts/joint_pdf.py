#!/usr/bin/env python3
"""Lay out a sheet written by Octave (make_joint_pdfs.m, make_detail_pdf.m,
make_plan_sheets.m) as a PDF.

    python3 joint_pdf.py sheet.json sheet.pdf

Printing only: every number and every line of text comes from the JSON.

Document: {"title": ..., "blocks": [...],
           "page": "A4" (default) | "A2L" (A2 landscape),
           "fs": text size factor (default 1),
           "frame": {"fields": [[label, value], ...], "widths": [fractions],
                     "h": strip height mm, "sheets": [title of each sheet],
                     "subtitle": text under the sheet title}
               optional: border and a title block along the bottom of every
               page.  A value "@sheet" prints the sheet title (and the
               subtitle), "@page" prints "i / n"; newlines split lines.}
Blocks:
    {"k": "h1" | "h2" | "h3" | "p" | "note", "t": text}
    {"k": "page"}          {"k": "space", "h": mm}
    {"k": "table", "head": [...], "rows": [[...], ...], "w": [fractions],
     "right": [1-based columns], "red": [[row, col], ...] 1-based, body rows}
    {"k": "drawing", "h": height on paper in mm, "cap": bold title below,
     "note": text below the title, "items": [...]}   see drawing()
    {"k": "row", "w": [fractions], "cols": [[blocks], [blocks], ...]}
        blocks side by side
"""
import json
import math
import sys
from xml.sax.saxutils import escape

try:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A2, A4, landscape
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.units import mm
    from reportlab.platypus import (PageBreak, Paragraph, SimpleDocTemplate, Spacer,
                                    Table, TableStyle)
    from reportlab.graphics.shapes import Circle, Drawing, Group, Line, Polygon, String
    from reportlab.pdfbase.pdfmetrics import stringWidth
except ImportError:
    sys.exit("joint_pdf.py needs ReportLab. Install it with:\n"
             "    sudo apt install python3-reportlab")

BASE, BOLD = "Helvetica", "Helvetica-Bold"
GRID = colors.HexColor("#A0A0A0")
HEAD = colors.HexColor("#E6E6E6")
RED = colors.HexColor("#B00020")


def aslist(x):
    """Octave's jsonencode writes 1-element arrays as scalars."""
    if x is None:
        return []
    return x if isinstance(x, list) else [x]


def _c(h):
    return colors.HexColor(h)


# ---------------------------------------------------------------- styles
class Style:
    def __init__(self, fs):
        def P(n, f, s, l, **k):
            return ParagraphStyle(n, fontName=f, fontSize=s * fs, leading=l * fs, **k)
        self.fs = fs
        self.par = {
            "h1": P("h1", BOLD, 14, 18, spaceAfter=6),
            "h2": P("h2", BOLD, 11, 14, spaceBefore=10, spaceAfter=4),
            "h3": P("h3", BASE, 8.5, 11, spaceBefore=4, spaceAfter=1),
            "p": P("p", BASE, 8.5, 11, spaceAfter=3),
            "note": P("note", BASE, 7.5, 9.5, spaceBefore=2),
            "cap": P("cap", BOLD, 8.5, 11, spaceBefore=2),
            "capnote": P("capnote", BASE, 7.2, 9.2),
        }
        self.cell = P("cell", BASE, 7.5, 9)
        # drawing text: (font, size, colour)
        self.text = {"label": (BASE, 6.5 * fs, "#222222"), "small": (BASE, 5.5 * fs, "#555555"),
                     "title": (BOLD, 8.0 * fs, "#111111"), "code": (BOLD, 6.5 * fs, "#111111"),
                     "red": (BOLD, 6.0 * fs, "#D0021B"), "dim": (BASE, 6.0 * fs, "#333333"),
                     "grid": (BOLD, 8.0 * fs, "#333333"), "compass": (BASE, 5.0 * fs, "#808080"),
                     "big": (BOLD, 7.5 * fs, "#111111"), "vv": (BOLD, 5.5 * fs, "#6A1B9A")}


S = Style(1.0)

# drawing shapes: (stroke, width, fill, fill opacity, dash)
SHAPE = {
    "plate":  ("#1F5A96", 1.3, "#BFD7F0", 0.85, None),
    "plate2": ("#2E6B30", 1.3, "#C6E2C0", 0.85, None),
    "plate3": ("#8A4B9E", 1.3, "#E3CDEB", 0.85, None),
    "column": ("#333333", 1.0, "#BDBDBD", 1.0, None),
    "void":   ("#333333", 0.6, "#FFFFFF", 1.0, None),
    "white":  ("#FFFFFF", 0.1, "#FFFFFF", 1.0, None),
    "beam":   ("#7A5A2F", 0.8, "#F3E7D3", 1.0, None),
    "beamline": ("#5A4020", 1.5, None, 0, None),
    "hidden": ("#7A5A2F", 0.7, None, 0, (3, 2)),
    "weld":   ("#D0021B", 2.4, None, 0, None),
    "weldf":  ("#D0021B", 0.6, "#D0021B", 1.0, None),
    "weld5":  ("#E0141E", 2.4, None, 0, None),          # 5 mm fillets: red
    "weldf5": ("#E0141E", 0.6, "#E0141E", 1.0, None),
    "weld4":  ("#8E3B1F", 2.4, None, 0, None),          # 4 mm fillets: brownish red
    "weldf4": ("#8E3B1F", 0.6, "#8E3B1F", 1.0, None),
    "stab":   ("#2E6B30", 0.8, "#8CC084", 1.0, None),
    "tab":    ("#B06F00", 0.8, "#F5C66B", 1.0, None),
    "tabh":   ("#B06F00", 0.8, None, 0, (3, 2)),
    "angle":  ("#B06F00", 0.9, "#F5C66B", 1.0, None),
    "angleh": ("#B06F00", 0.9, None, 0, (3, 2)),
    "bolt":   ("#222222", 1.2, "#FFFFFF", 1.0, None),
    "center": ("#8C8C8C", 0.4, None, 0, (6, 2, 1, 2)),
    "axis":   ("#9A9A9A", 0.5, None, 0, (10, 3, 2, 3)),
    "bubble": ("#333333", 0.8, "#FFFFFF", 1.0, None),
    "edge":   ("#555555", 0.9, None, 0, (8, 3)),
    "grid":   ("#9E9E9E", 0.6, None, 0, None),
    "cut":    ("#555555", 0.6, None, 0, (2, 2)),
    "codeM":  ("#D0021B", 2.6, None, 0, None),
    "codeS":  ("#2E8B57", 2.6, None, 0, None),
    "codeNL": ("#E08A00", 2.6, None, 0, (4, 2)),
    "codeE":  ("#555555", 1.6, None, 0, (2, 2)),
    "vv":     ("#6A1B9A", 0.8, "#6A1B9A", 1.0, None),
    "vvcut":  ("#6A1B9A", 2.2, None, 0, None),
    "arrow":  ("#333333", 0.8, "#333333", 1.0, None),
    "compass": ("#9A9A9A", 0.5, None, 0, None),
}
DIMCOL = _c("#333333")


def P_(text, style):
    return Paragraph(escape(str(text)), style)


def table(b, width):
    right = {int(c) - 1 for c in aslist(b.get("right"))}
    red = aslist(b.get("red"))
    if red and not isinstance(red[0], list):     # a single [row, col]
        red = [red]
    red = {(int(r) - 1, int(c) - 1) for r, c in red}
    head = aslist(b["head"])
    rows = aslist(b["rows"])
    if rows and not isinstance(rows[0], list):   # a single row
        rows = [rows]

    def cell(v, bold=False, rt=False, rd=False):
        st = ParagraphStyle("c", parent=S.cell, fontName=BOLD if (bold or rd) else BASE,
                            alignment=2 if rt else 0, textColor=RED if rd else colors.black)
        return P_(v, st)

    data = [[cell(h, bold=True, rt=i in right) for i, h in enumerate(head)]]
    for r, row in enumerate(rows):
        data.append([cell(v, rt=i in right, rd=(r, i) in red) for i, v in enumerate(aslist(row))])
    t = Table(data, colWidths=[w * width for w in aslist(b["w"])], repeatRows=1)
    t.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.4, GRID),
        ("BACKGROUND", (0, 0), (-1, 0), HEAD),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 1.5 * S.fs),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 1.5 * S.fs),
        ("LEFTPADDING", (0, 0), (-1, -1), 3),
        ("RIGHTPADDING", (0, 0), (-1, -1), 3),
    ]))
    return t


# ---------------------------------------------------------------- drawings
# A drawing block holds shapes in model millimetres, y up:
#   {"t": "poly", "p": [x1, y1, x2, y2, ...], "s": style}       closed
#   {"t": "line", "p": [x1, y1, x2, y2], "s": style}
#   {"t": "circle", "p": [x, y, r], "s": style}
#   {"t": "text", "p": [x, y], "txt": text, "s": style, "a": "start"|"middle"|"end",
#    "r": rotation in degrees (optional)}
#   {"t": "dim", "p": [x1, y1, x2, y2], "o": offset, "txt": text,
#    "pos": "after"|"before"}   offset in mm, to the left of p1 -> p2
#   {"t": "weld", "p": [xt, yt, xe, ye], "dir": 1|-1, "side": "arrow"|"other"|"both",
#    "size": "5", "len": "80", "all": 0|1, "field": 0|1, "tail": text, "s": style}
#       AWS A2.4 fillet weld symbol: arrow to (xt, yt), reference line from
#       the elbow (xe, ye) to the right (dir 1) or left (-1); "all" draws
#       the weld-all-around circle, "field" the field-weld flag; the
#       triangle takes the colour of style s.  Drawn at a fixed size.
# Everything is scaled to fit the width and the height; text and line
# weights stay in points.
def _style(shape, s, closed=True):
    st, w, fill, op, dash = SHAPE.get(s, SHAPE["grid"])
    shape.strokeColor = _c(st)
    shape.strokeWidth = w
    if dash:
        shape.strokeDashArray = list(dash)
    if closed:
        shape.fillColor = _c(fill) if fill else None
        if fill:
            shape.fillOpacity = op
    return shape


def drawing(b, width):
    items = aslist(b["items"])
    xs, ys = [], []
    for it in items:
        p = aslist(it["p"])
        if it["t"] == "circle":
            xs += [p[0] - p[2], p[0] + p[2]]; ys += [p[1] - p[2], p[1] + p[2]]
        elif it["t"] == "dim":
            x1, y1, x2, y2 = p; o = it["o"]
            L = max(math.hypot(x2 - x1, y2 - y1), 1e-9)
            nx, ny = -(y2 - y1) / L, (x2 - x1) / L
            xs += [x1, x2, x1 + nx * o, x2 + nx * o]; ys += [y1, y2, y1 + ny * o, y2 + ny * o]
        else:
            xs += p[0::2]; ys += p[1::2]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    pad = 14 * S.fs
    Hp = float(b.get("h", 100)) * mm
    fit = lambda a, b_, c, e: min((width - 2 * pad) / max(b_ - a, 1e-9),
                                  (Hp - 2 * pad) / max(e - c, 1e-9))
    k = fit(x0, x1, y0, y1)
    # text keeps its size in points: grow the box until it holds the text too
    for _ in range(4):
        X0, X1, Y0, Y1 = x0, x1, y0, y1
        for it in items:
            if it["t"] == "weld":
                q = aslist(it["p"])
                ext = (_WREF + 12 + stringWidth(it.get("tail", ""), BASE, 6 * S.fs)) * S.fs / k
                xa, xb = sorted([q[2], q[2] + it.get("dir", 1) * ext])
                X0, X1 = min(X0, xa, q[0]), max(X1, xb, q[0])
                Y0, Y1 = min(Y0, q[3] - 12 * S.fs / k, q[1]), max(Y1, q[3] + 14 * S.fs / k, q[1])
                continue
            if it["t"] != "text" or it.get("r"):
                continue
            px, py = aslist(it["p"])[:2]
            font, size, _col = S.text.get(it.get("s", "label"), S.text["label"])
            lines = it["txt"].split("\n")
            w = max(stringWidth(t_, font, size) for t_ in lines) / k
            a = it.get("a", "start")
            lo = px - (w if a == "end" else w / 2 if a == "middle" else 0)
            X0, X1 = min(X0, lo), max(X1, lo + w)
            Y0 = min(Y0, py - (0.3 + 1.25 * (len(lines) - 1)) * size / k)
            Y1 = max(Y1, py + size / k)
        k = fit(X0, X1, Y0, Y1)
    x0, x1, y0, y1 = X0, X1, Y0, Y1
    W, H = (x1 - x0) * k + 2 * pad, (y1 - y0) * k + 2 * pad
    ox = (width - W) / 2
    X = lambda x: ox + pad + (x - x0) * k
    Y = lambda y: pad + (y - y0) * k
    d = Drawing(width, H)
    texts = []
    for it in items:
        t, p, s = it["t"], aslist(it["p"]), it.get("s", "grid")
        if t == "poly":
            pts = []
            for i in range(0, len(p), 2):
                pts += [X(p[i]), Y(p[i + 1])]
            d.add(_style(Polygon(pts), s))
        elif t == "line":
            d.add(_style(Line(X(p[0]), Y(p[1]), X(p[2]), Y(p[3])), s, closed=False))
        elif t == "circle":
            d.add(_style(Circle(X(p[0]), Y(p[1]), max(p[2] * k, 0.8)), s))
        elif t == "text":
            texts.append((X(p[0]), Y(p[1]), it["txt"], s, it.get("a", "start"), it.get("r", 0)))
        elif t == "dim":
            _dim(d, X, Y, p, it["o"] * k, it["txt"], it.get("pos", "after"))
        elif t == "weld":
            _weld(d, X(p[0]), Y(p[1]), X(p[2]), Y(p[3]), it)
    for x, y, txt, s, a, r in texts:              # text on top of everything
        font, size, col = S.text.get(s, S.text["label"])
        # several lines, separated by newlines, spaced in points
        g = Group(*[String(0, -i * 1.25 * size, t_, fontName=font, fontSize=size,
                           fillColor=_c(col), textAnchor=a)
                    for i, t_ in enumerate(txt.split("\n"))])
        ra = math.radians(r or 0)
        g.transform = (math.cos(ra), math.sin(ra), -math.sin(ra), math.cos(ra), x, y)
        d.add(g)
    out = [d]
    if b.get("cap"):
        out.append(P_(b["cap"], S.par["cap"]))
    if b.get("note"):
        out.append(P_(b["note"], S.par["capnote"]))
    return out


_WREF = 44          # reference line length, points (times the text factor)


def _weld(d, xt, yt, xe, ye, it):
    """AWS A2.4 fillet weld symbol, in points."""
    f = S.fs
    blk = _c("#222222")
    dr = 1 if it.get("dir", 1) >= 0 else -1
    Lr = _WREF * f
    xr = xe + dr * Lr
    # arrow line and arrowhead at the joint
    d.add(Line(xe, ye, xt, yt, strokeColor=blk, strokeWidth=0.6))
    L = max(math.hypot(xt - xe, yt - ye), 1e-6)
    ux, uy = (xt - xe) / L, (yt - ye) / L
    al, aw = 5.5 * f, 1.8 * f
    d.add(Polygon([xt, yt, xt - ux * al - uy * aw, yt - uy * al + ux * aw,
                   xt - ux * al + uy * aw, yt - uy * al - ux * aw],
                  fillColor=blk, strokeColor=blk, strokeWidth=0.3))
    # reference line
    d.add(Line(xe, ye, xr, ye, strokeColor=blk, strokeWidth=0.8))
    # fillet triangle(s): perpendicular leg always on the left
    h = 6 * f
    xs = xe + 13 * f if dr > 0 else xe - 13 * f - h
    fill = _c(SHAPE.get(it.get("s", "weld"), SHAPE["weld"])[0])
    font, size, col = BASE, 6 * f, "#222222"
    sides = {"arrow": [-1], "other": [1], "both": [-1, 1]}.get(it.get("side", "arrow"), [-1])
    for sg in sides:
        d.add(Polygon([xs, ye, xs, ye + sg * h, xs + h, ye], fillColor=fill,
                      strokeColor=blk, strokeWidth=0.5))
        ty = ye + (sg * h * 0.55 if sg > 0 else -h * 0.85)
        if it.get("size"):
            d.add(String(xs - 1.5 * f, ty, str(it["size"]), fontName=font, fontSize=size,
                         fillColor=_c(col), textAnchor="end"))
        if it.get("len"):
            d.add(String(xs + h + 1.5 * f, ty, str(it["len"]), fontName=font, fontSize=size,
                         fillColor=_c(col), textAnchor="start"))
    if it.get("all"):
        d.add(Circle(xe, ye, 2.8 * f, fillColor=None, strokeColor=blk, strokeWidth=0.6))
    if it.get("field"):
        top = ye + 10 * f
        d.add(Line(xe, ye, xe, top, strokeColor=blk, strokeWidth=0.6))
        d.add(Polygon([xe, top, xe + dr * 6 * f, top - 2 * f, xe, top - 4 * f],
                      fillColor=blk, strokeColor=blk, strokeWidth=0.3))
    if it.get("tail"):
        tw = 4 * f
        d.add(Line(xr, ye, xr + dr * tw, ye + tw, strokeColor=blk, strokeWidth=0.6))
        d.add(Line(xr, ye, xr + dr * tw, ye - tw, strokeColor=blk, strokeWidth=0.6))
        d.add(String(xr + dr * (tw + 1.5 * f), ye - size * 0.35, it["tail"], fontName=font,
                     fontSize=size, fillColor=_c(col), textAnchor="start" if dr > 0 else "end"))


def _dim(d, X, Y, p, off, txt, pos):
    x1, y1, x2, y2 = X(p[0]), Y(p[1]), X(p[2]), Y(p[3])
    L = math.hypot(x2 - x1, y2 - y1)
    if L < 1e-6:
        return
    ux, uy = (x2 - x1) / L, (y2 - y1) / L
    nx, ny = -uy, ux
    sg = 1 if off >= 0 else -1
    a1 = (x1 + nx * off, y1 + ny * off)
    a2 = (x2 + nx * off, y2 + ny * off)
    for (bx, by), (ax, ay) in (((x1, y1), a1), ((x2, y2), a2)):
        d.add(Line(bx + nx * sg * 1.5, by + ny * sg * 1.5, ax + nx * sg * 2.5, ay + ny * sg * 2.5,
                   strokeColor=DIMCOL, strokeWidth=0.35))
    d.add(Line(a1[0], a1[1], a2[0], a2[1], strokeColor=DIMCOL, strokeWidth=0.45))
    for ax, ay in (a1, a2):                       # architectural ticks
        tx, ty = (ux + nx) * 2.2, (uy + ny) * 2.2
        d.add(Line(ax - tx, ay - ty, ax + tx, ay + ty, strokeColor=DIMCOL, strokeWidth=0.9))
    ang = math.degrees(math.atan2(uy, ux))
    if ang > 90.001 or ang < -89.999:
        ang += 180
    font, size, col = S.text["dim"]
    mx, my = (a1[0] + a2[0]) / 2, (a1[1] + a2[1]) / 2
    tw = stringWidth(txt, font, size)
    if tw + 4 > L:                                # no room between ticks: put it beside
        if pos == "before":
            mx, my = a1[0] - ux * (tw / 2 + 5), a1[1] - uy * (tw / 2 + 5)
        else:
            mx, my = a2[0] + ux * (tw / 2 + 5), a2[1] + uy * (tw / 2 + 5)
    ra = math.radians(ang)
    g = Group(String(0, 1.5, txt, fontName=font, fontSize=size, fillColor=_c(col),
                     textAnchor="middle"))
    g.transform = (math.cos(ra), math.sin(ra), -math.sin(ra), math.cos(ra), mx, my)
    d.add(g)


# ---------------------------------------------------------------- blocks
def flow(blocks, width):
    story = []
    for b in aslist(blocks):
        k = b["k"]
        if k == "page":
            story.append(PageBreak())
        elif k == "table":
            story.append(table(b, width))
        elif k == "drawing":
            story += drawing(b, width)
        elif k == "row":
            ws = [w * width for w in aslist(b["w"])]
            cols = aslist(b["cols"])
            cells = [flow(c, w - 8) for c, w in zip(cols, ws)]
            t = Table([cells], colWidths=ws)
            t.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"),
                                   ("LEFTPADDING", (0, 0), (-1, -1), 4),
                                   ("RIGHTPADDING", (0, 0), (-1, -1), 4)]))
            story.append(t)
        elif k == "space":
            story.append(Spacer(1, float(b.get("h", 5)) * mm))
        else:
            story.append(P_(b["t"], S.par[k]))
    return story


def _wrap(text, font, size, width):
    """Split text into lines that fit the width (points)."""
    out, cur = [], ""
    for word in str(text).split():
        t = (cur + " " + word).strip()
        if stringWidth(t, font, size) <= width or not cur:
            cur = t
        else:
            out.append(cur)
            cur = word
    if cur:
        out.append(cur)
    return out


def main(src, dst):
    global S
    with open(src) as f:
        doc = json.load(f)
    S = Style(float(doc.get("fs", 1.0)))
    size = landscape(A2) if doc.get("page") == "A2L" else A4
    frame = doc.get("frame")
    hb = float(frame.get("h", 20)) * mm if frame else 0
    m = 18 * mm if not frame else 16 * mm
    bottom = 16 * mm if not frame else 8 * mm + hb + 8 * mm
    pdf = SimpleDocTemplate(dst, pagesize=size, leftMargin=m, rightMargin=m, topMargin=15 * mm,
                            bottomMargin=bottom, title=doc["title"])
    width = size[0] - 2 * m

    def page(canvas, d):
        canvas.saveState()
        if frame:
            sheets = aslist(frame.get("sheets"))
            n, i = len(sheets), d.page
            blk = _c("#222222")
            canvas.setStrokeColor(blk)
            canvas.setLineWidth(1.2)
            canvas.rect(8 * mm, 8 * mm, size[0] - 16 * mm, size[1] - 16 * mm)
            x0, y0, w = 8 * mm, 8 * mm, size[0] - 16 * mm
            canvas.setLineWidth(0.8)
            canvas.line(x0, y0 + hb, x0 + w, y0 + hb)
            fields = aslist(frame.get("fields"))
            ws = aslist(frame.get("widths")) or [1 / len(fields)] * len(fields)
            x = x0
            for (label, value), f in zip(fields, ws):
                cw = f * w
                if x > x0:
                    canvas.line(x, y0, x, y0 + hb)
                pad = 3 * mm
                canvas.setFillColor(_c("#555555"))
                canvas.setFont(BOLD, 6.5)
                canvas.drawString(x + pad, y0 + hb - 5 * mm, label)
                canvas.setFillColor(_c("#111111"))
                if value == "@page":
                    canvas.setFont(BOLD, 18)
                    canvas.drawCentredString(x + cw / 2, y0 + hb / 2 - 5 * mm, f"{i} / {n}")
                elif value == "@sheet":
                    canvas.setFont(BOLD, 11)
                    canvas.drawString(x + pad, y0 + hb - 11 * mm, sheets[i - 1] if i <= n else "")
                    lines = _wrap(frame.get("subtitle", ""), BASE, 7, cw - 2 * pad)
                    canvas.setFont(BASE, 7)
                    for j, ln in enumerate(lines):
                        canvas.drawString(x + pad, y0 + hb - 16 * mm - j * 3.2 * mm, ln)
                else:
                    lines = []
                    for part in str(value).split("\n"):
                        lines += _wrap(part, BASE, 8.5, cw - 2 * pad)
                    canvas.setFont(BASE, 8.5)
                    for j, ln in enumerate(lines):
                        canvas.drawString(x + pad, y0 + hb - 10.5 * mm - j * 3.8 * mm, ln)
                x += cw
        else:
            canvas.setFont(BASE, 7)
            canvas.setFillColor(_c("#606060"))
            canvas.drawString(m, 10 * mm, d.title)
            canvas.drawRightString(size[0] - m, 10 * mm, f"page {d.page}")
        canvas.restoreState()

    pdf.build(flow(doc["blocks"], width), onFirstPage=page, onLaterPages=page)
    print(f"  {dst}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
