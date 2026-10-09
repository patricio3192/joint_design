function SUM = compare_direct_weld(DB, joints, J, Jc, outdir)
% COMPARE_DIRECT_WELD  Beams welded DIRECTLY to the column (dwj_lib), optionally
% side by side with the collar joint (dmj_lib) on the same joints.
%
%   source('lib/direct_weld_joint/dwj_lib.m');  source('lib/collar_joint/dmj_lib.m');
%   compare_direct_weld(DB, {'10', '13'}, dwj_default_joint(), default_joint(), 'reports')
%
% DB      joint database (load_joint_db)
% joints  point unique names, or {DB.joints.joint} for every joint
% J       direct-weld detail: dwj_default_joint() plus overrides
%         (J.wl.fl_type = 'cjp' for CJP flanges instead of fillets)
% Jc      collar detail (default_joint()) to compare with; [] = no comparison
% outdir  folder for direct_joints.pdf (and collar_joints.pdf with Jc); '' = no PDF.
%         make_joint_pdfs.m builds the content; lib/printing/joint_pdf.py prints it.
% The joint classes (joint_classes.m) must be on the path: only M beams are
% moment beams.  Prints the full direct-weld report and a summary with the
% governing check of each joint (and of the collar joint with Jc).

  if nargin < 4, Jc = []; end
  if nargin < 5, outdir = ''; end
  compare = ~isempty(Jc);

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

  if ~isempty(outdir)
    if compare
      kinds = struct('type', {'direct', 'collar'}, 'J', {J, Jc});
    else
      kinds = struct('type', {'direct'}, 'J', {J});
    end
    fprintf('\nPDF check sheets:\n');
    make_joint_pdfs(DB, joints, kinds, outdir);
  end
end
