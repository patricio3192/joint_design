# Cantilever anchorage, bolted plate (check of the RAM Connection design)

## Column hooks and ties 14 under the anchors (user, 2026-10-05) - CURRENT
- Column top hooks (all types; D4 oriented by X): level A (+72, top cover 20, `P.col.ctop`) = corners and the
  front / far mid bars (D4: east / west), hooked ALONG the anchors; level B (+45, `P.col.zhB`) = the side mid
  bars (D4: north / south), hooked ACROSS, resting on the A1 (of X). Level C is gone. Hook tables in
  `hook_table` (make_pour_sheets.m). Cover 20 < ACI 40: the user's choice (base plate grout and slab on top).
- Ties 14 both under the anchors (`P.top.z`, computed after the anchors in ca_inputs.m): upper at +10
  (`P.top.zu`), right under the B1 front nuts (a flat down): the A1 sit on it; lower at -43, on the beam
  top bars (39 mm clear between them for the concrete). The -43 tie is 143 under the pedestal top: outside
  the 127 of ACI 10.7.6.1.5 (flagged in the clearance table).
- B1 face at u = 364 (`P.bp.u`), against the back leg of the upper tie; the tie bears on the far-face Ø16,
  straight up to +16 (level-A bends start there). Contact line 3.5 above the B1 bottom edge. CY: its B1
  (bottom +22.5) does not reach the tie.
- STM (ca_stm): node width wV = B1 face to the front of the far bars = 30 (was 39 to the hook at 334):
  type E path 1 goes 0.99 -> 1.04 (N2 node / development of the tie, beta_n = 0.6).
- Anchorage page figure G: full width, 192 dpi, marks where the breakout body ends (cold joint, 111 from the face).

## Pre-pour placement sheets (2026-10-02, in review with the user)

`octave-cli t3_planos_colocacion.m` writes `reports/planos_colocacion_anclajes.pdf` (`make_pour_sheets.m`,
same printer and helpers as the workshop sheets), 4 A4 sheets in Spanish:
1. key plan from the user's floor plan: grids B–C–D–E at 0 / 4780 / 9560 / 10830, A inclined (-1780 at
   grid 4, about -2400 at grid 1, not dimensioned by the user); rows 9 / 4 / 3 / 2 / 1 at -1270 / 0 / 4330 /
   5730 / 9750 (origin B4). Cantilevers: south at B4, C4, D4; east at D4, D3. Types: E = C4, C1 = B4 and D3
   (they have concrete beams on both sides, so the C1 "free face" was conservative), CX/CY = D4.
   Primed grids (1', 2', 3', A', B', C') left out; the cantilever tip member is not drawn (slab edge only).
2. E and C1: view from outside, section along the cantilever, plan at z = +29, tolerance table.
3. Corner D4: CX = east cantilever (z = +29), CY = south (z = +56); the sheet prescribes that the concrete
   beam on grid D (in line with the south cantilever) has its top bars on the upper layer.
4. Assembled A1 / A2, back plate B1, closed tie 14, quantities of the pre-pour items, notes.
Template for the anchors: left to the site (user), with the tolerances: level ±5 (A1 of Y: +0/-5),
lateral ±10, projection +10/-0, B1 depth +10/-5.
Ties 14 moved to -25 / -7 (user): the tie at -25 is 125 under the pedestal top (ACI 10.7.6.1.5).

### Revision (2026-10-02, later): colours, hooks, joint ties
- Printer `pour_pdf.py`: joint_pdf.py unchanged + styles r_* (report colours, stroke opacity for what is
  already in the cage) + text styles + `**bold**` in tables and paragraphs.
- Bars are drawn as rounded paths (`fillet`, `d_path`): column hooks r = 3.5 d at the axis, beam hooks,
  135° tie hooks. Sheets: 1 key plan; 2 E/C1 (front, section with the 2 stacked Ø12 VCM hooks, plan, hook
  plan); 3 D4 (plan, section along the south cantilever with the east A1/A2 cut and dimensioned, hook
  plan); 4 pieces, closed tie 14, joint-tie layer, tolerances, quantities (closed ties for all 16 columns,
  `opts.ncol`), notes. Labels VCS (crossing beams) and VCM (beam in line).
- Column hook scheme (8 Ø16, 90°, tail 192, 248 from the bar axis in plan), two levels:
  * level A, z = +52 (cover 40): may cross the A1 of X/E (7 mm), not the A1 of Y (z = +56).
  * level B, z = +29 (`P.col.zhB`): only parallel to the A1, 11 mm beside them; A passes over B bars.
  * E/C1: front/far mid bars B along the beam (v = -8 / +8); side mid bars A across (u = 192 / 208);
    corners A across (u = 50 / 66 front, 334 / 350 far).
  * D4: N/S face bars A north-south (corners x = ±134 / ±150, mids x = ±8); E/W mid bars B east-west (y = ±8).
  * ca_calc: E/C1 A1 may rise only 7 mm (hooks over them); clearance rows added.
- Closed ties 14 wrapping the column bars: cover 36, accepted by the user (2026-10-02).
- **OPEN, decision pending (2026-10-02): ACI 318-19 17.1.5** excludes "multiple anchors connected to a single
  steel plate at the embedded end" (confirmed by the user from the code). The single B1 is outside chapter 17.
  `ca_options.m` -> reports/back_plate_options.html checks two fixes for the four types:
  A) one plate washer per anchor, PL 12x45x50 (effective head = nut face + t, A_brg 1432): pullout 0.25,
     blowout 0.76 (E) / 0.65 (CY), plate 0.25; anchor reinforcement unchanged. Recommended.
  B) through-bolts + PL 12x55x120 on the far face (160 wide fails through the holes, 1.30): bearing 0.59,
     plate 0.46, pedestal shear 0.42, but shear friction across z = 0 fails: the column bars end in hooks
     only 37 / 60 mm above the plane (need 150); plain concrete 1.70. Needs U-bars where the level-A hooks are.
     Service: ~0.35 MPa shear on z = 0, likely no cracking.
  Nothing in the calc, pages or sheets is switched yet (B1 is still one plate).
  User (2026-10-02): keeps the single B1 for now (behaviour the same; switch is code coverage only).
