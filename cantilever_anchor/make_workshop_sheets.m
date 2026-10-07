function file = make_workshop_sheets(P, R, outdir, opts)
% MAKE_WORKSHOP_SHEETS  A4 workshop sheets (Spanish) of the embedded assemblies:
%   1  quantities, bar schedule and notes
%   2  type E  (edge column: 2 bars under the lug + 2 over)
%   3  type C1 (corner column: 2 bars under the lug)
%   4  type C2 (corner column: 2 bars over the lug)
%
%   make_workshop_sheets(P, R, 'reports', opts)
%
% opts.n          number of assemblies of each type, [E C1 C2]
% opts.titleblock, opts.tbwidths, opts.subtitle   as in make_plan_sheets.m
% opts.printer    path of joint_pdf.py;  opts.python  Python command
%
% Same JSON format and printer as joint_calculations/make_plan_sheets.m; the
% small block and drawing helpers at the end are copied from there.
% Drawing units mm; u = 0 at the outer face of the embed plate, z = 0 at the
% top of the beam.

  T = types(P);
  B = {};

  % ---- sheet 1: quantities, bars, notes ------------------------------------
  B{end+1} = blk_h(1, 'Conjuntos de anclaje de voladizos IPE 200');
  [rows, kg] = quantities(P, T, opts.n);
  B{end+1} = blk_h(2, 'Cuadro de cantidades');
  B{end+1} = blk_table({'Marca', 'Elemento', 'Descripción', 'E', 'C1', 'C2', 'Total', 'kg c/u', 'kg total'}, ...
      rows, [0.07 0.17 0.36 0.05 0.05 0.05 0.07 0.09 0.09], [4 5 6 7 8 9], []);
  B{end+1} = blk_note(sprintf('Conjuntos: %d E, %d C1, %d C2. Acero total: %.0f kg. Las vigas no están incluidas: se sueldan en obra.', opts.n, kg));
  B{end+1} = blk_h(2, 'Varillas de anclaje (dobladas en frío antes de soldar; medidas exteriores)');
  B{end+1} = blk_row([0.5 0.5], {{blk_draw(bar_shape(P, P.anc.uhA), 62, ...
      sprintf('MARCA V1 - Ø%g, %g x %g mm', P.anc.db, P.anc.uhA - P.pl.t, legv(P)), ...
      sprintf('Tipo E, bajo la platina. Corte aprox. %.0f mm.', cutlen(P, P.anc.uhA)))}, ...
      {blk_draw(bar_shape(P, P.anc.uh), 62, ...
      sprintf('MARCA V2 - Ø%g, %g x %g mm', P.anc.db, P.anc.uh - P.pl.t, legv(P)), ...
      sprintf('Tipos E (sobre la platina), C1 y C2. Corte aprox. %.0f mm.', cutlen(P, P.anc.uh)))}});
  B{end+1} = blk_h(2, 'Notas');
  notes = {
    'Medidas en mm. Placas: acero A36. Varillas: corrugadas soldables, fy = 420 MPa (INEN 2167 / A706). Verificar el certificado.'
    'Soldadura de varillas según AWS D1.4. Precalentar si el certificado lo exige.'
    sprintf('Varilla sobre platina: a cada lado queda una ranura en V curva. Rellenarla a ras. Encima, filete de %g mm y %g mm de largo, a cada lado de cada varilla.', P.w.bar, P.anc.Lw)
    sprintf('Platina superior, placa y extremos de varillas: un solo cordón de %g mm, continuo. Sigue la unión platina-placa y rodea el extremo de cada varilla. Rellenar primero la ranura junto a la placa.', P.w.lug)
    'Varillas cortadas a escuadra. El extremo apoya contra la placa. La varilla apoya sobre (o bajo) la platina.'
    'Secuencia: 1) doblar las varillas. 2) soldar las varillas a la platina superior (nota 3). 3) soldar placa, platina superior y varillas a la vez, con el cordón continuo de la nota 4. 4) soldar la platina inferior.'
    'La platina superior va a la altura del ala superior de la viga (± 3 mm). Marcar con punzón, en la cara exterior de la placa, el eje de la viga y la cara superior del ala.'
    'No pintar. Retirar óxido suelto y grasa.'
    sprintf('En obra: la viga se suelda a la placa. Filete %g alrededor de las alas. Filete %g a ambos lados del alma. Símbolos con bandera.', P.w.flange, P.w.web)};
  for i = 1:numel(notes), B{end+1} = blk_p(sprintf('%d. %s', i, notes{i})); end

  % ---- sheets 2 to 4: one type each ----------------------------------------
  for k = 1:numel(T)
    t = T(k);
    B{end+1} = blk_page();
    B{end+1} = blk_h(1, sprintf('Conjunto tipo %s (%d unidad%s)', t.name, opts.n(k), plural(opts.n(k))));
    B{end+1} = blk_p(t.desc);
    B{end+1} = blk_row([0.64 0.36], {{blk_draw(elev(P, R, t), 118, sprintf('DETALLE %d.1 - TIPO %s, ELEVACIÓN LATERAL', k, t.name), ...
        'Viga en discontinuo: se suelda en obra. Cotas desde la cara exterior de la placa.')}, ...
        {blk_draw(front(P, t), 118, sprintf('DETALLE %d.2 - TIPO %s, VISTA DE LA PLACA', k, t.name), ...
        'Vista desde afuera. En discontinuo: platina y varillas, detrás de la placa. En rojo: soldadura de obra.')}});
    B{end+1} = blk_row([0.5 0.5], {{blk_draw(plan(P, t, 'sup'), 84, sprintf('DETALLE %d.3 - TIPO %s, VISTA DESDE ARRIBA', k, t.name), t.notesup)}, ...
                                   {blk_draw(plan(P, t, 'inf'), 84, sprintf('DETALLE %d.4 - TIPO %s, VISTA DESDE ABAJO', k, t.name), t.noteinf)}});
    B{end+1} = blk_draw(weld_detail(P, t), 62, sprintf('DETALLE %d.5 - SOLDADURAS DE LAS VARILLAS (AMPLIADO)', k), ...
        sprintf(['Izquierda: vista lateral. Derecha: vista contra la placa, con todas las varillas. ' ...
        'La cara cortada de la varilla apoya en la placa; no se suelda. El cordón de %g mm sigue la platina y rodea cada varilla. ' ...
        'Donde la varilla toca la platina no hay soldadura.'], P.w.end));
  end

  sheets = {'Cantidades y notas'};
  for k = 1:numel(T), sheets{end+1} = sprintf('Conjunto tipo %s', T(k).name); end
  doc = struct('title', 'Anclajes de voladizos - taller', 'page', 'A4', 'fs', 0.9, 'blocks', {B}, ...
               'frame', struct('fields', {title_fields(opts)}, 'widths', tb_widths(opts), ...
                               'h', 30, 'subtitle', opts.subtitle, 'sheets', {sheets}));
  base = fullfile(outdir, 'planos_taller_anclajes');
  fid = fopen([base '.json'], 'w');
  if fid < 0, error('Cannot write %s.json', base); end
  fprintf(fid, '%s', jsonencode(doc));
  fclose(fid);
  [st, out] = system(sprintf('%s "%s" "%s.json" "%s.pdf"', opts.python, opts.printer, base, base));
  fprintf('%s', out);
  if st ~= 0, error('PDF generation failed (see the message above).'); end
  file = [base '.pdf'];
