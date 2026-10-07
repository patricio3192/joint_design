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
- Nuts 5/8"-11 UNC heavy hex ASTM A194 2H (27 across flats); washers ASTM F436 (OD 33, 4 thick). Rod tip at 346.
- Welds beam - plate (detail 5): all in the field, E70XX; top flange CJP, bottom flange and web 6 fillets, none in the root radii.
- Edge beams IPE 160 on grids 9 and E. Slab: Novalosa 55 (1 mm) + 50 concrete = 105 over the beams, mesh 4.5-15
  (106 mm2/m >= 0.0018 x 50 x 1000 = 90, ACI 318-19 24.4.3.2; >= 0.00075 x 50 x 1000 = 38, SDI C-2017).
