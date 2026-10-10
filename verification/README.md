# Verification of the equations (handoff for the agent on the user's PC)

You are a Claude Code agent running on the user's own PC, where the design
code PDFs are. The cloud agent that wrote most of lib/ could not open them.
Your job: check every code equation used in lib/ against its page, record the
result, and fix what is wrong **with the user's approval**. Read the root
CLAUDE.md first (rules, token economy) and `audit_2026-10-09.md` here (what a
read-only audit of the code found).

## Where the PDFs are
`C:\Users\winpat\Desktop\Bibliography4structures\02 NORMATIVAS\`
- `AISC\AISC 360-16 Specification for Structural Steel Buildings.pdf`  [A360]
- `AISC\guias de diseno\pdfcoffee.com_aisc-design-guide-39-end-plate-moment-connections-2023-4-pdf-free.pdf`  [DG39]
- `AISC\guias de diseno\design-guide-1-base-plate-and-anchor-rod-design-second-edition.pdf`  [DG1]
- `ACI\ACI 318-19.pdf` (in-lb edition; SI coefficients in its Appendix C, PDF p. 587-595)  [ACI]
Also cited and NOT in that folder (ask the user where they are, or whether to
leave them unchecked): ASTM A193 Table 2, ISO 7089, EN 1993-1-8 6.2.5, AISC
Steel Construction Manual Parts 9 and 10, CIDECT Design Guide 9, AISC 360-10.

"PDF p." in the EQUATIONS files is the page index of the PDF file (as a viewer
shows it), not the printed page number.

## How to read the pages (tokens cost the user money)
Use the Read tool with `pages` (at most 20 per call). Read only the cited page,
plus one page before/after if the equation continues. Never read a whole code.
If a reference has no page (collar and direct-weld manuals), find it through
the PDF's table of contents or bookmarks first, then read only that page.

## What to check for each line
1. The equation in the PDF is the one the CODE computes (open the .m line; the
   audit gives file:line), not only the one written in EQUATIONS.txt.
2. Coefficient, phi factor, limits and conditions of use (the "if" around it).
3. SI form: the coefficient comes from ACI Appendix C, or the conversion is
   right (the audit recomputed all of them numerically: all correct).
4. The page number is right; fix it if not.

## Where to record it
One file per library here: `status_<library>.md`, a table with one row per
equation: `module | equation | reference | page | status | note`, status one
of `OK` (matches, date), `DIFF` (what differs), `PAGE` (right equation, wrong
page: fixed), `MISSING` (in the code, not in the reference file: added),
`OWN` (engineering model, not a code equation: say so). When a library is
finished, add one line to its CLAUDE.md: "Equations checked against the
pages on <date>: verification/status_<library>.md".

## Order (most useful first)
1. **Two errors confirmed in the code** (audit items S1, S2). Show the user the
   fix and what it changes before editing; then rerun casa_saav/collar_joints.m
   (steps check, details, sheets) and report which ratios changed.
2. **collar_joint**: the manual has clause numbers but no pages, and about 14
   groups of checks are not in it at all. Create lib/collar_joint/EQUATIONS.txt
   in the format of lib/end_plate_concrete/EQUATIONS.txt.
3. **direct_weld_joint**: same (no pages).
4. **end_plate_concrete, sandwich_concrete**: pages exist; check them; add the
   few missing items (audit table B/C).
5. **sandwich_column** (new 2026-10-10): its own-model items (modules 6 and 10)
   need the user's engineering judgment, not only a page check.

## Also add (asked by tests with a small model)
- The rows of ACI Table 15.4.2.3 (joint shear coefficient) in SI, into
  lib/end_plate_concrete/EQUATIONS.txt and lib/sandwich_column/EQUATIONS.txt,
  so the user can pick gamma from the file.
- What counts as supplementary reinforcement for the ACI 17.9.1 waiver
  (splitting_reinf in the sandwich libraries), with its page.

## Worked examples as tests (worth more than reading)
Reading confirms the transcription; reproducing a solved example confirms the
code. Good candidates: DG 39 Example 5.2-1 (PDF p. 79-82, flush end plate:
Yp, tp,req, bolt force, welds) and the DG 1 base plate examples (bearing,
Y, tp). Write each as a small script in `lib/<library>/tests/` that feeds the
example's numbers (converted to N, mm) to the same helper functions and prints
the example's values next to ours. Agreement within rounding = pass.

## Rules that do not change
- Numbers of casa_saav must not change unless intended. After any library
  change rerun the project scripts and compare with casa_saav/reports/*_output.txt
  and the JSON next to each PDF. Intended changes: regenerate, and tell the
  user exactly which numbers changed.
- Do not edit archived/. Commit or push only when the user asks.
