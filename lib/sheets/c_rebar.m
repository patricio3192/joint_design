function it = c_rebar(Q, d, s, o)
% C_REBAR  A bar along the polyline Q = [x y; ...], drawn d wide, with its bends
% rounded (radius o.r) and an optional label: {path, text}.
%
%   it = c_rebar([0 -240; 1500 -240], 45, 'r_bm2', struct('label', '+1Ø12, L = 1500', 'at', [750 -480]))
%   o.r      bend radius on the bar axis (0 = sharp)
%   o.label  text, o.at [x y] (default: middle of the first segment), o.ls style ('bsm'),
%   o.a      alignment ('middle')
  if nargin < 4, o = struct(); end
  if isfield(o, 'r') && o.r > 0, Q = fillet(Q, o.r); end
  it = {d_path(Q, d, s)};
  if isfield(o, 'label') && ~isempty(o.label)
    if ~isfield(o, 'at'), o.at = (Q(1,:) + Q(2,:))/2; end
    if ~isfield(o, 'ls'), o.ls = 'bsm'; end
    if ~isfield(o, 'a'), o.a = 'middle'; end
    it{end+1} = d_text(o.at(1), o.at(2), o.label, o.ls, o.a);
  end
end
