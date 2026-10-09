# sheets: drawing items, components and sheet blocks (Octave)

Everything a sheet script needs to build the JSON that `lib/printing` prints
(PDF) and turns into DXF. Coordinates in model mm; text sizes come from the
printer's styles. Add the folder to the path:
`addpath(fullfile(lib, 'sheets'), fullfile(lib, 'profiles'))`.

`examples/component_catalog.m` draws every component on one sheet
(`examples/component_catalog.pdf`): look there first.

## Items (one JSON item each)
```
d_line  d_circle  d_poly  d_rectxy  d_tri  d_text  d_lines  d_dim  d_weld
d_path (bar along a polyline)  d_bar  d_half      fillet  arcp  rotp (point helpers)
```

## Components (return a cell array of items; join them with it = [it, c_...])
```
c_axis, c_grid       grid lines with bubbles; c_grid takes G.v {name, p1, p2} (may be
                     inclined) and G.h {name, y}, cut to a box
c_node               ball with a label, to mark a joint
c_rebar              bar along a polyline, bends rounded, optional label (extra bars, bastones)
c_rc_section         rectangular concrete section: outline, stirrup with 135 deg hooks, bars
c_rc_dims            its width and depth
c_column_tie         square column with its 8 bars and one tie with 135 deg hooks
c_plate              plate with rows of holes and the dimension chain
c_nut                washer + nut on a rod, either direction
c_ishape             rolled I section (steel_profile): 'section' or 'elevation'
c_hss                rectangular hollow section, cut
c_leader             text with a leader line to what it names
c_cutmark            section cut mark across a member
c_dim_chain          consecutive dimensions through a list of points
```
Each file's help lists its fields and defaults (`help c_rc_section`).

## Blocks (sheet layout)
```
blk_h  blk_p  blk_note  blk_space  blk_page  blk_table  blk_row  blk_draw
```

## Who uses it
`lib/collar_joint` (make_detail_pdf, make_plan_sheets, make_joint_pdfs) and
`casa_saav/sheets/make_concrete_sheet.m`. Checked 2026-10-09: all five sheets
produce the same JSON as before the helpers and components moved here.
