function file = make_plan_sheets(DB, M, J, outdir, opts)
% MAKE_PLAN_SHEETS  A2 sheets for the structural drawings, in Spanish:
%   1  general plan of the joints and joint schedule
%   2  collar plate types and connection details (M, C, LB, beam to beam)
%   3+ plan of every joint, 8 per sheet
%
%   make_plan_sheets(DB, M, default_joint(), 'reports', opts)
%
% opts.project, opts.subtitle   title strip text
% opts.beam, opts.column        section names for the notes
% opts.stab   stability plates on the cap for C beams, [t L depth clear] mm
% opts.gap    beam end to column face shown on the drawings, mm (<=)
% opts.python Python command
%
% All geometry and text is produced here from J, the joint classes, the
% grid (grid_lines.m) and the model; joint_pdf.py only prints it.
% Writes <outdir>/planos_uniones.json and .pdf.

  if nargin < 5, opts = struct(); end
  def = struct('python', 'python3', 'stab', [8 60 25 3], 'gap', 10, ...
               'project', 'Estructura metálica - uniones de vigas y columnas', ...
               'subtitle', '', 'beam', 'IPE 160', ...
               'column', sprintf('HSS %gx%gx%g', J.cl.D, J.cl.B, J.cl.t));
  f = fieldnames(def);
  for i = 1:numel(f), if ~isfield(opts, f{i}), opts.(f{i}) = def.(f{i}); end, end
  if isempty(opts.subtitle)
    opts.subtitle = sprintf(['Vigas %s, columnas %s, placas y ángulos A36, electrodo E70XX. ' ...
                             'Medidas en mm.'], opts.beam, opts.column);
  end
  if ~exist(outdir, 'dir'), mkdir(outdir); end
  here = fileparts(mfilename('fullpath'));

  C  = joint_classes();
  T  = collar_types(DB, J, C);
  P  = plan_layout(M, DB);
  tstyle = {'plate', 'plate2', 'plate3'};
  typeOf = containers.Map();
  for t = 1:numel(T)
    for k = 1:numel(T(t).joints), typeOf(T(t).joints{k}) = t; end
  end
  % joints in grid order: A1, A2, ... B1, ...
  jn = {};  gn = {};
  for k = 1:size(C, 1)
    if ~isKey(P.name, C{k,1}), continue; end
    jn{end+1} = C{k,1};  gn{end+1} = P.name(C{k,1});
  end
  order = grid_order(gn, P.grid);
  jn = jn(order);  gn = gn(order);

  % ---------------------------------------------------------------- sheet 1
  n = 1;
  key = blk_draw(key_plan(DB, M, J, C, P, typeOf, tstyle), 330, ...
                 sprintf('DETALLE %d - PLANTA GENERAL DE UNIONES', n), ...
                 'Collarines coloreados por tipo. Las correas no se muestran.');
  rows = {};
  for k = 1:numel(jn)
    jt = DB.joints(strcmp({DB.joints.joint}, jn{k}));
    [map, Jj] = joint_config(jt, J, C);
    codes = cellfun(@code_es, map.sides, 'UniformOutput', false);
    rows{end+1} = [{gn{k}, T(typeOf(jn{k})).name}, codes([1 2 3 4]), {placement(Jj.pl.over, map.strongAxis, J)}];
  end
  sched = blk_table({'Unión', 'Collarín', 'O', 'N', 'E', 'S', 'Colocación del collarín'}, rows, ...
                    [0.1 0.11 0.07 0.07 0.07 0.07 0.51], {}, {});
  notes = {
    'Medidas en milímetros.'
    sprintf('Separación entre el extremo de la viga y la cara de la columna: ≤ %g mm.', opts.gap)
    'Collarín inferior: soldado a la columna en taller. Collarín superior: se coloca sobre las alas superiores y se suelda en obra.'
    sprintf('Collarines a columna: filete de %g mm en todo el contorno. Alas de vigas M a collarines: filete de %g mm en 3 lados.', J.wl.leg_col, J.wl.leg_fl)
    'Las vigas C no se sueldan al collarín superior: quedan libres para girar.'
    'Las correas no se muestran en estos planos.'};
  legend = {
    'M   viga a momento: ambas alas soldadas a los collarines superior e inferior (detalle 4)'
    'C   viga a corte: apoyada y soldada solo al collarín inferior, con placas de estabilidad (detalle 5)'
    'LB  viga que llega bajo el collarín: apoyada en un ángulo soldado a la columna (detalles 6 y 7)'
    '—   sin viga'
    'Unión viga-viga a corte: ver detalles 8 y 9'};
  right = {blk_h(2, 'Cuadro de uniones'), sched, blk_space(4), blk_h(2, 'Simbología'), ...
           blk_draw(legend_drawing(tstyle, T), 62, '', ''), blk_space(2)};
  for i = 1:numel(legend), right{end+1} = blk_p(legend{i}); end
  right = [right, {blk_space(3), blk_h(2, 'Notas generales')}];
  for i = 1:numel(notes), right{end+1} = blk_p(sprintf('%d. %s', i, notes{i})); end
  B = {blk_row([0.63 0.37], {{key}, right})};

  % ---------------------------------------------------------------- sheet 2
  B = [B, {blk_page()}];
  d = cell(1, 8);
  for t = 1:numel(T)
    n = n + 1;
    d{t} = blk_draw(type_drawing(T(t), J, tstyle{min(t,3)}), 150, ...
       sprintf('DETALLE %d - COLLARÍN TIPO %s', n, T(t).name), ...
       sprintf(['PL %g x %g x %g mm (superior) y PL %g x %g x %g mm (inferior). %d uniones, ' ...
                '%d placas: %s. La abertura es el contorno de la columna más la holgura de montaje.'], ...
               T(t).t(1), T(t).LD, T(t).LB, T(t).t(2), T(t).LD, T(t).LB, numel(T(t).joints), ...
               2*numel(T(t).joints), strjoin(cellfun(@(j) P.name(j), T(t).joints, 'UniformOutput', false), ', ')));
  end
  n = n + 1;  nM = n;
  dM = blk_draw(section_moment(J, opts), 150, sprintf('DETALLE %d - UNIÓN A MOMENTO (M)', n), ...
                'Corte a lo largo de la viga.');
  n = n + 1;  nC = n;
  dC = blk_draw(section_shear(J, opts), 150, sprintf('DETALLE %d - UNIÓN A CORTE SOBRE EL COLLARÍN (C)', n), ...
                'Corte a lo largo de la viga. El ala superior no se suelda.');
  n = n + 1;
  dL = blk_draw(section_seat(J, opts), 175, sprintf('DETALLE %d - VIGA BAJO EL COLLARÍN, APOYO EN ÁNGULO (LB)', n), ...
                'Corte a lo largo de la viga. La altura de la viga respecto al collarín es la del proyecto.');
  n = n + 1;
  lbj = lb_joints(DB, J, C, P);
  dF = blk_draw(seat_front(J, lbj), 175, sprintf('DETALLE %d - ÁNGULO DE APOYO, VISTA DE LA CARA DE LA COLUMNA', n), ...
                sprintf(['El ángulo cubre el ancho plano de la cara: sus soldaduras (filete de %g mm en los dos ' ...
                         'extremos, %g mm de alto) quedan junto a las paredes laterales.'], J.nl.leg_a, J.nl.ang(1)));
  n = n + 1;
  dV = blk_draw(vv_elevation(J, opts), 175, sprintf('DETALLE %d - UNIÓN VIGA-VIGA A CORTE, ELEVACIÓN', n), ...
                'Recorte de alas superior e inferior de la viga soportada; alma soldada al alma de la viga soportante.');
  n = n + 1;
  dP = blk_draw(vv_plan(J), 175, sprintf('DETALLE %d - UNIÓN VIGA-VIGA A CORTE, PLANTA', n), ...
                sprintf(['Aplica a todas las uniones viga-viga del detalle 1 (%d ubicaciones). En ' ...
                         'esquinas se recorta la viga marcada en el detalle 1.'], numel(P.vv)));
  B = [B, {blk_row([0.21 0.21 0.29 0.29], {{d{1}}, {d{2}}, {dM}, {dC}}), blk_space(6), ...
           blk_row([0.28 0.22 0.3 0.2], {{dL}, {dF}, {dV}, {dP}})}];

  % ---------------------------------------------------------------- joint plans
  per = 8;
  for s0 = 1:per:numel(jn)
    B = [B, {blk_page()}];
    for r0 = s0:4:min(s0 + per - 1, numel(jn))
      cells = {};
      for k = r0:min(r0 + 3, numel(jn))
        jt = DB.joints(strcmp({DB.joints.joint}, jn{k}));
        [map, Jj] = joint_config(jt, J, C);
        t = typeOf(jn{k});
        n = n + 1;
        codes = cellfun(@code_es, map.sides, 'UniformOutput', false);
        cells{end+1} = {blk_draw(joint_plan(map, Jj, tstyle{min(t,3)}, opts), 160, ...
            sprintf('DETALLE %d - UNIÓN %s, COLLARÍN TIPO %s', n, gn{k}, T(t).name), ...
            sprintf('O N E S: %s. Lado de %g mm de la columna en dirección %s.', ...
                    strjoin(codes, ' '), J.cl.D, dir_es(map.strongAxis)))};
      end
      while numel(cells) < 4, cells{end+1} = {blk_space(1)}; end
      B = [B, {blk_row([0.25 0.25 0.25 0.25], cells), blk_space(4)}];
    end
  end

  nsheet = 2 + ceil(numel(jn)/per);
  sheets = {'Planta general y cuadro de uniones', 'Collarines y detalles de uniones'};
  for s = 3:nsheet, sheets{end+1} = sprintf('Plantas de uniones (%d de %d)', s - 2, nsheet - 2); end
  doc = struct('title', 'Uniones - planos', 'page', 'A2L', 'fs', 1.35, 'blocks', {B}, ...
               'frame', struct('project', opts.project, 'subtitle', opts.subtitle, ...
                               'sheetword', 'Lámina', 'sheets', {sheets}));
  base = fullfile(outdir, 'planos_uniones');
  fid = fopen([base '.json'], 'w');
  if fid < 0, error('Cannot write %s.json', base); end
  fprintf(fid, '%s', jsonencode(doc));
  fclose(fid);
  [st, out] = system(sprintf('%s "%s" "%s.json" "%s.pdf"', opts.python, ...
                     fullfile(here, 'python_support_scripts', 'joint_pdf.py'), base, base));
  fprintf('%s', out);
  if st ~= 0, error('PDF generation failed (see the message above).'); end
  file = [base '.pdf'];
