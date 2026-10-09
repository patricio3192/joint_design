function file = make_concrete_sheet(outdir, opts)
% MAKE_CONCRETE_SHEET  A1 sheet (Spanish) of the steel-beam connections. Units mm.
%   Column 1: location plan + beam sections. Column 2: end plate on concrete
%   column (C4) and sandwich connection. Column 3: pieces, quantities, notes.
% Transparent: what is placed after the pour (end plates, IPE, grout, outer
% nuts). Solid: everything placed before the pour.
% Drawing items (d_*), components (c_*) and blocks (blk_*): lib/sheets.
  lib = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'lib');
  addpath(fullfile(lib, 'sheets'), fullfile(lib, 'profiles'));   % d_*, blk_*, c_* components; steel_profile
  P = params();
  c1 = {};  c2 = {};  c3 = {};

  % ---- column 1: location plan and sections -------------------------------------------
  c1{end+1} = blk_h(1, 'Conexiones de vigas de acero a vigas y columnas de hormigón');
  c1{end+1} = blk_h(2, '1. Planta de ubicación');
  c1{end+1} = blk_draw(dr_keyplan(P), 330, 'PLANTA DE UBICACIÓN', ...
      ['**Rojo: unión placa extremo-columna** (B4, C4, D4X, D4Y, D3), con 2 bastones Ø12 (naranja) en la viga en línea; ' ...
       'punto naranja: pata hacia abajo. **Círculos: conexión sándwich (10)**, con los 2 anclajes que atraviesan la viga. ' ...
       'Viga D entre 3 y 4: estribos Ø10 cada 110 / 140 / 110. Ejes 4 (B-C y C-D): **VCS+1Ø12**, varilla extra abajo (celeste).']);
  c1{end+1} = blk_row([1 1 1]/3, { ...
      {blk_draw(dr_beamsec(P, 'vcs1'), 95, 'CORTE A-A: VCS+1Ø12 (EJE 4)', ...
         '3Ø12 arriba, 4Ø12 abajo (1-2-1). **Varilla extra Ø12, L = 1500, centrada en el cruce con la IPE 200 (ejes F y G).**')}, ...
      {blk_draw(dr_beamsec(P, 'vcm'), 95, 'CORTE B-B: VCM CON BASTONES', ...
         'B4, C4, D4Y. VCM 5Ø12 + 5Ø12 (pares en las esquinas). **Bastones Ø12 junto al par de esquina, a 80 de arriba.**')}, ...
      {blk_draw(dr_beamsec(P, 'vcs'), 95, 'CORTE C-C: VCS CON BASTONES', ...
         'D4X y D3. VCS 3Ø12 + 3Ø12. **Bastones Ø12 contra el estribo, debajo de las esquinas, a 80 de arriba (en D4X: a 98).**')}});

  % ---- column 2: C4 and sandwich ---------------------------------------------------------
  c2{end+1} = blk_h(2, '2. Unión placa extremo - columna (C4; igual en B4, D4X, D4Y, D3)');
  c2{end+1} = blk_draw(dr_c4_elev(P), 150, 'DETALLE 2.1 - C4: CORTE POR EL EJE DEL VOLADIZO', ...
      ['Anclajes A1 (rojo) con placa de cabeza P1 dentro de la jaula de estribos. Bastones Ø12 (naranja) con pata de 200 hacia abajo. ' ...
       'Estribos del nudo Ø10 (morado) en 4 niveles; 2 estribos Ø14 (verde) en la cabeza de la columna. Transparente: va después.']);
  c2{end+1} = blk_row([0.5 0.5], { ...
      {blk_draw(dr_c4_front(P), 135, 'DETALLE 2.2 - C4: VISTA DESDE EL VOLADIZO', ...
         'Placa P2 140x260x12 sobre grout de 25. **En D4X los A1 van a 62 y 173** (cruzan debajo de los de D4Y).')}, ...
      {blk_draw(dr_c4_plan(P), 135, 'DETALLE 2.3 - C4: PLANTA A LA ALTURA DE LOS A1', ...
         'Bastones a ±82 del eje, junto a las barras de esquina de la VCM. Tramo recto 1220 desde la cara exterior de la pata.')}});
  c2{end+1} = blk_draw(dr_d4_front(P), 108, 'DETALLE 2.4 - D4: VISTA DESDE EL SUR', ...
      ['Dos voladizos. **A1 de D4X a 62 y 173, debajo de los de D4Y; bastones de D4X a 98, hacia el oeste por la VCS del eje 4.** ' ...
       'D4Y igual a C4. Correr los estribos del nudo lo necesario.']);
  c2{end+1} = blk_h(2, '3. Conexión sándwich (A, B, C, D en 10 y 11; F4, G4)');
  c2{end+1} = blk_row([0.5 0.5], { ...
      {blk_draw(dr_sw_front(P), 95, 'DETALLE 3.1 - SÁNDWICH: VISTA LATERAL DE LA VIGA', ...
         'Placa P3 140x220x12 sobre grout de 25 a cada lado (después). **Un estribo a cada lado de los anclajes**, los demás cada 110 desde ellos.')}, ...
      {blk_draw(dr_sw_plan(P), 95, 'DETALLE 3.2 - SÁNDWICH: PLANTA POR LOS ANCLAJES', ...
         'Anclajes A2 pasantes, L = 440, entre estribos. Grout 25, placas, tuercas e IPE 200: después.')}});

  % ---- column 3: pieces, quantities, notes ------------------------------------------------------
  c3{end+1} = blk_h(2, '4. Piezas, cantidades y notas');
  c3{end+1} = blk_row([1 1 1]/3, { ...
      {blk_draw(dr_tie(P, 14), 60, 'DETALLE 4.1 - ESTRIBO Ø14', ...
         'Cabeza de la columna (105 sobre las vigas): 2 por columna, juntos, a 63 de la cara superior de la columna.')}, ...
      {blk_draw(dr_tie(P, 10), 60, 'DETALLE 4.2 - ESTRIBO DEL NUDO Ø10', ...
         '4 niveles: 110, 155, 230 y 305 bajo la cara superior de las vigas (cada 75 o menos).')}, ...
      {blk_draw(dr_tie4(P), 60, 'DETALLE 4.3 - OPCIÓN: Ø10 EN 4 PIEZAS', ...
         '4 piezas rectas con ganchos de 135° a las barras de esquina, una por cara.')}});
  c3{end+1} = blk_row([0.5 0.5], { ...
      {blk_draw(dr_rod(P, 1), 45, 'DETALLE 4.4 - ANCLAJE A1 (COLUMNAS)', ...
         'Desde la cara de la columna. Placa de cabeza P1, arandela y tuerca: antes. Tuercas de nivelación y exterior: después.')}, ...
      {blk_draw(dr_rod(P, 2), 45, 'DETALLE 4.5 - ANCLAJE A2 (SÁNDWICH)', ...
         'Pasante. Grout 25, placas P3, tuercas de nivelación y exteriores: después.')}});
  c3{end+1} = blk_row([0.25 0.375 0.375], { ...
      {blk_draw(dr_plates(P, 1), 55, 'P1 - PL 50x50x12', 'Agujero Ø18.')}, ...
      {blk_draw(dr_plates(P, 2), 55, 'P2 - PL 140x260x12 A36', 'Columnas. 4 agujeros Ø18.')}, ...
      {blk_draw(dr_plates(P, 3), 55, 'P3 - PL 140x220x12 A36', 'Sándwich. 4 agujeros Ø18.')}});
  c3{end+1} = blk_h(3, '**Cantidades (solo lo que se añade)**');
  c3{end+1} = blk_table({'Marca', 'Elemento', 'Descripción', 'Por conexión', 'Total'}, quantities(P), ...
                        [0.08 0.17 0.53 0.12 0.10], [4 5], []);
  c3{end+1} = blk_h(3, '**Notas**');
  N = notes(P);
  for i = 1:numel(N), c3{end+1} = blk_note(sprintf('%d. %s', i, N{i})); end

  B = {blk_row([0.38 0.35 0.27], {c1, c2, c3})};
  doc = struct('title', 'Conexiones de vigas de acero', 'page', opts.page, 'fs', opts.fs, 'blocks', {B}, ...
               'frame', struct('fields', {title_fields(opts)}, 'widths', opts.tbwidths/sum(opts.tbwidths), ...
                               'h', opts.tbh, 'tb', opts.tbk, 'subtitle', opts.subtitle, 'sheets', {{opts.sheetname}}));
  base = fullfile(outdir, 'planos_conexiones');
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
%  Data (from end_plate_column.m and sandwiched_connection.m)
% =====================================================================
function P = params()
  P.col = struct('b', 400, 'db', 16, 'rc', 58, 'top', 105);        % 40x40, bars 58 from the faces
  P.xc  = P.col.b/2 - P.col.rc;                                     % 142
  P.bm  = struct('b', 300, 'h', 350, 'rc', 56, 'db', 12);           % beams 30x35
  P.ipe = steel_profile('IPE 240');
  P.ip2 = steel_profile('IPE 200');
  % end plate on column
  P.ep = struct('t', 12, 'b', 140, 'H', 260, 'g', 80, 'yT', 42, 'yS', 198, 'gr', 25);
  P.rod = struct('d', 16, 'tip', 345, 'L1', 440, 'L2', 440, 'nut', 16, 'wsh', 3, 'dw', 30, 'nw', 24, 'hole', 18);
  P.hd  = struct('a', 50, 't', 12, 'z', 309);                       % head plate: bearing face at z = hef
  P.bas = struct('d', 12, 'x', 82, 'y', 80, 'yX', 98, 'zh', 66, 'Ls', 1220, 'pata', 200);
  P.jt  = [110 155 230 305];                                        % joint ties Ø10 (below the top of the beams)
  P.tt  = [28 42];                                                  % ties Ø14 above the top of the beams
  % sandwich
  P.sw = struct('gr', 25, 't', 12, 'b', 140, 'H', 220, 'g', 55, 'yT', 42, 'yS', 150, 's', 110, 'xe', 46);
