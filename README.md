# Diaphragm moment joint checks

Capacity check (welds, plates, column walls, seat) of the external diaphragm
joints, using member forces exported from ETABS. Everything runs in Octave.

## Folders

```
joint_calculations/
  dmj_lib.m          joint checks library (sections, plates, welds in default_joint)
  t1_joint_test.m    MAIN SCRIPT: checks one joint, a list, or all joints
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

## Known limits

- Beam **torsion** is not included in the dmj_lib checks. Where a beam twists
  into the column (joint 8: beam 22, ~6.9 kNm), the equilibrium/mapping check
  flags the joint, and the beam-side checks miss that moment.
- One section for all joints (`default_joint` in dmj_lib.m). Frame sections
  are not read from the export.
