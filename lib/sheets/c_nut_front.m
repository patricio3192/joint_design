function it = c_nut_front(x, y, N, s, sr)
% C_NUT_FRONT  washer + hex nut seen along the rod, centred at (x, y):
% washer circle of diameter N.dw, hexagon N.nw across flats (flats horizontal),
% and the rod end of diameter N.d if given. s = {washer style, nut style}
% (default {'r_ancg', 'r_nut'}), sr = style of the rod end (default 'r_anc').
% Side view of the same nut: c_nut.
  if nargin < 4, s = {'r_ancg', 'r_nut'}; end
  if ischar(s), s = {s, s}; end
  if nargin < 5, sr = 'r_anc'; end
  a = (0:5)'*60 + 30;  rc = N.nw/2/cosd(30);           % corner radius
  it = {d_circle(x, y, N.dw/2, s{1}), d_poly([x + rc*cosd(a), y + rc*sind(a)], s{2})};
  if isfield(N, 'd'), it{end+1} = d_circle(x, y, N.d/2, sr); end
end
