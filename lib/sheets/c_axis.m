function it = c_axis(name, p0, p1, o)
% C_AXIS  Grid line p0 -> p1 with its bubble(s): {line, circle, text, ...}.
%
%   it = c_axis('B', [0 -2170], [0 10650])
%   o.at   'start' (default) | 'end' | 'both': where the bubble goes (beyond that end)
%   o.r    bubble radius, model mm (330)        o.tdy  text offset from its centre (-90)
%   o.s    line style ('axis'); bubble style 'bubble', text style 'grid'
%   o.dir  direction in which the bubble is pushed out, as a unit vector from
%          start to end (default: along the line; c_grid uses [0 1] / [1 0], so
%          the bubble of an inclined line sits straight below its end)
  if nargin < 4, o = struct(); end
  if ~isfield(o, 'at'), o.at = 'start'; end
  if ~isfield(o, 'r'), o.r = 330; end
  if ~isfield(o, 'tdy'), o.tdy = -90; end
  if ~isfield(o, 's'), o.s = 'axis'; end
  it = {d_line(p0(1), p0(2), p1(1), p1(2), o.s)};
  if isfield(o, 'dir'), u = o.dir; else, u = (p1 - p0)/norm(p1 - p0); end
  ends = {};
  if any(strcmp(o.at, {'start', 'both'})), ends{end+1} = p0 - o.r*u; end
  if any(strcmp(o.at, {'end', 'both'})),   ends{end+1} = p1 + o.r*u; end
  for k = 1:numel(ends)
    c = ends{k};
    it{end+1} = d_circle(c(1), c(2), o.r, 'bubble');
    it{end+1} = d_text(c(1), c(2) + o.tdy, name, 'grid', 'middle');
  end
end
