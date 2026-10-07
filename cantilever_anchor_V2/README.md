# Revision 3 (variant): IPE 240, two platinas, one load path

A variant of the issued design (revision 2, in `../cantilever_anchor`). Same concept:
embed plate flush with the pedestal face, platina behind the top flange,
hooked bars welded to it, and the top bars of the concrete beam as anchor
reinforcement. It removes the weak points of revision 2. The issued files
in `../cantilever_anchor` are untouched. (This folder was `cantilever_anchor/variant_r3` until 2026-10-01.)

Status (2026-09-30): calculation, report and report drawings done. Not
issued. Workshop sheets not made yet (`make_workshop_sheets.m` in `../cantilever_anchor`
is for revision 2).

## Run

```
cd cantilever_anchor_V2
octave-cli t1_cantilever_anchor.m    # checks + reports/cantilever_anchor_report.html
```

Run it from inside this folder: the function names are the same as in
`../cantilever_anchor`, and Octave takes the ones in the current folder.

## What changed from revision 2

| Item | Revision 2 | Revision 3 |
|---|---|---|
| Beam | IPE 200 | IPE 240 (T at the edge 99 -> 82.7 kN) |
| Embed plate | PL 12x220x260 | PL 12x220x300 |
| Platina | one PL 12x110x30, + the same under the bottom flange | two PL 12x76x70 behind the top flange, 40 mm apart (the mid-face column bar passes between them); nothing at the bottom flange |
| Anchors | Ø16; edge 4 (hooks at 270 and 350), corner 2 | Ø12, 4 per beam, all hooks at 350 |
| Edge (type E) | 2 under + 2 over at v = ±35 | 2 under at ±37 + 2 over at ±78 |
| Corner | C1: 2 under, C2: 2 over, v = ±35 | C1: 4 under, C2: 4 over, at ±37 and ±78 |
| Pull path | two in parallel (bead around the bar ends, platina + side welds) | one: plate -> platina fillets -> platinas -> side welds -> bars. Bars start 18 mm behind the plate, not welded to it |
| Side welds | 6 x 25 | 6 x 50 per side, ending at the end of the platina |
| Anchor reinforcement check | nominal positions | ACI placing tolerances applied against the design |
| Coating | none | grind the weld zones before the site weld; weldable primer optional |

## Results (report section 7)

- With every tolerance against the design at once, the highest ratio is
  0.95: the corner envelope, VCS anchor reinforcement. The edge is 0.92 if
  the VCM pairs are separated and 0.97 if they are left in contact. At
  nominal positions the same checks are 0.75 or less (revision 2: 0.88).
- Hook development of the anchors: 0.57 (revision 2: 0.90).
- 12 mm embed plate, lower-bound models (section 3 of the report):
  - through the thickness 0.18
  - over the 40 mm gap, simply supported 0.67 (fixed ends 0.33)
  - offset moment at the corner 0.66
  - bearing 0.33
- Platina root at the corner (tension + bending, H1) 0.75.
- Order of failure: the side welds develop 1.25 fy of the bars (0.64). At
  the corner the platina root yields before its fillets break (0.86;
  0.84 with Ry = 1.3 against the nominal weld strength).

## New in the code

- `ca_calc.m`:
  - one load path
  - plate checks 5a to 5e (through thickness, gap, offset strip, platina H1, strength order)
  - `cone()` with tolerances and `pick()`: it counts only the beam bars needed and chooses their number so the larger of the two ratios is smallest
  - `R.clr`, the clearance table
- `ca_draw.m`: new figures (2026-10-01: `fig_tol`, the beam-bar hooks the design counts on, with how far each may fall short; `C.short` in `ca_calc.m`):
  - `fig_path`: the one load path
  - `fig_plate_face`: where the forces enter the plate
  - `fig_plate_models`: the two bending models

  The other figures were rewritten for two platinas. `fig_trib`, `fig_hoops` and `fig_tie` and the drawing tools are copied unchanged.
- `ca_report.m`: rewritten. Section 3 is the plate-bending proof the user asked for. Section 4 is the anchorage with tolerances. Section 8 is the clearance table and the site notes, including coating and weld preparation.

## Assumptions to confirm

- Beam bars on the lower layer (-68) everywhere, because which beam is on top is not known.
- The centre bar of each beam is stopped behind the mid-face column bar (hook at u = 66).
- Both corner assemblies are checked against the 3-bar VCS beam.
- Column top hooks are not bent yet. The mid-face bars should hook along the steel beam, not across the anchors.
- Clearances of 10 to 12 mm remain between:
  - the platina and the mid-face column bar
  - the platina end and the base-plate rods
  - the outer bar and the base-plate rods
  - the X and Y bars at the corner

  They are listed in the report, section 8.

## Change log

2026-10-01:
- VCM layout corrected (user). The 5 top bars are 3 on the top line (0, ±94) plus 2 in contact
  **under** the corner bars. The bottom bars mirror this. The edge beams are VCS. The old
  "2-1-2, pairs separated at ±57" layout is gone.
- Only one bar of each stacked pair is counted as anchor reinforcement (a hooked bundle is
  outside ACI).
- Levels taken conservatively, since which beam is on top is not known: a VCM under a VCS sits at
  -68 / -80; a VCS under a VCM sits at -80.
- Anchors moved to |v| = 33 and 70, so the hook tails clear the beam top bars by 12 to 25 mm.
  Before, the gap was 4 mm.
- Hooks extended to u = 380, behind the far tie legs (user). The beam in line is behind the column,
  so no cover is needed there. ψo = 1.0 by side cover ≥ 6 db.
- Top joint tie layer moved -90 -> -95 to clear the stacked bars at -80.
- Placing figure rebuilt: plan from above, far side enlarged, section at the tails.
- Figures numbered with titles.
- Result: highest D/C 0.86 with every tolerance against the design (breakout check 0.81-0.85).
  Revision 2 rechecked with the real VCM layout: edge anchor reinforcement 0.93 instead of 0.56,
  breakout check 0.85-0.91 at nominal positions. It still passes.
- Correction (same day): with the hooks behind the far tie legs, the joint ties no longer enclose them
  (ACI 25.4.3.3), so ψr = 1.6. ℓdh of the anchors is now 216 mm instead of 150; with 293 mm available
  the D/C is 0.74. The "ties confining the anchor hooks" row is shown only if the hooks end inside the ties.
