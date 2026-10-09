function it = c_ishape(S, view, o)
% C_ISHAPE  Rolled I section (steel_profile, or any struct with h, b, tw, tf).
%
%   it = c_ishape(steel_profile('IPE 240'), 'section')
%   'section'    cross-section, top of the flange at y = 0, centred on x = 0
%                (no root radii), style o.s ('r_ipe')
%   'elevation'  side view from x = o.x0 to o.x1, top at y = 0: web rectangle
%                (o.s) and the two flanges (o.sf, 'r_ipef')
%   o.y0         y of the top of the section (default 0)
  if nargin < 3, o = struct(); end
  if ~isfield(o, 's'), o.s = 'r_ipe'; end
  if ~isfield(o, 'sf'), o.sf = 'r_ipef'; end
  if ~isfield(o, 'y0'), o.y0 = 0; end
  y0 = o.y0;
  switch view
    case 'section'
      I = [-S.b/2 0; S.b/2 0; S.b/2 -S.tf; S.tw/2 -S.tf; S.tw/2 -S.h + S.tf; S.b/2 -S.h + S.tf; S.b/2 -S.h; ...
           -S.b/2 -S.h; -S.b/2 -S.h + S.tf; -S.tw/2 -S.h + S.tf; -S.tw/2 -S.tf; -S.b/2 -S.tf];
      I(:,2) = I(:,2) + y0;
      it = {d_poly(I, o.s)};
    case 'elevation'
      it = {d_rectxy(o.x0, y0 - S.h, o.x1, y0, o.s), ...
            d_rectxy(o.x0, y0 - S.tf, o.x1, y0, o.sf), d_rectxy(o.x0, y0 - S.h, o.x1, y0 - S.h + S.tf, o.sf)};
    otherwise
      error('c_ishape: view %s (use section or elevation).', view);
  end
end
