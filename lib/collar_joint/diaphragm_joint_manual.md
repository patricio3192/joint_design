# Diaphragm moment joint: verification manual (v5, welded flanges)

Companion to `dmj_lib.m`. Every check in the script has a tag; this document has
the same tags in the same order.

**This replaces the earlier bolted version of the manual.** Bolts no longer
transfer moment: both beam flanges are welded to the collar plates, and the
bolts that remain are erection only, through a web cleat. Every bolt check, the
prying model and the F13.1 hole check are gone.

References are to **AISC 360-16** unless stated. Numbers quoted are joint 10
(interior, four IPE 160, HSS 200x100x4) with 12 mm plates.

---

## 1. The connection

The column runs to the top of the beams. Two collar plates are welded around it:

- **Shelf plate** at beam bottom flange level, welded in the shop, both faces.
  The beams land on it.
- **Cap plate** at beam top flange level, laid on and welded in the field, one
  face, together with the four flange welds.

Each beam flange is lapped and welded to its plate on **three sides**: two
longitudinal welds along the plate edges plus one transverse weld across the
plate end. The transverse weld is what makes the shear lag factor U = 1.0.

Moment goes into the column in **both directions**, which is the whole point of
the detail. It is the external diaphragm connection of CIDECT Design Guide 9,
chapter 8, adapted to a column top.

---

## 2. Force paths

**Moment** becomes a couple: flange force T = M/z, tension in one plate and
compression in the other, carried across the weld in shear.

**Vertical reaction** goes into the shelf by direct bearing.

**Uplift** is carried by the flange welds, since there is no bearing in that
direction (check S7).

**Beam axial force** splits between the flanges, so T = |M|/z + |N|/2.

### Lever arm z - [MODEL]

z = h + (t_cap + t_shf)/2 = 160 + 12 = **172 mm**, between the mid-thicknesses
of the two plates. Conservative alternative: z = h - t_f. Set it in
`joint_checks`.

### Local force versus anchored force

Two different demands, and confusing them is the classic error:

| | Demand | Used by |
|---|---|---|
| **Local** | largest single beam flange force | T1 to T6 |
| **Anchored** | column-top moment / z | T7 to T9 |

Under balanced gravity the column sees nothing, yet 93 kN still crosses the
plate from one beam to the other. Version 2 of the script reported zero there
and was wrong. Taking the anchored force from the **column-top moment** read
from ETABS removes every sign-convention question.

---

## 2b. How the force flows through the collar plate

This is the part of the connection that is hardest to see, so here it is step by
step for the **tension** flange. The compression flange is the mirror image,
with buckling instead of yielding.

### Step 1 - out of the beam flange, into the plate

The flange pulls with T. The three-sided weld transfers it into the plate by
shear along the two longitudinal welds and by tension across the transverse one.
Checks: **T1** weld, **T2** and **T3** the flange itself.

### Step 2 - across the lap

The force spreads from the weld into the plate at roughly 30 degrees, the
Whitmore idea. Check **T4**, on the spread width.

### Step 3 - past the column opening

Here the plate has a hole in it. The force reaching the column can go two ways,
and the split depends on stiffness:

- **Into the collar weld**, then as shear along the two column walls that are
  parallel to the force, and out the other side or down the column.
- **Around the opening**, through the two strips of plate beside it.

The two paths are in parallel and their stiffnesses are comparable, so neither
can be assumed to carry everything.

### Step 4 - what actually leaves the joint

Only the **net** force leaves, and it equals the column-top moment divided by z.

| Situation | Through the plate | Into the column |
|---|---|---|
| Two opposite beams both hogging | full T, one beam to the other | nearly zero |
| Sway, beams in double curvature | small | the sum of both flange forces |
| Corner, one beam | sheds progressively into the weld | full T |

### The safe method

**We do not try to compute the split.** The script checks each path for the full
force that could reach it:

| Check | Demand | Why it is safe |
|---|---|---|
| T5, T6 strips | largest single beam flange force | Assumes the strips take it all, and the weld nothing |
| T7, T8, T9 weld and walls | column-top moment / z | Assumes the weld takes the whole net force, and the plate nothing |

Summing the two capacities would be unconservative, because it assumes a
distribution nobody verified. Checking each for the whole of its own worst-case
demand is conservative for a statically indeterminate load path, and it is the
standard way to treat one: any equilibrium-satisfying load path with every
element checked for what it carries is a valid lower bound on strength.

