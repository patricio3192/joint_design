"""Sketch (2026-10-05, user): top anchors opened out beyond the IPE 240 flanges, end plate as a T with
stiffeners (A36 PL 12 only). Writes reports/anclas_anchas.html: front at the column face, plan at the
anchor level, section along an anchor, and the D/C table written by ca_wide.m (run it first).
mm; v across (column axis 0), z up (0 = top of the concrete beams = top of the IPE), u into the column
(0 = column face). Numbers from ca_inputs.m / ca_wide.m, copied here: change both if one changes.
"""
import math
import os

# ---- geometry (ca_inputs.m) ----------------------------------------------------------
B, TOP, CJ = 400, 100, -350           # column, pedestal top, soffit of the beams
COVER, DTIE, DB = 40, 10, 16          # column cover, tie, bars
RC = COVER + DTIE + DB / 2            # bar axis from a face: 58
H, BF, TF, TW = 240, 120, 9.8, 6.2    # IPE 240
EPT, DBL, G = 12, 12, 30              # end plate, extra plate, grout
DA, NUT, NUTC = 15.875, 24, 27.7      # 5/8" rod, nut across flats / corners
ROD, RODP = 12, 100                   # steel column rods at (+-100, +-100)
VS, ZS = 35, -201                     # A2
BPU, BPT = 364, 12                    # back plate bearing face, thickness

# ---- the new layout (ca_wide.m) -------------------------------------------------------
VA, ZA, ZAY = 120, -50, 30            # anchors: |v|, z (E, C1, CX: under S1, as deep as the crossing bars at -68 allow); CY over S1
EDGE, TOL = 25, 20                    # hole to plate edge + 20 for the anchors set out of place (user)
TS, WS, DS = 12, 6, 100               # S1: flange extension, top flush with the flange top (z 0 .. -12), depth along u
X3, DS2 = 20, 80                      # S2 under the anchor: its fillet toe 20 from the anchor axis; depth along u
ZS2 = ZA - X3 - WS                    # S2 top face: -76 (plate -76 .. -88)
EAR_T = 15                            # top of the T: over the flange top fillet
EAR_B = ZS2 - TS - 8                  # bottom of the T bar: under S2: -96
VR, TR, DR = 82, 12, 80               # R1: vertical gusset under S1, inner face at v = 82, down to S2
EPW_TOP = 2 * (VA + EDGE + TOL)       # T bar: 330
EPW = 160                             # stem (bearing side, as now)
BWW, BWH = 50, 50                     # back plates: one square per anchor, PL 12x50x50 (clear of the beam bars at v = 88)
VRT = VR + TR + WS                    # R1 fillet toe on the anchor side: 100
X1, X2 = (-TS - WS) - ZA, VA - VRT     # anchor to the S1 and R1 fillet toes: 32, 20

clr_rod = VA - RODP - DA / 2 - ROD / 2
clr_bar = (B / 2 - RC) - VA - DA / 2 - DB / 2
side = B / 2 - VA


