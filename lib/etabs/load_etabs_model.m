function M = load_etabs_model(files)
% LOAD_ETABS_MODEL  Build the model from ETABS table exports.
%
%   M = load_etabs_model({'forces.txt', 'points.txt'})
%
% files: file name or cell of file names. Each file can be
%   - an ETABS text export (.txt), which may contain several tables
%   - a CSV with one table (.csv)
% Tables are recognised by their title, so order and grouping don't matter.
%
% Needed tables:
%   Point Object Connectivity                    (UniqueName, X, Y, Z)
%   Column / Beam / Brace Object Connectivity    (UniqueName, UniquePtI, UniquePtJ)
%   Element Forces - Columns / Beams / Braces
%   Frame Assignments - Local Axes               (optional, Angle; default 0)
% All tables in the same units.

  if ischar(files), files = {files}; end
  tabs = {};
  for f = 1:numel(files)
    [~, ~, ext] = fileparts(files{f});
    if strcmpi(ext, '.csv')
      tabs{end+1} = read_etabs_table(files{f});
    else
      tabs = [tabs read_etabs_txt(files{f})];
    end
  end
  titles = cellfun(@(T) T.title, tabs, 'UniformOutput', false);
  fprintf('Tables found: %s\n', strjoin(titles, ', '));
  UN = {'uniquename', 'unique'};

  % ---- points
  ip = find(strcmp(titles, 'pointobjectconnectivity'));
  if isempty(ip)
    error(['Table "Point Object Connectivity" not found. ' ...
           'It is needed for the joint coordinates (local axes).']);
  end
  M.pt.name = {}; M.pt.xyz = [];
  for t = ip
    T = tabs{t};
    M.pt.name = [M.pt.name; tcol(T, UN)];
    M.pt.xyz  = [M.pt.xyz; tnum(T,'x') tnum(T,'y') tnum(T,'z')];
  end

  bad = find(any(isnan(M.pt.xyz), 2));
  if ~isempty(bad)
    error('Coordinates could not be read for %d points, e.g. point %s.', ...
          numel(bad), M.pt.name{bad(1)});
  end

  % ---- frames
  M.fr.name = {}; M.fr.ptI = {}; M.fr.ptJ = {}; M.fr.type = {};
  kinds = {'column','Column'; 'beam','Beam'; 'brace','Brace'};
  for q = 1:rows(kinds)
    for t = find(strcmp(titles, [kinds{q,1} 'objectconnectivity']))
      T = tabs{t};
      n = tcol(T, UN);
      M.fr.name = [M.fr.name; n];
      M.fr.ptI  = [M.fr.ptI;  tcol(T, {'uniquepti','pointi'})];
      M.fr.ptJ  = [M.fr.ptJ;  tcol(T, {'uniqueptj','pointj'})];
      M.fr.type = [M.fr.type; repmat(kinds(q,2), numel(n), 1)];
    end
  end
  nf = numel(M.fr.name);
  if nf == 0, error('No Column/Beam/Brace Object Connectivity table found.'); end

  % ---- local axis angles
  M.fr.angle = zeros(nf, 1);
  for t = find(strcmp(titles, 'frameassignmentslocalaxes'))
    T = tabs{t};
    [tf, loc] = ismember(tcol(T, UN), M.fr.name);
    ang = tnum(T, 'angle');
    M.fr.angle(loc(tf)) = ang(tf);
  end

  % ---- local axes
  M.fr.R = zeros(3, 3, nf); M.fr.L = zeros(nf, 1);
  for i = 1:nf
    pI = point_xyz(M, M.fr.ptI{i});
    pJ = point_xyz(M, M.fr.ptJ{i});
    M.fr.R(:,:,i) = frame_local_axes(pI, pJ, M.fr.angle(i));
    M.fr.L(i)     = norm(pJ - pI);
  end

  % ---- forces
  F.name = {}; F.case = {}; F.ctype = {}; F.step = {}; F.sta = []; F.f = [];
  for t = find(strncmp(titles, 'elementforces', 13))
    T = tabs{t};
    n  = tcol(T, UN);
    st = tcol(T, 'steptype', false);   if isempty(st), st = repmat({''}, numel(n), 1); end
    sn = tcol(T, 'stepnumber', false); if isempty(sn), sn = repmat({''}, numel(n), 1); end
    ct = tcol(T, 'casetype', false);   if isempty(ct), ct = repmat({''}, numel(n), 1); end
    F.name  = [F.name; n];
    F.case  = [F.case; tcol(T, {'outputcase','loadcase','combo'})];
    F.ctype = [F.ctype; ct];
    F.step  = [F.step; strtrim(strcat(st, {' '}, sn))];
    F.sta   = [F.sta;  tnum(T, 'station')];
    F.f     = [F.f; [tnum(T,'p') tnum(T,'v2') tnum(T,'v3') ...
                     tnum(T,'t') tnum(T,'m2') tnum(T,'m3')]];
  end
  M.F = F;
  nbad = sum(any(isnan([F.sta F.f]), 2));
  if nbad > 0
    error('%d force rows could not be read (NaN). Check the export.', nbad);
  end
  fprintf('Loaded %d points, %d frames, %d force rows.\n', ...
          numel(M.pt.name), nf, numel(F.name));
end

function p = point_xyz(M, name)
  k = find(strcmp(M.pt.name, name), 1);
  if isempty(k), error('Point %s not found in Point Object Connectivity.', name); end
  p = M.pt.xyz(k, :);
end
