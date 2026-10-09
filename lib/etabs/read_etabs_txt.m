function tabs = read_etabs_txt(fname)
% READ_ETABS_TXT  Read an ETABS text export (File > Export > Tables to Text,
% or "Export to text" from the table window). One file can hold many tables.
%
% Returns a cell array of tables, each like read_etabs_table output:
%   T.title  normalised table title, e.g. 'elementforcesbeams'
%   T.names  normalised column names, e.g. 'uniquename', 'outputcase'
%   T.raw    cell of strings
%
% The format is fixed-width, right-aligned, 12 characters per column.
% Values longer than the width (long combo names) push the rest of the
% line to the right; this parser tracks that shift. Blank fields (Step
% Type for linear combos, Location, ...) are handled.
% Limitation: names containing spaces AND overflowing their column.

  txt = fileread(fname);
  L = regexp(txt, '\r?\n', 'split');
  tabs = {};
  i = 1;
  while i <= numel(L)
    tk = regexp(L{i}, '^\s*Table:\s*(.+?)\s*$', 'tokens', 'once');
    if isempty(tk), i++; continue; end
    title = tk{1};
    i++;
    while i <= numel(L) && isempty(strtrim(L{i})), i++; end   % blank lines
    hdr = L{i}; i++;
    % units line (only unit strings) -> skip
    if i <= numel(L) && ~isempty(strtrim(L{i})) && ...
       all(isnan(str2double(strsplit(strtrim(L{i})))))
      if ~any(cellfun(@(s) any(isstrprop(s,'digit')), strsplit(strtrim(L{i}))))
        i++;
      end
    end
    % data lines until blank line or next table
    j = i;
    while j <= numel(L) && ~isempty(strtrim(L{j})) && isempty(regexp(L{j}, '^\s*Table:', 'once'))
      j++;
    end
    T = parse_block(hdr, L(i:j-1));
    T.title = lower(regexprep(title, '[^A-Za-z0-9]', ''));
    T.file  = [fname ' / ' title];
    tabs{end+1} = T;
    i = j;
  end
end

function T = parse_block(hdr, lines)
  % ETABS text tables use a fixed grid (12 characters per column), values
  % right-aligned. A value that does not fit (long combo name, GUID, or a
  % long header like "Is Auto Point") is printed after one space and pushes
  % the REST OF THAT LINE to the right. Header and data lines follow the same
  % rule, so both are parsed with the same routine.
  hdr = regexprep(hdr, '\s+$', '');
  [~, e1] = regexp(hdr, '\S+', 'start', 'end', 'once');
  W = 12; if ~isempty(e1) && e1 >= 12 && e1 <= 16, W = e1; end
  names = split_row(hdr, W, Inf);
  T.names = cellfun(@(x) lower(regexprep(x, '[^A-Za-z0-9]', '')), names, 'UniformOutput', false);
  nc = numel(names);
  raw = cell(numel(lines), nc); raw(:) = {''};
  for r = 1:numel(lines)
    c = split_row(lines{r}, W, nc);
    raw(r, 1:numel(c)) = c;
  end
  T.raw = raw;
end

function cells = split_row(ln, W, nc)
  ln = regexprep(ln, '\s+$', '');
  [ts, te] = regexp(ln, '\S+', 'start', 'end');
  cells = {};
  shift = 0; k = 1; t = 1;
  while t <= numel(ts) && k <= nc
    % move to the column whose (shifted) cell contains the token start
    while ts(t) > W*k + shift && k < nc, cells{k} = ''; k++; end
    edge = W*k + shift;
    val = ln(ts(t):te(t));
    % value ends before the cell edge: next word in the same cell belongs to it
    while te(t) < edge && t < numel(ts) && ts(t+1) <= edge
      t++; val = [val ' ' ln(ts(t):te(t))];
    end
    if te(t) > edge, shift = te(t) - W*k; end   % overflow
    cells{k} = val;
    t++; k++;
  end
end
