function file = make_workshop_sheets(P, R, outdir, opts)
% MAKE_WORKSHOP_SHEETS  A4 workshop sheets (Spanish) of the bolted plate anchorage:
%   1  quantities, anchors, back plate, notes
%   2  end plate P1, one for all types (with extra plates and rib); holes at +29 or +56
%
% opts.n   number of connections of each type, [E C1 CX CY]
% Same JSON format and printer as ../cantilever_anchor/make_workshop_sheets.m; the block and
% drawing helpers at the end are copied from there. Units mm. End-plate drawings: x = 0 at the
% column-side face of the end plate (beam side x < 0), z = 0 at the top of the beam.

  an = P.an;  bp = P.bp;  bm = P.bm;  n = opts.n;  ne = sum(n);              % one end plate type
  E = R.typ(1);  Y = R.typ(4);
  B = {};

  % ---- sheet 1 ---------------------------------------------------------------
  B{end+1} = blk_h(1, 'Anclajes de voladizos IPE 240 con placa extremo empernada');
  B{end+1} = blk_h(2, 'Cuadro de cantidades');
  [rows, kg] = quantities(P, R, n);
  B{end+1} = blk_table({'Marca', 'Elemento', 'Descripción', 'Por conexión', 'Total', 'kg total'}, ...
      rows, [0.07 0.17 0.44 0.12 0.08 0.12], [4 5 6], []);
  B{end+1} = blk_note(sprintf(['Conexiones: %d tipo E, %d tipo C1, %d tipo CX, %d tipo CY. Acero en placas, anclajes y viga de borde: %.0f kg. ' ...
      'Las vigas IPE 240 e IPE 200 no están incluidas.'], n, kg));
  B{end+1} = blk_h(2, 'Anclajes y placa posterior');
  B{end+1} = blk_row([0.64 0.36], {{blk_draw(dr_anchors(P), 52, sprintf('MARCAS A1 Y A2 - ANCLAJES %s (misma escala)', an.lab), ...
      sprintf('A1: anclaje superior. A2: anclaje de corte. Varilla roscada %s %s, cortada a medida.', P.an.thr, P.an.grade))}, ...
      {blk_draw(dr_backplate(P), 52, sprintf('MARCA B1 - PLACA POSTERIOR PL %gx%gx%g', bp.t, bp.h, bp.w), ...
      sprintf('2 agujeros Ø%g.', an.hole))}});
  B{end+1} = blk_h(2, 'Notas');
  notes = {
    'Antes de la fundición del nudo se colocan: anclajes A1 con la placa posterior B1 y sus tuercas, y anclajes A2 con su tuerca y arandela en el extremo interior. Placas extremo, refuerzos, rigidizadores y vigas se colocan después.'
    sprintf(['Una sola placa extremo P1 para todas las uniones. En la columna de esquina con dos voladizos, los anclajes A1 de las dos vigas ' ...
             'se cruzan a distinta altura: viga X a %g mm sobre el ala, viga Y a %g mm (apoyados sobre los de X). Los agujeros superiores de la placa ' ...
             'se perforan donde quedan los anclajes (nota 8). Viga Y: la viga de hormigón cuyas varillas superiores están en la capa de arriba.'], P.an.pf, P.an.zH)
    'Medidas en mm.'
    sprintf('Placas: acero A36. Anclajes: varilla roscada comercial %s %s (barras de 3,66 m cortadas a medida; grado marcado en la barra y certificado de calidad). NO usar varilla roscada de ferretería (grado 2).', P.an.thr, P.an.grade)
    sprintf('Tuercas hexagonales %s grado 8 (SAE J995) o pesadas ASTM A194 2H; arandela plana Ø30 x 3 (agujero 17). Extremos interiores cortados a ras de la tuerca.', P.an.thr)
    'Soldadura E70. Filetes de taller: refuerzos S1 a la placa extremo, 6 mm, solo en el borde inferior y en el borde interior. Bordes exterior y superior: a ras con la placa, sin soldar.'
    sprintf('Soldaduras de obra (bandera): alas a placa extremo %g mm todo alrededor; alma %g mm a ambos lados; rigidizador %g mm a ambos lados, a la placa y al ala.', P.w.flange, P.w.web, P.rib.w)
    sprintf(['Grout bajo la placa extremo, %g mm: mortero de relleno cementicio sin contracción (ASTM C1107), resistencia mínima 280 kg/cm2 a 28 días; por ejemplo SikaGrout-212 o INTACO Maxibed Grout, o equivalente. ' ...
             'Cara de la columna limpia, rugosa y saturada sin agua libre. Placa sostenida a %g mm de la cara con calzas de acero (quedan dentro) y las tuercas a mano; vaciar por un solo lado hasta que salga por el opuesto, sin aire atrapado; curar según el fabricante. ' ...
             'Apriete final de las tuercas cuando el grout alcance la resistencia indicada por el fabricante.'], P.g, P.g)
    sprintf('Agujeros Ø%g de la placa extremo y de los refuerzos: perforar juntos, en la posición medida de los anclajes en obra. Las cotas de los agujeros son teóricas.', an.hole)
    'Marcar con punzón, en la placa extremo, el eje de la viga y la cara superior del ala.'
    'Proteger las roscas con cinta.'
    'No pintar las zonas a soldar en obra.'};
  for i = 1:numel(notes), B{end+1} = blk_p(sprintf('%d. %s', i, notes{i})); end

  % ---- sheet 2: the end plate (one type) --------------------------------------
  t = E;  k = 1;
  B{end+1} = blk_page();
  B{end+1} = blk_h(1, sprintf('Placa extremo P1 - todas las uniones (%d unidad%s)', ne, plural(ne)));
  B{end+1} = blk_p(sprintf('PL %gx%gx%g + 2 refuerzos S1 + rigidizador R1. Agujeros superiores a %g mm sobre el ala; tipo CY: a %g mm (línea punteada).', ...
      P.ep.t, P.ep.w, t.H, P.an.pf, P.an.zH));
  B{end+1} = blk_row([0.6 0.4], {{blk_draw(dr_side(P, t), 92, sprintf('DETALLE %d.1 - ELEVACIÓN LATERAL', k+1), ...
      'Viga, rigidizador y anclajes en línea punteada. Viga y rigidizador: en obra.')}, ...
      {blk_draw(dr_rib(P, t), 40, sprintf('DETALLE %d.4 - RIGIDIZADOR R1, PL %g A36', k+1, P.rib.t), ...
      sprintf('%d unidad%s. Lado vertical contra la placa; lado inferior sobre el ala.', ne, plural(ne))), ...
       blk_draw(dr_supl(P, t), 34, sprintf('DETALLE %d.5 - REFUERZOS S1, PL %g', k+1, P.dbl.t), ...
      sprintf('%d unidades (2 por placa), iguales; vista desde la columna. Rojo: filetes %g.', 2*ne, P.dbl.w))}});
  B{end+1} = blk_row([0.5 0.5], {{blk_draw(dr_colside(P, t), 98, sprintf('DETALLE %d.2 - VISTA DESDE LA COLUMNA', k+1), ...
      'Refuerzos soldados en taller.')}, ...
      {blk_draw(dr_beamside(P, t), 98, sprintf('DETALLE %d.3 - VISTA DESDE LA VIGA', k+1), ...
      'Viga y rigidizador en línea punteada.')}});

  % ---- sheet 3: IPE 200 floor beams to the VCM (cast-in through rods, plate PV, web weld) ---------------
  s2 = P.s2;  Lr = s2_rod(P);
  B{end+1} = blk_page();
  B{end+1} = blk_h(1, sprintf('Unión de las vigas %s a las vigas de hormigón VCM (ejes A, B, C, D)', s2.name));
  B{end+1} = blk_p(sprintf(['Vigas %s entre los ejes 3 y 4, a los tercios: 12 extremos en 8 ubicaciones. Corte simple: el alma se suelda a la placa PV; ' ...
      'la placa se fija con 4 varillas pasantes AV dejadas en la VCM antes de la fundición.'], s2.name));
  B{end+1} = blk_row([0.55 0.45], {{blk_draw(dr_s2_sect(P), 62, 'DETALLE 3.1 - CORTE POR LA VCM (EJES B Y C)', ...
      sprintf(['Una viga a cada lado; en A y D, una sola: la placa de la otra cara va sin viga. Filete de obra %g a ambos lados del alma, ' ...
               'de z = %g a %g. Alas sin soldar, a %g de la placa.'], s2.w, s2.wz, s2.gap))}, ...
      {blk_draw(dr_s2_plate(P), 62, sprintf('DETALLE 3.2 - PLACA PV, PL %gx%gx%g A36', s2.pl), ...
      sprintf(['Vista desde la viga. 4 agujeros Ø%g, perforados con la posición medida de las varillas. Línea punteada: estribos de la VCM a ±%g del eje de la viga ' ...
               '(separación 140), varillas a %g de un estribo.'], s2.hole, s2.stir, s2.v - s2.stir))}});
  B{end+1} = blk_row([0.55 0.45], {{blk_draw(dr_s2_rod(P), 26, sprintf('MARCA AV - VARILLA PASANTE Ø%g', s2.db), ...
      sprintf('Varilla corrugada Ø%g fy 4200 (INEN 2167), extremos torneados y roscados %s. 32 unidades.', s2.db, s2.thr))}, ...
      {blk_h(2, 'Notas de la unión'), ...
       blk_p(sprintf(['Varillas AV: ANTES DE LA FUNDICIÓN DE LA VCM, atravesando el encofrado y fijadas con plantilla. Superiores a z = %g, sobre las barras superiores de la VCM y amarradas a ellas; ' ...
                      'inferiores a z = %g. A %g mm de un estribo; no cortar estribos ni barras.'], s2.z, s2.v - s2.stir)), ...
       blk_p(sprintf('Placas PV contra la cara limpia de la VCM; tuercas firmes antes de soldar. Largo de la %s: luz libre entre caras - %g (medir en obra); en el eje A la VCM es inclinada (~4°): cortar el extremo a ese ángulo.', s2.name, 2*(s2.pl(1) + s2.gap)))}});

  % ---- sheet 4: border beam IPE 160 and its connection to the cantilever tips ------------------
  bb = P.bb;  V = bb_pieces(P);
  B{end+1} = blk_page();
  B{end+1} = blk_h(1, sprintf('Viga de borde %s y su unión a las puntas de los voladizos', bb.name));
  B{end+1} = blk_draw(dr_bb_key(P), 70, 'DETALLE 4.1 - PLANTA DE VIGAS DE BORDE', ...
      sprintf('%s A36, superior a ras con los voladizos. Placa T1 en la punta de cada voladizo (naranja).', bb.name));
  B{end+1} = blk_row([0.5 0.5], {{blk_draw(dr_bb_join(P, 'end2'), 80, 'DETALLE 4.2 - DOS VIGAS TERMINAN EN LA PUNTA (C9, D9)', ...
      sprintf('Cada viga con 2 pernos de su lado. Media ala interior (arriba y abajo) cortada a ras del alma, %g mm más allá de la placa.', bb.cl))}, ...
      {blk_draw(dr_bb_join(P, 'pass'), 80, 'DETALLE 4.3 - LA VIGA PASA LA PUNTA (B9, E3, E4)', ...
      '4 pernos centrados en el alma del voladizo. En B9 la viga termina 75 más allá del eje; en E3, en el borde de losa (60).')}});
  B{end+1} = blk_row([0.45 0.55], {{blk_draw(dr_bb_tip(P), 55, sprintf('DETALLE 4.4 - PLACA T1, PL %gx%gx%g A36', bb.tp), ...
      sprintf('5 unidades (B9, C9, D9, E4, E3), soldadas en taller al extremo de cada IPE 240, filetes %g todo alrededor.', bb.wtp))}, ...
      {blk_draw(dr_bb_corner(P), 55, 'DETALLE 4.5 - ESQUINA E9 (PLANTA)', ...
      'VB3 llega al alma de VB4 con un tab soldado a VB4; destaje de VB3 arriba y abajo.')}});
  rowsV = {};
  for k = 1:numel(V), rowsV{end+1} = {V(k).mark, bb.name, sprintf('%g', V(k).L), V(k).cuts, V(k).holes}; end
  B{end+1} = blk_table({'Marca', 'Perfil', 'L (mm)', 'Cortes de media ala interior (arriba y abajo)', 'Agujeros Ø18 en el alma (z = -50 y -110)'}, rowsV, [0.07 0.09 0.08 0.40 0.36], 3, []);
  B{end+1} = blk_p(sprintf(['Pernos M%g x 40 ASTM A325 (o 8.8) con tuerca y arandela: %d. Agujeros Ø%g. Las cotas de los agujeros de las vigas se replantean ' ...
      'con las placas T1 colocadas. Perfiles: barras de 6 m; %s en total %.1f m.'], bb.bolt, 22, bb.hole, bb.name, sum([V.L])/1000));

  sheets = {'Cantidades', 'Placa extremo P1', 'Vigas IPE 200', 'Viga de borde'};
  page = 'A4';  fs = 0.9;
  if isfield(opts, 'page') && strcmp(opts.page, 'A2L')
    pg = {};  cur = {};
    for i = 1:numel(B)
      if strcmp(B{i}.k, 'page'), pg{end+1} = cur;  cur = {}; else, cur{end+1} = B{i}; end
    end
    pg{end+1} = cur;
    for i = 1:numel(pg), pg{i} = scale_blocks(pg{i}, opts.hk); end
    B = {blk_row(opts.colw, {pg{1}, [pg{2} pg{3}], pg{4}})};
    sheets = {'Taller: placas, anclajes, vigas IPE 200 y viga de borde'};  page = 'A2L';  fs = opts.fs;
  end
  doc = struct('title', 'Anclajes de voladizos - taller', 'page', page, 'fs', fs, 'blocks', {B}, ...
               'frame', struct('fields', {title_fields(opts)}, 'widths', tb_widths(opts), ...
                               'h', 30, 'subtitle', opts.subtitle, 'sheets', {sheets}));
  base = fullfile(outdir, 'planos_taller_placa_empernada');
  fid = fopen([base '.json'], 'w');
  if fid < 0, error('Cannot write %s.json', base); end
  fprintf(fid, '%s', jsonencode(doc));
  fclose(fid);
  [st, out] = system(sprintf('%s "%s" "%s.json" "%s.pdf"', opts.python, opts.printer, base, base));
  fprintf('%s', out);
  if st ~= 0, error('PDF generation failed (see the message above).'); end
  file = [base '.pdf'];
