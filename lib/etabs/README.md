# etabs: ETABS text export -> joint database

Reads an ETABS text export (`Table:` headings) and saves, for every joint with
a column below it and at least one beam, its frame map (column, strong and weak
beams) and its forces in the column axes. The collar and direct-weld libraries
read this database.

## 1. Export from ETABS

Export the tables to one **text file** (ETABS text format, with `Table:`
headings). **Units: kN, m** (forces kN, moments kN-m).

| Table | Why |
|---|---|
| Point Object Connectivity | joint coordinates |
| Column Object Connectivity | column end points |
| Beam Object Connectivity | beam end points |
| Element Forces - Columns | column forces |
| Element Forces - Beams | beam forces |
| Frame Assignments - Local Axes | column/beam rotation angles |

- **Do not skip Local Axes.** Without the table every angle is taken as 0, and
  with rotated columns strong and weak come out swapped.
- In Element Forces, include the **load combinations**. Load cases (Dead,
  Live, Modal, ...) are allowed but are dropped when the database is built.
- RSA combinations are kept in the database; the joint libraries skip them
  (`map.skip = 'RSA'`): they are not in equilibrium at the joint.
- Brace Object Connectivity / Element Forces - Braces are read if present, but
  no check uses them.

## 2. Build the database (once per export, ~40 s)

```
addpath('lib/etabs');
build_joint_db('casa_saav/data/gg.txt', 'casa_saav/data/joint_db')        % strong = M3
build_joint_db('casa_saav/data/gg.txt', 'casa_saav/data/joint_db', 'M2')  % sections turned
```
(`casa_saav/collar_joints.m` does it with `steps.build = true`.) It writes
`joint_db.mat` (DB, read with `load_joint_db`) and `etabs_model.mat` (the whole
parsed model M, for `joint_forces(M, ...)` without re-reading the text file),
and prints a table of joints, columns and beams: check the map there.
"Skew beams" are beams more than 10 deg off both column axes.
`load_joint_db` warns when the export changed after the build.

## Files
```
build_joint_db.m, load_joint_db.m    the database
read_etabs_txt.m, read_etabs_table.m, load_etabs_model.m   parsing
joint_map.m, frame_local_axes.m      frames at a joint, strong/weak
joint_forces.m, joint_f.m, write_joint_forces.m, print_joint_forces.m   forces at a joint
joint_residual.m                     equilibrium terms the libraries leave out
explain_joint_equilibrium.m          why a joint fails the equilibrium / mapping check
run_joint_extraction.m, tcol.m, tnum.m   older stand-alone extraction and table helpers
```
