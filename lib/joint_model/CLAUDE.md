# joint_model: limits

- Geometry is simple on purpose: bars are cylinders along polylines (flat ends,
  bends as short straight pieces), everything else is an axis-parallel box. Hex
  nuts are cylinders of diameter = across flats (slightly unconservative at the
  corners), holes in plates are not modelled (use touch), inclined plates are
  not possible. Tell the user before modelling something that needs more.
- Distances near bar ends use the end disk (approximate, within about 1 mm).
  Results within 1 mm of a limit deserve a look at the drawing.
- The spacing rule is the only code rule here (ACI 25.2.1, parallel bars); cover,
  hook geometry and development lengths are NOT checked by jm_clash.
- The model says nothing about strength: the connection library's check_* does.
  A model builder must read the same P as its check and use R (the check result)
  for the derived lengths (hef, rod length, development lengths).
- Concrete pieces are never clash-checked (bars are inside them); cover is not checked.
