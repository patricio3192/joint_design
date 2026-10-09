"""Small detail: column head with the base plate of the steel column flush with the
finished slab (+105). Plate 10, grout 25, concrete head at +70, cover 40 to the Ø16 hooks,
2 ties Ø14 between the hooks and the top row of A1. Writes reports/detalle_cabeza_columna.pdf.
Model units: mm; x = 0 at the column face on the cantilever side, y = 0 at the top of the beams."""
import math
import os
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

pdfmetrics.registerFont(TTFont("L", "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"))
pdfmetrics.registerFont(TTFont("LB", "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"))

# geometry ------------------------------------------------------------------------------
B = 400                 # column
SLAB = 105              # finished slab over the top of the beams
TP, GR = 10, 25         # base plate, grout
TOP = SLAB - TP - GR    # concrete head: 70
CV, DB = 40, 16         # cover to the hooks, column bars
YH = TOP - CV - DB / 2  # hook centre: 22
RB = 3 * DB + DB / 2    # bend radius to the bar centre: 56
XC = 58                 # column bars from the faces
YA, DA = -42, 16        # top row of A1
T14 = 14
GAP_LO = (YA + DA / 2)  # top of the A1: -34
GAP_HI = YH - DB / 2    # bottom of the hooks: +14
FREE = GAP_HI - GAP_LO  # 48
CLR = (FREE - 2 * T14) / 2
YT = [GAP_LO + CLR + T14 / 2, GAP_LO + CLR + 3 * T14 / 2]   # -17, -3
PB = 340                # base plate drawn (size from the steel column)
YB = -150               # crop

S = 0.95                # pt per mm
OX, OY = 360, 190       # page position of the model origin
W, H = 1400, 500

ST = {  # stroke, width, fill, fill opacity, dash
    "conc":  ("#6b6b6b", 0.8, "#ece9e2", 1.0, None),
    "grout": ("#6b6b6b", 0.6, "#b9b2a0", 0.55, None),
    "plate": ("#1f3347", 0.8, "#a9bdd1", 0.9, None),
    "steel": ("#1f3347", 0.7, "#a9bdd1", 0.25, (5, 3)),
    "deck":  ("#555555", 0.8, None, 0, None),
    "ipe":   ("#1f3347", 0.6, "#dfe7ef", 1.0, None),
}


def P(x, y):
    return OX + S * x, OY + S * y


def hexc(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) / 255 for i in (0, 2, 4))


def rect(c, x0, y0, x1, y1, st):
    s, w, f, fo, dash = ST[st]
    c.saveState()
    c.setStrokeColorRGB(*hexc(s)); c.setLineWidth(w)
    if dash: c.setDash(*dash)
    if f:
        c.setFillColorRGB(*hexc(f)); c.setFillAlpha(fo)
    a, b = P(min(x0, x1), min(y0, y1))
    c.rect(a, b, S * abs(x1 - x0), S * abs(y1 - y0), stroke=1, fill=1 if f else 0)
    c.restoreState()


def bar(c, pts, d, col, edge):
    """Bar as a thick polyline (round caps), drawn twice for an outline."""
    for wid, colr in ((S * d, edge), (S * d - 1.0, col)):
        c.saveState()
        c.setStrokeColorRGB(*hexc(colr)); c.setLineWidth(wid); c.setLineCap(1); c.setLineJoin(1)
        p = c.beginPath(); p.moveTo(*P(*pts[0]))
        for q in pts[1:]: p.lineTo(*P(*q))
        c.drawPath(p, stroke=1, fill=0)
        c.restoreState()


def circ(c, x, y, d, col, edge):
    c.saveState(); c.setFillColorRGB(*hexc(col)); c.setStrokeColorRGB(*hexc(edge)); c.setLineWidth(0.5)
    c.circle(*P(x, y), S * d / 2, stroke=1, fill=1); c.restoreState()


def line(c, x0, y0, x1, y1, w=0.5, col="#222222", dash=None):
    c.saveState(); c.setStrokeColorRGB(*hexc(col)); c.setLineWidth(w)
    if dash: c.setDash(*dash)
    c.line(*P(x0, y0), *P(x1, y1)); c.restoreState()