- Pre-pour sheet 4 (new): top bars of the beams in the joint, solid (E/C1 plan + section with the 2
  stacked VCM bars; D4 plan + two sections). Pieces/notes moved to sheet 5.
  User: grid D beam has 5 top bars, grid 4 only 3. Drawn: grid D top line at -56 (upper layer), its 2
  extra bars at -80 (P.cb.zp), the 3 grid-4 bars at -68 passing between them. The anchor checks count only
  the top line, so nothing changes in the calc. Hooks of the beam bars drawn against the joint ties
  ("contra los estribos", bold); ties solid, column bars faint.
- Column top hooks: cover 25 to the pedestal top (P.col.ctop, user 2026-10-02: encased by the base plate
  grout and the slab; ACI table asks 40). Level A at +67. A1 level tolerance on the sheets +15 / -5 (E, C1,
  CX), P.tol.za = 15 in the checks (anchor reinforcement inside the body 0.85, all pass); CY +0 / -5.
- Beam bars as anchor reinforcement: on top of the 13 mm ACI placing tolerance already in the checks,
  they can sit about 40 mm lower before 'developed beyond the breakout body' reaches 1.0 (CX loses one
  counted bar after 10 mm; steel 0.87). Detail 5.4 (4-piece joint ties) only if normal closed 135° ties
  cannot be placed.
- Beam top bar layers (user 2026-10-02): at B4, C4 and D4 the VCM in line goes ABOVE the bars of the grid-4
  beam (-56; its 2 extra bars at -80, grid 4 at -68 between). D3: the VCM of grid 3 goes under the grid-D bars
  (they come over from D4), extra pair in contact at -80. The checks of E/C1 still use the lower layer
  (-68): conservative for B4 and C4, exact for D3. Pre-pour sheets: 4 = B4, C4, D3; 5 = D4; 6 = pieces.
- Supplementary U-bar (P.ub, user asked 2026-10-03): one U 16 per beam at E, C1, CX (not CY), across the
  beam at u = 335, resting on both A1 (axis z = +45), legs at v = +-75 to z = -250, 90 deg hooks towards the
  face. Vertical tie for the steepest strut 1.41 T: D/C 0.91 / 0.48 / 0.69; hooks l_dh 208 / 264 (0.78).
  Two U 12 do not fit (the second lands on the grid-4 bar at u = 294). Price: 6 mm to the level-A hooks, so
  with the U-bar the A1 tolerance up is ~+5, not +15. Anchor page section 6b, figure H (ta_ubar).
  NOT yet on the pre-pour sheets: waiting for the user's decision.
- Sheet for the architect (2026-10-03): `octave-cli t4_fisuras.m` -> reports/fisuras_esperadas_voladizos.pdf
  (make_crack_sheet.m): expected service cracks 1 (plate to pedestal top, hidden), 2 (grout/column joint at
  the top of the end plate), 3 (beam in line, top, at the column), 4 (possible floor cracks over grids 4 and D,
  depends on the slab top reinforcement), with notes on finishes and a 0.3 mm alarm width.
- Stress test (2026-10-03, anchor page 6c, R.hka): every bar crossing the body as a HOOKED ANCHOR (17.6.3.2.2b,
  no bond, e_h = 4.5 d_b): beam bars alone 3.22 / 2.56 / 2.46 / 3.35; + 2 extra beam bars (C4, D4-S) and the
  side legs of the two closed ties 14: 0.93 / 0.69 / 0.87 / 0.71; + a proposed third closed tie 14 at -41:
  0.73 / 0.50 / 0.66 / 0.55 (proposal, not in the drawings). Side-by-side table on the page: chapter 25
  development (what ACI 17.5.2.1 requires for anchor reinforcement) vs the hooked-bolt equation.
- Pre-pour sheets: 3D views of the column hooks (2.4, 3.4) with transparent grout + base plate; level B drawn
  under level A; hidden level-B dots removed from the hook plans.
- Frame category: ORDINARY (user). Joint ties per 15.7 / 10.7.6 spacing (<= 16 d_b = 256): the 125 mm gap
  between -225 and the soffit is fine.
- Back plate B1 checked as a beam along its length (`ca_bpbeam.m`): concrete pressure uniform, each nut
  pushing on a ring Ø18..22.5 (P.an.dw), net width through the holes, M-V interaction. Between the anchors
  0.56 (governs, no hole), through the hole 0.39, shear rupture 0.20. The first version (point push at the
  axis vs the full width) hid the hole; on the net width that model gives 0.98 / 1.29 (explained in
  anchor_check.html, section 3b). Side-face blowout figure now draws the spall (3 ca1 on the top face).
- Shear anchors A2, concrete side (2026-10-03, `shear_conc` in ca_calc.m, R.shc; anchor_check.html section 8,
  figures I/J/K = ta_spry, ta_sbrk, ta_sfr): pryout kcp Ncbg with V = sqrt(V^2 + H^2) on the group (0.51 E);
  breakout towards a side face under the torsion couple H, cases 1 and 2 of R17.7.2.1 (holes not welded),
  V down taken as parallel to the side face (2 x, 17.7.2.1(c)), components combined as EN 1992-4 psi_alpha,V:
  case 2 governs, 0.56 (E). Before, breakout was dismissed because V points down (no edge): H was missed.