end

% =====================================================================
%  Types
% =====================================================================
function T = types(P)
  zA = -(P.bm.tf + P.lug.t)/2 - P.anc.db/2;           % bar axis under the lug
  zB = -(P.bm.tf - P.lug.t)/2 + P.anc.db/2;           % bar axis over the lug
  T(1).name = 'E';   T(1).rows = [zA P.anc.uhA; zB P.anc.uh];
  T(1).desc = sprintf('Columna de borde. 4 varillas Ø%g: 2 V1 bajo la platina superior, 2 V2 sobre ella.', P.anc.db);
  T(1).notesup = 'Arriba: varillas V2. Las V1 están debajo, en la misma línea.';
  T(1).noteinf = 'Vista sin la platina inferior. Abajo: varillas V1.';
  T(2).name = 'C1';  T(2).rows = [zA P.anc.uh];
  T(2).desc = sprintf('Columna de esquina, primera viga. 2 varillas V2 (Ø%g) BAJO la platina superior.', P.anc.db);
  T(2).notesup = 'Varillas debajo de la platina, en discontinuo.';
  T(2).noteinf = 'Vista sin la platina inferior. Varillas bajo la platina.';
  T(3).name = 'C2';  T(3).rows = [zB P.anc.uh];
  T(3).desc = sprintf('Columna de esquina, segunda viga. 2 varillas V2 (Ø%g) SOBRE la platina superior.', P.anc.db);
  T(3).notesup = 'Varillas sobre la platina.';
  T(3).noteinf = 'Vista sin la platina inferior. Varillas encima, en discontinuo.';