class Svg:
    def __init__(s, x0, x1, y0, y1, k=1.25):
        s.x0, s.y1, s.k = x0, y1, k
        s.w, s.h = (x1 - x0) * k, (y1 - y0) * k
        s.b = []

    def p(s, x, y):
        return (x - s.x0) * s.k, (s.y1 - y) * s.k

    def rect(s, x0, y0, x1, y1, fill, stroke='#333', sw=0.8, op=1, dash=None):
        a, b = s.p(min(x0, x1), max(y0, y1))
        d = f' stroke-dasharray="{dash}"' if dash else ''
        s.b.append(f'<rect x="{a:.1f}" y="{b:.1f}" width="{abs(x1-x0)*s.k:.1f}" height="{abs(y1-y0)*s.k:.1f}" '
                   f'fill="{fill}" fill-opacity="{op}" stroke="{stroke}" stroke-width="{sw}"{d}/>')

    def circ(s, x, y, r, fill, stroke='#333', sw=0.8, dash=None):
        a, b = s.p(x, y)
        d = f' stroke-dasharray="{dash}"' if dash else ''
        s.b.append(f'<circle cx="{a:.1f}" cy="{b:.1f}" r="{r*s.k:.1f}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}/>')

    def line(s, x0, y0, x1, y1, col='#333', sw=0.8, dash=None):
        a, b = s.p(x0, y0); c, d = s.p(x1, y1)
        ds = f' stroke-dasharray="{dash}"' if dash else ''
        s.b.append(f'<line x1="{a:.1f}" y1="{b:.1f}" x2="{c:.1f}" y2="{d:.1f}" stroke="{col}" stroke-width="{sw}"{ds}/>')

    def poly(s, pts, fill, stroke='#333', sw=0.8, op=1):
        q = ' '.join('%.1f,%.1f' % s.p(x, y) for x, y in pts)
        s.b.append(f'<polygon points="{q}" fill="{fill}" fill-opacity="{op}" stroke="{stroke}" stroke-width="{sw}"/>')

    def text(s, x, y, t, anchor='start', size=11, col='#222', bold=False):
        a, b = s.p(x, y)
        fw = ' font-weight="bold"' if bold else ''
        s.b.append(f'<text x="{a:.1f}" y="{b:.1f}" font-size="{size}" fill="{col}" text-anchor="{anchor}"{fw}>{t}</text>')

    def dim(s, x0, y0, x1, y1, off, t=None, size=10):
        # dimension parallel to 0 -> 1, moved off (mm) to the left of the direction
        L = math.hypot(x1 - x0, y1 - y0); ux, uy = (x1 - x0) / L, (y1 - y0) / L; nx, ny = -uy, ux
        a0, b0, a1, b1 = x0 + nx * off, y0 + ny * off, x1 + nx * off, y1 + ny * off
        s.line(x0, y0, a0 + nx * 3, b0 + ny * 3, '#777', 0.5)
        s.line(x1, y1, a1 + nx * 3, b1 + ny * 3, '#777', 0.5)
        s.line(a0, b0, a1, b1, '#333', 0.7)
        for (a, b) in [(a0, b0), (a1, b1)]:
            s.line(a - 3 * (ux - nx), b - 3 * (uy - ny), a + 3 * (ux - nx), b + 3 * (uy - ny), '#333', 1.0)
        t = t if t is not None else '%g' % round(L, 1)
        cx, cy = (a0 + a1) / 2 + nx * 4, (b0 + b1) / 2 + ny * 4
        X, Y = s.p(cx, cy)
        ang = -math.degrees(math.atan2(uy, ux))
        if ang > 90 or ang <= -90:
            ang += 180
        s.b.append(f'<text x="{X:.1f}" y="{Y:.1f}" font-size="{size}" text-anchor="middle" '
                   f'transform="rotate({ang:.1f} {X:.1f} {Y:.1f})">{t}</text>')

    def svg(s):
        return (f'<svg viewBox="0 0 {s.w:.0f} {s.h:.0f}" width="100%" style="max-width:{s.w:.0f}px" '
                f'xmlns="http://www.w3.org/2000/svg" font-family="Helvetica,Arial,sans-serif">' + ''.join(s.b) + '</svg>')


CONC, BAR, ROD_C, ANC, PLATE, STEEL, STIFF, IPE = '#efece6', '#a8822a', '#2e8b74', '#c0392b', '#34506b', '#9fb3c8', '#e08e2b', '#5d7b99'


