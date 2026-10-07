# Cantilever anchorage, third concept: through-rods and a bolted end plate ("double plate")

Folder created 2026-10-01. **Status (2026-10-01): scheme done, waiting for the user's review.**
See "Scheme (2026-10-01)" at the end. The sections below are the original briefing for whoever
(human or agent) works on this design. Read it all before touching anything, then
read the two sibling designs it builds on:

- `../cantilever_anchor/`: revision 2, **issued**. Shop drawings were sent; do not change it
  without the user's explicit approval. Its README has the full history and a list of the
  mistakes made and caught.
- `../cantilever_anchor_V2/`: revision 3, the "variant", under review. It has the most
  complete code (`ca_inputs` -> `ca_calc` -> `ca_draw` -> `ca_report`), which is the best
  starting point to copy from.

## 1. The problem

Steel IPE cantilevers on the edge and at the corners of a building leave from 40x40 cm
concrete pedestals. The connection has to take the cantilever moment into the joint of the
pedestal with the concrete beams behind it. The two earlier designs weld the beam on site to an
embed plate with hooked bars behind it. This concept replaces that with:

- straight threaded rods running through the joint along the beam axis, anchored at the far side by
  nuts and washers bearing on the concrete (cast-in headed anchors, ACI 318-19 chapter 17);
- the rods sticking out of the outer face;
- the steel beam with an extended end plate, bolted to the rods on site, with shims or grout behind it.

The user proposed "a second plate on the other side of the column". The far face is inside
the concrete beam that frames in there, so a single back plate would be cast inside concrete.
Nuts with washers per rod do the same job and leave much more room. An agent called this the best
ranked option on 2026-09-30, but the user chose to improve the welded concept first (V2). This
folder is for comparing.

## 2. Situation at site (as of 2026-10-01)

- The pedestal is already cast up to the beam soffit (cold joint at z = -350). Its 8 Ø16 bars
  stick up through the joint; their 90° top hooks are **not bent yet**.
- The cage of the concrete beams is **already tied in place**. Exact bar positions are not known.
  The user was asked for measurements and the answers are still pending:
  1. at the far side of each joint, the |v| of every top bar of the beam in line with the cantilever,
     and whether the VCM bar pairs were separated;
  2. at each corner, which beam is VCM and which is VCS;
  3. whether the far-face joint ties are in place;
  4. which beam's top bars are on the upper layer.
- The pour of the joints was planned for 2026-10-01 and has been delayed; the user has "about one
  day" of design time. The schedule decides how far any new concept can go.
- The site is "not very strict". Design for ACI placing tolerances at least (section 6).
- Beams are welded (or would be bolted) on site after the pour. The shop makes the embedded
  assemblies. Count ordered for revision 2: 1 edge (E), 1 corner C1, 3 corner C2.
- Placing the assemblies **from the front** (through the open outer face) is not possible for the
  hooked designs: their hook tails would cross the crossing-beam top bars and the joint ties. Only
  **from above** works. Straight rods without tails might be slid in from the front. Verify this
  with a drawing; it is a possible advantage of this concept.

## 3. Geometry (all from `../cantilever_anchor_V2/ca_inputs.m`; copy that file)

Axes: z from the top of the concrete beam (= top of steel), up. u from the outer face of the column,
into the column. v across, from the beam axis. Units N, mm, MPa.

- Pedestal 400 x 400, cover 40, ties Ø10. 8 Ø16 (4 corners + 4 mid-face), so bar axes at 58 mm
  from each face: u = 58 and 342, v = 0 and ±142. The **mid-face bar sits right on the beam axis**
  behind the plate (u = 58, v = 0), the main obstacle for anything at v = 0. The pedestal ends at
  z = +100 under a steel column base plate. 4 Ø12 rods of that base plate at (±100, ±100) from the
  column axis, i.e. u = 100 and 300, v = ±100, vertical, with 180° hooks.
