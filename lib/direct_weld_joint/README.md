# direct_weld_joint: beams welded straight to the HSS column

The same joint as `lib/collar_joint` WITHOUT the collar plates: beam flanges
and web welded directly onto the HSS column faces. Checked with the same
forces, beam and column as the collar joint, to show with code equations why
the collar is needed. AISC 360-16 Chapter J and K1/K5 (Table K1.2 of 360-10 for
reference). Every check and its tag are explained in `direct_weld_manual.md`.

## Files
```
dwj_lib.m               the checks (every function starts with dwj_, so it loads
                        next to dmj_lib without clashes); dwj_default_joint() holds the data
compare_direct_weld.m   direct weld on a list of joints, optionally side by side with
                        the collar joint, and the PDF check sheets of both
```

## Use
```
source(fullfile(lib, 'direct_weld_joint', 'dwj_lib.m'));
source(fullfile(lib, 'collar_joint', 'dmj_lib.m'));      % only to compare
J = dwj_default_joint();   % J.wl.fl_type = 'cjp' for CJP flanges
compare_direct_weld(DB, {'10', '13'}, J, default_joint(), 'reports')
```
Needs `lib/collar_joint` (joint_config, make_joint_pdfs) and the project's
joint_classes.m on the path. Example: `casa_saav/collar_joints.m`, step `compare`.