Two consequences worth remembering:

1. **Balanced gravity is not a free ride.** The column sees nothing, but the
   plate carries the full 94 kN across. This is why T5 governs at an interior
   joint under gravity, and it was the bug in version 2.
2. **Corners are the severe case for the weld and walls**, because the net force
   equals the full flange force.

### What the method does not cover

The strips are checked for axial force only. It ignores the bending and shear
they pick up from the eccentricity between the plate strip and the wall, and any
in-plane distortion of the plate around the hole. For that you need shell FE, or
the tested formulas of CIDECT DG9. Section 13 compares both.


---

## 3. Resistance factors

| phi | Applies to | Reference |
|---|---|---|
| 0.75 | welds, rupture, bearing | J2.4, J4.2, J7 |
| 0.90 | yielding of plates and flanges, flexure, plate buckling | J4.1, F2, F7, F11, E3 |
| 1.00 | web local yielding, beam shear | J10.2, G2.1 |

---

## 3b. Your failure-mode list, mapped to the checks

The checks are numbered in the order the force travels, T for the moment path,
S for the seat, M for the members. Your list is grouped by mechanism instead.
Both orders describe the same set, and this table is the bridge. I kept the tag
names unchanged so the script output and your notes stay comparable.

| # | Your failure mode | Tag | Status |
|---|---|---|---|
| 1 | Tension / compression in the plate | T4, T5, T6 | T4 at the lap, T5 and T6 beside the opening |
| 2 | Tension / compression in the beam flange | T2 | Gross yielding |
| 3 | Weld around the beam flange | T1 | Three-sided fillet group |
| 4 | Base metal failure along the weld | T3 | Rupture at the weld, U = 1.0 |
| 5 | Weld around the column, from beam shear | S5 | Shelf collar weld, vertical shear |
| 6 | Wall shear from force flow and net force | T8, **T10**, **T11** | See 3c and 3f, two checks your questions produced |
| 7 | Plate bending from beam shear | S4 | Both plates are the same thickness, so one check covers either |
| 8 | Column distortion between the plates | T8 | Stub shear over the height z |
| 9 | Crushing of plate and flange under the reaction | S3 | Bearing, J7 |
| 10 | Beam web buckling or distortion at the support | S1, S2 | Local yielding and crippling |
| 11 | Tension/compression with bending interaction | S8 | Mp(1 - n^2) |
| 12 | Local yielding of the column wall | T9 | See below, restated honestly |
| 13 | The shelf, S4 | S4 | Three switches, section 6 |
| 14 | Lever effect from the beam shear | - | See below, no separate check needed |

---

## 3c. Item 6: the two extremes, and why no interpolation is needed

Your description of the two extremes is right, and it leads somewhere useful.

**Extreme A, balanced.** Two opposite beams, both hogging. Net force into the
column is zero, but the plate is pulled apart along the column. If the wall
carried that through force, it would be in-plane tension along its length, the
wall being torn apart exactly as you say.

**Extreme B, aligned.** Sway, both beam moments the same sense. The forces add,
the net enters the column, and the stub carries it as shear over the height z.

**The key point: these are not two ends of one scale that needs interpolating,
they are two different quantities, and each is bounded by its own check.**

| Quantity | Largest it can ever be | Checked by |
|---|---|---|
| Through force, staying in the joint | the larger of the two beam flange forces | T5, T6 in the plate, T10 in the wall |
| Net force, entering the column | the sum of the two | T7, T8, T9 |

The through force can never exceed the larger single flange force, whatever the
balance. The net force is read directly from the column-top moment in ETABS, so
whatever the balance, it is the real value. Together the two checks envelope
every intermediate state without any interpolation. That is the safe
simplification you were looking for, and it needs no assumption about the split.

### T10, your half-length assumption, checked

I added it. The wall carries the through force as in-plane tension over a depth
taken as half the wall length, a 45 degree spread from the loaded edge:

phiRn = 0.90 Fy x 2 x (L/2) x t, with L the wall length in the direction of flow

| | Strong, L = 200 | Weak, L = 100 |
|---|---|---|
| Capacity | 180 kN | 90 kN |
| Joint 10 | 94.3 kN, 0.52 | 41.4 kN, 0.46 |
| Joint 13 | 60.8 kN, 0.34 | 49.9 kN, **0.55** |

**Your assumption holds, with roughly a factor of two.** It governs joint 13,
which is worth knowing.

