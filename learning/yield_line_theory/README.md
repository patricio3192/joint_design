# Yield-line theory: learning resource

A self-contained study page on yield-line (and lower-bound strip) analysis of
steel plates, written for the plate checks of `archived/cantilever_anchor/V2`.
Started 2026-10-01.

Open `yield_lines.html` in a browser (no internet needed: no external
libraries). Works in light and dark mode. Charts have hover tooltips and data
tables; three small calculators check hand calculations.

## Contents of the page

0. Where V2 stands (its plate checks are lower-bound strips, not yield lines)
1. The idea; 2. m_p = Fy t^2/4; 3. upper/lower bound theorems; 4. the work
   equation, the projection rule, the rules for valid patterns
5. strips (V2 step 3b worked with its numbers); 6. square and rectangular
   plates with brackets; 7. point loads and fans; 8. a load between two clamped
   edges (AISC Fig. C-J10.10), derived by hand = AISC 360-05 Eq. K2-13;
   9. T-stubs and prying (modes 1-3, AISC/Segui form); 10. end plates
   (DG 16 Table 3-2, AISC 358 Table 6.2)
11. V2 mapping table; 12. pitfalls; 13. formula sheet; 14. references with
   pages, all in `Bibliography4structures`; 15. how it was checked

## Checking code (MATLAB syntax, run in Octave)

```
cd yield_line_theory
octave-cli yl_verify.m
```

| File | What it does |
|---|---|
| `yl_work.m` | internal work of a mechanism from the deflection planes of its regions (slope jump across each line); also returns the deflection jump along each line, which must be 0 |
| `yl_volume.m` | volume under the deflected plate (external work of a unit uniform load) |
| `patchmech.m` | mechanism of AISC Fig. C-J10.10 (load c x bp between clamped edges) |
| `flushmech.m` | flush end plate, two bolts per row (DG 16 Table 3-2 pattern) |
| `lbcheck.m` | checks a lower-bound moment field: equilibrium, edge moments, Johansen / Tresca / von Mises |
| `yl_verify.m` | runs everything and prints every number used on the page |

## Findings worth remembering

- The work sum of the DG 16 flush pattern gives exactly the two main terms of
  Y; the published Y has an extra -bp/4 (about 3 % lower, safe side).
- The C-J10.10 mechanism with optimised e reproduces AISC 360-05 Eq. K2-13
  exactly. The same pattern without the transverse triangles is not a
  mechanism (the plate would tear); it gives P = 8 m_p (c + 2e)/L, which is too low.
- The Prager field (24 m_p/a^2 for a square plate) is admissible for the
  Johansen criterion but not for steel (Tresca 2.00, von Mises 1.73), so for a
  steel plate the safe bracket is 16 to 24 m_p/a^2.
- AISC's no-prying thickness (Segui eq. 7.18, alpha = 0) is the same mechanism
  as the mode 2/3 boundary, recalibrated with b' and Fu.

## Status

Done 2026-10-01. Not part of any issued calculation; the V2 code was not changed.
