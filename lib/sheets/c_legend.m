function it = c_legend(x, y, L, o)
% C_LEGEND  legend of member styles: one swatch and one text per row, top row
% at (x, y), rows going down. L = {style, text; ...}.
%   it = c_legend(0, -800, {'m_conc', 'Viga de hormigón'; 'm1', 'IPE 200'; 'm2', 'IPE 240'})
% o.w, o.h swatch size (model mm, default 500 x 120), o.dy row pitch (default 260),
% o.ls text style ('label'), o.title optional title above (style 'code')
  if nargin < 4, o = struct(); end
  if ~isfield(o, 'w'), o.w = 500; end
  if ~isfield(o, 'h'), o.h = 120; end
  if ~isfield(o, 'dy'), o.dy = 260; end
  if ~isfield(o, 'ls'), o.ls = 'label'; end
  it = {};
  if isfield(o, 'title'), it{end+1} = d_text(x, y + o.dy*0.8, o.title, 'code', 'start'); end
  for i = 1:size(L, 1)
    yi = y - (i - 1)*o.dy;
    it{end+1} = d_rectxy(x, yi - o.h/2, x + o.w, yi + o.h/2, L{i,1});
    it{end+1} = d_text(x + o.w + 120, yi - o.h/3, L{i,2}, o.ls, 'start');
  end
end