- Top anchors A1 in shear (2026-10-03, `shear_top`, R.sht; anchor_check.html section 8b, figure L = ta_stop):
  they always carry the torsion couple H (towards a side face, top of the pedestal cuts the half cone);
  V only if all 4 holes bear (info). 17.8 interaction with the tension ratio of the anchor reinforcement
  counting every beam bar still developed (R.cone.kTi / nTi): worst 0.86 (E); all 4 bearing 1.03 (E, info:
  V moves to A2). Offered: vertical slots in the end plate at the A1 (V never on A1).
- ca_capacity: D/C is not monotonic in the load (beam bars counted grow with T): step scan, then bisection.
- Bottom bars of the beams in line (2026-10-03): 90 deg hooks up, outside at P.cb.ubh (first 116, now 120)
  from the cantilever face (behind the top tails and the bend of the 2 extra bars); in line on the upper
  bottom layer (D4: grid D over grid 4). `bothooks` in ca_calc (clearances), details 4.4 / 5.4 (plan at A2).
  The U-bar foot clashes with the grid-D bottom hooks at CX (-12 mm).
- Ø14 ties as a pair in contact at -25 / -11 (user); grout: commercial non-shrink >= 280 kg/cm2
  (SikaGrout-212 or INTACO Maxibed Grout in Cuenca).
- Rods of the steel column drawn to the bottom of every drawing (anchored > 1 m below z = 0). They clash
  with the beam corner bars (+-100 vs +-94: -6 mm), both beams: open point.
- Anchors switched to commercial threaded rod 5/8"-11 UNC ASTM A193 B7 (user 2026-10-03), grade 8 or
  A194 2H nuts, washers Ø30x3; embedded ends cut flush with the nut (uT = 394, 6 inside the far face).
  F1554 Gr 55 is the fallback; grade 2 / Gr 36 not allowed.
- Bottom bars (user): VCM 5 Ø12 like the top (3 + 2 over the corner bars), VCS 3. No moment reversal:
  only the 2 corner bars hooked up (P.cb.vbh, at P.cb.ubh = 120; ACI 18.3.2, 9.7.7), centre bar straight
  150 into the joint, the 2 extra VCM bars stop at the column face. No clashes left (the 5-in-a-row
  layout had -3.5 mm at D4).
- Pour sheets: 'junta fría' label removed; D4 hook paragraph shortened; detail 2.5 redrawn without the
  VCS stubs; sections label the VCM as 5 Ø12.
- 3D hook views (details 2.4, 3.4): pieces sorted by depth where they overlap (paint3d), A1 + B1 drawn;
  level B under level A everywhere (the old sort put B last).
- 2026-10-03 (user): U-bar DROPPED (P.ub.on = 0, code kept). Level-A column hooks lowered from +67 to +51
  (P.col.ctop 25 -> 41, ACI 40 now met): the far corner hook (u = 350) rests on the B1 front nuts (corner up
  42.9), the one at 334 is 6 mm over the A1; they are the vertical tie at the plate (2 Ø16, 127 kN vs 1.41 T =
  115 kN at E; not counted, shared with the steel column). The hooks follow the anchors up: A1 +15 -> cover 26
  (P.col.cmin = 25). CY has none (a hook over the Y nuts would sit at +78, cover 14). Anchor page 6b rewritten.
- Rods of the steel column kept at +-100 (user: whatever leaves more room for the pour): the beam corner bars,
  top and bottom, both beams, go to +-88 inside the joint (P.cb.v / vb / vbot / vbh; P.cb.vbm = 94 in the beam),
  in contact with the rods and tied to them; 44 mm left to the column ties (rods at +-112: 6 to the beam bars).
  Bottom hooks moved to P.cb.ubh = 126 (D4 tails of grids 4 and D were 7.8 apart at 120; now 16.3).
- D4 (user 2026-10-03): CY anchors lowered from +56 to +45 (P.an.zH), resting on the CX anchors and on the
  level-B hooks. The two north corner bars hook east-west over the Y anchors (level C, P.col.zhC = 67): the one
  at 350 from the south face on the Y B1 front nuts, the other 6 mm over the Y anchors; cover 25. CX keeps the
  SW corner hook (level A) on its own B1 nuts. D4 tolerances: X +0 / -5, Y rests on X. CY checks: all pass
  (anchor reinforcement steel 0.82, end plate 0.52, blowout 0.43, A1 interaction 0.80). Sheets 3.2-3.4, tolerance
  table, anchor page 6b, workshop note 2 updated.

- Bottom hooks closed (user 2026-10-03, ETABS): largest positive moment 0.5 m from the face, beam in line:
  C4 3.5, D4 grid 4 6.2, grid D 6.6 kN m (P.etabs.Mpos; C1 not given, 6.6 used). With only the 2 hooked corner
  bars, phi Mn = 23.6 kN m: D/C 0.15 / 0.28 / 0.27 / 0.28. The 2 hooks are the ACI 18.3.2 minimum: no more to cut.
- Border beam (2026-10-03, PROPOSAL, not in the drawings): t5_border_beam.m -> bb_calc.m, bb_page.m ->
  reports/border_beam.html. Every IPAC 2023 IPE and rectangular tube, A36, pinned spans 4780 / 4330 between
  cantilever tips; deck 1270 to the border beam (half on it); no edge line load (to confirm). Strength F2/F7,
  L/360, L/240, DG11: fn of the edge strip with the tips moving (IPE 240 + A1 rod stretch) >= 9 Hz, 1 mm/kN.
  Lightest: IPE 140 / tube 75x175x3; proposal IPE 160 (fn 10.4 Hz). DG11 acceleration 5-19 % for every section
  (strip of ~1.2 t): not controlled by the beam. Tip point loads raise E to 23.7 kN m (governing D/C 0.87 -> 0.93)
  if ETABS did not have the beam. Corner: east beam continuous E3-E4-E9 (5.6 m), south piece D9-E9 pinned.
  User answers (same day): railing, no data -> 0.3 kN/m assumed (B.wedge); deck directions and corner scheme
  accepted; ETABS already has the border beam -> only the railing is added to the cantilevers: E 24.9 kN m,
  governing D/C 0.98 (railing must stay under ~0.35 kN/m). With the railing IPE 140 fails L/240: IPE 160 is the
  lightest IPE (fn 9.7 Hz, 8.3 with the connection x2). Not in the drawings yet.

