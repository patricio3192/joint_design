# planos_conexiones

One A1 landscape sheet (Spanish): `octave-cli t_planos.m` -> `reports/planos_conexiones.pdf`.
Generator `make_sheet.m` (Octave -> JSON), printer `pour_pdf.py` (copied from
../cantilever_anchor_bolted_plate, uses ../python_support_scripts/joint_pdf.py, same colours).

Design numbers come from ../end_plate_concrete_column (C4, run_output.txt) and
../sandwiched_concrete_beam. D4X checked with Mu = 9 kNm, rows at 62 / 173, bastones at 98 (passes, 0.74).

Decisions taken while drawing (2026-10-07), to confirm with the user:
- Bastón pata drawn vertical (down, 200), not horizontal: a 12db = 144 tail does not fit
  between x = 82 and the column side cover (about 70 mm free).
- Joint ties Ø10 at 110 / 155 / 230 / 305 below the top of the beams; Ø14 ties at 10 and 40 above.
- Extra VCS bar: 4 bottom bars evenly spaced (1-2-1), extra one at +31, L = 1500 centred on F and G.
- Rods 5/8"-11 UNC A193 B7 (local thread), holes 18. A1 and A2 both L = 470 (grout 25; holds ±20 placement error with 2 threads past every nut). Plates on 25 grout, with leveling nuts (4 nuts per A2).
- Cover 40 to ties and over the Ø16 column hooks (ACI 318-19 Table 20.5.1.3.1, columns: 40; 20 is for slabs and walls only).