end

function s = plural(n)
  if n == 1, s = ''; else, s = 'es'; end
end

% =====================================================================
%  IPE 200 to VCM (section 3)
% =====================================================================
function L = s2_rod(P)
  % through rod: VCM width plus, at each end, plate, washer, nut and thread past it; rounded up to 10
  s2 = P.s2;  L = 10*ceil((s2.vb + 2*(s2.pl(1) + s2.wsh(2) + s2.nut(1) + s2.pp))/10);
end

function t = s2_thread(P)
  % thread length at each end: plate, washer, nut and 20 of tolerance
  s2 = P.s2;  t = 10*ceil((s2.pl(1) + s2.wsh(2) + s2.nut(1) + s2.pp + 20)/10);
end

function it = s2_ibeam(x0, x1, s2)
  % IPE 200 in elevation from x0 to x1: outline, flanges, web (z = 0 at its top)
  it = {d_rectxy(min(x0, x1), -s2.h, max(x0, x1), 0, 'beam')};
  for z = [-s2.tf, -s2.h + s2.tf], it{end+1} = d_line(x0, z, x1, z, 'beamline'); end
end

function it = dr_s2_sect(P)
  % section across the VCM at an IPE 200 (grids B, C: one beam on each side); x across, z up
  s2 = P.s2;  hb = s2.vb/2;  t = s2.pl(1);  it = {};  Lr = s2_rod(P);  xr = 420;
  it{end+1} = d_rectxy(-hb, -s2.vh, hb, 0, 'void');
  it{end+1} = d_line(-xr, 110, xr, 110, 'hidden');  it{end+1} = d_text(xr - 10, 118, 'losa (después)', 'small', 'end');
  % VCM bars and stirrup, faint
  it{end+1} = d_rectxy(-hb + 45, -s2.vh + 45, hb - 45, -45, 'hidden');
  for k = 1:size(s2.bars, 1)                       % VCM 5 + 5 Ø12
    xs = [-1 0 1]*(hb - 56);  if s2.bars(k,2) == 2, xs = xs([1 3]); end
    for x = xs, it{end+1} = d_circle(x, s2.bars(k,1), 6, 'void'); end
  end
  for sg = [-1 1]
    it{end+1} = d_rectxy(sg*hb, s2.ztop - s2.pl(3), sg*(hb + t), s2.ztop, 'plate');
    it = [it, s2_ibeam(sg*(hb + t + s2.gap), sg*xr, s2)];
    for z = s2.z
      it{end+1} = d_rectxy(sg*(hb + t), z - s2.wsh(1)/2, sg*(hb + t + s2.wsh(2)), z + s2.wsh(1)/2, 'bolt');
      it{end+1} = d_rectxy(sg*(hb + t + s2.wsh(2)), z - s2.nut(2)/2, sg*(hb + t + s2.wsh(2) + s2.nut(1)), z + s2.nut(2)/2, 'bolt');
    end
  end
  for z = s2.z, it{end+1} = d_rectxy(-Lr/2, z - s2.db/2, Lr/2, z + s2.db/2, 'tab'); end
  it{end+1} = d_weld(-(hb + t), -100, -300, -260, -1, 'both', sprintf('%g', s2.w), sprintf('%g', -diff(s2.wz)), 0, 1, 'alma', 'weld5');
  % dimensions
  it{end+1} = d_dim(-hb, -s2.vh, hb, -s2.vh, -20, sprintf('%g', s2.vb));
  it{end+1} = d_dim(-Lr/2, -s2.vh, Lr/2, -s2.vh, -48, sprintf('AV: L = %g', Lr));
  xd = hb + 70;
  it{end+1} = d_dim(xd, 0, xd, s2.z(1), -10, sprintf('%g', -s2.z(1)));
  it{end+1} = d_dim(xd, s2.z(1), xd, s2.z(2), -10, sprintf('%g', s2.z(1) - s2.z(2)));
  it{end+1} = d_dim(xd, s2.z(2), xd, -s2.vh, -10, sprintf('%g', s2.vh + s2.z(2)));
  it{end+1} = d_dim(-hb - 70, 0, -hb - 70, s2.ztop, 10, sprintf('%g', -s2.ztop), 'before');
  it{end+1} = d_dim(-hb - 70, s2.ztop, -hb - 70, s2.ztop - s2.pl(3), 10, sprintf('%g', s2.pl(3)));
  it{end+1} = d_text(xr, -s2.h/2 - 4, s2.name, 'small', 'end');
  it{end+1} = d_text(0, -s2.vh/2 + 20, 'VCM', 'small', 'middle');
  it{end+1} = d_text(0, -s2.vh/2 - 6, sprintf('%gx%g', s2.vb/10, s2.vh/10), 'small', 'middle');
  it{end+1} = d_text(xr, 6, 'z = 0: cara superior', 'small', 'end');
  it{end+1} = d_text(hb + 4, s2.ztop - s2.pl(3) - 18, 'PV', 'code', 'start');
