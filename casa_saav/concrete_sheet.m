% =====================================================================
%  casa_saav / concrete_sheet.m   One A1 landscape sheet (Spanish): location
%  plan, end plate on concrete column (C4, B4, D4X, D4Y, D3) and sandwich
%  connections (10).  Geometry and text: sheets/make_concrete_sheet.m.
%  Writes reports/planos_conexiones.json and .pdf through lib/printing/pour_pdf.py.
%  Design numbers: end_plate_column.m and sandwich_beam.m (reports/*_output.txt).
%  Editable DXF of the sheet: see lib/printing/README.md (json_dxf.py).
% =====================================================================
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'sheets'));

opts.python  = 'python3';
opts.printer = fullfile(here, '..', 'lib', 'printing', 'pour_pdf.py');
opts.page = 'A1L';
opts.fs   = 1.25;                  % text factor
opts.tbh  = 45;  opts.tbk = 1.5;   % title block height (mm) and text factor
opts.sheetname = 'Conexiones de vigas de acero';
opts.subtitle  = 'Anclajes, bastones, estribos y placas de las conexiones de las vigas IPE 240 e IPE 200.';
opts.titleblock = {
  'PROYECTO:',               'VIVIENDA EDGAR ORTEGA Y FAMILIA'
  'PROPIETARIO:',            'SR. EDGAR ORTEGA'
  'DISEÑO ARQUITECTÓNICO:',  'DAVID SAAVEDRA'
  'DISEÑO ESTRUCTURAL:',     'ING. PATRICIO RODRIGUEZ\nSENESCYT: 1007-15-1429459'
  'CONTENIDO:',              '@sheet'
  'FECHA:',                  'OCTUBRE 2026'
  'LÁMINA:',                 '@page'
};
opts.tbwidths = [13 11 18 16 21 13 8];

make_concrete_sheet(fullfile(here, 'reports'), opts);