end

% =====================================================================
%  Words
% =====================================================================
function s = code_es(c)
  switch c
    case 'M',  s = 'M';
    case 'S',  s = 'C';
    case 'NL', s = 'LB';
    otherwise, s = '—';
  end
end

function s = dir_es(axis)
  if strcmp(axis, 'Y'), s = 'N-S'; else, s = 'E-O'; end
end

function s = placement(over, axis, J)
  side = {'O', 'N', 'E', 'S'};
  s = ['lado largo ' dir_es(axis)];
  short = find(over < J.pl.L_lap + J.st.gap);
  for i = short, s = [s sprintf(', franja de %g mm al %s', over(i), side{i})]; end
end

function o = grid_order(gn, G)
  key = zeros(1, numel(gn));
  for k = 1:numel(gn)
    iv = find(strcmp(G.v(:,1), gn{k}(1)));
    key(k) = 100*iv + str2double(gn{k}(2:end));
  end
  [~, o] = sort(key);
end

% LB joints: grid name and the width of the face the angle is welded to
function L = lb_joints(DB, J, C, P)
  L = struct('name', {}, 'face', {});
  for k = 1:size(C, 1)
    if ~any(strcmp(C(k,2:5), 'NL')), continue; end
    jt = DB.joints(strcmp({DB.joints.joint}, C{k,1}));
    [~, Jj] = joint_config(jt, J, C);
    L(end+1) = struct('name', P.name(C{k,1}), 'face', Jj.nl.face);
  end
