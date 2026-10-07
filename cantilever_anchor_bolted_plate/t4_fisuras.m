% =====================================================================
%  t4_fisuras.m   One A4 sheet (Spanish) for the architect: cracks expected under service loads.
%
%  Writes reports/fisuras_esperadas_voladizos.pdf with the printer of
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
opts.ncol = 16;                   % columns with a steel column on top (closed ties 14): A1-A4, B1-B4, C1-C4, D1-D4
opts.subtitle = 'Voladizos IPE 240 anclados a las columnas: fisuras esperadas en servicio.';
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
make_crack_sheet(P, R, fullfile(here, 'reports'), opts);