One thing to be clear about: this path is **not required**. The plate strips
already carry the same force at DCR 0.22, so a complete load path exists in the
plate alone. Under the lower-bound theorem, one checked equilibrium path with
adequate ductility is enough. T10 is reported as [INFO] because it tells you what
happens if the force chooses the wall instead, and the answer is that the wall
can take it too. Two independent paths, each sufficient on its own.

---

## 3d. Item 12, restated honestly

You do not understand T9 because it was not stated clearly. Here is what it is
and what it is not.

**What it is meant to represent:** the flange force does not arrive spread over
the whole wall. It comes in over roughly the flange width, so a limited region
of wall receives it and could yield locally before the rest of the wall
participates.

**What it actually computes:** phiRn = 0.90 Fy t b_e, with
b_e = min(wall length, b_f + 5 t_cap), an analogy with web local yielding,
J10.2, where a load applied to a flange spreads into the web at 1:2.5.

**Where the analogy is weak.** In J10.2 the force is perpendicular to the web
edge and b_e is measured along the member. Here the force is parallel to the
wall, so the resisting section is a vertical strip of wall and b_e should be a
depth, not a length. The formula is dimensionally consistent but the direction
of b_e was never pinned down. That is why it is tagged [MODEL] and why I keep
saying not to trust it near 1.0.

**Why it is still in the calculation.** It is the most conservative of the three
wall checks and it has never governed above 0.47. The CIDECT formula, which is
calibrated against tests for exactly this configuration, gives three to four
times more. So T9 acts as a lower bound, and if it ever approaches unity, the
answer is to get the real formula rather than to argue about mine.

If you would prefer, T9 can be deleted and replaced by T8 plus T10, both of which
have defensible mechanics. I left it in because a conservative extra check costs
nothing while it sits at half capacity.

---

## 3e. Item 14, the lever effect

Yes, there is a lever, but it does not do what the word suggests.

The reaction V acts at an eccentricity e from the column face, so the joint has
to resist V x e. Two things happen, and they are different:

**Vertical sharing.** Both plates are welded to the beam, so both resist the
downward reaction. The beam pulls the cap plate DOWN through its welds while it
pushes the shelf DOWN through bearing. The cap is never pushed up. This is the
`J.st.share` switch, and it is why S4 has a factor of two in reserve.

**The horizontal couple.** For the beam end to rotate, the top flange must move
horizontally one way and the bottom flange the other. That is a couple
H = V x e / z, about 1.7 kN at joint 13. It is horizontal at both plates, not
vertical, and it is already inside the column-top moment you read from ETABS,
because the ETABS beam element runs to the column axis. So it needs no separate
check.

The intuition that something is being levered is correct. What is levered is the
beam end rotating, and both plates restrain it horizontally, at a force an order
of magnitude below everything else in the joint.


---

## 3f. Converting the column moment into a force, and the wall interaction

### Which lever arm

Both lever arms are correct, for different forces. They are not alternatives.

**M_col / z, the horizontal force in the plate.** The stub between the two
collars has zero moment at the cap, since nothing continues above it, and M_col
at the shelf. The only way to build that moment over the height z is a
horizontal couple, one force at each plate, separated by z. That is the force
the plate carries, the collar weld transfers as shear flow, and the side walls
carry as shear. Checks T7, T8, T9.

**M_col / (d - t), the vertical force in the end walls.** Below the shelf the
column resists M_col as ordinary bending, with axial forces along the column
axis in the walls perpendicular to the moment axis. That is the column member
check, M4 and M5.

The two coexist. Over the stub height the horizontal couple converts into the
column's bending stresses by shear flow in the side walls, and that conversion
takes about a column depth. Our stub is 172 mm against a 200 mm depth, so it is
not complete inside the joint, which is why the side-wall shear check stays.

Joint 10, seismic, M_col = 7.89 kN.m:

| | |
|---|---|
| Horizontal force in the plate, 7.89/0.172 | 45.9 kN |
| Vertical force in the end walls, 7.89/0.196 | 40.3 kN |
| Check, 45.9 x 0.172 | 7.89 kN.m, closes |

A detail in favour of the collar with a hole over a butt cap plate: the end
walls run continuously THROUGH the shelf, so the vertical wall forces are never
interrupted by a plate.

### Force normal to the plate

