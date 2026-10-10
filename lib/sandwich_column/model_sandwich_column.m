function M = model_sandwich_column(P, R, o)
% MODEL_SANDWICH_COLUMN  3D model of the column sandwich (lib/joint_model) from
% the same P as check_sandwich_column and its result R.
%   M = model_sandwich_column(P, R, o)
% Coordinates: x along the column face (0 = beam axis = column axis), y down
% from the top of the beams, z along the beams: z = 0 face A, z = P.column.h
% face B. mm. Column bars and ties are context (new = false); rods, plates,
% nuts, grout and the beams are the connection.
% Uses besides the check fields: P.column.bars_side [3] bars per face;
% P.rods.leveling [false] leveling washer + nut in each grout gap.
% o (drawing extent): above 300 (column shown above the beams when it
% continues), below 300 (column shown under the beams), L_ipe 400.
  if nargin < 3, o = struct(); end
  dflt = struct('above', 300, 'below', 300, 'L_ipe', 400);
  f = fieldnames(dflt);
  for i = 1:numel(f), if ~isfield(o, f{i}), o.(f{i}) = dflt.(f{i}); end, end
  bm = P.beam;  h = bm.h;  bf = bm.bf;  tf = bm.tf;  tw = bm.tw;
  C = P.column;  b = C.b;  H = C.h;  cov = C.cover;  dh = C.db_hoop;  dc = C.db_bar;
  pl = P.plate;  tp = pl.tp;  bp = pl.bp;  tg = pl.t_grout;
  r = P.rods;  db = r.d_b;  g = r.g;
  ytop = -min(C.top, o.above);  ybot = h + pl.ext + o.below;

  M = jm_new();
  M = jm_box(M, 'columna', [-b/2 ytop 0], [b/2 ybot H], struct('kind', 'concrete', 'new', false, 'style', 'r_conc'));
  % column cage (context)
  c_col = cov + dh + dc/2;  ns = 3;  if isfield(C, 'bars_side'), ns = C.bars_side; end
  xs = linspace(-(b/2 - c_col), b/2 - c_col, ns);  zs = linspace(c_col, H - c_col, ns);
  yb = ytop;  if isfinite(C.top), yb = -C.top + cov + dh + dc/2; end
  K = struct('kind', 'rebar', 'grp', 'cage', 'new', false, 'style', 'r_col');
  for x = xs, for z = zs
    if ~(x == xs(1) || x == xs(end) || z == zs(1) || z == zs(end)), continue; end
    M = jm_bar(M, sprintf('col x=%+.0f z=%.0f', x, z), [x ybot z; x yb z], dc, K);
  end, end
  if isfield(C, 'hoop_y')
    T = struct('kind', 'rebar', 'grp', 'cage', 'new', false, 'style', 'r_tie', 'r', 2.5*dh);
    a = b/2 - cov - dh/2;
    for y = C.hoop_y
      M = jm_bar(M, sprintf('estribo y=%g', y), jm_loop(-a, a, cov + dh/2, H - cov - dh/2, y), dh, T);
    end
  end
  % rods through the column, with a plate, grout and beam on each face
  N = struct('t_wsh', r.t_wsh, 'h_nut', r.h_nut, 'dw', r.dw, 'nw', r.nw, 'db', db);
  zA = -(tg + tp);  zB = H + tg + tp;          % outer faces of the plates
  tail = r.t_wsh + r.h_nut + r.proj;
  k = 0;
  for y = [r.dist_top r.dist_bot], for x = [-g/2 g/2]
    k = k + 1;
    R0 = struct('grp', sprintf('A-%d', k), 'touch', {{'PA', 'PB', 'GA', 'GB'}});
    Rr = R0;  Rr.kind = 'rod';  Rr.style = 'r_anc';  Rr.mark = 'AS';
    Rr.desc = sprintf('varilla roscada Ø%g A193 B7, L = %.0f', db, R.L_rod);
    M = jm_bar(M, sprintf('AS x=%+g y=%g', x, y), [x y zA - tail; x y zB + tail], db, Rr);
    Rn = R0;  Rn.style = 'r_ancg';  Rn.phase = 'after';
    M = jm_washer_nut(M, [x y zA], -3, N, Rn);
    M = jm_washer_nut(M, [x y zB], 3, N, Rn);
    if isfield(r, 'leveling') && r.leveling
      M = jm_washer_nut(M, [x y -tg], 3, N, Rn);
      M = jm_washer_nut(M, [x y H + tg], -3, N, Rn);
    end
  end, end
  for F = {'A', -1; 'B', 1}'
    [s, sg] = F{:};
    z0 = iif_(sg < 0, 0, H);                    % column face
    zg = z0 + sg*tg;  zp = zg + sg*tp;  z1 = zp + sg*o.L_ipe;
    A = struct('phase', 'after', 'grp', ['P' s], 'touch', {{['G' s]}}, 'style', 'r_eplate', 'mark', 'PS', ...
               'desc', sprintf('PL %gx%gx%g, 4 agujeros Ø%g', bp, h + pl.ext, tp, r.dh));
    M = jm_box(M, ['placa ' s], [-bp/2 0 zg], [bp/2 h + pl.ext zp], A);
    M = jm_box(M, ['grout ' s], [-bp/2 0 z0], [bp/2 h + pl.ext zg], struct('phase', 'after', 'grp', ['G' s], ...
               'kind', 'grout', 'style', 'r_grout', 'mark', 'G', 'desc', sprintf('grout sin contracción, espesor %g', tg)));
    I = struct('phase', 'after', 'grp', ['P' s], 'style', 'r_ipe', 'qty', false);
    M = jm_box(M, [bm.name ' ' s ' ala sup'], [-bf/2 0 zp], [bf/2 tf z1], I);
    M = jm_box(M, [bm.name ' ' s ' ala inf'], [-bf/2 h - tf zp], [bf/2 h z1], I);
    M = jm_box(M, [bm.name ' ' s ' alma'], [-tw/2 tf zp], [tw/2 h - tf z1], I);
  end
end

function v = iif_(c, a, b)
  if c, v = a; else, v = b; end
end
