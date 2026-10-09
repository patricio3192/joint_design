# direct_weld_joint: limits

- Same scope as lib/collar_joint (rectangular HSS column, I beams on the column
  axes, one section for all joints, no beam torsion, RSA skipped).
- It was written to justify the collar, not to design a direct-welded joint
  for construction. Its HSS-face checks follow AISC 360-16 K1/K5 and Chapter J;
  some limits come from AISC 360-10 Table K1.2 and are reference only. Tell the
  user before using it as the design of a real direct-welded joint.
- Verified 2026-10-09: compare_direct_weld reproduces the old t2_direct_test.m output.