end

function it = dr_s2_plate(P)
  % plate PV seen from the IPE 200 (v across, z up): holes, beam section, VCM outline and stirrups
  s2 = P.s2;  w = s2.pl(2)/2;  zt = s2.ztop;  zb = zt - s2.pl(3);  it = {};
  it{end+1} = d_rectxy(-w - 60, -s2.vh, w + 60, 0, 'void');
  for v = [-3 -1 1 3]*s2.stir, it{end+1} = d_line(v, -s2.vh + 15, v, -15, 'hidden'); end
  it{end+1} = d_rectxy(-w, zb, w, zt, 'plate');
  for v = [-1 1]*s2.v, for z = s2.z, it{end+1} = d_circle(v, z, s2.hole/2, 'void'); end, end
  b2 = s2.b/2;  t2 = s2.tw/2;  h = s2.h;  f = s2.tf;
  it{end+1} = d_poly([-b2 0; b2 0; b2 -f; t2 -f; t2 -h + f; b2 -h + f; b2 -h; -b2 -h; -b2 -h + f; -t2 -h + f; -t2 -f; -b2 -f], 'beam');
  for x = [-t2 - 2.5, t2 + 2.5], it{end+1} = d_rectxy(x - 2.5, s2.wz(2), x + 2.5, s2.wz(1), 'weldf5'); end
  % dimensions
  it{end+1} = d_dim(-w, zb, w, zb, -20, sprintf('%g', 2*w));
  it{end+1} = d_dim(-s2.v, zb, s2.v, zb, -44, sprintf('%g', 2*s2.v));
  it{end+1} = d_dim(s2.v, zb, w, zb, -44, sprintf('%g', w - s2.v));
  it{end+1} = d_dim(w, zt, w, s2.z(1), -16, sprintf('%g', zt - s2.z(1)));
  it{end+1} = d_dim(w, s2.z(1), w, s2.z(2), -16, sprintf('%g', s2.z(1) - s2.z(2)));
  it{end+1} = d_dim(w, s2.z(2), w, zb, -16, sprintf('%g', s2.z(2) - zb));
  it{end+1} = d_dim(-w, zt - s2.pl(3), -w, zt, 16, sprintf('%g', s2.pl(3)));
  it{end+1} = d_dim(s2.stir, 0, s2.v, 0, 16, sprintf('%g', s2.v - s2.stir));
  it{end+1} = d_text(0, -s2.h - 26, sprintf('filete %g, ambos lados del alma', s2.w), 'small', 'middle');
  it{end+1} = d_text(s2.v + 30, 24, 'estribo VCM a varilla', 'small', 'start');
