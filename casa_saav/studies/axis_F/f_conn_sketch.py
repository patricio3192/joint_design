"""Dimensioned sketch of the moment connection of axis F across VCS (f_conn.m), in Spanish:
writes axis_F/conexion_F.html. Numbers copied from f_conn.m / f_capacities.m: change both together.
s along F (north < 0 < south, VCS axis at 0), x across F (web at 0), z up (0 = top of VCS and of the IPE 160).
"""
import math
import os

# ---- geometry (mm) -----------------------------------------------------------------------------
BV, HV = 300, 350                      # VCS width (along F) and depth
COV, DST, DBV = 40, 10, 12             # VCS cover, stirrup, bars
H, B, TW, TF = 160, 82, 5.0, 7.4       # IPE 160
GAP, TP, BP, HP = 10, 12, 116, 180     # grout gap, end plate t, width, height
TS, WS, LAP = 12, 70, 120              # strap t, width, lap on each flange
LS = BV + 2 * (GAP + TP + LAP)         # strap length 590
DR, XR, ZR = 16, 35, -120              # rods
NUT_T, NUT_C = 14, 13.9                # M16 nut height, half across corners
SLAB, DECK = 110, 55
s_ep = BV / 2 + GAP                    # end plate inner face (towards VCS)
s_beam = s_ep + TP                     # beam end (outer face of the end plate)
s_far = 470                            # beams drawn up to here
s_strap = LS / 2
rod_end = s_beam + 3 + NUT_T + 8       # washer + nut + thread past the nut


class Svg:
    def __init__(s, x0, x1, y0, y1, k=1.2):
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

    def circ(s, x, y, r, fill, stroke='#333', sw=0.8):
        a, b = s.p(x, y)
        s.b.append(f'<circle cx="{a:.1f}" cy="{b:.1f}" r="{r*s.k:.1f}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')

    def line(s, x0, y0, x1, y1, col='#333', sw=0.8, dash=None):
        a, b = s.p(x0, y0); c, d = s.p(x1, y1)
        ds = f' stroke-dasharray="{dash}"' if dash else ''
        s.b.append(f'<line x1="{a:.1f}" y1="{b:.1f}" x2="{c:.1f}" y2="{d:.1f}" stroke="{col}" stroke-width="{sw}"{ds}/>')

    def text(s, x, y, t, anchor='start', size=15, col='#222', bold=False):
        a, b = s.p(x, y)
        fw = ' font-weight="bold"' if bold else ''
        s.b.append(f'<text x="{a:.1f}" y="{b:.1f}" font-size="{size}" fill="{col}" text-anchor="{anchor}"{fw}>{t}</text>')

    def lead(s, x0, y0, x1, y1, t, anchor='start', col='#222', bold=False):
        s.line(x0, y0, x1, y1, '#666', 0.6)
        s.text(x1 + (4 if anchor == 'start' else -4), y1 - 3, t, anchor, 15, col, bold)

    def arrow(s, x0, y0, x1, y1, col):
        s.line(x0, y0, x1, y1, col, 2.2)
        a = math.atan2(y1 - y0, x1 - x0); L = 12
        for da in (2.6, -2.6):
            s.line(x1, y1, x1 + L * math.cos(a + da), y1 + L * math.sin(a + da), col, 2.2)

    def dim(s, x0, y0, x1, y1, off, t=None, size=14):
        L = math.hypot(x1 - x0, y1 - y0); ux, uy = (x1 - x0) / L, (y1 - y0) / L; nx, ny = -uy, ux
        a0, b0, a1, b1 = x0 + nx * off, y0 + ny * off, x1 + nx * off, y1 + ny * off
        s.line(x0, y0, a0 + nx * 3, b0 + ny * 3, '#888', 0.5)
        s.line(x1, y1, a1 + nx * 3, b1 + ny * 3, '#888', 0.5)
        s.line(a0, b0, a1, b1, '#333', 0.7)
        for (a, b) in [(a0, b0), (a1, b1)]:
            s.line(a - 3 * (ux - nx), b - 3 * (uy - ny), a + 3 * (ux - nx), b + 3 * (uy - ny), '#333', 1.0)
        t = t if t is not None else '%g' % round(L, 1)
        X, Y = s.p((a0 + a1) / 2 + nx * 5, (b0 + b1) / 2 + ny * 5)
        ang = -math.degrees(math.atan2(uy, ux))
        if ang > 90 or ang <= -90:
            ang += 180
        s.b.append(f'<text x="{X:.1f}" y="{Y:.1f}" font-size="{size}" text-anchor="middle" '
                   f'transform="rotate({ang:.1f} {X:.1f} {Y:.1f})">{t}</text>')

    def svg(s):
        return (f'<svg viewBox="0 0 {s.w:.0f} {s.h:.0f}" width="100%" style="max-width:{s.w:.0f}px" '
                f'xmlns="http://www.w3.org/2000/svg" font-family="Helvetica,Arial,sans-serif">' + ''.join(s.b) + '</svg>')


