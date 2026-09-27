# Direct-welded moment joint: verification manual (v1)

Companion to `dwj_lib.m`. Every check in the script has a tag, and this document
uses the same tags in the same order.

**Purpose.** This is the connection we are *not* using: the beams welded
straight onto the HSS column faces, with no collar plates. It is checked with
the same forces, beam and column as the collar joint (`dmj_lib.m`, manual
`diaphragm_joint_manual.md`). It exists to show, with code equations, why the
collar is needed.

References are to **AISC 360-16** unless stated otherwise. In 360-16, K2.3 says
that connections to rectangular HSS with concentrated loads are checked with the
limit states of **Chapter J**; there is no plate-to-rectangular-HSS table any
more. Chapter K still supplies two things used here: the **effective width Be**
of a plate on an HSS face (**K1-1**) and the **weld effective length** (**K5**,
**Table K5.1**). Checks that only exist in AISC 360-10 (Table K1.2) are marked
**[360-10]**. EN 1993-1-8 is used once, as an `[INFO]` cross-check. Numbers quoted are for joint 10 (interior,
four IPE 160, HSS 200x100x4).

---

## 1. The connection

The column runs to the top of the beams. Each beam is cut square and welded to
the column face:

- **Flanges**: fillet welds on both faces of each flange, across the column
  face (`fl_type = 'fillet'`), or CJP (`fl_type = 'cjp'`).
- **Web**: fillet welds on both sides, along the web height.

In AISC Chapter K terms, each flange is a **transverse plate** on the face of a
rectangular HSS, and the web is a **longitudinal plate** on the same face.

Which face a beam lands on matters:

| Beams | Land on the face of width | Side walls along the force | B/t, 4 mm wall | beta = bf/B |
|---|---|---|---|---|
| strong direction (column M3) | B = 100 mm | D = 200 mm | 25 | 0.82 |
| weak direction (column M2) | D = 200 mm | B = 100 mm | **50** | 0.41 |

The strong-direction beams bend the column about its strong axis, but they land
on the **narrow** face.

---

## 2. Force paths

**Moment** becomes a flange couple, T = |M| / z + |N| / 2, with
**z = h - tf = 152.6 mm** (flange centre to flange centre). There is no plate
here to lengthen the lever arm: the collar joint uses 172 mm.

**The flange force goes into a 4 mm wall that spans between the side walls.**
The face is a thin plate loaded across its middle. It bends out of plane, so
almost all of the force goes through the two stiff strips next to the side
walls. The rest of the flange width does very little. This is the whole issue,
and it is what F1 measures.

**Shear** goes through the web welds into the face, parallel to the column axis.

**Net force**: the unbalanced part, column-top moment / z, leaves through the
column walls, as in the collar joint (C1 here, T8 there).

---

## 3. Resistance factors

| phi | Applies to | Reference |
|---|---|---|
| 0.90 | flange yielding over Be | K1-1 + J4.1 |
| 0.95 | punching shear [360-10] | 360-10 K1-8 |
| 1.00 | side wall local yielding (walls as webs) | J10.2 |
| 0.75 / 0.90 | side wall crippling / compression buckling | J10.3 / J10.5 |
| 0.75 | welds | J2.4 |
| 0.90 | flange yielding, wall shear yielding, flexure | J4, F2, F7 |
| 1.00 | beam web shear (compact web) | G2.1 |
| 1.0 (gamma_M5) | face plastification, `[INFO]` | EN 1993-1-8 |

---

## 4. Limits of applicability, AISC 360-10 Table K1.2A (reference)

360-16 has no such table: K2.3 sends rectangular HSS to Chapter J. The 360-10
limits are kept as a guide to where the effective-width model was calibrated.

`dwj_validity` prints these for every face that has a beam.

| Limit | Strong face | Weak face |
|---|---|---|
| B/t <= 35, transverse plate (flange) | 25 ok | **50 OUT** |
| B/t <= 40, longitudinal plate (web) | 25 ok | **50 OUT** |
| 0.25 < beta <= 1.0 | 0.82 ok | 0.41 ok |
| Fy <= 360 MPa | ok | ok |
| Fy/Fu <= 0.8 | 0.62 ok | 0.62 ok |

**The weak face is outside the Specification.** The script still runs the
checks there, and prints `OUT`. Those results only show the size of the
problem. They are not a design basis in either direction. Section 11 relies on
the strong face alone, which is inside every limit.

---

## 5. Flange on the face

### B1 - Beam flange gross yielding, J4.1 (J4-1)

0.90 Fy bf tf = 0.90 x 250 x 82 x 7.4 = **136.5 kN**. This is the same as T2 in
the collar joint, but with the smaller lever arm, so the demand is higher.

### F1s, F1w - Flange yielding over its effective width, K1-1 + J4.1 (J4-1)

