% =========================================================================
% casa_saav / end_plate_model.m
% 3D model of the end plate joint C4 built from the SAME input as the checks
% (data/end_plate_C4.m): clash list, quantities and the three views on one
% A2 sheet (pilot of lib/joint_model).
%   octave-cli casa_saav/end_plate_model.m
% Writes reports/end_plate_model.json / .pdf; prints the clash list (saved in
% reports/end_plate_model_output.txt).
% =========================================================================
clc; clear;
here = fileparts(mfilename('fullpath'));
lib = fullfile(here, '..', 'lib');
addpath(fullfile(lib, 'end_plate_concrete'), fullfile(lib, 'concrete_common'), fullfile(lib, 'joint_model'), ...
        fullfile(lib, 'sheets'), fullfile(lib, 'profiles'), fullfile(here, 'data'));

P = end_plate_C4();
evalc('R = check_end_plate_column(P);');        % report: end_plate_column.m
M = model_end_plate_column(P, R);
F = jm_clash(M);
Q = jm_quantities(M);
V = views_end_plate_column(M, P, R);

% ---- sheet ---------------------------------------------------------------------
notes = {
  'Todo sale del modelo 3D (lib/joint_model), construido con los mismos datos del cálculo (casa_saav/data/end_plate_C4.m): si cambia un dato, cambian el cálculo, las vistas, los choques y las cantidades.'
  'Holgura = distancia libre entre superficies (mm). Separación: barras paralelas a menos de max(25, db, 4/3 tamaño de agregado 19) (ACI 25.2.1). Contacto: se tocan (normal en barras que se cruzan y se amarran). Justo: menos de 10.'
  'Dónde: coordenadas x (a lo largo de la cara), y (hacia abajo desde la cara superior de las vigas), z (hacia dentro de la columna).'
  'Cantidades por unión, solo lo que añade la conexión. Estribos: perímetro sin ganchos. Barras de vigas y columna: contexto, no se cuentan.'
  'Diferencia con la lámina A1 (planos_conexiones): allí el grout es 25; aquí 30, como en el cálculo. Hay que decidir uno y dejarlo solo en data/end_plate_C4.m.'};
c1 = {blk_draw(V.side, 120, 'CORTE POR EL EJE DE LA VIGA', 'Hormigón cortado en x = 0; barras y acero vistos.')};
c2 = {blk_draw(V.front, 120, 'VISTA DESDE LA VIGA', 'Sin la viga de atrás.')};
c3 = {blk_draw(V.plan, 120, 'PLANTA POR LOS ANCLAJES DE TRACCIÓN', sprintf('Corte entre y = 0 y y = %g.', P.rods.y_t + 80))};
[t1, t2] = jm_tables(F, Q);
for i = 1:numel(notes), t2{end+1} = blk_note(sprintf('%d. %s', i, notes{i})); end
B = {blk_h(1, sprintf('Unión placa extremo - columna C4: modelo 3D (%s, placa %gx%gx%g)', P.beam.name, ...
                      P.plate.bp, P.beam.h + P.plate.ext, P.plate.tp)), ...
     blk_row([0.38 0.28 0.34], {c1, c2, c3}), blk_row([0.56 0.44], {t1, t2})};
doc = struct('title', 'Modelo placa extremo C4', 'page', 'A2L', 'fs', 1.0, 'blocks', {B});
base = fullfile(here, 'reports', 'end_plate_model');
fid = fopen([base '.json'], 'w');  fprintf(fid, '%s', jsonencode(doc));  fclose(fid);
[st, out] = system(sprintf('python3 "%s" "%s.json" "%s.pdf"', fullfile(lib, 'printing', 'pour_pdf.py'), base, base));
if st ~= 0, fprintf('%s', out);  error('PDF generation failed (see the message above).'); end
