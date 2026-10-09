# printing: sheet JSON -> PDF and editable DXF

Octave sheet scripts write a JSON (blocks: headings, paragraphs, tables and
drawings in model mm; see the docstring of `joint_pdf.py`). These scripts only
print it; every number and line of text comes from the JSON.

```
joint_pdf.py      JSON -> PDF (A4, A2 landscape)
pour_pdf.py       joint_pdf.py plus the concrete/rebar styles and A1 landscape
json_dxf.py       JSON -> editable DXF files (needs pip install ezdxf)
armar_lamina.py   rebuilds the assembled DXF sheets from the edited files
dxf_common.py     shared by the two DXF scripts
```

## Sheets as editable DXF (LibreCAD / AutoCAD)

```
python3 lib/printing/json_dxf.py casa_saav/reports/planos_uniones.json
python3 lib/printing/json_dxf.py casa_saav/reports/planos_conexiones.json \
        --printer lib/printing/pour_pdf.py        # sheets printed by pour_pdf.py
```

It writes `<sheet>_dxf/`:

```
detalles/NN_name.dxf   one drawing per file, 1:1 in real mm     <- edit these ("model space")
papel_N.dxf            border, title block, titles, notes and tables of sheet N,
                       in paper mm                               <- and these ("paper space")
lamina.json            which detail goes where on the sheet, at what scale (1:N)
lamina_librecad.dxf    the sheet assembled in model space: each detail a block at 1:N
lamina_autocad.dxf     details 1:1 in model space + a layout per sheet with viewports
```

After editing, rebuild the two assembled sheets (never edit those):

```
python3 lib/printing/armar_lamina.py casa_saav/reports/planos_conexiones_dxf/lamina.json
```

Layout and scales come from the PDF (each drawing gets the next standard scale
at or below the PDF's). Layers follow the drawing styles (`G-` shapes, `T-`
texts, `COTAS`, `SOLDADURA`, `LAMINA_*`). Dimensions are real DXF dimensions;
in the LibreCAD sheet they show the real length although the detail is
reduced. LibreCAD has no Arial and no bold: texts carry a width factor so they
take the PDF's room there, and the AutoCAD sheet (Arial, bold) undoes it.
`json_dxf.py` will not overwrite an existing `_dxf` folder (hand edits) unless
given `--overwrite`.