The face is stiff only next to the side walls, so only part of the flange can
deliver force. AISC 360-16 K1-1 gives that part, the effective width:

Be = (10 t / B) (Fy t / (Fyb tb)) Bb <= Bb

with t, B, Fy of the **column** face and tb = tf, Bb = bf, Fyb of the **beam
flange**. The flange then yields over Be (J4.1, phi 0.90):

phi Rn = 0.90 Fyb tf Be

- Strong: Be = (10 x 4/100)(250 x 4/(250 x 7.4)) x 82 = **17.7 mm** of 82 mm;
  0.90 x 250 x 7.4 x 17.7 = **29.5 kN**
- Weak: Be = **8.9 mm**; **14.8 kN**

This is the same limit state as AISC 360-10 eq. K1-7 (Rn = [10/(B/t)] Fy t Bp,
phi 0.95): multiplying out Fyb tf Be gives exactly that expression. Only phi
changed, 0.95 -> 0.90, because 360-16 routes the check through J4.1.

### F2 - Punching shear of the face [360-10], 360-10 K1-8

phi = 0.95. Rn = 0.60 Fy t (2 tp + 2 Bep), with Bep = 10 Bp/(B/t) <= Bp.

This only applies when 0.85 B <= Bp <= B - 2t, and it never does here: on the
strong face, 0.85 x 100 = 85 > 82. The script leaves it out when it doesn't
apply.

### F3, F4 - Side walls checked as webs, J10.2, J10.3, J10.5

Following K2.3, the two side walls are checked with the Chapter J web equations,
with t for tw and H - 3t for the web depth. They only matter when the flange
covers the flat width of the face, taken as Bp >= B - 2t `[MODEL]`. They never
apply here. When they do:

- F3, J10.2, phi 1.00: Rn = 2 Fy t (5k + lb), k = outside corner radius
  (`J.cl.ro`, 1.5 t when unknown), lb = tf
- F4, compression only, multiplied by Qf (section 7) as a reduction for column
  stress:
  - one beam, J10.3, phi 0.75: Rn = 1.6 t^2 [1 + 3 lb/(H - 3t)] sqrt(E Fy) Qf
  - two opposite beams, J10.5, phi 0.90: Rn = [48 t^3 / (H - 3t)] sqrt(E Fy) Qf

### F5s, F5w - Flange welds, K5 (K5-1) with le from Table K5.1

AISC K5: the weld is only as effective as the face behind it.
Rn = Fnw tw le (K5-1), phi 0.75, Fnw = 0.60 FEXX with no directional increase,
tw the throat. For a transverse plate welded on both faces, Table K5.1 gives

le = 2 Be

which is our case: each flange is fillet welded on its top and its bottom face.

- Strong: le = 2 x 0.40 x (250 x 4)/(250 x 7.4) x 82 = **35.5 mm** out of 164 mm
  of weld. Capacity 0.75 x 0.60 x 480 x 0.707 x 5 x 35.5 = **27.1 kN**
- Weak: le = 17.7 mm, capacity **13.5 kN**

**A bigger weld doesn't help.** le doesn't depend on the leg size, only on the
wall. F5 governs because K5 counts only the weld length that the wall can load.
Skipped with `fl_type = 'cjp'`, where F1 still applies.

### F6s, F6w - Face plastification, EN 1993-1-8 Table 7.13 - [INFO]

For beta <= 0.85: N = kn fy t^2 (2 + 2.8 beta) / sqrt(1 - 0.9 beta), with
gamma_M5 = 1.0.

- Strong: 250 x 4^2 x (2 + 2.8 x 0.82)/sqrt(1 - 0.9 x 0.82) = **33.6 kN**
- Weak: **15.9 kN**

This is a yield-line model, which is independent of AISC's effective-width
rule. It lands within 15% of F1 on both faces (33.6 against 29.5 kN, 15.9
against 14.8 kN). Two different theories give
the same answer, which makes that answer hard to argue with.

---

## 6. Web, column and members

### C1s, C1w - Column walls in shear, J4.2 (J4-3)

0.90 x 0.60 Fy x 2 L t, with L the wall length along the force, and demand =
column-top moment / z. This is the same model as T8 in the collar joint, with the
smaller z.

### W1 - Web fillet welds, J2.4 (J2-3)

Two fillets over Lw = h - 2(tf + r) = 145.2 mm each:
0.75 x 0.60 x 480 x 0.707 x 4 x 2 x 145.2 = **177.4 kN**.

### W2 - Wall against web thickness [360-10], 360-10 Table K1.2 / Manual Part 10

tp <= Fu t / Fyp, which requires the wall to be strong enough that it does not
rupture before the web yields. Fu t / Fy = 400 x 4 / 250 = **6.40 mm** against
tw = 5 mm, DCR 0.78. This is a proportioning rule, not a force check, and it is
reported in mm.