end

function La = seat_length(J, face)
  if isempty(J.nl.La), La = face - 2*1.5*J.cl.t - 2*J.nl.leg_a; else, La = J.nl.La; end
end

% =====================================================================
%  Detail 1: general plan
% =====================================================================
function it = key_plan(DB, M, J, C, P, typeOf, tstyle)
  it = {};
  xy = 1000*M.pt.xyz(:, 1:2);
  idx = containers.Map(M.pt.name, num2cell(1:numel(M.pt.name)));
  ext = [min(xy(:,1)) max(xy(:,1)) min(xy(:,2)) max(xy(:,2))];
  G = P.grid;  e = 900;  rb = 260;
  % grid lines and bubbles
  for g = 1:size(G.v, 1)
    a = 1000*G.v{g,2};  b = 1000*G.v{g,3};  u = (b - a)/norm(b - a);
    p0 = a + (ext(3) - e - a(2))/u(2)*u;  p1 = a + (ext(4) + e - a(2))/u(2)*u;
    it{end+1} = d_line(p0(1), p0(2), p1(1), p1(2), 'axis');
    for pe = {p0 - rb*u, p1 + rb*u}
      q = pe{1};
      it{end+1} = d_circle(q(1), q(2), rb, 'bubble');
      it{end+1} = d_text(q(1), q(2) - 95, G.v{g,1}, 'grid', 'middle');
    end
  end
  for g = 1:size(G.h, 1)
    y = 1000*G.h{g,2};
    it{end+1} = d_line(ext(1) - e, y, ext(2) + e, y, 'axis');
    for x = [ext(1) - e - rb, ext(2) + e + rb]
      it{end+1} = d_circle(x, y, rb, 'bubble');
      it{end+1} = d_text(x, y - 95, G.h{g,1}, 'grid', 'middle');
    end
  end
  % IPE beams
  for i = P.ipe
    a = xy(idx(M.fr.ptI{i}), :);  b = xy(idx(M.fr.ptJ{i}), :);
    it{end+1} = d_line(a(1), a(2), b(1), b(2), 'beamline');
  end
  % collars and codes
  dirs = [-1 0; 0 1; 1 0; 0 -1];
  for k = 1:size(C, 1)
    jt = DB.joints(strcmp({DB.joints.joint}, C{k,1}));
    if isempty(jt), continue; end
    [map, Jj] = joint_config(jt, J, C);
    p0 = 1000*jt.xyz(1:2);
    [hx, hy, bx] = plan_box(Jj.pl.over, map.strongAxis, J.cl);
    it{end+1} = d_rectxy(p0(1)+bx(1), p0(2)+bx(3), p0(1)+bx(2), p0(2)+bx(4), tstyle{min(typeOf(jt.joint),3)});
    it{end+1} = d_rectxy(p0(1)-hx, p0(2)-hy, p0(1)+hx, p0(2)+hy, 'column');
    face = [hx hy hx hy];
    for s = 1:4
      switch map.sides{s}
        case 'M',  st = 'codeM';
        case 'S',  st = 'codeS';
        case 'NL', st = 'codeNL';
        otherwise, continue
      end
      a = p0 + (face(s) + Jj.pl.over(s))*dirs(s,:);  b = a + 380*dirs(s,:);
      it{end+1} = d_line(a(1), a(2), b(1), b(2), st);
    end
    it{end+1} = d_text(p0(1) + bx(2) + 70, p0(2) + bx(4) + 70, ...
                       sprintf('%s (%s)', P.name(jt.joint), char('A' + typeOf(jt.joint) - 1)), 'big', 'start');
  end
  % beam to beam connections: diamond, and a bar across each cut beam
  for v = P.vv
    p = 1000*v.xy;  r = 120;
    it{end+1} = d_poly([p(1)-r p(2); p(1) p(2)+r; p(1)+r p(2); p(1) p(2)-r], 'vv');
    for c = 1:numel(v.coped)
      i = find(strcmp(M.fr.name, v.coped{c}), 1);
      a = xy(idx(M.fr.ptI{i}), :);  b = xy(idx(M.fr.ptJ{i}), :);
      if norm(a - p) > norm(b - p), q = a; else, q = b; end
      u = (q - p)/norm(q - p);  nn = [-u(2) u(1)];  m = p + 300*u;
      it{end+1} = d_line(m(1) - 110*nn(1), m(2) - 110*nn(2), m(1) + 110*nn(1), m(2) + 110*nn(2), 'vvcut');
    end
  end
  it = [it, compass(ext(2) + e + 1400, ext(4) + e - 300, 380)];
