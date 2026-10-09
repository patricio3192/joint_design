#!/usr/bin/env python3
"""A sheet JSON (the one joint_pdf.py / pour_pdf.py print) -> editable DXF files.

    python3 json_dxf.py sheet.json [--printer pour_pdf.py] [--out folder] [--overwrite]

Writes to <out> (default: <sheet>_dxf next to the JSON):
    detalles/NN_name.dxf   one file per drawing, 1:1 in real mm   ("model space")
    papel_N.dxf            border, title block, headings, notes and tables of sheet N,
                           in paper mm                              ("paper space")
    lamina.json            which detail goes where, at what scale
and then runs armar_lamina.py, which assembles lamina_librecad.dxf and lamina_autocad.dxf.

Edit the detail and paper files, then run armar_lamina.py again; json_dxf.py is only for a
fresh start from Octave (it will not overwrite <out> without --overwrite, so hand edits
are not lost).

The layout is the PDF's: the printer is run with its canvas watched, and every drawing,
line and piece of text is taken where the PDF puts it.  Each drawing gets the nearest
standard scale at or below the PDF's (1:10, 1:20, 1:25, 1:50...).  Dimensions are real
DXF dimensions ("<>" = measured value).  Fills with opacity are blended with white.
"""
import argparse
import importlib.util
import json
import math
import os
import re
import shutil
import sys
import tempfile
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import dxf_common as C  # noqa: E402
import joint_pdf as J  # noqa: E402
from ezdxf.enums import TextEntityAlignment  # noqa: E402
from reportlab.graphics.shapes import Circle, Drawing, Line, Polygon, String  # noqa: E402
from reportlab.pdfbase.pdfmetrics import stringWidth  # noqa: E402
from reportlab.pdfgen.canvas import Canvas  # noqa: E402
from reportlab.pdfgen.textobject import PDFTextObject  # noqa: E402

PT = C.PT
SCALES = [1, 2, 2.5, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100, 125, 150, 200, 250, 300, 400,
          500, 750, 1000, 1250, 1500, 2000, 2500, 5000, 10000]
ALIGN = {"start": TextEntityAlignment.LEFT, "middle": TextEntityAlignment.CENTER,
         "end": TextEntityAlignment.RIGHT}


def _hex(c):
    if c is None or isinstance(c, str):
        return c
    return "#" + c.hexval()[2:]


# ---------------------------------------------------------------- watching the printer
class Watch:
    """Everything the printer puts on each page, in absolute points."""

    def __init__(self):
        self.pages, self.size, self.inside = {}, None, 0

    def page(self, canv):
        self.size = canv._pagesize
        return self.pages.setdefault(canv.getPageNumber(),
                                     {"lines": [], "fills": [], "texts": [], "drawings": []})

    def install(self):
        W = self
        o_line, o_rect = Canvas.line, Canvas.rect
        o_tout, o_tfill = PDFTextObject._textOut, PDFTextObject.setFillColor
        o_textout, o_textline = PDFTextObject.textOut, PDFTextObject.textLine
        o_draw, o_jdraw = Drawing.draw, J.drawing

        def line(canv, x1, y1, x2, y2):
            if not W.inside:
                W.page(canv)["lines"].append((canv.absolutePosition(x1, y1), canv.absolutePosition(x2, y2),
                                              _hex(canv._strokeColorObj), canv._lineWidth))
            return o_line(canv, x1, y1, x2, y2)

        def rect(canv, x, y, w, h, stroke=1, fill=0, **k):
            if not W.inside:
                pts = [canv.absolutePosition(*p) for p in ((x, y), (x + w, y), (x + w, y + h), (x, y + h))]
                pg = W.page(canv)
                if fill:
                    pg["fills"].append((pts, _hex(canv._fillColorObj)))
                if stroke:
                    for i in range(4):
                        pg["lines"].append((pts[i], pts[(i + 1) % 4], _hex(canv._strokeColorObj),
                                            canv._lineWidth))
            return o_rect(canv, x, y, w, h, stroke=stroke, fill=fill, **k)

        def tfill(tx, color, alpha=None):
            tx._wfill = color
            return o_tfill(tx, color, alpha)

        def keep(tx, text):
            if not W.inside and str(text).strip():
                canv = tx._canvas
                x, y = canv.absolutePosition(tx._x, tx._y)
                col = getattr(tx, "_wfill", None) or canv._fillColorObj
                W.page(canv)["texts"].append([x, y, str(text), tx._fontname, tx._fontsize, _hex(col)])

        def tout(tx, text, TStar=0):
            keep(tx, text)
            o_tout(tx, text, TStar)
            # reportlab does not move its cursor here: follow the text, and T* (next line)
            if TStar:
                tx._y0 += -tx._leading if tx._canvas.bottomup else tx._leading
                tx._x, tx._y = tx._x0, tx._y0
            else:
                tx._x += stringWidth(str(text), tx._fontname, tx._fontsize)

        def textout(tx, text):
            keep(tx, text)
            return o_textout(tx, text)

        def textline(tx, text=""):
            keep(tx, text)
            return o_textline(tx, text)

        def draw(d, *a, **k):
            if getattr(d, "_blk", None) is not None:
                ax, ay = d.canv.absolutePosition(0, 0)
                W.page(d.canv)["drawings"].append((d._blk, ax, ay, d._map))
            W.inside += 1
            try:
                return o_draw(d, *a, **k)
            finally:
                W.inside -= 1

        def jdrawing(b, width):
            out = o_jdraw(b, width)
            out[0]._blk = b
            return out

        Canvas.line, Canvas.rect = line, rect
        PDFTextObject._textOut, PDFTextObject.setFillColor = tout, tfill
        PDFTextObject.textOut, PDFTextObject.textLine = textout, textline
        Drawing.draw, J.drawing = draw, jdrawing


