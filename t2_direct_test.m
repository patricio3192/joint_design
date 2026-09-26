% =====================================================================
%  t2_direct_test.m   Beams welded DIRECTLY to the column (dwj_lib),
%  optionally side by side with the collar joint (dmj_lib).
%
%  Uses the same joint database as t1_joint_test.m.  Build it once with
%      addpath('etabs_joints');  build_joint_db;
%
%  Edit the blocks marked EDIT and run.
% =====================================================================
here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(here, 'etabs_joints'));
source(fullfile(here, 'dwj_lib.m'));

DB = load_joint_db(fullfile(here, 'joint_db', 'joint_db.mat'));

% ---- EDIT 1: the joints ----------------------------------------------
joints = {'10', '13'};
% joints = {DB.joints.joint};            % every joint in the model

% ---- EDIT 2: the detail ----------------------------------------------
J = dwj_default_joint();   % beam, column and welds live in dwj_lib.m
% J.wl.fl_type = 'cjp';    % flanges CJP instead of fillets

% ---- EDIT 3: comparison with the collar joint ---------------------------
%  true: also run dmj_lib on the same joints (its report is not printed)
%  and list both governing checks in the summary.
compare = true;

% ---- EDIT 4: PDF check sheets --------------------------------------------
%  true: write reports/direct_joints.pdf and reports/collar_joints.pdf for
%  the joints above.  make_joint_pdfs.m builds the content; python3 with
%  python3-reportlab only prints it (python_support_scripts/joint_pdf.py).
make_pdf = true;

% ======================================================================
if compare || make_pdf
  source(fullfile(here, 'dmj_lib.m'));
  Jc = default_joint();
end

SUM = {};
for n = 1:numel(joints)
  k = find(strcmp({DB.joints.joint}, joints{n}), 1);
  if isempty(k)
    error('Joint %s is not in the database. Available: %s', joints{n}, ...
          strjoin({DB.joints.joint}, ' '));
  end
  jt  = DB.joints(k);
  % beams by class (joint_classes.m): only M beams are moment beams
  [map, ~, msg] = joint_config(jt, J);
  map.skip = 'RSA';                     % signed combinations only
  for m = 1:numel(msg), fprintf('WARNING %s\n', msg{m}); end

  E = dwj_run_joint_res(J, jt.res, map, sprintf('JOINT %s', jt.joint));
  f = fieldnames(E);  d = cellfun(@(t) E.(t).dcr, f);
  [w, i] = max(d);
  row = {jt.joint, f{i}, E.(f{i}).name, w, E.(f{i}).case};

  if compare
    [mapc, Jcj] = joint_config(jt, Jc);  mapc.skip = 'RSA';
    evalc('Ec = run_joint_res(Jcj, jt.res, mapc, ''collar'');');
    fc = fieldnames(Ec);  dc = cellfun(@(t) Ec.(t).dcr, fc);
    [wc, ic] = max(dc);
    row = [row, {fc{ic}, Ec.(fc{ic}).name, wc}];
  end
  SUM{end+1} = row;
end

fprintf('\n\nSUMMARY, governing check per joint\n');
if compare
  fprintf('  %-6s | %-5s %-38s %6s | %-5s %-38s %6s\n', 'joint', ...
          'tag', 'DIRECT WELD', 'DCR', 'tag', 'COLLAR (dmj_lib)', 'DCR');
  for n = 1:numel(SUM)
    s = SUM{n};
    fprintf('  %-6s | %-5s %-38s %6.2f | %-5s %-38s %6.2f\n', ...
            s{1}, s{2}, s{3}, s{4}, s{6}, s{7}, s{8});
  end
else
  fprintf('  %-8s %-5s %-38s %6s  %s\n', 'joint', 'tag', 'limit state', 'DCR', 'case');
  for n = 1:numel(SUM)
    s = SUM{n};
    fprintf('  %-8s %-5s %-38s %6.2f  %s\n', s{1}, s{2}, s{3}, s{4}, s{5});
  end
end

if make_pdf
  addpath(here);
  kinds = struct('type', {'direct', 'collar'}, 'J', {J, Jc});
  fprintf('\nPDF check sheets:\n');
  make_joint_pdfs(DB, joints, kinds, fullfile(here, 'reports'));
end