end

% =====================================================================
%  1. Location plan (origin at B4, x east, y north)
% =====================================================================
function G = grid_lines()
  % lettered lines through two points (A is inclined: points at grids 4 and 1), numbered lines by y
  G.v = {'A', [-1780 0], [-2400 9750];  'B', [0 0], [0 9750];  'F', [2390 0], [2390 9750];
         'C', [4780 0], [4780 9750];  'G', [7170 0], [7170 9750];  'D', [9560 0], [9560 9750];
         'E', [10830 0], [10830 9750]};
  G.h = {'9', -1270;  '4', 0;  '11', 1443;  '10', 2887;  '3', 4330;  '2', 5730;  '1', 9750};
end

function x = xA(G, y)
  a = G.v{1,2};  b = G.v{1,3};
  x = a(1) + (b(1) - a(1))*(y - a(2))/(b(2) - a(2));
end

function it = dr_keyplan(P)
  G = grid_lines();  c = P.col.b/2;  bw = P.bm.b;  r = 330;  ext = 900;
  y9 = -1270;  y4 = 0;  y11 = 1443;  y10 = 2887;  y3 = 4330;  y2 = 5730;  y1 = 9750;
  xB = 0;  xF = 2390;  xC = 4780;  xG = 7170;  xD = 9560;  xE = 10830;
  it = {};
  yb = y9 - ext;  yt = y1 + ext;  xr = xE + ext;  xl = xA(G, y1) - ext;
  it = c_grid(G, [xl xr yb yt], struct('r', r, 'tdy', -90));
  % concrete beams 30x35
  for y = [y4 y3 y2 y1], it{end+1} = d_rectxy(xA(G, y), y - bw/2, xD, y + bw/2, 'beam'); end
  it{end+1} = d_poly([xA(G, y4) - bw/2, y4; xA(G, y1) - bw/2, y1; xA(G, y1) + bw/2, y1; xA(G, y4) + bw/2, y4], 'beam');
  for x = [xB xC xD], it{end+1} = d_rectxy(x - bw/2, y4, x + bw/2, y1, 'beam'); end
  % stirrups of beam D between 3 and 4: 110 from 3 to 10 and from 11 to 4, 140 between 10 and 11
  ys = [stir(y3 - c - 50, y10, -110), stir(y10, y11, -140), stir(y11, y4 + c + 50, -110)];
  for y = unique(round(ys)), it{end+1} = d_line(xD - bw/2 + 30, y, xD + bw/2 - 30, y, 'r_tieS'); end
  % steel beams IPE 200: grids 10 and 11 from A to E; grids F and G from 11 to 9
  for y = [y11 y10], it{end+1} = d_rectxy(xA(G, y), y - 50, xE, y + 50, 'tab'); end
  for x = [xF xG], it{end+1} = d_rectxy(x - 50, y9, x + 50, y11, 'tab'); end
  % columns 40x40
  for y = [y4 y3 y2 y1]
    for x = [xA(G, y) xB xC xD], it{end+1} = d_rectxy(x - c, y - c, x + c, y + c, 'column'); end
  end
  % cantilevers IPE 240 and slab edge
  bf = P.ipe.b;
  for x = [xB xC xD], it{end+1} = d_rectxy(x - bf/2, y9, x + bf/2, y4 - c, 'plate'); end
  for y = [y4 y3], it{end+1} = d_rectxy(xD + c, y - bf/2, xE, y + bf/2, 'plate'); end
  it{end+1} = d_line(xB - bw/2, y9, xE, y9, 'edge');  it{end+1} = d_line(xE, y9, xE, y3 + 60, 'edge');
  % extra bar of VCS+1Ø12 (drawn just south of the beam), centred on F and G
  for x = [xF xG]
    it = [it, c_rebar([x - 750, y4 - bw/2 - 90; x + 750, y4 - bw/2 - 90], 45, 'r_bm2', ...
                      struct('label', '+1Ø12, L = 1500 (abajo)', 'at', [x, y4 - bw/2 - 330]))];
  end
  % bastones: [column face point, direction into the beam in line]
  S = {[xB, y4 + c], [0 1];  [xC, y4 + c], [0 1];  [xD, y4 + c], [0 1];      % B4, C4, D4Y: VCM to the north
       [xD - c, y4], [-1 0];  [xD - c, y3], [-1 0]};                          % D4X, D3: beams to the west
  for k = 1:size(S, 1)
    p0 = S{k,1} - (P.col.b - P.bas.zh)*S{k,2};  e = S{k,2};  n = [-e(2) e(1)];   % hook face at 66 from the cantilever face
    for sg = [-1 1]
      q0 = p0 + sg*P.bas.x*n;
      it = [it, c_rebar([q0; q0 + P.bas.Ls*e], 40, 'r_bas')];
      it{end+1} = d_circle(q0(1), q0(2), 45, 'r_bas');                       % pata, down
    end
  end
  % sandwich connections: circle + the 2 rods through the beam
  for y = [y11 y10]
    for x = [xA(G, y) xB xC xD]
      it{end+1} = d_circle(x, y, 380, 'r_oval_l');
      for sg = [-1 1], it{end+1} = d_path([x - 200, y + sg*60; x + 200, y + sg*60], 40, 'r_anc'); end
    end
  end
  for x = [xF xG]
    it{end+1} = d_circle(x, y4, 380, 'r_oval_l');
    for sg = [-1 1], it{end+1} = d_path([x + sg*60, y4 - 200; x + sg*60, y4 + 200], 40, 'r_anc'); end
  end
  % labels
  ls = 'label';
  for x = (xB + xC)/2 + [0 4780]
    for y = [y3 y2 y1], it{end+1} = d_text(x + 900, y + 230, 'VCS 30x35', ls, 'middle'); end
    it{end+1} = d_text(x + 1150, y4 + 230, 'VCS+1Ø12', 'code', 'middle');
  end
  for x = [xB xC xD]
    it{end+1} = struct('t', 'text', 'p', [x - 260, (y10 + y3)/2], 'txt', 'VCM 30x35', 's', ls, 'a', 'middle', 'r', 90);
    it{end+1} = struct('t', 'text', 'p', [x - 260, (y2 + y1)/2], 'txt', 'VCS 30x35', 's', ls, 'a', 'middle', 'r', 90);
  end
  for y = [y11 y10], it{end+1} = d_text((xC + xG)/2, y + 120, 'IPE 200', 'small', 'middle'); end
  for x = [xF xG]
    it{end+1} = struct('t', 'text', 'p', [x + 170, (y11 + y4)/2], 'txt', 'IPE 200', 's', 'small', 'a', 'middle', 'r', 90);
  end
  for x = [xB xC]
    it{end+1} = struct('t', 'text', 'p', [x + 200, (y9 + y4)/2 - 150], 'txt', 'IPE 240', 's', 'code', 'a', 'middle', 'r', 90);
  end
  it{end+1} = d_text((xD + c + xE)/2, y3 - 300, 'IPE 240', 'code', 'middle');
  it{end+1} = d_text((xB + xC)/2, y9 - 280, 'borde de losa', 'small', 'middle');
  it{end+1} = d_text(xB - 260, y4 - 700, 'B4', 'red', 'end');
  it{end+1} = d_text(xC - 260, y4 - 700, 'C4', 'red', 'end');
  it{end+1} = d_text(xD - 260, y4 - 700, 'D4Y', 'red', 'end');
  it{end+1} = d_text(xD + c + 120, y4 - 320, 'D4X', 'red', 'start');
  it{end+1} = d_text(xD + c + 120, y3 + 200, 'D3', 'red', 'start');
  it{end+1} = d_text(xD + 450, (y11 + y4)/2, 'Ø10 c/110', 'tie', 'start');
  it{end+1} = d_text(xD + 450, (y10 + y11)/2, 'Ø10 c/140', 'tie', 'start');
  it{end+1} = d_text(xD + 450, (y3 + y10)/2, 'Ø10 c/110', 'tie', 'start');
  % section marks
  it = [it, c_cutmark([xF + 1100, y4], [1 0], 'A'), c_cutmark([xC, 700], [0 1], 'B'), c_cutmark([xD - 650, y3], [1 0], 'C')];
  % dimensions
  yd = yb - 2*r - 500;
  it{end+1} = d_dim(xA(G, y4), y4, xB, y4, -(y4 - yd), sprintf('%g', xB - xA(G, y4)));
  xs = cellfun(@(p) p(1), G.v(2:end,2));  ys = cell2mat(G.h(:,2));
  it = [it, c_dim_chain([xs, yd + 0*xs], 0)];
  xd = xr + 2*r + 450;
  it = [it, c_dim_chain([xd + 0*ys, ys], 0)];
