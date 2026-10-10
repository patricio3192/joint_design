function it = c_rc_dims(S, o)
% C_RC_DIMS  Width (below) and depth (left) of a section drawn by c_rc_section,
% and with o.st = true also the stirrup's outside dimensions (for bending it):
% its width above the section and its height left of the depth, texts "(est.)".
%   o.ob, o.oh   offsets of the two section dimensions (default -100 and 60)
%   o.st         stirrup dimensions too (default false)
%   o.os         stirrup dimension offset beyond the section faces (default 60;
%                the height goes o.oh + o.os out from the left face)
  if nargin < 2, o = struct(); end
  if ~isfield(o, 'ob'), o.ob = -100; end
  if ~isfield(o, 'oh'), o.oh = 60; end
  if ~isfield(o, 'st'), o.st = false; end
  if ~isfield(o, 'os'), o.os = 60; end
  it = {d_dim(-S.b/2, 0, S.b/2, 0, o.ob, sprintf('%g', S.b)), ...
        d_dim(-S.b/2, 0, -S.b/2, S.h, o.oh, sprintf('%g', S.h))};
  if o.st
    e = S.ct - S.dst/2;                       % face to the stirrup's outside
    ws = S.b - 2*e;  hs = S.h - 2*e;
    it{end+1} = d_dim(-ws/2, S.h - e, ws/2, S.h - e, e + o.os, sprintf('%g (est.)', ws));
    it{end+1} = d_dim(-ws/2, e, -ws/2, S.h - e, e + o.oh + o.os, sprintf('%g (est.)', hs));
  end
end
