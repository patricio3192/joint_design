function V = views_sandwich_column(M, P, R)
% VIEWS_SANDWICH_COLUMN  three views of the column sandwich model (lib/joint_model
% jm_view) with the main dimensions. Items for lib/sheets blk_draw:
%   V.side   section along the beams (z right, up = top of the beams)
%   V.front  seen from face A (x right)
%   V.plan   plan cut at the tension rods (x right, z up)
% Labels in Spanish (sheet language).
  bm = P.beam;  C = P.column;  pl = P.plate;  r = P.rods;
  Hp = bm.h + pl.ext;  zA = -(pl.t_grout + pl.tp);  zB = C.h + pl.t_grout + pl.tp;
  s = jm_view(M, {'z', '-y'}, struct('cut_conc', [-1 1]));
  zl = zA - 420;  vd = 80;
  s = [s, c_dim_chain([zl 0; zl -r.dist_top; zl -r.dist_bot; zl -Hp], -50)];
  s = [s, c_dim_chain([zA vd; 0 vd; C.h vd; zB vd], 0)];
  s{end+1} = d_text(C.h/2, vd + 70, sprintf('columna %gx%g', C.b, C.h), 'label', 'middle');
  s{end+1} = d_text(zA - 200, -bm.h - 40, sprintf('%s cara A', bm.name), 'small', 'middle');
  s{end+1} = d_text(zB + 200, -bm.h - 40, sprintf('%s cara B', bm.name), 'small', 'middle');
  f = jm_view(M, {'x', '-y'}, struct('skip', {{'PB', 'GB'}}));
  f{end+1} = d_dim(-r.g/2, -Hp, r.g/2, -Hp, -60, sprintf('%g', r.g));
  f{end+1} = d_dim(-pl.bp/2, -Hp, pl.bp/2, -Hp, -130, sprintf('%g', pl.bp));
  f{end+1} = d_dim(-C.b/2, 80, C.b/2, 80, 0, sprintf('%g', C.b));
  p = jm_view(M, {'x', 'z'}, struct('cut', [0, r.dist_top + 40]));
  p = [p, c_dim_chain([C.b/2 + 120, zA - r.t_wsh - r.h_nut - r.proj; C.b/2 + 120, zB + r.t_wsh + r.h_nut + r.proj], 0, 'L = %g')];
  p{end+1} = d_dim(-r.g/2, zA - 300, r.g/2, zA - 300, 0, sprintf('%g', r.g));
  V = struct('side', {s}, 'front', {f}, 'plan', {p});
end