end

function y = stir(y0, y1, s)
  % stirrup positions from y0 toward y1 at spacing s (signed)
  y = y0:s:y1;
end

% =====================================================================
%  Beam sections (v = up from the bottom of the beam)
% =====================================================================
function it = dr_beamsec(P, kind)
  b = P.bm.b;  h = P.bm.h;  rc = P.bm.rc;  d = P.bm.db;  x1 = b/2 - rc;
  S = struct('b', b, 'h', h, 'ct', 45, 'dst', 10);   % stirrup axis 45 from the faces
  top = @(x, y) [x, h - y, d];  bot = @(x, y) [x, y, d];
  switch kind
    case 'vcs1'
      xs = [-x1, -6, 6, x1];
      S.bars = [top(-x1, rc); top(0, rc); top(x1, rc); bot(xs(1), rc); bot(xs(2), rc); bot(xs(3), rc); bot(xs(4), rc)];
      S.bar_s = {'r_bm1', 'r_bm1', 'r_bm1', 'r_bm1', 'r_bm1', 'r_bm2', 'r_bm1'};
      it = c_rc_section(S);
      it{end+1} = d_text(xs(3) + 15, rc + 25, '+1Ø12', 'bsm', 'start');
      it{end+1} = d_text(0, h + 30, '3Ø12', 'bsm', 'middle');  it{end+1} = d_text(0, -60, '4Ø12 (1-2-1)', 'bsm', 'middle');
    case 'vcm'
      S.bars = [top(-x1, rc); bot(-x1, rc); top(0, rc); bot(0, rc); top(x1, rc); bot(x1, rc);
                top(-x1, rc + 24); bot(-x1, rc + 24); top(x1, rc + 24); bot(x1, rc + 24);
                top(-P.bas.x, P.bas.y); top(P.bas.x, P.bas.y)];
      S.bar_s = [repmat({'r_bm1'}, 1, 10), {'r_bas', 'r_bas'}];
      it = c_rc_section(S);
      it{end+1} = d_text(0, h + 30, '5Ø12 + 2 bastones Ø12', 'bsm', 'middle');  it{end+1} = d_text(0, -60, '5Ø12', 'bsm', 'middle');
      it{end+1} = d_dim(-P.bas.x, h - P.bas.y, P.bas.x, h - P.bas.y, -60, sprintf('%g', 2*P.bas.x));
    case 'vcs'
      S.bars = [top(-x1, rc); bot(-x1, rc); top(0, rc); bot(0, rc); top(x1, rc); bot(x1, rc);
                top(-x1, P.bas.y); top(x1, P.bas.y)];
      S.bar_s = [repmat({'r_bm1'}, 1, 6), {'r_bas', 'r_bas'}];
      it = c_rc_section(S);
      it{end+1} = d_text(0, h + 30, '3Ø12 + 2 bastones Ø12', 'bsm', 'middle');  it{end+1} = d_text(0, -60, '3Ø12', 'bsm', 'middle');
      it{end+1} = d_dim(-x1, h - P.bas.y, x1, h - P.bas.y, -60, sprintf('%g', 2*x1));
  end
  if ~strcmp(kind, 'vcs1')
    it{end+1} = d_dim(b/2, h, b/2, h - P.bas.y, -40, sprintf('%g', P.bas.y));
  end
  it = [it, c_rc_dims(S)];
