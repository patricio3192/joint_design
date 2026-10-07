% =====================================================================
%  t2_planos_taller.m   A4 workshop sheets of the bolted plate anchorage (Spanish).
%
%  Writes reports/planos_taller_placa_empernada.pdf with the printer of
%  joint_calculations (python_support_scripts/joint_pdf.py).
% =====================================================================
here = fileparts(mfilename('fullpath'));
addpath(here);
P = ca_inputs();
R = ca_calc(P);

% ---- EDIT ---------------------------------------------------------------
opts.n = [1 2 1 1];               % number of connections of type E, C1, CX, CY
opts.page = 'A2L';                 % one A2 landscape sheet (user 2026-10-04)
opts.hk   = 0.85;  opts.fs = 0.8;  opts.colw = [0.32 0.32 0.36];
opts.python  = 'python3';
opts.printer = fullfile(here, '..', 'python_support_scripts', 'joint_pdf.py');
opts.subtitle = 'Placa extremo empernada a anclajes en el nudo, para voladizos IPE 240.';
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
make_workshop_sheets(P, R, fullfile(here, 'reports'), opts);
