# sandwich_concrete: limits

- Two steel beams on opposite faces of ONE concrete beam, sharing the same
  through-rods; the governing face is checked with the shear of the other.
- The concrete beam's shear and torsion check covers the connection region
  only; it does not replace the beam design.
- Both DG 39 paths are reported (see casa_saav/notes/sandwich_PENDIENTE.txt, item 2).
- The design script is casa_saav/sandwich_beam.m. After any change here, run
  it and compare with casa_saav/reports/sandwich_beam_output.txt (identical on 2026-10-09).
