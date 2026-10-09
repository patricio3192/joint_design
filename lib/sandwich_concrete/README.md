# sandwich_concrete: steel beams on both faces of a concrete beam

Helper functions for the "sandwich" moment connection: two steel beams (IPE)
frame into the two side faces of a concrete beam through flush end plates
tied together by through-rods cast in the concrete beam. AISC 360-16, AISC
Design Guides 1 and 39, ACI 318-19 (SI). Equations and pages: `EQUATIONS.txt`.

```
check_sandwich_beam.m      every check, from an input struct P (fields listed in its help)
bearing_strips.m           compression side of an end plate bearing on concrete
conf_factor.m              sqrt(A2/A1) <= 2 for a loaded area on the beam side face
aci_shear_breakout.m       concrete breakout of anchors in shear (ACI 17.7.2)
aci_beam_shear_torsion.m   shear and torsion of the concrete beam and their steel (ACI 318-19 ch. 22)
aisc_f2_ltb.m              flexural strength of the steel beam, F2 with LTB
```
Also uses `lib/concrete_common` (iif, print_check).

## Use
```
addpath('lib/sandwich_concrete', 'lib/concrete_common');
P.load = struct('Mu_kNm', 23.5, 'Vu_kN', 21.5, 'Vu_other_kN', 9.5);  P.beam = ...;  % help check_sandwich_beam
R = check_sandwich_beam(P);         % prints the report; R.checks, R.governing, R.ratio, R.best_dist_bot, ...
```
`casa_saav/sandwich_beam.m` is a complete input (IPE 200 on a 30 x 35 beam).
