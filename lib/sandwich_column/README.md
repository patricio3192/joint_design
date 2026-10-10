# sandwich_column: steel beams on both faces of a concrete column

Two steel beams (IPE) in one line frame into opposite faces of a concrete
column through flush end plates tied together by through-rods cast across the
column. It is the `sandwich_concrete` connection with a column instead of a
beam: the steel side and the bearing use the same equations and helpers; the
concrete side changes (no edge below for shear, joint shear of the column, the
opposite plate pressed by the rods). AISC 360-16, DG 39, DG 1, ACI 318-19 (SI).
Equations and pages: `EQUATIONS.txt`.

```
check_sandwich_column.m   every check, from an input struct P (fields in its help)
top_band_bearing.m        bearing of the band of the opposite plate around the tension rods
model_sandwich_column.m   3D model from the same P and R (lib/joint_model)
views_sandwich_column.m   section, front view and plan of the model, with dimensions
examples/                 example_sandwich_column.m: made-up input, report, clash list, A2 sheet
```
Uses `lib/sandwich_concrete` (bearing_strips, conf_factor, aisc_f2_ltb,
end_plate_welds), `lib/concrete_common`, and for the model `lib/joint_model`,
`lib/sheets`, `lib/profiles`.

## Use
```
P = ...;                                   % help check_sandwich_column; examples/ has a full input
R = check_sandwich_column(P);              % report; R.checks, R.governing, R.ratio, R.L_rod, ...
M = model_sandwich_column(P, R);  F = jm_clash(M);  Q = jm_quantities(M);
```
