function file = make_crack_sheet(P, R, outdir, opts)
% MAKE_CRACK_SHEET  One A4 sheet (Spanish) for the architect: the cracks expected under service
%   loads at the cantilever joints, where they run, which stay hidden and which may show on the
%   floor. Same printer (pour_pdf.py) and title block as the placement sheets. Units mm.
%   Geometry from P and R: anchors, back plate, breakout slope (1.5 across : 1 along the anchor,
%   apex at the bearing face of B1, as in ca_calc), beam bars, slab.

  an = P.an;  bp = P.bp;  Y = R.typ(1);
  Tsv = Y.T*(P.etabs.MD + P.etabs.ML)/(Y.Mu/1e6);           % service pull at E
  fs = Tsv/(R.cone(1).k*pi*P.cb.db^2/4);                       % service stress in the beam bars
  B = {};
  B{end+1} = blk_h(1, 'Fisuras esperadas en servicio: uniones de los voladizos');
  B{end+1} = blk_p(['Con las cargas de servicio (peso propio y carga viva) se esperan fisuras finas en los nudos de los voladizos. ' ...
      'Son parte del comportamiento previsto del hormigón armado: el diseño las considera y las barras de acero las controlan. ' ...
      'La mayoría quedan ocultas bajo la placa base de la columna metálica y bajo la losa.']);
  B{end+1} = blk_draw(dr_section(P, R), 118, 'CORTE POR EL EJE DE UN VOLADIZO (C4, B4, D3 Y D4)', ...
      'Rojo: fisuras esperadas. Línea punteada roja: la fisura sigue dentro del hormigón, sin llegar a la superficie.');
  B{end+1} = blk_row([0.55 0.45], {{blk_draw(dr_plan(P), 82, 'PLANTA: DÓNDE PUEDEN APARECER', ...
      'Círculos: fisuras ocultas en la parte superior de las columnas. Franjas: posibles fisuras en el piso.')}, ...
      {blk_h(2, 'Fisuras'), ...
       blk_p('**1.** Desde la placa de anclaje hasta la cara superior de la columna. Oculta bajo el grout y la placa base de la columna metálica.'), ...
       blk_p('**2.** Junta entre el grout y la columna, en la parte superior de la placa extremo del voladizo. Capilar; queda dentro de la losa.'), ...
       blk_p('**3.** Fisuras verticales en la parte superior de la viga de hormigón, junto a la columna. Normales en vigas continuas; quedan bajo la losa.'), ...
       blk_p('**4.** Posibles fisuras en la superficie de la losa, sobre los ejes 4 y D, junto a los voladizos. Dependen del refuerzo superior de la losa.')}});
  B{end+1} = blk_h(2, 'Notas para arquitectura');
  notes = {
    sprintf('Ancho esperado de la fisura 1: capilar, del orden de 0.1 a 0.2 mm (acero de las vigas a unos %.0f MPa en servicio).', fs)
    'Las fisuras 1, 2 y 3 no se verán: no requieren tratamiento.'
    'Fisura 4: en la franja sobre los ejes 4 y D junto a los voladizos, evitar acabados rígidos continuos sin juntas (microcemento, resinas). Preferir un acabado con juntas, o una junta de control sobre el eje.'
    'Avisar al ingeniero si aparece una fisura de más de 0.3 mm de ancho, o una fisura que crece con el tiempo.'};
  for i = 1:numel(notes), B{end+1} = blk_p(sprintf('%d. %s', i, notes{i})); end

  doc = struct('title', 'Fisuras esperadas - voladizos', 'page', 'A4', 'fs', 0.9, 'blocks', {B}, ...
               'frame', struct('fields', {title_fields(opts)}, 'widths', tb_widths(opts), ...
                               'h', 30, 'subtitle', opts.subtitle, 'sheets', {{'Fisuras esperadas'}}));
  base = fullfile(outdir, 'fisuras_esperadas_voladizos');
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
%  Drawings. Section: u from the cantilever face of the column (cantilever side u < 0), z from
%  the top of the concrete beams. Plan: grids as in make_pour_sheets.m.
% =====================================================================
function it = d_crack(Q, s, seed)
  % a crack along the polyline Q (N x 2), with a small zigzag
  it = {};  amp = 4;  k = 0;
  for i = 1:size(Q, 1) - 1
    a = Q(i,:);  b = Q(i+1,:);  L = norm(b - a);  n = max(2, round(L/12));
    t = (0:n)'/n;  p = a + t.*(b - a);
    nv = [-(b(2) - a(2)), b(1) - a(1)]/L;
    off = amp*sin(seed + (1:n+1)'*2.3).*(t > 0 & t < 1);
    p = p + off.*nv;
    for j = 1:n, k = k + 1;  it{end+1} = d_line(p(j,1), p(j,2), p(j+1,1), p(j+1,2), s); end
  end
end

function it = dr_section(P, R)
  an = P.an;  bp = P.bp;  Y = R.typ(1);  b = P.col.b;  cj = P.col.cj;  top = P.col.top;  st = P.slab.t;
  zA = Y.zT;  zt = P.cb.zt(2);  k = 1.5;  L = 700;  xR = b + 520;  it = {};
  % concrete: column, beam in line, slab on both sides (cast later), steel column on top
  it{end+1} = d_rectxy(0, cj, b, top, 'r_conc');
  it{end+1} = d_rectxy(b, -P.cb.h, xR, 0, 'r_conc');
  it{end+1} = d_rectxy(b, 0, xR, st, 'r_concb');
  it{end+1} = d_rectxy(-L, 0, 0, st, 'r_concb');
  it{end+1} = d_rectxy(60, top, b - 60, top + 25, 'r_old');                                 % grout
  it{end+1} = d_rectxy(40, top + 25, b - 40, top + 50, 'plate');                            % base plate
  it{end+1} = d_rectxy(b/2 - 75, top + 50, b/2 + 75, top + 260, 'r_steel');                 % steel column
  % cantilever: IPE 240, end plate, grout pad
  x0 = -P.g - P.ep.t;  tw = P.bm.tw;  tf = P.bm.tf;  h = P.bm.h;
  it{end+1} = d_rectxy(-L, -tf, x0, 0, 'plate');
  it{end+1} = d_rectxy(-L, -h, x0, -h + tf, 'plate');
  it{end+1} = d_rectxy(-L, -h + tf, x0, -tf, 'r_steel');
  it{end+1} = d_rectxy(x0, R.typ(1).ep_bot, -P.g, R.typ(1).ep_top, 'plate');
  it{end+1} = d_rectxy(-P.g, R.typ(1).ep_bot - 10, 0, R.typ(1).ep_top + 10, 'r_old');
  % anchors and beam bars, faint
  it{end+1} = d_bar(-an.out, zA, an.uT, zA, an.db, 'r_ancg');
  it{end+1} = d_rectxy(bp.u, zA - bp.h/2, bp.u + bp.t, zA + bp.h/2, 'r_ancg');
  it{end+1} = d_bar(xR, zt, P.cb.uh + 6, zt, P.cb.db, 'r_ex');
  it{end+1} = d_bar(P.cb.uh + 6, zt, P.cb.uh + 6, zt - 186, P.cb.db, 'r_ex');
  % cracks
  % crack 1 leaves the edges of the plate at the ACI slope, 1.5 across : 1 along the anchor
  zt1 = zA + bp.h/2;  zb1 = zA - bp.h/2;  zbar = zt + P.cb.db/2;
  uT = bp.u - (top - zt1)/k;  uB = bp.u - (zb1 - zbar)/k;
  it = [it, d_crack([bp.u, zt1; uT, top], 'weld5', 1)];                                       % 1
  it = [it, d_crack([bp.u, zb1; uB, zbar], 'r_crkh', 2)];                                     % 1, inside
  it = [it, d_crack([0, R.typ(1).ep_top + 10; 0, zA - 20], 'weld5', 3)];                     % 2
  for u = b + [25 165 305], it = [it, d_crack([u, 0; u + 6, -90], 'weld5', u)]; end          % 3
  for u = [-60 -10], it = [it, d_crack([u, st; u - 4, st - 55], 'weld5', u + 7)]; end        % 4
  for u = b + [20 160], it = [it, d_crack([u, st; u + 4, st - 55], 'weld5', u + 9)]; end
  % labels
  it{end+1} = d_text(uT + 6, top + 8, '1', 'red', 'start');
  it{end+1} = d_text(uB - 18, zt - 6, '1', 'red', 'end');
  it{end+1} = d_text(-12, zA - 10, '2', 'red', 'end');
  it{end+1} = d_text(b + 30, -110, '3', 'red', 'start');
  it{end+1} = d_text(-36, st + 12, '4', 'red', 'middle');
  it{end+1} = d_text(b + 160, st + 12, '4', 'red', 'middle');
  it{end+1} = d_text(-L + 10, st/2 - 4, 'losa del voladizo', 'small', 'start');
  it{end+1} = d_text(xR - 10, st/2 - 4, 'losa', 'small', 'end');
  it{end+1} = d_text(-L + 10, -h/2, 'viga metálica IPE 240', 'small', 'start');
  it{end+1} = d_text(b + 260, -175, 'viga de hormigón', 'small', 'middle');
  it{end+1} = d_text(b/2, -200, 'columna', 'small', 'middle');
  it{end+1} = d_text(b/2, top + 150, 'columna metálica', 'small', 'middle');
  it{end+1} = d_text(b - 30, top + 70, 'placa base y grout', 'small', 'start');
  it{end+1} = d_text(-P.g - 20, R.typ(1).ep_top + 40, 'placa extremo', 'small', 'end');
  it{end+1} = d_text(bp.u - 40, zA - 40, 'placa de anclaje', 'small', 'end');
  it{end+1} = d_text(xR, zt - 14, 'barras de la viga', 'small', 'end');
end

function it = d_bar(x0, y0, x1, y1, d, s)
  % straight bar of diameter d between two axis points
  L = hypot(x1 - x0, y1 - y0);  nx = -(y1 - y0)/L*d/2;  ny = (x1 - x0)/L*d/2;
  it = d_poly([x0+nx y0+ny; x1+nx y1+ny; x1-nx y1-ny; x0-nx y0-ny], s);
end

function it = dr_plan(P)
  % the cantilever corner of the plan: grids B..E and 3..9 (spacings as in make_pour_sheets.m)
  xg = [0 4780 9560 10830];  xn = {'B', 'C', 'D', 'E'};  yg = [-1270 0 4330];  yn = {'9', '4', '3'};
  c = P.col.b/2;  it = {};
  for i = 1:4, it{end+1} = d_line(xg(i), -1900, xg(i), 5000, 'axis'); it{end+1} = d_text(xg(i), -2300, xn{i}, 'grid', 'middle'); end
  for j = 1:3, it{end+1} = d_line(-900, yg(j), 11600, yg(j), 'axis'); it{end+1} = d_text(12000, yg(j) - 90, yn{j}, 'grid', 'middle'); end
  for x = xg(1:3), it{end+1} = d_rectxy(x - 150, 0 - 150, x + 150, 4330 + 150, 'r_concb'); end
  it{end+1} = d_rectxy(-150, -150, 9710, 150, 'r_concb');
  it{end+1} = d_rectxy(-150, 4180, 9710, 4480, 'r_concb');
  for x = xg(1:3), it{end+1} = d_rectxy(x - 60, -1270, x + 60, -c, 'plate'); end
  for y = [0 4330], it{end+1} = d_rectxy(9560 + c, y - 60, 10830, y + 60, 'plate'); end
  it{end+1} = d_poly([-150 -1270; 10830 -1270; 10830 4330; 10829 4330; 10829 -1269; -150 -1269], 'edge');
  % floor cracks (4): bands over grid 4 and grid D next to the cantilevers
  it{end+1} = d_rectxy(-300, -260, 9560 + 260, 260, 'clash');
  it{end+1} = d_rectxy(9560 - 260, -260, 9560 + 260, 4330 + 260, 'clash');
  % hidden cracks (1): column tops
  for p = [0 0; 4780 0; 9560 0; 9560 4330]', it{end+1} = d_circle(p(1), p(2), 420, 'clash'); end
  for p = [0 0; 4780 0; 9560 0; 9560 4330]', it{end+1} = d_rectxy(p(1) - c, p(2) - c, p(1) + c, p(2) + c, 'r_conc'); end
  it{end+1} = d_text(4780/2, 420, '4: posibles fisuras en el piso', 'red', 'middle');
  it{end+1} = d_text(9560 + 420, 2165, '4', 'red', 'start');
  it{end+1} = d_text(4780 + 480, -520, '1 (oculta)', 'red', 'start');
  it{end+1} = d_text(4780, -1500, 'voladizos IPE 240', 'small', 'middle');
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
%  drawing items and blocks (copied from ../cantilever_anchor/make_workshop_sheets.m, see joint_pdf.py)
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
