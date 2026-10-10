function M = jm_washer_nut(M, p, dir, N, o)
% JM_WASHER_NUT  washer then nut on a rod, from point p = [x y z] along the axis
% dir (+3 = +z, -3 = -z, +1/-1 x, +2/-2 y). N: t_wsh, h_nut, dw (washer OD),
% nw (nut across flats), db (rod, for the text). o: piece options (grp, touch,
% style, phase, ...); marks W and T, kind 'nut'.
  u = zeros(1, 3);  u(abs(dir)) = sign(dir);
  p1 = p + u*N.t_wsh;  p2 = p1 + u*N.h_nut;
  o.kind = 'nut';  o.mark = 'W';  o.desc = sprintf('arandela Ø%g x %g', N.dw, N.t_wsh);
  tag = sprintf('x=%+g y=%g z=%g', p);
  M = jm_bar(M, ['arandela ' tag], [p; p1], N.dw, o);
  o.mark = 'T';  o.desc = sprintf('tuerca Ø%g', N.db);
  M = jm_bar(M, ['tuerca ' tag], [p1; p2], N.nw, o);
end
