# collar_joint: beams to an HSS column through external diaphragm collars

Capacity checks (welds, plates, column walls, seat, beam-to-beam shear
connections) of moment joints between I beams and a rectangular HSS column,
through two collar plates (cap above the top flanges, shelf below the bottom
flanges) welded around the column. Forces come from the ETABS joint database
(`lib/etabs`). AISC 360-16, LRFD. The method and every check (tags T1...,
S1..., V1...) are explained in `diaphragm_joint_manual.md`;
`joint10_handcheck.pdf` is a hand check of one joint against the library.

## Files
```
dmj_lib.m           the checks; default_joint() holds sections, plates and welds
joint_config.m      a joint's class -> beam map and collar strips (warns when the model disagrees)
collar_types.m      groups the collar plates by outline
plan_layout.m       grid names of the joints, IPE vs correas, beam-to-beam connections
make_detail_pdf.m   detail sheets (key plan, plate types, sections, plan of every joint)
make_plan_sheets.m  A2 sheets in Spanish (general plan, schedule, details, joints)
make_joint_pdfs.m   PDF check sheets (index, data, demands, capacities), also for direct_weld_joint
```

## Use
```
lib = 'path/to/lib';
addpath(fullfile(lib, 'collar_joint'), fullfile(lib, 'etabs'), 'path/to/project/data');
source(fullfile(lib, 'collar_joint', 'dmj_lib.m'));   % defines every check function
DB = load_joint_db('path/to/project/data/joint_db/joint_db.mat');
J  = default_joint();  J.pl.t_cap = 12;                % overrides
[map, Jj] = joint_config(DB.joints(k), J);  map.skip = 'RSA';
E  = run_joint_res(Jj, DB.joints(k).res, map, 'JOINT 10');
```
`casa_saav/collar_joints.m` is the complete example (checks, detail sheets,
plan sheets, comparison with direct weld, equilibrium diagnosis).

The project must provide on the path:
- `joint_classes.m`: for every joint, what arrives on each global side
  (W = -X, N = +Y, E = +X, S = -Y): M moment beam, S shear only on the shelf,
  NL beam below the collar on a shear tab, N no beam (free strip), E no beam
  at the building edge (strip limited to `w_back`).
- `grid_lines.m`: the construction grid (for plan_layout and the sheets).

Check sheets need Python 3 with ReportLab (`sudo apt install python3-reportlab`).
Substituted formulas on them come from the library itself (8th field of each
check): dwj_lib supplies them, dmj_lib does not, so the collar sheet shows
capacities only.

## Known limits
- Beam **torsion** is not included. Where a beam twists into the column
  (a direction with no beam, whose column moment is balanced by beam torsion),
  the equilibrium/mapping check flags the joint and the beam-side checks miss
  that moment (`lib/etabs/explain_joint_equilibrium.m` tells which joints).
- One section for all joints (`default_joint`). Frame sections are not read
  from the export.
- Rectangular HSS column and I beams only; beams along the column axes
  (skew beams, more than 10 deg off, are only reported).
- RSA combinations are skipped (`map.skip = 'RSA'`): not in equilibrium at the joint.

## TODO
- Check sheets: write out each equation, define the symbols, and add a short
  explanation of each check, for someone checking with a hand calculator.
- Manual: add the newer tags (T1a, T3b as block shear, T3c, T3d, T12, T13,
  S9c, S10, S11, shear tab P1-P11, seat angle L1-L7, beam to beam V1-V6, U in
  T3) and the joint classes.
- Manual section 1 says the shelf is welded to the column on both faces; the
  checks and drawings use one face (J.wl.n_shf = 1). Align the text.
