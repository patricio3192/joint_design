#!/usr/bin/env python3
"""Assemble the sheets described in lamina.json from the detail and paper DXF files.

    python3 armar_lamina.py lamina.json [--modo librecad|autocad|ambos]

librecad  lamina_librecad.dxf: everything in model space at paper size (1 unit = 1 mm of
          paper), sheet after sheet.  Each detail is a block DET_<file> made from its file,
          scaled 1:N; dimensions show the real length, not the reduced one.
autocad   lamina_autocad.dxf: the details 1:1 in model space, and one layout ("Lamina 1"...)
          per sheet with the paper file and a viewport per detail at its scale.

Edit the files in detalles/ and papel_N.dxf, never the assembled sheets: they are rebuilt
from scratch each time.  lamina.json, written by json_dxf.py and editable by hand:
    {"hojas": [{"tamano": [w, h] paper mm, "papel": "papel_1.dxf",
                "detalles": [{"archivo": "detalles/01_x.dxf", "escala": N (1:N),
                              "base": [x, y] point of the detail (model mm),
                              "en": [x, y] where that point goes on the sheet (paper mm),
                              "ventana": [w, h] viewport size (paper mm, autocad only)}]}]}
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import dxf_common as C  # noqa: E402
import ezdxf  # noqa: E402
from ezdxf.addons import Importer  # noqa: E402
from ezdxf.math import Matrix44  # noqa: E402


def _import(path, doc, target):
    """Import the model space of a DXF file into target; returns the new entities."""
    src = ezdxf.readfile(path)
    before = {e.dxf.handle for e in target}
    imp = Importer(src, doc)
    imp.import_tables("*")
    imp.import_entities(list(src.modelspace()), target)
    imp.finalize()
    return [e for e in target if e.dxf.handle not in before]


def _dims_real_text(e, doc):
    """Linear dimension -> its text with the measured value written in, before scaling."""
    if e.dxftype() != "DIMENSION" or e.dimtype not in (0, 1):
        return
    t = e.dxf.get("text", "")
    if t not in ("", "<>") and "<>" not in t:
        return                                            # fixed text, or hidden (" ")
    ds = doc.dimstyles.get(e.dxf.dimstyle) if e.dxf.dimstyle in doc.dimstyles else None
    dec = ds.dxf.get("dimdec", 0) if ds else 0
    val = f"{e.get_measurement():.{dec}f}"
    e.dxf.text = val if t in ("", "<>") else t.replace("<>", val)


def _move(ents, M, dimstyle=None, arial=False):
    for e in ents:
        e.transform(M)
        if arial and e.dxftype() == "TEXT":
            e.dxf.width = e.dxf.get("width", 1) / C.WIDTH       # see dxf_common.WIDTH
        if e.dxftype() == "DIMENSION":
            if dimstyle:
                e.dxf.dimstyle = dimstyle
            e.override().render()


def librecad(spec, root, dst):
    doc = C.new_doc()
    C.header_scale(doc, 1)
    paper_ds = C.dimstyle(doc, 1)
    msp = doc.modelspace()
    C.layer(doc, "DETALLES", "#222222", 0.25)
    used = set()
    for i, h in enumerate(spec["hojas"]):
        dx = i * (h["tamano"][0] + 100)
        _move(_import(os.path.join(root, h["papel"]), doc, msp), Matrix44.translate(dx, 0, 0))
        for d in h["detalles"]:
            name = "DET_" + os.path.splitext(os.path.basename(d["archivo"]))[0]
            while name in used:
                name += "_"
            used.add(name)
            blk = doc.blocks.new(name)
            ents = _import(os.path.join(root, d["archivo"]), doc, blk)
            for e in ents:
                _dims_real_text(e, doc)
            bx, by = d["base"]
            _move(ents, Matrix44.chain(Matrix44.translate(-bx, -by, 0), Matrix44.scale(1 / d["escala"])),
                  paper_ds)
            msp.add_blockref(name, (d["en"][0] + dx, d["en"][1]), dxfattribs={"layer": "DETALLES"})
    doc.saveas(dst)


def autocad(spec, root, dst):
    doc = C.new_doc()
    doc.header["$DIMSCALE"] = 1
    doc.header["$LTSCALE"] = 1
    msp = doc.modelspace()
    C.layer(doc, "VENTANAS", "#9E9E9E", 0.25)
    doc.layers.get("VENTANAS").dxf.plot = 0
    lab = C.layer(doc, "MODELO_ROTULOS", "#9E9E9E", 0.25)
    doc.layers.get(lab).dxf.plot = 0
    y = 0
    for i, h in enumerate(spec["hojas"]):
        lay = doc.layouts.new(f"Lamina {i + 1}")
        lay.page_setup(size=tuple(h["tamano"]), margins=(0, 0, 0, 0), units="mm")
        _move(_import(os.path.join(root, h["papel"]), doc, lay), Matrix44(), arial=True)
        x, row = 0, 0
        for d in h["detalles"]:
            N = d["escala"]
            vw, vh = d["ventana"]
            cx, cy = x + vw * N / 2, y - vh * N / 2
            bx, by = d["base"]
            _move(_import(os.path.join(root, d["archivo"]), doc, msp),
                  Matrix44.translate(cx - bx, cy - by, 0), arial=True)
            msp.add_text(f"{d['archivo']}  1:{N:g}", height=5 * N,
                         dxfattribs={"layer": lab, "style": C.FONT["bold"][0]}).set_placement((x, y + 4 * N))
            lay.add_viewport(center=tuple(d["en"]), size=(vw, vh), view_center_point=(cx, cy),
                             view_height=vh * N, dxfattribs={"layer": "VENTANAS"})
            x += vw * N * 1.15
            row = max(row, vh * N)
        y -= row * 1.3 + 1000
    if "Layout1" in doc.layouts:
        doc.layouts.delete("Layout1")
    doc.saveas(dst)


def build(path, modo="ambos"):
    root = os.path.dirname(os.path.abspath(path))
    with open(path, encoding="utf-8") as f:
        spec = json.load(f)
    for m, fn in (("librecad", librecad), ("autocad", autocad)):
        if modo in (m, "ambos"):
            dst = os.path.join(root, f"lamina_{m}.dxf")
            fn(spec, root, dst)
            print(f"  {dst}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("lamina")
    ap.add_argument("--modo", choices=["librecad", "autocad", "ambos"], default="ambos")
    a = ap.parse_args()
    build(a.lamina, a.modo)