- Concrete beams 30x35. VCS: 3 Ø12 top at v = 0, ±94 (bottom the same). VCM: 5 Ø12 top =
  3 on the top line (0, ±94) + 2 **in contact under the corner bars** (user, 2026-10-01). The bottom
  bars mirror this (2 over the bottom corners). The edge beams crossing the edge joint are VCS. Which
  beam is on top is not known: top line at -56 for the beam on top. A VCS under a VCM passes under the
  stacked corners at -80. A VCM under a VCS has its top line at -68 and its pairs at -80.
  Bottom lines around -294 / -270.
  (Earlier documents assumed "2-1-2 pairs side by side, separated at ±57". That was wrong.)
  Stirrups Ø10 at 7 / 14 cm. Top bars hooked down at the outer face, outside of the hook at u = 50
  (the centre bar may stop at u = 66, behind the mid-face column bar; at the far face it must step
  around the far mid-face bar).
- Joint ties added for the hooked designs: 4 layers at z = -95 (was -90; moved to clear the bars
  at -80), -135, -180, -225, each 4 straight Ø10
  with 135° hooks around the corner bars, + 1 closed tie at z = +45 placed after the assemblies.
  If this concept is chosen, these can be re-planned.
- Composite deck slab 110 thick (deck 55) on top of the beams. An extended end plate rising
  above z = 0 needs a notch in the deck.
- Edge column: the beam in line is behind the far face. The edge beams run along the face, through
  the joint. Corner: one beam in line behind each of the two outer faces.
- Behind the column there is a concrete beam, so at the far face within |v| ≤ 150 the 40 mm cover
  is not needed: the concrete continues into the beam. The user pointed this out. Anchors may end
  there, e.g. past the far ties.

## 4. Loads

NEC-SE-DS vertical seismic: Ev = (2/3) I η Z Fa = 0.579 of D. qD = 2.5 kN/m², qL = 2.0 kN/m².
Combination 1.2D + Ev + L governs (q = 6.45 kN/m²; 1.2D + 1.6L = 6.20; 0.9D - Ev = 0.80, still
downwards, so the moment never reverses). Cantilever 1.3 m from the column axis, loaded length
L = 1.1 m from the face. Edge tributary width 4.8 m. Corner: the user's trapezoid 2.4 / 3.7 x 1.3 m,
plus an "envelope" with the whole corner square on one beam (conservative).

At the column face (IPE 240 self-weight included):

| Case | Vu (kN) | Mu (kN m) | Flange force M/(h - tf), IPE 240 (kN) |
|---|---|---|---|
| Edge | 34.6 | 19.05 | 82.7 |
| Corner, trapezoid | 22.9 | 13.32 | 57.9 |
| Corner, envelope | 26.8 | 14.75 | 64.1 |

With IPE 200 the edge flange force is 99 kN. Frame forces at the edge pedestal (ETABS,
1.2D + L - Ex): column 21.04 kN m and 15.65 kN; edge beams 26 and 5.126 kN m (signs uncertain:
added). The support moments of the concrete beams were never received. The VCM has about 32 kN m of
room left and the VCS about 16 (φMn 58.0 and 36.0 kN m).

Materials: f'c = 210 kg/cm² = 20.6 MPa. Rebar fy = 420, fu = 550, weldable (INEN 2167 / A706).
Plates A36 (Fy 248, Fu 400). E70 electrode. Rod material for this concept is to be chosen:
ASTM F1554 Gr 36 / 55 or equivalent, and check local availability.

## 5. What this concept must check (start list)

- **Layout first, before any number.** The rods run along u at the flange level, and there are only two
  free bands. Above the top flange: 0 to about +34, limited by the column-bar top hooks and the closed
  tie at +45 (both can still be adjusted). Below the flange: -10 to -50, limited by the beam top bars.
  Nut tightening needs about db + 13 mm from the flange face to the rod axis (≈ 29 for M16). The edge
  fits with rods at v = ±28, z ≈ +29 and -39, if the closed tie moves to +50 and the column hooks are
  bent along the beam. **The corner is the hard case:** X and Y rods cross, so each corner beam probably
  gets one rod row, eccentric to its flange. The beam whose top bars are on the upper layer takes the
  rods below its flange, running parallel to its own bars.
