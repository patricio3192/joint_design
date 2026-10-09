# collar_joint: limits (warn the user before using it outside them)

- Column: rectangular HSS (J.cl.D x J.cl.B x J.cl.t; D = face in the strong
  direction). Not for open sections, round HSS or concrete-filled tubes.
- Beams: I sections (IPE), along the column axes. Skew beams (> 10 deg) are
  only reported, never checked.
- Collar: two plates (cap and shelf) fillet-welded around the column, beam
  flanges fillet-welded to them on three sides (J.wl.*). Not for bolted
  collars, through-plates or internal diaphragms.
- Torsion in the beams is NOT checked. Joints whose equilibrium/mapping check
  fails may hide moment carried by torsion: run explain_joint_equilibrium.
- One section and one detail (default_joint) for all joints; sections are not
  read from the ETABS export. If the project has more than one beam or column
  size, the user must split the run by joint.
- Forces: ETABS combinations only, RSA skipped. Units in the database: kN, m;
  dmj_lib converts to N, mm.
- Project data is passed in: joint classes C and grid G (README.md has the
  format). Never add project numbers to lib/. A joint missing from C is taken
  as all-moment with a warning: tell the user when you see that warning.
- make_plan_sheets.m and make_detail_pdf.m write Spanish sheets with fixed
  notes (A36, E70XX, IPE/HSS names from J): read the notes before reusing
  them on another project.
- Verified: casa_saav/collar_joints.m reproduces the outputs from before the
  reorganisation exactly (2026-10-09, after C and G became arguments too).
  Run every step again after any change here.