def front():
    """Seen from the beam side at the column face: column, end plate (T), IPE 240 cut, S1, R1, anchors."""
    s = Svg(-300, 470, -385, 200)
    s.rect(-B/2, CJ, B/2, TOP, CONC)
    for sg in (-1, 1):
        s.rect(sg * B/2, -350, sg * (B/2 + 60), 0, '#f6f4ef', '#999', 0.5, dash='4 3')
    for v in (-RODP, RODP):
        s.rect(v - ROD/2, CJ + 30, v + ROD/2, TOP + 40, ROD_C, ROD_C, 0.5, op=0.35)
    for v in (-B/2 + RC, 0, B/2 - RC):
        s.rect(v - DB/2, CJ + 30, v + DB/2, 72, BAR, BAR, 0.5, op=0.30)
    # end plate as a T, the extra plate on the ears (concrete side, dashed); trapezoid option dashed
    s.poly([(-EPW/2, -265), (EPW/2, -265), (EPW/2, EAR_B), (EPW_TOP/2, EAR_B), (EPW_TOP/2, EAR_T),
            (-EPW_TOP/2, EAR_T), (-EPW_TOP/2, EAR_B), (-EPW/2, EAR_B)], STEEL, '#1f3347', 0.9, op=0.35)
    for sg in (-1, 1):
        s.line(sg * EPW_TOP/2, EAR_B, sg * EPW/2, -265, '#1f3347', 0.7, '5 3')
        s.rect(sg * VR, -TS, sg * EPW_TOP/2, EAR_B, 'none', '#1f3347', 0.7, dash='2 2')
    # IPE 240 cut
    s.rect(-BF/2, -TF, BF/2, 0, IPE, '#1f3347')
    s.rect(-BF/2, -H, BF/2, -H + TF, IPE, '#1f3347')
    s.rect(-TW/2, -H + TF, TW/2, -TF, IPE, '#1f3347')
    # stiffeners: S1 in the plane of the flange (top flush), R1 on S1 inside the anchor
    for sg in (-1, 1):
        s.rect(sg * BF/2, -TS, sg * EPW_TOP/2, 0, STIFF, '#7a4a10')
        s.rect(sg * VR, -TS, sg * (VR + TR), ZS2, STIFF, '#7a4a10')
        s.rect(sg * (VR + TR), ZS2, sg * EPW_TOP/2, ZS2 - TS, STIFF, '#7a4a10')
    # anchors
    for v in (-VS, VS):
        s.circ(v, ZS, DA/2 + 1, ANC, '#7a1f17')
    for v in (-VA, VA):
        s.circ(v, ZA, NUTC/2, 'none', '#7a1f17', 0.8, dash='2 2')
        s.circ(v, ZA, DA/2 + 1, ANC, '#7a1f17')
    # dimensions
    s.dim(-B/2, -370, B/2, -370, 0, '400')
    s.dim(-VA, -335, VA, -335, 0, '%g' % (2*VA))
    s.dim(VA, -335, B/2, -335, 0, '%g' % side)
    s.dim(-EPW/2, -265, EPW/2, -265, -14, '%g' % EPW)
    s.dim(-EPW_TOP/2, EAR_T, EPW_TOP/2, EAR_T, 40, '%g' % EPW_TOP)
    s.dim(EPW_TOP/2, EAR_B, EPW_TOP/2, EAR_T, 14, '%g' % (EAR_T - EAR_B))
    s.dim(VA, EAR_T, EPW_TOP/2, EAR_T, 12, '%g' % (EPW_TOP/2 - VA))
    s.dim(VRT, ZA, VA, ZA, -18, '%g' % X2)
    s.dim(-VA - 30, -TS - WS, -VA - 30, ZA, 0, '%g' % X1)
    s.dim(-VA - 30, ZA, -VA - 30, ZA - X3, 0, '%g' % X3)
    s.dim(BF/2, -TS - 30, VR, -TS - 30, 0, '%g' % (VR - BF/2))
    s.dim(-B/2 - 25, 0, -B/2 - 25, ZA, 0, '%g' % ZA)
    labels = [(TOP, TOP, 'cara superior +100'), (EAR_T, EAR_T + 6, 'placa: borde superior %+g' % EAR_T), (0, -8, 'S1: 0 a %g' % -TS),
              (ZA, ZA - 6, 'A1 %+g (CY: %+g, sobre S1)' % (ZA, ZAY)), (ZS2, ZS2 - 16, 'S2: %g a %g' % (ZS2, ZS2 - TS)),
              (EAR_B, EAR_B - 30, 'fin del ala de la T %+g' % EAR_B), (ZS, ZS, 'A2 %g' % ZS)]
    xr = B/2 + 75
    for z, zq, t in labels:
        s.line(EPW_TOP/2 + 5, z, xr - 14, z, '#999', 0.4, '3 2'); s.line(xr - 14, z, xr - 4, zq, '#999', 0.4)
        s.text(xr, zq - 4, t, size=10)
    s.text(VR + TR/2 - 14, ZA, 'R1', 'end', 10, '#7a4a10', True)
    s.text(150, 4, 'S1', 'middle', 10, '#7a4a10', True)
    s.text(150, ZS2 - TS - 14, 'S2', 'middle', 10, '#7a4a10', True)
    s.text(0, -H - 52, 'Visto desde la viga: IPE cortado en la placa; S1 y R1 (naranja) del lado de la viga', 'middle', 10)
    s.text(-RODP, TOP + 52, 'pernos Ø12 col. metálica', 'middle', 9, ROD_C)
    return s.svg()