- Bastones (user 2026-10-03): 2 extra Ø12 top bars in every beam in line (P.cb.bas), top line at v = +-44, 180 deg
  hooks at the cantilever face (outside 50; the 90 deg tail would hit the A2), 1500 into the beam. Counted as anchor
  reinforcement (cone picks 4 at E) and in the beam check (7 bars). E: anchor reinforcement steel 0.76 -> 0.57, A1
  tension + shear 0.86 -> 0.71, beam in line 0.85 -> 0.62. Largest Mu: E 29.4 (end plate strict no-prying governs),
  C1/CX 23.5, CY 24.0 (A1 interaction). With the 0.3 kN/m railing: E 0.85, C1 0.58, CX 0.82, CY 0.81. Drawn on
  sheets 2.2, 3.2, 4.1, 4.2, 4.3, 5.1-5.3 (orange, r_bas); quantity BA 2 per connection.
- Not adopted yet (offered): centred tip connection of the border beam (study override P.tor in ca_calc), counting
  the 2 extra VCM bars at -80 as drawn at C4 / D4-S (scratch study only).
- REMIND THE USER: re-spread the Ø10 joint ties (now -95/-135/-180/-225, inherited; ACI 15.7 / 10.7.6 allows
  256 spacing). Keep the pair around the A2 at -201.

- 2026-10-04: anchor page renamed reports/anchorage_check.html ("Anchorage check"). New section 9: strut-and-tie
  model of the anchorage (ca_stm.m, figure M = ta_stm): N1 at B1 (ties A1 + V = far corner column bars), strut S1 at
  theta chosen in 25..65 deg (lower bound, best of a scan), N2 smeared CCT on the beam top bars, strut S2 down.
  ACI 23.2.7, 23.4.1/23.4.3 (beta_s 0.75 joint), 23.7.2, 23.8.3, 23.9 (beta_n 0.6 at N1, 0.8 at N2), phi 0.75.
  Strict result: E 1.05 with B1 45x120 (N1 face and bar length past N2); beta_n 0.8: 0.99. PL 12x60x120 -> 0.95
  (3 mm to the tie 14 at -11); wider plates fail B1's own hole check. NOT adopted: the code path (17.5.2.1(a) +
  ch. 25) passes; STM is optional (R17.5.2.1 'may'). User to decide.
  User asked (2026-10-04) why it differs from the revision-2 report (cantilever_anchor, Step 6): that report had TWO
  paths (1: T into the beam top bars + C straight to the beam bottom; 2: diagonal strut from the anchors to the end
  plate compression, V in the far column bars, column takes the moment). Section 9 first had only path 1 (local
  transfer to the bars). Now both: ca_stm returns M.p2 (N3 = DG1 bearing block on the face, CCC, theta ~37 deg);
  path 2 alone: 0.90 at E without the N1 face; the N1 face (1.05 strict) is common to both paths.
- Joint ties Ø10 spread: P.hoop.z = -95 -160 -245 -310 (were -95 -135 -180 -225). Stress test per layer with the
  35 deg cone (R17.6.2.1): no layer below -95 ever counted; nothing lost. Plans now draw a normal closed tie; the
  4-piece tie is detail 6.4, as an option.
- Grout note added to the workshop sheets (ASTM C1107, >= 280 kg/cm2, SikaGrout-212 / INTACO Maxibed or equivalent,
  shims, pouring, final tightening).
- REMIND THE USER (last task): move all details to A3 (or A2) sheets.
- Pending user decisions: arrangement of the 2 extra bars (options in the reply of 2026-10-04: keep 180 deg in the
  top line, or second layer packed beside the -80 bars with staggered 90 deg hooks; only C4 (E) needs them),
  Ø10 vs Ø12, B1 size (STM), centred border-beam connection. After that: material list, bar detail, top view of all
  beam rebar, cross-section.

- 2026-10-04, user decisions: bastones Ø12; back plate stays PL 12x45x120; border beam connection CENTRED on the
  cantilever web (ca_calc tor = 0.25 for all types, 15 mm misalignment). Bastones moved: only at E (C4), second
  layer -80 at v = +-76 packed beside the -80 bars (2-bar bundle in the span), 90 deg hooks 16 mm behind theirs
  (tails 8 mm apart, 27 mm to the A2); top line back to 3 bars, 76 mm clear. E: A1 tension + shear 0.58, beam in
  line 0.63. Largest Mu: E 29.4, C1 28.3, CX 28.3, CY 28.7; with the 0.3 kN/m railing E 0.85, C1 0.48, CX/CY 0.68.
- STM final review (section 9.8): equilibrium closes in both paths; the concrete at N1 is the anchor head, checked
  by ch. 17 (pullout, blowout); ch. 23 values there are information and do not steer theta. Path 1 0.99 (E),
  path 2 0.90-0.95. The joint ties (stirrups) are not in the STM; beta_n 0.6 at N1 comes from the column-bar hooks
  counted as a second tie.
- REMINDERS: (1) move all details to A3 (or A2) sheets, last task; (2) draw the border beam with the CENTRED
  tip connection (bolt group on the cantilever web; at E the two spans from opposite sides, at the corners the
  beam end past the web): the calc already assumes it.
  (3) add a lateral (side) view of the column hooks with the anchors, for the edge types (E/C1) and the corner D4,
  next to the existing plan and 3D views (details 2.3/2.4, 3.3/3.4) - with the A3 move.