CONC, STEEL, IPE, STRAP, ROD, NUT, BAR, GROUT, WELD = '#ece8df', '#9fb3c8', '#5d7b99', '#e08e2b', '#c0392b', '#7a1f17', '#1a5276', '#cfc6b4', '#111'


def ipe_side(s, s0, s1):
    """IPE 160 seen from the side between s0 and s1 (flanges dark, web light)."""
    lo, hi = min(s0, s1), max(s0, s1)
    s.rect(lo, -H, hi, 0, '#c9d6e3', '#1f3347', 0.6)
    s.rect(lo, -TF, hi, 0, IPE, '#1f3347')
    s.rect(lo, -H, hi, -H + TF, IPE, '#1f3347')


def elevation():
    s = Svg(-560, 820, -400, 225, 0.85)
    # slab (later) and VCS
    s.rect(-s_far, 0, s_far, SLAB, '#f4f1ea', '#aaa', 0.6, dash='4 3')
    s.text(-s_far + 10, SLAB - 18, 'losa (después)', 'start', 14, '#777')
    s.rect(-BV/2, -HV, BV/2, 0, CONC, '#555')
    a = COV + DST/2
    s.rect(-BV/2 + a, -HV + a, BV/2 - a, -a, 'none', '#7d3c98', 1.6)          # stirrup
    for x in (-BV/2 + COV + DST + DBV/2, 0, BV/2 - COV - DST - DBV/2):
        for z in (-COV - DST - DBV/2, -HV + COV + DST + DBV/2):
            s.circ(x, z, DBV/2, BAR, '#0e2f44')
    # grout gaps, end plates, beams
    for sg in (-1, 1):
        s.rect(sg * BV/2, -HP, sg * s_ep, 0, GROUT, '#999', 0.5)
        s.rect(sg * s_ep, -HP, sg * s_beam, 0, STEEL, '#1f3347')
        ipe_side(s, sg * s_beam, sg * s_far)
        s.line(sg * s_far, 30, sg * s_far, -H - 30, '#666', 0.8, '6 3')
    # rods and nuts
    s.rect(-rod_end, ZR - DR/2, rod_end, ZR + DR/2, ROD, '#7a1f17')
    for sg in (-1, 1):
        s.rect(sg * s_beam, ZR - 12, sg * (s_beam + 3 + NUT_T), ZR + 12, NUT, '#4a120c')
    # strap and its welds on the flanges
    s.rect(-s_strap, 0, s_strap, TS, STRAP, '#7a4a10')
    for sg in (-1, 1):
        s.line(sg * s_beam, TS + 1, sg * s_strap, TS + 1, WELD, 2.4)
    # forces (hogging both sides)
    s.arrow(-s_strap - 40, TS / 2, -s_strap - 160, TS / 2, '#c0392b')
    s.arrow(s_strap + 40, TS / 2, s_strap + 160, TS / 2, '#c0392b')
    s.arrow(-s_beam - 140, -H + TF/2, -s_beam - 20, -H + TF/2, '#1f6fb2')
    s.arrow(s_beam + 140, -H + TF/2, s_beam + 20, -H + TF/2, '#1f6fb2')
    s.text(-s_strap - 100, TS + 14, 'T = 113 kN', 'middle', 15, '#c0392b', True)
    s.text(s_strap + 100, TS + 14, 'T = 89 kN', 'middle', 15, '#c0392b', True)
    s.text(-s_beam - 80, -H - 22, 'C', 'middle', 15, '#1f6fb2', True)
    s.text(s_beam + 80, -H - 22, 'C', 'middle', 15, '#1f6fb2', True)
    # labels
    s.lead(-40, TS, -300, 190, 'Pletina superior PL 12×70×%g: lleva la tracción por encima de VCS' % LS, 'start', '#7a4a10', True)
    s.lead(s_beam - 6, -60, 200, -250, 'Placa extremo PL 12×116×180, soldada a la IPE: empuja contra VCS', 'start', '#1f3347', True)
    s.lead(0, ZR, 200, -210, '2 varillas Ø16 roscadas M16, pasantes, coladas con VCS: corte', 'start', '#a93226', True)
    s.lead(BV/2 + GAP/2, -170, 200, -290, 'Mortero sin retracción o lainas, 10', 'start', '#666')
    s.text(-s_far + 20, -H/2, 'IPE 160 norte', 'start', 15, '#fff', True)
    s.text(-s_far + 20, -H/2 - 16, '(viene de la IPE 200)', 'start', 14, '#fff')
    s.text(s_far - 20, -H/2, 'IPE 160 sur', 'end', 15, '#fff', True)
    s.text(s_far - 20, -H/2 - 16, '(volado al borde)', 'end', 14, '#fff')
    s.text(0, -HV - 22, 'VCS 30×35 (eje 4), cortada', 'middle', 15, '#333', True)
    s.lead(s_beam + 60, TS + 1, 330, 150, 'filetes 6 (pletina sobre el ala)', 'start', '#111')
    # dimensions
    s.dim(-BV/2, -HV, BV/2, -HV, -55, '%g' % BV)
    s.dim(-s_strap, TS, s_strap, TS, 70, '%g' % LS)
    s.dim(s_beam, TS, s_strap, TS, 38, '%g' % LAP)
    s.dim(BV/2, -HP, s_ep, -HP, -18, '%g' % GAP)
    s.dim(s_ep, -HP, s_beam, -HP, -38, '%g' % TP)
    s.dim(-s_beam - 30, 0, -s_beam - 30, -HP, 0, '%g' % HP)
    s.dim(-BV/2 - 70, 0, -BV/2 - 70, ZR, 0, '%g' % -ZR)
    s.dim(BV/2 + 60, 0, BV/2 + 60, TS, 0, '%g' % TS)
    s.dim(-rod_end, ZR - 60, rod_end, ZR - 60, 0, '%.0f' % (2 * rod_end))
    s.dim(s_far + 30, 0, s_far + 30, -H, 0, '160')
    return s.svg()


