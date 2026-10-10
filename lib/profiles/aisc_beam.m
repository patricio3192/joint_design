function B = aisc_beam(name, Fy, Fu, E)
% AISC_BEAM  catalog section (steel_profile) as the P.beam struct of the
% connection libraries, in AISC names (x = strong axis, y = weak axis), mm:
%   name, h, bf, tf, tw, r_fil (root radius), h_web (straight web, catalog d),
%   A, Zx (= Wply), Sx (= Wely), Ix (= Iy of the catalog), Iy (= Iz, WEAK),
%   rx, ry (= iz), J (= It), Cw (= Iw), Fy, Fu, E (defaults 250, 400, 200000).
%   B = aisc_beam('IPE 200');  B.L_span = 4800;  B.L_brace = 2400;
% The catalog uses EN axes (y strong, z weak): this is the only place where
% the names are translated.
  if nargin < 2, Fy = 250; end
  if nargin < 3, Fu = 400; end
  if nargin < 4, E = 200000; end
  s = steel_profile(name);
  B = struct('name', s.name, 'h', s.h, 'bf', s.b, 'tf', s.tf, 'tw', s.tw, 'r_fil', s.r, 'h_web', s.d, ...
             'A', s.A, 'Zx', s.Wply, 'Sx', s.Wely, 'Ix', s.Iy, 'Iy', s.Iz, 'rx', s.iy, 'ry', s.iz, ...
             'J', s.It, 'Cw', s.Iw, 'Fy', Fy, 'Fu', Fu, 'E', E);
end
