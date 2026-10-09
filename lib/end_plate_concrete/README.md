# end_plate_concrete: steel end plate on a concrete column

Helper functions for a steel beam (IPE) with a flush end plate on cast-in
threaded rods (A193 B7) in a concrete column, the rods ending in head plates
inside the column ties, their tension taken by L bars ("bastones", ACI
17.5.2.1(a) anchor reinforcement) lapping into the beam. AISC 360-16, AISC
Design Guides 1 and 39, ACI 318-19 (SI). Equations and pages: `EQUATIONS.txt`.

```
check_end_plate_column.m every check, from an input struct P (fields listed in its help)
aci_tension_breakout.m   concrete breakout of cast-in anchors in tension (ACI 17.6.2)
aci_dev_lengths.m        tension development lengths of deformed bars (ACI 25.4)
dg1_bearing.m            compression side of the end plate bearing on concrete (DG1)
model_end_plate_column.m 3D model from the same P (and the check result R): lib/joint_model
views_end_plate_column.m section, front view and plan of that model, with the main dimensions
```
Also uses `lib/concrete_common` (iif, print_check).

## Use
```
addpath('lib/end_plate_concrete', 'lib/concrete_common');
P.load = struct('Mu_kNm', 12.1, 'Vu_kN', 14.1);  P.beam = ...;  % every field: help check_end_plate_column
R = check_end_plate_column(P);      % prints the report; R.checks, R.governing, R.ratio, R.hef, ...
```
`casa_saav/data/end_plate_C4.m` is a complete input (IPE 240 on a 40 x 40 column);
`casa_saav/end_plate_column.m` checks it and `casa_saav/end_plate_model.m` builds the
model, the clash list, the quantities and the pilot sheet from it:
```
M = model_end_plate_column(P, R);  F = jm_clash(M);  Q = jm_quantities(M);  V = views_end_plate_column(M, P, R);
```