end

function it = dr_s2_rod(P)
  s2 = P.s2;  L = s2_rod(P);  th = s2_thread(P);  d = s2.db;  it = {};
  it{end+1} = d_rectxy(th, -d/2, L - th, d/2, 'tab');
  for x = [0 L - th], it{end+1} = d_rectxy(x, -d/2, x + th, d/2, 'tabh'); end
  it{end+1} = d_dim(0, d/2, L, d/2, 30, sprintf('%g', L));
  it{end+1} = d_dim(0, d/2, th, d/2, 12, sprintf('%g', th));
  it{end+1} = d_dim(L - th, d/2, L, d/2, 12, sprintf('%g', th));
  it{end+1} = d_text(L/2, -d/2 - 26, sprintf('rosca %s en ambos extremos', s2.thr), 'small', 'middle');
end

% =====================================================================
%  Quantities
% =====================================================================
function L = len_a2(P)
  an = P.an;  L = an.outS + an.uS + an.twsh + an.tnut + an.pp;
end

function [rows, tot] = quantities(P, R, n)
  rho = 7.85e-6;  wb = 1.55e-3;  an = P.an;  bp = P.bp;  N = sum(n);     % wb: 5/8" rod, gross section
  E = R.typ(1);  ne = N;
  Ls = @(t) 5*ceil(t.ep_top/tan(pi/6)/5);
  sw = P.ep.w/2 - P.dbl.gap/2;
  it = {
    'P1', 'Placa extremo', sprintf('PL %gx%gx%g, 4 agujeros Ø%g', P.ep.t, P.ep.w, E.H, an.hole), '1', ne, rho*P.ep.t*P.ep.w*E.H
    'S1', 'Refuerzo', sprintf('PL %gx%gx%g, 1 agujero Ø%g', P.dbl.t, sw, E.ep_top, an.hole), '2', 2*ne, rho*P.dbl.t*sw*E.ep_top
    'R1', 'Rigidizador', sprintf('PL %g, %g x %g (ver detalle 2.4)', P.rib.t, E.ep_top, Ls(E)), '1', ne, rho*P.rib.t*E.ep_top*Ls(E)/2
    'B1', 'Placa posterior', sprintf('PL %gx%gx%g, 2 agujeros Ø%g', bp.t, bp.h, bp.w, an.hole), '1', N, rho*bp.t*bp.h*bp.w
    'A1', 'Anclaje superior', sprintf('varilla roscada %s %s, L = %.0f', an.thr, an.grade, an.out + an.uT), '2', 2*N, wb*(an.out + an.uT)
    'A2', 'Anclaje de corte', sprintf('varilla roscada %s %s, L = %.0f', an.thr, an.grade, len_a2(P)), '2', 2*N, wb*len_a2(P)
    'T', 'Tuerca', sprintf('%s grado 8 o A194 2H', P.an.thr), '14', 14*N, 0
    'W', 'Arandela', 'plana Ø30 x 3, agujero 17', '8', 8*N, 0
    'VB', 'Viga de borde', sprintf('%s A36, 4 piezas VB1 a VB4 (lámina de la viga de borde)', P.bb.name), '-', 4, 15.8e-3*sum([bb_pieces(P).L])/4
    'T1', 'Placa de punta', sprintf('PL %gx%gx%g A36, 4 agujeros Ø%g', P.bb.tp, P.bb.hole), '1', 5, rho*prod(P.bb.tp)
    'TB', 'Tab de esquina', sprintf('PL %gx%gx%g A36, 2 agujeros Ø%g (E9)', P.bb.tab, P.bb.hole), '-', 1, rho*prod(P.bb.tab)
    'PB', 'Perno', sprintf('M%g x 40 A325 (u 8.8), tuerca y arandela', P.bb.bolt), '-', 22, 0
    'PV', 'Placa de viga IPE 200', sprintf('PL %gx%gx%g A36, 4 agujeros Ø%g; 12 con viga, 4 sin viga (A, D)', P.s2.pl, P.s2.hole), '-', 16, rho*prod(P.s2.pl)
    'AV', 'Varilla pasante', sprintf('Ø%g fy 4200, L = %g, rosca %s en %g mm de cada extremo', P.s2.db, s2_rod(P), P.s2.thr, s2_thread(P)), '-', 32, 2.47e-3*s2_rod(P)
    'TV', 'Tuerca', sprintf('%s grado 8 o A194 2H', P.s2.thr(1:3)), '-', 64, 0
    'WV', 'Arandela', sprintf('plana M%g (Ø%g x %g)', P.s2.db, P.s2.wsh), '-', 64, 0};
  rows = {};  tot = 0;
  for i = 1:size(it, 1)
    q = it{i,5};  kg = it{i,6};
    if kg > 0, ks = sprintf('%.1f', q*kg); else, ks = '-'; end
    rows{end+1} = {it{i,1}, it{i,2}, it{i,3}, it{i,4}, sprintf('%d', q), ks};
    tot = tot + q*kg;
  end
end

% =====================================================================
%  Drawings
% =====================================================================
function it = dr_anchors(P)
  % both anchors, same scale: A1 at y = 0, A2 at y = -75
  it = [dr_anchor1(P), shift(dr_anchor2(P), -75)];
  it{end+1} = d_text(-8, 0, 'A1', 'label', 'end');
  it{end+1} = d_text(-8, -75, 'A2', 'label', 'end');
end

function it = shift(it, dy)
  for i = 1:numel(it)
    p = it{i}.p;
    if strcmp(it{i}.t, 'circle'), p(2) = p(2) + dy; else, p(2:2:end) = p(2:2:end) + dy; end
    it{i}.p = p;
  end
end

function it = dr_anchor1(P)
  % threaded rod, thread along the whole length: only the cut length
  an = P.an;  d = an.db;  L = an.out + an.uT;
  it = {d_rectxy(0, -d/2, L, d/2, 'tabh')};
  it{end+1} = d_dim(0, d/2, L, d/2, 16, sprintf('%.0f', L));
  it{end+1} = d_dim(0, -d/2, L, -d/2, -14, 'roscada en toda su longitud');
end

function it = dr_anchor2(P)
  an = P.an;  d = an.db;  L = len_a2(P);
  it = {d_rectxy(0, -d/2, L, d/2, 'tabh')};
  it{end+1} = d_dim(0, d/2, L, d/2, 16, sprintf('%.0f', L));
  it{end+1} = d_dim(0, -d/2, L, -d/2, -14, 'roscada');
end

