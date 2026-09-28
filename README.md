# Diaphragm moment joint checks

Capacity check (welds, plates, column walls, seat) of the external diaphragm
joints, using member forces exported from ETABS. Everything runs in Octave.

## Folders

```
joint_calculations/
  dmj_lib.m          joint checks library (sections, plates, welds in default_joint)
  t1_joint_test.m    MAIN SCRIPT: checks one joint, a list, or all joints
  dwj_lib.m          same joint WITHOUT collar: beams welded to the column faces
  t2_direct_test.m   runs dwj_lib, optionally side by side with dmj_lib,
                     and writes the PDF check sheets
  direct_weld_manual.md  manual for dwj_lib (why the collar is needed)
  t3_joint_equilibrium.m  explains a joint that fails the equilibrium/mapping check
  t4_collar_details.m  plate types + reports/collar_details.pdf (drawings)
  t5_planos.m        A2 sheets in Spanish for the structural drawings
                     (reports/planos_uniones.pdf) + beam-to-beam checks
  joint_classes.m    EDIT: what arrives on each side of every joint (M S NL N E)
  grid_lines.m       EDIT: construction grid (A B C D F / 5 1 6 2 3 7 4 8)
  plan_layout.m      grid names of the joints, IPE vs correas, beam-to-beam connections
  make_plan_sheets.m builds the A2 sheets (all geometry and text)
  joint_config.m     turns a joint's class into the beam map and collar strips
  collar_types.m     groups the collar plates by outline
  make_detail_pdf.m  builds the detail drawings (all geometry, from J)
  make_joint_pdfs.m  builds the PDF check sheets (all content, from the libraries)
  python_support_scripts/  joint_pdf.py: prints a sheet to PDF, nothing else
  reports/           generated PDFs (and the JSON behind them)
  snap.sh            ./snap.sh "message" saves a git snapshot
  joint_db/          generated .mat files (safe to delete, rebuild below)
  etabs_joints/      ETABS reader toolkit + the export file (gg.txt)
```

## 1. Export from ETABS

Export the tables to one **text file** (the ETABS text format, with `Table:`
headings). Save it as `etabs_joints/gg.txt`, or use any name and pass it to
`build_joint_db`.

**Units: kN, m** (forces kN, moments kN-m). dmj_lib converts these to N and mm.

| Table | Why |
|---|---|
| Point Object Connectivity | joint coordinates |
| Column Object Connectivity | column end points |
| Beam Object Connectivity | beam end points |
| Element Forces - Columns | column forces |
| Element Forces - Beams | beam forces |
| Frame Assignments - Local Axes | column/beam rotation angles |

Notes:
- **Do not skip Local Axes.** The columns here are rotated 90 deg. Without the
  table every angle is taken as 0 and strong/weak come out swapped.
- In Element Forces, include the **load combinations**. Load cases (Dead,
  Live, Modal, ...) are allowed but are dropped when the database is built.
- RSA combinations are kept in the database but skipped by `t1_joint_test.m`
  (`map.skip = 'RSA'`). They are not in equilibrium at the joint.
- Brace Object Connectivity / Element Forces - Braces are read if present,
  but no check uses them.

## 2. Build the .mat files (once per export, ~40 s)

From `joint_calculations/`:

```
octave-cli --eval "addpath('etabs_joints'); build_joint_db"
```

or with another file: `build_joint_db('etabs_joints/other.txt')`.

This writes:
- `joint_db/joint_db.mat`: every joint with a column below it and at least
  one beam, with its frame map (column, strong beams, weak beams) and its
  forces (combinations only).
- `joint_db/etabs_model.mat`: the whole parsed model (`M`), for use with
  `joint_forces(M, ...)` without re-reading the text file.

It prints a table of joints, columns and beams. Check the map there.
- Strong direction = column **M3** (200 mm face). If the sections are turned
  the other way, run `build_joint_db('etabs_joints/gg.txt', '', 'M2')`.
- "skew beams" = beams more than 10 deg off both column axes.

## 3. Check joints (< 1 s)

Open `t1_joint_test.m`, edit:
- `joints = {'10'};` for one joint, or `joints = {DB.joints.joint};` for all
- `J = default_joint();` plus any overrides (plate thickness, lap, welds)

and run it from `joint_calculations/`:

```
octave-cli t1_joint_test.m
```

If gg.txt has changed since the build, you get a warning to rebuild.

For the direct-weld comparison (justifies the collar), run `t2_direct_test.m`
the same way. With `compare = true` its summary lists the governing check of
both details for each joint.

With `make_pdf = true` it also writes two PDF check sheets for the joints in
`joints`, one per connection type:
`reports/direct_joints.pdf` and `reports/collar_joints.pdf`. They follow
joint10_handcheck.pdf: index of limit states, data, demands, capacities with
numbers substituted. Everything on the sheet comes from Octave
(`make_joint_pdfs.m` and the libraries); Python only prints it. The substituted
formulas come from the library itself (8th field of each check): dwj_lib
supplies them, dmj_lib does not, so the collar sheet shows capacities only.

Needs ReportLab, once:

```
sudo apt install python3-reportlab
```

## Joint classes and collar details

`joint_classes.m` lists, for every joint, what arrives on each global side
(W = -X, N = +Y, E = +X, S = -Y): M moment beam, S shear only on the shelf,
NL beam below the collar on a shear tab, N no beam (free strip), E no beam
at the building edge (strip limited to `w_back`). t1, t2 and t4 all read it
through `joint_config`, which also warns when the ETABS model disagrees
(a beam missing, or a moment at a beam detailed as a pin).

`octave-cli t4_collar_details.m` groups the collar plates into types and
writes `reports/collar_details.pdf`: key plan, joint schedule, plate types,
sections of the M, S and NL connections, and a plan of every joint.

## Plan sheets (A2, Spanish)

`octave-cli t5_planos.m` writes `reports/planos_uniones.pdf`: general plan
with the grid and joint schedule, collar types and connection details
(M, C, LB on a seat angle, beam to beam), and a plan of every joint. The
console lists every beam-to-beam connection with its checks (not shown on
the sheets). Codes on the sheets: M moment, C shear on the collar, LB below
the collar on a seat angle, — no beam. Correas (north-south members off the
lettered grid lines) are not drawn.

## Known limits

- Beam **torsion** is not included in the dmj_lib or dwj_lib checks. Where a
  beam twists into the column (e.g. a direction with no beam, whose column
  moment is balanced by beam torsion), the equilibrium/mapping check flags
  the joint, and the beam-side checks miss that moment.
- One section for all joints (`default_joint` in dmj_lib.m). Frame sections
  are not read from the export.

## TODO

- Check sheets (PDF): improve readability for someone checking with a hand
  calculator: write out each equation, define the symbols, and add a short
  explanation of each check.
- Manual: add the new collar tags (T1a, T3b as block shear, T3c, T3d, T12,
  T13, S9c, S10, S11, shear tab P1-P11, seat angle L1-L7, beam to beam
  V1-V6, U in T3) and the joint classes to diaphragm_joint_manual.md.
- Manual section 1 says the shelf is welded to the column on both faces;
  the checks and drawings use one face (J.wl.n_shf = 1). Align the text.
