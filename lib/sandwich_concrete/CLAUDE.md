# sandwich_concrete: limits

- Two steel beams on opposite faces of ONE concrete beam, sharing the same
  through-rods; the governing face is checked with the shear of the other.
- The concrete beam's shear and torsion check covers the connection region
  only; it does not replace the beam design.
- 2 rods per row in 2 rows (tension row near the top, shear row below), top of
  the steel beam flush with the top of the concrete, shear acting downward.
- Both DG 39 paths are reported; the report says "see PENDIENTE.txt item 2",
  which points to the project's open items (casa_saav/notes/sandwich_PENDIENTE.txt).
- Fixed values to watch: AISC minimum edge 22 mm (Table J3.4M for M16), minimum
  fillet 5 mm (Table J2.4), Cb = 1.0 for LTB, web shear by G2.1(a) only.
- Verified 2026-10-09: casa_saav/sandwich_beam.m (input) + this function
  reproduce casa_saav/reports/sandwich_beam_output.txt byte for byte. Run it
  and compare after any change here.