end

function it = legend_drawing(tstyle, T)
  it = {};  y = 0;  dy = 120;
  rows = {'codeM', 'M: viga a momento'; 'codeS', 'C: viga a corte sobre el collarín'; ...
          'codeNL', 'LB: viga bajo el collarín, sobre ángulo'};
  for i = 1:size(rows, 1)
    it{end+1} = d_line(0, y, 180, y, rows{i,1});
    it{end+1} = d_text(230, y - 18, rows{i,2}, 'label', 'start');
    y = y - dy;
  end
  for t = 1:numel(T)
    it{end+1} = d_rectxy(40, y - 40, 140, y + 40, tstyle{min(t,3)});
    it{end+1} = d_text(230, y - 18, sprintf('Collarín tipo %s', T(t).name), 'label', 'start');
    y = y - dy;
  end
  r = 45;
  it{end+1} = d_poly([90-r y; 90 y+r; 90+r y; 90 y-r], 'vv');
  it{end+1} = d_line(20, y, 160, y, 'grid');
  it{end+1} = d_text(230, y - 18, 'Unión viga-viga a corte', 'label', 'start');
  y = y - dy;
  it{end+1} = d_line(20, y, 160, y, 'beamline');
  it{end+1} = d_line(110, y - 45, 110, y + 45, 'vvcut');
  it{end+1} = d_text(230, y - 18, 'Viga que se recorta y suelda', 'label', 'start');
  y = y - dy;
  it{end+1} = d_line(0, y, 180, y, 'axis');
  it{end+1} = d_text(230, y - 18, 'Eje de construcción', 'label', 'start');
  it{end+1} = d_line(1400, 60, 1400, y, 'white');         % keeps the legend at a sensible width
end

function it = compass(x, y, s)
  it = {d_line(x, y - s, x, y + s, 'compass'), d_line(x - s, y, x + s, y, 'compass'), ...
        d_poly([x - s*0.12, y + s*0.55; x, y + s; x + s*0.12, y + s*0.55], 'compass'), ...
        d_text(x, y + s*1.12, 'N', 'compass', 'middle'), d_text(x, y - s*1.35, 'S', 'compass', 'middle'), ...
        d_text(x + s*1.12, y - s*0.1, 'E', 'compass', 'start'), d_text(x - s*1.12, y - s*0.1, 'O', 'compass', 'end')};
end

% =====================================================================
%  Collar plate types
% =====================================================================
function [hx, hy, box] = plan_box(over, axis, c)
  if strcmp(axis, 'Y'), hx = c.B/2; hy = c.D/2; else, hx = c.D/2; hy = c.B/2; end
  box = [-hx - over(1), hx + over(3), -hy - over(4), hy + over(2)];
end

function it = type_drawing(T, J, style)
  D = J.cl.D;  Bc = J.cl.B;
  a = T.oD(1);  b = T.oB(1);
  it = {d_rectxy(0, 0, T.LD, T.LB, style), d_rectxy(a, b, a + D, b + Bc, 'void'), ...
        d_line(a + D/2, -25, a + D/2, T.LB + 25, 'center'), ...
        d_line(-25, b + Bc/2, T.LD + 25, b + Bc/2, 'center')};
  it{end+1} = d_dim(0, 0, a, 0, -30, mm_t(a));
  it{end+1} = d_dim(a, 0, a + D, 0, -30, mm_t(D));
  it{end+1} = d_dim(a + D, 0, T.LD, 0, -30, mm_t(T.LD - a - D));
  it{end+1} = d_dim(0, 0, T.LD, 0, -60, mm_t(T.LD));
  it{end+1} = d_dim(0, 0, 0, b, 30, mm_t(b), 'before');
  it{end+1} = d_dim(0, b, 0, b + Bc, 30, mm_t(Bc));
  it{end+1} = d_dim(0, b + Bc, 0, T.LB, 30, mm_t(T.LB - b - Bc));
  it{end+1} = d_dim(0, 0, 0, T.LB, 60, mm_t(T.LB));
  it{end+1} = d_text(a + D/2, b + Bc/2 - 16, 'abertura', 'small', 'middle');
end

% =====================================================================
%  Sections along a beam: x from the column face (0), y up from the top
%  of the lower collar (0)
% =====================================================================
function it = column_cut(J, ytop, ybot)
  c = J.cl;
  it = {d_rectxy(-c.t, ybot, 0, ytop, 'column'), d_rectxy(-60, ybot, -c.t, ytop, 'void'), ...
        d_line(-60, ybot, -60, ytop, 'cut'), d_text(-32, ybot - 16, 'pared de la columna', 'small', 'middle')};
end

function it = beam_elev(x0, x1, ybot, b, style)
  it = {d_rectxy(x0, ybot, x1, ybot + b.h, style), ...
        d_line(x0, ybot + b.tf, x1, ybot + b.tf, 'grid'), ...
        d_line(x0, ybot + b.h - b.tf, x1, ybot + b.h - b.tf, 'grid'), ...
        d_line(x1, ybot - 10, x1, ybot + b.h + 10, 'cut')};
end

