# Axis F: north-south IPE line between grids B and C (study, from 2026-10-05)

## Concept (user, 2026-10-05)
A north-south line halfway between grids B and C (axis F, x = 2.39 m from B). Two IPE 160 pieces, one each
side of VCS (grid 4):
- north piece: from the IPE 200 north of grid 4 (shear connection) to VCS, 1.45 m;
- south piece: cantilever from VCS to the border beam IPE 160 at the slab edge (shear connection), 1.27 m.
Aims: less torsion in VCS, more stiffness at the edge (vibration), less load on the IPE 240 cantilevers.
If every check passes here, the same concept goes to C-D (and maybe the east side, rows 3-4).

## Files
- `etabs_F.txt`: ETABS results given by the user, verbatim (dead only; live = 0.8 dead).
- `f_capacities.m` -> `capacities.txt`: design strengths of VCS (3+3 Ø12), IPE 160, IPE 200, IPE 240.
  Reference table for direct look-up; regenerate, never edit by hand.
- `f_calc.m` -> `f_results.txt`: demands and D/C along F and grid 4. Run: `octave-cli --eval "f_calc"`.
- `f_conn.m` -> `conn_results.txt`: moment connection of F across VCS; `f_conn_sketch.py` -> `conexion_F.html` (drawing).
- `f_two_lines.m` -> `two_lines_results.txt`: estimate for two IPE 140 lines instead of one IPE 160.
- `f_deeper.m` -> `deeper_results.txt`: IPE 160 / 180 / 200 with the connection made by Ø20 rods only (no strap).
- `f_vib.m` -> `vib_results.txt`: edge vibration, without / with F, hand estimate with assumed stiffnesses.

## Assumptions (to confirm)
- f'c 210 kg/cm2 (the calc stays at 210, user), fy 420, sections A36.
- VCS stirrups Ø10 2 legs @ 140, as the VCM (not confirmed for VCS).
- Live = 0.8 x dead everywhere (user); pattern only for the uplift at the IPE 200 (live on the cantilever only).
- Governing factor 1.2D + Ev + L = 2.58 D (Ev = 0.579 D, NEC), as the cantilever calc.
- IPE 160 flexure with Cb = 1 and the bottom flange unbraced over the whole piece (conservative).

## Results (2026-10-05, f_results.txt): two ETABS runs, design for the envelope
- Run 1, VCS torsion stiffness x1.0; run 2, x0.1 (cracked, compatibility torsion). Run 2 moves the F moments
  to 6.36 north / 5.62 south (D) and the VCS torsion to 0; the 0.74 left over goes into the slab over VCS.
- IPE 160 north 0.72 (run 1), south cantilever 0.55 (run 2); shears <= 0.14.
- VCS: negative moment at the column faces 0.73, positive at F 0.84, shear 0.29 (both runs).
- VCS torsion: 1.13 x the threshold in run 1, 0 in run 2. Compatibility torsion: designed with the cracked
  torsional stiffness (run 2) -> no torsion reinforcement required; closed 135 deg stirrups near F anyway
  (VCS not poured yet).
- IPE 200 at F: upward point load up to 10.5 kN (run 1, live on the cantilever only); gravity design relieved;
  uplift alone 0.49. User: no change in that beam.
- C4 IPE 240 with F: 14.7-15.7 kN m factored at the face (the cantilever calc designs E for >= 20.5, user minimum).

## Moment connection across VCS (2026-10-05, conn_results.txt)
- Rods across VCS taking the top tension were rejected: with the IPE 160 the tension is about 157 kN and a 12 mm
  end plate fails in bending (strips, D/C about 2.9).
- Tension: top strap PL 12x70x540 A36 on both top flanges (lap 120 each side), fillets 6 (2 x 120 + 70), proud
  12 mm over z = 0 under the slab. T = 113 / 89 kN: strap 0.60, welds 0.39; IPE top flange 0.89.
- Compression: end plates PL 12x116x180 A36 welded to the beam ends, bearing on the VCS faces (f_p,max with
  sqrt(A2/A1) = 2): block 0.63, plate n strip 0.90.
- Shear: 2 rods Ø16 (rebar, threaded M16) through VCS at x = +-35, z = -120, cast with VCS (AV type): 0.22.
  Clearances: nut to flange/web fillet toes 12.7 / 13.6; rods 50 from the VCS bars, 22 from the stirrups (at +-70).

