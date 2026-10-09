# end_plate_concrete: steel end plate on a concrete column

Helper functions for a steel beam (IPE) with a flush end plate on cast-in
threaded rods (A193 B7) in a concrete column, the rods ending in head plates
inside the column ties, their tension taken by L bars ("bastones", ACI
17.5.2.1(a) anchor reinforcement) lapping into the beam. AISC 360-16, AISC
Design Guides 1 and 39, ACI 318-19 (SI). Equations and pages: `EQUATIONS.txt`.

```
aci_tension_breakout.m   concrete breakout of cast-in anchors in tension (ACI 17.6.2)
aci_dev_lengths.m        tension development lengths of deformed bars (ACI 25.4)
dg1_bearing.m            compression side of the end plate bearing on concrete (DG1)
```
Also uses `lib/concrete_common` (iif, print_check).

The calculation itself is still the project script `casa_saav/end_plate_column.m`
(input at the top, N-mm-MPa); it will become a function of this library.
