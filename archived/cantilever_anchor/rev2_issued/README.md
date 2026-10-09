# Cantilever anchorage: steel beam on a concrete pedestal

Design of the connection of IPE 200 steel cantilevers to 40x40 cm concrete
pedestals, for an edge column (one beam) and a corner column (two orthogonal
beams), plus the workshop sheets of the embedded assemblies.
ACI 318-19 (318S-14 equivalents noted), AISC 360-16, NEC-SE-DS. LRFD.
Everything runs in Octave with MATLAB-only syntax.

Status (2026-09-30): design complete, report and workshop sheets issued.
The assemblies are cast with the joint; the beams are welded on site afterwards.

Location: `~/scripting/structures/joint_calculations/cantilever_anchor` (moved there
2026-10-01 from `~/scripting/cantilever_anchor`; untracked, listed in the repo's
.gitignore).

Variant under review (pour delayed): `../cantilever_anchor_V2/` (IPE 240, two platinas
with the centre free, Ø12 anchors, one load path, anchorage checked with the
ACI placing tolerances, plate-bending proof). It has its own README and
report; the files of this folder are unchanged. A third concept, through-rods
with a bolted end plate, is set up in `../cantilever_anchor_double_plate/`
(README only).

## Run

```
octave-cli t1_cantilever_anchor.m    # checks + reports/cantilever_anchor_report.html
octave-cli t2_planos_taller.m        # A4 workshop sheets, Spanish: reports/planos_taller_anclajes.pdf
```