## Two IPE 140 lines instead of one IPE 160 (user question, 2026-10-05; estimate, two_lines_results.txt)
- User: flush plate is not an option. Asked if 2 IPE 140 lowers the forces enough for Ø20 rods (no strap).
- Estimate per line (scaled from run 2): about 30 % less moment (11.3 / 10.0 kN m factored); IPE 140 0.63 / 0.54.
- Rods Ø20 in tension 0.60, but the 12 mm end plate they pull on fails in bending: 2.24 (1.12 with an extra plate).
  The strap still works (0.49). So two lines do not remove the strap.
- Steel per bay: 53 kg (1 IPE 160) vs 90 kg (2 IPE 140, +70 %), and twice the connections.
- What two lines would give: border beam spans 1.59 instead of 2.39 (edge stiffness, vibration).

## Deeper section, rods only (user question, 2026-10-05; deeper_results.txt)
- One row of 2 Ø20 rods: the 12 mm end plate fails for every section (IPE 200 with an extra plate 0.97-1.17).
- Two rows (4 Ø20 at z = -40 and -75, the VCS top bars between them): IPE 200 + end plate 12 + extra plate 12:
  0.67-0.81 at the top row (lower row about 0.85 by hand); IPE 180: 0.84-1.01. Moment 18.3 and +20 % (a stiffer F
  attracts more: ETABS to confirm).
- Steel per bay: IPE 200 with rods about 76 kg against 53 kg for IPE 160 + strap (+43 %). IPE 200 is 2.2 x stiffer
  (edge, vibration). North end into the IPE 200: same depth, coped.

## Decision and vibration (2026-10-05)
- User: F stays IPE 160 with the top strap. Strap may be PL 10x70 if available (yield 0.72, welds 0.39); 12 gives 0.60.
- Vibration (vib_results.txt, DG11, 3.0 kPa in the mode): F raises the edge frequency from 4.6-6.9 Hz to 6.1-8.8 Hz
  (LOW / HIGH stiffness). Still under 9 Hz; ap/g 1.1-4.6 % against 0.5 %. With F the soft point is the F tip:
  cantilever 3.1 / backspan rotation 3.7 / VCS 1.5 mm (LOW). With IPE 200 on F: 8.3-12.3 Hz.
  The DG11 walking formula is very pessimistic for a light edge strip (W 25-40 kN): fn >= 9 Hz + about 1 kN/mm is
  the practical target. Needs an ETABS modal with realistic stiffness (slab acting, joint springs) to decide.

## IPE 200 on F (user, 2026-10-05, leaning to it): run 3 dead moments at VCS -7.61 N / -6.56 S
- Factored (x 2.58): 19.6 / 16.9 kN m (+ about 15 % with railing 0.3 + C profile 0.1 kN/m). IPE 200 flexure 0.42-0.48.
- Connection: 4 Ø20 through rods (two rows, -40 / -75) + end plate 12 + extra plate 12, no strap, flush top:
  about 0.72-0.83 (deeper_results.txt interpolated; lower row about +5 %). Vibration estimate 8.3-12.3 Hz.
- Run 3 VCS (x 2.58): negative at the faces 27.7 kN m (0.77); POSITIVE AT F 32.7 (0.91; about 0.98 with the railing
  and C profile at the edge); shear 0.30; torsion 0.57 of the threshold. C4 IPE 240: 13.8 kN m, 15.7 kN.
  Proposal: one more Ø12 bottom bar in VCS between B and C (4 Ø12: phi Mn 47.2 -> about 0.75); VCS not poured yet.
- Run 3: shear at the north end of F (IPE 200 contact) 2 kN dead (5.2 factored): simple shear tab.
- DECIDED (user): one more Ø12 bottom bar in VCS between B and C (4 Ø12 bottom, phi Mn 47.2).
- With C4 at 16.5-18.5 kN m (F + railing + C profile), the wide anchors (ca_wide, A1 at -50) pass: max 0.92-0.96
  (top bars T + M/jd upper bound), B1 under z = 0 (no stub sliding). Needs the user's minimum 20.5 dropped.

## Open
- Slab over VCS at F: takes the unbalanced F moment in run 2 (0.74 D, about 1.9 kN m factored): check its top steel.
- Strap proud 12 mm over z = 0: deck locally shimmed or cut; alternative flush plate cast in VCS with CJP to the flanges.
- Grout or shims between the end plates and the VCS faces (gap and tolerance); rod holes drilled to the as-built rods.
- Shear connections at the IPE 200 (16.3 kN, both directions) and at the border beam (8.6 kN): to size.
- Drawing of the connection (dimensioned).
- ETABS: VCS torsional stiffness modifier; joint springs at B4/C4/D4 (share between F and the IPE 240).
