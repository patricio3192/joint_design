# Task: member design library (beams and columns)

## Goal
The toolbox checks connections but not the members. Add `lib/members/`: the
design strength of beams and columns, steel (AISC 360-16) and reinforced
concrete (ACI 318-19, SI), for flexure, shear, torsion and their interaction,
so a project script can check every member of a frame from the ETABS forces.
You have the PDFs: every equation goes in `lib/members/EQUATIONS.txt` with
clause and PDF page, written from the page, not from memory.

## What already exists (absorb it, do not duplicate)
- `lib/sandwich_concrete/aisc_f2_ltb.m`: AISC F2 (compact doubly symmetric I,
  LTB, Cb input). Move it to lib/members (keep the name or wrap it) and make
  sandwich_concrete and sandwich_column call it from there; their saved outputs
  must stay byte-identical (casa_saav/reports/sandwich_beam_output.txt,
  lib/sandwich_column/examples/example_sandwich_column_output.txt).
- `lib/sandwich_concrete/aci_beam_shear_torsion.m`: ACI shear + torsion of a
  rectangular beam, Nu = 0, top/bottom bars only. Same treatment.
- `lib/collar_joint/dmj_lib.m` M1, M4, M5, M6 and `lib/direct_weld_joint/dwj_lib.m`
  M1, M4: member checks inside the connection libraries (M5 is wrong, see
  verification/audit_2026-10-09.md S1). When lib/members has F7 for HSS, these
  should call it (change the collar outputs only with the user's approval).
- `lib/profiles/steel_profile.m`: IPE, HE A, HE B in mm (EN axes: y strong,
  z weak; Wply = Zx, Wely = Sx, Iz = weak inertia, It = J, Iw = Cw). No HSS
  table yet: add one (rectangular HSS used in casa_saav: 200x100x4) or compute
  HSS properties from D, B, t (with the 0.93 t design wall of AISC B4.2 for
  ASTM A500; ask the user which steel the HSS are).
- `lib/etabs/`: reads the ETABS export into a joint database (forces at
  joints). Member forces along the member may need a new reader; ask the user
  for the ETABS table names before writing one.

## Scope, in order (stop after each block, show the user, then go on)
### A. Steel (AISC 360-16)
1. Classification Table B4.1a/b (compact / noncompact / slender) for I shapes
   and rectangular HSS, flexure and compression.
2. Flexure: F2 (I, major axis, LTB, Cb by F1-1 from moments at quarter
   points), F3 (noncompact flanges), F6 (I, minor axis), F7 (rectangular HSS,
   both axes, including slender flanges: this is the collar M5 case).
3. Shear: G2.1 (a) and (b) with Cv1 (I webs), G4 (HSS), G6 (weak axis).
4. Compression: E3 (flexural buckling, K L/r input), E7 (slender elements), and
   torsional buckling only where the code requires it for the shapes used.
5. Tension: D2 (yielding, rupture with An, U input).
6. Interaction: H1.1 (H1-1a, H1-1b), and H3 for HSS torsion with combined
   forces. Torsion of open I sections (warping): AISC Design Guide 9 (ask the
   user whether they have it; if not, leave it out and say so in CLAUDE.md).
### B. Reinforced concrete (ACI 318-19, SI forms from Appendix C)
1. Beam flexure: rectangular section, any number of bar layers, strain
   compatibility, phi from Table 21.2.2 (eps_ty + 0.003 rule, not 0.005: see
   audit C3), minimum steel 9.6.1, maximum spacing / bar limits as information.
2. Beam shear: 22.5 (Vc with Table 22.5.5.1 including the size effect when
   Av < Av,min, Vs, limits), 9.6.3 minimum, 9.7.6.2.2 spacing.
3. Torsion: 22.7 (threshold, cracking, compatibility torsion, Al, section
   limit), as aci_beam_shear_torsion but with axial force and any bar layout.
4. Columns: P-M interaction diagram by strain compatibility (rectangular
   section, bars anywhere), phi transition, Pn,max (22.4.2.1), biaxial bending
   (state the method: Bresler reciprocal or a P-Mx-My surface; ask the user),
   slenderness: moment magnification 6.6.4 as a separate function with its
   inputs explicit (k, lu, EI choice).
5. Column shear (22.5 with Nu) and the transverse reinforcement limits that
   are not seismic (10.6, 10.7, 25.7). Seismic chapters (18) only if the user asks.

## Function style (look at check_end_plate_column.m and aisc_f2_ltb.m)
- Small functions that return a struct with every intermediate value (r.Mn,
  r.phi, r.eq = which equation governed, r.class), no printing.
- One `check_*` per member type that takes the member and its forces and
  prints demand/capacity lines with lib/concrete_common/print_check.m.
- Units N, mm, MPa. Axis names in the help text (EN y/z of steel_profile vs
  AISC x/y: write the mapping once).

## Tests (required; this is how the user will trust the library)
Each function gets a test in `lib/members/tests/` that reproduces a solved
example and prints ours next to the book's value. Sources to ask the user for:
AISC Design Examples (companion to 360-16), ACI 318-19 SP-17 Design Handbook,
or any textbook they have (McCormac, Nilson, Wight & MacGregor). Agreement
within rounding = pass. Put the source and page in the test file.

## Done when
- lib/members/ with README.md, CLAUDE.md (limits), EQUATIONS.txt (every line
  with clause and PDF page), tests/ passing, and the two moved helpers used
  from there with the saved outputs unchanged.
- The root README.md and CLAUDE.md maps list lib/members.
