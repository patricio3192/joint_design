function M = jm_piece_(M, name, type, pts, d, o)
% JM_PIECE_  (internal) append one piece; o fields are optional, see jm_bar.
  def = struct('mark', '', 'grp', '', 'kind', 'steel', 'style', 'r_steel', 'phase', 'before', ...
               'new', true, 'qty', [], 'touch', {{}}, 'desc', '', 'kgm', NaN);
  f = fieldnames(o);
  for i = 1:numel(f), def.(f{i}) = o.(f{i}); end
  if isempty(def.grp), def.grp = name; end
  if isempty(def.qty), def.qty = def.new; end
  if ischar(def.touch), def.touch = {def.touch}; end
  p = struct('name', name, 'type', type, 'pts', pts, 'd', d, 'mark', def.mark, 'grp', def.grp, ...
             'kind', def.kind, 'style', def.style, 'phase', def.phase, 'new', logical(def.new), ...
             'qty', logical(def.qty), 'touch', {def.touch}, 'desc', def.desc, 'kgm', def.kgm);
  M.pc(end+1) = p;
end