At the cap plate it is negligible: the moment there is zero and the beam
reactions enter through the shelf, so the column's vertical wall forces at the
cap are small. At the shelf the wall is continuous and does not bear on the
plate. So the plate never carries a significant force normal to its plane from
the column. What it does carry out of plane is the beam reaction, which is S4,
combined with the in-plane force, which is S8.

### T11, wall stress interaction

The side wall carries three actions at the same point, and they were being
checked separately. T11 combines them with von Mises against 0.90 Fy, taking all
three from the SAME load case so nothing is enveloped against nothing:

| Stress | Source |
|---|---|
| sigma_h, horizontal | the through force, the T10 mechanism |
| sigma_v, vertical | column axial over the gross area plus bending at the extreme fibre |
| tau | the net force as shear over the stub |

sigma_vm = sqrt(sigma_h^2 + sigma_v^2 - sigma_h sigma_v + 3 tau^2)

| Joint | Strong | Weak |
|---|---|---|
| 10 | 109 MPa, 0.48 | 131 MPa, 0.58 |
| 13 | 107 MPa, 0.47 | 133 MPa, **0.59, governs** |

It is conservative in two ways beyond the combination itself: sigma_h assumes the
wall takes the whole through force, which the plate can carry instead, and
sigma_v uses the extreme fibre, which is not where sigma_h peaks. Tagged [INFO]
for that reason, but it is the most complete picture of the wall we have.


---

## 4. Local checks

### T1 - Flange to plate weld, J2.4 eq. J2-3

**What fails:** the three-sided fillet weld group.

phiRn = 0.75 x 0.60 FEXX x (0.707 leg) x L, with L = 2 L_lap + b_f = 242 mm

The directional strength increase of J2.4(b) is **not** used, which is
conservative. Capacity 184.8 kN.

**Weld size is fixed by the code, not by strength.** Table J2.4 requires at
least 5 mm against 7.4 mm material, and J2.2b caps it at t - 2 = 5.4 mm along
the flange edge. 5 mm is the only size that fits.

### T2 - Flange gross yielding, J4.1 eq. J4-1 - GOVERNS

phiRn = 0.90 Fy bf tf = 136.5 kN. DCR 0.69.

This is the governing check for the whole joint, which is the right place for it
to be: the limit is the beam, not the connection.

### T3 - Flange rupture at the weld, J4.2 eq. J4-2

phiRn = 0.75 Fu Ae, Ae = U Ag with **U = 1.0** because a transverse weld crosses
the full flange width (Table D3.1). Without the transverse weld, l/w = 100/82 =
1.22 would give U = 0.75 and cut this by a quarter. Capacity 182.0 kN.

### T4s, T4w - Plate yielding at the lap, J4.1 - [MODEL] for the width

The plate must carry the flange force across the lap. The width engaged is taken
as a **Whitmore spread at 30 degrees** from the weld, limited by the plate:

b_eff = min(bf + 2 L_lap tan30, plate width) = min(174, 260) = 174 mm

phiRn = 0.90 Fy b_eff t_cap = 470.8 kN.

The 30 degree spread is the AISC Manual Part 9 concept for gusset plates,
applied here by analogy. Conservative alternative: b_eff = bf.

### T5s, T5w - Plate strips beside the opening, tension, J4.1 - [MODEL]

**Not a code check.** The force has to pass the hole cut for the tube, through
the two strips of plate beside it:

phiRn = 0.90 Fy (2 x margin x t_cap), margin = (plate width - column face)/2

At joint 10 the margin is 80 mm each side, giving 432 kN. This is conservative
at a corner, where the force sheds progressively into the weld, and it is the
right check at an interior joint where the force genuinely passes through.

### T6s, T6w - The same strips in compression, E3 eq. E3-2

On the compression flange the strips can buckle instead of yielding. Treated as
a short column, restrained along the weld:

r = t/sqrt(12), KL/r with K = 0.65 and L = the column face in that direction

phiRn = 0.90 Fcr A_str = 400.9 kN strong, 424.0 kN weak.

---

## 5. Anchorage into the column

Demand for all three is T_anc = M_col / z, with M_col read from ETABS.

### T7s, T7w - Collar weld, J2.4 eq. J2-3

Only the two walls **parallel to the force** are counted, since they receive it
as shear flow. L = 2 x 200 mm strong, 2 x 100 mm weak, one weld line on the cap.

**The collar weld is 4 mm**, matching the tube wall. A 5 mm fillet on a 4 mm
wall is oversized and risks burn-through. Capacities 244.3 and 122.2 kN.

### T8s, T8w - Column walls in shear yielding, J4.2 eq. J4-3

