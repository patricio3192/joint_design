# sheets: drawing items, components and sheet blocks (Octave)

Everything a sheet script needs to build the JSON that `lib/printing` prints
(PDF) and turns into DXF. Coordinates in model mm; text sizes come from the
printer's styles; every style name is in `STYLES.md` (with a "which style
for what" table).

## Start a sheet (copy this)
```
lib = '/path/to/joint_design/lib';     % in the repo: fullfile(fileparts(mfilename('fullpath')), <..>, 'lib')
addpath(lib);  addlib();                       % every library (or only sheets + profiles)
it = c_grid(G, box);  it = [it, c_node(0, 0, 'B2')];          % build each drawing as a cell array
B = {blk_h(1, 'Título'), ...
     blk_row([0.6 0.4], {{blk_draw(it, 180, 'PLANTA', 'nota')}, {blk_table(head, rows, widths, [], [])}})};
o.tb = {'PROYECTO:', 'X';  'FECHA:', 'OCTUBRE 2026';  'LÁMINA:', '@page'};   % title block (frame)
sheet_pdf(B, '/path/to/out/lamina', o);     % JSON + PDF (pour_pdf.py, A2 landscape); error if it overflows
```
`help sheet_pdf` lists the page sizes (A2L, A1L, A4) and the title-block options.
`examples/component_catalog.m` and `casa_saav/sheets/make_concrete_sheet.m` are full sheets.

## Conventions (read once)
- Units are model mm; each drawing is scaled to fit its `blk_draw` height and its
  column width (no fixed scale is printed). A row that does not fit the page
  moves to a new page: the printer prints a WARNING and sheet_pdf stops; lower `h`.
  An A2 landscape page holds about 330 mm of drawing height in one column
  (caption included) above a 30 mm title block; A1 about 480 mm.
- Components return a cell array: join with `it = [it, c_leader(...)]`, never
  `{c_leader(...)}` (that nests it). Items (d_*) are single structs: `it{end+1} = d_line(...)`.
- Bars are drawn with their real diameter in model mm (`d_path`, `c_rebar`):
  right in a section or a detail, invisible in a plan at 1:100. In plans draw
  them with an exaggerated d (40-60) and write the real one in the label.
- `d_dim(x0, y0, x1, y1, off, txt)`: the dimension line sits `off` to the LEFT
  of the direction p0 -> p1. Horizontal left-to-right: off > 0 above, off < 0
  below. Vertical bottom-to-top: off > 0 to the left. `c_dim_chain` the same.
- `c_rc_section`: `ct` is the stirrup AXIS from the faces = cover + dst/2; bar
  centres are yours: corner bar = cover + dst + db/2 from each face.
- y is up in every drawing (a section's origin is its bottom centre).
- '@page' in the title block prints "i / n"; write a literal like '1/1' if you prefer.

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
c_nut                washer + nut on a rod, side view, either direction
c_nut_front          washer + hex nut + rod end seen along the rod
c_ishape             rolled I section (steel_profile): 'section' or 'elevation'
c_hss                rectangular hollow section, cut
c_leader             text with a leader line to what it names
c_cutmark            section cut mark across a member
c_dim_chain          consecutive dimensions through a list of points
```
Each file's help lists its fields and defaults (`help c_rc_section`).

## Blocks (sheet layout) and output
```
blk_h  blk_p  blk_note  blk_space  blk_page  blk_table  blk_row  blk_draw
sheet_pdf            blocks + title block -> JSON -> PDF
```

## Who uses it
`lib/collar_joint` (make_detail_pdf, make_plan_sheets, make_joint_pdfs) and
`casa_saav/sheets/make_concrete_sheet.m`. Checked 2026-10-09: all five sheets
produce the same JSON as before the helpers and components moved here.