function it = section_moment(J, opts)
  b = J.bm;  p = J.pl;  g = opts.gap;  ov = p.L_lap + J.st.gap;  h = b.h;  x1 = ov + 150;
  ytop = h + p.t_cap;
  it = column_cut(J, ytop, -p.t_shf - 70);
  it = [it, beam_elev(g, x1, 0, b, 'beam')];
  it{end+1} = d_rectxy(0, -p.t_shf, ov, 0, 'plate');
  it{end+1} = d_rectxy(0, h, ov, ytop, 'plate');
  it{end+1} = d_line(ov - p.L_lap, 0, ov, 0, 'weld');
  it{end+1} = d_line(ov - p.L_lap, h, ov, h, 'weld');
  it{end+1} = d_tri(ov, h, 6, 6, 'weldf');
  it{end+1} = d_tri(ov, 0, 6, -6, 'weldf');
  it{end+1} = d_tri(0, ytop, 5, 5, 'weldf');
  it{end+1} = d_tri(0, 0, 5, 5, 'weldf');
  it{end+1} = d_dim(0, -p.t_shf, g, -p.t_shf, -28, ['≤ ' mm_t(g)], 'before');
  it{end+1} = d_dim(ov - p.L_lap, ytop, ov, ytop, 28, mm_t(p.L_lap));
  it{end+1} = d_dim(0, ytop, ov, ytop, 52, mm_t(ov));
  it{end+1} = d_dim(x1, 0, x1, h, -25, mm_t(h));
  it{end+1} = d_dim(x1, h, x1, ytop, -25, mm_t(p.t_cap));
  it{end+1} = d_dim(x1, -p.t_shf, x1, 0, -25, mm_t(p.t_shf), 'before');
  xn = x1 + 50;  dy = 13;
  it = [it, d_lines(xn, ytop - 2, {'collarín superior sobre', 'el ala, soldado en obra'}, 'label', 'start', dy)];
  it = [it, d_lines(xn, h/2 + 12, {sprintf('alas: filete %g mm', J.wl.leg_fl), 'en 3 lados'}, 'red', 'start', dy)];
  it = [it, d_lines(xn, h/2 - 16, {sprintf('(bordes %g mm y frente)', p.L_lap)}, 'small', 'start', dy)];
  it = [it, d_lines(xn, 10, {'collarín inferior bajo', 'el ala, soldado en taller'}, 'label', 'start', dy)];
  it = [it, d_lines(-66, ytop - 2, {sprintf('filete %g mm', J.wl.leg_col), 'todo el', 'contorno'}, 'red', 'end', dy)];
end

function it = section_shear(J, opts)
  b = J.bm;  p = J.pl;  g = opts.gap;  ov = p.L_lap + J.st.gap;  h = b.h;  x1 = ov + 150;
  st = opts.stab;  ytop = h + p.t_cap;
  it = column_cut(J, ytop, -p.t_shf - 70);
  it = [it, beam_elev(g, x1, 0, b, 'beam')];
  it{end+1} = d_rectxy(0, -p.t_shf, ov, 0, 'plate');
  it{end+1} = d_rectxy(0, h, ov, ytop, 'plate');
  it{end+1} = d_rectxy(ov - st(2) - 10, h - st(3), ov - 10, h, 'stab');
  it{end+1} = d_line(ov - st(2) - 10, h, ov - 10, h, 'weld');
  it{end+1} = d_line(ov - p.L_lap, 0, ov, 0, 'weld');
  it{end+1} = d_tri(ov, 0, 6, -6, 'weldf');
  it{end+1} = d_tri(0, ytop, 5, 5, 'weldf');
  it{end+1} = d_tri(0, 0, 5, 5, 'weldf');
  it{end+1} = d_dim(0, -p.t_shf, g, -p.t_shf, -28, ['≤ ' mm_t(g)], 'before');
  it{end+1} = d_dim(ov - p.L_lap, -p.t_shf, ov, -p.t_shf, -28, mm_t(p.L_lap));
  it{end+1} = d_dim(ov - st(2) - 10, ytop, ov - 10, ytop, 28, mm_t(st(2)));
  it{end+1} = d_dim(x1, h - st(3), x1, h, -25, mm_t(st(3)));
  xn = x1 + 50;  dy = 13;
  it = [it, d_lines(xn, ytop - 2, {'ala superior NO', 'soldada al collarín'}, 'red', 'start', dy)];
  it = [it, d_lines(xn, h - 40, {'2 placas de estabilidad', sprintf('PL %g x %g x %g mm,', st(1), st(2), st(3)), ...
        'una a cada lado del ala,', 'soldadas solo al collarín', sprintf('superior; holgura %g mm', st(4))}, 'label', 'start', dy)];
  it = [it, d_lines(xn, 10, {sprintf('ala inferior: filete %g mm', J.wl.leg_fl), 'en 3 lados'}, 'red', 'start', dy)];
end