- 2026-10-04: pour sheets moved to ONE A2 landscape sheet (t3: opts.page 'A2L', hk 0.66, fs 0.75, colw; the A4 pages
  become panels, two per column; the notes go to column 4). New details: 6.4 closed joint tie Ø10 (the 4-piece tie
  is now 6.5, option); 7.1 C4 plan with all beam bars; 7.2 section A-A of the VCM at C4 (7 top bars); 7.3 bastón
  Ø12 with dimensions (1822 + hook 192, 2 at C4); 7.4 / 7.5 side views of the column hooks (E/C1, D4). Reminder (3)
  done; (2) done for the pour sheets (workshop sheets still A4); (1) border beam: connection detail to be agreed.

- 2026-10-04: border beam connection, option (a) (user): tip plate T1 PL 10x150x240 A36 welded across the end of each
  IPE 240 (5 units: B9, C9, D9, E4, E3), IPE 160 web bolted flat to it with M16 A325 at x = +-35, z = -50/-110; inner
  half-flanges cut flush with the web over the plate + 10. 4 bolts where the beam passes (B9, E3, E4), 2 + 2 where two
  beams end (C9, D9). Corner E9: tab PL 8x90x120 on the VB4 web, VB3 double coped. Pieces VB1 4850, VB2 4770,
  VB3 1265, VB4 5714 (P.bb, bb_pieces). Checks in border_beam.html 6b (bolts / bearing / coped web 0.10, welds 0.08,
  cantilever torsion within the 0.25 assumption). Workshop sheets now ONE A2 sheet (t2: opts.page A2L) with a
  border-beam page (details 3.1-3.5, piece table, quantities VB/T1/TB/PB). All three reminders done.

## HANDOFF (2026-10-02): pre-pour placement plans (now drawn, see above; kept for the rules)

**Task (user, 2026-10-02):** "a new set of plans with everything that needs to be set before the pouring".
These are A4 sheets in Spanish, in the same style as `reports/planos_taller_placa_empernada.pdf`.
The design is FINAL and checked. Do not change it; draw it. If something does not fit, stop and ask.

### What is set before the joint is poured (per connection)
Same for every type except the anchor level of CY. Coordinates: u from the outer face of the
column, into the column; v across, from the beam axis; z from the top of the concrete beam
(= top of steel), up. All mm. Numbers are from `ca_inputs.m` / `ca_calc.m`; reprint them from
`P` and `R`, never type them.

| Item | Mark | Where |
|---|---|---|
| Top anchors, 2 per beam | A1: Ø16 INEN 2167 (fy 4200 kg/cm2), L = 479, thread M16x2: 100 outer end, 64 inner end | v = ±35; z = +29 (E, C1, CX) or +56 (CY); from u = -80 (80 out of the face) to u = 399 |
| Back plate, 1 per beam | B1: PL 12x45x120 A36, 2 holes Ø18 at 70 | bearing face at u = 365 (365..377); centred on the A1 row; behind the far column bars and the far ties (5 mm to the outer face of the far ties) |
| Nuts on A1 | M16 class 8 (ISO 4032, 15 high) | front nut, no washer, u = 350..365 (positions the plate); washer + nut behind u = 377..395 (carry the pull); 2 threads beyond. Per connection: 14 nuts, 8 washers (sheet 1) |
| Shear anchors, 2 per beam | A2: Ø16, L = 187, thread 100 outer / 30 inner | v = ±35, z = -201.2 (all types); from u = -65 to u = 122; washer u = 100..103 + nut 103..118 at the inner end |
| Template (temporary) | to be designed: holds the 4 anchors at the face during the pour | nominal pattern: v = ±35 at z = zT and z = -201.2; outer threads taped |
| Closed ties at the pedestal top | 2 Ø14, closed, ACI 318-19 10.7.6.1.5 (rods of the steel column) | z = -25 and -7 (tie at -25: 125 under the pedestal top); placed BEFORE the anchors |
| Joint ties | 4 layers of 4 straight Ø10 with 135° hooks (as in the earlier designs) | z = -95, -135, -180, -225 |
| Column top hooks | 8 Ø16 column bars, 90° hooks, two levels A (+52) and B (+29) | see 'Revision' above and sheets 2.4 / 3.3; bent after the anchors are placed |
| The closed tie at +50 of the earlier designs | DROPPED | - |

Corner with two cantilevers: beam X gets anchors at z = +29, beam Y at z = +56 (same end plate P1, holes drilled where the anchors are);
they cross 11 mm apart. **Rule: beam Y is the concrete beam whose top bars are on the upper layer**
(look at the tied cage). The shear anchors of X and Y do not cross (they are short).

What is NOT set before the pour: end plates P1, refuerzos S1, ribs R1, IPE 240, grout pad
(30 mm). The holes of the end plate are drilled AFTER the pour, to the surveyed anchors.

### Clearances and room for errors (print them on the sheets where useful)
`R.clr` and `R.tolt` hold them. Key values:
- anchors to the mid-face column bar 19; to the steel-column rods (v = ±100) 51; top anchors to the
  top tie at -7: 21; X–Y anchors at the corner 11; corner hooks over the X anchors 7;
- back plate to the far ties 5; back plate to the top tie at -7: 6.5; back plate of CY 21.5 under the pedestal top; bar ends 1 mm from the far face;
- shear anchors to the joint ties at -180 / -225: 8;
- top anchors: -6 / +8.5 mm in level (edge), ±19 / +51 sideways; back plate free in depth (nuts).

