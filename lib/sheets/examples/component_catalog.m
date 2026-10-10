% =====================================================================
%  component_catalog.m   Lámina de plantillas: one A2 sheet with an example of
%  every component of lib/sheets, drawn as a real sheet would use it (invented
%  structure, invented numbers). The visual index of what is available.
%    octave-cli lib/sheets/examples/component_catalog.m
%  Writes component_catalog.json / .pdf next to this file.
% =====================================================================
here = fileparts(mfilename('fullpath'));
lib  = fullfile(here, '..', '..');
addpath(lib);  addlib();

% ---- 1. location plan: grid, concrete beams and columns, steel members by colour,
%         joints, extra bar, cut mark, legend, dimensions -------------------------
xs = [0 4500 9500 14000];  ys = [0 5000 9000];
G.v = {'A', [xs(1) 0], [xs(1) 9000];  'B', [xs(2) 0], [xs(2) 9000];
       'C', [xs(3) 0], [xs(3) 9000];  'D', [xs(4) 0], [xs(4) 9000]};
G.h = {'1', ys(1);  '2', ys(2);  '3', ys(3)};
pl = c_grid(G, [-900 15900 -900 9900], struct('r', 300));
for y = ys, pl = [pl, c_member([xs(1) y], [xs(end) y], 250, 'm_conc', '', struct('cut', [150 150]))]; end
for x = xs, pl = [pl, c_member([x ys(1)], [x ys(end)], 250, 'm_conc', '', struct('cut', [150 150]))]; end
pl = [pl, c_member([xs(1) ys(2)], [xs(2) ys(2)], 250, 'm_conc', 'V-2  25x40', struct('at', 0.3))];
pl = [pl, c_member([xs(1) ys(1)], [xs(1) ys(2)], 250, 'm_conc', 'V-A  25x40')];
for x = [6200 7800]
  pl = [pl, c_member([x ys(1) + 125], [x ys(2) - 125], 110, 'm1', 'IPE 200', struct('off', -170))];
end
pl = [pl, c_member([xs(4) + 150 ys(2)], [xs(4) + 1600 ys(2)], 130, 'm2', 'IPE 240', struct('off', -200))];
k = 0;
for x = xs, for y = ys
  k = k + 1;  pl = [pl, c_column_mark(x, y, 300, 300, sprintf('C%d', k))];
end, end
pl = [pl, c_node(xs(4), ys(2), 'D2'), c_node(xs(3), ys(2), 'C2')];
pl = [pl, c_rebar([5400 ys(2) - 260; 8600 ys(2) - 260], 60, 'r_bas', ...
                  struct('label', '+2Ø12, L = 3200', 'at', [7000 ys(2) - 620]))];
pl = [pl, c_cutmark([2250 ys(2)], [1 0], 'A', struct('k', 0.9))];
pl = [pl, c_dim_chain([xs' -650*ones(4,1)], 0), c_dim_chain([[-700; -700; -700] ys'], 0)];
pl = [pl, c_legend(5200, -1700, {'m_conc', 'Vigas de hormigón 25x40';  'm_col', 'Columnas de hormigón 30x30';
                                 'm1', 'IPE 200';  'm2', 'IPE 240'}, struct('w', 600, 'h', 150, 'dy', 330))];

% ---- 2. concrete sections with their reinforcement written out ---------------------
S = struct('b', 250, 'h', 400, 'ct', 44, 'dst', 8);
yb = 40 + 8 + 7;  xb = 125 - yb;
S.bars = [-xb yb 14; 0 yb 14; xb yb 14; -xb 400-yb 14; 0 400-yb 14; xb 400-yb 14;
          -xb 400-yb-38 12; xb 400-yb-38 12];            % a second top layer: just more rows in S.bars
S.bar_s = [repmat({'r_bm1'}, 1, 6), {'r_bas', 'r_bas'}];   % one style per bar (extra bars in orange)
bs = [c_rc_section(S), c_rc_dims(S, struct('st', true)), c_rc_labels(S, struct('st', 'Est. Ø8 c/15'))];
T = struct('b', 300, 'xc', 150 - 40 - 10 - 8, 'db_col', 16, 'db', 10);
T.col_dims = true;
cs = c_column_tie(T);
% larger column: 12 bars, outer stirrup + interior stirrup + two crossties (90 deg hooks alternated)
q = [58 186 314 442];  C = struct('b', 500, 'h', 500, 'ct', 45, 'dst', 10, 'rb', 13);
C.bars = [];
for x = q - 250, for y = q
  if abs(x) > 190 || y < 60 || y > 440, C.bars(end+1,:) = [x y 16]; end
end, end
C.inner = [-64 58 64 442 16];
C.xties = [-192 186 192 186 16;  192 314 -192 314 16];
cg = [c_rc_section(C), c_rc_dims(C, struct('st', true)), ...
      c_rc_labels(C, struct('kind', 'column', 'st', 'Est., est. int. y grapas Ø10 c/10'))];
B8 = [];  for sx = -1:1, for sy = -1:1, if sx || sy, B8(end+1,:) = [sx*T.xc sy*T.xc 16]; end, end, end
cs = [cs, c_rc_labels(struct('b', 300, 'h', 300, 'ct', 45, 'bars', B8), ...
                      struct('kind', 'column', 'y0', -150, 'st', 'Est. Ø10 c/10 (nudo)'))];