end

% =====================================================================
%  2. End plate on column, C4. Elevation: z horizontal (0 = column face, IPE at z < 0),
%  v vertical (0 = top of the beams, up positive).
% =====================================================================
function it = dr_c4_elev(P)
  b = P.col.b;  ep = P.ep;  r = P.rod;  hd = P.hd;  ba = P.bas;  zL = 950;  vb = -520;  ip = P.ipe;
  it = {};
  it{end+1} = d_rectxy(0, -P.bm.h, b, P.col.top, 'r_conc');          % joint + column head (new pour)
  it{end+1} = d_rectxy(0, vb, b, -P.bm.h, 'r_old');                   % column below (cast before)
  it{end+1} = d_rectxy(b, -P.bm.h, zL, 0, 'r_conc');                  % VCM (cut)
  it{end+1} = d_line(zL, 0, zL, -P.bm.h, 'edge');
  for z = [P.col.rc, b - P.col.rc]
    zi = iif(z < b/2, z + 190, z - 190);
    it{end+1} = d_path(fillet([z vb; z P.col.top - 48; zi P.col.top - 48], 40), 16, 'r_colS');
  end
  for z = [100 300], it{end+1} = d_path([z P.col.top + 60; z -300], 12, 'r_rodS'); end   % steel-column anchors
  for v = -P.jt, it{end+1} = d_path([45 v; b - 45 v], 10, 'r_tieS'); end
  for v = P.tt, it{end+1} = d_path([43 v; b - 43 v], 14, 'r_new'); end
  for z = [106 200 294], for v = -[68 282], it{end+1} = d_circle(z, v, 6, 'r_bm3'); end, end
  for v = -[56 80], it{end+1} = d_path(fillet([zL v; 70 v; 70 v - 150], 25), 12, 'r_bm1'); end
  for v = -[294 270], it{end+1} = d_path(fillet([zL v; 70 v; 70 v + 150], 25), 12, 'r_bm1'); end
  it{end+1} = d_path(fillet([zL, -ba.y; ba.zh + 6, -ba.y; ba.zh + 6, -ba.y - ba.pata + 6], 25), 12, 'r_bas');
  % after the pour (transparent)
  it{end+1} = d_rectxy(-ep.gr, -ep.H, 0, 0, 'r_grout');
  it{end+1} = d_rectxy(-ep.gr - ep.t, -ep.H, -ep.gr, 0, 'r_eplate');
  zi = -ep.gr - ep.t;  zo = zi - 330;
  it = [it, c_ishape(ip, 'elevation', struct('x0', zo, 'x1', zi))];
  for v = -[ep.yT ep.yS]
    it{end+1} = d_bar(r.tip - r.L1, v, r.tip, v, r.d, 'r_anc');
    it{end+1} = d_rectxy(hd.z, v - hd.a/2, hd.z + hd.t, v + hd.a/2, 'r_bp');
    N = struct('wsh', r.wsh, 'nut', r.nut, 'dw', r.dw, 'nw', r.nw);
    it = [it, c_nut(hd.z + hd.t, v, 1, N, 'r_nut'), c_nut(-ep.gr, v, 1, N, 'r_ancg'), c_nut(zi, v, -1, N, 'r_ancg')];
  end
  % labels on the right, raised so the leaders are inclined
  xt = zL + 90;  up = P.bm.h/2;
  L = {40, [b - 60, P.tt(2)], '2 estribos Ø14 juntos, en la cabeza de la columna', 'new';
       -40, [600, -56], 'VCM: 5Ø12 arriba (2 líneas), gancho contra los estribos', 'bsm';
       -100, [700, -ba.y], sprintf('bastón Ø12: recto %g + pata %g', ba.Ls, ba.pata), 'hk';
       -170, [b - 60, -P.jt(2)], sprintf('estribos Ø10 del nudo cada 75 aprox. (110, 155, 230, 305);\nse pueden mover ± 20 para acomodar las barras longitudinales'), 'tie';
       -250, [300, -250], 'anclas Ø12 de la columna metálica, a 200 entre sí', 'bsm';
       -300, [200, -282], 'VCS: 3Ø12 + 3Ø12 (cruza)', 'bsm';
       -350, [600, -294], 'VCM: 5Ø12 abajo (2 líneas)', 'bsm'};
  for k = 1:size(L, 1)
    it = [it, c_leader(xt, L{k,1} + up, L{k,2}, L{k,3}, L{k,4})];
  end
  % A1 to the left, P1 to the right, with a leader to each pair
  it{end+1} = d_text(zo - 40, -120, 'A1', 'anc', 'end');
  for v = -[ep.yT ep.yS], it{end+1} = d_line(zo - 30, -110, -ep.gr - 60, v, 'lead'); end
  it{end+1} = d_text(b + 120, -175, 'P1', 'anc', 'start');
  for v = -[ep.yT ep.yS], it{end+1} = d_line(b + 110, -165, hd.z + hd.t, v, 'lead'); end
  it{end+1} = d_text(zo + 165, -ip.h/2, 'IPE 240 (después)', 'small', 'middle');
  it{end+1} = d_text(-ep.gr - 20, -ep.H - 45, sprintf('P2 + grout %g (después)', ep.gr), 'small', 'end');
  it{end+1} = d_text(-ep.gr - 20, -ep.H - 100, sprintf('Colocar los ganchos de las Ø12\ncontra los estribos'), 'code', 'end');
  it{end+1} = d_text(b/2, P.col.top + 30, 'columna 40x40', 'label', 'middle');
  it{end+1} = d_text(700, 25, 'VCM', 'label', 'middle');
  it{end+1} = d_text(b/2, -P.bm.h - 40, 'junta fría', 'small', 'middle');
  % dimensions
  for k = 0:2
    v0 = [0 ep.yT ep.yS ep.H];
    it{end+1} = d_dim(zo, -v0(k+1), zo, -v0(k+2), -60, sprintf('%g', v0(k+2) - v0(k+1)));
  end
  yd = P.col.top + 70;
  it{end+1} = d_dim(-ep.gr, yd, 0, yd, 0, sprintf('%g', ep.gr));
  it{end+1} = d_dim(0, yd, hd.z, yd, 0, sprintf('%g', hd.z));
  it{end+1} = d_dim(hd.z, yd, b, yd, 0, sprintf('%g', b - hd.z));
  it{end+1} = d_dim(0, 0, 0, P.col.top, 45, sprintf('%g', P.col.top));
  it{end+1} = d_dim(b, P.tt(2), b, P.col.top, -40, sprintf('%g', P.col.top - P.tt(2)));
end

