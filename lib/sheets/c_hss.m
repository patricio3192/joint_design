function it = c_hss(D, B, t, o)
% C_HSS  Rectangular hollow section, cut, centred at o.c ([0 0]): D along x,
% B along y, wall t, outside corner radius o.ro (default 2t), inside ro - t.
% Returns {outer outline (o.s, 'column'), inner outline ('void')}.
  if nargin < 4, o = struct(); end
  if ~isfield(o, 'c'), o.c = [0 0]; end
  if ~isfield(o, 'ro'), o.ro = 2*t; end
  if ~isfield(o, 's'), o.s = 'column'; end
  rr = @(a, b, r) [arcp([ a/2 - r,  b/2 - r], r,   0,  90, 4);
                   arcp([-a/2 + r,  b/2 - r], r,  90, 180, 4);
                   arcp([-a/2 + r, -b/2 + r], r, 180, 270, 4);
                   arcp([ a/2 - r, -b/2 + r], r, 270, 360, 4)];
  it = {d_poly(rr(D, B, o.ro) + o.c, o.s), d_poly(rr(D - 2*t, B - 2*t, max(o.ro - t, 0)) + o.c, 'void')};
end