end

function s = plural(n)
  if n == 1, s = ''; else, s = 'es'; end
end

% =====================================================================
%  Quantities
% =====================================================================
function [rows, tot] = quantities(P, T, n)
  rho = 7.85e-6;  wb = 0.00158;                       % kg/mm3, kg/mm of a 16 mm bar
  hp = P.pl.zt - P.pl.zb;
  it = {
    'P1', 'Placa embebida', sprintf('PL %gx%gx%g', P.pl.t, P.pl.w, hp), [1 1 1], rho*P.pl.t*P.pl.w*hp
    'P2', 'Platina superior e inferior', sprintf('PL %gx%gx%g (2 por conjunto)', P.lug.t, P.lug.w, P.lug.L), [2 2 2], rho*P.lug.t*P.lug.w*P.lug.L
    'V1', 'Varilla de anclaje', sprintf('Ø%g soldable, %g x %g', P.anc.db, P.anc.uhA - P.pl.t, legv(P)), [2 0 0], wb*cutlen(P, P.anc.uhA)
    'V2', 'Varilla de anclaje', sprintf('Ø%g soldable, %g x %g', P.anc.db, P.anc.uh - P.pl.t, legv(P)), [2 2 2], wb*cutlen(P, P.anc.uh)};
  rows = {};  tot = 0;
  for i = 1:size(it, 1)
    c = it{i,4};  N = sum(c.*n);  kg = it{i,5};
    rows{end+1} = {it{i,1}, it{i,2}, it{i,3}, sprintf('%d', c(1)), sprintf('%d', c(2)), sprintf('%d', c(3)), ...
                   sprintf('%d', N), sprintf('%.2f', kg), sprintf('%.1f', N*kg)};
    tot = tot + N*kg;
  end
  rows{end+1} = {'', 'Soldadura de taller', sprintf('filetes: %g (platina superior y extremos de varillas), %g (platina inferior), %g (varillas sobre platina)', ...
      P.w.lug, P.w.stf, P.w.bar), '', '', '', '', '', ''};
end

function L = legv(P)
  % outside dimension of the vertical leg of an anchor bar (16 d)
  L = P.anc.db/2 + 3.5*P.anc.db + 12*P.anc.db;
end

function L = cutlen(P, uh)
  % cut length of an anchor bar: two straight legs + the 90 degree bend (axis)
  d = P.anc.db;  r = 3.5*d;
  L1 = uh - P.pl.t;                                  % outside, horizontal
  L2 = d/2 + r + 12*d;                               % outside, vertical (= 16 d)
  L = (L1 - r - d/2) + (L2 - r - d/2) + pi/2*r;
  L = 5*ceil(L/5);
end

% =====================================================================
%  Drawings
% =====================================================================
function it = bar_shape(P, uh)
  d = P.anc.db;  L1 = uh - P.pl.t;  L2 = d/2 + 3.5*d + 12*d;
  [x, z] = hook(0, L1, 0, d, -1);
  it = {d_poly(outline(x, z, d), 'tab')};
  it{end+1} = d_dim(0, d/2, L1, d/2, 18, sprintf('%g', L1));
  it{end+1} = d_dim(L1, d/2, L1, d/2 - L2, 18, sprintf('%g', L2));
  it = [it, d_lines(L1/2 - 60, -70, {sprintf('doblez: Ø interior %g (6 db)', 6*d), sprintf('cola 12 db = %g', 12*d)}, 'label', 'start', 0)];
end

