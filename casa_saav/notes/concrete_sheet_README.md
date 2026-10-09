# concrete_sheet (planos_conexiones)

One A1 landscape sheet (Spanish): `octave-cli casa_saav/concrete_sheet.m` -> `reports/planos_conexiones.pdf`.
Generator `sheets/make_concrete_sheet.m` (Octave -> JSON), printer `lib/printing/pour_pdf.py`.

Design numbers come from end_plate_column.m (C4, reports/end_plate_column_output.txt) and
sandwich_beam.m. D4X checked with Mu = 9 kNm, rows at 62 / 173, bastones at 98 (passes, 0.74).
Detail 2.4 drawn 108 mm high (was 120) so that column 2 fits the A1 page (2026-10-09).

Decisions taken while drawing (2026-10-07), to confirm with the user:
- Bastón pata drawn vertical (down, 200), not horizontal: a 12db = 144 tail does not fit
  between x = 82 and the column side cover (about 70 mm free).
- Joint ties Ø10 at 110 / 155 / 230 / 305 below the top of the beams; Ø14 ties at 10 and 40 above.
- Extra VCS bar: 4 bottom bars evenly spaced (1-2-1), extra one at +31, L = 1500 centred on F and G.
- Rods 5/8"-11 UNC A193 B7 (local thread), holes 18. A1 and A2 both L = 440 (+20 margin, user). Sandwich plates on 20 grout, with leveling nuts (4 nuts per A2).