- Rods parallel to the beam top bars at v = 0, ±57, ±94 (or ±82): lateral clearance. Nuts and washers at
  the far end (u ≈ 330, inside the core, before the far column bars at u = 334..350) must clear the
  beam bars and the rods of the steel column.
- ACI 318-19 chapter 17 for cast-in headed bolts:
  - steel in tension and shear, and their interaction (17.8);
  - pullout Np = 8 Abrg f'c (17.6.3.2.2);
  - side-face blowout (17.6.4): hef is large compared with the 100 mm to the pedestal top;
  - concrete breakout, about 31 kN unreinforced in this pedestal: it fails, so anchor reinforcement is
    needed (17.5.2.1). The beam top bars again, developed on both sides of the breakout surface, within
    0.5 hef of the anchors, full fy (no excess-steel reduction);
  - check with the ACI placing tolerances, as in V2.
- End plate: AISC Design Guide 4 / 16 (extended or flush end plate), with prying. The rods are the bolts.
  Bearing of the end plate on the concrete face, with grout or shims.
- Shear: by the rods (with interaction), or by bearing at the bottom. V2 used the platinas as a shear lug
  under 17.11 (needs at least 4 anchors and hef/hsl ≥ 2.5).
- Joint shear (15.4.2), the beam negative moment, the pedestal (paths 1 and 2 in the other reports).
- Placing sequence and template: how the rods are held in position during the pour (the embed plate with
  holes as template is one option), tolerances of the rod positions against the end-plate holes
  (oversized holes and plate washers), protection of the threads.
- Torsion at the corner (eccentric tributary) as in the other reports.

## 6. Lessons (humans and agents)

From the two earlier designs (details in `../cantilever_anchor/README.md`, "Error prone"):

- **Geometry kills these designs, not strength.** Forces are small (Mu about 19 kN m). Every
  difficulty was a clash or a few millimetres. Draw every layout in plan, both elevations and
  the outside view **before** computing. Make a clearance table from the inputs. Render SVGs
  with `mutool draw -o x.png x.svg` and look at them; there is no browser.
- Mistakes that were actually made:
  - assumed 4 column bars (there are 8; the mid-face bar is on the beam axis);
  - overlapping corner pieces;
  - colliding bar layers;
  - a wrong hook leg length;
  - hooked bundles (outside ACI);
  - weld length counted where bars sit;
  - AISC J2-5 directional factor and J2.4(c) used out of scope;
  - the wrong lever arm when the bars are offset from the flange;
  - 17.11 used with fewer than 4 anchors;
  - the SI joint-shear coefficient rounded;
  - **ψc of hooks written from memory as f'c/105 + 0.6; the SI form (ACI 318-19 Appendix E) is
    0.01 f'c + 0.6**;
  - **the hook tails crossing the beam top bars left out of the clearance table** (gaps of 4 mm, or a
    clash, found only when the user asked for a placing drawing).
- Verify every clause against the PDFs in
  `/mnt/c/Users/winpat/Desktop/Bibliography4structures/02 NORMATIVAS/`: ACI 318-19 (inch-pound, SI forms
  in Appendix E, page 592 of the PDF), ACI 318S-14 (Spanish), AISC 360-16, AISC 341-16, PCI Design
  Handbook 7th ed., NEC. `pdftotext -layout` + grep works, but symbols and limits often come out
  garbled. Render the page (`mutool draw -r 110 -o p.png file.pdf <page>`) and read it, as was done for
  17.11.1.1.8 (hef/hsl ≥ 2.5) and Appendix E. AWS D1.1 / D1.4 are not available; quote them only
  through AISC or PCI and say so.
- Apply placing tolerances against the design: ACI 318-19 Table 26.6.2.1(b), ±25 mm for bar ends at
  discontinuous ends; Table 26.6.2.1(a), ±13 mm in d for members deeper than 200. V2 shows how
  (`cone()` and `pick()` in `ca_calc.m`), with per-bar "may fall short" limits turned into a site
  hold point.
- External reviews (the user forwards comments from other AIs, e.g. Gemini) can be right or wrong.
  Check each claim against the code text and say which parts hold. One wrong claim (a supposed
  ψr = 0.8) led to finding the real ψc error.
