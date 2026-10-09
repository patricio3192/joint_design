# sheets: notes for the agent

- Drawing a new sheet: build it from these components and blocks; do not copy
  d_*/blk_* helpers into sheet scripts any more. A new reusable piece goes here
  as a c_* file with its help text, plus one example in examples/component_catalog.m.
- Styles (the s argument) must exist in the printer: lib/printing/joint_pdf.py
  SHAPE / Style.text, or pour_pdf.py for the r_* (concrete, rebar) styles.
- Changing a component changes every sheet that uses it: rerun
  casa_saav/concrete_sheet.m and the collar sheets and compare the JSON files
  (they must stay identical unless the change is intended).
- Components are 2D drawings with fixed conventions (origins and directions in
  each help text). 3D joint models (clash checks, views) are in lib/joint_model;
  jm_view returns items of this library.