`t1` prints the demands and the full limit-state table (D/C for edge,
corner with the user's trapezoid, corner envelope). The report is one HTML
file with all drawings inline (SVG). `t2` writes a JSON and prints it with
`../python_support_scripts/joint_pdf.py`
(the user's printer, reused unchanged; needs python3-reportlab).

## Files

```
cantilever_anchor/
  t1_cantilever_anchor.m   MAIN: checks and HTML report
  t2_planos_taller.m       MAIN: workshop sheets; EDIT here: counts per type (opts.n = [E C1 C2]), title block
  ca_inputs.m              EDIT: materials, loads, every dimension (single source of truth)
  ca_calc.m                loads, forces, all limit states; R.rows is the limit-state table
  ca_draw.m                report drawings as SVG strings (plans, elevations, details, force diagrams)
  ca_report.m              HTML report; every number is read from R, nothing typed by hand
  make_workshop_sheets.m   workshop sheets: quantities, bar shapes, notes, 3 type sheets
  reports/                 generated outputs (report, sheets PDF + JSON)
```

## Conventions

- Units N, mm, MPa inside; kN, m in loads and printed results.
- z: from the top of the concrete beam = top of the steel beam, upwards.
  u: from the outer face of the column (= outer face of the embed plate),
  into the column. v: across, from the beam axis.
- Cases (R.kase): 1 edge, 2 corner with the user's trapezoid, 3 corner
  envelope (whole corner square on one beam).
- Rows of R.rows: {group, name, reference, demand(1x3), strength(1x3), unit, flag};
  flag 'info' = shown, not relied upon; 'frame' = needs frame forces.

## The design (final)

- Embed plate PL 12x220x260, A36, cast flush in the outer face of the pedestal.
  Punch marks for the beam axis and the top of the flange.
- Platina superior PL 12x110x30 behind the top flange (tension transfer and
  shear key); platina inferior, same piece, behind the bottom flange.
- Anchor bars Ø16, weldable, 90° hooks turned down:
  - E (edge): 2 V1 under the platina (258 x 256) + 2 V2 over it (338 x 256), v = ±35.
  - C1 (corner, first beam): 2 V2 under the platina.
  - C2 (corner, second beam): 2 V2 over the platina. X and Y bars cross 12 mm apart.
- Welds (shop): one continuous 8 mm bead joins plate, platina and bar ends;
  bars to platina: groove filled flush + 6 mm fillet, 25 mm, both sides;
  platina inferior 6 mm. Beam to plate (site): 8 mm all round the flanges,
  5 mm both sides of the web.
- Anchor reinforcement = top bars of the concrete beam in line, hooked down at
  the outer face (VCM: 5 Ø12, pairs separated in the joint; VCS: 3 Ø12).
- Joint ties: 4 layers (z = -90, -135, -180, -225), 4 straight Ø10 per layer
  with 135° hooks around the corner bars, + 1 closed tie at z = +45.
- Ordered: 1 E, 1 C1, 3 C2.

Governing ratios (report section 4): bead around the bar ends alone 0.89 and
side welds alone 0.90 (corner envelope); hook embedment from the end of the
platina 0.91 (edge, conservative measure); beam bars inside the breakout body
0.88; VCS bars as anchor reinforcement 0.77.

## Assumptions and open items

- Ordinary moment frame (confirmed): joint ties per ACI 15.3, not 18.8.
- Frame moments were given only for the edge pedestal (1.2D + L - Ex) and are
  added at right angles to the cantilever moment. The concrete beams' own
  support moments were never received: the report gives the room left
  (VCM about 32 kN m, VCS about 16 kN m).
- Column bars must end in 90° hooks at the top (site).
- The platina ends 8 mm from the mid-face column bar; the site nudges that bar if needed.
- Weldable rebar (A706 / INEN 2167) assumed; check the mill certificate for preheat.
- AWS D1.4 was not available to check; rules quoted from memory are flagged as such.

## Notes for humans and future agents

How the user works (also in Claude's memory for this project):
- Metric only. MATLAB syntax, run in Octave. Ask before changing their own
  code and keep their style. This folder is new code written for them.
- They check everything with the books in hand: every equation needs the
  clause number, verified against the PDFs in
  `/mnt/c/Users/winpat/Desktop/Bibliography4structures/02 NORMATIVAS/`
  (ACI 318-19 is inch-pound: use its Appendix E for the SI forms).
  `pdftotext -layout` + grep works on all of them.
- Drawings: they want many, with dimensions; geometry mistakes are their main
  worry. There is no browser on this machine: render SVG with
  `mutool draw -o x.png x.svg` and look at it; render PDF pages the same way.
- Workshop sheets in Spanish, short direct sentences, no condescending
  instructions (do not tell the shop how to hold or flip a piece), no
  calculation remarks on workshop sheets, no electrode class.
- "Margin of safety is the priority": prefer the literal, conservative reading
  of a code clause, and say so when an assumption is optimistic.

## What was hard, error prone, important

Hard
- The force path behind the plate. Three welded pieces (plate, platina, bars)
  give two parallel paths for the pull, and the split between them cannot be
  computed reliably. Resolved by making each path carry all of T alone: the
  bead around the bar ends (path A), and platina + side welds (path B).
- Congestion. Pedestal bars, beam bars in two layers, base-plate rods,
  anchor tails, ties: everything had to be placed to the millimetre, with
  clearances of 8 mm in several places. Only the drawings revealed most conflicts.
- Construction sequence: column already cast to the beam soffit (no room below
  for hooks), ties that cannot be slid into an already tied cage, a pour the
  next day.

Error prone (mistakes actually made and caught, in order)
1. Assumed 4 column bars; the pedestal has 8. The mid-face bar hit the lug.
2. The lugs of the two corner assemblies overlapped; found only in the plan.
3. L bars in two layers collided where they crossed; found in an elevation.
4. Hook vertical leg written as 264 instead of 16 db = 256 (cut lengths wrong).
5. Bundled bar pairs (VCM layout 2-1-2): ACI does not cover a hooked bundle
   (R25.6.1.5); the pairs must be separated in the joint.
6. Lug-to-plate weld counted over its full length although the bars sit on it.
7. Directional factor 1.5 (AISC J2-5) used outside its scope (non-linear weld
   groups), and J2.4(c) used with two leg sizes. Both removed.
8. Corner anchor force computed with the flange lever arm; the bars sit 14 mm
   below the flange line, so the real force is 8 % higher.
9. ACI 17.11 (shear lug) needs 4 anchors; the corner has 2, so there the bars
   carry the shear.
10. Joint shear SI coefficient rounded up (1.3 instead of 1.25).
11. Drawing artefacts a worker would misread: welds drawn on top of bars that
    are underneath; the ring weld drawn into the platina.
12. (found 2026-09-30, after issue) psi_c of the hooks written from memory as
    f'c/105 + 0.6; the SI form in ACI 318-19 Appendix E is 0.01 f'c + 0.6.
    Edge hook ldh 205 -> 207.6 mm, ratio 0.90 -> 0.91. Report regenerated;
    workshop sheets unaffected.

Important
- Concrete breakout of ACI chapter 17 cannot work in a 40 cm pedestal (about
  35 kN against 100 kN). The design relies on anchor reinforcement (17.5.2.1)
  and on hook development; the beam top bars must be hooked at the outer face.
- Every number in the report and every dimension in the drawings come from
  ca_inputs.m. After a change, rerun both scripts and check the
  clearance-sensitive figures (plans, plate view, detail x.5) by eye.
- When the user asks "are you sure?", look for code clauses applied outside
  their stated scope; that is where items 5 to 10 came from.

Weak links (smallest margin or softest assumption)
- Bead around the bar ends alone and side welds alone: 0.89 / 0.90 (corner envelope).
- Hook embedment of the edge V1 bars measured from the end of the platina: 0.91.
- Beam bars inside the breakout body (geometric check, conservative apex): 0.88.
- Plate bending from the 14 mm offset assumes the full 220 mm plate width
  (0.61); about 0.9 with a narrow strip. Not governing, because path B carries T alone.
- Site execution: hooks at the top of the column bars, separated bar pairs,
  ties bent in place, platina level ± 3 mm, quality of the ring weld around
  each bar end.