- Lower-bound models (plate alone, no spreading, simply supported) are what the user wants as
  "proof". Say when an assumption is not conservative (e.g. a point load on a simply supported strip).

## 7. How the user works

- Metric only. MATLAB-only syntax, run with `octave-cli`. Keep the code style of the sibling folders:
  `ca_inputs` as the single source of truth, `R.rows` limit-state table, a report where every number
  comes from R or P, and drawings generated from the same inputs.
- **Ask before changing their code**; propose first, then document every change in the README.
  New folders for new concepts (that is why this folder exists). Issued material stays untouched
  unless they approve a fix.
- Conservative by default ("be conservative" where data is missing), but say how much is gained or
  lost by each assumption.
- They want to see things. Numbered figures with titles, one colour code everywhere:
  - red: anchors;
  - grey: beam bars;
  - brown: column bars;
  - green: rods of the steel column;
  - purple: ties;
  - dark blue: plates.

  Visual confirmation for any placing or clearance claim: draw it, with gaps labelled.
- Equations written out with numbers and clause numbers ("easy check" steps). Short direct
  sentences.
- Workshop sheets in Spanish, short notes, workshop-only content (no calculations, no electrode
  class), terms "platina superior / inferior" (not "orejeta").
- Printer for sheets: `../python_support_scripts/joint_pdf.py`, as used by
  `../cantilever_anchor/t2_planos_taller.m`.
- The desktop side panel only opens files under `structures/joint_calculations`. That is why the
  projects live here. They are untracked in the repo: do not commit them without asking.

## 8. Suggested first steps

1. Copy `ca_inputs.m` from `../cantilever_anchor_V2/`, remove the platina and hook entries, and add
   rods (diameter, grade, positions u/v/z, nut and washer size, end plate).
2. Draw the edge and corner layouts in plan and elevation with every bar of section 3. Compute a
   clearance table for both possible layers (-56, -68) and both VCM layouts. Show it to the user
   before any strength check.
3. Then the chapter 17 checks, the end plate and the report. Reuse the V2 drawing tools (`cv_*`,
   `hook`, `draw_ties_plan`) and report helpers.
4. Compare with V2 in one table (ratios, site steps, risks, cost) so the user can choose.

## Scheme (2026-10-01)

Run from inside this folder: `octave-cli t0_scheme.m` writes `reports/scheme.html` and
`reports/figures/*.svg|png`.

Files:
- `ca_inputs.m`: site data and loads copied from V2, plus rods (`P.tr`), front plate (`P.fp`),
  back plate (`P.bp`), CY heads (`P.hd`), end plate (`P.ep`). The platina and hook entries are removed.
  The closed tie moves to +50.
- `ca_layout.m`: loads (same code as V2), rod levels, the three assembly types (`R.typ`),
  clearance table `R.clr`, first sizing `R.pre` (not the final limit-state table).
- `ca_draw.m`: edge and corner plans and elevations, outside view, the two embedded pieces, and the
  5-step placing sequence. The drawing tools at the end are copied unchanged from V2.
- `ca_scheme_report.m`: the scheme page.

Layout chosen:
- Rods M16 (F1554 Gr 36 minimum, Gr 55 better). Tension rods at pf = 29 from the flange face
  (d + 1/2 in, DG4/DG16). Shear rods 29 over the bottom flange, in the compression zone.
- Type E (edge) = CX (corner, beam with its bars on the lower layer): 2 rods over the top flange,
  z = +29, |v| = 40, back plate PL 16x60x150 at u = 365..381 (behind the far column bars and the far
  tie, inside the beam in line). Shear rods z = -201.2, |v| = 28.5.
- Type CY (corner, beam with its bars on the upper layer): 2 rods under the top flange, z = -38.8,
  |v| = 30, each with a plate washer 32x32x10 and a heavy nut at u = 360. Shear rods z = -157
  (between the ties at -135 and -180).
- Front plate PL 12x180 flush with the face (template + bearing). End plate PL 20x150, shop welded.
- Joint ties stay as planned. Column hooks bent along the steel beam (corner: along X).

