function M = jm_bar(M, name, pts, d, o)
% JM_BAR  add a round piece of diameter d along the polyline pts = [x y z; ...]:
% a reinforcing bar, a rod, or a short cylinder (washer, nut: two points).
%   M = jm_bar(M, name, pts, d, o)
% o (all optional):
%   r      bend radius at the polyline corners (centreline), default 0
%   mark   piece mark for the quantities ('A1', 'BA', ...)
%   grp    assembly: pieces of the same grp are not checked against each other
%          (a rod with its nuts and head plate), default = name
%   touch  {grp, ...} other assemblies this piece is meant to touch or go through
%          (a rod through the end plate and the grout)
%   kind   'rebar' | 'rod' | 'nut' | 'steel' | 'grout' | 'concrete' (rebar and rod
%          get the parallel-bar spacing rule in jm_clash)
%   style  printer style for jm_view (lib/printing/pour_pdf.py r_* styles)
%   phase  'before' | 'after' the pour (drawing order)
%   new    true: checked by jm_clash; false: existing context (only checked
%          against new pieces), default true
%   qty    counted by jm_quantities, default = new
%   desc   text for the quantities table;  kgm  mass per metre (default steel)
  if nargin < 5, o = struct(); end
  r = 0;  if isfield(o, 'r'), r = o.r;  o = rmfield(o, 'r'); end
  if r > 0 && size(pts, 1) > 2, pts = jm_fillet3(pts, r); end
  M = jm_piece_(M, name, 'bar', pts, d, o);
end