def run_printer(src, printer):
    """Run the printer on src (PDF to a temporary file) and return the module and what it drew."""
    if os.path.abspath(printer) == os.path.abspath(J.__file__):
        mod = J
    else:
        spec = importlib.util.spec_from_file_location("sheet_printer", printer)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
    w = Watch()
    w.install()
    with tempfile.TemporaryDirectory() as tmp:
        mod.main(src, os.path.join(tmp, "sheet.pdf"))
    return mod, w


# ---------------------------------------------------------------- detail files (model space)
def pick_scale(k):
    """Points per model mm in the PDF -> the next standard scale at or below it (1:N)."""
    D = 1 / (k * PT)
    return next((s for s in SCALES if s >= D * 0.999), math.ceil(D))


def slug(text, n):
    t = re.sub(r"\*\*", "", text or "dibujo")
    t = unicodedata.normalize("NFKD", t).encode("ascii", "ignore").decode()
    t = re.sub(r"[^a-z0-9]+", "-", t.lower()).strip("-")[:48].strip("-")
    return f"{n:02d}_{t or 'dibujo'}"


def _text(lay, txt, x, y, size_mm, font, col, align="start", rot=0, layer="TEXTO"):
    """One TEXT per line; size_mm is the font size (lines 1.25 apart, as the PDF)."""
    style = C.FONT["bold" if "Bold" in font else "normal"][0]
    ra = math.radians(rot or 0)
    for i, ln in enumerate(str(txt).split("\n")):
        if not ln.strip():
            continue
        dy = -i * 1.25 * size_mm
        p = (x - dy * math.sin(ra), y + dy * math.cos(ra))
        t = lay.add_text(ln, height=size_mm * C.CAP, rotation=rot or 0,
                         dxfattribs=dict(C.color_attribs(C.rgb(col or "#222222")), layer=layer, style=style,
                                         width=C.WIDTH))
        t.set_placement(p, align=ALIGN.get(align, TextEntityAlignment.LEFT))


def _hatch(lay, layer, col, path=None, circle=None):
    h = lay.add_hatch(dxfattribs=dict(C.color_attribs(col), layer=layer))
    if circle:
        h.paths.add_edge_path().add_arc(circle[:2], circle[2], 0, 360)
    else:
        h.paths.add_polyline_path(path, is_closed=True)
    return h


