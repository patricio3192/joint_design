function c = tcol(T, alts, required)
% TCOL  Column of an ETABS table as cell of strings.
%   alts: normalised name or cell of alternative names.
  if nargin < 3, required = true; end
  if ischar(alts), alts = {alts}; end
  j = [];
  for a = 1:numel(alts)
    j = find(strcmp(T.names, alts{a}), 1);
    if ~isempty(j), break; end
  end
  if isempty(j)
    if required
      error('Column "%s" not found in %s.\nAvailable: %s', alts{1}, T.file, ...
            strjoin(T.names, ', '));
    end
    c = {};
    return
  end
  c = T.raw(:, j);
end