### W3 - Beam web shear, G2.1 (G2-1)

1.00 x 0.60 x 250 x 160 x 5 = **120.0 kN**.

### M1, M4, M5, M6 - Members

These are the same as in the collar joint. M6 needs `J.cl.phiPn` from ETABS.

---

## 7. The chord stress function Qf

AISC K1 and EN 1993-1-8 (kn) both reduce the face resistance when the column is
already stressed:

U = Pu / (Fy Ag) + Mcol / (Fy S),    Qf = 1.3 - 0.4 U / beta <= 1.0

S is taken about the axis the beams in that direction bend. The loaded face is
taken as in compression whenever U > 0, which can only lower Qf. At joint 10, U
stays below 0.26 and Qf = 1.0 in every case. The reduction matters only for a
heavily loaded column. The PDF sheet prints U and Qf per case (section 5).

---

## 8. Direct weld against collar, check by check

| Mechanism | Direct weld | Collar joint |
|---|---|---|
| Flange force into the connection | F1, F5: 10/(B/t) of the flange width works | T1: three-sided weld to a 12 mm plate, full width |
| Lever arm | h - tf = 152.6 mm | h + plates = 172 mm |
| Force into the column | through the 4 mm face in bending | through the collar welds around the whole perimeter (T7), then wall shear (T8) |
| Weak-direction face | B/t = 50, outside the 360-10 Table K1.2A limits | the plate spreads the force, so the face is not loaded in bending |
| Governing DCR, joint 10 | **3.93** (F5s) | **0.78** (S8) |

The collar fixes the weak link. It takes the flange force over its full width
into a 12 mm plate, and then delivers it to the column **all around the
perimeter** as shear in the walls, in their plane. The direct weld asks the
4 mm wall to carry the same force in out-of-plane bending.

---

## 9. Getting the demands and running it

These are the same demands as for the collar joint: `build_joint_db` once, then
`t2_direct_test.m`. `dwj_cases_from_res` is a copy of `cases_from_res` in dmj_lib,
kept separate so the two libraries stay independent. The equilibrium/mapping
check works the same way.

With `make_pdf = true`, t2 writes `reports/direct_joints.pdf` and
`reports/collar_joints.pdf` for the joints listed. The substituted formulas on
the direct-weld sheet are written by `dwj_checks` itself, next to each formula.

---

## 10. Not covered

- Beam torsion.
- The web as a longitudinal plate under beam axial force (the axial force is
  split between the flanges, as in dmj).
- The design wall thickness 0.93 t of AISC B4.2 for ERW tubes (nominal t is used,
  as in dmj). It would make every face check about 7 to 14% worse.
- Lateral-torsional buckling, fatigue, fire.
- Seismic detailing under AISC 341: not prequalified under AISC 358.

---

## 11. Worked numbers, joint 10

Gravity case **1.2D+L+1.6Lr**, strong direction:

| Step | Formula | Value |
|---|---|---|
| Beam moment | beam 38, abs(M3) | 16.22 kNm |
| Flange force | 16.22 x 10^6 / 152.6 + abs(-0.03 kN)/2 | **106.3 kN** |
| B1 | 0.90 x 250 x 82 x 7.4 | 136.5 kN, DCR 0.78 |
| F1s | Be = 17.7 mm; 0.90 x 250 x 7.4 x 17.7 | 29.5 kN, **DCR 3.60** |
| F5s | le = 35.5 mm; 0.75 x 0.60 x 480 x 0.707 x 5 x 35.5 | 27.1 kN, **DCR 3.93** |
| F6s [INFO] | 250 x 16 x 4.296 / 0.512 | 33.6 kN, DCR 3.17 |

Weak direction, same case: flange force 45.1 kN, F1w 14.8 kN (**3.05**), F5w
13.5 kN (**3.33**), on a face outside the Specification limits.

### What it would take

Running `dwj_lib` with a thicker wall (and ro = 1.5 t) gives this governing DCR:

| Column wall | Joint 10 | Joint 13 |
|---|---|---|
| 4 mm (actual) | 3.93 | 3.26 |
| 6 mm | 1.74 | 1.45 |
| 8 mm | 0.98 | 0.81 |
| 10 mm | 0.85 | 0.54 |

A direct weld needs an **HSS 200x100x8**, which puts both faces inside the
360-10 Table K1.2A limits. That is twice the wall, and about 1.95 times the column weight, just to
make the connection work. The collar joint does it with the 4 mm column and two
12 mm plates.

### Three checks to do first

1. T = 16.22 x 10^6 / 152.6 = about 106 300 N. Everything scales with z.
2. F1s = 0.90 x 250 x 7.4 x 17.7 = 29 520 N. Compare it with T: this is the
   whole argument.
3. le = 2 x 0.4 x (1000/1850) x 82 = 35.5 mm, against 2 x 82 = 164 mm of weld
   actually laid.