% Front view from the cantilever: x horizontal (0 = column axis), v up (0 = top of beams)
function it = dr_c4_front(P)
  b = P.col.b;  ep = P.ep;  ba = P.bas;  ip = P.ipe;  it = {};
  it{end+1} = d_rectxy(-b/2, -P.bm.h, b/2, P.col.top, 'r_conc');
  it{end+1} = d_rectxy(-b/2, -480, b/2, -P.bm.h, 'r_old');
  for s = [-1 1], it{end+1} = d_rectxy(s*b/2, -P.bm.h, s*420, 0, 'r_conc'); end
  for s = [-1 1], it{end+1} = d_line(s*420, 0, s*420, -P.bm.h, 'edge'); end
  it = [it, joint_bars(P, -480)];
  for v = -[68 282], it{end+1} = d_path([-420 v; 420 v], 12, 'r_bm3'); end
  it = [it, vcm_patas(P)];
  for s = [-1 1]
    it{end+1} = d_path([s*ba.x, -ba.y; s*ba.x, -ba.y - ba.pata + 6], 12, 'r_bas');
    it{end+1} = d_half(s*ba.x, -ba.y, 6, 1, 'r_bas');
  end
  it{end+1} = d_rectxy(-ep.b/2 - 10, -ep.H - 10, ep.b/2 + 10, 0, 'r_grout');
  it{end+1} = d_rectxy(-ep.b/2, -ep.H, ep.b/2, 0, 'r_eplate');
  it = [it, c_ishape(ip, 'section')];
  for v = -[ep.yT ep.yS], for s = [-1 1]
    it{end+1} = d_circle(s*ep.g/2, v, P.rod.dw/2, 'r_ancg');
    it{end+1} = d_circle(s*ep.g/2, v, P.rod.d/2, 'r_anc');
  end, end
  it{end+1} = d_text(0, P.col.top + 30, 'columna', 'label', 'middle');
  it{end+1} = d_text(-310, 30, 'VCS', 'label', 'middle');  it{end+1} = d_text(310, 30, 'VCS', 'label', 'middle');
  it{end+1} = d_text(440, -60, sprintf('Estribos Ø10 del nudo\ncada 75 aprox.\n(110, 155, 230, 305);\n± 20 para acomodar\nlas barras longitudinales'), 'tie', 'start');
  it{end+1} = d_text(440, -330, 'P2 (después)', 'small', 'start');
  it{end+1} = d_dim(-ep.g/2, -ep.H, ep.g/2, -ep.H, -70, sprintf('%g', ep.g));
  it{end+1} = d_dim(-ep.b/2, -ep.H, ep.b/2, -ep.H, -150, sprintf('%g', ep.b));
  it{end+1} = d_dim(-ba.x, -ep.H - 230, ba.x, -ep.H - 230, 0, sprintf('%g', 2*ba.x));
  it{end+1} = d_dim(-b/2, 0, -b/2, -ba.y, 60, sprintf('%g', ba.y));
  it{end+1} = d_dim(-b/2, P.col.top, b/2, P.col.top, 50, sprintf('%g', b));
  it{end+1} = d_dim(-420, 0, -420, P.col.top, 50, sprintf('%g', P.col.top));
end

function it = joint_bars(P, vb)
  % column bars, steel-column anchors and ties, seen from a face (x = 0 at the column axis)
  b = P.col.b;  it = {};
  for x = [-1 0 1]*P.xc, it{end+1} = d_path([x vb; x P.col.top - 48], 16, 'r_col'); end
  for x = [-100 100], it{end+1} = d_path([x P.col.top + 60; x -300], 12, 'r_rodS'); end
  for v = -P.jt, it{end+1} = d_path([-b/2 + 45, v; b/2 - 45, v], 10, 'r_tieS'); end
  for v = P.tt, it{end+1} = d_path([-b/2 + 43, v; b/2 - 43, v], 14, 'r_new'); end
end

function it = vcm_patas(P)
  % VCM bars coming toward the viewer with their hooks: top ones down, bottom ones up
  it = {};
  T = [-94 56; 0 56; 94 56; -94 80; 94 80];  B = [-94 294; 0 294; 94 294; -94 270; 94 270];
  for k = 1:5
    it{end+1} = d_path([T(k,1), -T(k,2); T(k,1), -T(k,2) - 150], 12, 'r_bm1');
    it{end+1} = d_half(T(k,1), -T(k,2), 6, 1, 'r_bm1');
    it{end+1} = d_path([B(k,1), -B(k,2); B(k,1), -B(k,2) + 150], 12, 'r_bm1');
    it{end+1} = d_half(B(k,1), -B(k,2), 6, -1, 'r_bm1');
  end
end

% Plan at the level of the A1: x horizontal (0 = column axis), z up (0 = column face, VCM north)
function it = dr_c4_plan(P)
  b = P.col.b;  ep = P.ep;  r = P.rod;  hd = P.hd;  ba = P.bas;  zL = 1400;  it = {};
  it{end+1} = d_rectxy(-b/2, 0, b/2, b, 'r_conc');
  it{end+1} = d_rectxy(-P.bm.b/2, b, P.bm.b/2, zL, 'r_conc');
  for s = [-1 1], it{end+1} = d_rectxy(s*b/2, 50, s*450, 350, 'r_conc'); end
  for sx = [-1 0 1], for sz = [-1 0 1]
    if sx ~= 0 || sz ~= 0, it{end+1} = d_circle(sx*P.xc, b/2 + sz*P.xc, 8, 'r_col'); end
  end, end
  for sx = [-1 1], for z = [100 300], it{end+1} = d_circle(sx*100, z, 6, 'r_rod'); end, end
  it{end+1} = d_path([-b/2 + 45, 45; b/2 - 45, 45; b/2 - 45, b - 45; -b/2 + 45, b - 45; -b/2 + 45, 45], 10, 'r_tie');
  for x = [-94 0 94], it{end+1} = d_path([x zL; x 70], 12, 'r_bm1'); end
  for z = [106 200 294], it{end+1} = d_path([-450 z; 450 z], 12, 'r_bm3'); end
  for s = [-1 1]
    it{end+1} = d_path([s*ba.x, ba.zh + 6; s*ba.x, ba.zh + ba.Ls], 12, 'r_bas');
    it{end+1} = d_circle(s*ba.x, ba.zh + 6, 9, 'r_bas');
  end
  zi = -ep.gr - ep.t;
  it{end+1} = d_rectxy(-ep.b/2 - 10, -ep.gr, ep.b/2 + 10, 0, 'r_grout');
  it{end+1} = d_rectxy(-ep.b/2, zi, ep.b/2, -ep.gr, 'r_eplate');
  it{end+1} = d_rectxy(-P.ipe.b/2, zi - 220, P.ipe.b/2, zi, 'r_ipe');
  for s = [-1 1]
    x = s*ep.g/2;
    it{end+1} = d_bar(x, r.tip - r.L1, x, r.tip, r.d, 'r_anc');
    it{end+1} = d_rectxy(x - hd.a/2, hd.z, x + hd.a/2, hd.z + hd.t, 'r_bp');
    z = hd.z + hd.t;  it{end+1} = d_rectxy(x - 15, z, x + 15, z + r.wsh, 'r_nut');
    it{end+1} = d_rectxy(x - 12, z + r.wsh, x + 12, z + r.wsh + r.nut, 'r_nut');
    it{end+1} = d_rectxy(x - 12, zi - r.wsh - r.nut, x + 12, zi - r.wsh, 'r_ancg');
  end
  it{end+1} = d_text(0, zi - 260, 'IPE 240 (después)', 'small', 'middle');
  it{end+1} = d_text(0, zL + 30, 'VCM', 'label', 'middle');
  it{end+1} = d_text(-330, 380, 'VCS', 'label', 'middle');
  it{end+1} = d_text(ba.x + 30, 900, 'bastón Ø12', 'hk', 'start');
  it{end+1} = d_text(-ba.x - 30, 900, 'VCM 5Ø12', 'bsm', 'end');
  % dimensions, all outside the concrete
  it{end+1} = d_dim(-ep.g/2, zi - 300, ep.g/2, zi - 300, 0, sprintf('%g', ep.g));
  it{end+1} = d_dim(-450, 0, -450, hd.z, 60, sprintf('%g', hd.z));
  it{end+1} = d_dim(-450, -ep.gr, -450, 0, 60, sprintf('%g', ep.gr));
  it{end+1} = d_dim(-ba.x, zL + 120, ba.x, zL + 120, 0, sprintf('%g', 2*ba.x));
  it{end+1} = d_dim(450, 0, 450, ba.zh, -60, sprintf('%g', ba.zh));
  it{end+1} = d_dim(450, ba.zh, 450, ba.zh + ba.Ls, -60, sprintf('%g', ba.Ls));