function it = section_seat(J, opts)
  b = J.bm;  p = J.pl;  q = J.nl;  h = b.h;  ov = p.L_lap + J.st.gap;
  Lv = q.ang(1);  Lo = q.ang(2);  tA = q.ang(3);  g = opts.gap;
  clr = 40;                                       % shown only; the level is the project's
  ybt = -p.t_shf - clr - h;                       % bottom of the LB beam
  x1 = Lo + 170;  ytop = h + p.t_cap;
  it = column_cut(J, ytop, ybt - Lv - 25);
  it{end+1} = d_rectxy(0, -p.t_shf, ov, 0, 'plate');
  it{end+1} = d_rectxy(0, h, ov, ytop, 'plate');
  it{end+1} = d_text(ov + 8, h + 1, 'collarín superior', 'small', 'start');
  it{end+1} = d_text(ov + 8, -p.t_shf + 1, 'collarín inferior', 'small', 'start');
  it = [it, beam_elev(g, x1, ybt, b, 'beam')];
  % angle: vertical leg against the wall, outstanding leg under the flange
  it{end+1} = d_poly([0 ybt; Lo ybt; Lo ybt - tA; tA ybt - tA; tA ybt - Lv; 0 ybt - Lv], 'angle');
  it{end+1} = d_line(0, ybt - Lv, 0, ybt, 'weld');
  it{end+1} = d_line(g, ybt, Lo, ybt, 'weld');
  it{end+1} = d_dim(0, ybt + h, g, ybt + h, 28, ['≤ ' mm_t(g)], 'before');
  it{end+1} = d_dim(0, ybt - Lv, Lo, ybt - Lv, -25, mm_t(Lo));
  it{end+1} = d_dim(-60, ybt - Lv, -60, ybt, 25, mm_t(Lv));
  it{end+1} = d_dim(x1, ybt, x1, ybt + h, -25, mm_t(h));
  xn = x1 + 50;  dy = 13;
  it = [it, d_lines(xn, ybt + h - 4, {'ala superior libre,', 'sin unión al collarín'}, 'label', 'start', dy)];
  it = [it, d_lines(xn, ybt + 20, {sprintf('ala inferior al ángulo:'), sprintf('filete %g mm, ambos bordes', q.leg_f)}, 'red', 'start', dy)];
  it = [it, d_lines(xn, ybt - 22, {sprintf('ángulo L %gx%gx%g mm', Lv, Lo, tA), 'a la columna: filete', sprintf('%g mm en ambos extremos', q.leg_a)}, 'label', 'start', dy)];
end

% front view of the column faces with the seat angle, one per face width
function it = seat_front(J, L)
  b = J.bm;  q = J.nl;  c = J.cl;  Lv = q.ang(1);
  faces = unique([L.face]);  it = {};  x0 = 0;
  for f = faces
    La = seat_length(J, f);  names = {L([L.face] == f).name};
    xc = x0 + f/2;  ytop = Lv + b.h + 60;
    it{end+1} = d_rectxy(x0, -40, x0 + f, ytop, 'column');
    it{end+1} = d_rectxy(x0 + 1.5*c.t, -40, x0 + f - 1.5*c.t, ytop, 'white');
    it{end+1} = d_line(x0 + 1.5*c.t, -40, x0 + 1.5*c.t, ytop, 'cut');
    it{end+1} = d_line(x0 + f - 1.5*c.t, -40, x0 + f - 1.5*c.t, ytop, 'cut');
    it{end+1} = d_rectxy(xc - La/2, 0, xc + La/2, Lv, 'angle');
    it{end+1} = d_line(xc - La/2, 0, xc - La/2, Lv, 'weld');
    it{end+1} = d_line(xc + La/2, 0, xc + La/2, Lv, 'weld');
    % beam section sitting on the angle
    bw = b.bf/2;  y0 = Lv;
    it{end+1} = d_poly([xc-bw y0; xc+bw y0; xc+bw y0+b.tf; xc+b.tw/2 y0+b.tf; xc+b.tw/2 y0+b.h-b.tf; ...
                        xc+bw y0+b.h-b.tf; xc+bw y0+b.h; xc-bw y0+b.h; xc-bw y0+b.h-b.tf; ...
                        xc-b.tw/2 y0+b.h-b.tf; xc-b.tw/2 y0+b.tf; xc-bw y0+b.tf], 'beam');
    it{end+1} = d_dim(xc - La/2, 0, xc + La/2, 0, -28, mm_t(La));
    it{end+1} = d_dim(x0, -40, x0 + f, -40, -30, sprintf('cara de %s', mm_t(f)));
    it{end+1} = d_text(xc, ytop + 14, sprintf('uniones %s', strjoin(names, ', ')), 'label', 'middle');
    x0 = x0 + f + 140;
  end

end

