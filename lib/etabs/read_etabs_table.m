function T = read_etabs_table(fname)
% READ_ETABS_TABLE  Read a table exported from ETABS and saved as CSV.
%   Handles: optional "TABLE: ..." title line, header line, optional units
%   line, comma or semicolon delimiter, decimal comma (with ';' files).
%   Header names are normalised: lower case, spaces/symbols removed,
%   e.g. 'Unique Name' -> 'uniquename', 'UniquePtI' -> 'uniquepti'.
%
%   T.names : 1 x nc cell of normalised header names
%   T.raw   : nr x nc cell of strings
%   Use tcol(T,{'name1','alt'}) / tnum(T,{...}) to get columns.

  txt = fileread(fname);
  if numel(txt) >= 3 && all(double(txt(1:3)) == [239 187 191]) % UTF-8 BOM
    txt = txt(4:end);
  end
  lines = regexp(txt, '\r?\n', 'split');
  lines = lines(~cellfun(@(s) isempty(strtrim(s)), lines));

  % skip title lines ("TABLE: Element Forces - Columns")
  k = 1; title = '';
  while k <= numel(lines) && ~isempty(regexpi(strtrim(lines{k}), '^"?TABLE', 'once'))
    title = regexprep(strtrim(lines{k}), '^"?TABLE:?\s*', '', 'ignorecase');
    k++;
  end
  if isempty(title), [~, title] = fileparts(fname); end
  T.title = lower(regexprep(title, '[^A-Za-z0-9]', ''));
  hdr = lines{k};

  % delimiter
  if sum(hdr == ';') > sum(hdr == ',')
    delim = ';';  decComma = true;
  elseif sum(hdr == char(9)) > sum(hdr == ',')
    delim = char(9); decComma = false;
  else
    delim = ',';  decComma = false;
  end

  splitl = @(s) strtrim(strrep(strsplit(s, delim, 'CollapseDelimiters', false), '"', ''));
  names = splitl(hdr);
  T.names = cellfun(@(s) lower(regexprep(s, '[^A-Za-z0-9]', '')), names, ...
                    'UniformOutput', false);
  nc = numel(names);

  body = lines(k+1:end);
  raw = cell(numel(body), nc);
  raw(:) = {''};
  for i = 1:numel(body)
    f = splitl(body{i});
    n = min(nc, numel(f));
    raw(i,1:n) = f(1:n);
  end

  % drop units line (a line where no field is numeric)
  if ~isempty(raw)
    r1 = raw(1,:);  r1 = r1(~cellfun(@isempty, r1));
    if ~isempty(r1) && all(isnan(str2double(r1)))
      raw(1,:) = [];
    end
  end
  if decComma
    raw = strrep(raw, ',', '.');
  end
  T.raw  = raw;
  T.file = fname;
end
