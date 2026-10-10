function file = sheet_pdf(B, base, o)
% SHEET_PDF  write a sheet: blocks B (blk_* cell array) -> base.json -> base.pdf,
% with the frame and title block, printed by lib/printing/pour_pdf.py (all styles).
%   file = sheet_pdf(B, '/path/to/name', o)      % returns the PDF path
% o (all optional):
%   page      'A2L' (A2 landscape, default) | 'A1L' | 'A4'
%   fs        text factor (default 1.0; 1.25 suits A1)
%   title     PDF title (default the file name)
%   tb        title block {label, value; ...}; a value '@sheet' prints the sheet
%             name and o.subtitle, '@page' prints "i / n"; '\n' splits lines.
%             Without tb there is no frame.
%   widths    relative widths of the title-block fields (default equal)
%   tbh       title-block height in mm (default 30), tbk text factor (default 1.0)
%   sheets    {name of sheet 1, ...} for '@sheet' and the page count (default {title})
%   subtitle  line under the sheet name
%   python    python executable (default 'python3')
%   overflow  'error' (default) | 'warn': what to do when the blocks need more
%             pages than o.sheets lists (with a title block)
% Stops with an error if the printer fails, and by default if the sheet
% overflows: a row was taller than the page; lower the blk_draw h of the
% tallest drawing in that row (or split the row).
  if nargin < 3, o = struct(); end
  [~, nm] = fileparts(base);
  d = struct('page', 'A2L', 'fs', 1.0, 'title', nm, 'widths', [], 'tbh', 30, 'tbk', 1.0, ...
             'subtitle', '', 'python', 'python3', 'overflow', 'error');
  f = fieldnames(o);  for i = 1:numel(f), d.(f{i}) = o.(f{i}); end
  if ~isfield(d, 'sheets'), d.sheets = {d.title}; end
  doc = struct('title', d.title, 'page', d.page, 'fs', d.fs, 'blocks', {B});
  if isfield(d, 'tb')
    T = d.tb;  F = cell(1, size(T, 1));
    for i = 1:size(T, 1), F{i} = {T{i,1}, strrep(T{i,2}, '\n', char(10))}; end
    w = d.widths;  if isempty(w), w = ones(1, numel(F)); end
    doc.frame = struct('fields', {F}, 'widths', w/sum(w), 'h', d.tbh, 'tb', d.tbk, ...
                       'subtitle', d.subtitle, 'sheets', {d.sheets});
  end
  fid = fopen([base '.json'], 'w');
  if fid < 0, error('Cannot write %s.json', base); end
  fprintf(fid, '%s', jsonencode(doc));  fclose(fid);
  printer = fullfile(fileparts(mfilename('fullpath')), '..', 'printing', 'pour_pdf.py');
  [st, out] = system(sprintf('%s "%s" "%s.json" "%s.pdf"', d.python, printer, base, base));
  if st ~= 0, fprintf('%s', out);  error('PDF generation failed (see the message above).'); end
  if ~isempty(strfind(out, 'WARNING'))
    fprintf('%s', out);
    if strcmp(d.overflow, 'error'), error('sheet_pdf: the sheet overflowed (see the WARNING). The PDF was written anyway.'); end
  end
  file = [base '.pdf'];
end
