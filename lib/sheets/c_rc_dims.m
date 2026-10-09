function it = c_rc_dims(S, o)
% C_RC_DIMS  Width (below) and depth (left) of a section drawn by c_rc_section.
%   o.ob, o.oh   offsets of the two dimension lines (default -100 and 60)
  if nargin < 2, o = struct(); end
  if ~isfield(o, 'ob'), o.ob = -100; end
  if ~isfield(o, 'oh'), o.oh = 60; end
  it = {d_dim(-S.b/2, 0, S.b/2, 0, o.ob, sprintf('%g', S.b)), ...
        d_dim(-S.b/2, 0, -S.b/2, S.h, o.oh, sprintf('%g', S.h))};
end