phiRn = phi x 0.60 Fy Agv, Agv = 2 x (wall length) x t

The code gives phi = 1.00 for shear yielding. **The script uses 0.90**, a
deliberate margin because the shear distribution is less uniform here than in
the rolled sections the clause was written for. 216 and 108 kN.

### T9s, T9w - Wall local yielding - [MODEL] - the weakest documentation

**Not a code check.** The force arrives over roughly the flange width, not the
whole wall. The script assumes a 1:2.5 spread through the plate, by analogy with
web local yielding:

b_e = min(wall length, bf + 5 t_cap), phiRn = 0.90 Fy t b_e

127.8 kN strong, 90.0 kN weak, DCR 0.47 at joint 10.

**If this check ever exceeds about 0.8, do not use it.** Get CIDECT Design
Guide 9 chapter 8, whose yield-line formulas for diaphragm plates are calibrated
against tests.

---

## 6. Seat and vertical load

### S1 - Web local yielding, J10.2 eq. J10-3

phiRn = 1.00 Fy tw (2.5k + lb), k = tf + r, lb = the lap length.

Eq. J10-3 is the version for a load within d of the member end, which is our
case. The interior version J10-2 uses 5k and would be unconservative. 151.2 kN.

### S2 - Web crippling, J10.3 eq. J10-5b

At a member end with lb/d > 0.2:

Rn = 0.40 tw^2 [1 + (4 lb/d - 0.2)(tw/tf)^1.5] sqrt(E Fy tf / tw), phi = 0.75

**The coefficient is 0.40 at a member end**, not the 0.80 of the interior case
J10-4. An early version used 0.80 and overstated this twofold. 129.0 kN.

### S3 - Bearing on the shelf, J7 eq. J7-1

phiRn = 0.75 x 1.8 Fy Apb. Never close to governing.

### S4 - Shelf plate bending, F11.1 eq. F11-1

The beam reaction lands out along the lap and has to be carried back to the
column face, where the collar weld is. Between the contact point and the weld
line the plate bends. This is a LOCAL check on the plate, nothing to do with
the joint transferring moment.

phiMn = 0.90 min(Fy Z, 1.6 Fy S), Z = b t^2 / 4, demand = share x V x e

For a rectangle Z/S = 1.5, so the 1.6 Fy S cap never governs.

Three inputs make this check move, and all three are switches in the script:

**e, `J.st.e_react`.** The reaction is distributed over the lap by bearing and
by the welds, so e is the position of its resultant. A uniform distribution
gives 40 mm, concentration toward the stiff face gives 20 to 25. Default 40,
the conservative bound.

**share, `J.st.share`.** The beam end is welded to BOTH plates. When it deflects
down, the shelf pushes up and the cap hangs the top flange. For the beam end to
move, a hinge line must form in both plates, so the mechanism capacity is the
sum and share = 0.5 is defensible. Default 1.0, shelf alone.

Two cautions on that. The shelf receives the load in bearing, steel on steel,
while the cap receives it by pulling the flange up through its welds, which
opens the root of the lap; fillet welds are strong that way but the root is the
detail to be careful with. And the elastic split depends on fit-up, since a cap
laid on with a 1 mm gap may not engage until the shelf has yielded. The plastic
sum survives poor fit; the elastic split does not.

**bwidth, `J.st.bwidth`.** The plate is continuous, so the strip under the beam
is helped by the plate either side. Option 2 allows a 45 degree spread,
b = b_f + 2e. Default 1, b = b_f, no credit.

Ignored throughout: the beam flange is welded to the plate along the lap, so
7.4 mm of flange and 12 mm of plate act partly together. That composite action
is not taken.

### S8 - Shelf under axial force and bending at the same section

At the column face the shelf carries the bottom flange force IN plane and the
seat moment OUT of plane, at the same section. For a rectangle the plastic
interaction is exact:

M_red = M_p (1 - n^2),  n = N / (phi Fy A)

not a linear sum; axial load only consumes the middle of the section, where the
bending lever arm is smallest.

`J.st.nwidth` sets the width carrying N: b_f, or the Whitmore width already used
by T4. Default 2, Whitmore, which is the same model as T4 and should be the same
number.

Note that S8 pairs the seat moment with T4, the flange force under the beam. It
does NOT pair with T5 or T6, which act on the strips beside the tube, 90 degrees
away, where the seat moment does not exist.

