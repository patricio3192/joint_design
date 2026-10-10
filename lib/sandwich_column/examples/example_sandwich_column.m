% =====================================================================
%  example_sandwich_column.m   Column sandwich with MADE-UP numbers (not a
%  project): IPE 200 on both faces of a 40 x 40 column, 4 through-rods M16.
%    octave-cli lib/sandwich_column/examples/example_sandwich_column.m
%  Prints the checks and the clash list; writes example_sandwich_column.json/.pdf
%  here. A project copies this input into its data/ folder.
% =====================================================================
here = fileparts(mfilename('fullpath'));
lib = fullfile(here, '..', '..');
addpath(lib);  addlib();                       % every library on the path

P.load = struct('Mu_A_kNm', 23.5, 'Vu_A_kN', 21.5, 'Mu_B_kNm', 12.0, 'Vu_B_kN', 14.0);
P.beam = aisc_beam('IPE 200', 250, 400);       % catalog, AISC names (lib/profiles/aisc_beam.m)
P.beam.L_span = 4800;  P.beam.L_brace = 2400;  % unbraced lengths checked for LTB
P.column = struct('b', 400, 'h', 400, 'top', Inf, ...       % the column continues above
                  'fc', 21, 'fy_bar', 412, 'lambda', 1.0, 'cover', 40, ...
                  'db_hoop', 10, 'db_bar', 16, 'bars_side', 3, ...
                  'hoop_y', [10 110 230 300], ...           % ties in the joint, clear of the rod rows
                  'gamma', 1.25);                           % ACI Table 15.4.2.3: pick for the real case
P.plate = struct('tp', 12, 'bp', 140, 'ext', 20, 'Fyp', 250, 'Fup', 400, 't_grout', 25);
P.rods = struct('d_b', 16, 'Fu', 860, 'dh', 18, 'dist_top', 42, 'g', 55, 'dist_bot', 160, ...
                'torqued', false, 'splitting_reinf', true, ...
                't_wsh', 3, 'h_nut', 16, 'dw', 30, 'nw', 24, 'proj', 5, 'leveling', true);
P.weld = struct('FEXX', 482, 'top_cjp', true, 'S_pjp', 6, 'pjp_flat', true, 'w_fl', 6, 'w_web', 6);

R = check_sandwich_column(P);
M = model_sandwich_column(P, R);
F = jm_clash(M);
Q = jm_quantities(M);
V = views_sandwich_column(M, P, R);

[tc, tq] = jm_tables(F, Q);
tq{end+1} = blk_note('Ejemplo con números inventados (lib/sandwich_column/examples). Cálculo, modelo, choques y cantidades salen del mismo P.');
B = {blk_h(1, sprintf('Sándwich en columna %gx%g: %s en las dos caras (ejemplo)', P.column.b, P.column.h, P.beam.name)), ...
     blk_row([0.42 0.24 0.34], {{blk_draw(V.side, 110, 'CORTE POR EL EJE DE LAS VIGAS', 'Hormigón cortado en x = 0.')}, ...
                                {blk_draw(V.front, 110, 'VISTA DESDE LA CARA A', 'Sin la placa de la cara B.')}, ...
                                {blk_draw(V.plan, 110, 'PLANTA POR LOS ANCLAJES DE TRACCIÓN', '')}}), ...
     blk_row([0.56 0.44], {tc, tq})};
doc = struct('title', 'Sándwich en columna', 'page', 'A2L', 'fs', 1.0, 'blocks', {B});
base = fullfile(here, 'example_sandwich_column');
fid = fopen([base '.json'], 'w');  fprintf(fid, '%s', jsonencode(doc));  fclose(fid);
[st, out] = system(sprintf('python3 "%s" "%s.json" "%s.pdf"', fullfile(lib, 'printing', 'pour_pdf.py'), base, base));
if st ~= 0, fprintf('%s', out);  error('PDF generation failed (see the message above).'); end
