function file = make_sheet(outdir, opts)
% MAKE_SHEET  A1 sheet (Spanish) of the steel-beam connections. Units mm.
%   Column 1: location plan + beam sections. Column 2: end plate on concrete
%   column (C4) and sandwich connection. Column 3: pieces, quantities, notes.
% Transparent: what is placed after the pour (end plates, IPE, grout, outer
% nuts). Solid: everything placed before the pour.
% Item and block helpers copied from ../cantilever_anchor_bolted_plate/make_pour_sheets.m.
  P = params();
  c1 = {};  c2 = {};  c3 = {};

  % ---- column 1: location plan and sections -------------------------------------------
  c1{end+1} = blk_h(1, 'Conexiones de vigas de acero a vigas y columnas de hormigón');
  c1{end+1} = blk_h(2, '1. Planta de ubicación');
  c1{end+1} = blk_draw(dr_keyplan(P), 300, 'PLANTA DE UBICACIÓN', ...
      ['**Rojo: unión placa extremo-columna** (B4, C4, D4X, D4Y, D3), con 2 bastones Ø12 (naranja) en la viga en línea; ' ...
       'punto naranja: pata hacia abajo. **Círculos: conexión sándwich (10)**, con los 2 anclajes que atraviesan la viga. ' ...
       'Viga D entre 3 y 4: estribos Ø10 cada 110 / 140 / 110. Ejes 4 (B-C y C-D): **VCS+1Ø12**, varilla extra abajo (celeste). ' ...
       'Azul: vigas de acero IPE 240 (voladizos) e IPE 160 (bordes en los ejes 9 y E).']);
  c1{end+1} = blk_row([1 1 1]/3, { ...
      {blk_draw(dr_beamsec(P, 'vcs1'), 95, 'CORTE A-A: VCS+1Ø12 (EJE 4)', ...
         '3Ø12 arriba, 4Ø12 abajo (1-2-1). **Varilla extra Ø12, L = 1500, centrada en el cruce con la IPE 200 (ejes F y G).**')}, ...
      {blk_draw(dr_beamsec(P, 'vcm'), 95, 'CORTE B-B: VCM CON BASTONES', ...
         'B4, C4, D4Y. VCM 5Ø12 + 5Ø12 (pares en las esquinas). **Bastones Ø12 junto al par de esquina, a 80 de arriba.**')}, ...
      {blk_draw(dr_beamsec(P, 'vcs'), 95, 'CORTE C-C: VCS CON BASTONES', ...
         'D4X y D3. VCS 3Ø12 + 3Ø12. **Bastones Ø12 contra el estribo, debajo de las esquinas, a 80 de arriba (en D4X: a 98).**')}});
  c1{end+1} = blk_h(2, '5. Soldadura de las vigas a las placas (IPE 240 a P2, IPE 200 a P3)');
  c1{end+1} = blk_row([0.58 0.42], { ...
      {blk_draw(dr_weld_front(P), 68, 'DETALLE 5.1 - SOLDADURAS VIGA - PLACA, VISTA DE FRENTE', ...
         ['Mismo detalle para IPE 240 + P2 e IPE 200 + P3 (dibujada la IPE 240). **Todas en obra, E70XX.** Largos de los filetes de 6: ' ...
          'IPE 240: alma 2 x 190, ala inferior 120 por fuera y 2 x 42 por dentro; IPE 200: alma 2 x 159, ala inferior 100 por fuera y 2 x 35 por dentro. ' ...
          '**No soldar en los radios entre ala y alma.**'])}, ...
      {blk_draw(dr_weld_side(P), 68, 'DETALLE 5.2 - CORTE POR EL ALMA', ...
         'Bandera: soldadura en obra. Ala superior: CJP con bisel en el ala, junta precalificada AWS D1.1, sin agujeros de acceso.')}});

  % ---- column 2: C4 and sandwich ---------------------------------------------------------
  c2{end+1} = blk_h(2, '2. Unión placa extremo - columna (C4; igual en B4, D4X, D4Y, D3)');
  c2{end+1} = blk_draw(dr_c4_elev(P), 150, 'DETALLE 2.1 - C4: CORTE POR EL EJE DEL VOLADIZO', ...
      ['Anclajes A1 (rojo) con placa de cabeza P1 dentro de la jaula de estribos. Bastones Ø12 (naranja) con pata de 200 hacia abajo. ' ...
       'Estribos del nudo Ø10 (morado) cada 75 aprox.; 2 estribos Ø14 (verde) en la cabeza de la columna. Transparente: va después.']);
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
         [sprintf('Anclajes A2 pasantes, L = %g, entre estribos.', P.rod.L2) ' Grout 25, placas, tuercas e IPE 200: después.'])}});

  % ---- column 3: pieces, quantities, notes ------------------------------------------------------
  c3{end+1} = blk_h(2, '4. Piezas, cantidades y notas');
  c3{end+1} = blk_row([1 1 1]/3, { ...
      {blk_draw(dr_tie(P, 14), 56, 'DETALLE 4.1 - ESTRIBO Ø14', ...
         'Cabeza de la columna (105 sobre las vigas): 2 por columna, juntos. Recubrimiento 36 (barras de la columna a 58).')}, ...
      {blk_draw(dr_tie(P, 10), 56, 'DETALLE 4.2 - ESTRIBO DEL NUDO Ø10', ...
         'Cada 75 aprox. en el nudo; se pueden mover ± 20 para acomodar las barras longitudinales.')}, ...
      {blk_draw(dr_tie4(P), 56, 'DETALLE 4.3 - OPCIÓN: Ø10 EN 4 PIEZAS', ...
         '4 piezas rectas con ganchos de 135° a las barras de esquina, una por cara.')}});
  c3{end+1} = blk_row([0.5 0.5], { ...
      {blk_draw(dr_rod(P, 1), 45, 'DETALLE 4.4 - ANCLAJE A1 (COLUMNAS)', ...
         'Desde la cara de la columna. Placa de cabeza P1, arandela y tuerca: antes. Tuercas de nivelación (dentro del grout) y exterior: después.')}, ...
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
  sl = P.sl;  Am = pi*sl.dm^2/4;  As = Am*1000/sl.sm;
  c3{end+1} = blk_draw(dr_deck(P), 41, 'DETALLE 4.6 - LOSA: NOVALOSA 55 + 5 CM DE HORMIGÓN (GENÉRICO)', ...
      sprintf(['Placa según el fabricante. Nivel terminado: %g sobre las vigas. ' ...
               'Malla 4.5-15, lisa o corrugada, fy ≥ 490 MPa. Cumple la cuantía mínima: %.0f mm2/m, se piden %.0f. ' ...
               'Traslapo de la malla: 300.'], sl.hd + sl.tc, As, 0.0018*sl.tc*1000));

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
  P.ipe = struct('h', 240, 'b', 120, 'tf', 9.8, 'tw', 6.2);
  P.ip2 = struct('h', 200, 'b', 100, 'tf', 8.5, 'tw', 5.6);
  P.ip6 = struct('h', 160, 'b', 82, 'tf', 7.4, 'tw', 5.0);
  % slab: Novalosa 55 (steel deck 1 mm) + 50 of concrete = 105 over the top of the beams; mesh 4.5-15
  P.sl = struct('hd', 55, 'tc', 50, 'e', 1, 'dm', 4.5, 'sm', 150);
  % end plate on column
  P.ep = struct('t', 12, 'b', 140, 'H', 260, 'g', 80, 'yT', 42, 'yS', 198, 'gr', 25);
  P.rod = struct('d', 16, 'L1', 470, 'L2', 470, 'nut', 16, 'nw', 27, 'wsh', 4, 'dw', 33, 'hole', 18, 'pr', 5);
  % 5/8"-11 UNC: heavy hex nut A194 2H (27 across flats, 16 high); F436 washer (OD 33, ID 17.5, 3.1-4.5 thick)
  % pr: rod past the nut, 2 threads (pitch 2.3)
  P.hd  = struct('a', 50, 't', 12, 'z', 309);                       % head plate: bearing face at z = hef
  P.rod.tip = P.hd.z + P.hd.t + P.rod.wsh + P.rod.nut + P.rod.pr;  % 346: rod tip from the column face
  P.bas = struct('d', 12, 'x', 82, 'y', 80, 'yX', 98, 'zh', 66, 'Ls', 1220, 'pata', 200);
  P.jt  = [110 155 230 305];                                        % joint ties Ø10 (below the top of the beams)
  P.tt  = [14 28];                                                  % ties Ø14 above the top of the beams
  P.cv  = 40;                                                       % cover: ties, and top of the column to the Ø16 hooks
  % sandwich
  P.sw = struct('gr', 25, 't', 12, 'b', 140, 'H', 220, 'g', 55, 'yT', 42, 'yS', 150, 's', 110, 'xe', 46);
end

% =====================================================================
%  1. Location plan (origin at B4, x east, y north)
% =====================================================================
function G = grid_lines()
  G.xn = {'B', 'F', 'C', 'G', 'D', 'E'};  G.x = [0 2390 4780 7170 9560 10830];
  G.yn = {'9', '4', '11', '10', '3', '2', '1'};  G.y = [-1270 0 1443 2887 4330 5730 9750];
  G.A = [-1780 0; -2400 9750];                      % grid A, inclined: points at grids 4 and 1
end

function x = xA(G, y)
  x = G.A(1,1) + (G.A(2,1) - G.A(1,1))*(y - G.A(1,2))/(G.A(2,2) - G.A(1,2));
end

function it = dr_keyplan(P)
  G = grid_lines();  c = P.col.b/2;  bw = P.bm.b;  r = 330;  ext = 900;
  y9 = -1270;  y4 = 0;  y11 = 1443;  y10 = 2887;  y3 = 4330;  y2 = 5730;  y1 = 9750;
  xB = 0;  xF = 2390;  xC = 4780;  xG = 7170;  xD = 9560;  xE = 10830;
  it = {};
  yb = y9 - ext;  yt = y1 + ext;  xr = xE + ext;  xl = xA(G, y1) - ext;
  it{end+1} = d_line(xA(G, yb), yb, xA(G, yt), yt, 'axis');
  it{end+1} = d_circle(xA(G, yb), yb - r, r, 'bubble');  it{end+1} = d_text(xA(G, yb), yb - r - 90, 'A', 'grid', 'middle');
  for i = 1:numel(G.x)
    it{end+1} = d_line(G.x(i), yb, G.x(i), yt, 'axis');
    it{end+1} = d_circle(G.x(i), yb - r, r, 'bubble');  it{end+1} = d_text(G.x(i), yb - r - 90, G.xn{i}, 'grid', 'middle');
  end
  for j = 1:numel(G.y)
    it{end+1} = d_line(xl, G.y(j), xr, G.y(j), 'axis');
    it{end+1} = d_circle(xr + r, G.y(j), r, 'bubble');  it{end+1} = d_text(xr + r, G.y(j) - 90, G.yn{j}, 'grid', 'middle');
  end
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
  % edge beams IPE 160 on grids 9 (B to E) and E (9 to 3)
  b6 = P.ip6.b;
  it{end+1} = d_rectxy(xB - bf/2, y9 - b6/2, xE + b6/2, y9 + b6/2, 'plate');
  it{end+1} = d_rectxy(xE - b6/2, y9 + b6/2, xE + b6/2, y3 + bf/2, 'plate');
  % extra bar of VCS+1Ø12 (drawn just south of the beam), centred on F and G
  for x = [xF xG]
    it{end+1} = d_path([x - 750, y4 - bw/2 - 90; x + 750, y4 - bw/2 - 90], 45, 'r_bm2');
    it{end+1} = d_text(x, y4 - bw/2 - 330, '+1Ø12, L = 1500 (abajo)', 'bsm', 'middle');
  end
  % bastones: [column face point, direction into the beam in line]
  S = {[xB, y4 + c], [0 1];  [xC, y4 + c], [0 1];  [xD, y4 + c], [0 1];      % B4, C4, D4Y: VCM to the north
       [xD - c, y4], [-1 0];  [xD - c, y3], [-1 0]};                          % D4X, D3: beams to the west
  for k = 1:size(S, 1)
    p0 = S{k,1} - (P.col.b - P.bas.zh)*S{k,2};  e = S{k,2};  n = [-e(2) e(1)];   % hook face at 66 from the cantilever face
    for sg = [-1 1]
      q0 = p0 + sg*P.bas.x*n;
      it{end+1} = d_path([q0; q0 + P.bas.Ls*e], 40, 'r_bas');
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
  it{end+1} = d_text((xB + xC)/2, y9 - 280, 'IPE 160 (viga de borde, eje 9)', 'code', 'middle');
  it{end+1} = struct('t', 'text', 'p', [xE + 200, (y4 + y11)/2], 'txt', 'IPE 160 (borde, eje E)', 's', 'code', 'a', 'middle', 'r', 90);
  it{end+1} = d_text(xB - 260, y4 - 700, 'B4', 'red', 'end');
  it{end+1} = d_text(xC - 260, y4 - 700, 'C4', 'red', 'end');
  it{end+1} = d_text(xD - 260, y4 - 700, 'D4Y', 'red', 'end');
  it{end+1} = d_text(xD + c + 120, y4 - 320, 'D4X', 'red', 'start');
  it{end+1} = d_text(xD + c + 120, y3 + 200, 'D3', 'red', 'start');
  it{end+1} = d_text(xD + 450, (y11 + y4)/2, 'Ø10 c/110', 'tie', 'start');
  it{end+1} = d_text(xD + 450, (y10 + y11)/2, 'Ø10 c/140', 'tie', 'start');
  it{end+1} = d_text(xD + 450, (y3 + y10)/2, 'Ø10 c/110', 'tie', 'start');
  % section marks
  it = [it, cutmark([xF + 1100, y4], [1 0], 'A'), cutmark([xC, 700], [0 1], 'B'), cutmark([xD - 650, y3], [1 0], 'C')];
  % dimensions
  yd = yb - 2*r - 500;
  it{end+1} = d_dim(xA(G, y4), y4, xB, y4, -(y4 - yd), sprintf('%g', xB - xA(G, y4)));
  for i = 1:numel(G.x) - 1, it{end+1} = d_dim(G.x(i), yd, G.x(i+1), yd, 0, sprintf('%g', G.x(i+1) - G.x(i))); end
  xd = xr + 2*r + 450;
  for j = 1:numel(G.y) - 1, it{end+1} = d_dim(xd, G.y(j), xd, G.y(j+1), 0, sprintf('%g', G.y(j+1) - G.y(j))); end
end

function y = stir(y0, y1, s)
  % stirrup positions from y0 toward y1 at spacing s (signed)
  y = y0:s:y1;
end

function it = cutmark(p, e, L)
  % section cut across a beam: two short strokes and the letter, e = direction of the beam
  n = [-e(2) e(1)];  it = {};
  for sg = [-1 1]
    a = p + sg*260*n;  b = p + sg*480*n;
    it{end+1} = d_line(a(1), a(2), b(1), b(2), 'lead');
    it{end+1} = d_text(b(1) + sg*n(1)*120 + 60*e(1), b(2) + sg*n(2)*120 - 60, L, 'code', 'middle');
  end
end

% =====================================================================
%  Beam sections (v = up from the bottom of the beam)
% =====================================================================
function it = dr_beamsec(P, kind)
  b = P.bm.b;  h = P.bm.h;  rc = P.bm.rc;  d = P.bm.db;  x1 = b/2 - rc;
  it = {d_rectxy(-b/2, 0, b/2, h, 'r_conc')};
  ct = 45;                                            % stirrup axis from the face
  TL = [-b/2 + ct, h - ct];  w = 60*[1 -1]/sqrt(2);  m = [0, h - ct];
  e1 = TL + [22 0];  e2 = TL + [0 -22];          % both 135 deg hooks wrap the corner bar and point inward
  it{end+1} = d_path(fillet([e1 + w; e1; TL; -b/2 + ct, ct; b/2 - ct, ct; b/2 - ct, h - ct; m], 8), 10, 'r_tieS');
  it{end+1} = d_path(fillet([m; TL; e2; e2 + w], 8), 10, 'r_tieS');
  top = @(x, y, s) d_circle(x, h - y, d/2, s);
  bot = @(x, y, s) d_circle(x, y, d/2, s);
  switch kind
    case 'vcs1'
      for x = [-x1 0 x1], it{end+1} = top(x, rc, 'r_bm1'); end
      xs = [-x1, -6, 6, x1];
      for k = 1:4, it{end+1} = bot(xs(k), rc, iif(k == 3, 'r_bm2', 'r_bm1')); end
      it{end+1} = d_text(xs(3) + 15, rc + 25, '+1Ø12', 'bsm', 'start');
      it{end+1} = d_text(0, h + 30, '3Ø12', 'bsm', 'middle');  it{end+1} = d_text(0, -60, '4Ø12 (1-2-1)', 'bsm', 'middle');
    case 'vcm'
      for x = [-x1 0 x1], it{end+1} = top(x, rc, 'r_bm1');  it{end+1} = bot(x, rc, 'r_bm1'); end
      for x = [-x1 x1], it{end+1} = top(x, rc + 24, 'r_bm1');  it{end+1} = bot(x, rc + 24, 'r_bm1'); end
      for x = [-1 1]*P.bas.x, it{end+1} = top(x, P.bas.y, 'r_bas'); end
      it{end+1} = d_text(0, h + 30, '5Ø12 + 2 bastones Ø12', 'bsm', 'middle');  it{end+1} = d_text(0, -60, '5Ø12', 'bsm', 'middle');
      it{end+1} = d_dim(-P.bas.x, h - P.bas.y, P.bas.x, h - P.bas.y, -60, sprintf('%g', 2*P.bas.x));
    case 'vcs'
      for x = [-x1 0 x1], it{end+1} = top(x, rc, 'r_bm1');  it{end+1} = bot(x, rc, 'r_bm1'); end
      for x = [-1 1]*x1, it{end+1} = top(x, P.bas.y, 'r_bas'); end
      it{end+1} = d_text(0, h + 30, '3Ø12 + 2 bastones Ø12', 'bsm', 'middle');  it{end+1} = d_text(0, -60, '3Ø12', 'bsm', 'middle');
      it{end+1} = d_dim(-x1, h - P.bas.y, x1, h - P.bas.y, -60, sprintf('%g', 2*x1));
  end
  if ~strcmp(kind, 'vcs1')
    it{end+1} = d_dim(b/2, h, b/2, h - P.bas.y, -40, sprintf('%g', P.bas.y));
  end
  it{end+1} = d_dim(-b/2, 0, b/2, 0, -100, sprintf('%g', b));
  it{end+1} = d_dim(-b/2, 0, -b/2, h, 60, sprintf('%g', h));
  it{end+1} = d_dim(b/2, 0, b/2, ct - 5, -40, sprintf('rec. %g', ct - 5), 'before');
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
    zi = iif(z < b/2, z + 190, z - 190);  vh = P.col.top - P.cv - P.col.db/2;
    it{end+1} = d_path(fillet([z vb; z vh; zi vh], 40), 16, 'r_colS');
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
  it{end+1} = d_rectxy(zo, -ip.h, zi, 0, 'r_ipe');
  it{end+1} = d_rectxy(zo, -ip.tf, zi, 0, 'r_ipef');  it{end+1} = d_rectxy(zo, -ip.h, zi, -ip.h + ip.tf, 'r_ipef');
  for v = -[ep.yT ep.yS]
    it{end+1} = d_bar(r.tip - r.L1, v, r.tip, v, r.d, 'r_anc');
    it{end+1} = d_rectxy(hd.z, v - hd.a/2, hd.z + hd.t, v + hd.a/2, 'r_bp');
    z = hd.z + hd.t;  it{end+1} = d_rectxy(z, v - r.dw/2, z + r.wsh, v + r.dw/2, 'r_nut');
    it{end+1} = d_rectxy(z + r.wsh, v - r.nw/2, z + r.wsh + r.nut, v + r.nw/2, 'r_nut');
    it{end+1} = d_rectxy(-ep.gr, v - r.dw/2, -ep.gr + r.wsh, v + r.dw/2, 'r_ancg');
    it{end+1} = d_rectxy(-ep.gr + r.wsh, v - r.nw/2, -ep.gr + r.wsh + r.nut, v + r.nw/2, 'r_ancg');
    it{end+1} = d_rectxy(zi - r.wsh, v - r.dw/2, zi, v + r.dw/2, 'r_ancg');
    it{end+1} = d_rectxy(zi - r.wsh - r.nut, v - r.nw/2, zi - r.wsh, v + r.nw/2, 'r_ancg');
  end
  % labels on the right: short horizontal landing, inclined leader, dot on the element.
  % Ordered so that the leaders do not cross.
  xk = zL + 25;  xt = zL + 70;
  L = {220, [b - 70, P.tt(2)], '2 estribos Ø14 juntos, en la cabeza de la columna', 'new';
       160, [b - 70, -P.jt(2)], sprintf('estribos Ø10 del nudo cada 75 aprox.;\nse pueden mover ± 20 para acomodar las barras longitudinales'), 'tie';
       85, [300, -190], 'anclas Ø12 de la columna metálica, a 200 entre sí', 'bsm';
       35, [106, -282], 'VCS: 3Ø12 + 3Ø12 (cruza)', 'bsm';
       -15, [880, -56], 'VCM: 5Ø12 arriba (2 líneas), gancho contra los estribos', 'bsm';
       -65, [900, -ba.y], sprintf('bastón Ø12: recto %g + pata %g', ba.Ls, ba.pata), 'hk';
       -115, [880, -294], 'VCM: 5Ø12 abajo (2 líneas)', 'bsm'};
  for k = 1:size(L, 1)
    vl = L{k,1} + 8;  q = L{k,2};
    it{end+1} = d_line(xt - 8, vl, xk, vl, 'leadt');
    it{end+1} = d_line(xk, vl, q(1), q(2), 'leadt');
    it{end+1} = d_circle(q(1), q(2), 7, 'leadf');
    it{end+1} = d_text(xt, L{k,1}, L{k,3}, L{k,4}, 'start');
  end
  % A1 to the left (beyond the dimensions), P1 to the right, with an arrow to each pair
  it{end+1} = d_text(zo - 130, 80, 'A1', 'anc', 'end');
  for v = -[ep.yT ep.yS], it = [it, d_arrow(zo - 120, 90, zi - r.wsh - r.nut - 15, v)]; end
  it{end+1} = d_text(b + 120, -175, 'P1', 'anc', 'start');
  for v = -[ep.yT ep.yS], it = [it, d_arrow(b + 110, -165, hd.z + hd.t + 4, v)]; end
  it{end+1} = d_text(zo + 165, -ip.h/2, 'IPE 240 (después)', 'small', 'middle');
  it{end+1} = d_text(-ep.gr - 20, -ep.H - 45, sprintf('P2 + grout %g (después)', ep.gr), 'small', 'end');
  it{end+1} = d_text(-ep.gr - 20, -ep.H - 100, sprintf('Colocar los ganchos de las Ø12\ncontra los estribos'), 'code', 'end');
  it{end+1} = d_text(b/2, -P.bm.h - 110, 'columna 40x40', 'label', 'middle');
  it{end+1} = d_text(700, 25, 'VCM', 'label', 'middle');
  it{end+1} = d_text(b/2, -P.bm.h - 40, 'junta fría', 'small', 'middle');
  % dimensions
  for k = 0:2
    v0 = [0 ep.yT ep.yS ep.H];
    it{end+1} = d_dim(zo, -v0(k+1), zo, -v0(k+2), -50, sprintf('%g', v0(k+2) - v0(k+1)), iif(k == 0, 'before', 'after'));
  end
  yd = P.col.top + 70;
  it{end+1} = d_dim(-ep.gr, yd, 0, yd, 0, sprintf('%g', ep.gr));
  it{end+1} = d_dim(0, yd, hd.z, yd, 0, sprintf('%g', hd.z));
  it{end+1} = d_dim(hd.z, yd, b, yd, 0, sprintf('%g', b - hd.z));
  it{end+1} = d_dim(0, 0, 0, P.col.top, 45, sprintf('%g', P.col.top));
  it{end+1} = d_dim(b, P.col.top - P.cv, b, P.col.top, -40, sprintf('rec. %g', P.cv));
  % steel-column anchors, below the column, with their axes dashed down
  vd = vb - 50;
  for z = [100 300], it{end+1} = d_line(z, -300, z, vd, 'cut'); end
  it{end+1} = d_dim(0, vd, 100, vd, 0, '100');
  it{end+1} = d_dim(100, vd, 300, vd, 0, '200');
  it{end+1} = d_dim(300, vd, b, vd, 0, '100');
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
    it{end+1} = d_pata(s*ba.x, -ba.y, ba.pata - 6, -1, 12, 'r_bas');
  end
  it{end+1} = d_rectxy(-ep.b/2 - 10, -ep.H - 10, ep.b/2 + 10, 0, 'r_grout');
  it{end+1} = d_rectxy(-ep.b/2, -ep.H, ep.b/2, 0, 'r_eplate');
  it{end+1} = d_poly(ishape(ip), 'r_ipe');
  for v = -[ep.yT ep.yS], for s = [-1 1]
    it{end+1} = d_circle(s*ep.g/2, v, P.rod.dw/2, 'r_ancg');
    it{end+1} = d_circle(s*ep.g/2, v, P.rod.d/2, 'r_anc');
  end, end
  it{end+1} = d_text(0, -P.bm.h - 80, 'columna', 'label', 'middle');
  it{end+1} = d_text(-310, 30, 'VCS', 'label', 'middle');  it{end+1} = d_text(310, 30, 'VCS', 'label', 'middle');
  % anchor rows from the top of the beams: dashed axes out to a chain on the right
  xr = 480;
  for v = -[ep.yT ep.yS], it{end+1} = d_line(ep.g/2, v, xr + 10, v, 'cut'); end
  it{end+1} = d_line(420, 0, xr + 10, 0, 'cut');
  it{end+1} = d_dim(xr, 0, xr, -ep.yT, 0, sprintf('%g', ep.yT), 'before');
  it{end+1} = d_dim(xr, -ep.yT, xr, -ep.yS, 0, sprintf('%g', ep.yS - ep.yT));
  it{end+1} = d_dim(xr + 70, 0, xr + 70, -ep.yS, 0, sprintf('%g', ep.yS));
  it{end+1} = d_text(xr + 100, -ep.yT - 5, 'A1 (fila superior)', 'anc', 'start');
  it{end+1} = d_text(xr + 100, -ep.yS - 5, 'A1 (fila inferior)', 'anc', 'start');
  it{end+1} = d_text(xr + 100, 10, 'cara superior de las vigas', 'small', 'start');
  it{end+1} = d_text(440, -300, 'P2 (después)', 'small', 'start');
  % plate and bastón dimensions below the column, with the axes dashed down to them
  vd = -480 - 50;
  for x = [-1 1]*ep.g/2, it{end+1} = d_line(x, -ep.yS, x, vd, 'cut'); end
  for x = [-1 1]*ba.x, it{end+1} = d_line(x, -ba.y - ba.pata, x, vd - 140, 'cut'); end
  it{end+1} = d_dim(-ep.g/2, vd, ep.g/2, vd, 0, sprintf('%g', ep.g));
  it{end+1} = d_dim(-ep.b/2, -ep.H, ep.b/2, -ep.H, -(-vd + 70 - ep.H), sprintf('%g', ep.b));
  it{end+1} = d_dim(-ba.x, vd - 140, ba.x, vd - 140, 0, sprintf('%g', 2*ba.x));
  it{end+1} = d_dim(-b/2, 0, -b/2, -ba.y, 60, sprintf('%g', ba.y));
  it{end+1} = d_dim(-100, P.col.top + 60, 100, P.col.top + 60, 25, '200');
  it{end+1} = d_dim(-b/2, P.col.top, b/2, P.col.top, 125, sprintf('%g', b));
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
    it{end+1} = d_pata(T(k,1), -T(k,2), 150, -1, 12, 'r_bm1');
    it{end+1} = d_pata(B(k,1), -B(k,2), 150, 1, 12, 'r_bm1');
  end
end

function it = d_pata(x, y, len, dir, d, s)
  % hook leg seen from the front: the bar turns toward the viewer at (x, y), drawn as one
  % outline with a rounded end (no line across it); dir = -1: leg goes down, 1: up
  r = d/2;  a = linspace(0, pi, 13)';  if dir > 0, a = a + pi; end
  it = d_poly([x - dir*r, y + dir*len; x - dir*r, y; x + r*cos(a), y + r*sin(a); x + dir*r, y; x + dir*r, y + dir*len], s);
end

function I = ishape(ip)
  I = [-ip.b/2 0; ip.b/2 0; ip.b/2 -ip.tf; ip.tw/2 -ip.tf; ip.tw/2 -ip.h + ip.tf; ip.b/2 -ip.h + ip.tf; ip.b/2 -ip.h; ...
       -ip.b/2 -ip.h; -ip.b/2 -ip.h + ip.tf; -ip.tw/2 -ip.h + ip.tf; -ip.tw/2 -ip.tf; -ip.b/2 -ip.tf];
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
    z = hd.z + hd.t;  it{end+1} = d_rectxy(x - r.dw/2, z, x + r.dw/2, z + r.wsh, 'r_nut');
    it{end+1} = d_rectxy(x - r.nw/2, z + r.wsh, x + r.nw/2, z + r.wsh + r.nut, 'r_nut');
    it{end+1} = d_rectxy(x - r.nw/2, zi - r.wsh - r.nut, x + r.nw/2, zi - r.wsh, 'r_ancg');
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
    it{end+1} = d_pata(s*ba.x, -ba.y, ba.pata - 6, -1, 12, 'r_bas');
  end
  xh = b/2 - ba.zh;
  it{end+1} = d_path(fillet([xh - ba.Ls, -ba.yX; xh - 6, -ba.yX; xh - 6, -ba.yX - ba.pata + 6], 25), 12, 'r_bas');
  for v = -vT
    it{end+1} = d_bar(b/2 - r.tip, v, b/2 - r.tip + r.L1, v, r.d, 'r_anc');
    it{end+1} = d_rectxy(b/2 - hd.z - hd.t, v - hd.a/2, b/2 - hd.z, v + hd.a/2, 'r_bp');
  end
  for v = -[ep.yT ep.yS], for s = [-1 1], it{end+1} = d_circle(s*ep.g/2, v, r.d/2, 'r_anc'); end, end
  it{end+1} = d_rectxy(-ep.b/2, -ep.H, ep.b/2, 0, 'r_eplate');  it{end+1} = d_poly(ishape(ip), 'r_ipe');
  x0 = b/2;  it{end+1} = d_rectxy(x0, -ep.H, x0 + ep.gr, 0, 'r_grout');
  it{end+1} = d_rectxy(x0 + ep.gr, -ep.H, x0 + ep.gr + ep.t, 0, 'r_eplate');
  xi = x0 + ep.gr + ep.t;
  it{end+1} = d_rectxy(xi, -ip.h, xi + 350, 0, 'r_ipe');
  it{end+1} = d_rectxy(xi, -ip.tf, xi + 350, 0, 'r_ipef');  it{end+1} = d_rectxy(xi, -ip.h, xi + 350, -ip.h + ip.tf, 'r_ipef');
  it{end+1} = d_text(xi + 175, -ip.h - 45, 'IPE 240 D4X (después)', 'small', 'middle');
  it{end+1} = d_text(0, -P.bm.h - 60, 'columna D4', 'label', 'middle');
  it{end+1} = d_text((xW - b/2)/2, 25, 'VCS eje 4: 3Ø12 + 3Ø12, gancho contra los estribos', 'bsm', 'middle');
  it{end+1} = d_text(-700, -ba.yX - 35, sprintf('bastones D4X (a %g)', ba.yX), 'hk', 'middle');
  it{end+1} = d_text(-280, -235, 'A1 de D4X', 'anc', 'end');
  for v = -vT, it = [it, d_arrow(-275, -225, b/2 - r.tip + 15, v)]; end
  it{end+1} = d_text(-280, -420, 'A1 de D4Y', 'anc', 'end');
  for v = -[ep.yT ep.yS], it = [it, d_arrow(-275, -410, -ep.g/2 - 6, v - 6)]; end
  it{end+1} = d_text(0, vb - 50, 'D4Y: placa, A1 y bastones de frente (iguales a C4)', 'small', 'middle');
  % anchor axes: dashed lines out to the dimensions (D4X and D4Y, two chains on the right)
  xd = xi + 420;  xy = xd + 130;  vd = vb - 120;
  for v = -vT, it{end+1} = d_line(b/2 - r.tip + r.L1, v, xd, v, 'cut'); end
  for v = -[ep.yT ep.yS], it{end+1} = d_line(ep.g/2, v, xy, v, 'cut'); end
  for s = [-1 1], it{end+1} = d_line(s*ep.g/2, -ep.yS, s*ep.g/2, vd, 'cut'); end
  it{end+1} = d_line(xd, 0, xy, 0, 'cut');
  it{end+1} = d_dim(xd, 0, xd, -vT(1), -40, sprintf('%g', vT(1)));
  it{end+1} = d_dim(xd, -vT(1), xd, -vT(2), -40, sprintf('%g', vT(2) - vT(1)));
  it{end+1} = d_dim(xy, 0, xy, -ep.yT, -40, sprintf('%g', ep.yT));
  it{end+1} = d_dim(xy, -ep.yT, xy, -ep.yS, -40, sprintf('%g', ep.yS - ep.yT));
  it{end+1} = d_text(xd, 40, 'A1 D4X', 'anc', 'middle');
  it{end+1} = d_text(xy + 40, 40, 'A1 D4Y', 'anc', 'middle');
  it{end+1} = d_dim(-ep.g/2, vd, ep.g/2, vd, 0, sprintf('%g (A1 de D4Y)', ep.g));
  it{end+1} = d_dim(xW, 0, xW, -ba.y, 60, sprintf('%g', ba.y));
  it{end+1} = d_dim(xW, -ba.y, xW, -ba.yX, 60, sprintf('%g', ba.yX - ba.y));
  it{end+1} = d_dim(-b/2, 0, -b/2, P.col.top, 60, sprintf('%g', P.col.top));
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
  % anchor rows: dashed axes out to a chain on the left of the beam, and a label with arrows
  xc = -L - 50;
  for v = -[sw.yT sw.yS], it{end+1} = d_line(-sw.g/2, v, xc, v, 'cut'); end
  it{end+1} = d_dim(-L, 0, -L, -sw.yT, -50, sprintf('%g', sw.yT), 'before');
  it{end+1} = d_dim(-L, -sw.yT, -L, -sw.yS, -50, sprintf('%g', sw.yS - sw.yT));
  it{end+1} = d_dim(-L, -sw.yS, -L, -h, -50, sprintf('%g', h - sw.yS));
  it{end+1} = d_text(-260, 95, 'A2 (anclajes)', 'anc', 'end');
  for v = -[sw.yT sw.yS], it = [it, d_arrow(-255, 85, -sw.g/2 - 9, v + 5)]; end
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
      it{end+1} = d_rectxy(x - r.dw/2, w0, x + r.dw/2, w0 + s*r.wsh, 'r_ancg');
      it{end+1} = d_rectxy(x - r.nw/2, w0 + s*r.wsh, x + r.nw/2, w0 + s*(r.wsh + r.nut), 'r_ancg');
      w1 = s*(b/2 + sw.gr);
      it{end+1} = d_rectxy(x - r.dw/2, w1, x + r.dw/2, w1 - s*r.wsh, 'r_ancg');
      it{end+1} = d_rectxy(x - r.nw/2, w1 - s*r.wsh, x + r.nw/2, w1 - s*(r.wsh + r.nut), 'r_ancg');
    end
  end
  wp = b/2 + sw.gr + sw.t;  xl = 190;
  T = {[xl, 400], [P.ip2.b/2 - 5, 390], 'IPE 200 (después)';
       [xl, 300], [sw.b/2 - 10, wp - sw.t/2], sprintf('P3 140x220x12 (después)');
       [xl, 235], [sw.b/2 + 2, b/2 + sw.gr/2], sprintf('grout %g (después)', sw.gr);
       [xl, -260], [sw.g/2 + r.d/2 + 2, -b/2 - e + 10], sprintf('A2, L = %g', r.L2);
       [xl, -330], [sw.g/2 + r.nw/2 + 2, -wp - r.wsh - r.nut/2], 'tuerca y arandela exteriores';
       [xl, -400], [P.ip2.b/2 - 5, -390], 'IPE 200 (después)'};
  for k = 1:size(T, 1)
    q = T{k,1};  it{end+1} = d_text(q(1) + 10, q(2) - 8, T{k,3}, iif(k == 4, 'anc', 'small'), 'start');
    it = [it, d_arrow(q(1), q(2), T{k,2}(1), T{k,2}(2))];
  end
  it{end+1} = d_dim(-L, b/2, -L, b/2 + sw.gr, 60, sprintf('%g', sw.gr));
  it{end+1} = d_dim(L, -b/2, L, b/2, -60, sprintf('%g', b));
  it{end+1} = d_dim(-sw.g/2, -b/2 - e, -sw.g/2, b/2 + e, 73, sprintf('%g', r.L2));
  it{end+1} = d_dim(-sw.g/2, b/2 + 60, sw.g/2, b/2 + 60, 0, sprintf('%g', sw.g));
end

% =====================================================================
%  5. Welds of the beam to the plate (generic: IPE 240 on P2 drawn). x across, v up (0 = top)
% =====================================================================
function it = dr_weld_front(P)
  ip = P.ipe;  ep = P.ep;  w = 6;  rr = 15;  b = ip.b;  h = ip.h;  tf = ip.tf;  tw = ip.tw;  it = {};
  it{end+1} = d_rectxy(-ep.b/2, -ep.H, ep.b/2, 0, 'r_eplate');
  it{end+1} = d_poly(ishape_r(ip, rr), 'r_ipe');
  it{end+1} = d_rectxy(-b/2, -tf, b/2, 0, 'weldf');                                % CJP: the whole flange
  it{end+1} = d_rectxy(-b/2, -h - w, b/2, -h, 'weldf');                            % bottom flange, outside
  for s = [-1 1]
    it{end+1} = d_rectxy(s*(tw/2 + rr), -h + tf, s*b/2, -h + tf + w, 'weldf');    % bottom flange, inside
    it{end+1} = d_rectxy(s*tw/2, -tf - rr, s*(tw/2 + w), -h + tf + rr, 'weldf');  % web, straight part
  end
  xl = b/2 + 45;
  T = {[xl, 10], [b/2 - 8, -tf/2], 'CJP ala superior (todo el ancho)';
       [xl, -55], [tw/2 + 5, -tf - 5], 'radios: sin soldadura';
       [xl, -120], [tw/2 + w, -h/2], sprintf('filete %g alma, ambos lados,\nen la parte recta', w);
       [xl, -200], [b/2 - 8, -h + tf + w/2], sprintf('filete %g ala inferior, por dentro,\nde la punta al radio', w);
       [xl, -265], [b/2 - 8, -h - w/2], sprintf('filete %g ala inferior, por fuera,\ntodo el ancho', w)};
  for k = 1:size(T, 1)
    q = T{k,1};  it{end+1} = d_text(q(1) + 8, q(2) - 6, T{k,3}, iif(k == 2, 'code', 'small'), 'start');
    it = [it, d_arrow(q(1), q(2), T{k,2}(1), T{k,2}(2))];
  end
  it = [it, d_arrow(xl, -55, tw/2 + 5, -h + tf + 5)];
  it{end+1} = d_text(-ep.b/2 - 60, -40, sprintf('placa\nP2 o P3'), 'small', 'end');
  it{end+1} = d_dim(-b/2, -tf - rr, -b/2, -h + tf + rr, -25, sprintf('%.0f (alma)', h - 2*(tf + rr)));
  it{end+1} = d_dim(-b/2, -h + tf, -tw/2 - rr, -h + tf, -(tf + 2*P.ep.H - 2*h + 20), sprintf('%.0f', (b - tw - 2*rr)/2), 'before');
  it{end+1} = d_dim(-b/2, -h - w, b/2, -h - w, -(P.ep.H - h - w + 50), sprintf('%g', b));
end

function I = ishape_r(ip, r)
  % I section with the root radii
  b = ip.b;  h = ip.h;  tf = ip.tf;  t = ip.tw/2;
  I = [-b/2 0; b/2 0; b/2 -tf; arcp([t + r, -tf - r], r, 90, 180); arcp([t + r, -h + tf + r], r, 180, 270); ...
       b/2 -h + tf; b/2 -h; -b/2 -h; -b/2 -h + tf; arcp([-t - r, -h + tf + r], r, 270, 360); ...
       arcp([-t - r, -tf - r], r, 0, 90); -b/2 -tf];
end

% Section through the web: z horizontal (0 = beam face of the plate), v up (0 = top)
function it = dr_weld_side(P)
  ip = P.ipe;  ep = P.ep;  w = 6;  rr = 15;  h = ip.h;  tf = ip.tf;  Lb = 230;  it = {};
  it{end+1} = d_rectxy(-ep.t, -ep.H, 0, 0, 'r_eplate');
  it{end+1} = d_rectxy(0, -h, Lb, 0, 'r_ipe');
  it{end+1} = d_rectxy(0, -tf, Lb, 0, 'r_ipef');  it{end+1} = d_rectxy(0, -h, Lb, -h + tf, 'r_ipef');
  it{end+1} = d_line(Lb, 0, Lb, -h, 'edge');
  it{end+1} = d_poly([0 0; tf 0; 0 -tf], 'weldf');                                   % bevel, filled
  it{end+1} = d_poly([0 -h; w -h; 0 -h - w], 'weldf');                               % bottom flange outside
  it{end+1} = d_poly([0 -h + tf; w -h + tf; 0 -h + tf + w], 'weldf');                % bottom flange inside
  it{end+1} = d_rectxy(0, -tf - rr, w, -h + tf + rr, 'weldf');                       % web
  it{end+1} = d_weld(3, -tf/2, 70, 70, 1, 'arrow', '', '', 0, 1, 'CJP', 'weldf', 'bevel');
  it{end+1} = d_weld(w, -h/2, 70, -60, 1, 'both', sprintf('%g', w), '', 0, 1, 'alma, parte recta', 'weldf', '');
  it{end+1} = d_weld(2, -h - 2, 70, -h - 60, 1, 'both', sprintf('%g', w), '', 0, 1, 'ala inferior', 'weldf', '');
  it{end+1} = d_text(-ep.t - 8, -ep.H + 10, 'placa', 'small', 'end');
  it{end+1} = d_text(Lb/2 + 40, -h/2 - 50, 'IPE', 'small', 'middle');
end

function it = d_weld(xt, yt, xe, ye, dr, side, sz, len, all, field, tail, s, groove)
  % AWS weld symbol (joint_pdf.py; groove 'bevel' from pour_pdf.py)
  it = struct('t', 'weld', 'p', [xt yt xe ye], 'dir', dr, 'side', side, 'size', sz, ...
              'len', len, 'all', all, 'field', field, 'tail', tail, 's', s, 'groove', groove);
end

% =====================================================================
%  4.6 Slab on steel deck, section across the ribs: x along, v up (0 = top of the beams)
% =====================================================================
function it = dr_deck(P)
  sl = P.sl;  H = sl.hd + sl.tc;  p = 230;  a = 55;  c = 105;  sp = (p - a - c)/2;  n = 2;  X = n*p;  it = {};
  Q = [];
  for k = 0:n-1
    x = k*p;  Q = [Q; x 0; x + a 0; x + a + sp, sl.hd; x + a + sp + c, sl.hd];
  end
  Q = [Q; X 0];
  it{end+1} = d_poly([Q; X H; 0 H], 'r_conc');
  hb = 45;                                                                          % beam drawn cut
  it{end+1} = d_rectxy(0, -hb, X, 0, 'r_ipe');  it{end+1} = d_rectxy(0, -P.ip6.tf, X, 0, 'r_ipef');
  it{end+1} = d_line(0, -hb, X, -hb, 'edge');
  it{end+1} = d_path(Q, 3, 'r_bp');                                                  % deck, 1 mm (drawn thicker)
  vm = H - 20 - sl.dm*1.5;                                                            % lower wires, cover 20 on top
  it{end+1} = d_path([0 vm; X vm], sl.dm, 'r_bm1');
  for x = 40:sl.sm:X, it{end+1} = d_circle(x, vm + sl.dm, sl.dm/2 + 0.5, 'r_bm1'); end
  for x = [0 X], it{end+1} = d_line(x, -hb, x, H, 'edge'); end
  % labels
  xl = X + 40;
  T = {[xl, H + 60], [X - 70, H - 8], 'hormigón fc 210', 'small';
       [xl, H + 5], [X - 40, vm + 2], sprintf('malla %g-%g', sl.dm, sl.sm/10), 'bsm';
       [xl, -10], [X - p + a + sp/2 + 4, sl.hd/2], sprintf('Novalosa 55, e = %g mm', sl.e), 'code';
       [xl, -55], [X - 30, -hb/2], 'viga de acero', 'small'};
  for k = 1:size(T, 1)
    q = T{k,1};  it{end+1} = d_text(q(1) + 10, q(2) - 6, T{k,3}, T{k,4}, 'start');
    it = [it, d_arrow(q(1), q(2), T{k,2}(1), T{k,2}(2))];
  end
  % dimensions on the left
  it{end+1} = d_dim(0, 0, 0, sl.hd, 40, sprintf('%g', sl.hd));
  it{end+1} = d_dim(0, sl.hd, 0, H, 40, sprintf('%g', sl.tc));
  it{end+1} = d_dim(0, 0, 0, H, 110, sprintf('%g', H));
  it{end+1} = d_dim(p + 40, vm + sl.dm*1.5, p + 40, H, -25, 'rec. 20');
end

% =====================================================================
%  4. Pieces
% =====================================================================
function it = dr_tie(P, db)
  c = P.xc;  r = P.col.db/2 + db/2;  e = max(6*db, 75);  w = [1 1]/sqrt(2);
  BL = [-c -c];  BR = [c -c];  TR = [c c];  TL = [-c c];
  a0 = arcp(BL, r, 135, 270);  a5 = arcp(BL, r, 180, 315);
  Q1 = [a0(1,:) + e*w; a0; arcp(BR, r, -90, 0); arcp(TR, r, 0, 90); arcp(TL, r, 90, 180)];
  Q2 = [Q1(end,:); a5; a5(end,:) + e*w];
  st = iif(db == 14, 'r_new', 'r_tieS');
  it = {d_rectxy(-P.col.b/2, -P.col.b/2, P.col.b/2, P.col.b/2, 'r_conc')};
  for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, it{end+1} = d_circle(sx*c, sy*c, 8, 'r_col'); end
  end, end
  it{end+1} = d_path(Q1, db, st);  it{end+1} = d_path(Q2, db, st);
  o = c + r + db/2;  B = P.col.b/2;
  it{end+1} = d_dim(-o, -o, o, -o, -90, sprintf('%.0f', 2*o));
  it{end+1} = d_dim(-B, B, -o, B, 30, sprintf('rec. %.0f', B - o));
  it{end+1} = d_dim(o, -o, o, o, -90, sprintf('%.0f', 2*o));
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
    it{end+1} = d_rectxy(xh + hd.t, -r.dw/2, xh + hd.t + r.wsh, r.dw/2, 'r_nut');
    it{end+1} = d_rectxy(xh + hd.t + r.wsh, -r.nw/2, xh + hd.t + r.wsh + r.nut, r.nw/2, 'r_nut');
    xp = xF - ep.gr - ep.t;
    it{end+1} = d_rectxy(xF - ep.gr, -ep.H/4, xF, ep.H/4, 'r_grout');
    it{end+1} = d_rectxy(xp, -ep.H/4, xp + ep.t, ep.H/4, 'r_eplate');
    it{end+1} = d_rectxy(xp + ep.t, -r.dw/2, xp + ep.t + r.wsh, r.dw/2, 'r_nut');
    it{end+1} = d_rectxy(xp + ep.t + r.wsh, -r.nw/2, xp + ep.t + r.wsh + r.nut, r.nw/2, 'r_nut');
    it{end+1} = d_rectxy(xp - r.wsh, -r.dw/2, xp, r.dw/2, 'r_nut');
    it{end+1} = d_rectxy(xp - r.wsh - r.nut, -r.nw/2, xp - r.wsh, r.nw/2, 'r_nut');
    it{end+1} = d_text(xF + 10, 105, 'cara de la columna', 'small', 'start');
    it{end+1} = d_dim(0, -50, L, -50, -165, sprintf('L = %g', L));
    it{end+1} = d_dim(xF - ep.gr, -ep.H/4, xF, -ep.H/4, -20, sprintf('%g grout', ep.gr));
    it{end+1} = d_text(xF - ep.gr/2 - 70, 115, 'grout', 'small', 'end');
    it = [it, d_arrow(xF - ep.gr/2 - 65, 110, xF - ep.gr/2, 35)];
    it{end+1} = d_dim(xF, 55, xh, 55, 0, sprintf('%g', hd.z));
    it{end+1} = d_dim(xp, 55, xF, 55, 0, sprintf('%g', xF - xp));
    it{end+1} = d_text(xh + 6, -hd.a/2 - 35, 'P1', 'anc', 'middle');
    it{end+1} = d_text(xF + 110, -122, 'tuerca de nivelación', 'small', 'start');
    it = [it, d_arrow(xF + 105, -115, xp + ep.t + r.wsh + r.nut/2, -r.nw/2 - 2)];
  else
    L = r.L2;  b = P.bm.b;  x0 = (L - b)/2;  t = P.sw.t;
    it{end+1} = d_rectxy(x0, -45, x0 + b, 45, 'r_concb');
    it{end+1} = d_bar(0, 0, L, 0, r.d, 'r_anc');
    gr = P.sw.gr;
    for s = [0 1]
      xp = iif(s == 0, x0 - gr - t, x0 + b + gr);
      xg = iif(s == 0, x0 - gr, x0 + b);
      it{end+1} = d_rectxy(xg, -P.sw.H/4, xg + gr, P.sw.H/4, 'r_grout');
      it{end+1} = d_rectxy(xp, -P.sw.H/4, xp + t, P.sw.H/4, 'r_eplate');
      xw = iif(s == 0, xp + t, xp - r.wsh);                                    % leveling washer and nut
      it{end+1} = d_rectxy(xw, -r.dw/2, xw + r.wsh, r.dw/2, 'r_nut');
      xl = iif(s == 0, xw + r.wsh, xw - r.nut);
      it{end+1} = d_rectxy(xl, -r.nw/2, xl + r.nut, r.nw/2, 'r_nut');
      it{end+1} = d_dim(xg, -P.sw.H/4, xg + gr, -P.sw.H/4, -20, sprintf('%g', gr), iif(s == 0, 'before', 'after'));
      it = [it, d_arrow(L/2, 115, xg + gr/2, 35)];
      xo = iif(s == 0, xp - r.wsh, xp + t);
      it{end+1} = d_rectxy(xo, -r.dw/2, xo + r.wsh, r.dw/2, 'r_nut');
      xn = iif(s == 0, xo - r.nut, xo + r.wsh);
      it{end+1} = d_rectxy(xn, -r.nw/2, xn + r.nut, r.nw/2, 'r_nut');
    end
    it{end+1} = d_dim(0, -50, L, -50, -165, sprintf('L = %g', L));
    it{end+1} = d_dim(x0, 55, x0 + b, 55, 0, sprintf('%g (viga)', b));
    it{end+1} = d_text(L/2, 122, sprintf('grout %g', gr), 'small', 'middle');
    it{end+1} = d_text(L/2, -125, 'tuercas de nivelación', 'small', 'middle');
    for xn = [x0 - gr + r.wsh + r.nut/2, x0 + b + gr - r.wsh - r.nut/2]
      it = [it, d_arrow(L/2 + sign(xn - L/2)*40, -108, xn, -r.nw/2 - 2)];
    end
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
      it{end+1} = d_rectxy(-s.b/2, -s.H, s.b/2, 0, 'r_eplate');
      for v = -[s.yT s.yS], for x = [-1 1]*s.g/2, it{end+1} = d_circle(x, v, 9, 'void'); end, end
      it{end+1} = d_dim(-s.b/2, -s.H, s.b/2, -s.H, -30, sprintf('%g', s.b));
      it{end+1} = d_dim(-s.g/2, 0, s.g/2, 0, 30, sprintf('%g', s.g));
      it{end+1} = d_dim(s.b/2, 0, s.b/2, -s.yT, 30, sprintf('%g', s.yT));
      it{end+1} = d_dim(s.b/2, -s.yT, s.b/2, -s.yS, 30, sprintf('%g', s.yS - s.yT));
      it{end+1} = d_dim(s.b/2, -s.yS, s.b/2, -s.H, 30, sprintf('%g', s.H - s.yS));
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
    'T', 'Tuerca', 'hexagonal pesada 5/8"-11 UNC ASTM A194 2H (27 entre caras, 16 de alto): 3 por A1 (cabeza, nivelación, exterior), 4 por A2 (2 de nivelación, 2 exteriores)', '-', '220'
    'W', 'Arandela', 'endurecida ASTM F436 para 5/8" (Ø ext. 33, int. 17.5, espesor 4): 3 por A1, 4 por A2', '-', '220'
    'BA', 'Bastón', sprintf('Ø12, L = %g (recto %g + pata %g hacia abajo)', Lb, P.bas.Ls, P.bas.pata), '2', '10'
    'VE', 'Varilla extra VCS', 'Ø12, L = 1500, recta, abajo, centrada en F y G (eje 4)', '-', '2'
    'E14', 'Estribo columna', 'Ø14 cerrado, ganchos 135°, L ≈ 1450; 2 por columna, las 16 columnas', '2', '32'
    'E10', 'Estribo del nudo', 'Ø10 cerrado (o 4 piezas), L ≈ 1400; cada 75 aprox. en el nudo, las 16 columnas', '4', '64'
    'G', 'Grout', sprintf('sin contracción (ASTM C1107), mínimo 280 kg/cm2, similar a SikaGrout-212, espesor %g: bajo P2 (5) y bajo P3 (20). Después de fundir', P.ep.gr), '1 o 2', '25'};
  rows = {};
  for i = 1:size(t, 1), rows{end+1} = t(i,:); end
end

function N = notes(P)
  N = {
    'Medidas en mm. Cotas desde la cara superior de las vigas (= cara superior de las IPE).'
    'Hormigón: vigas y columnas fc = 240 kg/cm2; losa fc = 210 kg/cm2 (las conexiones se verificaron con 210). Acero de refuerzo fy = 4200 kg/cm2; malla electrosoldada fy ≥ 490 MPa.'
    'Recubrimiento libre 40 a los estribos en vigas y columnas, y 40 sobre los ganchos Ø16 en la cara superior de la columna.'
    '**Anclajes A1 y A2: varilla roscada ASTM A193 B7 con certificado del proveedor.** Tuercas hexagonales pesadas ASTM A194 2H y arandelas endurecidas ASTM F436 (no usar tuercas ni arandelas comunes). Apretar a mano (sin torque).'
    '**Colocar A1 y A2 antes de fundir, con una plantilla de acero perforada igual a la placa** (agujeros Ø18). Proteger las roscas con cinta.'
    sprintf('A1: placa de cabeza P1 dentro de la jaula de estribos de la columna, punta a %g de la cara. Si choca con una barra, inclinarla o correrla unos mm.', P.rod.tip)
    '**Bastones Ø12 (2 por unión):** pata de 200 hacia abajo a 66 de la cara del voladizo, tramo recto de 1220 hacia la viga en línea, junto al par de esquina.'
    '**D4: los A1 de D4X van a 62 y 173 (debajo de los de D4Y) y sus bastones a 98.** Correr los estribos del nudo lo necesario.'
    'Estribos del nudo Ø10 en las 16 columnas, cada 75 aprox. (se pueden mover ± 20 para acomodar las barras); deben quedar a 13 o más de anclajes y bastones.'
    '2 estribos Ø14 juntos en los 105 de la columna sobre las vigas, en las 16 columnas. Ganchos Ø16 de la columna hacia el centro, con 40 de recubrimiento a la cara superior.'
    'Sándwich: un estribo Ø10 a cada lado de los anclajes A2; los demás cada 110 desde ellos. A2 entre estribos, paralelos a sus ramas.'
    'Viga D entre 3 y 4: estribos Ø10 cada 110 de 3 a 10 y de 11 a 4; cada 140 entre 10 y 11.'
    ['**Después de fundir:** placas P2 y P3, IPE, tuercas de nivelación y exteriores, grout sin contracción (ASTM C1107, mínimo 280 kg/cm2) similar a SikaGrout-212, 25 bajo P2 y P3. ' ...
     '**Grout y no mortero:** el mortero se retrae al secar y deja la placa sin apoyo; el grout no se contrae, es fluido y llena los 25 sin vacíos, y gana resistencia rápido.']
    ['**Soldaduras viga - placa (detalle 5), todas en obra:** electrodo E70XX de bajo hidrógeno (E7018), soldador calificado según AWS D1.1. ' ...
     'Ala superior: penetración completa (CJP) en todo el ancho, con bisel en el ala, junta precalificada AWS D1.1 (con respaldo, o resanando la raíz por debajo y rematando), sin agujeros de acceso. ' ...
     'Ala inferior: filete de 6 por fuera en todo el ancho y por dentro de la punta del ala al inicio del radio. Alma: filete de 6 a ambos lados en la parte recta. ' ...
     '**No soldar en los radios entre ala y alma.** Limpiar óxido y pintura antes de soldar. Inspección visual del 100 %; la CJP, además con tintes penetrantes o ultrasonido.']
    'La columna se funde hasta el fondo de las vigas; nudo, vigas y cabeza de columna en una sola fundida.'
    '**Losa: verter el hormigón simultáneamente a ambos lados de las vigas de los ejes 4 y D**, avanzando parejo a cada lado, para no cargar esas vigas en torsión.'};
end

% =====================================================================
%  Helpers (copied from ../cantilever_anchor_bolted_plate/make_pour_sheets.m)
% =====================================================================
function out = iif(c, a, b)
  if c, out = a; else, out = b; end
end

function F = title_fields(opts)
  T = opts.titleblock;
  F = cell(1, size(T, 1));
  for i = 1:size(T, 1), F{i} = {T{i,1}, strrep(T{i,2}, '\n', char(10))}; end
end

function Q = fillet(Q0, r, n)
  if nargin < 3, n = 10; end
  N = size(Q0, 1);  Q = Q0(1,:);
  for i = 2:N-1
    A = Q0(i-1,:);  Bv = Q0(i,:);  C = Q0(i+1,:);
    u1 = (A - Bv)/norm(A - Bv);  u2 = (C - Bv)/norm(C - Bv);
    th = acos(max(-1, min(1, u1*u2')));
    if r <= 0 || th > pi - 1e-6, Q = [Q; Bv]; continue; end
    t = r/tan(th/2);  T1 = Bv + u1*t;
    Cc = Bv + (u1 + u2)/norm(u1 + u2)*r/sin(th/2);
    T2 = Bv + u2*t;
    a1 = atan2(T1(2) - Cc(2), T1(1) - Cc(1));  a2 = atan2(T2(2) - Cc(2), T2(1) - Cc(1));
    da = mod(a2 - a1 + pi, 2*pi) - pi;
    a = a1 + da*(0:n)'/n;
    Q = [Q; Cc(1) + r*cos(a), Cc(2) + r*sin(a)];
  end
  Q = [Q; Q0(N,:)];
end

function Q = arcp(c, r, a1, a2, n)
  if nargin < 5, n = 10; end
  a = (a1 + (a2 - a1)*(0:n)'/n)*pi/180;  Q = [c(1) + r*cos(a), c(2) + r*sin(a)];
end

function Q = rotp(Q, deg, c)
  a = deg*pi/180;  Rm = [cos(a) -sin(a); sin(a) cos(a)];
  Q = (Q - c)*Rm' + c;
end

function it = d_path(Q, d, s)
  k = [true; any(abs(diff(Q)) > 1e-9, 2)];  Q = Q(k,:);  N = size(Q, 1);
  T = zeros(N, 2);
  for i = 1:N
    t = Q(min(i+1, N),:) - Q(max(i-1, 1),:);  T(i,:) = t/norm(t);
  end
  Nn = [-T(:,2) T(:,1)];  sc = ones(N, 1);
  for i = 2:N-1
    s1 = Q(i,:) - Q(i-1,:);  s1 = s1/norm(s1);
    sc(i) = 1/max(Nn(i,:)*[-s1(2); s1(1)], 0.5);
  end
  it = d_poly([Q + Nn.*(d/2*sc); flipud(Q - Nn.*(d/2*sc))], s);
end

function it = d_bar(x0, y0, x1, y1, d, s)
  it = d_path([x0 y0; x1 y1], d, s);
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

function it = d_text(x, y, txt, s, a)
  it = struct('t', 'text', 'p', [x y], 'txt', txt, 's', s, 'a', a);
end

function it = d_arrow(x0, y0, x1, y1)
  % leader with a filled arrowhead at (x1, y1)
  u = [x1 - x0, y1 - y0];  u = u/norm(u);  n = [-u(2) u(1)];  p = [x1 y1];  a = 22;  w = 7;
  it = {d_line(x0, y0, x1 - u(1)*a, y1 - u(2)*a, 'lead'), d_poly([p; p - a*u + w*n; p - a*u - w*n], 'leadf')};
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

function b = blk_note(text)
  b = struct('k', 'note', 't', text);
end

function b = blk_table(head, rows, widths, right, red)
  b = struct('k', 'table', 'head', {head}, 'rows', {rows}, 'w', widths, ...
             'right', {right}, 'red', {red});
end
