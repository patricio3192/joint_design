% =====================================================================
%  component_catalog.m   One A3 sheet with every component of lib/sheets,
%  drawn with made-up numbers: the visual index of what is available.
%    octave-cli lib/sheets/examples/component_catalog.m
%  Writes component_catalog.json / .pdf next to this file.
% =====================================================================
here = fileparts(mfilename('fullpath'));
lib  = fullfile(here, '..', '..');
addpath(fullfile(lib, 'sheets'), fullfile(lib, 'profiles'));

% grid with an inclined line, joints marked with c_node, an extra bar
G.v = {'A', [-1500 0], [-2000 6000];  'B', [0 0], [0 6000];  'C', [4500 0], [4500 6000]};
G.h = {'1', 0;  '2', 3000;  '3', 6000};
it = c_grid(G, [-2700 5400 -900 6900], struct('r', 260, 'tdy', -80));
for y = [0 3000 6000], it{end+1} = d_rectxy(-1500 - y/12, y - 150, 4500, y + 150, 'beam'); end
it = [it, c_node(0, 3000, 'B2'), c_node(4500, 3000, 'C2', struct('ls', 'code'))];
it = [it, c_rebar([600 3400; 3900 3400], 40, 'r_bas', struct('label', '+2Ø12, L = 3300', 'at', [2250 3600]))];
it = [it, c_rebar([600 2500; 3200 2500; 3200 1800], 40, 'r_bm2', struct('r', 150))];
it = [it, c_cutmark([2250 6000], [1 0], 'A', struct('k', 0.8))];
it = [it, c_dim_chain([0 -650; 4500 -650], 0), c_dim_chain([5900 0; 5900 3000; 5900 6000], 0)];
plan = blk_draw(it, 120, 'c_grid, c_node, c_rebar, c_cutmark, c_dim_chain', ...
                'Ejes (uno inclinado), nudos marcados, barras adicionales recta y doblada, corte y cotas.');

% concrete section: 3 + 3 bars, stirrup with 135 deg hooks
S = struct('b', 300, 'h', 350, 'ct', 45, 'dst', 10);
S.bars = [-94 294 12; 0 294 12; 94 294 12; -94 56 12; 0 56 12; 94 56 12];
sec = c_rc_section(S);
sec{end+1} = d_text(0, 380, '3Ø12', 'bsm', 'middle');  sec{end+1} = d_text(0, -60, '3Ø12', 'bsm', 'middle');
sec = [sec, c_rc_dims(S)];
tie = c_column_tie(struct('b', 400, 'xc', 142, 'db_col', 16, 'db', 10));

% steel: IPE 240 from the catalog, HSS 200x100x4, plate with holes, rod with nuts
ip = steel_profile('IPE 240');
st = [c_ishape(ip, 'section'), {d_text(0, 30, ip.name, 'label', 'middle')}, ...
      c_hss(200, 100, 4, struct('c', [260 -120])), {d_text(260, 0, 'HSS 200x100x4', 'label', 'middle')}];
el = [c_ishape(ip, 'elevation', struct('x0', 0, 'x1', 600)), ...
      c_leader(700, 40, [450 -5], 'ala superior', 'label'), c_leader(700, -150, [450 -120], 'alma', 'label')];
pl = c_plate(struct('b', 140, 'H', 260, 'g', 80, 'rows', [42 198], 'dh', 18));
N = struct('wsh', 3, 'nut', 16, 'dw', 30, 'nw', 24);
rod = [{d_bar(0, 0, 440, 0, 16, 'r_anc'), d_rectxy(100, -70, 112, 70, 'r_eplate')}, ...
       c_nut(112, 0, 1, N, 'r_nut'), c_nut(100, 0, -1, N, 'r_nut'), {d_dim(0, -50, 440, -50, -30, 'L = 440')}];

B = {blk_h(1, 'Componentes de dibujo (lib/sheets)'), ...
     blk_row([0.55 0.45], {{plan}, {blk_row([0.5 0.5], {{blk_draw(sec, 60, 'c_rc_section + c_rc_dims', 'Sección de hormigón 30x35.')}, ...
                                                       {blk_draw(tie, 60, 'c_column_tie', 'Columna 40x40, estribo Ø10.')}}), ...
                                blk_row([0.5 0.5], {{blk_draw(st, 45, 'c_ishape (sección), c_hss', 'IPE 240 del catálogo (steel_profile).')}, ...
                                                       {blk_draw(pl, 45, 'c_plate', 'Placa 140x260, 4 agujeros Ø18.')}}), ...
                                blk_draw(el, 30, 'c_ishape (elevación) + c_leader', 'Perfil de lado y textos con línea guía.'), ...
                                blk_draw(rod, 25, 'c_nut', 'Varilla con arandela y tuerca a cada lado de una placa.')}})};
doc = struct('title', 'Componentes', 'page', 'A2L', 'fs', 1.0, 'blocks', {B});
base = fullfile(here, 'component_catalog');
fid = fopen([base '.json'], 'w');  fprintf(fid, '%s', jsonencode(doc));  fclose(fid);
[st_, out] = system(sprintf('python3 "%s" "%s.json" "%s.pdf"', fullfile(lib, 'printing', 'pour_pdf.py'), base, base));
fprintf('%s', out);
if st_ ~= 0, error('PDF generation failed.'); end