def plan():
    """Plan at the anchor level (z = -50), u from the cantilever face (left) into the column."""
    s = Svg(-210, 640, -260, 250)
    s.rect(0, -B/2, B, B/2, CONC)
    for u in (RC, B/2, B - RC):
        for v in (-B/2 + RC, 0, B/2 - RC):
            if u == B/2 and v == 0:
                continue
            s.circ(u, v, DB/2, BAR, '#6b5216')
    for u in (B/2 - RODP, B/2 + RODP):
        for v in (-RODP, RODP):
            s.circ(u, v, ROD/2, ROD_C, '#1d5c4d')
    # grout, extra plate (ears), end plate, R1 (beam side), S1 under it (dashed), IPE flange (below, dashed)
    s.rect(-G, -EPW_TOP/2, 0, EPW_TOP/2, '#d9d3c5', '#888', 0.5)
    for sg in (-1, 1):
        s.rect(-G, sg * VR, -G + DBL, sg * EPW_TOP/2, STEEL, '#1f3347', op=0.6)
    s.rect(-G - EPT, -EPW_TOP/2, -G, EPW_TOP/2, STEEL, '#1f3347')
    for sg in (-1, 1):
        s.rect(-G - EPT - DS, sg * BF/2, -G - EPT, sg * EPW_TOP/2, 'none', '#7a4a10', 0.8, dash='4 3')
        s.rect(-G - EPT - DS2, sg * (VR + TR), -G - EPT, sg * EPW_TOP/2, 'none', '#7a4a10', 0.8, dash='1 2')
        s.rect(-G - EPT - DR, sg * VR, -G - EPT, sg * (VR + TR), STIFF, '#7a4a10')
    s.rect(-G - EPT - 160, -BF/2, -G - EPT, BF/2, 'none', '#1f3347', 0.6, dash='4 3')
    s.text(-G - EPT - 120, -4, 'IPE (ala sup. encima)', 'middle', 9, '#1f3347')
    uT = BPU + BPT + 3 + 14
    for v in (-VA, VA):
        s.rect(-80, v - DA/2, uT, v + DA/2, ANC, '#7a1f17')
        s.rect(BPU, v - BWW/2, BPU + BPT, v + BWW/2, PLATE, '#142433')
        s.rect(BPU - 14, v - NUT/2, BPU, v + NUT/2, '#7a1f17', '#4a120c')
        s.rect(BPU + BPT, v - NUT/2, uT, v + NUT/2, '#7a1f17', '#4a120c')
        s.rect(-G - EPT - 14, v - NUT/2, -G - EPT, v + NUT/2, '#7a1f17', '#4a120c')
    s.dim(0, -B/2, B, -B/2, 22, '400')
    s.dim(0, B/2, BPU, B/2, -14, '%g' % BPU)
    s.dim(-185, -VA, -185, VA, 0, '%g' % (2*VA))
    s.dim(B + 30, VA, B + 30, B/2, 0, '%g' % side)
    s.dim(B + 60, VA - BWW/2, B + 60, VA + BWW/2, 0, '%g' % BWW)
    s.dim(-G - EPT - DS, -B/2 + 20, -G - EPT, -B/2 + 20, 0, '%g (S1)' % DS)
    s.text(B + 75, VA + 50, 'B1: 2 cuadradas PL 12x%gx%g' % (BWW, BWH), 'start', 9, PLATE, True)
    s.text(-G - EPT - DR/2, VR + TR + 10, 'R1', 'middle', 9, '#7a4a10', True)
    s.text(-G - EPT - DS/2, B/2 - 25, 'S1 (encima), S2 (debajo)', 'middle', 9, '#7a4a10')
    s.text(B/2, -B/2 - 38, 'Planta a z = %+g. Placa extra (azul claro) del lado del concreto, en las orejas' % ZA, 'middle', 10)
    return s.svg()