def plan():
    s = Svg(-560, 820, -250, 230, 0.85)
    s.rect(-BV/2, -220, BV/2, 220, CONC, '#555')
    s.text(0, 200, 'VCS', 'middle', 15, '#333', True)
    for sg in (-1, 1):
        s.rect(sg * BV/2, -BP/2, sg * s_ep, BP/2, GROUT, '#999', 0.5)
        s.rect(sg * s_ep, -BP/2, sg * s_beam, BP/2, STEEL, '#1f3347')
        lo, hi = sorted((sg * s_beam, sg * s_far))
        s.rect(lo, -B/2, hi, B/2, IPE, '#1f3347')
        s.line(sg * s_far, -70, sg * s_far, 70, '#666', 0.8, '6 3')
    for x in (-XR, XR):
        s.rect(-rod_end, x - DR/2, rod_end, x + DR/2, 'none', ROD, 1.0, dash='4 3')
    s.rect(-s_strap, -WS/2, s_strap, WS/2, STRAP, '#7a4a10')
    for sg in (-1, 1):
        lo, hi = sorted((sg * s_beam, sg * s_strap))
        for x in (-WS/2, WS/2):
            s.line(lo, x, hi, x, WELD, 2.6)
        s.line(sg * s_strap, -WS/2, sg * s_strap, WS/2, WELD, 2.6)
    s.lead(-s_strap + 40, WS/2, -540, 160, 'Pletina 70 de ancho, sobre las alas superiores (82)', 'start', '#7a4a10', True)
    s.lead(s_beam + 70, WS/2, 260, 120, 'Filetes 6: dos bordes (120 c/u) y punta (70)', 'start', '#111')
    s.lead(0, XR, 40, -200, 'Varillas Ø16 debajo (discontinuas), a ±35 del eje de F', 'start', '#a93226')
    s.dim(-s_strap, -WS/2, -s_strap, WS/2, 22, '%g' % WS)
    s.dim(s_far, -B/2, s_far, B/2, -24, '%g' % B)
    s.dim(-s_beam - 20, -BP/2, -s_beam - 20, BP/2, 0, '%g' % BP)
    s.dim(s_beam, -WS/2, s_strap, -WS/2, -22, '%g' % LAP)
    s.dim(BV/2 + 120, -XR, BV/2 + 120, XR, 0, '%g' % (2 * XR))
    return s.svg()


