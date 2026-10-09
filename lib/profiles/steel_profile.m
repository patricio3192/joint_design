function S = steel_profile(name)
% STEEL_PROFILE  Rolled I section from the ArcelorMittal 2023 catalog (README.md),
% in mm, N-free geometric units:
%
%   S = steel_profile('IPE 240')      % also 'ipe240', 'HE 200 A', 'HEA200', 'HEB 300'
%
%   S.name, S.G (kg/m), S.h, S.b, S.tw, S.tf, S.r, S.hi, S.d (mm), S.A (mm2),
%   S.Iy, S.Iz, S.It (mm4), S.Wely, S.Wply, S.Welz, S.Wplz (mm3), S.iy, S.iz (mm,
%   computed as sqrt(I/A): the catalog truncates them), S.Avz (mm2), S.Iw (mm6),
%   S.AL (m2/m), S.ss (mm).  EN axes: y-y strong, z-z weak.

  key = upper(regexprep(name, '\s+', ''));
  tok = regexp(key, '^(IPE|HE|HEA|HEB)(\d+)(A|B)?$', 'tokens', 'once');
  if isempty(tok), error('steel_profile: %s is not an IPE, HE A or HE B name.', name); end
  if strcmp(tok{1}, 'IPE')
    file = 'ipe.csv';  want = sprintf('IPE %s', tok{2});
  else
    s = '';  if numel(tok) > 2, s = tok{3}; end
    if numel(tok{1}) == 3, s = tok{1}(3); end
    if isempty(s), error('steel_profile: %s: give the series, HE %s A or HE %s B.', name, tok{2}, tok{2}); end
    file = sprintf('he%s.csv', lower(s));  want = sprintf('HE %s %s', tok{2}, s);
  end
  fid = fopen(fullfile(fileparts(mfilename('fullpath')), file), 'r');
  head = strsplit(fgetl(fid), ',');
  row = {};
  while true
    l = fgetl(fid);
    if ~ischar(l), break; end
    f = strsplit(l, ',');
    if strcmp(f{1}, want), row = f; break; end
  end
  fclose(fid);
  if isempty(row), error('steel_profile: %s is not in %s.', want, file); end
  v = @(c) str2double(row{strcmp(head, c)});
  S.name = want;  S.G = v('G_kgm');
  S.h = v('h_mm');  S.b = v('b_mm');  S.tw = v('tw_mm');  S.tf = v('tf_mm');  S.r = v('r_mm');
  S.hi = v('hi_mm');  S.d = v('d_mm');
  S.A = v('A_cm2')*1e2;  S.AL = v('AL_m2m');
  S.Iy = v('Iy_cm4')*1e4;  S.Wely = v('Wely_cm3')*1e3;  S.Wply = v('Wply_cm3')*1e3;
  S.Avz = v('Avz_cm2')*1e2;
  S.Iz = v('Iz_cm4')*1e4;  S.Welz = v('Welz_cm3')*1e3;  S.Wplz = v('Wplz_cm3')*1e3;
  S.ss = v('ss_cm')*10;  S.It = v('It_cm4')*1e4;  S.Iw = v('Iw_cm6')*1e6;
  S.iy = sqrt(S.Iy/S.A);  S.iz = sqrt(S.Iz/S.A);
end
