function DB = build_joint_db(src, dbdir, colM)
% BUILD_JOINT_DB  Parse the ETABS export ONCE and save every beam-column
% joint, ready for dmj_lib.  Run it again only when the export changes.
%
%   build_joint_db                      etabs_joints/gg.txt -> joint_db/
%   build_joint_db('other.txt')
%   build_joint_db('gg.txt', 'my_db', 'M2')
%
% Writes to dbdir (default: joint_db/ next to etabs_joints/):
%   joint_db.mat      DB   one entry per joint, used by t1_joint_test.m
%   etabs_model.mat   M    the parsed model, for anything else
%                          (joint_forces(M, ...) without re-parsing)
%
% DB.joints(k):
%   joint   point unique name
%   xyz     coordinates, as exported
%   map     frame map from joint_map (strong, weak, col, colM, ...)
%   res     joint_forces output, COMBINATIONS only, axes = column below
%   chk     joint_forces equilibrium check, same cases
% Forces are kept in the export units (kN, kN*m); dmj_lib converts.
%
% A joint is included when it has a column below it and at least one beam.

  here = fileparts(mfilename('fullpath'));
  if nargin < 1 || isempty(src),   src   = fullfile(here, 'gg.txt'); end
  if nargin < 2 || isempty(dbdir), dbdir = fullfile(fileparts(here), 'joint_db'); end
  if nargin < 3 || isempty(colM),  colM  = 'M3'; end

  t0 = tic;
  M = load_etabs_model({src});
  fprintf('Parsed in %.1f s.\n', toc(t0));

  isCol = strcmp(M.fr.type, 'Column');
  cand  = unique([M.fr.ptI(isCol); M.fr.ptJ(isCol)]);

  J = struct('joint', {}, 'xyz', {}, 'map', {}, 'res', {}, 'chk', {});
  for n = 1:numel(cand)
    map = joint_map(M, cand{n}, colM);
    if isempty(map.col) || isempty([map.strong map.weak]), continue; end
    [res, chk] = joint_forces(M, cand{n}, num2str(map.col));
    res = res(strcmp({res.ctype}, 'Combination'));
    chk = chk(ismember({chk.ocase}, {res.ocase}));
    k = numel(J) + 1;
    J(k).joint = cand{n};
    J(k).xyz   = M.pt.xyz(strcmp(M.pt.name, cand{n}), :);
    J(k).map   = map;
    J(k).res   = res;
    J(k).chk   = chk;
  end

  % natural sort by joint number when the names are numeric
  num = str2double({J.joint});
  if ~any(isnan(num)), [~, o] = sort(num); J = J(o); end

  d = dir(src);
  DB.source   = src;
  DB.srcdate  = d.datenum;
  DB.srcbytes = d.bytes;
  DB.built    = datestr(now);
  DB.units    = 'kN, kN*m (as exported)';
  DB.colM     = colM;
  DB.joints   = J;

  if ~exist(dbdir, 'dir'), mkdir(dbdir); end
  save(fullfile(dbdir, 'joint_db.mat'), 'DB', '-v7');
  save(fullfile(dbdir, 'etabs_model.mat'), 'M', '-v7');

  % summary, so the joint names and maps can be checked at a glance
  fprintf('\n%-8s %-6s %-16s %-16s %6s  %s\n', 'joint', 'col', 'strong', 'weak', 'cases', 'notes');
  for k = 1:numel(J)
    m = J(k).map;  note = '';
    if ~isempty(m.skew),     note = [note 'skew beams ' mat2str(m.skew) ' ']; end
    if ~isempty(m.colAbove), note = [note 'column above ' mat2str(m.colAbove)]; end
    fprintf('%-8s %-6d %-16s %-16s %6d  %s\n', J(k).joint, m.col, mat2str(m.strong), ...
            mat2str(m.weak), numel(unique({J(k).res.ocase})), note);
  end
  fprintf('\n%d joints saved to %s  (%.1f s total)\n', numel(J), dbdir, toc(t0));
end
