function file = make_pour_sheets(P, R, outdir, opts)
% MAKE_POUR_SHEETS  Placement sheets (Spanish) of everything set before the joint is poured.
%   Connections named by their column (user 2026-10-04): C4 (type E), B4 and D3 (type C1),
%   D4X / D4Y (types CX / CY, corner D4). Sections, in reading order of the A2 sheet:
%   1  key plan: grid lines, beams, the 5 cantilevers
%   2  one cantilever (C4, B4, D3): view from outside, section, column hooks (plan, 3D, side), plan at A1
%   3  corner D4 (D4X east, D4Y south): plan, section, column hooks (plan, 3D, side)
%   4  beam bars in the joint at D4
%   5  beam bars in the joint at B4, C4 (VCM above grid 4) and D3 (VCM under grid D)
%   6  all the beam bars at C4, section of the VCM, bastón
%   7  pieces (anchors with nuts, back plate, closed tie 14, joint ties), tolerances, quantities, notes
%
% opts.n     number of connections of each type, [E C1 CX CY] = [C4, B4 + D3, D4X, D4Y]
% opts.ncol  number of columns that carry a steel column (closed ties 14)
% Printer: pour_pdf.py (joint_pdf.py with the colours of the report). Units mm.

  B = {};
  an = P.an;  bp = P.bp;  zS = R.typ(1).zS;  zX = an.pf;  zY = an.zH;  g = geo(P);
  ne = opts.n(1) + opts.n(2);  zA2 = round(zS);
  bt = sprintf('Ganchos Ø%g de 90°: pata %g, medida por fuera. Cotas de abajo: desde la cara del voladizo hasta el gancho.', P.cb.db, 5*ceil(16*P.cb.db/5));
  tl = strjoin(arrayfun(@(z) sprintf('%g', z), P.hoop.z, 'UniformOutput', false), ' / ');

  % ---- 1: key plan ---------------------------------------------------------------
  B{end+1} = blk_h(1, 'Anclajes de voladizos IPE 240 - colocación antes de la fundición');
  B{end+1} = blk_h(2, '1. Planta de ubicación');
  B{end+1} = blk_row([0.74 0.26], {{blk_draw(dr_keyplan(P), 115, 'PLANTA DE UBICACIÓN - NIVEL DE LOSA', ...
      sprintf(['%d voladizos IPE 240 (azul). C4, B4 y D3: un voladizo, sección 3. D4: dos voladizos, sección 4. ' ...
               '**Óvalo: la viga en línea lleva 2 bastones Ø%g más** (B4, C4, D3 y D4X), %g mm desde la cara. Detalle 2.3.'], sum(opts.n), P.cb.db, P.cb.bas.L))}, ...
      {blk_draw(dr_beamsec(P, true), 70, 'CORTE A-A: VCM EN C4 Y B4', ...
      sprintf('**Arriba: 7 varillas Ø%g** (5 de la VCM + 2 bastones). Ver detalle 2.2.', P.cb.db))}});

  hk = sprintf('Barras Ø%g de la columna, ganchos de 90°: pata %g, medida por fuera. Oscuro: nivel A, arriba. Claro: nivel B, abajo.', P.col.db, 5*ceil(16*P.col.db/5));
  leg = 'Rojo: anclajes. Azul: placa B1. Verde: estribos Ø14. Colores claros: barras que ya están en la armadura. z = 0: cara superior de las vigas.';

  % ---- 3: one cantilever (C4, B4, D3): complete sections -------------------------------------
  cutnote = sprintf(['Estribos Ø%g del nudo: %d, a cada %g desde %g. Ganchos Ø%g de las vigas: pata %g, medida por fuera. ' ...
                     'Cotas de abajo: desde la cara del voladizo hasta cada gancho.'], P.hoop.db, numel(P.hoop.z), P.hoop.s, max(P.hoop.z), P.cb.db, 5*ceil(16*P.cb.db/5));
  B{end+1} = blk_page();
  B{end+1} = blk_h(1, sprintf('3. Uniones C4, B4 y D3: un voladizo (%d)', ne));
  B{end+1} = blk_p(['Dos anclajes A1 arriba y dos A2 abajo, a los lados del eje del voladizo. ' leg]);
  B{end+1} = blk_draw(dr_cut(P, 'EU'), 92, 'DETALLE 3.1 - B4 Y C4: CORTE POR EL EJE DEL VOLADIZO', ...
      ['**VCM: 5 Ø12 + 2 bastones (naranja) arriba, todas con gancho.** ' cutnote]);
  B{end+1} = blk_draw(dr_cut(P, 'EL'), 92, 'DETALLE 3.2 - D3: CORTE POR EL EJE DEL VOLADIZO', ...
      ['**Eje 3: 3 Ø12 + 2 bastones (naranja) arriba, todas con gancho**, debajo de las del eje D. ' cutnote]);
  B{end+1} = blk_p(sprintf('**Estribos Ø%g: dos debajo de los anclajes (%+g y %+g); estribo cerrado Ø%g encima (%+g; en D4 %+g).** Los anclajes A1 se apoyan sobre el Ø%g de %+g (tuercas delanteras de B1 con una cara plana abajo) y **B1 queda pegada a ese estribo**. Barras de las vigas: todas con gancho, contra los estribos de la columna.', P.top.db, P.top.z, P.t10.db, P.t10.z, P.t10.zD4, P.top.db, P.top.zu));
  B{end+1} = blk_page();                            % section 3 goes on in the next column
  B{end+1} = blk_row([0.5 0.5], {{blk_draw(dr_front(P, zX, zS), 52, 'DETALLE 3.3 - C4, B4 Y D3: VISTA DESDE AFUERA', 'La cara de la columna donde llega el voladizo.')}, ...
      {blk_draw(dr_plan1(P), 52, 'DETALLE 3.4 - C4, B4 Y D3: PLANTA A LA ALTURA DE LOS ANCLAJES A1', 'Los anclajes A2 van justo debajo de los A1.')}});
  B{end+1} = blk_row([0.5 0.5], {{blk_draw(dr_hooks(P, 'E'), 62, 'DETALLE 3.5 - C4, B4 Y D3: GANCHOS DE LA COLUMNA, PLANTA', ...
      [hk ' Nivel A: a lo largo de los anclajes. **Nivel B: de lado a lado, apoyado sobre los anclajes A1.**'])}, ...
      {blk_draw(dr_hooks3d(P, 'E'), 62, 'DETALLE 3.6 - C4, B4 Y D3: GANCHOS EN 3D', ...
      'Parte superior de las 8 barras de la columna. Oscuro: nivel A, arriba, a lo largo de los A1. Claro: nivel B, sobre los A1.')}});
  B{end+1} = blk_draw(dr_hookside(P, 'E'), 52, 'DETALLE 3.7 - C4, B4 Y D3: GANCHOS, VISTA LATERAL', ...
      'Nivel A: esquinas y centrales, a lo largo de los anclajes A1, recubrimiento superior 20. Nivel B: laterales, de lado a lado, apoyado sobre los A1.');

  % ---- 4: corner D4 -------------------------------------------------------------------------
  B{end+1} = blk_page();
  B{end+1} = blk_h(1, '4. Esquina D4: dos voladizos (D4X este, D4Y sur)');
  B{end+1} = blk_p(['Los anclajes A1 de los dos voladizos se cruzan. **Los de D4Y van encima de los de D4X.** ' leg]);
  B{end+1} = blk_draw(dr_plan4(P), 62, 'DETALLE 4.1 - D4: PLANTA', ...
      '**Eje D: 5 Ø12 arriba** (gris, arriba). **Eje 4: 3 Ø12 + 2 bastones** (azul y naranja, abajo). Los anclajes A2 van debajo de los A1.');
  B{end+1} = blk_draw(dr_cut(P, 'X'), 88, 'DETALLE 4.2 - D4: CORTE POR D4X (ESTE)', ...
      ['**Eje 4: 3 Ø12 + 2 bastones, todas con gancho.** Círculos rojos: anclajes de D4Y, cortados. ' cutnote]);
  B{end+1} = blk_draw(dr_cut(P, 'Y'), 88, 'DETALLE 4.3 - D4: CORTE POR D4Y (SUR)', ...
      ['**Eje D: las 5 superiores con gancho.** Círculos rojos: anclajes de D4X, cortados. ' cutnote]);
  B{end+1} = blk_page();                            % section 4 goes on in the next column
  B{end+1} = blk_row([0.5 0.5], {{blk_draw(dr_hooks(P, 'D4'), 72, 'DETALLE 4.4 - D4: GANCHOS DE LA COLUMNA, PLANTA', hk)}, ...
      {blk_draw(dr_hooks3d(P, 'D4'), 72, 'DETALLE 4.5 - D4: GANCHOS EN 3D', ...
      'Oscuro: nivel A, arriba, este-oeste. Claro: nivel B, norte-sur, sobre los A1 de D4X.')}});
  B{end+1} = blk_row([0.56 0.44], {{blk_draw(dr_hookside(P, 'D4'), 54, 'DETALLE 4.6 - D4: GANCHOS, VISTA LATERAL', ...
      'Vista desde el este.')}, ...
      {blk_h(2, 'Ganchos en D4'), ...
       blk_p('Colocar los ganchos después de los anclajes A1 y amarrarlos a ellos.'), ...
       blk_p(sprintf('**Nivel B (%+g):** las centrales norte y sur, sobre los anclajes A1 de D4X, al lado de los de D4Y.', P.col.zhB)), ...
       blk_p(sprintf('**Nivel A (%+g):** esquinas y centrales este y oeste, encima, a lo largo de los A1 de D4X. Recubrimiento superior %g.', P.col.top - P.col.ctop - P.col.db/2, P.col.ctop))}});

  % ---- 2: all the beam bars at C4, section, bastón -------------------------------------------
  B{end+1} = blk_page();
  B{end+1} = blk_h(1, '2. Barras de las vigas en C4 y B4');
  B{end+1} = blk_draw(dr_allbars(P), 96, 'DETALLE 2.1 - C4 Y B4: PLANTA CON TODAS LAS BARRAS DE LAS VIGAS', ...
      '**VCM: 7 Ø12 arriba** (5 + 2 bastones naranja). Las inferiores van debajo de las mismas líneas. **B4: igual.**');
  B{end+1} = blk_row([0.42 0.58], {{blk_draw(dr_beamsec(P), 66, 'DETALLE 2.2 - C4 Y B4: CORTE A-A DE LA VCM', ...
      '**Arriba: 7 varillas Ø12** (5 + 2 bastones). Corte en la viga, junto a la columna.')}, ...
      {blk_draw(dr_bastonbar(P), 34, sprintf('DETALLE 2.3 - BASTÓN Ø%g (8: 2 EN B4, C4, D3 Y D4X)', P.cb.db), ...
      sprintf('Gancho junto a la cara del voladizo, %g mm detrás del de la barra vecina. Entra %g mm en la viga en línea.', P.cb.bas.uh - P.cb.uh - P.cb.db, P.cb.bas.L))}});

  % ---- 8: pieces, ties, quantities, tolerances, notes ----------------------------------------
  B{end+1} = blk_page();
  B{end+1} = blk_h(1, '6. Piezas, estribos, cantidades y notas');
  B{end+1} = blk_row([0.6 0.4], {{blk_draw(dr_asm(P), 48, 'DETALLE 6.1 - ANCLAJES ARMADOS', ...
      'Medidas desde el extremo de afuera. Línea discontinua: cara de la columna.')}, ...
      {blk_draw(dr_backplate(P), 40, sprintf('DETALLE 6.2 - PLACA B1, PL %gx%gx%g A36', bp.t, bp.h, bp.w), sprintf('2 agujeros Ø%g.', an.hole))}});
  B{end+1} = blk_row([0.33 0.33 0.34], {{blk_draw(dr_tie14(P), 52, sprintf('DETALLE 6.3 - ESTRIBO CERRADO Ø%g', P.top.db), ...
      sprintf('Medidas exteriores. 2 por columna, debajo de los anclajes: %+g y %+g (los A1 se apoyan sobre este).', P.top.z))}, ...
      {blk_draw(dr_jtie_closed(P), 52, sprintf('DETALLE 6.4 - ESTRIBO DEL NUDO Ø%g', P.hoop.db), ...
      sprintf('Estribo cerrado normal. Medidas exteriores. En el nudo: %d, a cada %g desde %g. Uno más encima de los anclajes: %+g (D4: %+g).', numel(P.hoop.z), P.hoop.s, max(P.hoop.z), P.t10.z, P.t10.zD4))}, ...
      {blk_draw(dr_jtie(P), 52, 'DETALLE 6.5 - OPCIÓN: ESTRIBO EN 4 PIEZAS', ...
      sprintf('**Solo si no entra el estribo cerrado 6.4.** 4 piezas Ø%g con ganchos de 135°, colocadas una por una.', P.hoop.db))}});
  B{end+1} = blk_row([0.5 0.5], {{blk_h(2, 'Tolerancias'), tol_table(P)}, {}});
  rows = pour_quantities(P, opts);
  B{end+1} = blk_h(2, 'Cantidades (antes de la fundición)');
  B{end+1} = blk_table({'Marca', 'Elemento', 'Descripción', 'Por conexión', 'Total'}, rows, [0.08 0.18 0.54 0.11 0.09], [4 5], []);
  B{end+1} = blk_h(2, 'Notas');
  notes = {
    'Medidas en mm. z: nivel desde la cara superior (terminado) de las vigas (z = 0).'
    sprintf('Anclajes A1 y A2: varilla roscada %s %s, similar a la de Global Pernos. Tuercas grado 8 o A194 2H. **No usar varilla de ferretería.**', an.thr, an.grade)
    sprintf('Estribos Ø%g: **dos, debajo de los anclajes** (%+g y %+g), antes que los anclajes; el de %+g bajo las tuercas delanteras de B1. **Estribo cerrado Ø%g encima de los anclajes** (%+g; D4: %+g), después de los anclajes. En **todas** las columnas con columna metálica.', P.top.db, P.top.z, P.top.zu, P.t10.db, P.t10.z, P.t10.zD4)
    'La obra hace la plantilla para fijar los anclajes, con las tolerancias de este plano.'
    'Armar en banco cada anclaje A1 con la placa B1 y sus tuercas (detalle 6.1).'
    sprintf('Ganchos de la columna: después de los anclajes. **El nivel B se apoya y se amarra sobre los anclajes A1** (en D4, los de D4X); el nivel A va encima, a lo largo de los A1. **Recubrimiento superior %g.**', P.col.ctop)
    sprintf('Barras de esquina de las vigas (arriba y abajo): en la viga van a ±%g del eje; **dentro del nudo se corren %g mm hacia adentro (a ±%g)** para pasar pegadas a los pernos de la columna metálica, y se amarran a ellos.', P.cb.vbm, P.cb.vbm - max(P.cb.v), max(P.cb.v))
    sprintf('El estribo Ø%g de %+g **sostiene** los anclajes A1. Revisar los niveles antes de fundir. No mover las barras para hacer espacio.', P.top.db, P.top.zu)
    sprintf('**Fundir vigas, nudo y pedestal juntos, hasta +%g. Sin juntas frías.** La losa se funde después.', P.col.top)
    '**Hormigón f''c = 240 kg/cm2 en vigas, nudo y pedestal. Piedra de 10 mm máximo (3/8"). Vibrador de 25 mm**, sin tocar anclajes ni placas. Vibrar hasta ver hormigón alrededor de la placa B1.'
    sprintf('**Barras inferiores de las vigas en los nudos de los voladizos: solo las 2 de esquina con gancho hacia arriba**, a %g mm de la cara. La central: recta, %g mm dentro del nudo. Las otras 2 de las VCM terminan en la cara de la columna.', P.cb.ubh, P.cb.Lst)
    'No soldar anclajes ni placas a las barras. Proteger las roscas con cinta.'
    'Al desencofrar, medir dónde quedó cada anclaje. La placa extremo se perfora con esas medidas.'
    sprintf('Grout bajo la placa extremo (después, láminas de taller): sin contracción, mínimo 280 kg/cm2, similar a SikaGrout-212. Espesor %g mm.', P.g)};
  for i = 1:numel(notes), B{end+1} = blk_p(sprintf('%d. %s', i, notes{i})); end

  % ---- 7: through rods AV of the IPE 200 floor beams, cast in the VCM ---------------------------
  B{end+1} = blk_page();
  s2 = P.s2;  Lr = 10*ceil((s2.vb + 2*(s2.pl(1) + s2.wsh(2) + s2.nut(1) + s2.pp))/10);
  B{end+1} = blk_h(1, sprintf('5. Conexión a corte de las vigas %s: varillas pasantes AV', s2.name));
  B{end+1} = blk_p(sprintf(['VCM de los ejes A, B, C y D, entre los ejes 3 y 4: donde llegan las vigas %s. ' ...
      '**4 varillas Ø%g por apoyo, 32 en total.** La placa PV y la viga van después (lámina de taller).'], s2.name, s2.db));
  B{end+1} = blk_draw(dr_s2_elev(P), 50, sprintf('DETALLE 5.1 - CONEXIÓN A CORTE %s: CARA DE LA VCM', s2.name), ...
      'VCM: 5 Ø12 arriba y 5 Ø12 abajo (2 líneas cada una). Línea punteada: placa PV, va después.');
  B{end+1} = blk_row([0.45 0.55], {{blk_draw(dr_s2_cross(P), 55, sprintf('DETALLE 5.2 - CONEXIÓN A CORTE %s: CORTE POR LAS VARILLAS', s2.name), ...
      '**Las superiores van sobre las 5 barras superiores de la VCM, amarradas a ellas**, entre estribos.')}, ...
      {blk_draw(dr_s2_rodasm(P), 36, 'DETALLE 5.3 - VARILLA AV ARMADA', ...
      sprintf('Medidas desde un extremo. Línea discontinua: caras de la VCM. A cada lado: placa PV (después), arandela y tuerca %s.', s2.thr))}});
  B{end+1} = blk_p('**Colocar antes de fundir la VCM**, atravesando el encofrado, con plantilla.');
  B{end+1} = blk_p(sprintf('**No cortar estribos ni barras.** Correr los estribos de ese tramo a ±%g del eje de la viga.', s2.stir));
  B{end+1} = blk_p('Proteger las roscas con cinta.');

  sheets = {'Ubicación', 'Uniones C4, B4, D3', 'Esquina D4', 'Vigas D4', 'Vigas B4, C4, D3', 'Barras C4', 'Piezas y notas', 'Varillas AV'};
  page = 'A4';  fs = 0.9;
  if isfield(opts, 'page') && any(strcmp(opts.page, {'A2L', 'A1L'}))
    % one A2 landscape sheet: the A4 pages become panels, two per column, drawings scaled by opts.hk;
    % the notes of section 7 go under it in the last column
    pg = {};  cur = {};
    for i = 1:numel(B)
      if strcmp(B{i}.k, 'page'), pg{end+1} = cur;  cur = {}; else, cur{end+1} = B{i}; end
    end
    pg{end+1} = cur;
    hkp = ones(1, numel(pg));  if isfield(opts, 'hkp'), hkp = opts.hkp; end      % extra factor per section (page as built)
    for i = 1:numel(pg), pg{i} = scale_blocks(pg{i}, opts.hk*hkp(i)); end
    % opts.layout: one cell per sheet, one entry per column: the sections (pages) in that column
    B = {};
    for k = 1:numel(opts.layout)
      L = opts.layout{k};  cols = cell(1, numel(L));
      for c = 1:numel(L), cols{c} = [pg{L{c}}]; end
      if k > 1, B{end+1} = blk_page(); end
      B{end+1} = blk_row(opts.colw, cols);
    end
    sheets = opts.sheetnames;  page = opts.page;  fs = opts.fs;
  end
  tbh = 30;  tbk = 1;  if isfield(opts, 'tbh'), tbh = opts.tbh;  tbk = opts.tbk; end
  doc = struct('title', 'Anclajes de voladizos - colocación', 'page', page, 'fs', fs, 'blocks', {B}, ...
               'frame', struct('fields', {title_fields(opts)}, 'widths', tb_widths(opts), ...
                               'h', tbh, 'tb', tbk, 'subtitle', opts.subtitle, 'sheets', {sheets}));
  base = fullfile(outdir, 'planos_colocacion_anclajes');
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
%  Key plan
% =====================================================================
function G = grid_lines()
  % grid lines of the floor plan (user's plan, 2026-10-02), mm; origin at B4, x east, y north.
  % Grid A is inclined: x = -1780 at grid 4, about -2400 at grid 1 (not dimensioned on the plan).
  G.xn = {'B', 'C', 'D', 'E'};  G.x = [0 4780 9560 10830];
  G.yn = {'9', '4', '3', '2', '1'};  G.y = [-1270 0 4330 5730 9750];
  G.A = [-1780 0; -2400 9750];                      % grid A: points at grid 4 and grid 1
end

function x = xA(G, y)
  x = G.A(1,1) + (G.A(2,1) - G.A(1,1))*(y - G.A(1,2))/(G.A(2,2) - G.A(1,2));
end

function it = dr_keyplan(P)
  G = grid_lines();  c = P.col.b/2;  bw = 300;  r = 330;  ext = 900;
  y9 = G.y(1);  y4 = G.y(2);  y3 = G.y(3);  y2 = G.y(4);  y1 = G.y(5);
  xB = G.x(1);  xC = G.x(2);  xD = G.x(3);  xE = G.x(4);
  it = {};
  % grid lines and bubbles
  yb = y9 - ext;  yt = y1 + ext;  xl = xA(G, y1) - ext;  xr = xE + ext;
  it{end+1} = d_line(xA(G, yb), yb, xA(G, yt), yt, 'axis');
  it{end+1} = d_circle(xA(G, yb), yb - r, r, 'bubble');  it{end+1} = d_text(xA(G, yb), yb - r - 90, 'A', 'grid', 'middle');
  for i = 1:numel(G.x)
    y0 = yb;  if strcmp(G.xn{i}, 'E'), y0 = yb; end
    it{end+1} = d_line(G.x(i), y0, G.x(i), yt, 'axis');
    it{end+1} = d_circle(G.x(i), yb - r, r, 'bubble');  it{end+1} = d_text(G.x(i), yb - r - 90, G.xn{i}, 'grid', 'middle');
  end
  for j = 1:numel(G.y)
    it{end+1} = d_line(xl, G.y(j), xr, G.y(j), 'axis');
    it{end+1} = d_circle(xr + r, G.y(j), r, 'bubble');  it{end+1} = d_text(xr + r, G.y(j) - 90, G.yn{j}, 'grid', 'middle');
  end
  % concrete beams 30x35 (drawn 300 wide), along the rows and along A, B, C, D
  for y = [y4 y3 y2 y1]
    it{end+1} = d_rectxy(xA(G, y), y - bw/2, xD, y + bw/2, 'beam');
  end
  it{end+1} = d_poly([xA(G, y4) - bw/2, y4; xA(G, y1) - bw/2, y1; xA(G, y1) + bw/2, y1; xA(G, y4) + bw/2, y4], 'beam');
  for x = [xB xC xD], it{end+1} = d_rectxy(x - bw/2, y4, x + bw/2, y1, 'beam'); end
  % steel beams IPE 200 between grids 3 and 4 (thirds), from A to D, drawn 100 wide
  for y = y4 + (y3 - y4)*[1 2]/3, it{end+1} = d_rectxy(xA(G, y), y - 50, xD, y + 50, 'tab'); end
  % columns 40x40
  for y = [y4 y3 y2 y1]
    for x = [xA(G, y) xB xC xD], it{end+1} = d_rectxy(x - c, y - c, x + c, y + c, 'column'); end
  end
  % cantilevers IPE 240 (flange 120) and the slab edge
  bf = P.bm.b;
  for x = [xB xC xD], it{end+1} = d_rectxy(x - bf/2, y9, x + bf/2, y4 - c, 'plate'); end
  for y = [y4 y3], it{end+1} = d_rectxy(xD + c, y - bf/2, xE, y + bf/2, 'plate'); end
  it{end+1} = d_poly([xD + c, y3 + 60; xE, y3 + 60; xE, y9; xB - bw/2, y9; xB - bw/2, y9 + 1; xE - 1, y9 + 1; xE - 1, y3 + 59; xD + c, y3 + 59], 'edge');
  % section names
  ls = 'label';
  for x = (xB + xC)/2 + [0 4780]
    for y = [y4 y3 y2 y1], it{end+1} = d_text(x, y + 230, 'VCS 30x35', ls, 'middle'); end
  end
  for y = [y4 y3 y2 y1], it{end+1} = d_text((xA(G, y) + xB)/2, y + 230, 'VCS', 'small', 'middle'); end
  for x = [xB xC xD]
    it{end+1} = struct('t', 'text', 'p', [x - 230, (y4 + y3)/2], 'txt', 'VCM 30x35', 's', ls, 'a', 'middle', 'r', 90);
    it{end+1} = struct('t', 'text', 'p', [x - 230, (y2 + y1)/2], 'txt', 'VCS 30x35', 's', ls, 'a', 'middle', 'r', 90);
  end
  it{end+1} = struct('t', 'text', 'p', [xA(G, (y4 + y3)/2) - 230, (y4 + y3)/2], 'txt', 'VCM 30x35', 's', ls, 'a', 'middle', 'r', 90);
  for k = 1:2
    y = y4 + (y3 - y4)*k/3;  it{end+1} = d_text((xB + xC)/2, y + 110, 'IPE 200', 'small', 'middle');
    it{end+1} = d_text((xA(G, y) + xB)/2, y + 110, 'IPE 200', 'small', 'middle');
    it{end+1} = d_text((xC + xD)/2, y + 110, 'IPE 200', 'small', 'middle');
  end
  for x = [xB xC xD]
    it{end+1} = struct('t', 'text', 'p', [x + 330, (y9 + y4)/2 - 50], 'txt', 'IPE 240', 's', 'code', 'a', 'middle', 'r', 90);
  end
  for y = [y4 y3], it{end+1} = d_text((xD + c + xE)/2, y - 330, 'IPE 240', 'code', 'middle'); end
  it{end+1} = d_text((xB + xC)/2, y9 - 280, 'borde de losa', 'small', 'middle');
  % connection types
  it{end+1} = d_text(xB - 420, y4 - 650, 'B4', 'red', 'end');
  it{end+1} = d_text(xC - 420, y4 - 650, 'C4', 'red', 'end');
  it{end+1} = d_text(xD + 420, y4 - 800, 'D4X / D4Y', 'red', 'start');
  it{end+1} = d_text((xD + c + xE)/2, y3 + 230, 'D3', 'red', 'middle');
  % bastones (user 2026-10-04): one on each side of the beam in line, with its pata at the column, the beam
  % ringed by a dashed tomato oval; one comment for the three (C4, D3, D4X)
  yb0 = y4 + c;  Lb = P.cb.bas.L;  off = 380;
  S3 = {[xB yb0], [0 1];  [xC yb0], [0 1];  [xD - c y3], [-1 0];  [xD - c y4], [-1 0]};   % column face, direction into the beam
  for k = 1:size(S3, 1)
    p0 = S3{k,1};  e = S3{k,2};  n = [-e(2) e(1)];
    for sg = [-1 1]
      q0 = p0 + sg*off*n + 60*e;  q1 = q0 + Lb*e;
      it{end+1} = d_path([q0; q1], 70, 'r_bas');                          % bastón, beside its beam
    end
    m = p0 + (Lb/2 + 60)*e;  t = linspace(0, 2*pi, 49)';
    E2 = m + (Lb/2 + 260)*cos(t)*e + (off + 180)*sin(t)*n;
    for j = 2:numel(t), it{end+1} = d_line(E2(j-1,1), E2(j-1,2), E2(j,1), E2(j,2), 'r_oval'); end
  end
  xt = xB + 1500;  yt = y4 + 2450;                  % in the free bay B-C, between the IPE 200
  it{end+1} = d_text(xt, yt, sprintf('Armado de la viga\n+ 2 bastones Ø%g', P.cb.db), 'red', 'start');
  ym = yb0 + Lb/2 + 60;
  it{end+1} = d_line(xt - 30, yt - 150, xB + off + 180, ym, 'r_oval_l');
  it{end+1} = d_line(xt + 2000, yt - 150, xC - off - 180, ym, 'r_oval_l');
  it{end+1} = d_line(xt + 2600, yt + 80, xD - c - Lb/2 - 60, y3 - off - 180, 'r_oval_l');
  it{end+1} = d_line(xt + 2600, yt - 150, xD - c - Lb/2 - 60, y4 + off + 180, 'r_oval_l');
  ya = yb0 + 300;
  for sg = [-1 1], it{end+1} = d_line(xC + sg*230, ya, xC + sg*420, ya, 'arrow');  it{end+1} = d_text(xC + sg*500, ya - 50, 'A', 'code', 'middle'); end
  % dimensions
  yd = yb - 2*r - 500;
  it{end+1} = d_dim(xA(G, y4), y4, xB, y4, -(y4 - yd) + 0, sprintf('%g', xB - xA(G, y4)));
  for i = 1:numel(G.x) - 1
    it{end+1} = d_dim(G.x(i), yd, G.x(i+1), yd, 0, sprintf('%g', G.x(i+1) - G.x(i)));
  end
  xd = xr + 2*r + 450;
  for j = 1:numel(G.y) - 1
    it{end+1} = d_dim(xd, G.y(j), xd, G.y(j+1), 0, sprintf('%g', G.y(j+1) - G.y(j)));
  end
end

% =====================================================================
%  Placement drawings. Section and plan: u from the outer face of the column, into it
%  (beam side u < 0). Styles r_* come from pour_pdf.py: strong colours for what is placed
%  for the cantilevers, faint for what is already in the cage.
% =====================================================================
function g = geo(P)
  g.hb = P.col.b/2;  d = P.col.db;
  g.rc = P.col.cover + P.col.dtie + d/2;          % column bar axis from a face (58)
  g.xc = g.hb - g.rc;                              % same from the column axis (142)
  g.rt = g.rc - d/2 - P.top.db/2;                  % closed ties 14 wrap the bars: axis 43 from a face
  g.rh = g.rc - d/2 - P.hoop.db/2;                 % joint ties 10: axis 45 from a face
  g.zA = P.col.top - P.col.ctop - d/2;             % column hooks, level A (+72: along the anchors (of X), top cover 20)
  g.zB = P.col.zhB;                                % level B (+45): across, resting on the A1 (of X)
  g.rb = 3.5*d;                                    % bend radius at the bar axis (inside 6 d)
  g.tl = 12*d;                                     % tail
  g.ht = g.rb + g.tl;                              % bar axis to the end of the tail
end

function Q = fillet(Q0, r, n)
  % round the corners of the polyline Q0 (N x 2) with radius r at the bar axis
  if nargin < 3, n = 10; end
  N = size(Q0, 1);  Q = Q0(1,:);
  for i = 2:N-1
    A = Q0(i-1,:);  Bv = Q0(i,:);  C = Q0(i+1,:);
    u1 = (A - Bv)/norm(A - Bv);  u2 = (C - Bv)/norm(C - Bv);
    th = acos(max(-1, min(1, u1*u2')));
    if r <= 0 || th > pi - 1e-6, Q = [Q; Bv]; continue; end
    t = r/tan(th/2);  T1 = Bv + u1*t;  T2 = Bv + u2*t;
    Cc = Bv + (u1 + u2)/norm(u1 + u2)*r/sin(th/2);
    a1 = atan2(T1(2) - Cc(2), T1(1) - Cc(1));  a2 = atan2(T2(2) - Cc(2), T2(1) - Cc(1));
    da = mod(a2 - a1 + pi, 2*pi) - pi;
    a = a1 + da*(0:n)'/n;
    Q = [Q; Cc(1) + r*cos(a), Cc(2) + r*sin(a)];
  end
  Q = [Q; Q0(N,:)];
end

function Q = arcp(c, r, a1, a2, n)
  % points of an arc, angles in degrees
  if nargin < 5, n = 10; end
  a = (a1 + (a2 - a1)*(0:n)'/n)*pi/180;  Q = [c(1) + r*cos(a), c(2) + r*sin(a)];
end

function it = d_path(Q, d, s)
  % bar of diameter d along the polyline Q (N x 2), as one polygon
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

function Q = rotp(Q, deg, c)
  a = deg*pi/180;  Rm = [cos(a) -sin(a); sin(a) cos(a)];
  Q = (Q - c)*Rm' + c;
end

function it = colhook(g, x, z0, zh, s, d, st)
  % column bar in elevation: vertical from z0 to the hook level zh, tail towards s = -1 / +1
  it = d_path(fillet([x z0; x zh; x + s*g.ht zh], g.rb), d, st);
end

function it = beamhook(P, xR, ux, zt, st)
  % beam top bar from xR to a 90 degree hook down, axis of the hook at u = ux
  db = P.cb.db;  r = 3.5*db;
  it = d_path(fillet([xR zt; ux zt; ux zt - r - 12*db], r), db, st);
end

function it = a1_items(P, zT)
  % one top anchor A1 with its nuts and washer, along +u from u = -out
  an = P.an;  bp = P.bp;  it = {};
  it{end+1} = d_bar(-an.out, zT, an.uT, zT, an.db, 'r_anc');
  it{end+1} = d_rectxy(bp.u - an.tnut, zT - an.nut/2, bp.u, zT + an.nut/2, 'r_nut');
  it{end+1} = d_rectxy(bp.u + bp.t, zT - an.wsh/2, bp.u + bp.t + an.twsh, zT + an.wsh/2, 'r_nut');
  it{end+1} = d_rectxy(bp.u + bp.t + an.twsh, zT - an.nut/2, bp.u + bp.t + an.twsh + an.tnut, zT + an.nut/2, 'r_nut');
end

function it = a2_items(P, zS)
  an = P.an;  ue = an.uS + an.twsh + an.tnut + an.pp;  it = {};
  it{end+1} = d_bar(-an.outS, zS, ue, zS, an.db, 'r_anc');
  it{end+1} = d_rectxy(an.uS, zS - an.wsh/2, an.uS + an.twsh, zS + an.wsh/2, 'r_nut');
  it{end+1} = d_rectxy(an.uS + an.twsh, zS - an.nut/2, an.uS + an.twsh + an.tnut, zS + an.nut/2, 'r_nut');
end

function it = ep_side(P)
  % end plate of the IPE 240 with its 2 extra plates, and the grout pad, in a section along the
  % cantilever (u, z): transparent, no labels (they go on after the pour)
  tp = P.ep.t;  g = P.g;  zt = P.ep.ztop;  zb = -P.bm.h - P.ep.under;
  it = {d_rectxy(-g, zb - 10, 0, zt + 10, 'r_grout'), d_rectxy(-g - tp, zb, -g, zt, 'r_eplate'), ...
        d_rectxy(-g, 0, -g + P.dbl.t, zt, 'r_eplate')};
end

function it = ep_plan(P)
  % the same in plan (u, v)
  tp = P.ep.t;  g = P.g;  w = P.ep.w/2;  gp = P.dbl.gap/2;
  it = {d_rectxy(-g, -w - 15, 0, w + 15, 'r_grout'), d_rectxy(-g - tp, -w, -g, w, 'r_eplate'), ...
        d_rectxy(-g, gp, -g + P.dbl.t, w, 'r_eplate'), d_rectxy(-g, -w, -g + P.dbl.t, -gp, 'r_eplate')};
end

function it = ep_front(P)
  % the same seen from outside (v, z): grout pad and end plate
  w = P.ep.w/2;  zt = P.ep.ztop;  zb = -P.bm.h - P.ep.under;
  it = {d_rectxy(-w - 15, zb - 10, w + 15, zt + 10, 'r_grout'), d_rectxy(-w, zb, w, zt, 'r_eplate')};
end

function it = dr_front(P, zT, zS)
  % type E / C1 seen from outside: h across the face, z up
  g = geo(P);  hb = g.hb;  an = P.an;  cj = P.col.cj;  top = P.col.top;  bw = 70;  it = {};
  it{end+1} = d_rectxy(-hb, cj, hb, top, 'r_conc');
  for sg = [-1 1]
    it{end+1} = d_rectxy(sg*hb, -P.cb.h, sg*(hb + bw), 0, 'r_concb');
    it{end+1} = d_text(sg*(hb + bw/2), -P.cb.h/2, 'VCS', 'small', 'middle');
  end
  % bars already in the cage: crossing VCS, joint ties, column bars and hooks, rods
  for z = [P.cb.zt(1) P.cb.zbc], it{end+1} = d_bar(-hb - bw, z, hb + bw, z, P.cb.db, 'r_ex'); end
  for z = P.hoop.z, it{end+1} = d_bar(-(hb - g.rh), z, hb - g.rh, z, P.hoop.db, 'r_tie'); end
  for sg = [-1 1], it{end+1} = colhook(g, sg*g.xc, cj, g.zB, -sg, P.col.db, 'r_col'); end   % side mid bars (B), behind
  for h = [-1 0 1]*g.xc, it{end+1} = d_bar(h, cj, h, g.zA - g.rb, P.col.db, 'r_col'); end      % corners, front mid (A): into the page
  for h = [-1 0 1]*g.xc, it{end+1} = d_circle(h, g.zA - g.rb/2, P.col.db/2, 'r_col'); end
  for h = [-1 1]*P.rod.p, it{end+1} = d_bar(h, cj, h, top + 60, P.rod.db, 'r_rod'); end   % anchored > 1 m below
  % placed for the cantilever; end plate and grout pad (later) for reference
  for z = P.top.z, it{end+1} = d_bar(-(hb - g.rt), z, hb - g.rt, z, P.top.db, 'r_new'); end
  it = [it, ep_front(P)];
  for z = [zT zS], for h = [-1 1]*an.vT, it{end+1} = d_circle(h, z, an.db/2 + 1, 'r_anc'); end, end
  it{end+1} = d_line(-hb - bw - 20, 0, hb + bw + 20, 0, 'axis');
  % dimensions
  it{end+1} = d_dim(-hb, cj, -an.vT, cj, -22, sprintf('%g', hb - an.vT));
  it{end+1} = d_dim(-an.vT, cj, an.vT, cj, -22, sprintf('%g', 2*an.vT));
  it{end+1} = d_dim(an.vT, cj, hb, cj, -22, sprintf('%g', hb - an.vT));
  it{end+1} = d_dim(-hb, cj, hb, cj, -50, sprintf('%g', 2*hb));
  xl = -hb - bw - 20;
  it{end+1} = d_dim(xl, zS, xl, 0, 10, sprintf('%.0f', -zS));
  it{end+1} = d_dim(xl, 0, xl, zT, 10, sprintf('%g', zT), 'before');
  it{end+1} = d_dim(xl, zT, xl, top, 10, sprintf('%g', top - zT));
  % what the dimensions measure: short labels left of them
  xt = xl - 45;
  it{end+1} = d_text(xt, top - 4, 'cara superior', 'small', 'end');
  it{end+1} = d_text(xt, zT - 4, 'eje A1', 'small', 'end');
  it{end+1} = d_text(xt, -4, 'z = 0', 'small', 'end');
  it{end+1} = d_text(xt, zS - 4, 'eje A2', 'small', 'end');
  for z = [top zT 0 zS], it{end+1} = d_line(xt + 4, z, xl - 12, z, 'dim'); end
  % labels
  it{end+1} = d_text(an.vT + 14, zT + 10, 'A1', 'anc', 'start');
  it{end+1} = d_text(an.vT + 14, zS + 10, 'A2', 'anc', 'start');
  it{end+1} = d_text(0, top + 70, sprintf('pernos Ø%g de la columna metálica', P.rod.db), 'small', 'middle');
end

function it = dr_sect(P, zT, zS, cs)
  % section along the axis of the cantilever (u to the right). cs = 'E': B4 and C4, the VCM in
  % line above the bars of grid 4; 'Y': south cantilever of D4, with the A1 and A2 of the east
  % cantilever cut, the VCM of grid D above the bars of grid 4. Its 2 extra bars at P.cb.zp.
  g = geo(P);  b = P.col.b;  an = P.an;  bp = P.bp;  cj = P.col.cj;  top = P.col.top;  xR = b + 230;
  cy = strcmp(cs, 'Y');  cx = strcmp(cs, 'X');  it = {};   % 'X': D4X, the A1 / A2 of D4Y cut
  it{end+1} = d_rectxy(0, cj, b, top, 'r_conc');
  it{end+1} = d_rectxy(b, -P.cb.h, xR, 0, 'r_concb');
  it{end+1} = d_text(b + 115, -P.cb.h/2 - 30, 'VCM', 'small', 'middle');
  it = [it, ep_side(P)];
  % VCM in line: 2 top bars hooked down, one under the other; bottom bars straight
  ti = 1;  zt = P.cb.zt(ti);  ux = P.cb.uh + P.cb.db/2;
  if P.cb.bas.on && ~cy, it{end+1} = beamhook(P, xR, P.cb.bas.uh + P.cb.db/2, P.cb.bas.z, 'r_bas'); end   % bastón (C4 only), behind
  it{end+1} = beamhook(P, xR, ux + P.cb.db, P.cb.zp, 'r_bm2');
  it{end+1} = beamhook(P, xR, ux, zt, 'r_bm1');
  ubx = P.cb.ubh + P.cb.db/2;  rbx = 3.5*P.cb.db;
  it{end+1} = d_path(fillet([xR P.cb.zbl; ubx P.cb.zbl; ubx P.cb.zbl + rbx + 12*P.cb.db], rbx), P.cb.db, 'r_bm4');
  % crossing VCS, cut
  for v = P.cb.v, it{end+1} = d_circle(g.hb + v, P.cb.zt(3 - ti), P.cb.db/2, 'r_ex'); end
  for v = P.cb.vbot, it{end+1} = d_circle(g.hb + v, P.cb.zbc, P.cb.db/2, 'r_ex'); end
  % column bars and hooks
  if cy                                             % D4Y: the south and north mid bars hooked along the cut (level B,
    it{end+1} = colhook(g, g.rc, cj, g.zB, 1, P.col.db, 'r_col');       % on the A1 of X); level A east-west, cut
    it{end+1} = colhook(g, b - g.rc, cj, g.zB, -1, P.col.db, 'r_col');
    it{end+1} = d_bar(g.hb, cj, g.hb, g.zA, P.col.db, 'r_col');
    for u = [g.rc, g.rc + 16, g.hb + [-8 8], b - g.rc - 16, b - g.rc], it{end+1} = d_circle(u, g.zA, P.col.db/2, 'r_col'); end
  else                                              % E: front and far mid bars hooked along the cut (level A);
    it{end+1} = colhook(g, g.rc, cj, g.zA, 1, P.col.db, 'r_col');       % side mid bars across, over the A1 (B)
    it{end+1} = colhook(g, b - g.rc, cj, g.zA, -1, P.col.db, 'r_col');
    it{end+1} = d_bar(g.hb, cj, g.hb, g.zB, P.col.db, 'r_col');
    for u = g.hb + [-8 8], it{end+1} = d_circle(u, g.zB, P.col.db/2, 'r_col'); end
  end
  for u = g.hb + [-1 1]*P.rod.p, it{end+1} = d_bar(u, cj, u, top + 60, P.rod.db, 'r_rod'); end   % anchored > 1 m below
  for z = P.hoop.z, for u = [g.rh b - g.rh], it{end+1} = d_circle(u, z, P.hoop.db/2, 'r_tie'); end, end
  for z = P.top.z, for u = [g.rt b - g.rt], it{end+1} = d_circle(u, z, P.top.db/2, 'r_new'); end, end
  z10 = P.t10.z;  if cy || cx, z10 = P.t10.zD4; end   % closed tie 10 over the anchors (D4: over the Y anchors too)
  for u = [g.rh b - g.rh], it{end+1} = d_circle(u, z10, P.t10.db/2, 'r_tie'); end
  % anchors
  it = [it, a1_items(P, zT), a2_items(P, zS)];
  it{end+1} = d_rectxy(bp.u, zT - bp.h/2, bp.u + bp.t, zT + bp.h/2, 'r_bp');
  it{end+1} = d_line(-150, 0, xR + 40, 0, 'axis');
  % dimensions
  it{end+1} = d_dim(-an.out, top, 0, top, 24, sprintf('%g', an.out));
  it{end+1} = d_dim(0, top, bp.u, top, 24, sprintf('%g', bp.u));
  it{end+1} = d_dim(bp.u, top, bp.u + bp.t, top, 24, sprintf('%g', bp.t));
  it{end+1} = d_dim(-an.outS, cj, 0, cj, -22, sprintf('%g', an.outS));
  it{end+1} = d_dim(0, cj, an.uS, cj, -22, sprintf('%g', an.uS));
  it{end+1} = d_dim(0, cj, b, cj, -60, sprintf('%g', b));
  it{end+1} = d_dim(-110, zS, -110, 0, 0, sprintf('%.0f', -zS));
  it{end+1} = d_dim(-140, 0, -140, zT, 0, sprintf('%g', zT));
  if cy                                             % A1 and A2 of the east cantilever, cut
    zo = an.pf;  uo = g.hb + [-1 1]*an.vT;
    for z = [zo zS], for u = uo, it{end+1} = d_circle(u, z, an.db/2 + 1, 'r_anc'); end, end
    it{end+1} = d_dim(0, cj, uo(1), cj, -100, sprintf('%g', uo(1)));
    it{end+1} = d_dim(uo(1), cj, uo(2), cj, -140, sprintf('%g', diff(uo)));
    it{end+1} = d_dim(uo(2), cj, b, cj, -100, sprintf('%g', b - uo(2)));
    it{end+1} = d_dim(b, zS, b, 0, -14, sprintf('%.0f', -zS));
    it{end+1} = d_dim(b, 0, b, zo, -14, sprintf('%g', zo));
    it{end+1} = d_text(uo(2) + 14, zo - 22, 'A1 D4X', 'anc', 'start');
    it{end+1} = d_text(uo(2) + 14, zS - 22, 'A2 D4X', 'anc', 'start');
  end
  if cx                                             % D4X: A1 (+45) and A2 of D4Y cut
    zo = an.zH;  uo = g.hb + [-1 1]*an.vT;
    for z = [zo zS], for u = uo, it{end+1} = d_circle(u, z, an.db/2 + 1, 'r_anc'); end, end
    it{end+1} = d_text(uo(2) + 30, zo + 30, 'A1 D4Y', 'anc', 'start');
    it{end+1} = d_text(uo(2) + 14, zS - 22, 'A2 D4Y', 'anc', 'start');
  end
  % labels
  it{end+1} = d_text(-an.out, zT + 16, 'A1', 'anc', 'start');
  it{end+1} = d_text(-an.outS, zS + 16, 'A2', 'anc', 'start');
  it{end+1} = d_text(bp.u + bp.t + 6, zT + bp.h/2 + 6, 'B1', 'anc', 'start');
  zl14 = min(P.top.z) - 24;
  it{end+1} = d_text(b - g.rt - 12, zl14, sprintf('Ø%g', P.top.db), 'new', 'end');
  % levels as a dimension chain from the top of the beams (user 2026-10-05: dimensions, no level numbers),
  % right of the column; thin lines from each bar to the chain, a short name beside it
  xd = b + 34;
  zc_ = [P.hoop.z, P.top.z, 0, z10, g.zA, top];  nm = [repmat({sprintf('Ø%g', P.hoop.db)}, 1, numel(P.hoop.z)), ...
        repmat({sprintf('Ø%g', P.top.db)}, 1, numel(P.top.z)), {'cara sup. vigas', sprintf('Ø%g cerrado', P.t10.db), 'ganchos A', 'cara superior'}];
  [zc_, k] = sort(zc_);  nm = nm(k);
  it = [it, d_chain(xd, zc_, 28)];
  xn = xd + 3*28 + 8;  zn = [];  kn = [];
  for k = 1:numel(zc_)
    if zc_(k) ~= 0 && zc_(k) ~= top, it{end+1} = d_line(b - 40, zc_(k), xn - 6, zc_(k), 'dim'); end
    if zc_(k) > -60 && zc_(k) ~= 0 && zc_(k) ~= top, zn(end+1) = zc_(k);  kn(end+1) = k; end
  end
  zq = zn;  for k = 2:numel(zq), zq(k) = max(zq(k), zq(k-1) + 30); end   % names at least 30 apart, short leaders
  for k = 1:numel(zn)
    it{end+1} = d_line(xn - 6, zn(k), xn, zq(k) + 4, 'dim');
    it{end+1} = d_text(xn + 2, zq(k) - 4, nm{kn(k)}, 'small', 'start');
  end
  it{end+1} = d_text(xn + 2, mean(P.hoop.z(2:3)) - 4, sprintf('estribos Ø%g', P.hoop.db), 'small', 'start');
  it{end+1} = d_text(xR - 5, -118, sprintf('5 Ø%g superiores:\ntodas con gancho', P.cb.db), 'bsm', 'end');
  it{end+1} = d_text(xR - 5, P.cb.zbl + P.cb.db + 4, sprintf('5 Ø%g; 2 con gancho', P.cb.db), 'small', 'end');
  it{end+1} = d_text(-5, cj + 45, 'cara de la columna', 'small', 'end');
  it{end+1} = d_text(-155, -4, 'cara sup. vigas', 'small', 'end');
end

function it = jtie_closed(P, cx, cy, st)
  % joint tie Ø10 as a normal closed tie around the corner bars, both 135 degree hooks at one corner
  g = geo(P);  c = g.xc;  r = P.col.db/2 + P.hoop.db/2;  e = max(6*P.hoop.db, 75);  w = [1 1]/sqrt(2);
  BL = [-c -c];  BR = [c -c];  TR = [c c];  TL = [-c c];
  a0 = arcp(BL, r, 135, 270);  a5 = arcp(BL, r, 180, 315);
  Q1 = [a0(1,:) + e*w; a0; arcp(BR, r, -90, 0); arcp(TR, r, 0, 90); arcp(TL, r, 90, 180)];
  Q2 = [Q1(end,:); a5; a5(end,:) + e*w];
  it = {d_path(Q1 + [cx cy], P.hoop.db, st), d_path(Q2 + [cx cy], P.hoop.db, st)};
end

function it = tie14(P, cx, cy)
  % closed tie 14 around the corner bars, both 135 degree hooks at the corner (-,-); drawn as two
  % paths so that the overlap at the hooks stays filled
  g = geo(P);  c = g.xc;  r = P.col.db/2 + P.top.db/2;  e = max(6*P.top.db, 75);  w = [1 1]/sqrt(2);
  BL = [-c -c];  BR = [c -c];  TR = [c c];  TL = [-c c];
  a0 = arcp(BL, r, 135, 270);  a5 = arcp(BL, r, 180, 315);
  Q1 = [a0(1,:) + e*w; a0; arcp(BR, r, -90, 0); arcp(TR, r, 0, 90); arcp(TL, r, 90, 180)];
  Q2 = [Q1(end,:); a5; a5(end,:) + e*w];
  it = {d_path(Q1 + [cx cy], P.top.db, 'r_new'), d_path(Q2 + [cx cy], P.top.db, 'r_new')};
end

function Q = jtie_leg(P, k)
  % straight joint tie on face k (1 south, 2 east, 3 north, 4 west), 135 degree hooks around the
  % two corner bars, column axis at (0, 0)
  g = geo(P);  c = g.xc;  r = P.col.db/2 + P.hoop.db/2;  e = max(6*P.hoop.db, 75);
  aL = arcp([-c -c], r, 135, 270);  aR = arcp([c -c], r, -90, 45);
  Q = [aL(1,:) + e*[1 1]/sqrt(2); aL; aR; aR(end,:) + e*[-1 1]/sqrt(2)];
  Q = rotp(Q, 90*(k - 1), [0 0]);
end

function it = col_plan(P, cx, cy, ties, bars)
  % column outline, bars, rods of the steel column and the closed tie 14, in plan
  if nargin < 5, bars = true; end
  g = geo(P);  hb = g.hb;  it = {d_rectxy(cx - hb, cy - hb, cx + hb, cy + hb, 'r_conc')};
  if bars, for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, it{end+1} = d_circle(cx + sx*g.xc, cy + sy*g.xc, P.col.db/2, 'r_col'); end
  end, end, end
  for sx = [-1 1], for sy = [-1 1], it{end+1} = d_circle(cx + sx*P.rod.p, cy + sy*P.rod.p, P.rod.db/2, 'r_rod'); end, end
  if ties, it = [it, tie14(P, cx, cy)]; end
end

function it = rot_items(it, f)
  % map every point of the items with f([x y]) -> [x y]
  for i = 1:numel(it)
    p = it{i}.p;
    if strcmp(it{i}.t, 'circle'), p(1:2) = f(p(1:2));
    else, for k = 1:2:numel(p), p(k:k+1) = f(p(k:k+1)); end, end
    it{i}.p = p;
  end
end

function it = a1_plan(P, faint)
  % the two A1 of one cantilever with their back plate, in plan (x = u, y = v)
  an = P.an;  bp = P.bp;  it = {};
  for v = [-1 1]*an.vT, it = [it, a1_items(P, v)]; end
  it{end+1} = d_rectxy(bp.u, -bp.w/2, bp.u + bp.t, bp.w/2, 'r_bp');
  if faint, for i = 1:numel(it), it{i}.s = 'r_ancg'; end, end
end

function it = dr_plan1(P)
  % plan at the level of the A1, one cantilever from the left (x = u, y = v)
  g = geo(P);  hb = g.hb;  b = P.col.b;  an = P.an;  bp = P.bp;  bw = P.cb.b/2;  it = {};
  it{end+1} = d_rectxy(b, -bw, b + 120, bw, 'r_concb');
  it{end+1} = d_rectxy(-180, -P.bm.b/2, -P.g - P.ep.t, P.bm.b/2, 'r_steel');
  it = [it, ep_plan(P)];
  it = [it, col_plan(P, hb, 0, true), a1_plan(P, false)];
  it{end+1} = d_dim(0, -hb, 0, -an.vT, 230, sprintf('%g', hb - an.vT));
  it{end+1} = d_dim(0, -an.vT, 0, an.vT, 230, sprintf('%g', 2*an.vT));
  it{end+1} = d_dim(0, an.vT, 0, hb, 230, sprintf('%g', hb - an.vT));
  it{end+1} = d_dim(-an.out, hb, 0, hb, 20, sprintf('%g', an.out));
  it{end+1} = d_dim(0, hb, bp.u, hb, 20, sprintf('%g', bp.u));
  it{end+1} = d_dim(0, hb, b, hb, 70, sprintf('%g', b));
  it{end+1} = d_text(bp.u + bp.t + 6, bp.w/2 + 8, 'B1', 'anc', 'start');
  it{end+1} = d_text(-an.out, an.vT + 16, 'A1', 'anc', 'start');
  it{end+1} = d_text(-110, -P.bm.b/2 - 30, 'IPE 240 (después)', 'small', 'middle');
  it{end+1} = d_text(b + 60, 0, 'VCM', 'small', 'middle');
end

function it = dr_plan2(P)
  % corner D4 in plan, north up, column axis at (0, 0): cantilever X from the east, Y from the south
  g = geo(P);  hb = g.hb;  an = P.an;  bw = P.cb.b/2;  it = {};
  it{end+1} = d_rectxy(-hb - 230, -bw, -hb, bw, 'r_concb');
  it{end+1} = d_rectxy(-bw, hb, bw, hb + 230, 'r_concb');
  e0 = P.g + P.ep.t + hb;
  it{end+1} = d_rectxy(e0, -P.bm.b/2, hb + 330, P.bm.b/2, 'r_steel');
  it{end+1} = d_rectxy(-P.bm.b/2, -hb - 330, P.bm.b/2, -e0, 'r_steel');
  it = [it, rot_items(ep_plan(P), @(p) [hb - p(1), p(2)]), rot_items(ep_plan(P), @(p) [p(2), p(1) - hb])];
  it = [it, col_plan(P, 0, 0, true)];
  it = [it, rot_items(a1_plan(P, false), @(p) [hb - p(1), p(2)])];     % east: u along -x
  it = [it, rot_items(a1_plan(P, false), @(p) [p(2), p(1) - hb])];     % south: u along +y
  it{end+1} = d_dim(-hb, -hb, -an.vT, -hb, -40, sprintf('%g', hb - an.vT));
  it{end+1} = d_dim(-an.vT, -hb, an.vT, -hb, -80, sprintf('%g', 2*an.vT));
  it{end+1} = d_dim(an.vT, -hb, hb, -hb, -40, sprintf('%g', hb - an.vT));
  it{end+1} = d_dim(hb, -hb, hb, -an.vT, -40, sprintf('%g', hb - an.vT));
  it{end+1} = d_dim(hb, -an.vT, hb, an.vT, -80, sprintf('%g', 2*an.vT));
  it{end+1} = d_dim(hb, an.vT, hb, hb, -40, sprintf('%g', hb - an.vT));
  it{end+1} = d_text(hb + 100, 100, 'A1 D4X (abajo)', 'anc', 'start');
  it{end+1} = d_text(75, -hb - 150, 'A1 D4Y (encima)', 'anc', 'start');
  it{end+1} = d_text(-hb - 115, bw + 14, 'eje 4', 'small', 'middle');
  it{end+1} = d_text(bw + 10, hb + 115, 'VCM eje D', 'small', 'start');
  it{end+1} = d_text(hb + 230, -P.bm.b/2 - 20, 'IPE 240 (después)', 'small', 'middle');
  it{end+1} = d_text(-hb - 60, hb + 200, 'N', 'grid', 'middle');
  it{end+1} = d_line(-hb - 60, hb + 120, -hb - 60, hb + 180, 'arrow');
end

function [o, H] = hook_table(P, cs)
  % column top hooks. 'E': x = u, y = v, column axis at (200, 0); 'D4': north up, column axis at
  % (0, 0). Rows: x, y (bar, from the column axis), tail direction, side offset at the hook, level (1 A, 2 B)
  g = geo(P);  c = g.xc;
  if strcmp(cs, 'E')
    o = [g.hb 0];
    H = [-c 0  1 0  0 -8 1;   c 0 -1 0  0  8 1; ...          % user 2026-10-05: level A along the anchors (front and
         -c -c 1 0  0  0 1;   c -c -1 0 0 16 1; ...          % far mid bars and the corners), level B across, over
         -c c  1 0  0  0 1;   c c  -1 0 0 -16 1; ...         % the A1 (side mid bars). Corner tails: near ones on the
                                                             % bar line, far ones 16 inside (clear of the tie 14 at +64)
          0 -c 0 1 -8  0 2;   0 c  0 -1 8  0 2];
  else
    o = [0 0];
    H = [ c 0 -1 0  0 -8 1;  -c 0  1 0  0  8 1; ...          % user 2026-10-05: as C4, oriented by X (from the east):
          c -c -1 0 0  0 1;  -c -c 1 0  0 16 1; ...          % level A east-west (corners, east and west mid bars),
          c c  -1 0 0  0 1;  -c c  1 0  0 -16 1; ...         % level B north-south (north and south mid bars) on the
          0 -c 0 1  8  0 2;   0 c  0 -1 -8 0 2];             % A1 of X, beside those of Y
  end
end

function it = dr_hooks(P, cs)
  % plan of the column top hooks (see hook_table); the bars of level B are under the level-A tails
  % and are not drawn as dots
  g = geo(P);  hb = g.hb;  an = P.an;  it = {};
  [o, H] = hook_table(P, cs);
  if strcmp(cs, 'E')
    it = [it, col_plan(P, o(1), o(2), false, false), a1_plan(P, true)];
  else
    it = [it, col_plan(P, 0, 0, false, false)];
    it = [it, rot_items(a1_plan(P, true), @(p) [hb - p(1), p(2)]), rot_items(a1_plan(P, true), @(p) [p(2), p(1) - hb])];
  end
  st = {'r_hkA', 'r_hkB', 'r_hkA'};  lv = {'A', 'B', 'C'};  C = {};
  for L = [2 1 3]                                   % level B first, level A over it, level C (D4) on top
    for i = find(H(:,7) == L)'
      p0 = o + H(i,1:2) + H(i,5:6);  p1 = p0 + g.ht*H(i,3:4);
      it{end+1} = d_bar(p0(1), p0(2), p1(1), p1(2), P.col.db, st{L});
      if L ~= 2, C{end+1} = d_circle(p0(1), p0(2), P.col.db/2 + 1, st{L}); end
      q = p1 + 14*H(i,3:4) + 10*sign(H(i,5:6));
      it{end+1} = d_text(q(1), q(2) - 4, lv{L}, 'hk', 'middle');
    end
  end
  it = [it, C];
  it{end+1} = d_dim(o(1) - hb, o(2) - hb, o(1) + hb, o(2) - hb, -24, sprintf('%g', P.col.b));
  it{end+1} = d_dim(o(1) + hb, o(2) - hb, o(1) + hb, o(2) + hb, -24, sprintf('%g', P.col.b));
  if strcmp(cs, 'E')
    it{end+1} = d_text(o(1) - hb - 30, 0, 'cara del voladizo', 'small', 'end');
  else
    it{end+1} = d_text(-hb - 50, hb + 60, 'N', 'grid', 'middle');
    it{end+1} = d_line(-hb - 50, hb - 10, -hb - 50, hb + 45, 'arrow');
  end
end

function it = dr_hooks3d(P, cs)
  % the top of the Ø16 column bars with their hooks, in 3D (oblique view, depth into the page):
  % 'E' seen from the cantilever face, 'D4' seen from the south
  g = geo(P);  hb = g.hb;  d = P.col.db;  dz = 170;  it = {};
  [o, H] = hook_table(P, cs);
  if strcmp(cs, 'E')
    dep = @(x, y) x;  hor = @(x, y) y;              % into the page: u (0 at the cantilever face)
  else
    dep = @(x, y) y + hb;  hor = @(x, y) x;         % into the page: from the south face
  end
  % isometric: the across axis to the right and up, the depth axis to the left and up, z true
  pr = @(x, y, z) [0.866*(hor(x, y) - dep(x, y)), z + 0.5*(hor(x, y) + dep(x, y))];
  % column top: top face and the front edges (thin)
  sq = o + hb*[-1 -1; 1 -1; 1 1; -1 1; -1 -1];
  if strcmp(cs, 'E'), sq = o + hb*[-1 -1; -1 1; 1 1; 1 -1; -1 -1]; end
  for i = 1:4
    a = pr(sq(i,1), sq(i,2), P.col.top);  b = pr(sq(i+1,1), sq(i+1,2), P.col.top);
    it{end+1} = d_line(a(1), a(2), b(1), b(2), 'cut');
  end
  for i = 1:4
    a = pr(sq(i,1), sq(i,2), P.col.top);  b = pr(sq(i,1), sq(i,2), g.zB - dz);
    it{end+1} = d_line(a(1), a(2), b(1), b(2), 'cut');
  end
  % bars and the A1: pieces in 3D, drawn far to near where their pictures overlap (view from
  % -dep, -hor, +z: the depth of a point is dep + hor - z). Each hook in two pieces, the straight
  % leg and the bend with its tail, so that a leg can sit behind an A1 while its tail passes over it
  zl = [g.zA g.zB];  st = {'r_hkA', 'r_hkB'};  t = linspace(0, pi/2, 10)';
  O = struct('it', {}, 'X', {}, 'r', {});  lab = {};
  for i = 1:size(H, 1)
    p0 = o + H(i,1:2) + H(i,5:6);  dr = H(i,3:4);  zh = zl(H(i,7));  rb = g.rb;
    cxy = p0 + dr*rb;
    L3 = [p0, zh - dz; p0, zh - rb + 1];               % 1 mm into the bend: no hairline at the joint
    B3 = [cxy(1) - dr(1)*rb*cos(t), cxy(2) - dr(2)*rb*cos(t), zh - rb + rb*sin(t); p0 + dr*g.ht, zh];
    O(end+1) = piece3d(L3, d, st{H(i,7)}, [1 0], pr);
    O(end+1) = piece3d(B3, d, st{H(i,7)}, [0 1], pr);
    e = pr(p0(1) + dr(1)*g.ht, p0(2) + dr(2)*g.ht, zh);
    lab{end+1} = d_text(e(1) + 8, e(2) + 6, char('A' + H(i,7) - 1), 'hk', 'start');
  end
  [Oa, la] = a1_3d(P, cs, pr);
  O = [O, Oa];  lab = [lab, la];
  it = [it, paint3d(O, pr, dep, hor), lab];
  % orientation
  a = pr(o(1), o(2) - hb, g.zB - dz);
  if strcmp(cs, 'E')
    f = pr(0, 0, g.zB - dz - 30);
    it{end+1} = d_text(f(1), f(2) - 20, 'cara del voladizo (adelante)', 'small', 'middle');
  else
    f = pr(0, -hb, g.zB - dz - 30);
    it{end+1} = d_text(f(1), f(2) - 20, 'cara sur (adelante); norte hacia atrás', 'small', 'middle');
  end
  b = pr(o(1) + hb, o(2) + hb, P.col.top);
  it{end+1} = d_text(b(1) + 10, b(2) + 10, 'cara superior', 'small', 'start');
end

function [O, lab] = a1_3d(P, cs, pr)
  % the A1 with their back plate B1 for the 3D view of the hooks, as pieces for paint3d.
  % 'E': x = u, y = v; 'D4': A1 from the east face at z = an.pf, from the south face at z = an.zH
  an = P.an;  bp = P.bp;  hb = P.col.b/2;  O = struct('it', {}, 'X', {}, 'r', {});  lab = {};
  if strcmp(cs, 'E')
    S = {@(u, v) [u, v], an.pf};
  else
    S = {@(u, v) [hb - u, v], an.pf;  @(u, v) [v, u - hb], an.zH};
  end
  for k = 1:size(S, 1)
    m = S{k,1};  z = S{k,2};
    % back plate: a box, its points fill the volume
    [uu, vv, zz] = ndgrid(linspace(bp.u, bp.u + bp.t, 3), linspace(-bp.w/2, bp.w/2, 25), linspace(z - bp.h/2, z + bp.h/2, 10));
    X = zeros(numel(uu), 3);
    for j = 1:numel(uu), X(j,:) = [m(uu(j), vv(j)), zz(j)]; end
    O(end+1) = struct('it', {box3d(P, m, z, pr)}, 'X', X, 'r', 1);
    for v = [-1 1]*an.vT
      O(end+1) = piece3d([m(-an.out, v), z; m(bp.u, v), z], an.db, 'r_anc', [1 1], pr);    % in front of B1
      O(end+1) = piece3d([m(bp.u + bp.t, v), z; m(an.uT, v), z], an.db, 'r_anc', [1 1], pr);   % behind it
    end
    q = m(-an.out, an.vT);  pt = pr(q(1), q(2), z);
    lab{end+1} = d_text(pt(1) + 10, pt(2) - 4, 'A1', 'anc', 'start');
  end
end

function it = box3d(P, m, z, pr)
  % the three faces of the back plate turned to the viewer (from -dep, -hor, +z)
  bp = P.bp;  U = [bp.u, bp.u + bp.t];  V = [-1 1]*bp.w/2;  Z = z + [-1 1]*bp.h/2;  it = {};
  C = zeros(8, 2);  W = zeros(8, 3);  n = 0;
  for a = 1:2, for b = 1:2, for c = 1:2
    n = n + 1;  q = m(U(a), V(b));  C(n,:) = pr(q(1), q(2), Z(c));  W(n,:) = [q, Z(c)];
  end, end, end
  F = {[2 4 8 6], [1 3 7 5], [1 3 4 2], [5 7 8 6], [1 2 6 5], [3 4 8 7]};
  dv = viewdir(pr);
  % a face is seen when its centre is nearer the viewer than the centre of the box
  for f = 1:numel(F)
    w = mean(W(F{f},:)) - mean(W);                  % outward normal of the face (box axes)
    if w*dv' < -1e-9, Q = C(F{f}, :);  it{end+1} = d_poly([Q; Q(1,:)], 'r_bp'); end
  end
end

function dv = viewdir(pr)
  % direction of view in the world (x, y, z): the vector that projects to zero, pointing away from
  % the viewer (the depth of a point grows along it), from the projection pr
  J = zeros(2, 3);  s0 = pr(0, 0, 0);
  for k = 1:3, e = zeros(1, 3);  e(k) = 1;  J(:,k) = (pr(e(1), e(2), e(3)) - s0)'; end
  dv = null(J)';
  % sign: up (+z) must be towards the viewer
  if dv(3) > 0, dv = -dv; end
end

function O = piece3d(Q3, d, s, caps, pr)
  % one piece of a bar along the 3D polyline Q3 (N x 3): its picture (fill without the end lines
  % where caps = 0, so that two pieces of one bar join without a seam) and sample points
  Q2 = zeros(size(Q3, 1), 2);
  for j = 1:size(Q3, 1), Q2(j,:) = pr(Q3(j,1), Q3(j,2), Q3(j,3)); end
  it = {d_path(Q2, d, s)};
  if ~all(caps)
    pts = reshape(it{1}.p, 2, []).';  n = size(pts, 1)/2;
    it{1}.s = [s 'f'];                              % fill only
    it = [it, d_pline(pts(1:n,:), [s 'e']), d_pline(pts(n+1:end,:), [s 'e'])];
    if caps(1), it = [it, d_pline(pts([2*n 1],:), [s 'e'])]; end
    if caps(2), it = [it, d_pline(pts([n n+1],:), [s 'e'])]; end
  end
  % samples every 3 mm along the axis
  X = Q3(1,:);
  for j = 2:size(Q3, 1)
    L = norm(Q3(j,:) - Q3(j-1,:));  k = max(1, ceil(L/3));
    X = [X; Q3(j-1,:) + (1:k)'/k*(Q3(j,:) - Q3(j-1,:))];
  end
  O = struct('it', {it}, 'X', X, 'r', d/2);
end

function it = d_pline(Q, s)
  % open polyline as line items
  it = {};
  for j = 2:size(Q, 1), it{end+1} = d_line(Q(j-1,1), Q(j-1,2), Q(j,1), Q(j,2), s); end
end

function it = paint3d(O, pr, dep, hor)
  % painter's order of the 3D pieces: where two pictures overlap, the piece farther from the
  % viewer there is drawn first; the rest by mean depth
  n = numel(O);  S = cell(n, 1);  K = cell(n, 1);  km = zeros(n, 1);
  for i = 1:n
    X = O(i).X;  S{i} = zeros(size(X, 1), 2);  K{i} = zeros(size(X, 1), 1);
    for j = 1:size(X, 1)
      S{i}(j,:) = pr(X(j,1), X(j,2), X(j,3));  K{i}(j) = dep(X(j,1), X(j,2)) + hor(X(j,1), X(j,2)) - X(j,3);
    end
    km(i) = mean(K{i});
  end
  E = false(n);                                     % E(i, j): i before j
  for i = 1:n-1, for j = i+1:n
    D2 = (S{i}(:,1) - S{j}(:,1)').^2 + (S{i}(:,2) - S{j}(:,2)').^2;
    [a, b] = find(D2 < (O(i).r + O(j).r)^2);
    if isempty(a), continue; end
    vt = sum(sign(K{i}(a) - K{j}(b)));
    if vt > 0, E(i,j) = true; elseif vt < 0, E(j,i) = true; end
  end, end
  done = false(n, 1);  it = {};
  for step = 1:n
    free = find(~done & ~any(E(~done, :), 1)');
    if isempty(free), free = find(~done); end       % a cycle: farthest first
    [~, k] = max(km(free));  k = free(k);
    done(k) = true;  E(k,:) = false;
    it = [it, O(k).it];
  end
end

function it = dr_bplan(P, cs, solid)
% top bars of the beams through the joint, in plan. 'E': x = u, y = v (column axis at (200, 0)),
% VCM in line on the far side, VCS crossing on both sides. 'D4': north up, column axis at (0, 0),
% VCM of grid 4 from the west (lower layer), VCM of grid D from the north (upper layer)
if nargin < 3, solid = false; end
g = geo(P);  hb = g.hb;  cb = P.cb;  d = cb.db;  L = 430;  bw = cb.b/2;  it = {};
uh = cb.uh + d/2;  uh0 = cb.uh0 + d/2;              % hook axes from the face: corner bars, centre bar
if strcmp(cs, 'E')
  it{end+1} = d_rectxy(P.col.b, -bw, P.col.b + 230, bw, 'r_concb');
  it{end+1} = d_rectxy(hb - bw, hb, hb + bw, L, 'r_concb');
  it{end+1} = d_rectxy(hb - bw, -L, hb + bw, -hb, 'r_concb');
  it = [it, col_plan(P, hb, 0, false), a1_plan(P, true), ep_plan(P)];
  it = [it, jtie_closed(P, hb, 0, 'r_tieS')];
  for v = cb.v, it{end+1} = d_bar(hb + v, -L, hb + v, L, d, 'r_bm3'); end          % grid 4 (lower layer), through
  for v = cb.v                                                                       % VCM in line (upper layer), hooked at the face
    u0 = uh;  if v == 0, u0 = uh0; end
    it{end+1} = d_bar(P.col.b + 230, v, u0, v, d, 'r_bm1');
    it{end+1} = d_circle(u0, v, d/2 + 2, 'r_bm1');
  end
  it{end+1} = d_dim(0, -L, uh - d/2, -L, -18, sprintf('%g', cb.uh), 'before');
  it{end+1} = d_dim(0, L, uh0 - d/2, L, 18, sprintf('%g', cb.uh0));
  it{end+1} = d_dim(hb, -L, hb + cb.v(3), -L, -18, sprintf('%g', cb.v(3)));
  it{end+1} = d_dim(hb + cb.v(1), -L, hb, -L, -18, sprintf('%g', -cb.v(1)), 'before');
  it{end+1} = d_text(P.col.b + 20, bw + 20, 'VCM en línea (arriba)', 'small', 'start');
  it{end+1} = d_text(hb + bw + 10, L - 30, 'eje 4 (abajo)', 'small', 'start');
  it{end+1} = d_text(-10, 0, 'cara del voladizo', 'small', 'end');
  it{end+1} = d_text(-10, cb.v(3) + 60, 'ganchos contra los estribos', 'code', 'end');
  [tt, tl] = bar_counts(P, 'E');
  it{end+1} = d_text(-60, L + 60, tt, 'bsm', 'end');
  it{end+1} = d_text(-60, L + 12, strjoin(tl, char(10)), 'small', 'end');
  it{end+1} = d_line(-8, cb.v(3) + 56, uh - 4, cb.v(3) + 4, 'lead');
  for v = cb.v([1 3]), it{end+1} = d_text(P.col.b + 240, v - 4, sprintf('+ 1 Ø%g debajo (%+g)', d, cb.zp), 'small', 'start'); end
  if cb.bas.on                                       % bastones (C4 only): second layer, beside the -80 bars
    for v = cb.bas.v
      it{end+1} = d_bar(P.col.b + 230, v, cb.bas.uh + d/2, v, d, 'r_bas');
      it{end+1} = d_circle(cb.bas.uh + d/2, v, d/2 + 2, 'r_bas');
    end
    it{end+1} = d_text(P.col.b + 20, -bw - 45, sprintf('naranja: 2 bastones Ø%g a %+g (±%g)', d, cb.bas.z, max(cb.bas.v)), 'small', 'start');
  end
else
  it{end+1} = d_rectxy(-hb - L + hb, -bw, -hb, bw, 'r_concb');
  it{end+1} = d_rectxy(-bw, hb, bw, L, 'r_concb');
  it = [it, col_plan(P, 0, 0, false)];
  it = [it, rot_items(ep_plan(P), @(p) [hb - p(1), p(2)]), rot_items(ep_plan(P), @(p) [p(2), p(1) - hb])];
  it = [it, jtie_closed(P, 0, 0, 'r_tieS')];
  it = [it, rot_items(a1_plan(P, ~solid), @(p) [hb - p(1), p(2)]), rot_items(a1_plan(P, ~solid), @(p) [p(2), p(1) - hb])];
  for v = cb.v                                       % grid 4 VCM (lower layer): west to the east face
    x0 = hb - uh;  if v == 0, x0 = hb - uh0; end
    it{end+1} = d_bar(-L, v, x0, v, d, 'r_bm1');
    it{end+1} = d_circle(x0, v, d/2 + 2, 'r_bm1');
  end
  if cb.bas.on                                       % D4X: 2 bastones beside the grid-4 corner bars (-68)
    for v = cb.bas.v
      x0 = hb - (cb.bas.uh + d/2);
      it{end+1} = d_bar(-L, v, x0, v, d, 'r_bas');  it{end+1} = d_circle(x0, v, d/2 + 2, 'r_bas');
    end
  end
  for v = cb.v                                       % grid D VCM (upper layer): north to the south face
    y0 = -hb + uh;  if v == 0, y0 = -hb + uh0; end
    it{end+1} = d_bar(v, L, v, y0, d, 'r_bm3');
    it{end+1} = d_circle(v, y0, d/2 + 2, 'r_bm3');
  end
  it{end+1} = d_dim(hb - uh + d/2, -hb - 30, hb, -hb - 30, -14, sprintf('%g', cb.uh));
  it{end+1} = d_dim(-hb - 30, -hb, -hb - 30, -hb + uh - d/2, 14, sprintf('%g', cb.uh));
  it{end+1} = d_text(-L + 10, bw + 14, 'eje 4 (abajo, 3 barras)', 'small', 'start');
  it{end+1} = d_text(bw + 10, L - 20, 'VCM eje D (arriba)', 'small', 'start');
  for v = cb.v([1 3]), it{end+1} = d_text(v + 10*sign(v), L - 60, sprintf('+ 1 Ø%g debajo (%+g)', d, cb.zp), 'small', ifelse_(v > 0, 'start', 'end')); end
  it{end+1} = d_text(hb + 40, -hb + 40, 'ganchos contra los estribos', 'code', 'start');
  it{end+1} = d_text(-L - 60, -bw - 290, sprintf('Eje D: 5 Ø%g (refuerzo de VCM)', d), 'bsm', 'start');
  it{end+1} = d_text(-L - 60, -bw - 338, sprintf('3 (%+g) + 2 (%+g)', max(cb.zt), cb.zp), 'small', 'start');
  it{end+1} = d_text(-L - 60, -bw - 410, sprintf('Eje 4: 5 Ø%g = 3 Ø%g (refuerzo de VCS)\n+ 2 bastones Ø%g para el nudo', d, d, d), 'bsm', 'start');
  it{end+1} = d_text(-L - 60, -bw - 510, sprintf('(%+g)', min(cb.zt)), 'small', 'start');
  it{end+1} = d_line(hb + 38, -hb + 44, hb - uh + 4, cb.v(1) - 4, 'lead');
  it{end+1} = d_text(-hb - 50, hb + 60, 'N', 'grid', 'middle');
  it{end+1} = d_line(-hb - 50, hb - 10, -hb - 50, hb + 45, 'arrow');
end
end

function it = dr_bsect(P, cs)
% top bars of the beams in a section along a cantilever: 'E' (VCM in line on the lower layer, with
% the 2 bars under its corner bars), 'X' (D4, east: VCM grid 4, lower layer), 'Y' (D4, south: VCM
% grid D, upper layer). The bars of the crossing beam are cut.
g = geo(P);  b = P.col.b;  cb = P.cb;  d = cb.db;  an = P.an;  cj = P.col.cj;  top = P.col.top;  xR = b + 230;
uh = cb.uh + d/2;  uh0 = cb.uh0 + d/2;  r = 3.5*d;  tail = r + 12*d;  it = {};
switch cs
  case 'EU', zi = cb.zt(1);  zc = cb.zt(2);  pair = true;  zA = an.pf;  nin = 'VCM';  ncr = 'eje 4';
  case 'EL', zi = cb.zt(2);  zc = cb.zt(1);  pair = false; zA = an.pf;  nin = 'eje 3';  ncr = 'eje D';   % grid 3: 3 bars only (user)
  case 'X', zi = cb.zt(2);  zc = cb.zt(1);  pair = false; zA = an.pf;  nin = 'eje 4';  ncr = 'eje D';
  case 'Y', zi = cb.zt(1);  zc = cb.zt(2);  pair = true;  zA = an.zH;  nin = 'eje D';  ncr = 'eje 4';
end
it{end+1} = d_rectxy(0, cj, b, top, 'r_conc');
it{end+1} = d_rectxy(b, -cb.h, xR, 0, 'r_concb');
it = [it, a1_items(P, zA), a2_items(P, R_zS(P))];
for i = 1:numel(it), if ~strcmp(it{i}.s, 'r_conc') && ~strcmp(it{i}.s, 'r_concb'), it{i}.s = 'r_ancg'; end, end
it = [it, ep_side(P)];
for i = 1:numel(it), if ~strcmp(it{i}.s, 'r_conc') && ~strcmp(it{i}.s, 'r_concb'), it{i}.s = 'r_ancg'; end, end
rc = g.rc;  zt0 = g.zA;                           % column bars (faint), ties (solid)
for u = [rc b - rc], it{end+1} = d_bar(u, cj, u, zt0, P.col.db, 'r_col'); end
for z = P.hoop.z, for u = [g.rh b - g.rh], it{end+1} = d_circle(u, z, P.hoop.db/2 + 0.5, 'r_tieS'); end, end
for z = P.top.z, for u = [g.rt b - g.rt], it{end+1} = d_circle(u, z, P.top.db/2 + 0.5, 'r_new'); end, end
for v = cb.v, it{end+1} = d_circle(g.hb + v, zc, d/2, 'r_bm3'); end
if any(strcmp(cs, {'X', 'EL'})), for v = cb.v([1 3]), it{end+1} = d_circle(g.hb + v, cb.zp, d/2, 'r_bm3'); end, end   % crossing beam with 5 bars
if cb.bas.on && any(strcmp(cs, {'EU', 'X', 'EL'}))   % bastón: C4 second layer; D3, D4X beside the corner bars (-68)
  ubs = cb.bas.uh + d/2;  zbs = cb.bas.z;  if ~strcmp(cs, 'EU'), zbs = zi; end
  it{end+1} = d_path(fillet([xR zbs; ubs zbs; ubs zbs - tail], r), d, 'r_bas');
end
if pair, it{end+1} = d_path(fillet([xR cb.zp; uh + d cb.zp; uh + d cb.zp - tail], r), d, 'r_bm2'); end
it{end+1} = d_path(fillet([xR zi; uh zi; uh zi - tail], r), d, 'r_bm1');
it{end+1} = d_path(fillet([xR zi; uh0 zi; uh0 zi - tail], r), d, 'r_bm1');
% bottom bars: the beam in line hooked up behind everything (upper bottom layer; D4 grid 4: lower)
zbi = cb.zbl;  zbx = cb.zbc;  if strcmp(cs, 'X'), zbi = cb.zbc;  zbx = cb.zbl; end
ub = cb.ubh + d/2;
for v = cb.vbot, it{end+1} = d_circle(g.hb + v, zbx, d/2, 'r_bm3'); end
if any(strcmp(cs, {'EU', 'Y'})), it{end+1} = d_bar(xR, zbi + d, b, zbi + d, d, 'r_bm3'); end   % the 2 over the corner bars end at the face
it{end+1} = d_path(fillet([xR zbi; ub zbi; ub zbi + tail], r), d, 'r_bm4');
us = b - cb.Lst;                                   % the centre bottom bar ends here (straight)
it{end+1} = d_line(us, zbi - 14, us, zbi + 14, 'dim');
it{end+1} = d_text(us, zbi + 18, 'fin de la central', 'small', 'middle');
it{end+1} = d_line(-60, 0, xR + 30, 0, 'axis');
% dimensions: hook positions under the column (texts of the short ones left of the face), hook
% tails at the left of the column
sp = 48;                                           % spacing of stacked texts (the drawings are small)
o0 = -110;                                         % under the anchor and column dimensions
it{end+1} = d_dim(0, cj, uh - d/2, cj, o0, sprintf('%g', cb.uh), 'before');
it{end+1} = d_dim(0, cj, uh0 - d/2, cj, o0 - sp, sprintf('%g', cb.uh0), 'before');
k = o0 - sp;
if pair, k = k - sp;  it{end+1} = d_dim(0, cj, uh + d/2, cj, k, sprintf('%g', cb.uh + d), 'before'); end
it{end+1} = d_dim(0, cj, ub - d/2, cj, k - sp, sprintf('%g', cb.ubh), 'before');
% the note on the hooks, at the left
zn = zi - tail + 15;                               % the lower end of the hook, under the shear anchors
it{end+1} = d_text(-40, zn - 30, sprintf('gancho contra\nlos estribos'), 'code', 'end');
it{end+1} = d_line(-37, zn - 34, g.rh + 2, zn, 'lead');
it{end+1} = d_text(-5, cj + 40, 'cara del voladizo', 'small', 'end');
it{end+1} = d_text(-60, -4, 'z = 0', 'small', 'end');
% bar counts: a brace over the top bars and one over the bottom bars, with the number in bold
[tt, tl, bt_, bl] = bar_counts(P, cs);
ztop = [zc zi];  if pair || any(strcmp(cs, {'X', 'EL'})), ztop(end+1) = cb.zp; end
zbot = [zbi zbx];  xb = xR + 12;
it = [it, d_brace(xb, min(ztop) - 8, max(ztop) + 8, 22), d_brace(xb, min(zbot) - 8, max(zbot) + 8, 22)];
zt0 = mean(ztop) + 30*numel(tl);                   % the top block sits above the brace tip, clear of the bottom one
it{end+1} = d_line(xb + 24, mean(ztop), xb + 30, zt0 - 4, 'dimk');
it{end+1} = d_text(xb + 32, zt0, tt, 'bsm', 'start');
it{end+1} = d_text(xb + 32, zt0 - 48, strjoin(tl, char(10)), 'small', 'start');
it{end+1} = d_text(xb + 32, mean(zbot) - 4, bt_, 'bsm', 'start');
it{end+1} = d_text(xb + 32, mean(zbot) - 52, strjoin(bl, char(10)), 'small', 'start');
end

function it = dr_a2plan(P, cs)
% plan at the level of the shear anchors A2 (z = -201): every vertical bar crossing it near the
% cantilever face. 'E': x = u, y = v, column axis at (200, 0) (B4, C4, D3); 'D4': north up.
g = geo(P);  hb = g.hb;  cb = P.cb;  d = cb.db;  an = P.an;  it = {};
ut = cb.uh + d/2;  ut0 = cb.uh0 + d/2;  up = ut + d;  ub = cb.ubh + d/2;
tie = [g.rh g.rh; P.col.b - g.rh g.rh; P.col.b - g.rh P.col.b - g.rh; g.rh P.col.b - g.rh; g.rh g.rh] - hb;
if strcmp(cs, 'E')
  it = [it, col_plan(P, hb, 0, false)];
  it{end+1} = d_path(tie + [hb 0], P.hoop.db, 'r_tie');
  for v = [-1 1]*an.vS, it = [it, a2_items(P, v)]; end
  T = {ut, cb.v([1 3]), 'r_bm1';  ut0, 0, 'r_bm1';  up, cb.v([1 3]), 'r_bm2';  ub, cb.vbh, 'r_bm4'};
  for k = 1:size(T, 1), for v = T{k,2}, it{end+1} = d_circle(T{k,1}, v, d/2, T{k,3}); end, end
  it{end+1} = d_dim(0, -hb, ut - d/2, -hb, -18, sprintf('%g', cb.uh), 'before');
  it{end+1} = d_dim(0, -hb, up - d/2, -hb, -55, sprintf('%g', cb.uh + d), 'before');
  it{end+1} = d_dim(0, -hb, ub - d/2, -hb, -92, sprintf('%g', cb.ubh));
  it{end+1} = d_dim(0, hb, ut0 - d/2, hb, 18, sprintf('%g', cb.uh0));
  it{end+1} = d_dim(ub + 60, 0, ub + 60, an.vS, -8, sprintf('%g', an.vS));
  it{end+1} = d_text(ub + 14, cb.v(3) + 14, 'inferiores', 'small', 'start');
  it{end+1} = d_text(ut - 10, cb.v(3) + 26, 'superiores', 'small', 'end');
  it{end+1} = d_text(-10, 0, 'cara del voladizo', 'small', 'end');
  it{end+1} = d_text(-10, -an.vS - 26, 'A2', 'anc', 'end');
else
  it = [it, col_plan(P, 0, 0, false)];
  it{end+1} = d_path(tie, P.hoop.db, 'r_tie');
  it = [it, rot_items([a2_items(P, an.vS), a2_items(P, -an.vS)], @(p) [hb - p(1), p(2)])];       % east
  it = [it, rot_items([a2_items(P, an.vS), a2_items(P, -an.vS)], @(p) [p(2), p(1) - hb])];       % south
  for v = cb.v, it{end+1} = d_circle(hb - ifelse_(v == 0, ut0, ut), v, d/2, 'r_bm3'); end           % grid 4 top tails
  for v = cb.vbh, it{end+1} = d_circle(hb - ub, v, d/2, 'r_bm4'); end                                  % grid 4 bottom
  for v = cb.v, it{end+1} = d_circle(v, -hb + ifelse_(v == 0, ut0, ut), d/2, 'r_bm1'); end         % grid D top
  for v = cb.v([1 3]), it{end+1} = d_circle(v, -hb + up, d/2, 'r_bm2'); end
  for v = cb.vbh, it{end+1} = d_circle(v, -hb + ub, d/2, 'r_bm4'); end
  it{end+1} = d_dim(hb, -hb, hb - ub + d/2, -hb, -18, sprintf('%g', cb.ubh));
  it{end+1} = d_dim(-hb, -hb, -hb, -hb + ub - d/2, 18, sprintf('%g', cb.ubh));
  it{end+1} = d_text(hb + 10, 0, 'cara este', 'small', 'start');
  it{end+1} = d_text(-120, -hb - 30, 'cara sur', 'small', 'middle');
end
end

function s = ifelse_(c, a, b)
if c, s = a; else, s = b; end
end

function z = R_zS(P)
% level of the shear anchors (as in ca_calc: pfS over the inside face of the bottom flange)
z = -P.bm.h + P.bm.tf + P.an.pfS;
end

function it = dr_jtie(P)
  % one level of joint ties in plan: 4 straight ties hooked around the corner bars
  g = geo(P);  hb = g.hb;  it = col_plan(P, 0, 0, false);
  for k = 1:4, it{end+1} = d_path(jtie_leg(P, k), P.hoop.db, sprintf('r_t%d', k)); end
  it{end+1} = d_dim(-hb, -hb, hb, -hb, -45, sprintf('%g (columna)', P.col.b));
  it{end+1} = d_dim(hb, -hb, hb, hb, -45, sprintf('%g', P.col.b));
end

function it = dr_tie14(P)
  % closed tie 14
  g = geo(P);  a = g.hb - g.rt;  d = P.top.db;  it = tie14(P, 0, 0);
  o = a + d/2;
  it{end+1} = d_dim(-o, -o, o, -o, -45, sprintf('%g', 2*o));
  it{end+1} = d_dim(o, -o, o, o, -45, sprintf('%g', 2*o));
end

function it = dr_asm(P)
  % A1 and A2 assembled, measured from the outer end; column face dashed. Texts in the caption.
  an = P.an;  bp = P.bp;  it = {};
  L1 = an.out + an.uT;  L2 = an.outS + an.uS + an.twsh + an.tnut + an.pp;
  it = [it, rot_items([a1_items(P, 0), {d_rectxy(bp.u, -bp.h/2, bp.u + bp.t, bp.h/2, 'r_bp')}], @(p) [p(1) + an.out, p(2)])];
  it{end+1} = d_line(an.out, -35, an.out, 35, 'edge');
  it{end+1} = d_dim(0, 25, an.out, 25, 16, sprintf('%g', an.out));
  it{end+1} = d_dim(an.out, 25, an.out + bp.u, 25, 16, sprintf('%g', bp.u));
  it{end+1} = d_dim(an.out + bp.u, 25, L1, 25, 16, sprintf('%g', L1 - an.out - bp.u));
  it{end+1} = d_dim(0, 25, L1, 25, 56, sprintf('A1: L = %.0f', L1));
  it{end+1} = d_text(-8, -4, 'A1', 'anc', 'end');
  it{end+1} = d_text(an.out + bp.u + bp.t/2, -bp.h/2 - 18, 'B1', 'anc', 'middle');
  y2 = -190;
  it = [it, rot_items(a2_items(P, 0), @(p) [p(1) + an.outS, p(2) + y2])];
  it{end+1} = d_line(an.outS, y2 - 25, an.outS, y2 + 25, 'edge');
  it{end+1} = d_dim(0, y2 + 15, an.outS, y2 + 15, 16, sprintf('%g', an.outS));
  it{end+1} = d_dim(an.outS, y2 + 15, an.outS + an.uS, y2 + 15, 16, sprintf('%g', an.uS));
  it{end+1} = d_dim(an.outS + an.uS, y2 + 15, L2, y2 + 15, 16, sprintf('%g', L2 - an.outS - an.uS));
  it{end+1} = d_dim(0, y2 + 15, L2, y2 + 15, 56, sprintf('A2: L = %.0f', L2));
  it{end+1} = d_text(-8, y2 - 4, 'A2', 'anc', 'end');
end

function it = dr_backplate(P)
  an = P.an;  bp = P.bp;
  it = {d_rectxy(-bp.w/2, -bp.h/2, bp.w/2, bp.h/2, 'r_bp')};
  for v = [-1 1]*an.vT, it{end+1} = d_circle(v, 0, an.hole/2, 'bolt'); end
  it{end+1} = d_dim(-bp.w/2, bp.h/2, bp.w/2, bp.h/2, 16, sprintf('%g', bp.w));
  it{end+1} = d_dim(-an.vT, -bp.h/2, an.vT, -bp.h/2, -18, sprintf('%g', 2*an.vT));
  it{end+1} = d_dim(an.vT, -bp.h/2, bp.w/2, -bp.h/2, -18, sprintf('%g', bp.w/2 - an.vT));
  it{end+1} = d_dim(bp.w/2, -bp.h/2, bp.w/2, bp.h/2, -18, sprintf('%g', bp.h));
  a = an.hole/2*0.7071;
  it{end+1} = d_line(-an.vT - a, -a, -bp.w/2 - 12, -bp.h/2 - 14, 'dim');
  it{end+1} = d_text(-bp.w/2 - 14, -bp.h/2 - 22, sprintf('2 agujeros Ø%g', an.hole), 'label', 'end');
end

function it = dr_s2_elev(P)
  % face of the VCM at one support of an IPE 200 (x along the VCM from the IPE axis, z up)
  s2 = P.s2;  W = 330;  it = {};  w = s2.pl(2)/2;
  it{end+1} = d_rectxy(-W, -s2.vh, W, 0, 'r_concb');
  for z = s2.bars(:,1)', it{end+1} = d_bar(-W, z, W, z, 12, 'r_bm1'); end             % the 5 + 5 bars of the VCM: 2 lines each
  for x = [-3 -1 1 3]*s2.stir, it{end+1} = d_bar(x, -s2.vh + 45, x, -45, 10, 'r_tieS'); end
  it{end+1} = d_rectxy(-w, s2.ztop - s2.pl(3), w, s2.ztop, 'r_eplate');
  for x = [-1 1]*s2.v, for z = s2.z, it{end+1} = d_circle(x, z, s2.db/2, 'r_anc'); end, end
  it{end+1} = d_line(0, 40, 0, -s2.vh - 30, 'axis');
  it{end+1} = d_text(0, 95, sprintf('eje de la viga %s', s2.name), 'small', 'middle');
  it{end+1} = d_dim(-s2.v, 0, s2.v, 0, 30, sprintf('%g', 2*s2.v));
  it{end+1} = d_dim(-s2.stir, -s2.vh, s2.stir, -s2.vh, -25, sprintf('%g', 2*s2.stir));
  it{end+1} = d_dim(s2.stir, -s2.vh, s2.v, -s2.vh, -25, sprintf('%g', s2.v - s2.stir));
  it{end+1} = d_dim(W, 0, W, s2.z(1), -16, sprintf('%g', -s2.z(1)), 'before');
  it{end+1} = d_dim(W, s2.z(1), W, s2.z(2), -16, sprintf('%g', s2.z(1) - s2.z(2)));
  it{end+1} = d_dim(W, s2.z(2), W, -s2.vh, -16, sprintf('%g', s2.vh + s2.z(2)));
  it{end+1} = d_text(-W - 8, s2.z(1) - 4, 'AV', 'anc', 'end');
  it{end+1} = d_text(-W - 8, s2.z(2) - 4, 'AV', 'anc', 'end');
end

function it = dr_s2_cross(P)
  % section across the VCM through a pair of rods (y across, z up)
  s2 = P.s2;  hb = s2.vb/2;  it = {};
  Lr = 10*ceil((s2.vb + 2*(s2.pl(1) + s2.wsh(2) + s2.nut(1) + s2.pp))/10);
  it{end+1} = d_rectxy(-hb, -s2.vh, hb, 0, 'r_conc');
  it{end+1} = d_path(fillet([-hb + 45 -45; hb - 45 -45; hb - 45 -s2.vh + 45; -hb + 45 -s2.vh + 45; -hb + 45 -45.01], 20), 10, 'r_tieS');
  for k = 1:size(s2.bars, 1)                       % 5 + 5 Ø12: 3 in a row, 2 under / over the corner bars
    ys = [-1 0 1]*(hb - 56);  if s2.bars(k,2) == 2, ys = ys([1 3]); end
    for y = ys, it{end+1} = d_circle(y, s2.bars(k,1), 6, 'r_bm1'); end
  end
  it{end+1} = d_text(hb + 10, s2.bars(1,1) - 50, sprintf('5 Ø%g', 12), 'bsm', 'start');
  it{end+1} = d_text(hb + 10, s2.bars(3,1) - 50, sprintf('5 Ø%g', 12), 'bsm', 'start');
  for z = s2.z, it{end+1} = d_bar(-Lr/2, z, Lr/2, z, s2.db, 'r_anc'); end
  it{end+1} = d_dim(-hb, -s2.vh, hb, -s2.vh, -22, sprintf('%g', s2.vb));
  it{end+1} = d_dim(-Lr/2, -s2.vh, Lr/2, -s2.vh, -62, sprintf('AV: L = %g', Lr));
  xl = -Lr/2 - 30;
  it{end+1} = d_dim(xl, s2.z(1), xl, 0, 0, sprintf('%g', -s2.z(1)));
  it{end+1} = d_dim(xl, s2.z(2), xl, s2.z(1), 0, sprintf('%g', s2.z(1) - s2.z(2)));
  it{end+1} = d_dim(hb, s2.z(1), Lr/2, s2.z(1), 30, sprintf('%g', (Lr - s2.vb)/2));
  it{end+1} = d_text(0, 12, 'z = 0', 'small', 'middle');
end

function it = dr_s2_rodasm(P)
  % through rod AV with the plates PV, washers and nuts at both ends; x from the left end
  s2 = P.s2;  it = {};  hb = s2.vb/2;  d = s2.db;  t = s2.pl(1);  tw = s2.wsh(2);  tn = s2.nut(1);
  Lr = 10*ceil((s2.vb + 2*(t + tw + tn + s2.pp))/10);  th = 10*ceil((t + tw + tn + s2.pp + 20)/10);  c = Lr/2;
  it{end+1} = d_bar(0, 0, Lr, 0, d, 'r_anc');
  for sg = [-1 1]
    xf = c + sg*hb;                                  % face of the VCM
    it{end+1} = d_line(xf, -45, xf, 45, 'edge');
    it{end+1} = d_rectxy(xf, -45, xf + sg*t, 45, 'r_eplate');
    it{end+1} = d_rectxy(xf + sg*t, -s2.wsh(1)/2, xf + sg*(t + tw), s2.wsh(1)/2, 'r_nut');
    it{end+1} = d_rectxy(xf + sg*(t + tw), -s2.nut(2)/2, xf + sg*(t + tw + tn), s2.nut(2)/2, 'r_nut');
  end
  it{end+1} = d_dim(0, 0, Lr, 0, 70, sprintf('AV: L = %g', Lr));
  it{end+1} = d_dim(c - hb, 0, c + hb, 0, 50, sprintf('%g (VCM)', s2.vb));
  it{end+1} = d_dim(0, 0, c - hb, 0, 50, sprintf('%g', c - hb), 'before');
  it{end+1} = d_dim(0, 0, th, 0, -55, sprintf('rosca %g', th));
  it{end+1} = d_dim(Lr - th, 0, Lr, 0, -55, sprintf('rosca %g', th));
end

function it = dr_cut(P, cs)
  % complete section along the cantilever, nothing faded (user 2026-10-04): anchors, B1, column hooks,
  % ties (dr_sect) and the beam bars with their hooks, dimensions and counts (dr_bsect).
  % cs: 'EU' B4 / C4, 'EL' D3, 'X' D4X, 'Y' D4Y
  an = P.an;  b = P.col.b;  xR = b + 230;  zS = R_zS(P);
  switch cs
    case {'EU', 'EL'}, A = dr_sect(P, an.pf, zS, 'E');
    case 'X',          A = dr_sect(P, an.pf, zS, 'X');
    case 'Y',          A = dr_sect(P, an.zH, zS, 'Y');
  end
  B = dr_bsect(P, cs);
  bars = {'r_bas', 'r_bm1', 'r_bm2', 'r_bm3', 'r_bm4'};
  it = {};
  for i = 1:numel(A)                                  % anchors, column, ties, hooks; not its beam bars or their labels
    q = A{i};  if ~isfield(q, 's'), q.s = ''; end
    if any(strcmp(q.s, [bars {'r_ex'}])), continue; end
    if strcmp(q.t, 'text') && (any(strcmp(q.s, {'tie', 'bsm'})) || strcmp(q.txt, 'VCM') || any(strfind(q.txt, 'con gancho'))), continue; end
    if strcmp(q.t, 'line') && strcmp(q.s, 'dim') && abs(q.p(1) - (xR + 5)) < 1e-6 && any(abs(q.p(2) - P.hoop.z) < 1e-6), continue; end
    if strcmp(q.t, 'dim') && any(abs(q.o - [-100 -140 -14]) < 1e-6), continue; end   % positions of the other cantilever's anchors: plan 4.1
    if strcmp(q.t, 'text') && strcmp(q.txt, 'cara de la columna'), continue; end
    it{end+1} = q;
  end
  for i = 1:numel(B)                                  % beam bars, their dimensions and the hook note; not the counts
    q = B{i};  if ~isfield(q, 's'), q.s = ''; end
    keep = any(strcmp(q.s, bars)) || strcmp(q.t, 'dim');
    if strcmp(q.t, 'text'), keep = (strcmp(q.s, 'code') || strcmp(q.txt, 'fin de la central')) && q.p(1) < xR; end
    if strcmp(q.t, 'line') && strcmp(q.s, 'dim') && q.p(1) < xR, keep = true; end
    if keep, it{end+1} = q; end
  end
  % nothing faded: solid styles for what was drawn faint
  sol = {'r_col', 'r_colS'; 'r_rod', 'r_rodS'; 'r_tie', 'r_tieS'; 'r_ancg', 'r_anc'};
  for i = 1:numel(it)
    if ~isfield(it{i}, 's'), continue; end
    k = find(strcmp(it{i}.s, sol(:,1)));  if ~isempty(k), it{i}.s = sol{k,2}; end
  end
  % counts: braces at the beam end, the text below each brace tip
  [tt, tl, bt_, bl] = bar_counts(P, cs);
  tl = regexprep(tl, ' ?\(-?\d+\)', '');  bl = regexprep(bl, ' ?\(-?\d+\)', '');   % no level numbers (user 2026-10-05)
  ztop = [-56 -80];  zbot = [P.cb.zbc P.cb.zbl];
  zl = [0 max(P.cb.zt) min(P.cb.zt) P.cb.zp];  zlb = [P.cb.zbl P.cb.zbc -P.cb.h];   % bar levels: dimension chains at the beam end
  it = [it, d_chain(xR + 20, fliplr(zl), 26), d_chain(xR + 20, fliplr(zlb), 26)];
  for z = [zl(2:end) zlb(1:2)], it{end+1} = d_line(xR + 2, z, xR + 46, z, 'dim'); end
  xb = xR + 95;
  it = [it, d_brace(xb, min(ztop) - 8, max(ztop) + 8, 22), d_brace(xb, min(zbot) - 8, max(zbot) + 8, 22)];
  it{end+1} = d_text(xb + 32, mean(ztop) + 4, tt, 'bsm', 'start');
  it{end+1} = d_text(xb + 32, mean(ztop) - 96, strjoin(tl, char(10)), 'small', 'start');
  it{end+1} = d_text(xb + 32, mean(zbot) - 4, bt_, 'bsm', 'start');
  it{end+1} = d_text(xb + 32, mean(zbot) - 52, strjoin(bl, char(10)), 'small', 'start');
  if strcmp(cs, 'EU')                                 % user 2026-10-05: the IPE 240 (placed later), cut short
    u1 = -P.g - P.ep.t;  u0 = -100;  tf = P.bm.tf;  hh = P.bm.h;
    it = [it, {d_rectxy(u0, -hh, u1, 0, 'r_ipe'), d_rectxy(u0, -tf, u1, 0, 'r_ipef'), d_rectxy(u0, -hh, u1, -hh + tf, 'r_ipef'), ...
               d_line(u0, 12, u0, -hh - 12, 'cut'), d_text(-160, -112, 'IPE 240', 'small', 'end'), ...
               d_text(-160, -134, '(después)', 'small', 'end'), d_line(-156, -120, u0 + 20, -120, 'lead')}];
  end
  it = [it, dr_bot3d(P, 0, -840, cs)];      % the 5 bottom bars in 3D, under the section      % the 5 bottom bars in 3D, bottom right
end

function it = dr_plan4(P)
  % corner D4 in plan: anchors (solid) and the top bars of both beams, north up
  it = dr_bplan(P, 'D4', true);
  g = geo(P);  hb = g.hb;  an = P.an;
  it{end+1} = d_text(hb + 100, 100, 'A1 D4X (abajo)', 'anc', 'start');
  it{end+1} = d_text(75, -hb - 150, 'A1 D4Y (encima)', 'anc', 'start');
end

function it = dr_bot3d(P, ox, oy, cs)
  % the 5 bottom bars of the VCM at the joint, oblique 3D (u along the beam, v across, z up), placed so that
  % the column face (u = b) lands on the face line of the section above (ox = b - s(b - u0)): 2 corner bars
  % hooked up, the centre bar straight into the joint, the 2 bars over the corner bars ending at the face.
  % The column is a translucent box (u 0..b, v +-200), the beam in line dashed.
  if nargin < 4, cs = 'EU'; end
  cb = P.cb;  d = cb.db;  b = P.col.b;  s = 0.75;  r = 3.5*d;  tail = r + 12*d;  u0 = 100;
  five = any(strcmp(cs, {'EU', 'Y'}));              % VCM in line: 5 bottom bars; VCS (D3, D4X): 3
  zb = cb.zbl;  if strcmp(cs, 'X'), zb = cb.zbc; end
  ox = b - s*(b - u0);
  pr = @(u, v, z) [ox + s*(u - u0 + 0.55*v), oy + s*(z - zb + 0.40*v)];
  ub = cb.ubh + d/2;  ue = b + 330;  hb = b/2;  z0 = -340;  z1 = -60;  it = {};
  face = @(Q) d_poly(cell2mat(cellfun(@(q) pr(q(1), q(2), q(3)), num2cell(Q, 2), 'UniformOutput', false)), 'r_concb');
  % column: back face (v = +hb), top face, face at u = b (towards the beam); then the bars; then the front edges
  it{end+1} = face([0 hb z0; b hb z0; b hb z1; 0 hb z1]);
  it{end+1} = face([0 -hb z1; b -hb z1; b hb z1; 0 hb z1]);
  it{end+1} = face([b -hb z0; b hb z0; b hb z1; b -hb z1]);
  % beam in line, dashed outline (300 wide, from the face)
  bars = {};                                        % far (v > 0, up-right) to near
  for v = [max(cb.vbh) 0 -max(cb.vbh)]
    if v == 0
      bars{end+1} = {[pr(ue, v, zb); pr(b - cb.Lst, v, zb)], 'r_bm4'};
    else
      if five, bars{end+1} = {[pr(ue, v, zb + d); pr(b, v, zb + d)], 'r_bm3'}; end
      bars{end+1} = {fillet([pr(ue, v, zb); pr(ub, v, zb); pr(ub, v, zb + tail)], r*s), 'r_bm4'};
    end
  end
  for k = 1:numel(bars), it{end+1} = d_path(bars{k}{1}, d*s, bars{k}{2}); end
  E = [0 -hb z0; b -hb z0; b -hb z1; 0 -hb z1; 0 -hb z0];        % front face of the column, edges only
  for k = 2:5, q1 = pr(E(k-1,1), E(k-1,2), E(k-1,3)); q2 = pr(E(k,1), E(k,2), E(k,3)); it{end+1} = d_line(q1(1), q1(2), q2(1), q2(2), 'cut'); end
  t1 = pr(ub, -max(cb.vbh), zb + tail);  t2 = pr(b - cb.Lst, 0, zb);  t3 = pr(b, max(cb.vbh), zb + d);
  it{end+1} = d_line(t1(1) - 4, t1(2) - 6, t1(1) - 40, t1(2) - 6, 'dim');
  it{end+1} = d_text(t1(1) - 42, t1(2) - 10, sprintf('2 con gancho,\na %g de la cara', cb.ubh), 'small', 'end');
  it{end+1} = d_line(t2(1), t2(2), t2(1) - 20, t2(2) - 70, 'dim');
  it{end+1} = d_text(t2(1) - 22, t2(2) - 82, sprintf('central recta, %g dentro del nudo', cb.Lst), 'small', 'end');
  t4 = t3 + 140*s*[0.55 0.40];                      % leader along the depth direction (the box's slanted edges)
  if five
    it{end+1} = d_line(t3(1), t3(2), t4(1), t4(2), 'dim');
    it{end+1} = d_text(t4(1) + 4, t4(2) + 4, '2 terminan en la cara', 'small', 'start');
  end
  q = pr(0, hb, z1);  it{end+1} = d_text(q(1), q(2) + 10, 'columna', 'small', 'start');
  q = pr(0, -hb, z0);  it{end+1} = d_text(q(1), q(2) - 110, sprintf('BARRAS INFERIORES DE LA %s (%d Ø%g), 3D', ifelse_(five, 'VCM', 'VCS'), 3 + 2*five, d), 'bsm', 'start');
end

function it = d_chain(x, zs, w)
  % vertical dimension chain at x through the levels zs (ascending); short ones (< 40) alternate
  % between x and x + w so that their numbers do not overlap
  it = {};  n = 1;
  for k = 1:numel(zs) - 1
    dz = zs(k+1) - zs(k);  xx = x;
    if dz < 50, xx = x + mod(n, 3)*w;  n = n + 1; else, n = 1; end   % runs of short ones: three columns, next to a long one in the second
    it{end+1} = d_dim(xx, zs(k), xx, zs(k+1), 0, sprintf('%g', dz));
  end
end

function it = d_brace(x, z0, z1, w)
  % curly-brace-like bracket from z0 to z1 at x, its tip pointing right (+x) at mid height
  zm = (z0 + z1)/2;  q = w/2;  e = min(6, (z1 - z0)/6);
  Q = [x z1; x + q z1 - e; x + q zm + e; x + w zm; x + q zm - e; x + q z0 + e; x z0];
  it = {};
  for k = 2:size(Q, 1), it{end+1} = d_line(Q(k-1,1), Q(k-1,2), Q(k,1), Q(k,2), 'dimk'); end
end

function [tt, tl, bt, bl] = bar_counts(P, cs)
  % Ø12 bars by beam (user 2026-10-04): bold title = the beam in line, as "n Ø12 = reinforcement of the
  % beam + 2 bastones for the joint"; lines: levels and the beam that crosses it
  cb = P.cb;  d = cb.db;  z1 = max(cb.zt);  z2 = min(cb.zt);
  bas = sprintf('\n+ 2 bastones Ø%g para el nudo', d);
  switch cs
    case {'EU', 'E'}
      tt = [sprintf('7 Ø%g = 5 Ø%g (refuerzo de VCM)', d, d) bas];
      tl = {sprintf('3 (%+g) + 2 (%+g); bastones (%+g)', z1, cb.zp, cb.bas.z), sprintf('cruza: eje 4, 3 Ø%g (%+g)', d, z2)};
      bt = sprintf('5 Ø%g (refuerzo de VCM)', d);
      bl = {sprintf('3 entran al nudo (%+g); 2 terminan en la cara', cb.zbl), sprintf('cruza: eje 4, 3 Ø%g (%+g)', d, cb.zbc)};
    case 'EL'
      tt = [sprintf('5 Ø%g = 3 Ø%g (refuerzo de VCS eje 3)', d, d) bas];
      tl = {sprintf('3 + 2 bastones (%+g), con gancho', z2), sprintf('cruza: eje D, 5 Ø%g: 3 (%+g) + 2 (%+g)', d, z1, cb.zp)};
      bt = sprintf('3 Ø%g (refuerzo de VCS eje 3)', d);
      bl = {sprintf('(%+g), 2 con gancho', cb.zbl), sprintf('cruza: eje D (%+g)', cb.zbc)};
    case {'X', 'D4'}
      tt = [sprintf('5 Ø%g = 3 Ø%g (refuerzo de VCS eje 4)', d, d) bas];
      tl = {sprintf('3 + 2 bastones (%+g), con gancho', z2), sprintf('cruza: eje D, 5 Ø%g: 3 (%+g) + 2 (%+g)', d, z1, cb.zp)};
      bt = sprintf('3 Ø%g (refuerzo de VCS eje 4)', d);
      bl = {sprintf('(%+g), 2 con gancho', cb.zbc), sprintf('cruza: eje D, 3 entran al nudo (%+g)', cb.zbl)};
    case 'Y'
      tt = sprintf('5 Ø%g (refuerzo de VCM eje D)', d);
      tl = {sprintf('3 (%+g) + 2 (%+g), todas con gancho', z1, cb.zp), sprintf('cruza: eje 4, 3 Ø%g + 2 bastones (%+g)', d, z2)};
      bt = sprintf('5 Ø%g (refuerzo de VCM eje D)', d);
      bl = {sprintf('3 entran al nudo (%+g); 2 terminan en la cara', cb.zbl), sprintf('cruza: eje 4, 3 Ø%g (%+g)', d, cb.zbc)};
  end
end

function b = tol_table(P)
  t = {
    'A1 en C4, B4 y D3: nivel', '+15 / -5'
    'A1 de D4X (este): nivel', '+0 / -5'
    'A1 de D4Y (sur)', 'sobre los de D4X'
    'A1, A2: lateral', '± 10'
    'A1, A2: saliente de la cara', '+10 / -0'
    'A2: nivel', '± 5'
    sprintf('B1: profundidad (u = %g, pegada al estribo Ø%g)', P.bp.u, P.top.db), '+10 / -0'
    'AV (vigas IPE 200): nivel / horizontal / saliente', '± 5 / ± 10 / +5 -0'};
  rows = {};  for i = 1:size(t, 1), rows{end+1} = t(i,:); end
  b = blk_table({'Elemento', 'mm'}, rows, [0.72 0.28], 2, []);
end

function rows = pour_quantities(P, opts)
  an = P.an;  bp = P.bp;  N = sum(opts.n);
  L1 = an.out + an.uT;  L2 = an.outS + an.uS + an.twsh + an.tnut + an.pp;
  it = {
    'A1', 'Anclaje superior', sprintf('varilla roscada %s %s, L = %.0f', an.thr, an.grade, L1), 2, 2*N
    'A2', 'Anclaje de corte', sprintf('varilla roscada %s %s, L = %.0f', an.thr, an.grade, L2), 2, 2*N
    'B1', 'Placa posterior', sprintf('PL %gx%gx%g A36, 2 agujeros Ø%g', bp.t, bp.h, bp.w, an.hole), 1, N
    'T', 'Tuerca', sprintf('%s grado 8 o A194 2H: 2 por A1, 1 por A2. **Repetido en las láminas de taller.**', an.thr), 6, 6*N
    'W', 'Arandela', sprintf('plana Ø%g x %g: 1 por A1, 1 por A2. **Repetido en las láminas de taller.**', an.wsh, an.twsh), 4, 4*N
    'BA', 'Bastón', sprintf('varilla Ø%g, L = %.0f, gancho de 90°; en B4, C4, D3 y D4X, en la viga en línea', ...
        P.cb.db, 10*round(((P.col.b - P.cb.bas.uh - 3.5*P.cb.db) + P.cb.bas.L + pi*3.5*P.cb.db/2 + 12*P.cb.db)/10)), '2 (B4, C4, D3, D4X)', 8
    'AV', 'Varilla pasante', sprintf('Ø%g fy 4200, L = %g, roscada %s en ambos extremos; en las VCM de los ejes A, B, C, D (vigas IPE 200). **Repetido en las láminas de taller.**', ...
        P.s2.db, 10*ceil((P.s2.vb + 2*(P.s2.pl(1) + P.s2.wsh(2) + P.s2.nut(1) + P.s2.pp))/10), P.s2.thr), '4 por apoyo', 32
    'E14', 'Estribo cerrado', sprintf('Ø%g, ganchos 135°, 2 por columna. **Para todas las columnas con columna metálica (%d), no solo las de los voladizos.**', ...
        P.top.db, opts.ncol), '-', 2*opts.ncol};
  rows = {};
  for i = 1:size(it, 1)
    q = it{i,4};  if isnumeric(q), q = sprintf('%d', q); end
    rows{end+1} = {it{i,1}, it{i,2}, it{i,3}, q, sprintf('%d', it{i,5})};
  end
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

function B = scale_blocks(B, k)
  % drawing heights times k, also inside rows
  for i = 1:numel(B)
    if strcmp(B{i}.k, 'drawing'), B{i}.h = B{i}.h*k;
    elseif strcmp(B{i}.k, 'row'), for j = 1:numel(B{i}.cols), B{i}.cols{j} = scale_blocks(B{i}.cols{j}, k); end
    end
  end
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

% =====================================================================
%  New details for the A2 sheet (2026-10-04)
% =====================================================================
function it = dr_jtie_closed(P)
  % joint tie Ø10 as a normal closed tie, with its outside dimensions
  g = geo(P);  d = P.hoop.db;  o = g.hb - g.rh + d/2;  it = col_plan(P, 0, 0, false, true);
  it = [it, jtie_closed(P, 0, 0, 'r_tieS')];
  it{end+1} = d_dim(-o, -o, o, -o, -(g.hb - o) - 45, sprintf('%g', 2*o));
  it{end+1} = d_dim(o, -o, o, o, -(g.hb - o) - 45, sprintf('%g', 2*o));
end

function it = dr_hookside(P, cs)
  % side view of the column top hooks with the anchors. 'E': seen from a side face, u to the right
  % (cantilever face at u = 0). 'D4': seen from the east, y to the right (south face at 0, north at 400).
  g = geo(P);  an = P.an;  bp = P.bp;  d = P.col.db;  b = P.col.b;  top = P.col.top;  zb = -45;  it = {};
  it{end+1} = d_rectxy(0, zb, b, top, 'r_conc');
  for z = P.top.z, it{end+1} = d_bar(g.rt, z, b - g.rt, z, P.top.db, 'r_new'); end
  z10 = P.t10.z;  if strcmp(cs, 'D4'), z10 = P.t10.zD4; end           % closed tie 10 over the anchors
  it{end+1} = d_bar(g.rh, z10, b - g.rh, z10, P.t10.db, 'r_tieS');
  % anchors of this view: E, or the south cantilever (Y) at D4
  zT = an.pf;  if strcmp(cs, 'D4'), zT = an.zH; end
  it = [it, a1_items(P, zT)];
  it{end+1} = d_rectxy(bp.u, zT - bp.h/2, bp.u + bp.t, zT + bp.h/2, 'r_bp');
  if strcmp(cs, 'E')
    % level A: the front and far mid bars and the corners, hooked along the anchors (in the plane of the view)
    it{end+1} = d_path(fillet([g.rc zb; g.rc g.zA; g.rc + g.ht g.zA], g.rb), d, 'r_hkA');
    it{end+1} = d_path(fillet([b - g.rc zb; b - g.rc g.zA; b - g.rc - g.ht g.zA], g.rb), d, 'r_hkA');
    % level B: the side mid bars, hooked across, over the A1: seen end-on
    it{end+1} = d_bar(g.hb, zb, g.hb, g.zB - g.rb, d, 'r_col');
    for u = g.hb + [-8 8], it{end+1} = d_circle(u, g.zB, d/2, 'r_hkB'); end
    it{end+1} = d_text(g.hb, top + 26, 'nivel A: esquinas y centrales, a lo largo de A1', 'hk', 'middle');
    it{end+1} = d_line(g.hb, top + 20, g.hb + 40, g.zA + d/2 + 2, 'dim');
    it{end+1} = d_text(g.hb, zb - 34, 'nivel B: laterales, sobre los A1', 'hk', 'middle');
    it{end+1} = d_line(g.hb, zb - 26, g.hb - 8, g.zB - d/2 - 2, 'dim');
    zl = [g.zA g.zB];
  else
    % D4 seen from the east: the anchors of X (east-west) cut at y = +-35, z = +29
    for v = [-1 1]*an.vT, it{end+1} = d_circle(g.hb + v, an.pf, an.db/2, 'r_anc'); end
    % level B: the south and north mid bars, north-south (in the plane), on the A1 of X
    it{end+1} = d_path(fillet([g.rc zb; g.rc g.zB; g.rc + g.ht g.zB], g.rb), d, 'r_hkB');
    it{end+1} = d_path(fillet([b - g.rc zb; b - g.rc g.zB; b - g.rc - g.ht g.zB], g.rb), d, 'r_hkB');
    % level A: corners and east and west mid bars, east-west: end-on
    it{end+1} = d_bar(g.hb, zb, g.hb, g.zA - g.rb, d, 'r_col');
    for y = [g.rc, g.rc + 16, g.hb + [-8 8], b - g.rc - 16, b - g.rc], it{end+1} = d_circle(y, g.zA, d/2, 'r_hkA'); end
    it{end+1} = d_text(g.hb, top + 26, 'nivel A: esquinas y centrales este y oeste, a lo largo de A1 de D4X', 'hk', 'middle');
    it{end+1} = d_line(g.hb, top + 20, g.hb - 8, g.zA + d/2 + 2, 'dim');
    it{end+1} = d_text(g.hb, zb - 34, 'nivel B: centrales norte y sur, sobre A1 de D4X', 'hk', 'middle');
    it{end+1} = d_line(g.hb, zb - 26, g.hb + 40, g.zB - d/2 - 2, 'dim');
    it{end+1} = d_text(g.hb + an.vT + 12, an.pf - 4, 'A1 D4X', 'anc', 'start');
    zl = [g.zA zT g.zB an.pf];
  end
  it{end+1} = d_text(-an.out, zT + 14, ifelse_(strcmp(cs, 'E'), 'A1', 'A1 D4Y'), 'anc', 'start');
  it{end+1} = d_text(bp.u + bp.t + 4, zT + bp.h/2 + 8, 'B1', 'anc', 'start');
  % levels as a dimension chain from the top of the beams (no level numbers)
  xd = b + 40;
  zs = unique([0, zl, zT, top, P.top.z(P.top.z > zb), z10]);
  it = [it, d_chain(xd, zs, 28)];
  for z = zs, it{end+1} = d_line(b + 4, z, xd + 30, z, 'dim'); end
  it{end+1} = d_dim(0, zb, b, zb, -18, sprintf('%g', b));
  it{end+1} = d_text(-6, zb + 6, ifelse_(strcmp(cs, 'E'), 'cara del voladizo', 'cara sur'), 'small', 'end');
end

function it = dr_allbars(P)
  % plan of every beam bar at C4 (type E): top bars drawn, ends of the bottom bars and of the bars
  % under the corner bars marked (they lie under the drawn lines); x = u, y = v
  g = geo(P);  hb = g.hb;  cb = P.cb;  d = cb.db;  L = 300;  bw = cb.b/2;  xe = P.col.b + 230;  it = {};
  uh = cb.uh + d/2;  uh0 = cb.uh0 + d/2;  ub = cb.ubh + d/2;  up = cb.uh + d + d/2;  xt = xe + 40;
  it{end+1} = d_rectxy(P.col.b, -bw, xe, bw, 'r_concb');
  it{end+1} = d_rectxy(hb - bw, hb, hb + bw, L, 'r_concb');
  it{end+1} = d_rectxy(hb - bw, -L, hb + bw, -hb, 'r_concb');
  it = [it, col_plan(P, hb, 0, false), a1_plan(P, true), ep_plan(P), jtie_closed(P, hb, 0, 'r_tie')];
  for v = cb.v, it{end+1} = d_bar(hb + v, -L, hb + v, L, d, 'r_bm3'); end
  for v = cb.bas.v
    it{end+1} = d_bar(xe, v, cb.bas.uh + d/2, v, d, 'r_bas');  it{end+1} = d_circle(cb.bas.uh + d/2, v, d/2 + 2, 'r_bas');
  end
  for v = cb.v
    u0 = uh;  if v == 0, u0 = uh0; end
    it{end+1} = d_bar(xe, v, u0, v, d, 'r_bm1');  it{end+1} = d_circle(u0, v, d/2 + 2, 'r_bm1');
  end
  for v = cb.v([1 3]), it{end+1} = d_circle(up, v, d/2 + 1.5, 'r_bm2'); end
  for v = cb.vbh, it{end+1} = d_circle(ub, v, d/2 + 1.5, 'r_bm4'); end
  us = P.col.b - cb.Lst;  it{end+1} = d_line(us, -9, us, 9, 'r_bm4');
  lab = {cb.v(3), 150, sprintf('3 Ø%g arriba (%+g)', d, max(cb.zt));
         cb.bas.v(2), 105, sprintf('+2 bastones (%+g)', cb.bas.z);
         cb.v(1), -105, sprintf('debajo de las de esquina: 2 Ø%g (%+g)', d, cb.zp)};
  for k = 1:size(lab, 1)
    it{end+1} = d_line(xe - 20 - 25*(k - 1), lab{k,1}, xt, lab{k,2}, 'dim');
    it{end+1} = d_text(xt + 4, lab{k,2} - 3, lab{k,3}, 'small', 'start');
  end
  it{end+1} = d_line(ub, cb.vbh(1), ub - 40, -L + 30, 'dim');
  it{end+1} = d_text(ub - 40, -L + 18, sprintf('ganchos inferiores (u = %g)', cb.ubh), 'small', 'middle');
  it{end+1} = d_line(us, -9, us + 40, -L + 60, 'dim');
  it{end+1} = d_text(us + 40, -L + 48, sprintf('fin de la inferior central (%g dentro)', cb.Lst), 'small', 'start');
  it{end+1} = d_line(up, cb.v(3), up - 30, L - 40, 'dim');
  it{end+1} = d_text(up - 30, L - 30, sprintf('ganchos de las de %+g', cb.zp), 'small', 'middle');
  it{end+1} = d_text(-10, 0, 'cara del voladizo', 'small', 'end');
  it{end+1} = d_text((P.col.b + xe)/2, bw + 14, 'VCM en línea', 'small', 'middle');
end

function it = dr_beamsec(P, compact)
  % section A-A of the VCM in line at C4, next to the column (in the span), looking at the column.
  % compact: short labels (copy next to the key plan)
  if nargin < 2, compact = false; end
  cb = P.cb;  d = cb.db;  bw = cb.b/2;  h = cb.h;  c = 40;  ds = cb.dst;  it = {};
  it{end+1} = d_rectxy(-bw, -h, bw, 0, 'r_conc');
  it{end+1} = d_rectxy(-bw - 60, 0, bw + 60, P.slab.t, 'r_concb');
  a = bw - c - ds/2;  zt_ = -c - ds/2;  zb_ = -h + c + ds/2;
  it{end+1} = d_path(fillet([-a zt_; a zt_; a zb_; -a zb_; -a zt_ + 0.01], 2*ds), ds, 'r_tie');
  vb = cb.vbm;
  for v = [-vb 0 vb], it{end+1} = d_circle(v, max(cb.zt), d/2, 'r_bm1'); end
  for v = [-vb vb], it{end+1} = d_circle(v, max(cb.zt) - d, d/2, 'r_bm2'); end
  for v = [-1 1]*(vb - d), it{end+1} = d_circle(v, max(cb.zt) - d, d/2, 'r_bas'); end
  for v = [-vb 0 vb], it{end+1} = d_circle(v, -h + c + ds + d/2, d/2, 'r_bm4'); end
  for v = [-vb vb], it{end+1} = d_circle(v, -h + c + ds + 3*d/2, d/2, 'r_bm4'); end
  it{end+1} = d_dim(-bw, -h, bw, -h, -18, sprintf('%g', cb.b));
  it{end+1} = d_dim(bw, -h, bw, 0, -18, sprintf('%g', h));
  it{end+1} = d_dim(0, -h - 40, vb, -h - 40, 0, sprintf('%g', vb));
  if compact
    it{end+1} = d_line(vb + 6, max(cb.zt), bw + 30, max(cb.zt), 'dim');
    it{end+1} = d_text(bw + 34, max(cb.zt) - 3, sprintf('7 Ø%g', d), 'bsm', 'start');
    it{end+1} = d_line(vb + 6, -h + c + ds + d, bw + 30, -h + c + ds + d, 'dim');
    it{end+1} = d_text(bw + 34, -h + c + ds + d - 3, sprintf('5 Ø%g', d), 'small', 'start');
    return
  end
  it{end+1} = d_line(vb + 6, max(cb.zt), bw + 40, max(cb.zt) + 40, 'dim');
  it{end+1} = d_text(bw + 44, max(cb.zt) + 38, sprintf('3 Ø%g', d), 'small', 'start');
  it{end+1} = d_line(vb + 6, max(cb.zt) - d, bw + 40, max(cb.zt) - 60, 'dim');
  it{end+1} = d_text(bw + 44, max(cb.zt) - 62, sprintf('2 Ø%g bajo las de esquina', d), 'small', 'start');
  it{end+1} = d_text(bw + 44, max(cb.zt) - 80, '+ 2 bastones (naranja) al lado', 'small', 'start');
  it{end+1} = d_line(vb + 6, -h + c + ds + d, bw + 40, -h + 90, 'dim');
  it{end+1} = d_text(bw + 44, -h + 88, sprintf('5 Ø%g', d), 'small', 'start');
  it{end+1} = d_text(0, P.slab.t + 10, 'losa (después)', 'small', 'middle');
  it{end+1} = d_text(-bw - 8, -h/2, sprintf('estribo Ø%g', ds), 'small', 'end');
end

function it = dr_bastonbar(P)
  % the bastón Ø12 (C4): straight bar with a 90 degree hook at the joint end
  cb = P.cb;  d = cb.db;  r = 3.5*d;  Lh = (P.col.b - cb.bas.uh) + cb.bas.L;  hv = 5*ceil(16*d/5);  it = {};   % pata: 16 db (ACI minimum) rounded up
  it{end+1} = d_path(fillet([d/2 -hv + d/2; d/2 0; Lh 0], r), d, 'r_bas');
  it{end+1} = d_dim(0, d/2, Lh, d/2, 22, sprintf('%.0f (al exterior del gancho)', Lh));
  it{end+1} = d_dim(0, -hv + d/2, 0, d/2, 22, sprintf('%.0f', hv));
  it{end+1} = d_line(P.col.b - cb.bas.uh, -16, P.col.b - cb.bas.uh, 16, 'dim');
  it{end+1} = d_text(P.col.b - cb.bas.uh + 8, -26, 'cara de la columna', 'small', 'start');
  it{end+1} = d_text(Lh/2 + 200, -60, sprintf('Ø%g, doblez interior 6Ø; 2 por unión (total 8)', d), 'small', 'middle');
end