### Existing code to reuse
- `make_workshop_sheets.m` + `t2_planos_taller.m`: the JSON printer pipeline (`../python_support_scripts/joint_pdf.py`,
  not to be modified), title block, block/drawing helpers (`d_*`, `blk_*`, `holelab`), styles
  (`plate`, `plate2`, `plate3`, `tab`, `tabh` = dashed/faded anchor, `hidden`, `weld5`, `edge`, `cut`).
  Copy the pattern into a new `make_pour_sheets.m` / `t3_planos_colocacion.m`; do not break t2.
- `ca_draw.m` (report SVGs): `fig_plan`, `fig_elev`, `fig_front` already draw every bar, tie, rod,
  anchor and back plate in place for E, C1 and the corner (CX + CY). Use them as the geometric reference
  for the placement views (plan, section along the beam, view from outside, for each type).
- Check the drawings by rendering: `mutool draw -q -r 100 -o x.png file.pdf <page>` and read the PNG.

### User's rules for sheets (all confirmed by the user)
- Spanish; short, direct sentences; not condescending; no step-by-step assembly instructions (the user
  removed them from the workshop sheets; ask before adding a placing sequence).
- No wood formwork drawn. "línea punteada", not "en discontinuo". "refuerzos", not "suplementos".
- Every plate with holes shows the diameter of at least one hole (Ø18).
- Weld symbols with the flag for site welds. No electrode class on the sheets beyond "E70" in the notes.
- Same title block as `t2_planos_taller.m`; date OCTUBRE 2026; check that the CONTENIDO text fits.
- Faded (dashed) drawing for elements that are not the subject of a view.

### Open questions to ask the user before or while drawing
1. Number of connections: the sheets use 1 E, 2 C1, 1 CX, 1 CY (from the first design). Confirm.
2. Template for the anchors: material and how it is fixed (no formwork drawings). Not designed yet.
3. Two offers not yet answered: a note "No soldar los anclajes ni rellenar los agujeros con soldadura",
   and the refuerzo tolerance "borde inferior a nivel del ala, +8 / -10 mm" on the workshop sheets.