end

% D4 seen from the south: x east (0 = column axis), v up (0 = top of beams).
% D4Y plate on the south face (in front), D4X plate on the east face (right).
function it = dr_d4_front(P)
  b = P.col.b;  ep = P.ep;  ba = P.bas;  ip = P.ipe;  r = P.rod;  hd = P.hd;  it = {};
  xW = -1200;  vT = [62 173];  vb = -480;
  it{end+1} = d_rectxy(-b/2, -P.bm.h, b/2, P.col.top, 'r_conc');
  it{end+1} = d_rectxy(-b/2, vb, b/2, -P.bm.h, 'r_old');
  it{end+1} = d_rectxy(xW, -P.bm.h, -b/2, 0, 'r_conc');  it{end+1} = d_line(xW, 0, xW, -P.bm.h, 'edge');
  it = [it, joint_bars(P, vb)];
  it{end+1} = d_path(fillet([xW -68; b/2 - 70, -68; b/2 - 70, -68 - 150], 25), 12, 'r_bm3');
  it{end+1} = d_path(fillet([xW -282; b/2 - 70, -282; b/2 - 70, -282 + 150], 25), 12, 'r_bm3');
  it = [it, vcm_patas(P)];
  for s = [-1 1]
    it{end+1} = d_path([s*ba.x, -ba.y; s*ba.x, -ba.y - ba.pata + 6], 12, 'r_bas');
    it{end+1} = d_half(s*ba.x, -ba.y, 6, 1, 'r_bas');
  end
  xh = b/2 - ba.zh;
  it{end+1} = d_path(fillet([xh - ba.Ls, -ba.yX; xh - 6, -ba.yX; xh - 6, -ba.yX - ba.pata + 6], 25), 12, 'r_bas');
  for v = -vT
    it{end+1} = d_bar(b/2 - r.tip, v, b/2 - r.tip + r.L1, v, r.d, 'r_anc');
    it{end+1} = d_rectxy(b/2 - hd.z - hd.t, v - hd.a/2, b/2 - hd.z, v + hd.a/2, 'r_bp');
  end
  for v = -[ep.yT ep.yS], for s = [-1 1], it{end+1} = d_circle(s*ep.g/2, v, r.d/2, 'r_anc'); end, end
  it{end+1} = d_rectxy(-ep.b/2, -ep.H, ep.b/2, 0, 'r_eplate');  it = [it, c_ishape(ip, 'section')];
  x0 = b/2;  it{end+1} = d_rectxy(x0, -ep.H, x0 + ep.gr, 0, 'r_grout');
  it{end+1} = d_rectxy(x0 + ep.gr, -ep.H, x0 + ep.gr + ep.t, 0, 'r_eplate');
  xi = x0 + ep.gr + ep.t;
  it{end+1} = d_rectxy(xi, -ip.h, xi + 350, 0, 'r_ipe');
  it{end+1} = d_rectxy(xi, -ip.tf, xi + 350, 0, 'r_ipef');  it{end+1} = d_rectxy(xi, -ip.h, xi + 350, -ip.h + ip.tf, 'r_ipef');
  it{end+1} = d_text(xi + 175, -ip.h - 45, 'IPE 240 D4X (después)', 'small', 'middle');
  it{end+1} = d_text(0, P.col.top + 30, 'columna D4', 'label', 'middle');
  it{end+1} = d_text((xW - b/2)/2, 25, 'VCS eje 4: 3Ø12 + 3Ø12, gancho contra los estribos', 'bsm', 'middle');
  it{end+1} = d_text(-700, -ba.yX - 35, sprintf('bastones D4X (a %g)', ba.yX), 'hk', 'middle');
  it{end+1} = d_text(-140, -vT(2) - 45, 'A1 de D4X', 'anc', 'middle');
  it{end+1} = d_text(0, vb - 50, 'D4Y: placa, A1 y bastones de frente (iguales a C4)', 'small', 'middle');
  % anchor axes: dashed lines out to the dimensions
  xd = xi + 420;  vd = vb - 120;
  for v = -vT, it{end+1} = d_line(b/2 - r.tip + r.L1, v, xd, v, 'cut'); end
  for s = [-1 1], it{end+1} = d_line(s*ep.g/2, -ep.yS, s*ep.g/2, vd, 'cut'); end
  it{end+1} = d_dim(xd, 0, xd, -vT(1), -40, sprintf('%g', vT(1)));
  it{end+1} = d_dim(xd, -vT(1), xd, -vT(2), -40, sprintf('%g', vT(2) - vT(1)));
  it{end+1} = d_dim(-ep.g/2, vd, ep.g/2, vd, 0, sprintf('%g (A1 de D4Y)', ep.g));
  it{end+1} = d_dim(xW, 0, xW, -ba.y, 60, sprintf('%g', ba.y));
  it{end+1} = d_dim(xW, -ba.y, xW, -ba.yX, 60, sprintf('%g', ba.yX - ba.y));
  it{end+1} = d_dim(-b/2, 0, -b/2, -ep.yT, 60, sprintf('%g', ep.yT));
  it{end+1} = d_dim(-b/2, -ep.yT, -b/2, -ep.yS, 60, sprintf('%g', ep.yS - ep.yT));
end

