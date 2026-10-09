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
- Commit or push only when the user asks.

## Planned (not done yet)
- A geometric model per joint type (bars, rods, plates, profiles as 3D pieces,
  built from the same P as the checks): views for the sheets, clash checks
  (lib toolbox) and quantities from it. Pilot: end plate on concrete column.
- A sheet template for joint details (views + sections + pieces + notes).
- The collar sheets (lib/collar_joint) can move their grid and key plan to
  c_grid / c_node.
