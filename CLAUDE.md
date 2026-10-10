# Notes for the agent

The user is a structural engineer (Spanish speaker; sheets are in Spanish,
code and docs in English). Tokens cost them money: read the README/CLAUDE.md
of the folder you work in before opening code, and open only what you need.

## Map
- `lib/<name>/`: libraries. Each has README.md and CLAUDE.md with its limits.
  **Before using a library for a new case, read its CLAUDE.md and tell the
  user if the case is outside its limits.**
- `casa_saav/`: the only project so far. Project data lives in `casa_saav/data/`;
  never put project numbers inside `lib/`.
- `archived/`: superseded designs. Do not edit, do not run, do not copy from it
  without asking. Its paths are not maintained.
- `learning/`: study pages, not used by any calculation.
- `tasks/`: work for an agent that has the code PDFs (the user's PC): equation
  check, member design library. Start at tasks/README.md.
- `verification/`: checking the code equations against the PDFs (on the user's
  PC). README.md is the procedure, audit_2026-10-09.md the open findings. Two
  errors there are confirmed and NOT fixed yet (collar M5, shear-tab net area).

## Rules
- Octave scripts find everything relative to their own file
  (`here = fileparts(mfilename('fullpath'))`), so they run from any folder.
- Check before you claim: after changing a library, run the project scripts
  that use it and compare with the saved outputs (`casa_saav/reports/*_output.txt`,
  the JSON files next to each PDF). Numbers must not change unless intended.
- Sheets: Octave writes a JSON, `lib/printing/*.py` prints it. A ReportLab
  `LayoutError ... too large on page` means a column of the sheet is taller
  than the page: lower a drawing height (`blk_draw(..., h, ...)`) in the
  sheet script, do not touch the printer.
- `casa_saav/data/gg.txt` (ETABS export, 16 MB) is not in git. Ask the user
  for it if a step needs it.
- Assumptions: when a request leaves an input out (a length, a grade, a
  spacing, an unbraced length...), do not fill it in silently. Ask, or use a
  value and list it: every sheet or calculation made for a request carries a
  note "Supuestos: ..." with each input that was not given (also in the reply).
- Sheets: pick the size in sheet_pdf (A1L, A2L, A4); it brings the office title
  block, so never build one. Give only the project fields (proyecto,
  propietario, arquitecto, contenido). Details at a standard scale (blk_draw
  ..., 'std'), information on the drawing as labels, captions short, notes one line.
- Commit or push only when the user asks.

## Planned (not done yet)
- Geometric model per joint type (lib/joint_model): done for the end plate on a
  concrete column (pilot sheet casa_saav/reports/end_plate_model.pdf). Next:
  sandwich and collar; then the A1 sheet details 2.1-2.3 drawn from the model
  (needs the grout thickness decision: 30 in the check, 25 on the A1 sheet).
- A sheet template for joint details (views + sections + pieces + notes).
- sandwich_column has only a made-up example; no project uses it yet.
- The collar sheets (lib/collar_joint) can move their grid and key plan to
  c_grid / c_node.