### Sensitivity, 12 mm shelf, joint 10

| e | share | bending width | S4 | S8 |
|---|---|---|---|---|
| 40 | 1.0 | b_f | 0.93 | **0.96** |
| 40 | 1.0 | b_f + 2e | 0.47 | 0.49 |
| 40 | 0.5 | b_f | 0.46 | 0.48 |
| 25 | 1.0 | b_f | 0.58 | 0.60 |
| 25 | 0.5 | b_f + 2e | 0.18 | 0.19 |

With a 16 mm shelf the worst line becomes 0.53.

The first line stacks every conservatism at once and still passes. Relaxing any
single one, each of which is defensible on its own, roughly halves it. That is
why 12 mm is adequate and why S4 should not be used to justify a thicker plate.

### S5 - Shelf collar weld in vertical shear, J2.4

Full perimeter, both faces. DCR 0.02.

### S6 - Beam web shear, G2.1 eq. G2-1

phiVn = phi_v x 0.60 Fy d tw Cv1, with Cv1 = 1.0 and phi_v = 1.00 because
h/tw = 25.4 <= 2.24 sqrt(E/Fy) = 63.4. 120 kN.

### S7 - Flange weld under uplift, J2.4

Runs only when a case produces net uplift. With welded flanges there is no
bearing, so the same weld group carries it.

---

## 7. Members

### M1 - Beam flexure, F2.1 eq. F2-1

phiMn = 0.90 Fy Zx = 27.9 kNm. **F13.1 no longer applies**, because there are no
holes in the flange. That check, and its 1.5% margin, disappeared with the
bolts.

Lateral-torsional buckling is **not** checked here. For the cantilevers it is a
real check and belongs in ETABS with an unbraced length you set yourself.

### M4, M5 - Column flexure, F7.1 eq. F7-1

phiMn = 0.90 Fy Z, sharp-cornered box properties. A real cold-formed HSS gives
about 3% less; use the manufacturer's Z. Compactness holds for this section:
lambda_f = 22.0 <= 31.7 and lambda_w = 47.0 <= 68.5 (Table B4.1b).

### M6 - Column P-M-M interaction, H1.1

Runs only if you set `J.cl.phiPn` from the ETABS steel design output. Otherwise
take the interaction from ETABS, which has the real combinations.

---

## 8. The engineering models, together

| Tag | Model | Risk | If it governs |
|---|---|---|---|
| z | Lever arm between plate mid-thicknesses | Low | Use z = h - tf |
| T4 | Whitmore spread at 30 degrees | Low | Use b_eff = bf |
| T5, T6 | Strips carry the full force | Low at corners | Plate FE model |
| S4, S8 | e, plate share, bending width | Moderate, but three independent reserves | Run the sensitivity in section 6 |
| T9 | Wall spread bf + 5 t_cap | **Highest** | CIDECT DG9 ch. 8 |

---

## 9. Getting the demands

Two ways in, both producing the same load cases:

- `run_joint(J, file, map, title)` reads a joint text export directly.
- `run_joint_res(J, res, map, title)` takes `res` from your `joint_forces()`
  toolkit, already filtered to combinations. Use the **column's local axes** as
  the reference axes.

Values used: beam moment |M3| from the member local forces, beam axial P,
reaction from the vertical component in column axes, column-top M3, M2 and P.

### The mapping check

For each combination the script sums, in column axes, the column moment and the
moments of the beams **you declared in that direction**. It must be near zero. A
wrong `map.strong`, `map.weak` or `map.colM` leaves the missing beams in the
residual and is flagged. Tested: correct mapping 5%, either error 112%.

The 5% that remains is consistent with ETABS end-length offsets, which report
beam moments at the column face. That is also where the connection is designed,
so it works in your favour.

---

## 10. Not covered

Erection cleat, lateral-torsional buckling, column P-M-M without phiPn, fatigue,
fire, seismic detailing under AISC 341 (this connection is **not prequalified**
under AISC 358), weld inspection and fit-up, shim details at the 4.2% slope.

---

## 11. Independent verification

1. Hand-check T1, T2 and S1 with the Specification open. Three checks confirm
   units, phi factors and the force T.
2. Run a null case: M = 0 should leave only seat and member checks.
3. Scale M up until each check fails in turn, and see whether the order matches
   your expectation.
4. Get a second opinion on T9, the model with the least backing.
5. Deliberately mis-map one joint and confirm the residual flags it.

---

## 12. History of corrections