function it = elev(P, R, t)
  bm = P.bm;  uL = -230;  zl = -bm.tf/2;  zs = -bm.h + bm.tf/2;  d = P.anc.db;
  it = {};
  % beam, welded on site: outline only
  it{end+1} = d_line(uL, 0, 0, 0, 'hidden');            it{end+1} = d_line(uL, -bm.tf, 0, -bm.tf, 'hidden');
  it{end+1} = d_line(uL, -bm.h, 0, -bm.h, 'hidden');    it{end+1} = d_line(uL, -bm.h+bm.tf, 0, -bm.h+bm.tf, 'hidden');
  it{end+1} = d_line(uL, 15, uL, -bm.h-15, 'cut');
  it = [it, d_lines(-115, -90, {'viga IPE 200', '(en obra)'}, 'small', 'middle', 0)];
  % shop pieces
  it{end+1} = d_rectxy(0, P.pl.zb, P.pl.t, P.pl.zt, 'plate');
  it{end+1} = d_rectxy(P.pl.t, zl - P.lug.t/2, P.pl.t + P.lug.L, zl + P.lug.t/2, 'plate2');
  it{end+1} = d_rectxy(P.pl.t, zs - P.stf.t/2, P.pl.t + P.stf.L, zs + P.stf.t/2, 'plate2');
  for j = 1:size(t.rows, 1)
    [x, z] = hook(P.pl.t, t.rows(j,2), t.rows(j,1), d, -1);
    it{end+1} = d_poly(outline(x, z, d), 'tab');
  end
  % fillets seen from the side (filled red): platinas to plate, bar ends to plate
  x0 = P.pl.t;  w = P.w.lug;  ws = P.w.stf;  we = P.w.end;
  it{end+1} = d_poly([x0 zl+P.lug.t/2; x0+w zl+P.lug.t/2; x0 zl+P.lug.t/2+w], 'weldf5');
  it{end+1} = d_poly([x0 zl-P.lug.t/2; x0+w zl-P.lug.t/2; x0 zl-P.lug.t/2-w], 'weldf5');
  it{end+1} = d_poly([x0 zs+P.stf.t/2; x0+ws zs+P.stf.t/2; x0 zs+P.stf.t/2+ws], 'weldf5');
  it{end+1} = d_poly([x0 zs-P.stf.t/2; x0+ws zs-P.stf.t/2; x0 zs-P.stf.t/2-ws], 'weldf5');
  for j = 1:size(t.rows, 1)
    zc = t.rows(j,1);  sg = sign(zc);               % free side of the bar: away from the platina
    it{end+1} = d_poly([x0 zc+sg*d/2; x0+we zc+sg*d/2; x0 zc+sg*(d/2+we)], 'weldf5');
  end
  % dimensions
  it{end+1} = d_dim(uL, P.pl.zb, uL, -bm.h, 25, '30');
  it{end+1} = d_dim(uL, -bm.h, uL, 0, 25, sprintf('%g', bm.h));
  it{end+1} = d_dim(uL, 0, uL, P.pl.zt, 25, '30');
  it{end+1} = d_dim(uL, P.pl.zb, uL, P.pl.zt, 60, sprintf('%g', P.pl.zt - P.pl.zb));
  it{end+1} = d_dim(0, P.pl.zb, P.pl.t, P.pl.zb, -25, sprintf('%g', P.pl.t), 'before');
  it{end+1} = d_dim(P.pl.t, P.pl.zb, P.pl.t + P.lug.L, P.pl.zb, -25, sprintf('%g', P.lug.L));
  uu = sort(unique(t.rows(:,2)))';
  for j = 1:numel(uu)
    it{end+1} = d_dim(P.pl.t, P.pl.zb, uu(j), P.pl.zb, -25 - 30*j, sprintf('%g', uu(j) - P.pl.t));
  end
  zmin = min(t.rows(:,1)) - 3.5*d - 12*d;
  it{end+1} = d_dim(max(uu), zmin, max(uu), 0, -30, sprintf('%.0f bajo el ala', -zmin));
  it{end+1} = d_line(P.pl.t + P.lug.L, 0, max(uu) + 10, 0, 'center');
  % weld symbols (AWS): shop, and site with the flag
  it{end+1} = d_weld(0, -bm.tf/2, -110, 90, -1, 'both', sprintf('%g', P.w.flange), '', 1, 1, 'alas', 'weld5');
  it{end+1} = d_weld(0, -110, -110, -150, -1, 'both', sprintf('%g', P.w.web), '', 0, 1, 'alma', 'weld5');
  it{end+1} = d_weld(P.pl.t, zl + P.lug.t/2, 40, 150, 1, 'both', sprintf('%g', P.w.lug), '', 0, 0, 'ver nota 4', 'weld5');
  zb = t.rows(1,1);  ys = zb + sign(zb)*d/2;
  it{end+1} = d_weld(P.pl.t + P.lug.L/2, ys, 230, 85, 1, 'both', sprintf('%g', P.w.bar), sprintf('%g', P.anc.Lw), 0, 0, 'ver nota 3', 'weld5');
  it{end+1} = d_weld(P.pl.t, zb + sign(zb)*(d/2 + 2), 230, -40, 1, 'arrow', sprintf('%g', P.w.end), '', 1, 0, 'extremo de varilla', 'weld5');
  it{end+1} = d_weld(P.pl.t + P.stf.L, zs, 110, -175, 1, 'both', sprintf('%g', P.w.stf), '', 0, 0, 'platina inferior', 'weld5');
  it{end+1} = d_text(-4, P.pl.zt + 8, 'cara exterior', 'small', 'end');
  it{end+1} = d_text(P.pl.t + 2, P.pl.zt + 8, sprintf('platina superior PL %gx%gx%g', P.lug.t, P.lug.w, P.lug.L), 'small', 'start');
  it{end+1} = d_text(P.pl.t + P.stf.L + 4, zs - 18, sprintf('platina inferior PL %gx%gx%g', P.stf.t, P.stf.w, P.stf.L), 'small', 'start');
  it{end+1} = d_text(max(uu) + 14, 3, 'nivel sup. del ala', 'small', 'start');
