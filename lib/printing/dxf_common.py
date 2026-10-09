"""Shared by json_dxf.py and armar_lamina.py: DXF document setup, layers, line types,
dimension styles and text, in millimetres.

Conventions
  * Paper sizes (text heights, dash lengths, dimension text) are given in paper mm.
    A detail drawn at 1:N carries them multiplied by N, as in AutoCAD model space.
  * Dimension styles are named COTAS_1-N (DIMSCALE = N); COTAS_PAPEL has DIMSCALE = 1.
    LibreCAD reads the header variables rather than the dimension style, so a detail
    file also carries $DIMSCALE = N and $LTSCALE = N.
"""
import ezdxf
from ezdxf import colors

PT = 25.4 / 72          # mm per point
CAP = 0.72              # cap height / font size (Helvetica): DXF text height is the cap height
FONT = {"normal": ("ESTANDAR", "arial.ttf"), "bold": ("NEGRITA", "arialbd.ttf")}
# LibreCAD has no Arial: it draws every text in its own font, about 13 % wider than
# Helvetica.  Texts carry this width factor so they take the PDF's room in LibreCAD;
# armar_lamina.py divides it out of the AutoCAD sheet, which does use Arial.
WIDTH = 0.885

# dimension text and marks on paper, mm (as joint_pdf._dim draws them)
DIM = {"dimtxt": 7.2 * PT * CAP, "dimtsz": 2.2 * 1.41 * PT, "dimexo": 1.5 * PT, "dimexe": 2.5 * PT,
       "dimgap": 0.6, "dimasz": 2.0}

_LW = [0, 5, 9, 13, 15, 18, 20, 25, 30, 35, 40, 50, 53, 60, 70, 80, 90, 100, 106, 120, 140,
       158, 200, 211]


def new_doc():
    doc = ezdxf.new("R2010", setup=False, units=4)       # mm
    doc.header["$MEASUREMENT"] = 1
    doc.header["$LWDISPLAY"] = 1
    doc.header["$PSLTSCALE"] = 1
    for key, (name, ttf) in FONT.items():
        doc.styles.new(name, dxfattribs={"font": ttf})
    return doc


def lineweight(pt):
    """Line width in points -> nearest DXF lineweight (1/100 mm)."""
    mm100 = pt * PT * 100
    return min(_LW, key=lambda v: abs(v - mm100))


def rgb(h, op=1.0):
    """'#RRGGBB' -> (r, g, b), blended with white for an opacity below 1."""
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) for i in (0, 2, 4)]
    return tuple(round(op * v + (1 - op) * 255) for v in c)


def aci(c):
    """Nearest AutoCAD colour index, for programs that ignore true colour."""
    best, dmin = 7, 1e9
    for i in range(1, 256):
        r, g, b = colors.aci2rgb(i)
        d = (r - c[0]) ** 2 + (g - c[1]) ** 2 + (b - c[2]) ** 2
        if d < dmin:
            best, dmin = i, d
    return best


def color_attribs(c):
    return {"color": aci(c), "true_color": colors.rgb2int(c)}


def linetype(doc, dash):
    """Line type for a dash pattern in points (on, off, on, off...), in paper mm."""
    if not dash:
        return "Continuous"
    name = "TRAZO_" + "-".join(f"{d:g}" for d in dash).replace(".", "p")
    if name not in doc.linetypes:
        el = [d * PT * (1 if i % 2 == 0 else -1) for i, d in enumerate(dash)]
        doc.linetypes.add(name, pattern=[sum(abs(e) for e in el)] + el,
                          description="trazo " + " ".join(f"{d:g}" for d in dash))
    return name


def layer(doc, name, hexcol="#222222", width_pt=0.5, dash=None, op=1.0):
    if name in doc.layers:
        return name
    c = rgb(hexcol or "#222222", op)
    lay = doc.layers.add(name, color=aci(c), linetype=linetype(doc, dash))
    lay.rgb = c
    lay.dxf.lineweight = lineweight(width_pt)
    return name


def dimstyle(doc, N):
    """COTAS_1-N (N = 1: COTAS_PAPEL): architectural ticks, text above the line."""
    name = "COTAS_PAPEL" if N == 1 else f"COTAS_1-{N:g}"
    if name not in doc.dimstyles:
        attrs = dict(DIM, dimscale=N, dimtad=1, dimdec=0, dimzin=8, dimtih=0, dimtoh=0,
                     dimtxsty=FONT["normal"][0], dimclrd=8, dimclre=8, dimclrt=250,
                     dimlwd=lineweight(0.45), dimlwe=lineweight(0.35), dimatfit=3)
        doc.dimstyles.new(name, dxfattribs=attrs)
    return name


def header_scale(doc, N):
    """Header variables that LibreCAD uses instead of the dimension style."""
    doc.header["$DIMSCALE"] = N
    doc.header["$LTSCALE"] = N
    doc.header["$DIMTSZ"] = DIM["dimtsz"]
    doc.header["$DIMTXT"] = DIM["dimtxt"]
    doc.header["$DIMEXO"] = DIM["dimexo"]
    doc.header["$DIMEXE"] = DIM["dimexe"]
    doc.header["$DIMGAP"] = DIM["dimgap"]
    doc.header["$DIMTAD"] = 1
    doc.header["$DIMDEC"] = 0
    doc.header["$DIMSTYLE"] = dimstyle(doc, N)
