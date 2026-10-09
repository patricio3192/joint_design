function it = c_grid(G, box, o)
% C_GRID  Construction grid: lettered lines (any direction, may be inclined) and
% numbered lines (horizontal), cut to a box, with bubbles.
%
%   it = c_grid(G, [xmin xmax ymin ymax])
%   G.v  {name, [x1 y1], [x2 y2]; ...}  lettered lines through two points (model mm)
%   G.h  {name, y; ...}                 numbered lines
%   box  lettered lines run from ymin to ymax, numbered lines from xmin to xmax
%   o    passed to c_axis (r, tdy, s); o.vat / o.hat: bubble end of the
%        lettered / numbered lines ('start' = bottom / left, default 'start' / 'end')
  if nargin < 3, o = struct(); end
  ov = o;  if isfield(o, 'vat'), ov.at = o.vat; else, ov.at = 'start'; end
  oh = o;  if isfield(o, 'hat'), oh.at = o.hat; else, oh.at = 'end'; end
  ov.dir = [0 1];  oh.dir = [1 0];
  it = {};
  for k = 1:size(G.v, 1)
    a = G.v{k,2};  b = G.v{k,3};
    xa = @(y) a(1) + (b(1) - a(1))*(y - a(2))/(b(2) - a(2));
    it = [it, c_axis(G.v{k,1}, [xa(box(3)) box(3)], [xa(box(4)) box(4)], ov)];
  end
  for k = 1:size(G.h, 1)
    y = G.h{k,2};
    it = [it, c_axis(G.h{k,1}, [box(1) y], [box(2) y], oh)];
  end
end
