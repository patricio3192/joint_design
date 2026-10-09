function M = jm_box(M, name, lo, hi, o)
% JM_BOX  add a box with faces parallel to the axes, corners lo = [x y z] and
% hi: plates, flanges and webs, grout pads, concrete members (kind 'concrete',
% never checked for clashes, drawn first). o: as jm_bar (no r).
  if nargin < 5, o = struct(); end
  M = jm_piece_(M, name, 'box', [min(lo, hi); max(lo, hi)], 0, o);
end