% ---- 3. end plate detail: front and elevation, with the pieces named ------------------
ip = steel_profile('IPE 220');
N = struct('wsh', 3, 'nut', 16, 'dw', 30, 'nw', 24, 'd', 16);
fr = [c_plate(struct('b', 130, 'H', 240, 'g', 80, 'rows', [40 190], 'dh', 18)), c_ishape(ip, 'section')];
for y = -[40 190], for x = [-40 40], fr = [fr, c_nut_front(x, y, N)]; end, end
fr = [fr, c_leader(150, 40, [65 -10], 'PL 130x240x12 A36', 'label'), ...
          c_leader(150, -120, [40 -190], '4 var. Ø16 A193 B7', 'anc')];
el = {d_rectxy(0, -320, 300, 80, 'r_conc'), d_rectxy(-25, -240, 0, 0, 'r_grout'), d_rectxy(-37, -240, -25, 0, 'r_eplate')};
el = [el, c_ishape(ip, 'elevation', struct('x0', -420, 'x1', -37))];
for y = -[40 190]
  el{end+1} = d_bar(-61, y, 250, y, 16, 'r_anc');
  el = [el, c_nut(-37, y, -1, N, 'r_nut')];
end
el = [el, c_leader(330, 40, [-31 -20], 'Grout sin contracción, e = 25', 'label'), ...
          c_leader(330, -60, [200 -40], 'Varilla Ø16, L = 330: 250 en la columna', 'anc'), ...
          c_leader(330, -270, [-200 -230], ip.name, 'label')];
el = [el, c_dim_chain([-37 120; 0 120; 250 120], 0), c_dim_chain([-470 0; -470 -40; -470 -190; -470 -240], 0)];

% ---- 4. loose pieces ------------------------------------------------------------
rod = [{d_bar(0, 0, 330, 0, 16, 'r_anc'), d_rectxy(60, -60, 72, 60, 'r_eplate')}, ...
       c_nut(72, 0, 1, N, 'r_nut'), c_nut(60, 0, -1, N, 'r_nut'), {d_dim(0, -40, 330, -40, -30, 'L = 330')}, ...
       c_leader(380, 70, [300 8], 'Ø16 A193 B7, rosca corrida', 'anc')];
hs = [c_hss(200, 100, 4), {d_text(0, 90, 'HSS 200x100x4', 'label', 'middle')}];
ib = [c_ishape(ip, 'section'), {d_text(0, 30, ip.name, 'label', 'middle')}];

% ---- tables and notes ---------------------------------------------------------------
head = {'Marca', 'Elemento', 'Descripción', 'Cant.'};
rows = {{'A1', 'Varilla', 'Ø16 A193 B7, L = 330', '4'};  {'P2', 'Placa extremo', 'PL 130x240x12 A36, 4 agujeros Ø18', '1'};
        {'T', 'Tuerca', 'Ø16 grado 8', '4'};  {'BA', 'Barra extra', '2Ø12, L = 3200', '2'}};
notes = {'Medidas en mm.', 'Hormigón f''c 21 MPa; acero de refuerzo fy 412 MPa.', ...
         'Supuestos: longitud de varilla y tuercas grado 8 no dados en el pedido.'};

c1 = {blk_h(2, '1. Planta de ubicación'), ...
      blk_draw(pl, 195, 'PLANTA DE UBICACIÓN', 'c_grid, c_member, c_column_mark, c_node, c_rebar, c_cutmark, c_dim_chain, c_legend', 'std')};
c2 = {blk_h(2, '2. Secciones de hormigón'), ...
      blk_row([0.32 0.3 0.38], {{blk_draw(bs, 175, 'CORTE A-A: V-2 25x40', '2.ª capa arriba = más filas en S.bars', 'std')}, ...
                                {blk_draw(cs, 175, 'COLUMNA C 30x30', 'c_column_tie + c_rc_labels', 'std')}, ...
                                {blk_draw(cg, 175, 'COLUMNA 50x50', 'S.inner (estribo interior) + S.xties (grapas)', 'std')}})};
c3 = {blk_h(2, '3. Conexión placa extremo (D2)'), ...
      blk_row([0.42 0.58], {{blk_draw(fr, 160, 'VISTA DE FRENTE', 'c_plate + c_ishape + c_nut_front + c_leader', 'std')}, ...
                            {blk_draw(el, 160, 'ELEVACIÓN', 'c_ishape (elevación) + c_nut + c_leader', 'std')}})};
c4 = {blk_h(2, '4. Piezas, cantidades y notas'), ...
      blk_row([0.5 0.25 0.25], {{blk_draw(rod, 40, 'A1: VARILLA', 'c_nut a cada lado de una placa', 'std')}, ...
                                {blk_draw(hs, 40, 'HSS', 'c_hss', 'std')}, {blk_draw(ib, 40, 'IPE', 'c_ishape', 'std')}}), ...
      blk_h(3, '**Cantidades** (blk_table)'), blk_table(head, rows, [0.12 0.25 0.5 0.13], 4, []), ...
      blk_h(3, '**Notas** (blk_note)')};
for i = 1:numel(notes), c4{end+1} = blk_note(sprintf('%d. %s', i, notes{i})); end
B = {blk_h(1, 'Lámina de plantillas (lib/sheets)'), blk_row([0.5 0.5], {c1, c2}), blk_row([0.5 0.5], {c3, c4})};
o = struct('page', 'A2L', 'title', 'Plantillas', ...             % the size brings its title block
           'project', struct('proyecto', 'EJEMPLO (estructura inventada)', 'estructural', 'PRUEBA', ...
                             'contenido', 'Lámina de plantillas', 'subtitle', 'Una muestra de cada componente de lib/sheets.'));
sheet_pdf(B, fullfile(here, 'component_catalog'), o);