% =====================================================================
%  3. Sandwich. Side view of the concrete beam: x along the beam, v up (0 = top)
% =====================================================================
function it = dr_sw_front(P)
  sw = P.sw;  h = P.bm.h;  L = 520;  ip = P.ip2;  it = {};
  it{end+1} = d_rectxy(-L, -h, L, 0, 'r_conc');
  for s = [-1 1], it{end+1} = d_line(s*L, 0, s*L, -h, 'edge'); end
  xs = stirrups_sw(P, L);
  for x = xs, it{end+1} = d_path([x -45; x -h + 45], 10, 'r_tieS'); end
  for v = -[56 h - 56], it{end+1} = d_path([-L v; L v], 12, 'r_bm1'); end
  it{end+1} = d_rectxy(-sw.b/2, -sw.H, sw.b/2, 0, 'r_eplate');
  I = [-ip.b/2 0; ip.b/2 0; ip.b/2 -ip.tf; ip.tw/2 -ip.tf; ip.tw/2 -ip.h + ip.tf; ip.b/2 -ip.h + ip.tf; ip.b/2 -ip.h; ...
       -ip.b/2 -ip.h; -ip.b/2 -ip.h + ip.tf; -ip.tw/2 -ip.h + ip.tf; -ip.tw/2 -ip.tf; -ip.b/2 -ip.tf];
  it{end+1} = d_poly(I, 'r_ipe');
  for v = -[sw.yT sw.yS], for s = [-1 1], it{end+1} = d_circle(s*sw.g/2, v, P.rod.d/2, 'r_anc'); end, end
  it{end+1} = d_text(sw.b/2 + 20, -sw.H - 40, 'P3 + IPE 200 (después)', 'small', 'start');
  it{end+1} = d_text(-L + 20, -h + 75, 'estribos Ø10', 'tie', 'start');
  it{end+1} = d_dim(-sw.g/2, 0, sw.g/2, 0, 60, sprintf('%g', sw.g));
  it{end+1} = d_dim(-sw.b/2, 0, sw.b/2, 0, 130, sprintf('%g', sw.b));
  it{end+1} = d_dim(-sw.b/2, 0, -sw.b/2, -sw.yT, 60, sprintf('%g', sw.yT));
  it{end+1} = d_dim(-sw.b/2, -sw.yT, -sw.b/2, -sw.yS, 60, sprintf('%g', sw.yS - sw.yT));
  it{end+1} = d_dim(-sw.b/2, -sw.yS, -sw.b/2, -sw.H, 60, sprintf('%g', sw.H - sw.yS));
  xp = xs(xs >= 0);
  for k = 1:numel(xp) - 1, it{end+1} = d_dim(xp(k), -h, xp(k+1), -h, -60, sprintf('%g', xp(k+1) - xp(k))); end
  it{end+1} = d_dim(-xp(1), -h, xp(1), -h, -60, sprintf('%g', 2*xp(1)));
  it{end+1} = d_dim(L, 0, L, -h, -60, sprintf('%g', h));
end

function xs = stirrups_sw(P, L)
  % one stirrup at each side of the rods, the others every s outward from them
  xr = P.sw.xe:P.sw.s:L - 40;  xs = [-fliplr(xr), xr];
end

% Plan through the rods: x along the beam, w across (beam faces at w = +-150)
function it = dr_sw_plan(P)
  sw = P.sw;  b = P.bm.b;  L = 520;  r = P.rod;  it = {};
  it{end+1} = d_rectxy(-L, -b/2, L, b/2, 'r_conc');
  for s = [-1 1], it{end+1} = d_line(s*L, -b/2, s*L, b/2, 'edge'); end
  for x = stirrups_sw(P, L), it{end+1} = d_path([x -b/2 + 45; x b/2 - 45], 10, 'r_tieS'); end
  for w = [-94 0 94], it{end+1} = d_path([-L w; L w], 12, 'r_bm1'); end
  for s = [-1 1]
    it{end+1} = d_rectxy(-sw.b/2 - 10, s*b/2, sw.b/2 + 10, s*(b/2 + sw.gr), 'r_grout');
    it{end+1} = d_rectxy(-sw.b/2, s*(b/2 + sw.gr), sw.b/2, s*(b/2 + sw.gr + sw.t), 'r_eplate');
    it{end+1} = d_rectxy(-P.ip2.b/2, s*(b/2 + sw.gr + sw.t), P.ip2.b/2, s*(b/2 + sw.gr + sw.t + 250), 'r_ipe');
  end
  e = (r.L2 - b)/2;
  for x = [-1 1]*sw.g/2
    it{end+1} = d_bar(x, -b/2 - e, x, b/2 + e, r.d, 'r_anc');
    for s = [-1 1]
      w0 = s*(b/2 + sw.gr + sw.t);
      it{end+1} = d_rectxy(x - 15, w0, x + 15, w0 + s*r.wsh, 'r_ancg');
      it{end+1} = d_rectxy(x - 12, w0 + s*r.wsh, x + 12, w0 + s*(r.wsh + r.nut), 'r_ancg');
      w1 = s*(b/2 + sw.gr);
      it{end+1} = d_rectxy(x - 15, w1, x + 15, w1 - s*r.wsh, 'r_ancg');
    end
  end
  it{end+1} = d_text(0, b/2 + sw.gr + sw.t + 280, 'IPE 200 (después)', 'small', 'middle');
  it{end+1} = d_dim(-L, b/2, -L, b/2 + sw.gr, 60, sprintf('%g', sw.gr));
  it{end+1} = d_text(sw.g/2 + 30, -b/2 - e - 20, 'A2', 'anc', 'start');
  it{end+1} = d_dim(L, -b/2, L, b/2, -60, sprintf('%g', b));
  it{end+1} = d_dim(-sw.g/2, -b/2 - e, -sw.g/2, b/2 + e, 90, sprintf('%g', r.L2));
  it{end+1} = d_dim(-sw.g/2, b/2 + 60, sw.g/2, b/2 + 60, 0, sprintf('%g', sw.g));
end

% =====================================================================
%  4. Pieces
% =====================================================================
function it = dr_tie(P, db)
  it = c_column_tie(struct('b', P.col.b, 'xc', P.xc, 'db_col', P.col.db, 'db', db, ...
                           's', iif(db == 14, 'r_new', 'r_tieS')));
end

function it = dr_tie4(P)
  c = P.xc;  r = P.col.db/2 + 5;  e = 75;
  it = {d_rectxy(-P.col.b/2, -P.col.b/2, P.col.b/2, P.col.b/2, 'r_conc')};
  for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, it{end+1} = d_circle(sx*c, sy*c, 8, 'r_col'); end
  end, end
  aL = arcp([-c -c], r, 135, 270);  aR = arcp([c -c], r, -90, 45);
  Q = [aL(1,:) + e*[1 1]/sqrt(2); aL; aR; aR(end,:) + e*[-1 1]/sqrt(2)];
  for k = 1:4, it{end+1} = d_path(rotp(Q, 90*(k - 1), [0 0]), 10, sprintf('r_t%d', k)); end
  it{end+1} = d_dim(-P.col.b/2, -P.col.b/2, P.col.b/2, -P.col.b/2, -60, sprintf('%g (columna)', P.col.b));
end

