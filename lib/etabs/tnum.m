function v = tnum(T, alts, required)
% TNUM  Numeric column of an ETABS table.
  if nargin < 3, required = true; end
  c = tcol(T, alts, required);
  if isempty(c), v = []; else, v = str2double(c); end
end