end

function it = plan(P, t, side)
  % side 'sup': seen from above; 'inf': seen from below, without the bottom platina
  bm = P.bm;  uL = -150;  d = P.anc.db;  v = P.anc.v;  x0 = P.pl.t;  x1 = P.pl.t + P.lug.L;
  if strcmp(side, 'sup'), sv = 1; else, sv = -1; end
  near = t.rows(sign(t.rows(:,1)) == sv, :);        % bars on the side we look at
  far  = t.rows(sign(t.rows(:,1)) ~= sv, :);
  it = {};
  it{end+1} = d_line(uL, -bm.b/2, 0, -bm.b/2, 'hidden');
  it{end+1} = d_line(uL,  bm.b/2, 0,  bm.b/2, 'hidden');
  it{end+1} = d_line(uL, 0, 0, 0, 'center');
  % far bars: seen only beyond the platina (and beyond the near bars)
  for j = 1:size(far, 1)
    for vv = v
      u0 = x1;
      if ~isempty(near), u0 = max(near(:,2)); end
      if far(j,2) > u0
        it{end+1} = d_poly([u0 vv-d/2; far(j,2) vv-d/2; far(j,2) vv+d/2; u0 vv+d/2], 'tab');
      end
      it{end+1} = d_circle(far(j,2) - d/2, vv, d/2, 'bolt');
    end
  end
  it{end+1} = d_rectxy(x0, -P.lug.w/2, x1, P.lug.w/2, 'plate2');
  if isempty(near) && ~isempty(far)
    for vv = v
      it{end+1} = d_line(x0, vv - d/2, x1, vv - d/2, 'hidden');
      it{end+1} = d_line(x0, vv + d/2, x1, vv + d/2, 'hidden');
    end
  end
  % near bars with their welds
  for j = 1:size(near, 1)
    for vv = v
      it{end+1} = d_poly([x0 vv-d/2; near(j,2) vv-d/2; near(j,2) vv+d/2; x0 vv+d/2], 'tab');
      it{end+1} = d_circle(near(j,2) - d/2, vv, d/2, 'bolt');
      for sg = [-1 1]
        it{end+1} = d_line(x1 - P.anc.Lw, vv + sg*(d/2 + 1.5), x1, vv + sg*(d/2 + 1.5), 'weld5');
      end
      we = P.w.end;
      it{end+1} = d_poly([x0 vv-d/2-we; x0 vv+d/2+we; x0+we vv+d/2; x0+we vv-d/2], 'weldf5');
    end
  end
  % platina to plate on this face, stopped around the bars that sit on it
  it{end+1} = d_line(x0 + 2.5, -P.lug.w/2, x0 + 2.5, P.lug.w/2, 'weld5');   % one bead, it wraps the bar ends
  it{end+1} = d_rectxy(0, -P.pl.w/2, P.pl.t, P.pl.w/2, 'plate');
  uh = max(t.rows(:,2));
  it{end+1} = d_dim(x1, v(1), x1, v(2), -uh + x1 - 25, sprintf('%g', diff(v)));
  it{end+1} = d_dim(x1, 0, x1, v(2), -uh + x1 - 55, sprintf('%g', v(2)));
  it{end+1} = d_dim(0, -P.lug.w/2, 0, P.lug.w/2, 30, sprintf('%g', P.lug.w));
  it{end+1} = d_dim(0, -P.pl.w/2, 0, P.pl.w/2, 60, sprintf('%g', P.pl.w));
  if ~isempty(near) && size(near, 1) == 1
    it{end+1} = d_weld(x0, v(2) + d/2 + P.w.end, 70, P.pl.w/2 + 10, 1, 'arrow', sprintf('%g', P.w.end), '', 1, 0, 'extremo de varilla', 'weld5');
  end
  it{end+1} = d_text(-75, -bm.b/2 - 14, 'viga (en obra)', 'small', 'middle');
