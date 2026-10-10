# Styles (the `s` argument of d_* and c_*)

Every style below exists when the sheet is printed with `lib/printing/pour_pdf.py`
(it loads joint_pdf.py and adds the r_* styles). Print with pour_pdf.py unless
you have a reason not to. An unknown shape style falls back silently, so check
the name here. Generated from the printers on 2026-10-10.

## Which style for what (the usual choices)
| piece | style |
|---|---|
| concrete cut / seen; cast before (faint) | r_conc / r_old |
| column bars: solid / faint | r_colS / r_col |
| beam bars (in line, second pair, crossing, bottom) | r_bm1, r_bm2, r_bm3, r_bm4 |
| extra bars (bastones, added bars) | r_bas (or r_new) |
| ties: solid / faint | r_tieS / r_tie |
| anchor rods: cast in / after the pour (dashed) | r_anc / r_ancg |
| nuts and washers | r_nut (or r_ancg) |
| head plates / end plates / grout | r_bp / r_eplate / r_grout |
| steel profile: body / flanges | r_ipe / r_ipef (or plate, column, beam) |
| grid line, bubble | axis, bubble |
| dimension-free leaders, cut lines, hidden | lead, cut, hidden |
| joint marker (c_node) | r_oval_l |
| texts: normal, small, bold, red | label, small, code, red |
| texts by colour family: anchors, hooks/bastones, new bars, ties, beam bars | anc, hk, new, tie, bsm |

## Shapes: lines, polygons, circles, bars (stroke, width pt, fill, opacity, dash)

| style | stroke | width | fill | dash |
|---|---|---|---|---|
| plate | #1F5A96 | 1.3 | #BFD7F0 | - |
| plate2 | #2E6B30 | 1.3 | #C6E2C0 | - |
| plate3 | #8A4B9E | 1.3 | #E3CDEB | - |
| column | #333333 | 1.0 | #BDBDBD | - |
| void | #333333 | 0.6 | #FFFFFF | - |
| white | #FFFFFF | 0.1 | #FFFFFF | - |
| beam | #7A5A2F | 0.8 | #F3E7D3 | - |
| beamline | #5A4020 | 1.5 | - | - |
| hidden | #7A5A2F | 0.7 | - | yes |
| weld | #D0021B | 2.4 | - | - |
| weldf | #D0021B | 0.6 | #D0021B | - |
| weld5 | #E0141E | 2.4 | - | - |
| weldf5 | #E0141E | 0.6 | #E0141E | - |
| weld4 | #8E3B1F | 2.4 | - | - |
| weldf4 | #8E3B1F | 0.6 | #8E3B1F | - |
| stab | #2E6B30 | 0.8 | #8CC084 | - |
| tab | #B06F00 | 0.8 | #F5C66B | - |
| tabh | #B06F00 | 0.8 | - | yes |
| angle | #B06F00 | 0.9 | #F5C66B | - |
| angleh | #B06F00 | 0.9 | - | yes |
| bolt | #222222 | 1.2 | #FFFFFF | - |
| center | #8C8C8C | 0.4 | - | yes |
| axis | #9A9A9A | 0.5 | - | yes |
| bubble | #333333 | 0.8 | #FFFFFF | - |
| edge | #555555 | 0.9 | - | yes |
| grid | #9E9E9E | 0.6 | - | - |
| cut | #555555 | 0.6 | - | yes |
| codeM | #D0021B | 2.6 | - | - |
| codeS | #2E8B57 | 2.6 | - | - |
| codeNL | #E08A00 | 2.6 | - | yes |
| codeE | #555555 | 1.6 | - | yes |
| vv | #6A1B9A | 0.8 | #6A1B9A | - |
| vvcut | #6A1B9A | 2.2 | - | - |
| arrow | #333333 | 0.8 | #333333 | - |
| compass | #9A9A9A | 0.5 | - | - |
| r_conc | #6b6b6b | 0.8 | #ece9e2 | - |
| r_concb | #8a8a8a | 0.6 | #ece9e2 | yes |
| r_old | #6b6b6b | 0.8 | #cfc9bb | - |
| r_anc | #7b241c | 0.5 | #c0392b | - |
| r_ancg | #c0392b | 0.6 | #c0392b | yes |
| r_nut | #3d0f0b | 0.5 | #7b241c | - |
| r_bp | #142433 | 0.6 | #34506b | - |
| r_new | #145a32 | 0.5 | #1e8449 | - |
| r_hkA | #6b4a00 | 0.6 | #9a6b00 | - |
| r_hkB | #6b4a00 | 0.6 | #e0b04a | - |
| r_hkAf | None | 0 | #9a6b00 | - |
| r_hkAe | #6b4a00 | 0.6 | - | - |
| r_hkBf | None | 0 | #e0b04a | - |
| r_hkBe | #6b4a00 | 0.6 | - | - |
| r_col | #9a6b00 | 0.4 | #9a6b00 | - |
| r_ex | #5d6d7e | 0.4 | #5d6d7e | - |
| r_tie | #7d3c98 | 0.4 | #7d3c98 | - |
| r_tieS | #4a235a | 0.5 | #7d3c98 | - |
| r_rod | #117a65 | 0.4 | #117a65 | - |
| r_steel | #1f3347 | 0.6 | #a9bdd1 | yes |
| r_bm1 | #0e2f44 | 0.5 | #1a5276 | - |
| r_bm2 | #1b4f72 | 0.5 | #5dade2 | - |
| r_bm3 | #1c2833 | 0.5 | #616a6b | - |
| r_bm4 | #0b5345 | 0.5 | #48c9b0 | - |
| r_bas | #7e3a06 | 0.5 | #e67e22 | - |
| r_colS | #6b4a00 | 0.5 | #c9a227 | - |
| r_rodS | #0b5345 | 0.5 | #45b39d | - |
| r_oval | #e8603c | 1.1 | - | yes |
| r_oval_l | #e8603c | 0.6 | - | - |
| lead | #222222 | 1.0 | - | - |
| dimk | #222222 | 0.6 | - | - |
| r_eplate | #1f3347 | 0.6 | #a9bdd1 | - |
| r_ipe | #1f3347 | 0.5 | #c9d6e3 | - |
| r_ipef | #1f3347 | 0.6 | #7f9bb8 | - |
| r_grout | #6b6b6b | 0.5 | #b9b2a0 | - |
| r_crkh | #e3141e | 1.6 | - | yes |
| r_t1 | #4a235a | 0.5 | #8e44ad | - |
| r_t2 | #1b4f72 | 0.5 | #2e86c1 | - |
| r_t3 | #7e5109 | 0.5 | #e67e22 | - |
| r_t4 | #0b5345 | 0.5 | #17a589 | - |

## Texts (font, size pt at fs = 1, colour)

| style | font | size | colour |
|---|---|---|---|
| label | regular | 7.2 | #222222 |
| small | regular | 7.2 | #444444 |
| title | bold | 8.0 | #111111 |
| code | bold | 7.2 | #111111 |
| red | bold | 7.2 | #D0021B |
| dim | regular | 7.2 | #333333 |
| grid | bold | 8.0 | #333333 |
| compass | regular | 5.0 | #808080 |
| big | bold | 7.5 | #111111 |
| vv | bold | 5.5 | #6A1B9A |
| anc | bold | 7.2 | #a93226 |
| hk | bold | 7.2 | #7a5500 |
| new | bold | 7.2 | #145a32 |
| tie | bold | 7.2 | #5b2c6f |
| bsm | bold | 7.2 | #0e2f44 |
