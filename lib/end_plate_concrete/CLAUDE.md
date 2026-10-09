# end_plate_concrete: limits

- Moment with the top in tension and no reversal; shear down. Flush end plate,
  4 rods, head plates in the column, bastones as anchor reinforcement (all rod
  tension to the bars). Cracked concrete (psi_c = 1.0).
- Not a general anchor-design library: no edge-distance groups beyond what the
  script builds, no seismic (ACI 17.10) checks.
- The design script is casa_saav/end_plate_column.m. After any change here,
  run it and compare with casa_saav/reports/end_plate_column_output.txt
  (identical on 2026-10-09).