function it = dr_backplate(P)
  an = P.an;  bp = P.bp;
  it = {d_rectxy(-bp.w/2, -bp.h/2, bp.w/2, bp.h/2, 'plate')};
  for v = [-1 1]*an.vT, it{end+1} = d_circle(v, 0, an.hole/2, 'bolt'); end
  it{end+1} = d_dim(-bp.w/2, bp.h/2, bp.w/2, bp.h/2, 14, sprintf('%g', bp.w));
  it{end+1} = d_dim(-an.vT, -bp.h/2, an.vT, -bp.h/2, -12, sprintf('%g', 2*an.vT));
  it{end+1} = d_dim(an.vT, -bp.h/2, bp.w/2, -bp.h/2, -12, sprintf('%g', bp.w/2 - an.vT));
  it{end+1} = d_dim(bp.w/2, -bp.h/2, bp.w/2, bp.h/2, -12, sprintf('%g', bp.h));
  it = [it, holelab(an.vT, 0, an.hole)];
end

function it = dr_side(P, t)
  % side view: end plate, extra plate (column side), rib and beam (beam side, on site)
  bm = P.bm;  tp = P.ep.t;  td = P.dbl.t;  zt = t.ep_top;  zb = t.ep_bot;  x0 = -tp;  uL = -170;
  Ls = 5*ceil(zt/tan(pi/6)/5);  c = 15;
  it = {};
  for z = [0, -bm.tf, -bm.h+bm.tf, -bm.h], it{end+1} = d_line(uL, z, x0, z, 'hidden'); end
  it{end+1} = d_line(uL, 15, uL, -bm.h-15, 'cut');
  it{end+1} = d_text(-85, -100, 'IPE 240 (en obra)', 'small', 'middle');
  it{end+1} = d_rectxy(x0, zb, 0, zt, 'plate');
  it{end+1} = d_rectxy(0, 0, td, zt, 'plate2');
  it{end+1} = d_poly([x0 c; x0 zt; x0-20 zt; x0-Ls 0; x0-c 0], 'hidden');
  % anchors, faded (dashed outline): from the outer end of the thread to a cut in the concrete
  an = P.an;  g = P.g;  xo = x0 - an.twsh - an.tnut - an.pp;  xc = g + 70;
  it{end+1} = d_line(g, zb - 20, g, zt + 20, 'edge');
  for z = [t.zT t.zS]
    it{end+1} = d_rectxy(xo, z - an.db/2, xc, z + an.db/2, 'tabh');
    it{end+1} = d_rectxy(x0 - an.twsh, z - an.wsh/2, x0, z + an.wsh/2, 'hidden');
    it{end+1} = d_rectxy(x0 - an.twsh - an.tnut, z - an.nut/2, x0 - an.twsh, z + an.nut/2, 'hidden');
    it{end+1} = d_line(xc, z - an.db, xc, z + an.db, 'cut');
  end
  it{end+1} = d_text(g + 4, zb - 30, 'cara de la columna', 'small', 'start');
  % dimensions
  it{end+1} = d_dim(uL, zb, uL, -bm.h, 22, sprintf('%g', -bm.h - zb));
  it{end+1} = d_dim(uL, -bm.h, uL, 0, 22, sprintf('%g', bm.h));
  it{end+1} = d_dim(uL, 0, uL, zt, 22, sprintf('%g', zt));
  it{end+1} = d_dim(uL, zb, uL, zt, 50, sprintf('%g', zt - zb));
  xr = P.g + 70;
  it{end+1} = d_dim(xr, 0, xr, t.zT, -14, sprintf('%g', t.zT));
  zH = an.zH;  it{end+1} = d_line(x0 - 40, zH, xc, zH, 'center');
  it{end+1} = d_dim(xr, t.zT, xr, zH, -14, sprintf('%g', zH - t.zT));
  it{end+1} = d_dim(xr, zH, xr, zt, -14, sprintf('%g', zt - zH));
  it{end+1} = d_dim(xr, t.zS, xr, 0, -14, sprintf('%.1f', -t.zS));
  it{end+1} = d_dim(x0, zb, 0, zb, -16, sprintf('%g', tp), 'before');
  it{end+1} = d_dim(0, zb, td, zb, -16, sprintf('%g', td));
  % welds: shop (extra plate), site (flanges, web, rib)
  it{end+1} = d_weld(td, 2, 60, zt + 45, 1, 'arrow', sprintf('%g', P.dbl.w), '', 0, 0, 'refuerzos: bordes inf. e int.', 'weld5');
  it{end+1} = d_weld(x0, -bm.h + bm.tf/2, -120, -bm.h - 45, -1, 'both', sprintf('%g', P.w.flange), '', 1, 1, 'alas', 'weld5');
  it{end+1} = d_weld(x0, -140, -120, -170, -1, 'both', sprintf('%g', P.w.web), '', 0, 1, 'alma', 'weld5');
  it{end+1} = d_weld(x0 - Ls/2, zt*0.45, -120, zt + 45, -1, 'both', sprintf('%g', P.rib.w), '', 0, 1, 'rigidizador', 'weld5');
  it{end+1} = d_text(xr + 30, -4, 'z = 0: nivel sup. del ala', 'small', 'start');
  it{end+1} = d_text(xr + 30, t.zT - 2, 'anclaje superior', 'small', 'start');
  it{end+1} = d_text(xr + 30, zH - 2, 'anclaje superior, tipo CY', 'small', 'start');
  it{end+1} = d_text(xr + 30, t.zS - 2, 'anclaje de corte', 'small', 'start');
end

function it = dr_colside(P, t)
  % the end plate seen from the column: holes and the two extra plates (shop)
  an = P.an;  B2 = P.ep.w/2;  gp = P.dbl.gap/2;  zt = t.ep_top;  zb = t.ep_bot;
  it = {d_rectxy(-B2, zb, B2, zt, 'plate')};
  for sg = [-1 1]
    it{end+1} = d_rectxy(sg*gp, 0, sg*B2, zt, 'plate2');
    it{end+1} = d_line(sg*B2, -1.2, sg*gp, -1.2, 'weld5');
    it{end+1} = d_line(sg*(gp-1.2), -1.2, sg*(gp-1.2), zt, 'weld5');
  end
  for z = [t.zT t.zS], for v = [-1 1]*an.vT, it{end+1} = d_circle(v, z, an.hole/2, 'bolt'); end, end
  for v = [-1 1]*an.vT, it{end+1} = d_circle(v, an.zH, an.hole/2, 'hidden'); end   % type CY
  it{end+1} = d_line(0, zb, 0, zb + 12, 'beamline');  it{end+1} = d_line(0, zt, 0, zt - 12, 'beamline');
  it{end+1} = d_dim(-B2, zt, B2, zt, 30, sprintf('%g', P.ep.w));
  it{end+1} = d_dim(-an.vT, zt, an.vT, zt, 16, sprintf('%g', 2*an.vT));
  it{end+1} = d_dim(-B2, zb, -an.vT, zb, -16, sprintf('%g', B2 - an.vT), 'before');
  it{end+1} = d_dim(-an.vT, zb, an.vT, zb, -16, sprintf('%g', 2*an.vT));
  it{end+1} = d_dim(-B2, zb, -gp, zb, -34, sprintf('%g', B2 - gp));
  it{end+1} = d_dim(-gp, zb, gp, zb, -34, sprintf('%g', 2*gp));
  zz = sort([zb t.zS 0 t.zT an.zH zt]);
  for i = 1:numel(zz)-1
    it{end+1} = d_dim(B2, zz(i), B2, zz(i+1), -18, num2str(round(10*(zz(i+1) - zz(i)))/10));
  end
  it{end+1} = d_dim(-B2, zb, -B2, zt, 22, sprintf('%g', zt - zb));
  it{end+1} = d_weld(gp, zt*0.6, B2 + 45, zt + 30, 1, 'arrow', sprintf('%g', P.dbl.w), '', 0, 0, 'bordes inferior e interior', 'weld5');
  it{end+1} = d_text(0, -60, 'agujeros: según replanteo (nota 8)', 'small', 'middle');
  it{end+1} = d_text(-an.vT - an.hole/2 - 3, an.zH - 3, 'CY', 'small', 'end');
  it = [it, holelab(an.vT, t.zS, an.hole)];
  it{end+1} = d_text(0, -12, 'z = 0: nivel sup. del ala', 'small', 'middle');
