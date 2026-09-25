% =====================================================================
%  t1_joint_test.m   Joint capacity check from the saved joint database.
%
%  The ETABS export is NOT read here.  Build the database once, and again
%  only when gg.txt changes (about 40 s):
%      addpath('etabs_joints');  build_joint_db;
%  That writes joint_db/joint_db.mat, which loads in well under a second.
%
%  Edit the two blocks marked EDIT and run.
% =====================================================================
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'etabs_joints'));
source(fullfile(here, 'dmj_lib.m'));

DB = load_joint_db(fullfile(here, 'joint_db', 'joint_db.mat'));

% ---- EDIT 1: the joints ----------------------------------------------
%  Point unique names.  Beams, column and directions come from the
%  database (build_joint_db prints the list of joints and their maps).
joints = {'10'};
% joints = {DB.joints.joint};            % every joint in the model

% ---- EDIT 2: the detail ----------------------------------------------
J = default_joint();      % sections, plates and welds live in dmj_lib.m
% J.pl.t_cap = 12;  J.pl.t_shf = 12;  J.pl.L_lap = 80;

% ======================================================================
SUM = {};
for n = 1:numel(joints)
  k = find(strcmp({DB.joints.joint}, joints{n}), 1);
  if isempty(k)
    error('Joint %s is not in the database. Available: %s', joints{n}, ...
          strjoin({DB.joints.joint}, ' '));
  end
  jt  = DB.joints(k);
  map = jt.map;
  map.skip = 'RSA';                     % signed combinations only
  if ~isempty(map.skew)
    fprintf('NOTE joint %s: beams %s are skew to the column axes\n', ...
            jt.joint, mat2str(map.skew));
  end

  E = run_joint_res(J, jt.res, map, sprintf('JOINT %s', jt.joint));

  f = fieldnames(E);  d = cellfun(@(t) E.(t).dcr, f);
  [w, i] = max(d);
  SUM{end+1} = {jt.joint, f{i}, E.(f{i}).name, w, E.(f{i}).case};
end

if numel(SUM) > 1
  fprintf('\n\nJOB SUMMARY\n');
  fprintf('  %-8s %-5s %-36s %6s  %s\n', 'joint', 'tag', 'limit state', 'DCR', 'case');
  for n = 1:numel(SUM)
    s = SUM{n};
    fprintf('  %-8s %-5s %-36s %6.2f  %s\n', s{1}, s{2}, s{3}, s{4}, s{5});
  end
end