function it = dr_rod(P, k)
  % rod drawn horizontally, x from the outer end
  r = P.rod;  it = {};
  if k == 1
    L = r.L1;  ep = P.ep;  hd = P.hd;  xF = L - r.tip;               % x of the column face
    it{end+1} = d_rectxy(xF, -45, L + 15, 45, 'r_concb');
    it{end+1} = d_bar(0, 0, L, 0, r.d, 'r_anc');
    xh = xF + hd.z;  it{end+1} = d_rectxy(xh, -hd.a/2, xh + hd.t, hd.a/2, 'r_bp');
    N = struct('wsh', r.wsh, 'nut', r.nut, 'dw', r.dw, 'nw', r.nw);
    it = [it, c_nut(xh + hd.t, 0, 1, N, 'r_nut')];
    xp = xF - ep.gr - ep.t;
    it{end+1} = d_rectxy(xp, -ep.H/4, xp + ep.t, ep.H/4, 'r_eplate');
    it = [it, c_nut(xp + ep.t, 0, 1, N, 'r_ancg'), c_nut(xp, 0, -1, N, 'r_ancg')];
    it{end+1} = d_text(xF + 10, 105, 'cara de la columna', 'small', 'start');
    it{end+1} = d_dim(0, -50, L, -50, -50, sprintf('L = %g', L));
    it{end+1} = d_dim(xF, 55, xh, 55, 0, sprintf('%g', hd.z));
    it{end+1} = d_dim(xp, 55, xF, 55, 0, sprintf('%g', xF - xp));
    it{end+1} = d_text(xh + 6, -hd.a/2 - 35, 'P1', 'anc', 'middle');
  else
    L = r.L2;  b = P.bm.b;  x0 = (L - b)/2;  t = P.sw.t;
    it{end+1} = d_rectxy(x0, -45, x0 + b, 45, 'r_concb');
    it{end+1} = d_bar(0, 0, L, 0, r.d, 'r_anc');
    gr = P.sw.gr;
    for s = [0 1]
      xp = iif(s == 0, x0 - gr - t, x0 + b + gr);
      it{end+1} = d_rectxy(xp, -P.sw.H/4, xp + t, P.sw.H/4, 'r_eplate');
      it = [it, c_nut(iif(s == 0, xp, xp + t), 0, iif(s == 0, -1, 1), struct('wsh', r.wsh, 'nut', r.nut, 'dw', r.dw, 'nw', r.nw), 'r_ancg')];
    end
    it{end+1} = d_dim(0, -50, L, -50, -50, sprintf('L = %g', L));
    it{end+1} = d_dim(x0, 55, x0 + b, 55, 0, sprintf('%g (viga)', b));
  end
end

function it = dr_plates(P, k)
  it = {};
  switch k
    case 1
      a = P.hd.a;  it{end+1} = d_rectxy(-a/2, -a/2, a/2, a/2, 'r_bp');  it{end+1} = d_circle(0, 0, 9, 'void');
      it{end+1} = d_dim(-a/2, -a/2, a/2, -a/2, -15, sprintf('%g', a));
      it{end+1} = d_dim(a/2, -a/2, a/2, a/2, -15, sprintf('%g', a));
    otherwise
      if k == 2, s = P.ep; else, s = P.sw; end
      it = c_plate(struct('b', s.b, 'H', s.H, 'g', s.g, 'rows', [s.yT s.yS], 'dh', P.rod.hole));
  end
end

% =====================================================================
%  Quantities and notes
% =====================================================================
function rows = quantities(P)
  r = P.rod;
  Lb = P.bas.Ls + P.bas.pata;
  t = {
    'A1', 'Anclaje columna', sprintf('varilla roscada Ø16 (5/8"-11 UNC) ASTM A193 B7, L = %g', r.L1), '4', '20'
    'A2', 'Anclaje sándwich', sprintf('varilla roscada Ø16 (5/8"-11 UNC) ASTM A193 B7, L = %g', r.L2), '4', '40'
    'P1', 'Placa de cabeza', 'PL 50x50x12 A36, agujero Ø18 (una por A1)', '4', '20'
    'P2', 'Placa extremo', 'PL 140x260x12 A36, 4 agujeros Ø18 (después)', '1', '5'
    'P3', 'Placa sándwich', 'PL 140x220x12 A36, 4 agujeros Ø18 (después)', '2', '20'
    'T', 'Tuerca', '5/8"-11 UNC grado 8 o A194 2H: 3 por A1 (cabeza, nivelación, exterior), 4 por A2 (2 de nivelación, 2 exteriores)', '-', '220'
    'W', 'Arandela', 'plana Ø30 x 3: 3 por A1, 4 por A2', '-', '220'
    'BA', 'Bastón', sprintf('Ø12 fy 4200, L = %g (recto %g + pata %g hacia abajo)', Lb, P.bas.Ls, P.bas.pata), '2', '10'
    'VE', 'Varilla extra VCS', 'Ø12 fy 4200, L = 1500, recta, abajo, centrada en F y G (eje 4)', '-', '2'
    'E14', 'Estribo columna', 'Ø14 cerrado, ganchos 135°, L ≈ 1450; 2 por columna, las 16 columnas', '2', '32'
    'E10', 'Estribo del nudo', 'Ø10 cerrado (o 4 piezas), L ≈ 1400; 4 niveles, las 16 columnas', '4', '64'
    'G', 'Grout', 'sin contracción, similar a SikaGrout-212, espesor 25: bajo P2 (5) y bajo P3 (20). Después de fundir', '1 o 2', '25'};
  rows = {};
  for i = 1:size(t, 1), rows{end+1} = t(i,:); end
end

function N = notes(P)
  N = {
    'Medidas en mm. Cotas desde la cara superior de las vigas (= cara superior de las IPE).'
    'Hormigón fc = 240 kg/cm2. Acero de refuerzo fy = 4200 kg/cm2.'
    '**Anclajes A1 y A2: varilla roscada ASTM A193 B7 con certificado del proveedor.** Tuercas grado 8 o A194 2H. Apretar a mano (sin torque).'
    '**Colocar A1 y A2 antes de fundir, con una plantilla de acero perforada igual a la placa** (agujeros Ø18). Proteger las roscas con cinta.'
    'A1: placa de cabeza P1 dentro de la jaula de estribos de la columna, punta a 345 de la cara. Si choca con una barra, inclinarla o correrla unos mm.'
    '**Bastones Ø12 (2 por unión):** pata de 200 hacia abajo a 66 de la cara del voladizo, tramo recto de 1220 hacia la viga en línea, junto al par de esquina.'
    '**D4: los A1 de D4X van a 62 y 173 (debajo de los de D4Y) y sus bastones a 98.** Correr los estribos del nudo lo necesario.'
    'Estribos del nudo Ø10 en las 16 columnas, a 110, 155, 230 y 305; deben quedar a 13 o más de anclajes y bastones.'
    '2 estribos Ø14 juntos en los 105 de la columna sobre las vigas, en las 16 columnas. Ganchos Ø16 de la columna hacia el centro.'
    'Sándwich: un estribo Ø10 a cada lado de los anclajes A2; los demás cada 110 desde ellos. A2 entre estribos, paralelos a sus ramas.'
    'Viga D entre 3 y 4: estribos Ø10 cada 110 de 3 a 10 y de 11 a 4; cada 140 entre 10 y 11.'
    '**Después de fundir:** placas P2 y P3, IPE, tuercas de nivelación y exteriores, grout sin contracción similar a SikaGrout-212, 25 bajo P2 y P3.'
    'Soldadura E70XX: ala superior de penetración completa; ala inferior y alma, filete de 6.'
    'La columna se funde hasta el fondo de las vigas; nudo, vigas y cabeza de columna en una sola fundida.'};
end

% =====================================================================
%  Small helpers (drawing items and blocks: lib/sheets)
% =====================================================================
function out = iif(c, a, b)
  if c, out = a; else, out = b; end
end

function F = title_fields(opts)
  T = opts.titleblock;
  F = cell(1, size(T, 1));
  for i = 1:size(T, 1), F{i} = {T{i,1}, strrep(T{i,2}, '\n', char(10))}; end
end