% =====================================================================
%  Beam to beam: supporting beam in section, supported beam coped
% =====================================================================
function it = vv_elevation(J, opts)
  b = J.bm;  v = J.vv;  h = b.h;  tw = b.tw;  bf = b.bf;  tf = b.tf;
  x0 = tw/2;  xe = x0 + 260;  it = {};
  % supporting beam, cross-section
  it{end+1} = d_poly([-bf/2 0; bf/2 0; bf/2 tf; tw/2 tf; tw/2 h-tf; bf/2 h-tf; bf/2 h; ...
                      -bf/2 h; -bf/2 h-tf; -tw/2 h-tf; -tw/2 tf; -bf/2 tf], 'column');
  % supported beam: web outline with both copes (corner radius R)
  R = v.R;  c = v.c;  dc = v.dc;
  arc = @(xc, yc, a0, a1) [xc + R*cosd(linspace(a0, a1, 7)).', yc + R*sind(linspace(a0, a1, 7)).'];
  Pp = [x0 dc; x0+c-R dc; arc(x0+c-R, dc-R, 90, 0); x0+c 0; xe 0; xe h; x0+c h; ...
        arc(x0+c-R, h-dc+R, 0, -90); x0 h-dc];
  it{end+1} = d_poly(Pp, 'beam');
  it{end+1} = d_line(x0 + c, tf, xe, tf, 'grid');
  it{end+1} = d_line(x0 + c, h - tf, xe, h - tf, 'grid');
  it{end+1} = d_line(xe, -10, xe, h + 10, 'cut');
  it{end+1} = d_line(x0, dc, x0, h - dc, 'weld');
  it{end+1} = d_dim(x0, h, x0 + c, h, 28, mm_t(c));
  it{end+1} = d_dim(xe, h - dc, xe, h, -25, mm_t(dc));
  it{end+1} = d_dim(xe, 0, xe, dc, -25, mm_t(dc), 'before');
  it{end+1} = d_dim(xe, dc, xe, h - dc, -25, mm_t(h - 2*dc));
  it{end+1} = d_dim(xe, 0, xe, h, -60, mm_t(h));
  it{end+1} = d_text(x0 + c + 4, h - dc - 16, sprintf('R %s', mm_t(R)), 'small', 'start');
  it{end+1} = d_text(x0 + c + 4, dc + 8, sprintf('R %s', mm_t(R)), 'small', 'start');
  it{end+1} = d_text(0, -24, sprintf('viga soportante %s', opts.beam), 'small', 'middle');
  it = [it, d_lines(x0 + 120, h/2 + 6, {'viga soportada', 'con recorte de alas'}, 'label', 'start', 13)];
  it = [it, d_lines(xe + 75, h/2 + 20, {'alma con alma:', sprintf('filete %g mm', v.leg), 'a ambos lados,', sprintf('%s de largo', mm_t(h - 2*dc))}, 'red', 'start', 13)];
end

function it = vv_plan(J)
  b = J.bm;  v = J.vv;  tw = b.tw;  bf = b.bf;  L = 420;  it = {};
  % supporting beam runs along x; supported beam comes from -y
  it{end+1} = d_rectxy(-L/2, -bf/2, L/2, bf/2, 'column');
  it{end+1} = d_line(-L/2, -tw/2, L/2, -tw/2, 'hidden');
  it{end+1} = d_line(-L/2,  tw/2, L/2,  tw/2, 'hidden');
  y0 = -tw/2;  yf = y0 - v.c;  yb = yf - 230;
  it{end+1} = d_rectxy(-bf/2, yb, bf/2, yf, 'beam');                 % supported flange, cut back
  it{end+1} = d_rectxy(-tw/2, yf, tw/2, y0, 'hidden');               % web, under the supporting flange
  it{end+1} = d_line(-tw/2 - 1.5, y0, tw/2 + 1.5, y0, 'weld');
  it{end+1} = d_line(-bf/2 - 10, yb, bf/2 + 10, yb, 'cut');
  it{end+1} = d_dim(bf/2, y0, bf/2, yf, 30, mm_t(v.c));
  it{end+1} = d_dim(-bf/2, yf, -bf/2, -bf/2, 30, mm_t(abs(yf + bf/2)), 'before');  % clearance to the flange
  it{end+1} = d_dim(-bf/2, yb + 40, bf/2, yb + 40, -25, mm_t(bf));
  it{end+1} = d_text(-L/2 + 10, bf/2 + 12, 'viga soportante', 'small', 'start');
  it{end+1} = d_text(-bf/2 - 16, yf - 90, 'viga soportada', 'small', 'end');
  it{end+1} = d_line(tw/2 + 1, y0, 40, bf/2 + 22, 'grid');                       % leader to the weld
  it{end+1} = d_text(44, bf/2 + 22, 'filete a ambos lados del alma', 'red', 'start');
end

