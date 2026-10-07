% =====================================================================
%  t3_planos_colocacion.m   A4 placement sheets (Spanish): what is set before the joint is poured.
%
%  Writes reports/planos_colocacion_anclajes.pdf with the printer of
%  joint_calculations (python_support_scripts/joint_pdf.py).
% =====================================================================
here = fileparts(mfilename('fullpath'));
addpath(here);
P = ca_inputs();
R = ca_calc(P);

% ---- EDIT ---------------------------------------------------------------
opts.n = [1 2 1 1];               % number of connections of type E, C1, CX, CY
opts.python  = 'python3';
opts.printer = fullfile(here, 'pour_pdf.py');      % joint_pdf.py with the report colours
opts.page = 'A1L';                 % two A1 landscape sheets (user 2026-10-04: A2, then one A1, were too small)
opts.hk   = 1.4;                   % drawing heights on the sheet, times the A4 ones
opts.fs   = 1.4;                   % text factor: drawing labels and captions 10 pt (3.6 mm)
opts.colw = [1 1 1]/3;
opts.hkp  = [1 1.5 1.3 1.3 1 1 1 1];   % extra drawing factor per page as built (complete sections larger)
opts.layout = {{[1 6], 2, 3}, {4, [5 8], 7}};   % pages as built: 1 location, 2-3 C4/B4/D3, 4-5 D4, 6 C4 bars, 7 pieces, 8 AV
opts.sheetnames = {'Colocación de anclajes 1: ubicación y uniones C4, B4, D3', 'Colocación de anclajes 2: esquina D4, vigas IPE 200, piezas y notas'};
opts.tbh = 45;  opts.tbk = 1.5;    % title block height (mm) and text factor
opts.ncol = 16;                   % columns with a steel column on top (closed ties 14): A1-A4, B1-B4, C1-C4, D1-D4
opts.subtitle = 'Anclajes en el nudo para voladizos IPE 240: colocación antes de la fundición.';
% title block, copied from ../cantilever_anchor/t2_planos_taller.m
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

% ======================================================================
make_pour_sheets(P, R, fullfile(here, 'reports'), opts);