def endview():
    s = Svg(-330, 560, -260, 90)
    s.rect(-250, -HV, 250, 0, CONC, '#999', 0.5, dash='4 3')
    s.text(-240, -HV + 12, 'cara de VCS (detrás)', 'start', 14, '#777')
    s.rect(-BP/2, -HP, BP/2, 0, STEEL, '#1f3347')
    s.rect(-B/2, -TF, B/2, 0, IPE, '#1f3347')
    s.rect(-B/2, -H, B/2, -H + TF, IPE, '#1f3347')
    s.rect(-TW/2, -H + TF, TW/2, -TF, IPE, '#1f3347')
    s.rect(-WS/2, 0, WS/2, TS, STRAP, '#7a4a10')
    for x in (-XR, XR):
        s.circ(x, ZR, NUT_C, NUT, '#4a120c')
        s.circ(x, ZR, DR/2, ROD, '#7a1f17')
    s.dim(-BP/2, -HP, BP/2, -HP, -20, '%g' % BP)
    s.dim(-XR, ZR, XR, ZR, -30, '%g' % (2 * XR))
    s.dim(BP/2, 0, BP/2, -HP, -20, '%g' % HP)
    s.dim(BP/2 + 50, 0, BP/2 + 50, ZR, 0, '%g' % -ZR)
    s.dim(-WS/2, TS, WS/2, TS, 18, '%g' % WS)
    s.lead(BP/2, -40, 200, 40, 'Placa extremo PL 12×116×180', 'start', '#1f3347', True)
    s.lead(XR + 10, ZR, 200, -90, '2 varillas Ø16 con tuerca M16 y arandela', 'start', '#a93226', True)
    s.lead(WS/2, TS/2, 200, 75, 'Pletina superior PL 12×70', 'start', '#7a4a10', True)
    s.lead(0, -H/2, 200, -200, 'IPE 160 (cortada junto a la placa)', 'start', '#1f3347')
    return s.svg()


html = f"""<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Conexión eje F</title>
<style>body{{font-family:Helvetica,Arial,sans-serif;max-width:1150px;margin:24px auto;padding:0 16px;color:#222;background:#fff}}
h1{{font-size:22px}}h2{{font-size:17px;margin-top:26px}}.fig{{border:1px solid #ddd;padding:8px;margin:10px 0}}
p,li{{font-size:15px;line-height:1.5}}</style></head><body>
<h1>Eje F: conexión de las dos IPE 160 a través de VCS</h1>
<p>Las dos IPE 160 (la del norte, que viene de la IPE 200, y la del sur, el volado) llegan a VCS desde lados opuestos.
Las dos tienen momento negativo en VCS: <b>arriba tracción, abajo compresión</b>. La conexión hace que trabajen como una sola viga continua
que pasa por encima de VCS, sin torcer la viga de hormigón:</p>
<ul>
<li><b>Tracción (arriba): pletina superior</b> PL 12×70×{LS:.0f} A36. Es una platina que se apoya sobre VCS y sobre las alas superiores de las dos IPE,
soldada a cada ala con filetes de 6 mm (120 mm de traslape a cada lado). La tracción de un ala pasa por la pletina a la otra ala. Queda 12 mm por encima de la cara superior de VCS, debajo de la losa.</li>
<li><b>Compresión (abajo): placa extremo</b> PL 12×116×180 A36 soldada a la punta de cada IPE. El ala inferior empuja la placa contra la cara de VCS, con 10 mm de mortero sin retracción o lainas entre medio.</li>
<li><b>Corte: 2 varillas Ø16</b> roscadas (M16), pasantes, que se dejan coladas en VCS (como las varillas AV de las IPE 200). Atraviesan las dos placas extremo y llevan tuerca y arandela por fuera.</li>
</ul>
<h2>1. Corte a lo largo del eje F (VCS cortada)</h2><div class="fig">{elevation()}</div>
<h2>2. Planta</h2><div class="fig">{plan()}</div>
<h2>3. Vista desde la viga (placa extremo)</h2><div class="fig">{endview()}</div>
<p>Medidas en mm. Fuerzas mayoradas (envolvente de las dos corridas de ETABS): M = 18.3 (norte) / 14.5 (sur) kN m, V = 16.3 / 14.2 kN.
Mayor D/C: placa extremo 0.90, ala superior de la IPE 0.89, pletina 0.60 (detalle en conn_results.txt).</p>
</body></html>"""

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'conexion_F.html')
with open(out, 'w', encoding='utf-8') as f:
    f.write(html)
print(out)
