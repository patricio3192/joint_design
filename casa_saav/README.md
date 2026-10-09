# casa_saav: Vivienda Edgar Ortega y familia

Steel connections of the house. Every script runs from any folder with
`octave-cli casa_saav/<script>.m` and writes to `reports/`.

## Scripts: one per connection type
```
collar_joints.m        beam to HSS column, external diaphragm collars (lib/collar_joint).
                       Steps switched on at the top: build (ETABS -> database), check,
                       details (collar_details.pdf), sheets (planos_uniones.pdf, A2),
                       compare (direct weld vs collar), equilibrium (diagnosis).
end_plate_column.m     IPE 240 cantilever, end plate on the concrete column C4: the input P,
                       checked by lib/end_plate_concrete/check_end_plate_column.m
sandwich_beam.m        IPE 200 to both faces of a concrete beam, through-rods: the input P,
                       checked by lib/sandwich_concrete/check_sandwich_beam.m
concrete_sheet.m       the A1 sheet of the two concrete connections
                       (planos_conexiones.pdf); drawing in sheets/make_concrete_sheet.m
```
Save the output of the two concrete calculations when they change:
`octave-cli casa_saav/end_plate_column.m > casa_saav/reports/end_plate_column_output.txt`
(same for sandwich_beam).

## Folders
```
data/       project input: joint_classes.m (what arrives at each joint),
            grid_lines.m (construction grid A B C D F / 5 1 6 2 3 7 4 8),
            gg.txt (ETABS export, NOT in git: copy it here), joint_db/ (generated)
sheets/     drawing scripts of project sheets (make_concrete_sheet.m: base for a
            future sheet template)
reports/    PDFs, their JSON, the calculation outputs, and <sheet>_dxf/ folders
            (editable DXF, see lib/printing/README.md)
notes/      plate summaries (PLACA) and open items (PENDIENTE) of the concrete connections
studies/    axis_F: north-south IPE line between grids B and C (study)
```

## Editable DXF of a sheet
```
python3 lib/printing/json_dxf.py casa_saav/reports/planos_conexiones.json --printer lib/printing/pour_pdf.py
python3 lib/printing/armar_lamina.py casa_saav/reports/planos_conexiones_dxf/lamina.json   # after editing
```