end

function it = front(P, t)
  bm = P.bm;  d = P.anc.db;  v = P.anc.v;
  it = {};
  it{end+1} = d_rectxy(-P.pl.w/2, P.pl.zb, P.pl.w/2, P.pl.zt, 'plate');
  S = [-bm.b/2 0; bm.b/2 0; bm.b/2 -bm.tf; bm.tw/2 -bm.tf; bm.tw/2 -bm.h+bm.tf; bm.b/2 -bm.h+bm.tf; ...
       bm.b/2 -bm.h; -bm.b/2 -bm.h; -bm.b/2 -bm.h+bm.tf; -bm.tw/2 -bm.h+bm.tf; -bm.tw/2 -bm.tf; -bm.b/2 -bm.tf];
  for i = 1:size(S,1)
    j = mod(i, size(S,1)) + 1;
    it{end+1} = d_line(S(i,1), S(i,2), S(j,1), S(j,2), 'weld5');
  end
  % punch marks for the site: beam axis and top of the flange
  it{end+1} = d_line(0, P.pl.zt, 0, P.pl.zt - 12, 'beamline');
  it{end+1} = d_line(0, P.pl.zb, 0, P.pl.zb + 12, 'beamline');
  it{end+1} = d_line(-P.pl.w/2, 0, -P.pl.w/2 + 12, 0, 'beamline');
  it{end+1} = d_line(P.pl.w/2, 0, P.pl.w/2 - 12, 0, 'beamline');
  zl = -bm.tf/2;
  it{end+1} = d_line(-P.lug.w/2, zl - P.lug.t/2, P.lug.w/2, zl - P.lug.t/2, 'hidden');
  it{end+1} = d_line(-P.lug.w/2, zl + P.lug.t/2, P.lug.w/2, zl + P.lug.t/2, 'hidden');
  for j = 1:size(t.rows, 1)
    for vv = v, it{end+1} = d_circle(vv, t.rows(j,1), d/2, 'hidden'); end
  end
  it{end+1} = d_dim(-P.pl.w/2, P.pl.zt, P.pl.w/2, P.pl.zt, 20, sprintf('%g', P.pl.w));
  it{end+1} = d_dim(-bm.b/2, P.pl.zb, bm.b/2, P.pl.zb, -18, sprintf('%g', bm.b));
  it{end+1} = d_dim(-P.pl.w/2, P.pl.zb, -bm.b/2, P.pl.zb, -18, sprintf('%g', (P.pl.w - bm.b)/2), 'before');
  it{end+1} = d_dim(P.pl.w/2, P.pl.zb, P.pl.w/2, P.pl.zt, -20, sprintf('%g', P.pl.zt - P.pl.zb));
  it{end+1} = d_dim(-P.pl.w/2, -bm.h, -P.pl.w/2, 0, 20, sprintf('%g', bm.h));
  it{end+1} = d_dim(-P.pl.w/2, 0, -P.pl.w/2, P.pl.zt, 20, '30');
  it{end+1} = d_text(0, P.pl.zb + 12, 'marcas de punzón: eje y ala superior', 'small', 'middle');