4. The VCM stacked bars (hooked bundle, R25.6.1.5): the user said to drop it; do not raise it again
   unless asked (it is listed in the report's open items).

### Other open items (in the report)
Grout minimum thickness (18 under the refuerzos); M16x2 thread cut on INEN 2167 rebar (full thread over
the nut length, class 8 nuts, 2 threads beyond); deck notched around the end plate and the rib.


Fourth concept for the IPE cantilevers on the 40x40 pedestals. The beam has a shop-welded end
plate. It is bolted on site to Ø16 anchors cast into the joint. The end plate is **not** cast
flush: it goes on after the pour, over a grout pad.

Starting point: the user's RAM Connection report `anclaje voladizo.pdf` (2026-10-01): plate
250x351x12, 5 Ø16 anchors, shear key. Site data, reinforcement and lessons come from the sibling
folders `../cantilever_anchor` (rev. 2, issued), `../cantilever_anchor_V2` and
`../cantilever_anchor_double_plate`. Read their READMEs for the history.

Status (2026-10-02): design, checks, drawings and report done. Workshop sheets not made.

## Run

```
cd cantilever_anchor_bolted_plate
octave-cli t1_bolted_plate.m    # checks, figures, capacity, reports/bolted_plate_report.html
```

Run it from inside this folder: the function names are the same as in the sibling folders.

## Files

```
t1_bolted_plate.m   MAIN: runs everything, prints the D/C table and clearances
t2_planos_taller.m  MAIN: workshop sheets (Spanish), reports/planos_taller_placa_empernada.pdf
make_workshop_sheets.m  the workshop sheets (JSON for ../python_support_scripts/joint_pdf.py)
ca_plate_page.m     review page reports/plate_check.html (end plate, step by step)
ca_anchor_page.m    review page reports/anchor_check.html (tension anchors and back plate)
ca_inputs.m         EDIT: materials, loads, geometry (single source of truth)
ca_calc.m           loads, types, clearances, limit states (R.rows), plate study, RAM review,
                    room for site errors
ca_capacity.m       largest Mu per type: scales all forces until the first check reaches 1.0
ca_draw.m           figures as SVG (drawing tools copied from the double plate folder)
ca_report.m         HTML report; every number comes from P, R, C
reports/            bolted_plate_report.html, figures/*.svg|png
```

Units: N, mm, MPa inside; kN, m in loads. Axes as in the sibling folders: z from the top of the
concrete beam (= top of steel), u from the outer face into the column, v across from the beam
axis. Types: 1 E (edge), 2 C1 (corner, one cantilever), 3 CX and 4 CY (corner with two
cantilevers, beams X and Y).

## Design (final, 2026-10-02)

- **Loads:** from the user's ETABS model (edge cantilever B16 at the column face): Mu = 1.779 MD + ML =
  22.08 kN m. Ev = 0.579 D is added, because it is not in the ETABS combinations. The tributary areas
  (L = 1.12 m) give 19.74; the ratio 1.118 is applied to every case. Corners: CX/CY 17.20, C1 12.13 kN m.
- **End plate:** ONE plate for all types (user 2026-10-02, holes drilled on site to the survey):
  PL 12x160x350 A36, top at +85 (`P.ep.ztop`), 25 below the bottom flange. Hole to top edge 29 (CY)
  or 56. Rib PL 12 on the web line, 85 x 150. 2 extra plates PL 12x68x85 A36 on the column side, with a
  24 gap over the rib. Fillets 6 only on the bottom edge (flange line) and the inner edge (rib line),
  in the shop; the outer and top edges are flush with the end plate and not welded (user's review:
  there is no face for a fillet there, and 12 mm was too narrow for two fillets). Holes Ø18, drilled to
  the surveyed anchors. Tension side 0.66, strict 0.73.
- **Top anchors:** 2 Ø16 straight, threaded M16x2 both ends, L = 479, |v| = 35, z = +29 (CY +56).
  Back plate PL 12x45x120 A36 at u = 365.
- **Shear anchors:** 2 Ø16, L = 187, z = -201.2, nut at u = 100.
- **Grout pad:** 30 mm (18 under the extra plates). Beam and rib welded on site.
- **Results:** every check passes. Highest: beam in line 0.85, top anchor tension + shear 0.84,
  bearing on the concrete face 0.92 (all types), strict bearing side 0.79 (was 0.93 with the 320 plate). Largest Mu 26.1 kN m
  (E), limited by the anchor interaction.
- **Open:** the VCM stacked pairs form a hooked bundle (R25.6.1.5). Counting only the 3 top-line bars,
  the beam in line is at 1.34 (1.13 with ETABS alone). This is the user's beam design.

## User decisions (2026-10-02)

- Areas were short, not loads: use L = 1.12; Mu ≥ "a bit above 20" (edge) and 15.55 (corner).
- 5 anchors as in RAM → 4 (an odd number always puts one on the mid-face column bar at v = 0).
- 18 mm plates not available; 12 mm Gr50 (A572/A588, Fy 345) is the strongest. Fu taken as 450.
- Back plate instead of hooks for the top anchors.
- **Strip method governs the plates.** Yield lines are an upper bound and are shown as info only.
- No formwork in drawings.
- Edge and one-cantilever corners: the beam in line is VCM (5 Ø12 top: 3 in a row + 2 in contact
  under the corner bars). One bar per stacked pair is counted. Corner with two cantilevers: VCS
  assumed (conservative).
- Thicker plate if available: 14 mm Gr50 or 16 mm A36 → the plate no longer governs, largest Mu
  26.4 kN m (limited by the top anchor, tension + shear). 14 mm A36 → 21.4; 12 mm A36 fails (1.30).

## History of this folder (same day)

1. Hooked anchors (90° hook down behind the far ties). PL 250 wide. 18 mm A36 → user: not
   available. Backup of that version in the session scratchpad only.
2. 12 mm Gr50, 40 below the flange, rib added (CY failed without it).
3. Back plate instead of hooks, anchors at |v| = 40, strict strips.
4. Double check: the DG1 bearing-side strip **beyond the flange tips (n)** had been left out. At
   B = 250, n = 77 and D/C = 1.60. Changed to B = 160, 30 below the flange, |v| = 35, back plate
   120 wide.

## Open items

- Concrete beams behind the column (frame item): cantilever moment at the far face 35 / 27 kN m
  against the room quoted in rev. 2 (32 / 16 kN m). The frame support moments are needed.
- Ends of the top anchors are 1 mm from the far face, above the beam top (covered when the slab
  is cast). CY back plate: 24 mm cover to the pedestal top, under the base-plate grout.
- Confirm that the shop threads M16x2 on INEN 2167 bars (Ase 157 used).
- Workshop sheets, if this option is chosen.

## Notes for agents

- Strip (lower-bound) checks are valid only if each strip lands on a real support. Widths are cut
  at the flange tip + fillet and at the rib height (`R.strip`).
- DG1 bearing side: check **both** m and n (n = (B - 0.8 bf)/2). RAM reports both.
- mutool renders `<sub>` badly. `cv_end` strips sub/sup tags from the figures; the HTML keeps them.
- Do not read clearance values in labels by row index (`R.clr{k,2}`); the rows move. Compute them.
- Independent hand check of type E (scratchpad `hand.m`, session 2026-10-02) matched every ratio.

## Workshop sheets (2026-10-02)

`octave-cli t2_planos_taller.m` writes `reports/planos_taller_placa_empernada.pdf` (A4, Spanish, 2 sheets)
with `../python_support_scripts/joint_pdf.py`: quantities + anchors A1/A2 + back plate B1 + notes;
end plate P1, one for all types (PL 12x160x350 A36, 2 refuerzos S1 12x68x85, rib R1 85x150), the CY
hole level dashed. Counts in `opts.n = [E C1 CX CY] = [1 2 1 1]` (from rev. 2: confirm).
All beam and rib welds are site welds (flag); only the extra plates are shop-welded. Holes are drilled
to the surveyed anchors. No assembly steps on the sheets (user).
Plate review pages: `reports/plate_check.html`, `reports/anchor_check.html` (`ca_plate_page.m`, `ca_anchor_page.m`).

- 2026-10-04, pour-sheet review (user): sheets name the connections by column (C4 = type E, B4 / D3 = C1,
  D4X / D4Y = CX / CY); column names in the detail titles. Sections renumbered in reading order of the A2
  sheet: 2 C4/B4/D3 (2.5 = hooks side view, was 7.4; 2.6 = plan at A1, was 2.5), 3 D4 (3.5 = side view, was
  7.5), 4 D4 beam bars (was 5), 5 B4/C4/D3 beam bars (was 4), 6 C4 bars (was 7.1-7.3), 7 pieces (was 6).
  Texts moved out of the small drawings into captions; "todas con gancho" in bold; "gancho contra los
  estribos" on the left of the sections; dims rounded (201); notes: threaded rod similar to Global Pernos,
  grout similar to SikaGrout-212 / INTACO Maxibed. "2 adicionales" renamed (the 2 bars at -80 / over the corners).
- 2026-10-04, IPE 200 floor beams to the VCM (user's concept: PL 300x300x10 A36, 4 through rods Ø20 fy 4200,
  web-only weld). Rods are CAST IN (VCM not poured yet); layout P.s2: rows -75 (under the VCM top bars, inside
  the cage: no cover loss) and -200 (was -260), +-110 from the IPE axis, 40 from a stirrup. Demand 23.2 kN per
  end (1.2D + Ev + L, trib 1443, span 4780); 31.1 with Ev x Omega0 (17.10.6.3c), used. ACI 17.7.2 breakout
  toward the VCM soffit: lower row (half) 0.40, upper row (all) 0.45 (was 0.71 with -260); rod steel 0.15;
  web weld 5 both sides x 150: 0.14; web shear 0.25. Edge VCM (A, D): torsion 5.0 kN m > phi Tth 2.4 ->
  closed stirrups (Ø10@140 phi Tn 16.4) + longitudinal Al ~270 mm2; not in ETABS (pinned at the beam axis).
  Workshop sheet section 3 (border beam now 4.x); marks PV (16), AV (32, L 380), TV, WV.
  Pour sheet: section 8 (8.1 VCM face at a support, 8.2 section through the rods), AV row in quantities and tolerances.
- 2026-10-04: pour sheet on ONE A1 landscape sheet (opts.page = 'A1L', hk 1.05, fs 1.05). pour_pdf.py maps A1L onto joint_pdf's A2L path (swaps its A2 for A1); joint_pdf.py unchanged. Bar-count braces: one bold number per beam (never the sum of two beams).
- 2026-10-04 (later): pour sheets on TWO A1 sheets, 3 columns each (opts.layout {{[1 6], 2, 3}, {4, [5 8], 7}}),
  hk 1.5, fs 1.5 (labels 2.9 mm), title block 45 mm with text x1.5 (pour_pdf.py now has its own main: A1L
  page and frame.tb; joint_pdf.py unchanged). Sections renumbered in reading order: 1 location, 2 C4 bars,
  3 C4/B4/D3, 4 D4, 5 D4 beams, 6 B4/C4/D3 beams, 7 AV rods, 8 pieces and notes. All captions and notes
  rewritten short and plain. reports/prueba_impresion_A4.pdf: A4 windows of each sheet at true size (print at 100%).
- 2026-10-04 (later): user's ETABS negative moments at the face: D4 along 4 24.3, D3 along 3 23.0, B4 along B 30.0
  kN m. + Ev share (CX 5.7, C1 4.0): grid 4 (3 Ø12, phi Mn 34.4) 0.87, grid 3 (3 Ø12) 0.78, grid B (5 Ø12, 54.4)
  0.63. No more bastones: only C4. AV upper rods lowered to -105 (the VCM 5+5: its 2-bar top bundle at -68/-80
  clashed with -75); breakout 0.40 / 0.48. Sheets: drawing text at the caption-note size (7.2 pt x fs), fs = hk =
  1.4; "pata" (to the outside of the bar: Ø16 256, Ø12 192) instead of "cola"; 5.4 removed; bottom-bar rules moved
  to the notes; 3.1, 3.2, 4.1, 4.2, 5.2, 5.3, 6.1-6.3 full width; section 6 split over two columns; new 7.3 (AV
  assembled); VCM bars 5+5 drawn in 7.1, 7.2 and in the workshop detail 3.1.
- 2026-10-04: there are no VCP beams (user): the N-S beams of grids A, B, C, D are VCM; renamed everywhere.
- 2026-10-04: bastones also at D3 and D4X (user). There they go on the level of the beam in line (-68), pegados to
  its corner bars (grid D's 2 bars cross at -80), hooks 16 behind; same bar as C4 (6 in total). Calc: P.cb.bas.types
  [1 0 1 0] (C1 left without them: B4 has none), P.cb.bas.zt by type, P.cb.nin top bars of the beam in line
  [5 5 3 5], P.etabs.Mneg (user's M- at B4 30.0 and D4-grid 4 24.3). New row: T + M/jd <= 0.9 As fy (upper bound,
  the cantilever counted twice): 0.90 / 0.83 / 0.83 / 0.95. Beam in line: 0.63 / 0.63 / 0.54 / 0.68.
- 2026-10-04: pour sheets restructured (user): one COMPLETE section per joint, nothing faded (dr_cut = dr_sect +
  dr_bsect, solid styles r_colS / r_rodS): 3.1 B4/C4, 3.2 D3, 4.2 D4X (new: D4Y anchors cut, level C hooks),
  4.3 D4Y; plan 4.1 = anchors + beam bars (dr_plan4). Old sections 5 and 6 (beam bars) removed; 6.4 plan at A2
  removed. Sections now: 1 location, 2 C4 bars, 3 C4/B4/D3, 4 D4, 5 IPE 200 shear connection (AV), 6 pieces and
  notes. Key plan: bastones drawn one each side of the beam with their pata, beam ringed by a dashed tomato oval,
  one comment "Armado de la viga + 2 bastones Ø12" (D3 / D4X beams are VCS, so not "VCM").
- 2026-10-04: AV upper rods ON the VCM top bars at -40, tied to them (user; cone 0.41, was 0.49 under them at -105). For gravity shear the working reinforcement is on the soffit side (bottom bars + stirrups), not the top bars.
- 2026-10-04 (sheets only, calcs unchanged at f'c 210): note 10 asks f'c 240 kg/cm2 (vigas, nudo, pedestal);
  bastones also at B4 (sheets: 8 in total; the calc still credits them only at C4 and D4X, conservative);
  key plan: bastones drawn beside each beam (no pata), dashed oval, one comment for B4, C4, D3, D4X; counts as
  "7 Ø12 = 5 Ø12 (refuerzo de VCM) + 2 bastones Ø12 para el nudo"; bar levels as plain numbers at the beam end;
  3.1 has a 3D of the 5 bottom bars; pata = 16 db rounded up to 5 mm (Ø12 195, Ø16 260); notes 1, 3, 7, 8, 11
  reworded; thicker leader ('lead') for "gancho contra los estribos". Study of lowering A1 / two rows (option D)
  in scratchpad low_study.m: not adopted (user: stay as we are).
