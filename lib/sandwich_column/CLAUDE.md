# sandwich_column: limits

- Two steel beams of the SAME section in one line, on opposite faces of a
  concrete column, both moments with the top in tension (>= 0; it stops
  otherwise), shear down. 2 rods per row, 2 rows, plates centred on the face,
  top of the steel beams flush with the top of the plates.
- The column continues below the joint (no shear breakout). If it ends above
  the beams, give column.top (the top edge is then checked for the rod edge
  distance and limits the bearing frustum).
- No beams in the other direction are modelled; ties inside the joint are the
  column's (hoop_y), checked for spacing (ACI 15.3) and against the rods.
- Own models, flagged in EQUATIONS.txt: (a) the opposite plate pressed by the
  rod tension not balanced by the other beam (module 6), (b) joint shear = that
  unbalanced flange force, column shear not counted (module 10), (c) the plate
  width taken as the beam width in ACI 15.4.2.4. Tell the user when one of them
  governs.
- gamma (ACI Table 15.4.2.3) is an input: the user picks it for the confinement.
- The unbalanced moment goes into the column: design the column in the frame model.
- Same fixed values as sandwich_concrete: AISC minimum edge 22 mm (M16),
  minimum fillet 5 mm, Cb = 1.0, web shear by G2.1(a) only.
- Not verified against a project yet: only the made-up example exists
  (examples/example_sandwich_column_output.txt). New 2026-10-10; its equations
  are listed for the page check in verification/ (see the root CLAUDE.md).
