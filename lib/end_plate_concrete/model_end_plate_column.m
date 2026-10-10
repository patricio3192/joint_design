function M = model_end_plate_column(P, R, o)
% MODEL_END_PLATE_COLUMN  3D model of the end plate on a concrete column, built
% from the same input P as check_end_plate_column (and its result R): every
% bar, rod, plate, nut and concrete member as a piece of lib/joint_model, for
% clash checks (jm_clash), views (jm_view) and quantities (jm_quantities).
%   M = model_end_plate_column(P, R, o)
% Coordinates as the check: x along the column face (0 = beam axis = column
% axis), y down from the top of the beams, z into the column (0 = face). mm.
% Uses besides the check fields (all optional, defaults in brackets):
%   P.column.bars_side [3] bars per face;  P.column.ties_top.y, .d  ties above
%   the beams [none];  P.rods.L  rod length as bought [R.L_rod];  P.rods.leveling
%   [false] leveling washer + nut in the grout gap;  P.head.nw  nut across flats
%   [1.5 d_b];  P.bastones.L  straight leg from the hook face [R.L_bst rounded up
%   to 10];  P.bastones.tail  hook tail [12 db];  P.steel_col.z  [b/2 + x],
%   P.steel_col.y  [column top, beam depth].
% o (drawing extent only): L_beam 900 (beam behind), L_side 450 (crossing
%   beams, from the column face), below 150 (column under the joint), L_ipe 400,
%   n_vcs 3 (bars per layer of the crossing beams).
% Bends: centreline radius 3.5 db for bars, 2.5 db for ties (ACI 318-19 Table
% 25.3.1 and 25.3.2 inside diameters 6db and 4db, not checked against the pages).
% Pieces new = true are what this connection adds; the beams' and column's own
% bars are context (new = false: checked only against new pieces).
  if nargin < 3, o = struct(); end
  dflt = struct('L_beam', 900, 'L_side', 450, 'below', 150, 'L_ipe', 400, 'n_vcs', 3);
  f = fieldnames(dflt);
  for i = 1:numel(f), if ~isfield(o, f{i}), o.(f{i}) = dflt.(f{i}); end, end

  bm = P.beam;  h = bm.h;  bf = bm.bf;  tf = bm.tf;  tw = bm.tw;
  b = P.column.b;  top = P.column.top;  cov = P.column.cover;
  dh = P.column.db_hoop;  dc = P.column.db_bar;
  c_col = cov + dh + dc/2;
  bw = P.cbeam.bw;  hb = P.cbeam.h;  dbm = P.cbeam.db_bar;
  c_beam = cov + dh + dbm/2;  y_vcs = c_beam + dbm;
  tp = P.plate.tp;  bp = P.plate.bp;  ext = P.plate.ext;  tg = P.plate.t_grout;
  db = P.rods.d_b;  g = P.rods.g;  yt = P.rods.y_t;  ys = h - yt;
  hd = P.head;  nw = getf(hd, 'nw', 1.5*db);
  L_rod = getf(P.rods, 'L', R.L_rod);
  ba = P.bastones;  L_bst = getf(ba, 'L', 10*ceil(R.L_bst/10));  tail = getf(ba, 'tail', 12*ba.db);
  hef = R.hef;  z_tip = R.z_tip;

  fprintf('  model: rod L = %g (check needs >= %.0f) %s;  baston straight leg = %g (needs >= %.0f) %s\n', ...
          L_rod, R.L_rod, okay(L_rod >= R.L_rod), L_bst, R.L_bst, okay(L_bst >= R.L_bst));

  M = jm_new();
  C = struct('kind', 'concrete', 'new', false, 'style', 'r_conc');
  % ---- concrete -------------------------------------------------------------------
  M = jm_box(M, 'columna (nudo)', [-b/2 top 0], [b/2 hb b], C);
  M = jm_box(M, 'columna (abajo)', [-b/2 hb 0], [b/2 hb + o.below b], setf(C, 'style', 'r_old'));
  M = jm_box(M, 'viga detras', [-bw/2 0 b], [bw/2 hb b + o.L_beam], C);
  for s = [-1 1]
    M = jm_box(M, sprintf('viga lateral %+d', s), [s*b/2 0 b/2 - bw/2], [s*(b/2 + o.L_side) hb b/2 + bw/2], C);
  end

  % ---- column cage: bars (context), joint ties and ties above the beams (new) -----
  xc = b/2 - c_col;  ns = getf(P.column, 'bars_side', 3);  sp = linspace(-xc, xc, ns);
  ytop = top + cov + dc/2;  Lh = 12*dc;
  K = struct('kind', 'rebar', 'grp', 'cage', 'new', false, 'style', 'r_col', 'r', 3.5*dc);
  for x = sp, for zz = b/2 + sp
    if abs(abs(x) - xc) > 1e-9 && abs(abs(zz - b/2) - xc) > 1e-9, continue; end   % perimeter only
    if abs(abs(zz - b/2) - xc) < 1e-9, dv = [0 0 -sign(zz - b/2)]; else, dv = [-sign(x) 0 0]; end
    p0 = [x hb + o.below zz];  p1 = [x ytop zz];
    M = jm_bar(M, sprintf('col %+.0f/%+.0f', x, zz - b/2), [p0; p1; p1 + Lh*dv], dc, K);
  end, end
  T = struct('kind', 'rebar', 'grp', 'cage', 'style', 'r_tie', 'r', 2.5*dh, 'mark', 'E10', ...
             'desc', sprintf('estribo del nudo Ø%g cerrado', dh));
  for y = P.joint.hoop_y
    M = jm_bar(M, sprintf('estribo y=%g', y), jm_loop(-(b/2 - cov - dh/2), b/2 - cov - dh/2, cov + dh/2, b - cov - dh/2, y), dh, T);
  end
  if isfield(P.column, 'ties_top')
    tt = P.column.ties_top;
    T2 = setf(setf(setf(T, 'mark', sprintf('E%g', tt.d)), 'r', 2.5*tt.d), 'desc', sprintf('estribo Ø%g sobre las vigas', tt.d));
    for y = tt.y, M = jm_bar(M, sprintf('estribo y=%g', y), jm_loop(-(b/2 - cov - tt.d/2), b/2 - cov - tt.d/2, cov + tt.d/2, b - cov - tt.d/2, y), tt.d, T2); end
  end

  % ---- beam bars (context): behind along z with hooks into the column, crossing along x
  zb = c_col + dc/2;                              % hook against the column face bars
  for i = 1:size(P.joint.bars_z, 1)
    [nm, x, y, d] = P.joint.bars_z{i,:};
    zh = zb + d/2;  dn = sign(hb/2 - y);          % top bars hook down, bottom bars up
    M = jm_bar(M, sprintf('%s x=%g', nm, x), [x y + dn*12*d zh; x y zh; x y b + o.L_beam], d, ...
               struct('kind', 'rebar', 'grp', 'VCM', 'new', false, 'style', 'r_bm1', 'r', 3.5*d));
  end
  zv = b/2 + linspace(-1, 1, o.n_vcs)*(bw/2 - c_beam);
  for y = [y_vcs, hb - y_vcs], for zz = zv
    M = jm_bar(M, sprintf('VCS y=%g z=%g', y, zz), [-(b/2 + o.L_side) y zz; b/2 + o.L_side y zz], dbm, ...
               struct('kind', 'rebar', 'grp', 'VCS', 'new', false, 'style', 'r_bm3'));
  end, end
  sc = P.steel_col;  zs = getf(sc, 'z', b/2 + sc.x);  ysc = getf(sc, 'y', [top hb]);
  for x = sc.x, for zz = zs
    M = jm_bar(M, sprintf('ancla col. x=%g z=%g', x, zz), [x ysc(1) zz; x ysc(2) zz], sc.d, ...
               struct('kind', 'rebar', 'grp', 'SC', 'new', false, 'style', 'r_rod'));
  end, end

  % ---- the connection: rods with head plates and nuts, bastones, end plate, grout, beam
  zo = -(tg + tp);                                % outer face of the end plate
  k = 0;
  for y = [yt ys], for x = [-g/2 g/2]
    k = k + 1;  G = sprintf('A1-%d', k);
    R0 = struct('grp', G, 'touch', {{'P2', 'G'}});
    M = jm_bar(M, sprintf('A1 x=%+g y=%g', x, y), [x y z_tip - L_rod; x y z_tip], db, setf(setf(setf(setf(setf(R0, ...
        'kind', 'rod'), 'style', 'r_anc'), 'mark', 'A1'), 'desc', sprintf('varilla roscada Ø%g A193 B7, L = %g', db, L_rod)), 'phase', 'before'));
    M = jm_box(M, sprintf('P1 x=%+g y=%g', x, y), [x - hd.a/2, y - hd.a/2, hef], [x + hd.a/2, y + hd.a/2, hef + hd.t], ...
               setf(setf(setf(R0, 'style', 'r_bp'), 'mark', 'P1'), 'desc', sprintf('PL %gx%gx%g, agujero Ø%g', hd.a, hd.a, hd.t, P.rods.dh)));
    N = struct('t_wsh', hd.t_wsh, 'h_nut', hd.h_nut, 'dw', hd.dw, 'nw', nw, 'db', db);
    M = jm_washer_nut(M, [x y hef + hd.t], 3, N, setf(setf(R0, 'style', 'r_nut'), 'phase', 'before'));
    if getf(P.rods, 'leveling', false), M = jm_washer_nut(M, [x y -tg], 3, N, setf(setf(R0, 'style', 'r_ancg'), 'phase', 'after')); end
    M = jm_washer_nut(M, [x y zo], -3, N, setf(setf(R0, 'style', 'r_ancg'), 'phase', 'after'));
  end, end
  B0 = struct('kind', 'rebar', 'style', 'r_bas', 'mark', 'BA', 'r', 3.5*ba.db, ...
              'desc', sprintf('bastón Ø%g: recto %g + pata %g', ba.db, L_bst, tail));
  for s = [-1 1]
    x = s*ba.x;  zc = R.z_hook + ba.db/2;
    M = jm_bar(M, sprintf('baston x=%+g', x), [x ba.y + tail zc; x ba.y zc; x ba.y R.z_hook + L_bst], ba.db, ...
               setf(B0, 'grp', sprintf('BA%+d', s)));
  end
  A = struct('phase', 'after', 'grp', 'P2', 'touch', {{'G'}});
  M = jm_box(M, 'P2 placa extremo', [-bp/2 0 zo], [bp/2 h + ext -tg], setf(setf(setf(A, 'style', 'r_eplate'), 'mark', 'P2'), ...
             'desc', sprintf('PL %gx%gx%g, 4 agujeros Ø%g', bp, h + ext, tp, P.rods.dh)));
  M = jm_box(M, 'grout', [-bp/2 0 -tg], [bp/2 h + ext 0], struct('phase', 'after', 'grp', 'G', 'kind', 'grout', ...
             'style', 'r_grout', 'mark', 'G', 'desc', sprintf('grout sin contracción, espesor %g', tg)));
  I = setf(setf(A, 'style', 'r_ipe'), 'qty', false);
  z1 = zo - o.L_ipe;
  M = jm_box(M, [bm.name ' ala sup'], [-bf/2 0 z1], [bf/2 tf zo], I);
  M = jm_box(M, [bm.name ' ala inf'], [-bf/2 h - tf z1], [bf/2 h zo], I);
  M = jm_box(M, [bm.name ' alma'], [-tw/2 tf z1], [tw/2 h - tf zo], I);
end

% ---------------------------------------------------------------------------
function v = getf(s, f, d)
  if isfield(s, f), v = s.(f); else, v = d; end
end

function s = setf(s, f, v)
  s.(f) = v;
end

function t = okay(c)
  if c, t = 'OK'; else, t = 'TOO SHORT'; end
end