def text(c, x, y, s, size=9, col="#222222", bold=False, anchor="start", page=False):
    c.saveState(); c.setFillColorRGB(*hexc(col)); c.setFont("LB" if bold else "L", size)
    a, b = (x, y) if page else P(x, y)
    {"start": c.drawString, "end": c.drawRightString, "middle": c.drawCentredString}[anchor](a, b, s)
    c.restoreState()


def tick(c, x, y):
    a, b = P(x, y); c.saveState(); c.setLineWidth(0.8); c.line(a - 3, b - 3, a + 3, b + 3); c.restoreState()


def vdim(c, x, y0, y1, label, side=1, ext_from=None):
    """Vertical dimension at x; label on the left (side=-1) or right (side=1) of the line."""
    if ext_from is not None:
        for y in (y0, y1): line(c, ext_from, y, x + 4 * side, y, 0.3, "#555555")
    line(c, x, y0, x, y1, 0.5); tick(c, x, y0); tick(c, x, y1)
    a, b = P(x, (y0 + y1) / 2)
    c.saveState(); c.setFont("L", 8.5); c.translate(a - 3 if side < 0 else a + 9, b); c.rotate(90)
    c.drawCentredString(0, 0, label); c.restoreState()


def leader(c, xt, yt, xe, ye, s, col, lines=None):
    """Label at page-model (xt, yt) with a leader to (xe, ye) and a dot."""
    line(c, xt - 6, yt + 3, xt - 22, yt + 3, 0.5)
    line(c, xt - 22, yt + 3, xe, ye, 0.5)
    circ(c, xe, ye, 5, "#222222", "#222222")
    for k, t in enumerate([s] + (lines or [])):
        text(c, xt, yt - 11 * k / S, t, 9, col, bold=(k == 0))


def hooked_bar(xc, inward):
    """Column bar: straight up to the bend, quarter circle, leg inward."""
    y0 = YH - RB
    pts = [(xc, YB), (xc, y0)]
    for k in range(1, 13):
        a = math.pi / 2 * k / 12
        pts.append((xc + inward * (RB - RB * math.cos(a)), y0 + RB * math.sin(a)))
    pts.append((xc + inward * (RB + 130), YH))
    return pts


