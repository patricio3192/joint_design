function it = c_leader(xt, yt, target, txt, s, o)
% C_LEADER  Text with a leader line to the point it names: {line, text}.
%
%   it = c_leader(1040, 215, [340 42], '2 estribos Ø14', 'new')
%   The line runs from (xt + o.dx, yt + o.dy) to target; o.dx = -10, o.dy = 8 by
%   default (just before the text, at mid height); o.a alignment ('start'),
%   o.ls line style ('grid').
  if nargin < 6, o = struct(); end
  if ~isfield(o, 'dx'), o.dx = -10; end
  if ~isfield(o, 'dy'), o.dy = 8; end
  if ~isfield(o, 'a'), o.a = 'start'; end
  if ~isfield(o, 'ls'), o.ls = 'grid'; end
  it = {d_line(xt + o.dx, yt + o.dy, target(1), target(2), o.ls), d_text(xt, yt, txt, s, o.a)};
end
