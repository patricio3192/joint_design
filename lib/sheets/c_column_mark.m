function it = c_column_mark(x, y, b, h, label, o)
% C_COLUMN_MARK  column on a plan: b x h rectangle centred at (x, y) and its
% label at the corner: {rectangle, text}.
%   it = c_column_mark(4500, 5000, 300, 300, 'C1')
% o.s style ('m_col'), o.ls label style ('small'), o.at [dx dy] label offset
% from the centre (default [b/2 + 40, h/2 + 40]), o.a alignment ('start')
  if nargin < 5, label = ''; end
  if nargin < 6, o = struct(); end
  if ~isfield(o, 's'), o.s = 'm_col'; end
  if ~isfield(o, 'ls'), o.ls = 'small'; end
  if ~isfield(o, 'at'), o.at = [b/2 + 40, h/2 + 40]; end
  if ~isfield(o, 'a'), o.a = 'start'; end
  it = {d_rectxy(x - b/2, y - h/2, x + b/2, y + h/2, o.s)};
  if ~isempty(label), it{end+1} = d_text(x + o.at(1), y + o.at(2), label, o.ls, o.a); end
end
