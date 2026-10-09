# ArcelorMittal 2023 – IPE, HE A, HE B

In Octave: `S = steel_profile('IPE 240')` (also `'HEA300'`, `'HE 200 B'`) returns the row in
mm units (A mm2, I mm4, W mm3, Iw mm6; iy, iz recomputed as sqrt(I/A)). Used by
`lib/sheets/c_ishape.m` and `casa_saav/sheets/make_concrete_sheet.m`.

Source: ArcelorMittal Europe – Long Products, *Sections and Merchant Bars, Sales programme
2023-4* (sections.arcelormittal.com, file `Sections_MB_ArcelorMittal_FR_EN_DE_V2023-5.pdf`).
Local copy: `C:\Users\winpat\Desktop\Bibliography4structures\03 CATALOGOS\ArcelorMittal_Sections_MB_2023.pdf`

The PDF has a text layer, so values are extracted, not transcribed:

    python3 extract_ipe_he.py "<path to pdf>"     # writes ipe.csv, hea.csv, heb.csv
    octave --eval check_ipe_he                    # 0 flags expected

`check_ipe_he.m` recomputes every property from h, b, tw, tf, r with the closed-form
rolled-section formulas. A, G, I, Wel, Wpl, Avz and Iw agree within 0.5 % (worst case 0.2 of
the tolerance); iy, iz, ss agree with the catalog's truncation to 1 decimal; It is a loose check
(8 %) because the catalog's It is not reproduced exactly by any closed-form fillet formula.

| file | series | rows |
|---|---|---|
| ipe.csv | IPE 80 – IPE 600 | 18 |
| hea.csv | HE 100 A – HE 1000 A | 24 |
| heb.csv | HE 100 B – HE 1000 B | 24 |

Only the standard series. The PDF also has IPE A / O / AA, IPE 750, HE AA and HE M;
the extractor can be extended for these.

## Columns (same in all three files)

EN convention: **y-y is the strong axis**, z-z the weak axis.

| column | unit | meaning |
|---|---|---|
| name | | designation as in the catalog (IPE 300, HE 300 A) |
| G_kgm | kg/m | mass |
| h_mm, b_mm, tw_mm, tf_mm, r_mm | mm | depth, flange width, web, flange, root radius |
| A_cm2 | cm² | area |
| hi_mm, d_mm | mm | inner depth h − 2tf, straight web depth hi − 2r |
| AL_m2m | m²/m | painting surface |
| Iy_cm4, Wely_cm3, Wply_cm3, iy_cm | | strong axis: inertia, elastic and plastic modulus, radius of gyration |
| Avz_cm2 | cm² | shear area for a load parallel to the web |
| Iz_cm4, Welz_cm3, Wplz_cm3, iz_cm | | weak axis |
| ss_cm | cm | length of stiff bearing |
| It_cm4 | cm⁴ | torsion constant |
| Iw_cm6 | cm⁶ | warping constant (catalog prints ×10³; converted here) |

Notes:
- iy, iz and ss are **truncated** to 1 decimal in the catalog (e.g. IPE 300 iy = 12.4, exact
  12.46). For design, use √(I/A).
- Catalog typo fixed in the extractor: IPE 100 iy is printed `4;0` → 4.0.