def main():
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "reports", "detalle_cabeza_columna.pdf")
    c = canvas.Canvas(out, pagesize=(W, H))
    c.setTitle("Cabeza de columna con placa base al ras de la losa")

    # concrete: column and joint, beam in line (right), slab over the cantilever (left)
    rect(c, 0, YB, B, TOP, "conc")
    rect(c, B, YB, 640, 0, "conc")
    rect(c, B, 0, 640, SLAB, "conc")
    rect(c, -230, 0, 0, SLAB, "conc")
    for x in list(range(-230, -10, 75)) + list(range(410, 570, 75)):   # deck (Novalosa 55) on both sides
        line(c, x, 0, x + 20, 55, 0.8, "#555555"); line(c, x + 20, 55, x + 45, 55, 0.8, "#555555")
        line(c, x + 45, 55, x + 65, 0, 0.8, "#555555"); line(c, x + 65, 0, x + 75, 0, 0.8, "#555555")
    # IPE 240, P2 and grout (later) under the slab on the cantilever side
    rect(c, -25, YB, 0, 0, "grout")
    rect(c, -37, YB, -25, 0, "plate")
    rect(c, -230, -9.8, -37, 0, "ipe"); rect(c, -230, YB, -37, -9.8, "ipe")
    # pocket: grout and base plate, steel column (later)
    rect(c, 0, TOP, B, SLAB, "grout")
    rect(c, (B - PB) / 2, SLAB - TP, (B + PB) / 2, SLAB, "plate")
    rect(c, B / 2 - 75, SLAB, B / 2 + 75, SLAB + 70, "steel")
    line(c, -260, SLAB, 650, SLAB, 0.4, "#555555", (2, 2))
    line(c, -260, 0, 640, 0, 0.4, "#555555", (2, 2))

    # reinforcement
    for x in (B + 50, B + 160):                                                          # VCM stirrups Ø10
        bar(c, [(x, YB), (x, -45)], 10, "#7d3c98", "#4a235a")
    bar(c, [(45, -110), (B - 45, -110)], 10, "#7d3c98", "#4a235a")                     # joint tie Ø10
    for y in (-56, -80):                                                                 # VCM top bars, hooked down
        bar(c, [(640, y), (95, y), (70, y - 25), (70, YB)], 12, "#1a5276", "#0e2f44")
    for x in (106, 200, 294): circ(c, x, -68, 12, "#616a6b", "#1c2833")                 # VCS bars crossing
    for xc, inw in ((XC, 1), (B - XC, -1)):
        bar(c, hooked_bar(xc, inw), DB, "#c9a227", "#6b4a00")                            # column bars Ø16
    for x in (100, 300): bar(c, [(x, YB), (x, SLAB)], 12, "#45b39d", "#0b5345")          # rods of the steel column
    for y in YT: bar(c, [(43, y), (B - 43, y)], T14, "#1e8449", "#145a32")               # ties Ø14
    bar(c, [(-60, YA), (346, YA)], DA, "#c0392b", "#7b241c")                             # A1, top row
    rect(c, 309, YA - 25, 321, YA + 25, "plate")                                         # P1

    # dimensions: grout, plate and cover only
    xl = -290
    vdim(c, xl, TOP, SLAB - TP, f"{GR:g}", -1, ext_from=-240)
    vdim(c, xl, SLAB - TP, SLAB, f"{TP:g}", -1, ext_from=-240)
    line(c, -240, TOP, 0, TOP, 0.3, "#555555", (2, 2))
    xr = 385
    vdim(c, xr, YH + DB / 2, TOP, f"rec. {CV:g}", 1, ext_from=B - XC - 140)

    # labels
    X = 720
    leader(c, X, 205, B / 2 + 140, SLAB - 5, "Placa base 10, al ras de la losa terminada (+105)", "#1f3347")
    leader(c, X, 175, 20, TOP + 12, f"Grout {GR:g} (tipo SikaGrout-212)", "#5a5346")
    leader(c, X, 140, B - XC - 100, YH, f"Ganchos Ø16 de la columna: rec. {CV:g} a la cara del hormigón (+{TOP:g})", "#6b4a00")
    leader(c, X, 105, 300, 60, "Anclas Ø12 de la columna metálica (remate arriba: pendiente)", "#0b5345")
    leader(c, X, 50, B - 70, YT[1], f"2 estribos Ø14 juntos, a {YT[1]:g} y {YT[0]:g}", "#145a32",
           [f"{CLR:g} libres al gancho y {CLR:g} al A1"])
    leader(c, X, 0, 250, YA, f"A1 fila superior a {YA:g}", "#7b241c")
    leader(c, X, -40, 620, -56, "VCM: barras superiores", "#0e2f44")
    leader(c, X, -80, 200, -68, "VCS: barras superiores (cruzan)", "#1c2833")
    leader(c, X, -125, B - 70, -110, "Estribo Ø10 del nudo (el más alto)", "#4a235a")
    leader(c, X, -165, B + 160, -120, "Estribos Ø10 de la VCM: el primero a 50 de la cara de la columna", "#4a235a")
    text(c, -60, -9.8 - 60, "IPE 240", 9, "#1f3347", anchor="end")
    text(c, -130, SLAB + 12, "Novalosa 55 + 50", 8.5, "#555555", anchor="middle")
    text(c, 520, SLAB + 12, "Novalosa 55 + 50", 8.5, "#555555", anchor="middle")
    text(c, B / 2, SLAB + 75, "columna metálica", 8.5, "#1f3347", anchor="middle")
    text(c, 470, -30, "cara superior de las vigas (0)", 8, "#555555")

    # title
    text(c, 40, H - 40, "DETALLE - CABEZA DE COLUMNA CON PLACA BASE AL RAS DE LA LOSA (C4; corte por el eje del voladizo)",
         12, bold=True, page=True)
    c.save()
    print(out)


if __name__ == "__main__":
    main()
