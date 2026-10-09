# etabs: limits

- ETABS text export only (not .e2k, not CSV-per-table unless read_etabs_table
  handles it), units kN and m. Other units give wrong forces silently: ask.
- Joints = points with a column below and at least one beam. Braces are read
  but not used. Strong axis of the column = M3 unless 'M2' is passed.
- The export (gg.txt, ~16 MB) and joint_db/ are not in git.