Errors found and fixed while documenting, all of which produced plausible
numbers first:

1. Web crippling used the interior coefficient 0.80 at a member end instead of
   0.40.
2. Net areas used the hole diameter instead of hole + 2 mm (B4.3b). Moot now
   that the flanges have no holes.
3. Bolts were checked for the vertical reaction in shear, which they cannot
   carry: their axis is parallel to it.
4. Local checks used the net force when balanced beams pass the full force
   across the plate.
5. Plate dimensions were inputs that could drift from the drawing; they are now
   computed from the beams present.

---

## 13. Cross-check against CIDECT Design Guide 9

Our connection is the **external diaphragm** of DG9 section 8.6, with one
difference: the guide welds the diaphragm around a **continuous** column, while
ours sits at a column top. The load path in the diaphragm is the same.

### The guide's equation

For an RHS column, Table 8.3 equation (2) gives the ultimate resistance of the
flange force the diaphragm can deliver:

P_bf* = 3.17 (tc/bc)^(2/3) (td/bc)^(2/3) ((tc+hd)/bc)^(1/3) bc^2 f_du

with tc the column wall, td the diaphragm thickness, hd its projection beyond
the column face, bc the column width, and f_du the diaphragm's ultimate tensile
strength. The joint moment then follows from eq. 8.22:

M_j,cf* = P_bf* (hb - tb,f)

### Our joint against its range of validity

| Ratio | Ours | Range | |
|---|---|---|---|
| bc/tc | 25.0 | 17 to 67 | ok |
| hd/bc | 0.80 | 0.07 to 0.40 | **out** |
| td/tc | 3.00 | 0.75 to 2.0 | **out** |
| (bc/2+hd)/td | 10.8 | <= 15.2 | ok |

Taking bc as the smaller face, 100 mm, which is conservative since P varies as
bc^(1/3), the formula returns **P_bf\* = 340 kN**, ultimate and unfactored,
against a demand of 46 kN.

**Two ratios fall outside the tested range, so this is a comparison, not a
design basis.** The script prints it tagged `[INFO]`. Both departures come from
the same cause: our diaphragm is thick relative to a 4 mm wall, and the
projection is large relative to a 100 mm face. The guide's formula was also
derived for square columns; ours is 200x100.

What the comparison tells us is that our `[MODEL]` check T9, at 90 to 128 kN, is
roughly **three to four times more conservative** than the tested formula. That
is reassuring for the check I trust least.

### How to get inside the validity range

Change the column to **HSS 200x100x6**. Then td/tc = 2.0 and bc/tc = 16.7, and
with bc = 200 the projection ratio is 0.40. Everything lands inside the range,
and the wall checks T8 and T9 gain 50%. If a joint ever comes close to its
limit, this is the move, not a thicker plate.

### Full-strength design, and why we are not doing it

DG9 designs these connections for **overstrength**: the diaphragm is sized so
that the beam forms its plastic hinge first, eq. 8.23 with alpha = 1.2. We size
ours for the demand Mu from the analysis.

Section 8.8 addresses exactly this. It states that the designs of the preceding
sections can also be used where seismic forces are not the dominant design
action, that the overstrength requirements make those connections uneconomic,
and that the details can be simplified when ductility demands are lower. For a
class 2 beam it proposes reducing alpha to gamma_M,weld / gamma_M0 = 1.1
(eq. 8.28), and notes this significantly reduces the external diaphragm
dimensions. It also records that FEMA 350 permits unreinforced I-beam to column
connections in Ordinary Moment Frames, while cautioning that research on
full-strength I-beam to HSS-column connections for low-seismicity structures is
scarce.

**So our simplified version is defensible for an ordinary frame, with one
condition that is yours to settle.** If NEC-15 at R = 2.5 requires AISC 341
Ordinary Moment Frame detailing, then E1.6b asks for the connection to be
designed for 1.1 Ry Mp of the beam, or for the moment from the amplified seismic
load. With Ry = 1.5 for A36, 1.1 Ry Mp = 51 kN.m, three times our demand, and
the whole detail would change. If R = 2.5 instead corresponds to a system
designed to AISC 360 alone, designing for Mu is correct.

**Settle this before finalising the detail.** It is the single assumption with
the largest consequence in the whole calculation.

### A note on the beam-side check

Our T2, flange gross yielding, runs at 0.69 under gravity. DG9's philosophy
would call that the right governing check: the limit is the beam, not the
connection. If you later adopt the overstrength approach, the connection must
beat the beam, and T2 stops being a check and becomes the target.