def _dim_text(txt, p):
    """'<>' wherever the text shows the measured length, so the value stays live."""
    L = math.hypot(p[2] - p[0], p[3] - p[1])
    num = f"{L:.0f}"
    if abs(L - round(L)) < 0.05 and re.search(rf"(?<![\d.]){num}(?![\d.])", txt):
        return re.sub(rf"(?<![\d.]){num}(?![\d.])", "<>", txt, count=1)
    return txt


def detail_doc(b, N, mod):
    """One drawing block at 1:1, drawn for 1:N."""
    S, SHAPE = J.S, J.SHAPE
    sop = getattr(mod, "STROKE_OP", {})
    doc = C.new_doc()
    C.header_scale(doc, N)
    ds = C.dimstyle(doc, N)
    msp = doc.modelspace()
    kk = 1 / (N * PT)                        # points per model mm at 1:N

    def shape_layer(s):
        st, w, fill, op, dash = SHAPE.get(s, SHAPE["grid"])
        return C.layer(doc, f"G-{s}", st or fill or "#222222", w, dash, sop.get(s, 1.0)), st, fill, op

    for it in J.aslist(b["items"]):
        t, p, s = it["t"], J.aslist(it["p"]), it.get("s", "grid")
        if t == "poly":
            lay, st, fill, op = shape_layer(s)
            pts = [(p[i], p[i + 1]) for i in range(0, len(p) - 1, 2)]
            if fill:
                _hatch(msp, lay, C.rgb(fill, op), path=pts)
            if st:
                msp.add_lwpolyline(pts, close=True, dxfattribs={"layer": lay})
        elif t == "line":
            lay = shape_layer(s)[0]
            msp.add_line(p[0:2], p[2:4], dxfattribs={"layer": lay})
        elif t == "circle":
            lay, st, fill, op = shape_layer(s)
            if fill:
                _hatch(msp, lay, C.rgb(fill, op), circle=p)
            if st:
                msp.add_circle(p[0:2], p[2], dxfattribs={"layer": lay})
        elif t == "text":
            font, size, col = S.text.get(s, S.text["label"])
            _text(msp, it["txt"], p[0], p[1], size * PT * N, font, col, it.get("a", "start"),
                  it.get("r", 0), C.layer(doc, f"T-{s}", col))
        elif t == "dim":
            lay = C.layer(doc, "COTAS", "#333333", 0.45)
            dim = msp.add_aligned_dim(p1=p[0:2], p2=p[2:4], distance=it["o"], dimstyle=ds,
                                      text=_dim_text(it["txt"], p), dxfattribs={"layer": lay})
            dim.render()
        elif t == "weld":
            _weld(doc, msp, it, p, kk)
    return doc


class _Bag:
    def __init__(self):
        self.shapes = []

    def add(self, s):
        self.shapes.append(s)


def _weld(doc, msp, it, p, kk):
    """The PDF's AWS weld symbol, drawn by joint_pdf._weld in points and brought back to model mm."""
    bag = _Bag()
    J._weld(bag, p[0] * kk, p[1] * kk, p[2] * kk, p[3] * kk, it)
    lay = C.layer(doc, "SOLDADURA", "#222222", 0.6)
    for sh in bag.shapes:
        if isinstance(sh, Line):
            e = msp.add_line((sh.x1 / kk, sh.y1 / kk), (sh.x2 / kk, sh.y2 / kk), dxfattribs={"layer": lay})
            e.rgb = C.rgb(_hex(sh.strokeColor) or "#222222")
        elif isinstance(sh, Polygon):
            pts = [(sh.points[i] / kk, sh.points[i + 1] / kk) for i in range(0, len(sh.points), 2)]
            if sh.fillColor is not None:
                _hatch(msp, lay, C.rgb(_hex(sh.fillColor)), path=pts)
            msp.add_lwpolyline(pts, close=True, dxfattribs={"layer": lay})
        elif isinstance(sh, Circle):
            msp.add_circle((sh.cx / kk, sh.cy / kk), sh.r / kk, dxfattribs={"layer": lay})
        elif isinstance(sh, String):
            _text(msp, sh.text, sh.x / kk, sh.y / kk, sh.fontSize / kk, sh.fontName,
                  _hex(sh.fillColor), sh.textAnchor, 0, lay)