end

function it = dr_beamside(P, t)
  % the end plate seen from the beam: beam outline and rib (site), punch marks
  bm = P.bm;  B2 = P.ep.w/2;  zt = t.ep_top;  zb = t.ep_bot;  an = P.an;
  it = {d_rectxy(-B2, zb, B2, zt, 'plate')};
  S = [-bm.b/2 0; bm.b/2 0; bm.b/2 -bm.tf; bm.tw/2 -bm.tf; bm.tw/2 -bm.h+bm.tf; bm.b/2 -bm.h+bm.tf; ...
       bm.b/2 -bm.h; -bm.b/2 -bm.h; -bm.b/2 -bm.h+bm.tf; -bm.tw/2 -bm.h+bm.tf; -bm.tw/2 -bm.tf; -bm.b/2 -bm.tf];
  for i = 1:size(S,1)
    j = mod(i, size(S,1)) + 1;
    it{end+1} = d_line(S(i,1), S(i,2), S(j,1), S(j,2), 'hidden');
  end
  it{end+1} = d_rectxy(-P.rib.t/2, 0, P.rib.t/2, zt, 'hidden');
  for z = [t.zT t.zS], for v = [-1 1]*an.vT, it{end+1} = d_circle(v, z, an.hole/2, 'bolt'); end, end
  for v = [-1 1]*an.vT, it{end+1} = d_circle(v, an.zH, an.hole/2, 'hidden'); end   % type CY
  it{end+1} = d_line(0, zt, 0, zt - 12, 'beamline');  it{end+1} = d_line(0, zb, 0, zb + 12, 'beamline');
  it{end+1} = d_line(-B2, 0, -B2 + 12, 0, 'beamline');  it{end+1} = d_line(B2, 0, B2 - 12, 0, 'beamline');
  it{end+1} = d_dim(-bm.b/2, zb, bm.b/2, zb, -16, sprintf('%g', bm.b));
  it{end+1} = d_dim(-B2, zb, -bm.b/2, zb, -16, sprintf('%g', B2 - bm.b/2), 'before');
  it{end+1} = d_dim(-B2, -bm.h, -B2, 0, 18, sprintf('%g', bm.h));
  it{end+1} = d_text(0, zb + 16, 'marcas de punzón: eje y ala superior', 'small', 'middle');
  it = [it, holelab(an.vT, t.zS, an.hole)];
end

function it = holelab(x, y, d)
  % diameter label of one hole, leader to the upper right
  a = d/2*0.7071;
  it = {d_line(x + a, y + a, x + a + 14, y + a + 14, 'center'), d_text(x + a + 15, y + a + 15, sprintf('Ø%g', d), 'label', 'start')};
end

function it = dr_supl(P, t)
  % the two extra plates as seen from the column, with the gap over the rib
  an = P.an;  B2 = P.ep.w/2;  gp = P.dbl.gap/2;  zt = t.ep_top;  w = B2 - gp;
  it = {};
  for sg = [-1 1]
    it{end+1} = d_rectxy(sg*gp, 0, sg*B2, zt, 'plate2');
    it{end+1} = d_circle(sg*an.vT, t.zT, an.hole/2, 'bolt');
    it{end+1} = d_circle(sg*an.vT, an.zH, an.hole/2, 'hidden');
    it{end+1} = d_line(sg*B2, -1.2, sg*gp, -1.2, 'weld5');
    it{end+1} = d_line(sg*(gp-1.2), -1.2, sg*(gp-1.2), zt, 'weld5');
  end
  it = [it, holelab(an.vT, t.zT, an.hole)];
  it{end+1} = d_dim(gp, zt, B2, zt, 12, sprintf('%g', w));
  it{end+1} = d_dim(-gp, zt, gp, zt, 12, sprintf('%g', 2*gp));
  it{end+1} = d_dim(gp, 0, an.vT, 0, -12, sprintf('%g', an.vT - gp));
  it{end+1} = d_dim(an.vT, 0, B2, 0, -12, sprintf('%g', B2 - an.vT));
  it{end+1} = d_dim(B2, 0, B2, t.zT, -12, sprintf('%g', t.zT));
  it{end+1} = d_dim(B2, t.zT, B2, an.zH, -12, sprintf('%g', an.zH - t.zT));
  it{end+1} = d_dim(B2, an.zH, B2, zt, -12, sprintf('%g', zt - an.zH));
  it{end+1} = d_text(-an.vT - an.hole/2 - 3, an.zH - 3, 'CY', 'small', 'end');
  it{end+1} = d_dim(-B2, 0, -B2, zt, 12, sprintf('%g', zt));
  it{end+1} = d_text(0, -24, 'borde inferior: nivel sup. del ala', 'small', 'middle');
end