---

## 14. Worked numbers, joint 10

Interior joint, four IPE 160, HSS 200x100x4, 12 mm plates, z = 172 mm.
Use these to verify the script output line by line.

### The two cases

| | Gravity, 1.2D+L+1.6Lr | Seismic, 1.2D-Ey-.3Ex+L+.2S |
|---|---|---|
| Largest beam moment | 16.22 kN.m (frame 38) | 7.02 kN.m (frame 38) |
| Other strong beam | 15.21 kN.m, hogging | 1.22 kN.m, sagging |
| Column top, strong | 0.53 kN.m | 7.89 kN.m |
| Column top, weak | 0.27 kN.m | 1.82 kN.m |
| Largest reaction V | 15.37 kN | 4.80 kN |
| Column axial Pu | 41.64 kN | 15.10 kN |

Notice the reversal. Under gravity the beam moments nearly cancel and the column
gets almost nothing. Under seismic they add, and the column-top moment exceeds
either beam's moment.

### The forces

| Quantity | Gravity | Seismic |
|---|---|---|
| Local flange force, T = max\|M\|/z | 16.22e6/172 = **94.3 kN** | 7.02e6/172 = **40.8 kN** |
| Anchored force, strong, T = Mcol/z | 0.53e6/172 = **3.1 kN** | 7.89e6/172 = **45.9 kN** |
| Anchored force, weak | 1.6 kN | 10.6 kN |

Under seismic the anchored force, 45.9 kN, is larger than any single beam's
flange force, 40.8 kN, because the two beams add: (7.02 + 1.22)/0.172 = 47.9 kN,
which matches 45.9 plus the 0.35 kN.m equilibrium residual.

### Check by check

| Tag | Capacity | Gravity demand | DCR | Seismic demand | DCR |
|---|---|---|---|---|---|
| T1 flange weld | 184.8 kN | 94.3 | 0.51 | 40.8 | 0.22 |
| T2 flange yielding | 136.5 kN | 94.3 | **0.69** | 40.8 | 0.30 |
| T3 flange rupture | 182.0 kN | 94.3 | 0.52 | 40.8 | 0.22 |
| T4s plate at the lap | 470.8 kN | 94.3 | 0.20 | 40.8 | 0.09 |
| T5s strips tension | 432.0 kN | 94.3 | 0.22 | 40.8 | 0.09 |
| T6s strips compression | 400.9 kN | 94.3 | 0.24 | 40.8 | 0.10 |
| T7s collar weld | 244.3 kN | 3.1 | 0.01 | 45.9 | 0.19 |
| T8s wall shear | 216.0 kN | 3.1 | 0.01 | 45.9 | 0.21 |
| T9s wall local [MODEL] | 127.8 kN | 3.1 | 0.02 | 45.9 | **0.36** |
| Tcs CIDECT [INFO] | 340.4 kN | 3.1 | 0.01 | 45.9 | 0.13 |
| T7w collar weld, weak | 122.2 kN | 1.6 | 0.01 | 10.6 | 0.09 |
| T9w wall local, weak | 90.0 kN | 1.6 | 0.02 | 10.6 | 0.12 |
| S1 web local yielding | 151.2 kN | 15.4 | 0.10 | 4.8 | 0.03 |
| S2 web crippling | 129.0 kN | 15.4 | 0.12 | 4.8 | 0.04 |
| S4 shelf bending | 0.66 kN.m | 0.38 | **0.58** | 0.12 | 0.18 |
| M1 beam flexure | 27.88 kN.m | 16.22 | 0.58 | 7.02 | 0.25 |
| M4 column strong | 34.23 kN.m | 0.53 | 0.02 | 7.89 | 0.23 |

Over the whole envelope the weak-direction wall check T9w reaches 0.47 in a
different seismic combination, 1.2D+Ex-.3Ey, where the weak column moment peaks
at 7.30 kN.m.

### Three arithmetic checks you can do in a minute

1. **T** = 16.22e6 / 172 = 94 302 N. If your z differs, everything scales.
2. **T2** = 0.90 x 250 x 82 x 7.4 = 136 530 N. Two numbers, no geometry.
3. **T8s** = 0.90 x 0.60 x 250 x 2 x 200 x 4 = 216 000 N.

If those three match, the units, the resistance factors and the force are right,
and the rest is the same arithmetic with different areas.
