function it = c_member(p0, p1, w, s, label, o)
% C_MEMBER  member on a plan: a band of width w (model mm) from p0 to p1 in style
% s (m_conc for concrete, m1..m8 one colour per steel section, see STYLES.md),
% with its label written along it: {band, text}.
%   it = c_member([0 0], [4500 0], 250, 'm_conc', 'V 25x40')
%   it = c_member([0 0], [0 5000], 90, 'm1', 'IPE 200')      % steel: exaggerate w
% o.off  label offset to the left of p0->p1 (default w/2 + 60; negative = right)
% o.at   position along the member, 0..1 (default 0.5);  o.ls text style ('label')
% o.cut  [c0 c1] mm cut back at each end (to stop at the column faces), default [0 0]
  if nargin < 5, label = ''; end
  if nargin < 6, o = struct(); end
  if ~isfield(o, 'off'), o.off = w/2 + 60; end
  if ~isfield(o, 'at'), o.at = 0.5; end
  if ~isfield(o, 'ls'), o.ls = 'label'; end
  if ~isfield(o, 'cut'), o.cut = [0 0]; end
  u = (p1 - p0)/norm(p1 - p0);  n = [-u(2) u(1)];
  a = p0 + u*o.cut(1);  b = p1 - u*o.cut(2);
  it = {d_poly([a + n*w/2; b + n*w/2; b - n*w/2; a - n*w/2], s)};
  if ~isempty(label)
    ang = atan2d(u(2), u(1));
    if ang > 90.001 || ang < -89.999, ang = ang - 180*sign(ang); end    % keep text readable
    q = a + (b - a)*o.at + n*o.off;
    t = d_text(q(1), q(2), label, o.ls, 'middle');
    if abs(ang) > 0.01, t.r = ang; end
    it{end+1} = t;
  end
end