function it = dr_rib(P, t)
  zt = t.ep_top;  Ls = 5*ceil(zt/tan(pi/6)/5);  c = 15;
  it = {d_poly([0 c; 0 zt; -20 zt; -Ls 0; -c 0], 'plate3')};
  it{end+1} = d_dim(-Ls, 0, 0, 0, -14, sprintf('%g', Ls));
  it{end+1} = d_dim(0, 0, 0, zt, -14, sprintf('%g', zt));
  it{end+1} = d_dim(-20, zt, 0, zt, 12, '20');
  it{end+1} = d_dim(-c, 0, 0, 0, -30, sprintf('%g', c), 'before');
  it{end+1} = d_dim(0, 0, 0, c, -32, sprintf('%g', c));


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
%  Border beam IPE 160 (user 2026-10-04, option a: tip plate, inner half-flanges cut)
% =====================================================================
function V = bb_pieces(P)
  % the 4 pieces of the border beam and their cuts/holes, from the grid of the floor plan
  bb = P.bb;  xB = 0;  xC = 4780;  xD = 9560;  xE = 10830;  y9 = -1270;  y4 = 0;  y3 = 4330;
  hp = bb.tp(2)/2;  cut = hp + bb.cl;  g2 = bb.gap/2;  wc = bb.tp(1) + bb.tw/2;     % web line off the tip
  wo = wc + bb.b/2;                                                                % outer flange edge off the tip
  V(1) = struct('mark', 'VB1', 'L', (xC - g2) - (xB - bb.ext), 'cuts', sprintf('%g desde el extremo oeste; %g en el extremo este', bb.ext + cut, cut - g2), ...
                'holes', sprintf('a %g y %g del extremo oeste; a %g del extremo este', bb.ext - bb.bx, bb.ext + bb.bx, bb.bx - g2));
  V(2) = struct('mark', 'VB2', 'L', (xD - g2) - (xC + g2), 'cuts', sprintf('%g en cada extremo', cut - g2), 'holes', sprintf('a %g de cada extremo', bb.bx - g2));
  V(3) = struct('mark', 'VB3', 'L', xE - (xD + g2), 'cuts', sprintf('%g en el extremo oeste; extremo este: destaje %gx%g arriba y abajo y media ala norte %g', ...
                cut - g2, ceil(bb.tf + bb.r), ceil(bb.b/2 + 10), bb.tab(2)), 'holes', sprintf('a %g del extremo oeste; a %g del extremo este', bb.bx - g2, 40));
  V(4) = struct('mark', 'VB4', 'L', ceil((y3 + 60) - (y9 - wo)), 'cuts', sprintf('%g desde el extremo norte; %g centrado a %g del extremo norte', 60 + cut, 2*cut, y3 + 60 - y4), ...
                'holes', sprintf('a %g y %g del extremo norte; a %g y %g', 60 - bb.bx, 60 + bb.bx, y3 + 60 - bb.bx, y3 + 60 + bb.bx));
end

function it = flange_plan(xa, xb, yo, yi, ywf, cuts, s)
  % top flange of a border beam in plan between xa and xb: outer edge yo, inner edge yi, inner
  % half cut to the web face ywf over the intervals in cuts (rows [c0 c1])
  P = [xa yo; xb yo; xb yi];
  for k = size(cuts, 1):-1:1
    c = cuts(k,:);  P = [P; c(2) yi; c(2) ywf; c(1) ywf; c(1) yi];
  end
  P = [P; xa yi];
  it = d_poly(P, s);
end

function it = dr_bb_join(P, kind)
  % connection at a cantilever tip: plan (top) and elevation from outside (below). 'end2': two
  % beams end at the tip (C9, D9); 'pass': the beam passes the tip (B9, E3, E4)
  bb = P.bb;  bm = P.bm;  t = bb.tp(1);  hp = bb.tp(2)/2;  H = bb.tp(3);  L = 300;  dz = -330;  it = {};
  yw = -(t + bb.tw/2);  yo = yw - bb.b/2;  yi = yw + bb.b/2;  ywf = -t;  cut = hp + bb.cl;  g2 = bb.gap/2;
  % plan: cantilever, tip plate, beam(s)
  it{end+1} = d_rectxy(-bm.b/2, 0, bm.b/2, 170, 'beam');
  it{end+1} = d_line(-bm.tw/2, 0, -bm.tw/2, 170, 'hidden');  it{end+1} = d_line(bm.tw/2, 0, bm.tw/2, 170, 'hidden');
  it{end+1} = d_rectxy(-hp, -t, hp, 0, 'plate');
  if strcmp(kind, 'end2')
    it{end+1} = flange_plan(-L, -g2, yo, yi, ywf, [-cut -g2], 'beam');
    it{end+1} = flange_plan(g2, L, yo, yi, ywf, [g2 cut], 'beam');
    bx = [-bb.bx bb.bx];
  else
    it{end+1} = flange_plan(-L, L, yo, yi, ywf, [-cut cut], 'beam');
    bx = [-bb.bx bb.bx];
  end
  for x = bx, it{end+1} = d_rectxy(x - bb.bolt/2, yw - bb.tw/2 - 10, x + bb.bolt/2, 10, 'bolt'); end
  it{end+1} = d_text(0, 180, 'voladizo IPE 240', 'small', 'middle');
  it{end+1} = d_text(L + 10, yw - 4, sprintf('%s (vista superior)', bb.name), 'small', 'start');
  it{end+1} = d_dim(-hp, -t, hp, -t, 70, sprintf('%g', 2*hp));
  it{end+1} = d_dim(-cut, yo, cut, yo, -18, sprintf('corte de media ala: %g', 2*cut));
  if strcmp(kind, 'end2')
    it{end+1} = d_dim(-cut, yo, -g2, yo, -18, sprintf('%g', cut - g2));
    it{end+1} = d_dim(g2, yo, cut, yo, -18, sprintf('%g', cut - g2));
    it{end+1} = d_dim(-g2, yo - 30, g2, yo - 30, -10, sprintf('%g', 2*g2));
    it(end-3) = [];
  end
  % elevation from outside (z down from the top of steel), shifted by dz
  e = @(z) z + dz;
  it{end+1} = d_rectxy(-hp, e(-H), hp, e(0), 'hidden');
  for z = [0, -bm.tf, -bm.h + bm.tf, -bm.h], it{end+1} = d_line(-bm.b/2, e(z), bm.b/2, e(z), 'hidden'); end
  if strcmp(kind, 'end2'), segs = [-L -g2; g2 L]; else, segs = [-L L]; end
  for k = 1:size(segs, 1)
    it{end+1} = d_rectxy(segs(k,1), e(-bb.h), segs(k,2), e(0), 'beam');
    it{end+1} = d_line(segs(k,1), e(-bb.tf), segs(k,2), e(-bb.tf), 'beamline');
    it{end+1} = d_line(segs(k,1), e(-bb.h + bb.tf), segs(k,2), e(-bb.h + bb.tf), 'beamline');
  end
  for x = bx, for z = bb.bz, it{end+1} = d_circle(x, e(z), bb.hole/2, 'bolt'); end, end
  it{end+1} = d_dim(-bb.bx, e(-H) - 10, bb.bx, e(-H) - 10, -16, sprintf('%g', 2*bb.bx));
  it{end+1} = d_dim(L, e(0), L, e(bb.bz(1)), -16, sprintf('%g', -bb.bz(1)));
  it{end+1} = d_dim(L, e(bb.bz(1)), L, e(bb.bz(2)), -16, sprintf('%g', bb.bz(1) - bb.bz(2)));
  it{end+1} = d_dim(-L, e(-bb.h), -L, e(0), 16, sprintf('%g', bb.h));
  it{end+1} = d_dim(hp + 30, e(-H), hp + 30, e(0), -10, sprintf('%g', H));
  it{end+1} = d_text(0, e(-H) - 40, sprintf('vista desde afuera: placa T1 y voladizo detrás (línea punteada); %d pernos M%g', 2*numel(bx), bb.bolt), 'small', 'middle');
end

