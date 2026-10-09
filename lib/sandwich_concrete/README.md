# sandwich_concrete: steel beams on both faces of a concrete beam

Helper functions for the "sandwich" moment connection: two steel beams (IPE)
frame into the two side faces of a concrete beam through flush end plates
tied together by through-rods cast in the concrete beam. AISC 360-16, AISC
Design Guides 1 and 39, ACI 318-19 (SI). Equations and pages: `EQUATIONS.txt`.

```
bearing_strips.m           compression side of an end plate bearing on concrete
conf_factor.m              sqrt(A2/A1) <= 2 for a loaded area on the beam side face
aci_shear_breakout.m       concrete breakout of anchors in shear (ACI 17.7.2)
aci_beam_shear_torsion.m   shear and torsion of the concrete beam and their steel (ACI 318-19 ch. 22)
aisc_f2_ltb.m              flexural strength of the steel beam, F2 with LTB
```
Also uses `lib/concrete_common` (iif, print_check).

The calculation itself is still the project script `casa_saav/sandwich_beam.m`
(input at the top, N-mm-MPa); it will become a function of this library.
