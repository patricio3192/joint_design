function V = views_end_plate_column(M, P, R)
% VIEWS_END_PLATE_COLUMN  the three views of the end plate joint, drawn from the
% 3D model (model_end_plate_column) with lib/joint_model/jm_view, plus the main
% dimensions from P and R. Returns item lists for lib/sheets blk_draw:
%   V.side   section along the beam axis (z right, up = top of the beams)
%   V.front  seen from the beam (x right), column and crossing beams
%   V.plan   plan cut at the tension rods (x right, z up = into the column)
% Labels in Spanish (sheet language).
  bm = P.beam;  b = P.column.b;  top = P.column.top;  hb = P.cbeam.h;
  tg = P.plate.t_grout;  tp = P.plate.tp;  H = bm.h + P.plate.ext;
  yt = P.rods.y_t;  ys = bm.h - yt;  g = P.rods.g;  ba = P.bastones;
  zo = -(tg + tp);

  % section along the beam axis: concrete cut at x = 0, bars and steel all seen
  s = jm_view(M, {'z', '-y'}, struct('cut_conc', [-1 1]));
  zl = zo - 400;  vd = -top + 60;
  s = [s, c_dim_chain([zl 0; zl -yt; zl -ys; zl -H], -50)];
  s = [s, c_dim_chain([zo vd; -tg vd; 0 vd], 0), c_dim_chain([0 vd; R.hef vd; b vd], 0)];
  s{end+1} = d_text(b/2, -top + 120, sprintf('columna %gx%g', b, b), 'label', 'middle');
  s{end+1} = d_text(b + 300, 25, 'viga detrás', 'label', 'middle');
  s{end+1} = d_text(zo - 200, -bm.h - 40, sprintf('%s (después)', bm.name), 'small', 'middle');

  % front: without the beam behind (hidden by the column)
  f = jm_view(M, {'x', '-y'}, struct('cut_conc', [-Inf b - 1]));
  f{end+1} = d_dim(-g/2, -H, g/2, -H, -60, sprintf('%g', g));
  f{end+1} = d_dim(-P.plate.bp/2, -H, P.plate.bp/2, -H, -130, sprintf('%g', P.plate.bp));
  f{end+1} = d_dim(-ba.x, -hb - 60, ba.x, -hb - 60, -150, sprintf('%g (bastones)', 2*ba.x));
  f{end+1} = d_dim(-b/2, 0, -b/2, -ba.y, 60, sprintf('%g', ba.y));
  f{end+1} = d_dim(-b/2, -top, b/2, -top, 50, sprintf('%g', b));
  f{end+1} = d_text(0, -top + 110, 'columna', 'label', 'middle');

  % plan cut at the tension rods (slab from the top of the beams to below the bastones)
  p = jm_view(M, {'x', 'z'}, struct('cut', [0, yt + 80]));
  xr = b/2 + 300;
  L = 10*ceil(R.L_bst/10);  if isfield(ba, 'L'), L = ba.L; end
  p = [p, c_dim_chain([xr zo; xr -tg; xr 0; xr R.hef; xr b], 0)];
  p{end+1} = d_dim(xr + 120, R.z_hook, xr + 120, R.z_hook + L, 0, sprintf('%g (bastón recto)', L));
  p{end+1} = d_dim(-ba.x, b + 700, ba.x, b + 700, 0, sprintf('%g', 2*ba.x));
  p{end+1} = d_text(0, b + 950, 'viga detrás', 'label', 'middle');
  V = struct('side', {s}, 'front', {f}, 'plan', {p});
end