def section():
    """Section along an anchor (v = 120): S1 and R1 on the beam side, the anchor over S1, B1."""
    s = Svg(-330, 700, -380, 160)
    s.rect(0, CJ, B, TOP, CONC)
    s.rect(B, -350, B + 100, 0, '#f6f4ef', '#999', 0.5, dash='4 3')
    s.rect(-G, -265, 0, EAR_T, '#d9d3c5', '#888', 0.5)
    s.rect(-G - DBL, EAR_B, -G, -TS, STEEL, '#1f3347', op=0.6)          # extra plate (ear only)
    s.rect(-G - DBL - EPT, -265, -G - DBL, EAR_T, STEEL, '#1f3347')
    u0 = -G - DBL - EPT
    s.rect(u0 - DS, -TS, u0, 0, STIFF, '#7a4a10')                       # S1
    s.rect(u0 - DR, ZS2, u0, -TS, STIFF, '#7a4a10', op=0.45)            # R1 (behind, at v = 82)
    s.rect(u0 - DS2, ZS2 - TS, u0, ZS2, STIFF, '#7a4a10')               # S2
    s.rect(-300, -TF, u0 - DS, 0, IPE, '#1f3347', op=0.5)
    s.rect(-300, -H, u0, -H + TF, IPE, '#1f3347', op=0.5)
    s.text(-200, -120, 'IPE 240 (detrás)', 'middle', 10, '#1f3347')
    for u in (RC, B - RC):
        s.rect(u - DB/2, CJ + 20, u + DB/2, 16, BAR, BAR, 0.5, op=0.35)
    for z in (-56, -80):
        s.line(40, z, B + 100, z, '#1a5276', 3)
    for u in (112, 200, 288):                                           # crossing beam, cut
        s.circ(u, -68, 6, '#7f8c8d', '#555')
    uT = BPU + BPT + 3 + 14
    s.rect(-80 - DBL, ZA - DA/2, uT, ZA + DA/2, ANC, '#7a1f17')
    s.rect(BPU, ZA - BWH/2, BPU + BPT, ZA + BWH/2, PLATE, '#142433')
    s.rect(BPU - 14, ZA - NUT/2, BPU, ZA + NUT/2, '#7a1f17', '#4a120c')
    s.rect(BPU + BPT, ZA - NUT/2, uT, ZA + NUT/2, '#7a1f17', '#4a120c')
    s.rect(u0 - 14, ZA - NUT/2, u0, ZA + NUT/2, '#7a1f17', '#4a120c')
    s.dim(0, TOP, BPU, TOP, 18, '%g' % BPU)
    s.dim(u0, TOP, 0, TOP, 18, '%g' % -u0)
    s.dim(u0 - DS, -TS, u0, -TS, -16, '%g' % DS)
    s.dim(BPU + 40, ZA - BWH/2, BPU + 40, ZA + BWH/2, 0, '%g' % BWH)
    xr = B + 110
    for z, t in [(TOP, 'cara superior +100'), (EAR_T, 'placa: borde superior %+g' % EAR_T), (0, 'S1 / ala superior'),
                 (ZA, 'A1 %+g' % ZA), (-68, 'barras de la viga que cruza -68'), (ZS2 - TS, 'S2 %g' % (ZS2 - TS)), (EAR_B, 'borde inferior %+g' % EAR_B)]:
        s.line(B + 4, z, xr - 4, z, '#999', 0.4, '3 2')
        s.text(xr, z - 3, t, size=10)
    s.text(BPU + 6, ZA + BWH/2 + 6, 'B1', 'start', 10, PLATE, True)
    s.text(u0 - DS/2, -TS - 20, 'S1', 'middle', 10, '#7a4a10', True)
    s.text(u0 - DR - 6, (ZS2 - TS + -TS) / 2, 'R1', 'end', 10, '#7a4a10', True)
    s.text(u0 - DS2/2, ZS2 - TS - 18, 'S2', 'middle', 10, '#7a4a10', True)
    s.text(B/2, CJ - 22, 'Corte a v = %g, a lo largo de un ancla' % VA, 'middle', 10)
    return s.svg()


here = os.path.dirname(os.path.abspath(__file__))
dcf = os.path.join(here, 'reports', 'anclas_anchas_dc.html')
dc = open(dcf, encoding='utf-8').read() if os.path.exists(dcf) else '<p>Correr ca_wide.m primero.</p>'

