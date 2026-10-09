# joint_model: 3D pieces, clash check, views and quantities (Octave)

A joint described as pieces in 3D, so that one model gives the clash list, the
drawing views and the quantities. A connection library builds the model from
the same input P as its checks (first one: `lib/end_plate_concrete/model_end_plate_column.m`),
so the drawing cannot drift from the calculation.

```
jm_new           empty model (M.pc = list of pieces)
jm_bar           round piece along a 3D polyline: bar (bends rounded), rod, washer, nut
jm_box           box with faces parallel to the axes: plate, flange, web, grout, concrete
jm_clash         clear distance between pieces -> CLASH / spacing / contact / tight
jm_view          orthographic view or section -> lib/sheets items (blk_draw)
jm_quantities    count, length and steel mass by piece mark
jm_fillet3       round the corners of a 3D polyline
```

## Use
```
M = jm_new();
M = jm_bar(M, 'baston x=82', [82 280 72; 82 80 72; 82 80 1286], 12, struct('kind', 'rebar', 'r', 42, 'mark', 'BA'));
M = jm_box(M, 'P2', [-70 0 -42], [70 260 -30], struct('grp', 'P2', 'phase', 'after', 'style', 'r_eplate'));
F = jm_clash(M);                                   % prints the list, returns it
it = jm_view(M, {'x', 'z'}, struct('cut', [0 122]));   % plan, section between y = 0 and 122
T = jm_quantities(M);
```
Each piece carries: `grp` (assembly; pieces of the same grp are not checked
against each other), `touch` (assemblies it is meant to touch or go through),
`kind` (rebar, rod, nut, steel, grout, concrete), `new` (false = existing
context, checked only against new pieces), `qty`, `mark`, `desc`, `style`
(printer style), `phase` (before / after the pour). `help jm_bar` lists them.

## Clash classes
- CLASH: the solids overlap.
- spacing: two parallel bars (rebar or rods) closer than max(25, db1, db2,
  4/3 aggregate) — ACI 318-19 25.2.1 (dagg = 19 mm by default).
- contact: touching; normal for crossing bars that are tied together.
- tight: clear below 10 mm (information).

## Example
`casa_saav/end_plate_model.m`: joint C4, 78 pieces, sheet `reports/end_plate_model.pdf`.