end

function it = weld_detail(P, t)
  % enlarged welds: side view (left) and view against the plate with all the bars (right)
  d = P.anc.db;  r = d/2;  we = P.w.end;  tl = P.lug.t;  wl = P.w.lug;  v = P.anc.v;
  zl = -P.bm.tf/2;  zt = zl + tl/2;  zb = zl - tl/2;  zr = t.rows(:,1)';
  it = {};
  % ---- side view: plate on the left, u to the right
  it{end+1} = d_rectxy(-P.pl.t, zl - 45, 0, zl + 45, 'plate');
  it{end+1} = d_rectxy(0, zb, P.lug.L, zt, 'plate2');
  for z = zr
    sg = sign(z);
    it{end+1} = d_rectxy(0, z - r, 90, z + r, 'tab');
    it{end+1} = d_line(90, z - r - 3, 90, z + r + 3, 'cut');
    it{end+1} = d_poly([0 z+sg*r; we z+sg*r; 0 z+sg*(r+we)], 'weldf5');               % around the bar end
    it{end+1} = d_line(P.lug.L - P.anc.Lw, z - sg*(r + 1.2), P.lug.L, z - sg*(r + 1.2), 'weld5');   % along the platina
  end
  for f = [1 -1]                                      % platina faces without bars: bead along the platina
    if ~any(sign(zr) == f)
      zf = zl + f*tl/2;
      it{end+1} = d_poly([0 zf; wl zf; 0 zf + f*wl], 'weldf5');
    end
  end
  z1 = zr(1);  s1 = sign(z1);
  it{end+1} = d_dim(0, z1 + s1*(r+we), we, z1 + s1*(r+we), s1*8, sprintf('%g', we));
  it{end+1} = d_dim(P.lug.L - P.anc.Lw, zb - (z1 < 0)*0, P.lug.L, zb, -(12 + 18*any(zr < 0)), sprintf('%g', P.anc.Lw));
  it{end+1} = d_text(-P.pl.t - 4, zl + 40, 'placa', 'small', 'end');
  it{end+1} = d_text(P.lug.L + 4, zl, 'platina', 'small', 'start');
  % AWS symbol: bar to platina, both sides of each bar
  zw = z1 - s1*(r + 1.2);
  it{end+1} = d_weld(P.lug.L - 10, zw, -30, zl + 62, -1, 'both', sprintf('%g', P.w.bar), sprintf('%g', P.anc.Lw), 0, 0, 'cada varilla, nota 3', 'weld5');
  % ---- view against the plate: the whole platina and all the bars
  X = 200;
  it{end+1} = d_rectxy(X - 80, zl - 50, X + 80, zl + 50, 'plate');
  for f = [1 -1]                                      % bead along both faces of the platina
    zf = zl + f*tl/2;
    cuts = [-P.lug.w/2 P.lug.w/2];
    if any(sign(zr) == f), cuts = reshape([-P.lug.w/2, reshape([v - r; v + r], 1, []), P.lug.w/2], 2, [])'; end
    for i = 1:size(cuts, 1)
      it{end+1} = d_poly([X+cuts(i,1) zf; X+cuts(i,2) zf; X+cuts(i,2) zf+f*wl; X+cuts(i,1) zf+f*wl], 'weldf5');
    end
  end
  % bead around each bar: drawn as a full ring under the platina and the bar, so it
  % shows only on the plate and fills the small grooves next to the platina
  for z = zr
    a = linspace(0, 2*pi, 60);
    for vv = v
      ring = [X + vv + (r+we)*cos(a'), z + (r+we)*sin(a'); flipud([X + vv + r*cos(a'), z + r*sin(a')])];
      it{end+1} = d_poly(ring, 'weldf5');
    end
  end
  it{end+1} = d_rectxy(X - P.lug.w/2, zb, X + P.lug.w/2, zt, 'white');      % opaque backing
  it{end+1} = d_rectxy(X - P.lug.w/2, zb, X + P.lug.w/2, zt, 'plate2');
  for z = zr
    for vv = v, it{end+1} = d_circle(X + vv, z, r, 'tab'); end
  end
  it{end+1} = d_dim(X + v(1), zl + 50, X + v(2), zl + 50, 8, sprintf('%g', diff(v)));
  it{end+1} = d_dim(X - P.lug.w/2, zl - 50, X + P.lug.w/2, zl - 50, -8, sprintf('%g (platina)', P.lug.w));