rows = [
    ('Ancla - pie del filete de S1 / R1 / S2', '%g / %g / %g' % (X1, X2, X3), 'franjas a los tres apoyos; la tuerca (esquina) queda a %.0f / %.0f / %.0f' % (X1 - NUTC/2, X2 - NUTC/2, X3 - NUTC/2)),
    ('Ancla - perno Ø12 de la columna metálica (v = 100)', '%.1f' % clr_rod, 'libre entre barras'),
    ('Ancla - barra Ø16 de la cara lateral (v = 142)', '%.1f' % clr_bar, 'libre entre barras'),
    ('Ancla - cara lateral de la columna', '%g' % side, 'reventón lateral con c<sub>a1</sub> = %g (hoy 165)' % side),
    ('Placa extremo (T)', '%g x %g / %g' % (EPW_TOP, EAR_T - EAR_B, EPW), 'ala de la T de %+g a %+g; agujero a %g del borde (%g + %g de tolerancia)' % (EAR_T, EAR_B, EDGE + TOL, EDGE, TOL)),
    ('Placa extra (orejas, lado del concreto)', '%g x %g' % (EPW_TOP/2 - VR, -TS - EAR_B), 'de v = %g al borde, de %g a %g; filetes en sus bordes sobre las líneas de S1, R1 y S2' % (VR, -TS, EAR_B)),
    ('S2 (debajo del ancla)', 'PL %g x %g' % (TS, DS2), 'de R1 al borde, de %g a %g; colgada de R1' % (ZS2, ZS2 - TS)),
    ('Ancla - barras de la viga que cruza (-68)', '%.0f' % ((ZA - DA/2) - (-68 + 6)), 'libre en z: no puede bajar más'),
    ('S1 (prolongación del ala)', 'PL %g x %g' % (TS, DS), 'de la punta del ala (CJP) al borde de la placa, al ras de la cara superior del ala'),
    ('R1 (cartela vertical)', 'PL %g x %g' % (TR, DR), 'cara interior a v = %g, de S1 a S2' % VR),
    ('B1', '2 x PL 12x%gx%g' % (BWW, BWH), 'una por ancla, de v = %g a %g: libre de las barras de la viga en v = 88 (CY: 80 x 80)' % (VA - BWW/2, VA + BWW/2)),
]

html = f"""<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Anclas anchas</title>
<style>body{{font-family:Helvetica,Arial,sans-serif;max-width:1200px;margin:24px auto;padding:0 16px;color:#222;background:#fff}}
h1{{font-size:22px}}h2{{font-size:17px;margin-top:28px}}.fig{{border:1px solid #ddd;padding:8px;margin:10px 0}}
table{{border-collapse:collapse;font-size:14px}}td,th{{border:1px solid #ccc;padding:4px 8px;text-align:left}}th{{background:#f2f2f2}}
.note{{font-size:14px;line-height:1.45}}</style></head><body>
<h1>Anclas superiores abiertas, fuera de las alas del IPE 240</h1>
<p class="note">Propuesta (2026-10-05). Medidas en mm; z desde la cara superior de las vigas (= cara superior del IPE).
<b>Las A1 bajan de +29 a {ZA:+g}</b> (C4, B4, D3, D4X), fuera de las alas, a v = &plusmn;{VA}: es lo más bajo posible, justo encima de las barras
de la viga que cruza (-68). En D4 las de D4Y cruzan a las de D4X y van arriba, a {ZAY:+g}, sobre S1. Solo placas A36 de 12 mm. La placa extremo es una <b>T</b>
({EPW_TOP} de {EAR_T:+g} a {EAR_B:+g}, {EPW} abajo), con tres refuerzos por lado del lado de la viga: <b>S1</b>, la prolongación del ala superior;
<b>R1</b>, cartela vertical bajo S1, por dentro del ancla; <b>S2</b>, bajo el ancla, colgada de R1. Cada ancla queda en una caja S1-R1-S2: la placa
la lleva con tres franjas cortas, más la placa extra en las orejas. <b>B1: dos cuadradas de 50</b>, libres de las barras de la viga.
Al bajar, el brazo de palanca baja y T en C4 sube de 81 a 122 kN.</p>
<h2>1. Vista en la cara de la columna (desde la viga)</h2><div class="fig">{front()}</div>
<h2>2. Planta a la altura de las anclas (z = {ZA:+g})</h2><div class="fig">{plan()}</div>
<h2>3. Corte a lo largo de un ancla (v = {VA})</h2><div class="fig">{section()}</div>
<h2>4. Medidas</h2><table><tr><th>Elemento</th><th>mm</th><th>Nota</th></tr>
{''.join(f'<tr><td>{a}</td><td>{b}</td><td>{c}</td></tr>' for a, b, c in rows)}</table>
<h2>5. Demanda / capacidad (ca_wide.m)</h2>
<p class="note">Placa: franjas (cota inferior, DG1 / ancho efectivo como RAM), no líneas de fluencia. Anclas y concreto: ca_calc.m con las anclas en la posición nueva.
En gris, filas informativas.</p>
{dc}
</body></html>"""

out = os.path.join(here, 'reports', 'anclas_anchas.html')
with open(out, 'w', encoding='utf-8') as f:
    f.write(html)
print(out)
