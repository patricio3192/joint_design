# end_plate_concrete: limits

- Moment with the top in tension and no reversal; shear down. Flush end plate,
  4 rods, head plates in the column, bastones as anchor reinforcement (all rod
  tension to the bars). Cracked concrete (psi_c = 1.0).
- Geometry fixed by the function: square column, 2 rods per row in 2 rows
  (tension row y_t from the top, shear row symmetric), plate centred on the
  column, bastones as the only path for rod tension (plain-concrete breakout is
  reported for information only), one concrete beam behind and crossing beams
  whose top bars sit one bar below it.
- Fixed values to watch when the case changes: AISC minimum edge 22 mm (Table
  J3.4M for M16), minimum fillet 5 mm (Table J2.4), futa capped at 860 MPa,
  Ase from a metric thread (pitch input), web shear by G2.1(a) only (it stops
  if h/tw is larger). Top flange weld is CJP.
- Not a general anchor-design library: no seismic (ACI 17.10) checks, no shear
  breakout toward an edge below (the column continues), no interaction 17.8.
- The joint (ACI Ch. 15) coefficient gamma is an input: the user must pick it
  from Table 15.4.2.3 for the actual confinement.
- The 3D model (model_end_plate_column) adds the same fixed layout: beam behind
  along z with hooked bars, crossing beams along x on both sides (3 bars per
  layer by default), square ties without their 135 deg hooks. Its clash list
  (lib/joint_model/jm_clash) is wider than module 2 of the check, which stays as
  it was so the saved output does not change.
- Verified 2026-10-09: casa_saav/end_plate_column.m (input in data/end_plate_C4.m) + this function
  reproduce casa_saav/reports/end_plate_column_output.txt byte for byte. Run it
  and compare after any change here.
