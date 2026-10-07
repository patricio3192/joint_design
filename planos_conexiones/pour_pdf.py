"""pour_pdf.py  Printer of the pre-pour placement sheets.

Runs ../python_support_scripts/joint_pdf.py unchanged, with extra drawing styles in the
colours of the report (ca_draw.m) and stroke opacity, so that what is already in place
(column and beam bars, joint ties, rods) can be drawn faint.

    python3 pour_pdf.py sheets.json sheets.pdf
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "python_support_scripts"))
import joint_pdf as J  # noqa: E402

# (stroke, width, fill, fill opacity, dash), as in joint_pdf.SHAPE
J.SHAPE.update({
    # concrete
    "r_conc":  ("#6b6b6b", 0.8, "#ece9e2", 0.55, None),
    "r_concb": ("#8a8a8a", 0.6, "#ece9e2", 0.30, (6, 3)),
    "r_old":   ("#6b6b6b", 0.8, "#cfc9bb", 0.55, None),
    # what is placed for the cantilevers
    "r_anc":   ("#7b241c", 0.5, "#c0392b", 1.00, None),
    "r_ancg":  ("#c0392b", 0.6, "#c0392b", 0.18, (3, 2)),
    "r_nut":   ("#3d0f0b", 0.5, "#7b241c", 1.00, None),
    "r_bp":    ("#142433", 0.6, "#34506b", 1.00, None),
    "r_new":   ("#145a32", 0.5, "#1e8449", 0.90, None),
    "r_hkA":   ("#6b4a00", 0.6, "#9a6b00", 0.95, None),
    "r_hkB":   ("#6b4a00", 0.6, "#e0b04a", 0.95, None),
    # pieces of one hook in the 3D view: fill without outline, and the outline alone
    "r_hkAf":  (None, 0, "#9a6b00", 0.95, None),
    "r_hkAe":  ("#6b4a00", 0.6, None, 0, None),
    "r_hkBf":  (None, 0, "#e0b04a", 0.95, None),
    "r_hkBe":  ("#6b4a00", 0.6, None, 0, None),
    # already in place: faint
    "r_col":   ("#9a6b00", 0.4, "#9a6b00", 0.22, None),
    "r_ex":    ("#5d6d7e", 0.4, "#5d6d7e", 0.22, None),
    "r_tie":   ("#7d3c98", 0.4, "#7d3c98", 0.25, None),
    "r_tieS":  ("#4a235a", 0.5, "#7d3c98", 0.85, None),
    "r_rod":   ("#117a65", 0.4, "#117a65", 0.25, None),
    "r_steel": ("#1f3347", 0.6, "#a9bdd1", 0.25, (5, 3)),
    # beam bars in the joint (solid): beam in line, the pair under its corner bars, crossing beam
    "r_bm1":   ("#0e2f44", 0.5, "#1a5276", 1.00, None),
    "r_bm2":   ("#1b4f72", 0.5, "#5dade2", 1.00, None),
    "r_bm3":   ("#1c2833", 0.5, "#616a6b", 1.00, None),
    "r_bm4":   ("#0b5345", 0.5, "#48c9b0", 1.00, None),   # bottom bars of the beam in line
    "r_bas":   ("#7e3a06", 0.5, "#e67e22", 1.00, None),   # bastones: 2 extra top bars
    "r_colS":  ("#6b4a00", 0.5, "#c9a227", 0.85, None),   # column bars, solid (complete sections)
    "r_rodS":  ("#0b5345", 0.5, "#45b39d", 0.85, None),   # rods of the steel column, solid
    "r_oval":   ("#e8603c", 1.1, None, 0, (5, 3)),       # dashed tomato oval around a beam with bastones
    "r_oval_l": ("#e8603c", 0.6, None, 0, None),           # its leader
    "r_tubei": ("#555555", 0.4, "#f4f4f4", 1.00, None),     # inside of the sleeve
    "r_tube":  ("#555555", 0.5, "#ffffff", 0.90, None),     # sleeve (PVC tube) for the A2 rods
    "ipe160":  ("#3c7a3c", 0.6, "#a9dfa3", 0.95, None),    # IPE 160 edge beams in the location plan
    "lead":    ("#222222", 1.0, None, 0, None),             # leader of a note that must be seen
    "leadt":   ("#333333", 0.5, None, 0, None),             # thin leader of the labels beside a drawing
    "leadf":   ("#222222", 0.3, "#222222", 1.00, None),     # its arrowhead
    "dimk":    ("#222222", 0.6, None, 0, None),             # braces of the bar counts
    # end plate of the IPE 240 and its grout pad: placed after the pour, shown for reference
    "r_eplate": ("#1f3347", 0.6, "#a9bdd1", 0.30, None),
    "r_ipe":    ("#1f3347", 0.5, "#c9d6e3", 0.45, None),
    "r_ipef":   ("#1f3347", 0.6, "#7f9bb8", 0.70, None),
    "r_grout":  ("#6b6b6b", 0.5, "#b9b2a0", 0.30, None),
    # cracks: inside the concrete (dashed)
    "r_crkh":  ("#e3141e", 1.6, None, 0, (4, 3)),
    # the four pieces of one level of joint ties
    "r_t1":    ("#4a235a", 0.5, "#8e44ad", 0.90, None),
    "r_t2":    ("#1b4f72", 0.5, "#2e86c1", 0.90, None),
    "r_t3":    ("#7e5109", 0.5, "#e67e22", 0.90, None),
    "r_t4":    ("#0b5345", 0.5, "#17a589", 0.90, None),
})
# stroke opacity of the faint styles (joint_pdf sets the fill opacity only)
STROKE_OP = {"r_eplate": 0.55, "r_grout": 0.5, "r_col": 0.45, "r_ex": 0.45, "r_tie": 0.5, "r_rod": 0.5, "r_ancg": 0.7,
             "r_concb": 0.8, "r_steel": 0.7}

# a stroke or fill of None: nothing (fill-only pieces of the 3D hooks)
_c0 = J._c
J._c = lambda h: None if h is None else _c0(h)

_style0 = J._style


def _style(shape, s, closed=True):
    shape = _style0(shape, s, closed)
    if s in STROKE_OP:
        shape.strokeOpacity = STROKE_OP[s]
    return shape


J._style = _style

# text styles: (font, size, colour) at fs = 1
_init0 = J.Style.__init__


def _init(self, fs):
    _init0(self, fs)
    # all drawing text at the size of the caption notes (7.2 pt at fs = 1; user 2026-10-04)
    self.text.update({"anc": (J.BOLD, 7.2 * fs, "#a93226"), "hk": (J.BOLD, 7.2 * fs, "#7a5500"),
                      "new": (J.BOLD, 7.2 * fs, "#145a32"), "tie": (J.BOLD, 7.2 * fs, "#5b2c6f"),
                      "bsm": (J.BOLD, 7.2 * fs, "#0e2f44"),
                      "small": (J.BASE, 7.2 * fs, "#444444"), "label": (J.BASE, 7.2 * fs, "#222222"),
                      "dim": (J.BASE, 7.2 * fs, "#333333"), "code": (J.BOLD, 7.2 * fs, "#111111"),
                      "red": (J.BOLD, 7.2 * fs, "#D0021B")})


J.Style.__init__ = _init

# weld symbol: "groove": "bevel" draws the single-bevel groove symbol (arrow side) instead of
# the fillet triangle; arrow, reference line, field flag and tail are joint_pdf's
_weld0 = J._weld


def _weld(d, xt, yt, xe, ye, it):
    if it.get("groove") != "bevel":
        return _weld0(d, xt, yt, xe, ye, it)
    import math
    f = J.S.fs
    blk = J._c("#222222")
    dr = 1 if it.get("dir", 1) >= 0 else -1
    xr = xe + dr * J._WREF * f
    d.add(J.Line(xe, ye, xt, yt, strokeColor=blk, strokeWidth=0.6))
    L = max(math.hypot(xt - xe, yt - ye), 1e-6)
    ux, uy = (xt - xe) / L, (yt - ye) / L
    al, aw = 5.5 * f, 1.8 * f
    d.add(J.Polygon([xt, yt, xt - ux * al - uy * aw, yt - uy * al + ux * aw,
                     xt - ux * al + uy * aw, yt - uy * al - ux * aw],
                    fillColor=blk, strokeColor=blk, strokeWidth=0.3))
    d.add(J.Line(xe, ye, xr, ye, strokeColor=blk, strokeWidth=0.8))
    if it.get("field"):
        top = ye + 10 * f
        d.add(J.Line(xe, ye, xe, top, strokeColor=blk, strokeWidth=0.6))
        d.add(J.Polygon([xe, top, xe + dr * 6 * f, top - 2 * f, xe, top - 4 * f],
                        fillColor=blk, strokeColor=blk, strokeWidth=0.3))
    if it.get("tail"):
        tw = 4 * f
        size = 6 * f
        d.add(J.Line(xr, ye, xr + dr * tw, ye + tw, strokeColor=blk, strokeWidth=0.6))
        d.add(J.Line(xr, ye, xr + dr * tw, ye - tw, strokeColor=blk, strokeWidth=0.6))
        d.add(J.String(xr + dr * (tw + 1.5 * f), ye - size * 0.35, it["tail"], fontName=J.BASE,
                       fontSize=size, fillColor=blk, textAnchor="start" if dr > 0 else "end"))
    h = 6 * f
    xs = xe + 13 * f if dr > 0 else xe - 13 * f - h
    # perpendicular leg on the left, bevel leg from its foot up to the line
    d.add(J.Line(xs, ye, xs, ye - h, strokeColor=blk, strokeWidth=0.8))
    d.add(J.Line(xs, ye - h, xs + h, ye, strokeColor=blk, strokeWidth=0.8))


J._weld = _weld

# **bold** inside table cells and paragraphs
import re  # noqa: E402


def _P(text, style):
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", J.escape(str(text)))
    t = re.sub(r"\[\[azul\]\](.+?)\[\[/azul\]\]", r'<font color="#1f5fa8">\1</font>', t)   # blue text
    return J.Paragraph(t, style)


J.P_ = _P



def main(src, dst):
    """As joint_pdf.main, plus page 'A1L' (A1 landscape) and frame 'tb': a factor on the title-block
    text (joint_pdf draws it at fixed sizes, too small on A1). The flow of blocks is joint_pdf's."""
    import json
    from reportlab.lib.pagesizes import A1, A2, A4, landscape
    from reportlab.lib.units import mm
    from reportlab.platypus import SimpleDocTemplate
    with open(src) as f:
        doc = json.load(f)
    J.S = J.Style(float(doc.get("fs", 1.0)))
    size = {"A1L": landscape(A1), "A2L": landscape(A2)}.get(doc.get("page"), A4)
    frame = doc.get("frame")
    hb = float(frame.get("h", 20)) * mm if frame else 0
    tb = float(frame.get("tb", 1.0)) if frame else 1.0
    m = 18 * mm if not frame else 16 * mm
    bottom = 16 * mm if not frame else 8 * mm + hb + 8 * mm
    pdf = SimpleDocTemplate(dst, pagesize=size, leftMargin=m, rightMargin=m, topMargin=15 * mm,
                            bottomMargin=bottom, title=doc["title"])
    width = size[0] - 2 * m

    def page(canvas, d):
        canvas.saveState()
        if frame:
            sheets = J.aslist(frame.get("sheets"))
            n, i = len(sheets), d.page
            canvas.setStrokeColor(J._c("#222222"))
            canvas.setLineWidth(1.2)
            canvas.rect(8 * mm, 8 * mm, size[0] - 16 * mm, size[1] - 16 * mm)
            x0, y0, w = 8 * mm, 8 * mm, size[0] - 16 * mm
            canvas.setLineWidth(0.8)
            canvas.line(x0, y0 + hb, x0 + w, y0 + hb)
            fields = J.aslist(frame.get("fields"))
            ws = J.aslist(frame.get("widths")) or [1 / len(fields)] * len(fields)
            x = x0
            for (label, value), f in zip(fields, ws):
                cw = f * w
                if x > x0:
                    canvas.line(x, y0, x, y0 + hb)
                pad = 3 * mm * tb
                canvas.setFillColor(J._c("#555555"))
                canvas.setFont(J.BOLD, 6.5 * tb)
                canvas.drawString(x + pad, y0 + hb - 5 * mm * tb, label)
                canvas.setFillColor(J._c("#111111"))
                if value == "@page":
                    canvas.setFont(J.BOLD, 18 * tb)
                    canvas.drawCentredString(x + cw / 2, y0 + hb / 2 - 5 * mm * tb, f"{i} / {n}")
                elif value == "@sheet":
                    canvas.setFont(J.BOLD, 11 * tb)
                    canvas.drawString(x + pad, y0 + hb - 11 * mm * tb, sheets[i - 1] if i <= n else "")
                    lines = J._wrap(frame.get("subtitle", ""), J.BASE, 7 * tb, cw - 2 * pad)
                    canvas.setFont(J.BASE, 7 * tb)
                    for j, ln in enumerate(lines):
                        canvas.drawString(x + pad, y0 + hb - 16 * mm * tb - j * 3.2 * mm * tb, ln)
                else:
                    lines = []
                    for part in str(value).split("\n"):
                        lines += J._wrap(part, J.BASE, 8.5 * tb, cw - 2 * pad)
                    canvas.setFont(J.BASE, 8.5 * tb)
                    for j, ln in enumerate(lines):
                        canvas.drawString(x + pad, y0 + hb - 10.5 * mm * tb - j * 3.8 * mm * tb, ln)
                x += cw
        canvas.restoreState()

    pdf.build(J.flow(doc["blocks"], width), onFirstPage=page, onLaterPages=page)
    print(f"  {dst}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