% =====================================================================
%  Joint plan
% =====================================================================
function it = joint_plan(map, J, style, opts)
  c = J.cl;  b = J.bm;  p = J.pl;  q = J.nl;  o = p.over;  st = opts.stab;
  [hx, hy, bx] = plan_box(o, map.strongAxis, c);
  dirs = [-1 0; 0 1; 1 0; 0 -1];  face = [hx hy hx hy];  ext = 170;
  side = {'O', 'N', 'E', 'S'};
  it = {};  under = {};  top = {};
  for s = 1:4
    code = map.sides{s};  d = dirs(s,:);  f = face(s);  pe = f + o(s);
    switch code
      case {'M', 'S'}
        it{end+1}    = side_rect(d, pe, pe + ext, -b.bf/2, b.bf/2, 'beam');
        under{end+1} = side_rect(d, f + opts.gap, pe, -b.bf/2, b.bf/2, 'hidden');
        if strcmp(code, 'M')
          top{end+1} = side_line(d, pe - p.L_lap, -b.bf/2, pe, -b.bf/2, 'weld');
          top{end+1} = side_line(d, pe - p.L_lap,  b.bf/2, pe,  b.bf/2, 'weld');
          top{end+1} = side_line(d, pe, -b.bf/2, pe, b.bf/2, 'weld');
        else
          u0 = b.bf/2 + st(4);
          top{end+1} = side_rect(d, pe - st(2) - 10, pe - 10,  u0,  u0 + st(1), 'stab');
          top{end+1} = side_rect(d, pe - st(2) - 10, pe - 10, -u0, -u0 - st(1), 'stab');
        end
      case 'NL'
        La = seat_length(J, q.face);
        it{end+1}    = side_rect(d, pe, pe + ext, -b.bf/2, b.bf/2, 'beam');
        under{end+1} = side_rect(d, f + opts.gap, pe, -b.bf/2, b.bf/2, 'hidden');
        top{end+1}   = side_rect(d, f, f + q.ang(2), -La/2, La/2, 'angleh');
      case 'E'
        a = pe + 12;
        if s == 1 || s == 3, it{end+1} = d_line(d(1)*a, bx(3) - 40, d(1)*a, bx(4) + 40, 'edge');
        else,                it{end+1} = d_line(bx(1) - 40, d(2)*a, bx(2) + 40, d(2)*a, 'edge'); end
    end
    switch code
      case 'M',  lab = [side{s} ': M'];
      case 'S',  lab = [side{s} ': C'];
      case 'NL', lab = [side{s} ': LB'];
      case 'E',  lab = [side{s} ': borde'];
      otherwise, lab = [side{s} ': sin viga'];
    end
    if any(strcmp(code, {'M', 'S', 'NL'})), r = pe + ext; else, r = pe + 20; end
    switch s
      case 1, pt = [-r, b.bf/2 + 8];       a_ = 'start';
      case 3, pt = [ r, b.bf/2 + 8];       a_ = 'end';
      case 2, pt = [b.bf/2 + 8,  r - 12];  a_ = 'start';
      case 4, pt = [b.bf/2 + 8, -r + 4];   a_ = 'start';
    end
    if any(strcmp(code, {'E', 'N'}))
      if s == 1, pt = [-r, bx(4) + 12]; a_ = 'end';
      elseif s == 3, pt = [r, bx(4) + 12]; a_ = 'start';
      elseif s == 4, pt = [b.bf/2 + 8, -r - 16]; end
    end
    top{end+1} = d_text(pt(1), pt(2), lab, 'code', a_);
  end
  it{end+1} = d_rectxy(bx(1), bx(3), bx(2), bx(4), style);
  it = [it, under];
  it{end+1} = d_rectxy(-hx, -hy, hx, hy, 'column');
  it{end+1} = d_rectxy(-hx + c.t, -hy + c.t, hx - c.t, hy - c.t, 'void');
  g = 2;
  it{end+1} = d_poly([-hx-g -hy-g; hx+g -hy-g; hx+g hy+g; -hx-g hy+g; -hx-g -hy-g; -hx-g -hy-g+0.01], 'weld');
  it = [it, top];
  e = ext + 45;
  it{end+1} = d_dim(bx(1), bx(3), -hx, bx(3), -e, mm_t(o(1)), 'before');
  it{end+1} = d_dim(-hx, bx(3), hx, bx(3), -e, mm_t(2*hx));
  it{end+1} = d_dim(hx, bx(3), bx(2), bx(3), -e, mm_t(o(3)));
  it{end+1} = d_dim(bx(1), bx(3), bx(2), bx(3), -(e + 32), mm_t(bx(2) - bx(1)));
  it{end+1} = d_dim(bx(1), bx(3), bx(1), -hy, e, mm_t(o(4)), 'before');
  it{end+1} = d_dim(bx(1), -hy, bx(1), hy, e, mm_t(2*hy));
  it{end+1} = d_dim(bx(1), hy, bx(1), bx(4), e, mm_t(o(2)));
  it{end+1} = d_dim(bx(1), bx(3), bx(1), bx(4), e + 32, mm_t(bx(4) - bx(3)));
  it = [it, compass(bx(2) + ext + 40, bx(4) + ext - 30, 22)];
end

function it = side_rect(d, r0, r1, u0, u1, s)
  n = [-d(2) d(1)];
  it = d_poly([r0*d + u0*n; r1*d + u0*n; r1*d + u1*n; r0*d + u1*n], s);
end

function it = side_line(d, r0, u0, r1, u1, s)
  n = [-d(2) d(1)];  a = r0*d + u0*n;  b = r1*d + u1*n;
  it = d_line(a(1), a(2), b(1), b(2), s);
end

% ---------------------------------------------------------------------
%  drawing items and blocks (see joint_pdf.py)
% ---------------------------------------------------------------------
function s = mm_t(v)
  if abs(v - round(v)) < 1e-6, s = sprintf('%d mm', round(v)); else, s = sprintf('%.1f mm', v); end
end

function it = d_poly(P, s)
  it = struct('t', 'poly', 'p', reshape(P.', 1, []), 's', s);
end

function it = d_rectxy(x0, y0, x1, y1, s)
  it = d_poly([x0 y0; x1 y0; x1 y1; x0 y1], s);
end

function it = d_tri(x, y, sx, sy, s)
  it = d_poly([x y; x + sx y; x y + sy], s);
end

function it = d_line(x0, y0, x1, y1, s)
  it = struct('t', 'line', 'p', [x0 y0 x1 y1], 's', s);
end

function it = d_circle(x, y, r, s)
  it = struct('t', 'circle', 'p', [x y r], 's', s);
end

% several lines of text, first line at y, going down
function it = d_lines(x, y, lines, s, a, dy)
  it = {};
  for i = 1:numel(lines), it{end+1} = d_text(x, y - (i-1)*dy, lines{i}, s, a); end
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

function b = blk_space(h)
  b = struct('k', 'space', 'h', h);
end

function b = blk_h(level, text)
  b = struct('k', sprintf('h%d', level), 't', text);
end

function b = blk_p(text)
  b = struct('k', 'p', 't', text);
end

function b = blk_page()
  b = struct('k', 'page');
end

function b = blk_table(head, rows, widths, right, red)
  b = struct('k', 'table', 'head', {head}, 'rows', {rows}, 'w', widths, ...
             'right', {right}, 'red', {red});
end
