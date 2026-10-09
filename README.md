# joint_design

Steel connection design in Octave: libraries for each connection type, and
the project that uses them. Sheets (PDF and editable DXF) come out of the same
scripts. ACI 318-19, AISC 360-16, LRFD.

```
lib/                     libraries: no project data inside
  collar_joint/          beam to HSS column through external diaphragm collars (dmj_lib)
  direct_weld_joint/     beams welded straight to the HSS column (dwj_lib), and the
                         comparison with the collar joint
  etabs/                 ETABS text export -> joint database (forces at every joint)
  end_plate_concrete/    helpers: steel end plate on a concrete column (anchors, bastones)
  sandwich_concrete/     helpers: steel beams on both faces of a concrete beam, through-rods
  concrete_common/       helpers shared by the two concrete libraries
  printing/              JSON sheet -> PDF (joint_pdf.py, pour_pdf.py) and -> DXF
                         (json_dxf.py, armar_lamina.py)
casa_saav/               the project (Vivienda Ortega): data, one script per connection
                         type, sheets, reports
archived/                superseded designs, kept for reference only
learning/                study material (yield-line theory)
snap.sh                  ./snap.sh "message" saves a git snapshot
```

Each library has a `README.md` (how to use it, what it assumes) and a
`CLAUDE.md` (its limits, so the agent warns before it is used outside them).
Start a project the way `casa_saav/` does: a `data/` folder with the project
input, and scripts that add the libraries to the path and call them.

Needs: GNU Octave (8.x), Python 3 with ReportLab (`sudo apt install
python3-reportlab`) for the PDFs, and `pip install ezdxf` for the DXF.
