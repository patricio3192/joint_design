function file = sheet_pdf(B, base, o)
% SHEET_PDF  write a sheet: blocks B (blk_* cell array) -> base.json -> base.pdf,
% printed by lib/printing/pour_pdf.py (all styles), with the office title block.
%   file = sheet_pdf(B, '/path/to/name', o)        % returns the PDF path
% Choose the sheet size; the size brings its title block (same fields and
% proportions as the project sheets):
%   o.page     'A2L' (default) | 'A1L' | 'A4'
%   o.project  title-block data, all optional (missing ones print '-'):
%              proyecto, propietario, arquitecto, estructural (default: office.m),
%              contenido (sheet name, default o.title), subtitle (line under it),
%              fecha (default: current month, e.g. 'OCTUBRE 2026')
%   o.title    PDF title and default sheet name (default the file name)
%   o.overflow 'error' (default) | 'warn': when the blocks need a second page
% Rarely needed: o.fs, o.tbh, o.tbk, o.widths override the size defaults;
% o.tb = {label, value; ...} replaces the whole title block ({} = no frame);
% o.sheets {name of sheet 1, ...} for multi-sheet documents; o.python.
% Stops with an error if the printer fails, and by default if the sheet
% overflows (a row taller than the page: lower the blk_draw h of its tallest drawing).
  if nargin < 3, o = struct(); end
  [~, nm] = fileparts(base);
  if ~isfield(o, 'page'), o.page = 'A2L'; end
  d = size_defaults(o.page);
  d.title = nm;  d.python = 'python3';  d.overflow = 'error';  d.subtitle = '';
  f = fieldnames(o);  for i = 1:numel(f), d.(f{i}) = o.(f{i}); end
  if ~isfield(d, 'sheets')
    d.sheets = {d.title};
    if isfield(d, 'project') && isfield(d.project, 'contenido'), d.sheets = {d.project.contenido}; end
  end
  if ~isfield(d, 'tb'), [d.tb, d.subtitle] = office_tb(d); end
  doc = struct('title', d.title, 'page', d.page, 'fs', d.fs, 'blocks', {B});
  if ~isempty(d.tb)
    T = d.tb;  F = cell(1, size(T, 1));
    for i = 1:size(T, 1), F{i} = {T{i,1}, strrep(T{i,2}, '\n', char(10))}; end
    w = d.widths;  if numel(w) ~= numel(F), w = ones(1, numel(F)); end
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

function d = size_defaults(page)
  % text factor, title-block height (mm), its text factor and field widths, per size
  switch page
    case 'A1L', d = struct('page', page, 'fs', 1.25, 'tbh', 45, 'tbk', 1.5, 'widths', [13 11 18 16 21 13 8]);
    case 'A2L', d = struct('page', page, 'fs', 1.0, 'tbh', 26, 'tbk', 1.0, 'widths', [15 11 12 15 29 9 9]);
    case 'A4',  d = struct('page', page, 'fs', 0.9, 'tbh', 24, 'tbk', 0.7, 'widths', [15 11 12 15 25 11 11]);
    otherwise, error('sheet_pdf: page %s unknown (A1L, A2L, A4)', page);
  end
end

function [tb, sub] = office_tb(d)
  p = struct();  if isfield(d, 'project'), p = d.project; end
  of = office();
  mes = {'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO', 'JULIO', 'AGOSTO', ...
         'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'};
  c = clock();
  g = @(f, v) getf(p, f, v);
  tb = {'PROYECTO:',              g('proyecto', '-')
        'PROPIETARIO:',           g('propietario', '-')
        'DISEÑO ARQUITECTÓNICO:', g('arquitecto', '-')
        'DISEÑO ESTRUCTURAL:',    g('estructural', of.estructural)
        'CONTENIDO:',             '@sheet'
        'FECHA:',                 g('fecha', sprintf('%s %d', mes{c(2)}, c(1)))
        'LÁMINA:',                '@page'};
  sub = g('subtitle', d.subtitle);
end

function v = getf(s, f, dflt)
  if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dflt; end
end
