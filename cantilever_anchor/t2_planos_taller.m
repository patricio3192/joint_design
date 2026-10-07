% =====================================================================
%  t2_planos_taller.m   A4 workshop sheets of the embedded assemblies (Spanish).
%
%  Writes reports/planos_taller_anclajes.pdf with the printer of
%  joint_calculations (python_support_scripts/joint_pdf.py), same format as
%  the joint plan sheets.
% =====================================================================
here = fileparts(mfilename('fullpath'));
addpath(here);
P = ca_inputs();
R = ca_calc(P);

% ---- EDIT ---------------------------------------------------------------
opts.n = [1 1 3];                 % number of assemblies of type E, C1, C2
opts.python  = 'python3';
opts.printer = fullfile(here, '..', 'python_support_scripts', 'joint_pdf.py');
opts.subtitle = 'Placas embebidas con varillas de anclaje, para voladizos IPE 200 sobre pedestales de hormigón.';
% title block, copied from joint_calculations/t5_planos.m
opts.titleblock = {
  'PROYECTO:',               'VIVIENDA EDGAR ORTEGA Y FAMILIA'
  'PROPIETARIO:',            'SR. EDGAR ORTEGA'
  'DISEÑO ARQUITECTÓNICO:',  'DAVID SAAVEDRA'
  'DISEÑO ESTRUCTURAL:',     'ING. PATRICIO RODRIGUEZ\nSENESCYT: 1007-15-1429459'
  'CONTENIDO:',              '@sheet'
  'FECHA:',                  'SEPTIEMBRE 2026'
  'LÁMINA:',                 '@page'
};
opts.tbwidths = [13 11 18 16 21 13 8];   % A4: wider columns for the long labels

% ======================================================================
make_workshop_sheets(P, R, fullfile(here, 'reports'), opts);