function it = dr_bb_tip(P)
  % tip plate T1, welded across the end of each IPE 240 cantilever (shop), seen from outside
  bb = P.bb;  bm = P.bm;  t = bb.tp(1);  hp = bb.tp(2)/2;  H = bb.tp(3);  it = {};
  it{end+1} = d_rectxy(-hp, -H, hp, 0, 'plate');
  for z = [0, -bm.tf, -bm.h + bm.tf, -bm.h], it{end+1} = d_line(-bm.b/2, z, bm.b/2, z, 'hidden'); end
  for x = [-bm.tw/2 bm.tw/2], it{end+1} = d_line(x, -bm.tf, x, -bm.h + bm.tf, 'hidden'); end
  for x = [-bb.bx bb.bx], for z = bb.bz, it{end+1} = d_circle(x, z, bb.hole/2, 'void'); end, end
  it{end+1} = d_dim(-hp, -H, hp, -H, -16, sprintf('%g', 2*hp));
  it{end+1} = d_dim(-bb.bx, 0, bb.bx, 0, 16, sprintf('%g', 2*bb.bx));
  it{end+1} = d_dim(hp, -H, hp, 0, -16, sprintf('%g', H));
  it{end+1} = d_dim(-hp, 0, -hp, bb.bz(1), 16, sprintf('%g', -bb.bz(1)));
  it{end+1} = d_dim(-hp, bb.bz(1), -hp, bb.bz(2), 16, sprintf('%g', bb.bz(1) - bb.bz(2)));
  it{end+1} = d_text(hp + 30, bb.bz(1) - 4, sprintf('4 agujeros Ø%g', bb.hole), 'small', 'start');
  it{end+1} = d_text(hp + 30, -H/2 - 20, sprintf('IPE 240 detrás: filetes %g todo alrededor (taller)', bb.wtp), 'small', 'start');
  it{end+1} = d_text(0, -H - 46, sprintf('PL %g, A36; e = %g', t, t), 'small', 'middle');
end

function it = dr_bb_corner(P)
  % corner E9 in plan: the east beam VB4 ends at the slab corner, the piece VB3 frames into its web
  bb = P.bb;  it = {};  t = bb.tp(1);  wc = t + bb.tw/2;  b2 = bb.b/2;  L = 300;  tb = bb.tab;
  cy = ceil(bb.tf + bb.r);  cx = ceil(b2 + 10);
  % VB4 (north-south), web at x = wc, south end at y = -(wc + b2)
  ys = -(wc + b2);
  it{end+1} = d_rectxy(wc - b2, ys, wc + b2, L, 'beam');
  it{end+1} = d_rectxy(wc - bb.tw/2, ys, wc + bb.tw/2, L, 'beamline');
  % tab on the west face of its web, plane east-west, on the north side of the VB3 web
  yw3 = -wc;  it{end+1} = d_rectxy(wc - bb.tw/2 - tb(2), yw3 + bb.tw/2, wc - bb.tw/2, yw3 + bb.tw/2 + tb(1), 'tab');
  % VB3 (east-west), web at y = -wc, end at x = wc - tw/2 - gap
  xe = wc - bb.tw/2 - bb.gap;
  P3 = [-L, yw3 - b2; xe - cx, yw3 - b2; xe - cx, yw3 - bb.tw/2; xe, yw3 - bb.tw/2; xe, yw3 + bb.tw/2; ...
        wc - bb.tw/2 - tb(2) - 10, yw3 + bb.tw/2; wc - bb.tw/2 - tb(2) - 10, yw3 + b2; -L, yw3 + b2];
  it{end+1} = d_poly(P3, 'beam');
  it{end+1} = d_rectxy(xe - 40 - bb.bolt/2, yw3 - bb.tw/2 - 10, xe - 40 + bb.bolt/2, yw3 + bb.tw/2 + tb(1) + 10, 'bolt');
  it{end+1} = d_text(wc + b2 + 10, L - 20, 'VB4', 'small', 'start');
  it{end+1} = d_text(-L + 10, yw3 + b2 + 10, 'VB3', 'small', 'start');
  it{end+1} = d_line(wc - bb.tw/2 - tb(2)/2, yw3 + bb.tw/2 + tb(1), -150, yw3 + b2 + 90, 'cut');
  it{end+1} = d_text(-152, yw3 + b2 + 94, sprintf('tab PL %gx%gx%g, 2 pernos M%g', tb, bb.bolt), 'small', 'end');
  it{end+1} = d_dim(xe - cx, yw3 - b2, xe, yw3 - b2, -18, sprintf('destaje %g (alto %g)', cx, cy));
  it{end+1} = d_dim(wc - bb.tw/2 - tb(2) - 10, yw3 + b2, xe, yw3 + b2, 30, sprintf('media ala norte: %g', xe - (wc - bb.tw/2 - tb(2) - 10)));
  it{end+1} = d_dim(xe, yw3 - b2 - 40, wc - bb.tw/2, yw3 - b2 - 40, -8, sprintf('%g', bb.gap));
  it{end+1} = d_text(-L + 10, ys - 30, 'borde de losa (esquina E9)', 'small', 'start');
end

function it = dr_bb_key(P)
  % border beams in plan with their marks; cantilever tips with the tip plates T1
  bb = P.bb;  xB = 0;  xC = 4780;  xD = 9560;  xE = 10830;  y9 = -1270;  y4 = 0;  y3 = 4330;  it = {};
  for x = [xB xC xD], it{end+1} = d_line(x, y9, x, y4 - 200, 'beamline'); end
  for y = [y4 y3], it{end+1} = d_line(xD + 200, y, xE, y, 'beamline'); end
  it{end+1} = d_line(xB - bb.ext, y9 - 12, xE, y9 - 12, 'plate');
  it{end+1} = d_line(xE + 12, y9 - 53, xE + 12, y3 + 60, 'plate');
  for p = [xB y9; xC y9; xD y9]', it{end+1} = d_rectxy(p(1) - 75, p(2) - 10, p(1) + 75, p(2), 'tab'); end
  for p = [xE y4; xE y3]', it{end+1} = d_rectxy(p(1), p(2) - 75, p(1) + 10, p(2) + 75, 'tab'); end
  for g = {xB, 'B'; xC, 'C'; xD, 'D'; xE, 'E'}', it{end+1} = d_text(g{1}, y9 - 420, g{2}, 'grid', 'middle'); end
  for g = {y9, '9'; y4, '4'; y3, '3'}', it{end+1} = d_text(xE + 500, g{1} - 30, g{2}, 'grid', 'middle'); end
  lab = {(xB + xC)/2, y9 - 200, 'VB1';  (xC + xD)/2, y9 - 200, 'VB2';  (xD + xE)/2, y9 - 200, 'VB3';  xE + 220, (y9 + y3)/2, 'VB4'};
  for k = 1:4, it{end+1} = d_text(lab{k,1}, lab{k,2}, lab{k,3}, 'code', 'middle'); end
  it{end+1} = d_text(xE + 200, y9 - 200, 'E9', 'small', 'start');
  it{end+1} = d_text(xB, y4, 'voladizos IPE 240', 'small', 'middle');
  it{end+1} = d_dim(xB, y9 - 600, xC, y9 - 600, 0, '4780');  it{end+1} = d_dim(xC, y9 - 600, xD, y9 - 600, 0, '4780');
  it{end+1} = d_dim(xD, y9 - 600, xE, y9 - 600, 0, '1270');
  it{end+1} = d_dim(xE + 800, y9, xE + 800, y4, 0, '1270');  it{end+1} = d_dim(xE + 800, y4, xE + 800, y3, 0, '4330');
end
