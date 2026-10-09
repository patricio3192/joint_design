function it = c_node(x, y, label, o)
% C_NODE  Ball marking a joint, with its label: {circle, text}.
%
%   it = c_node(4780, 0, 'C4')
%   o.r      radius, model mm (250)        o.s   circle style ('r_oval_l', outline)
%   o.ls     label style ('red')           o.at  label position relative to the
%   centre, [dx dy] (default [-1.1r, -1.6r]), o.a  label alignment ('end')
  if nargin < 4, o = struct(); end
  if ~isfield(o, 'r'), o.r = 250; end
  if ~isfield(o, 's'), o.s = 'r_oval_l'; end
  if ~isfield(o, 'ls'), o.ls = 'red'; end
  if ~isfield(o, 'at'), o.at = [-1.1 -1.6]*o.r; end
  if ~isfield(o, 'a'), o.a = 'end'; end
  it = {d_circle(x, y, o.r, o.s), d_text(x + o.at(1), y + o.at(2), label, o.ls, o.a)};
end