# ---------------------------------------------------------------- paper files
def _merge(texts):
    """Runs of one paragraph line, same font and colour, one after the other -> one text."""
    out = []
    for x, y, s, font, size, col in texts:
        if out:
            q = out[-1]
            if (abs(q[1] - y) < 0.01 and q[3] == font and q[4] == size and q[5] == col
                    and abs(q[0] + stringWidth(q[2], q[3], q[4]) - x) < 0.6):
                q[2] += s
                continue
        out.append([x, y, s, font, size, col])
    return out


def paper_doc(pg):
    doc = C.new_doc()
    C.header_scale(doc, 1)
    msp = doc.modelspace()
    lf = C.layer(doc, "LAMINA_FONDO", "#E6E6E6", 0.1)
    for pts, col in pg["fills"]:
        if col and col.lower() not in ("#ffffff",):
            _hatch(msp, lf, C.rgb(col), path=[(x * PT, y * PT) for x, y in pts])
    for (a, b, col, w) in pg["lines"]:
        lay = C.layer(doc, "LAMINA_MARCO" if w >= 0.8 else "LAMINA_TABLAS", "#222222", w)
        e = msp.add_line((a[0] * PT, a[1] * PT), (b[0] * PT, b[1] * PT), dxfattribs={"layer": lay})
        if w not in (0.8, 1.2):
            e.dxf.lineweight = C.lineweight(w)
    lt = C.layer(doc, "LAMINA_TEXTO", "#111111", 0.25)
    for x, y, s, font, size, col in _merge(pg["texts"]):
        _text(msp, s.rstrip(), x * PT, y * PT, size * PT, font, col, layer=lt)
    return doc


# ---------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("sheet")
    ap.add_argument("--printer", default=os.path.join(HERE, "joint_pdf.py"),
                    help="the printer that makes the PDF of this JSON (default joint_pdf.py)")
    ap.add_argument("--out", help="output folder (default <sheet>_dxf next to the JSON)")
    ap.add_argument("--overwrite", action="store_true", help="replace an existing output folder")
    a = ap.parse_args()

    out = a.out or os.path.splitext(os.path.abspath(a.sheet))[0] + "_dxf"
    if os.path.exists(out):
        if not a.overwrite:
            sys.exit(f"{out} already exists and may hold hand edits. Use --overwrite to replace it, "
                     "or run armar_lamina.py to reassemble the sheets from it.")
        shutil.rmtree(out)
    os.makedirs(os.path.join(out, "detalles"))

    mod, w = run_printer(a.sheet, a.printer)
    with open(a.sheet) as f:
        title = json.load(f).get("title", "")
    lam = {"titulo": title, "hojas": []}
    n = 0
    for pnum in sorted(w.pages):
        pg = w.pages[pnum]
        paper = f"papel_{pnum}.dxf"
        paper_doc(pg).saveas(os.path.join(out, paper))
        dets = []
        for b, ax, ay, (x0, y0, x1, y1, k, ox, pad) in pg["drawings"]:
            n += 1
            N = pick_scale(k)
            name = os.path.join("detalles", slug(b.get("cap"), n) + ".dxf")
            detail_doc(b, N, mod).saveas(os.path.join(out, name))
            Wp, Hp = (x1 - x0) * k + 2 * pad, (y1 - y0) * k + 2 * pad
            dets.append({"archivo": name.replace(os.sep, "/"), "escala": N,
                         "base": [round((x0 + x1) / 2, 3), round((y0 + y1) / 2, 3)],
                         "en": [round((ax + ox + Wp / 2) * PT, 3), round((ay + Hp / 2) * PT, 3)],
                         "ventana": [round(Wp * PT, 2), round(Hp * PT, 2)]})
            print(f"  {name}  1:{N:g}")
        lam["hojas"].append({"tamano": [round(w.size[0] * PT, 1), round(w.size[1] * PT, 1)],
                             "papel": paper, "detalles": dets})
    spec = os.path.join(out, "lamina.json")
    with open(spec, "w", encoding="utf-8") as f:
        json.dump(lam, f, indent=1, ensure_ascii=False)
    print(f"  {spec}")

    import armar_lamina
    armar_lamina.build(spec, "ambos")


if __name__ == "__main__":
    main()