Placing (figure 9): front plate + shear rods pushed in from the outer face; back plate lowered
from above; tension rods pushed in from the front through both plates; nuts from above;
hooks, closed tie, pour; beam bolted after curing.

Findings:
- Placeable with the site as it is. Smallest gaps: 5 (back plate - far tie; CY washers - own bars
  if CY is a VCM with its pairs separated), 6.5 to 8 (nuts - fillets on the end plate; shear rods -
  ties). Corner hold point: CY rods 15 mm over the other beam's bars, 2 mm with the full ACI tolerance.
- First sizing max D/C 0.80 (rod steel, Gr 36). Side-face blowout of CY was 1.06 with a heavy
  nut alone, so a plate washer was added (0.77).
- Unreinforced breakout 26 kN << T: anchor reinforcement is still the beam top bars, but all of
  them count (D/C 0.40 to 0.70) and lie at least 196 mm inside the body with tolerances (ldh 150).
- 17.10.5: Ev share 22 % > 20 %; option (d) amplifies only Eh, so there is no amplification here.

Next: user review of the scheme, then the full limit-state table (list in the scheme page,
section 9), report, workshop sheets, and the comparison with V2.

### Scheme revision 2 (2026-10-01, after the user's decisions)

User decisions: (1) layout accepted; (2) find a rod supplier in Cuenca; (3) unknown bar layout:
"assume that they are below, the most conservative" -> every check takes the least favourable layer
(lower for strength, upper where it reduces a clearance), corner beams VCS, VCM pairs in contact for
strength and separated for clearances.

Changes:
- Corner type CY (rods under the flange) dropped: with the crossing bars on the upper layer it
  clashes (3 mm nominal, negative with the 13 mm tolerance). Both corner beams now have their rods
  over the flange: CX at z = +29 ("rods low"), CY at z = +56 ("rods high"), crossing 11 mm apart.
  All types have a back plate PL 16x50x150. Nothing depends on the bar layers.
- Rods 5/8"-11 UNC ASTM A193 B7 (Ase 146, futa 860), heavy hex A194 2H nuts on the tension rods,
  regular hex nuts on the shear rods. F1554 was not found in any Ecuadorian catalogue; B7 is stocked.
  Suppliers (web, 2026-10-01): BP Ecuador, Cuenca (2 branches, grade 5 rod listed, ask for B7);
  Importadora Banco del Perno, Cuenca (listing only); Castillo Hermanos, Quito (B7 listed);
  Casa del Perno, Sangolqui (B7 listed). Details in the scheme page, section 7.
- ACI 318-19 10.7.6.1.5 found: the steel column anchor rods in the top of the pedestal need two
  No. 4 (or three No. 3) ties within 127 mm of the top. Added 2 closed ties 14 mm at -22 and +6,
  placed before the rods. The earlier designs (cantilever_anchor, V2) had only one tie there.
- Column hooks: along the beam at the edge, along Y at the corner (hold point: 7 mm over the
  rods of X); the two mid-face hooks on one line go side by side.
- First sizing: rods 0.27 to 0.38; governing items anchor reinforcement of the edge (0.67, 3 bars
  counted) and the CY end-plate strip (0.73, lower bound); bars inside the breakout body 179 mm
  or more with every tolerance against (ldh 150).

## Limit states (2026-10-02)

`octave-cli t1_cantilever_anchor.m` runs everything: `t0_scheme` (layout, drawings, scheme.html),
then `ca_calc.m` (R.rows, 23 checks: rods, ch. 17, anchor reinforcement, end plate DG4/strip/prying,
shop welds, beam, front/back plate, joint shear, concrete beam, pedestal shear) and `ca_report.m`
(reports/cantilever_anchor_report.html, a table with every equation written out for type E).
User asked for no comparison with V2 (budget).
Results: highest D/C 0.84 (hook development of the beam bars inside the breakout body, CY, all tolerances
against). Open frame item: the cantilever moment at the far face of the column (32.9 kN m edge,
25.5 kN m corner) against the room left in the concrete beams (32 / 16) = 1.03 / 1.59, ignoring the share
taken by the pedestal. The same applies to V2 and revision 2. Needs the frame support moments.
Not done: workshop sheets.