end

% =====================================================================
%  Geometry
% =====================================================================
function [x, z] = hook(x0, xo, z0, d, dn)
  % axis of a bar from x0 to a 90 degree hook with its outside face at xo;
  % inside bend diameter 6 d, tail 12 d, downwards (dn = -1)
  sg = sign(xo - x0);  r = 3.5*d;  t = linspace(0, pi/2, 10);
  xb = xo - sg*(d/2 + r);
  x = [x0, xb + sg*r*sin(t), xo - sg*d/2];
  z = [z0, z0 + dn*r*(1 - cos(t)), z0 + dn*(r + 12*d)];
end

function Q = outline(x, z, d)
  % closed outline of a bar of diameter d along the polyline (x, z)
  x = x(:);  z = z(:);  n = numel(x);  N = zeros(n, 2);
  for i = 1:n
    a = max(i-1, 1);  b = min(i+1, n);
    t = [x(b)-x(a), z(b)-z(a)];  t = t/norm(t);
    N(i,:) = [-t(2) t(1)];
  end
  Q = [[x z] + d/2*N; flipud([x z] - d/2*N)];
end

% =====================================================================
%  Title block (as in make_plan_sheets.m)
% =====================================================================
function F = title_fields(opts)
  T = opts.titleblock;
  F = cell(1, size(T, 1));
  for i = 1:size(T, 1), F{i} = {T{i,1}, strrep(T{i,2}, '\n', char(10))}; end
end

function w = tb_widths(opts)
  if isfield(opts, 'tbwidths') && ~isempty(opts.tbwidths)
    w = opts.tbwidths / sum(opts.tbwidths);
  else
    w = ones(1, size(opts.titleblock, 1)) / size(opts.titleblock, 1);
  end
end

% ---------------------------------------------------------------------
%  drawing items and blocks (copied from make_plan_sheets.m, see joint_pdf.py)
% ---------------------------------------------------------------------
function it = d_weld(xt, yt, xe, ye, dr, side, sz, len, all, field, tail, s)
  it = struct('t', 'weld', 'p', [xt yt xe ye], 'dir', dr, 'side', side, 'size', sz, ...
              'len', len, 'all', all, 'field', field, 'tail', tail, 's', s);
end

function it = d_poly(P, s)
  it = struct('t', 'poly', 'p', reshape(P.', 1, []), 's', s);
end

function it = d_rectxy(x0, y0, x1, y1, s)
  it = d_poly([x0 y0; x1 y0; x1 y1; x0 y1], s);
end

function it = d_line(x0, y0, x1, y1, s)
  it = struct('t', 'line', 'p', [x0 y0 x1 y1], 's', s);
end

function it = d_circle(x, y, r, s)
  it = struct('t', 'circle', 'p', [x y r], 's', s);
end

function it = d_lines(x, y, lines, s, a, dy)
  it = {d_text(x, y, strjoin(lines, sprintf('\n')), s, a)};
end

function it = d_text(x, y, txt, s, a)
  it = struct('t', 'text', 'p', [x y], 'txt', txt, 's', s, 'a', a);
end

function it = d_dim(x0, y0, x1, y1, off, txt, pos)
  if nargin < 7, pos = 'after'; end
  it = struct('t', 'dim', 'p', [x0 y0 x1 y1], 'o', off, 'txt', txt, 'pos', pos);
end

function b = blk_draw(items, h, cap, note)
  b = struct('k', 'drawing', 'items', {items}, 'h', h, 'cap', cap, 'note', note);
end

function b = blk_row(w, cols)
  b = struct('k', 'row', 'w', w, 'cols', {cols});
end

function b = blk_h(level, text)
  b = struct('k', sprintf('h%d', level), 't', text);
end

function b = blk_p(text)
  b = struct('k', 'p', 't', text);
end

function b = blk_note(text)
  b = struct('k', 'note', 't', text);
end

function b = blk_page()
  b = struct('k', 'page');
end

function b = blk_table(head, rows, widths, right, red)
  b = struct('k', 'table', 'head', {head}, 'rows', {rows}, 'w', widths, ...
             'right', {right}, 'red', {red});
end
