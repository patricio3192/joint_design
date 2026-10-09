function explain_joint_equilibrium(DB, M, joints, opts)
% EXPLAIN_JOINT_EQUILIBRIUM  Why does a joint fail the equilibrium / mapping check?
%
%   S = load('data/joint_db/etabs_model.mat');
%   explain_joint_equilibrium(DB, S.M, {'3', '71', '73'})
%
%  For each joint it prints:
%    1. the frames at the joint: length, direction against the column
%       axes, and the distance from the joint centre to the member end
%       station (end offsets)
%    2. model geometry warnings: short frames and points close to the
%       joint (the 1 mm beam problem)
%    3. the residual broken down into the terms the libraries leave out
%       (see joint_residual.m), for the worst case
%    4. the verdict: which term explains the residual
%
%  DB, M: joint database and parsed model (build_joint_db writes both).
%  opts.short    m, frames shorter than this are flagged (0.05)
%  opts.near     m, other points closer than this to the joint are flagged (0.10)
%  opts.skewtol  deg, beams further than this off a column axis are flagged (1.0)

  if nargin < 4, opts = struct(); end
  short   = 0.05;  if isfield(opts, 'short'),   short   = opts.short;   end
  near    = 0.10;  if isfield(opts, 'near'),    near    = opts.near;    end
  skewtol = 1.0;   if isfield(opts, 'skewtol'), skewtol = opts.skewtol; end

nm = {'strong', 'weak'};
for n = 1:numel(joints)
  k = find(strcmp({DB.joints.joint}, joints{n}), 1);
  if isempty(k), error('Joint %s is not in the database.', joints{n}); end
  jt  = DB.joints(k);  map = jt.map;
  pj  = M.pt.xyz(strcmp(M.pt.name, jt.joint), :);
  kc  = find(strcmp(M.fr.name, num2str(map.col)), 1);
  Rc  = M.fr.R(:,:,kc);
  if strcmp(map.colM, 'M3'), ax = [2 3]; else, ax = [3 2]; end   % beam along this axis -> [strong weak]

  fprintf('\n================ JOINT %s at (%.3f, %.3f, %.3f) m ================\n', jt.joint, pj);
  fprintf('map: strong %s | weak %s | column %d (%s = strong)\n', ...
          mat2str(map.strong), mat2str(map.weak), map.col, map.colM);

  % ---- 1. frames
  fprintf('\n1. Frames at the joint\n');
  fprintf('  %-6s %-6s %-6s %8s  %-14s %9s  %9s\n', 'frame', 'type', 'mapped', 'L (m)', ...
          'along', 'off (deg)', 'arm (mm)');
  warn = {};
  kf = find(strcmp(M.fr.ptI, jt.joint) | strcmp(M.fr.ptJ, jt.joint));
  for i = kf.'
    arm = NaN;
    r = find(strcmp({jt.res.frame}, M.fr.name{i}), 1);
    if ~isempty(r), arm = 1000*norm(jt.res(r).arm); end
    b = str2double(M.fr.name{i});
    if any(b == map.strong), mp = 'strong'; elseif any(b == map.weak), mp = 'weak';
    elseif b == map.col, mp = 'column'; else, mp = '-'; end
    if strcmp(M.fr.type{i}, 'Beam')
      e1 = M.fr.R(1,:,i);
      c  = abs([dot(e1, Rc(ax(1),:)) dot(e1, Rc(ax(2),:))]);
      [cm, a] = max(c);
      off = acosd(min(cm / max(norm(c), eps), 1));
      along = [nm{a} ' axis'];
      if off > skewtol
        warn{end+1} = sprintf('beam %s is %.2f deg off the %s axis', M.fr.name{i}, off, nm{a});
      end
      if ~strcmp(mp, nm{a}) && ~strcmp(mp, '-')
        warn{end+1} = sprintf('beam %s runs along the %s axis but is mapped %s', M.fr.name{i}, nm{a}, mp);
      end
    else
      off = NaN;  along = '-';
    end
    fprintf('  %-6s %-6s %-6s %8.4f  %-14s %9.2f  %9.1f\n', M.fr.name{i}, M.fr.type{i}, ...
            mp, M.fr.L(i), along, off, arm);
    if M.fr.L(i) < short
      warn{end+1} = sprintf('frame %s is only %.1f mm long', M.fr.name{i}, 1000*M.fr.L(i));
    end
  end

  % ---- 2. geometry
  d  = sqrt(sum((M.pt.xyz - repmat(pj, size(M.pt.xyz, 1), 1)).^2, 2));
  kp = find(d > 0 & d < near);
  for i = kp.'
    warn{end+1} = sprintf('point %s is %.1f mm from the joint', M.pt.name{i}, 1000*d(i));
  end
  fprintf('\n2. Model geometry\n');
  if isempty(warn), fprintf('  nothing unusual\n'); end
  for i = 1:numel(warn), fprintf('  WARNING %s\n', warn{i}); end

  % ---- 3. residual breakdown
  Rr = joint_residual(M, jt, 'RSA');
  [~, w] = max([Rr.ratio]);  r = Rr(w);
  fprintf('\n3. Residual breakdown, worst case %s (kN*m about the column axes)\n', r.name);
  fprintf('  %-7s %9s %9s %10s | %9s %9s %9s | %9s\n', '', 'column', 'mapped', 'RESIDUAL', ...
          'torsion', 'skew', 'arm', 'closure');
  for q = 1:2
    fprintf('  %-7s %9.3f %9.3f %10.3f | %9.3f %9.3f %9.3f | %9.3f\n', nm{q}, r.col(q), ...
            r.mapped(q), r.residual(q), r.torsion(q), r.skew(q), r.arm(q), r.closure(q));
  end
  fprintf('  residual = %.1f%% of the largest beam moment (the libraries flag above 10%%)\n', 100*r.ratio);
  fprintf('  closure = residual + torsion + skew + arm: what is left is load on the\n');
  fprintf('  rigid end zones and rounding in the export.\n');

  % ---- 4. verdict: in the flagged case, and over all cases
  why = {['beam TORSION: a beam twists into the column. dmj_lib/dwj_lib do not ' ...
          'check torsion; look at that beam''s end release and the model.'], ...
         ['SKEWED beams: part of their bending goes into the other direction. ' ...
          'Harmless for the checks if the angle is real; if it is not, fix the geometry.'], ...
         ['FORCE x ARM: shears at the member ends (column face / end offsets) make a ' ...
          'moment about the joint centre. Real and expected; large for pinned beams ' ...
          'with a big reaction.']};
  [~, bw] = max([max(abs(r.torsion)) max(abs(r.skew)) max(abs(r.arm))]);
  T = reshape([Rr.torsion], 2, []).';
  K = reshape([Rr.skew], 2, []).';  A = reshape([Rr.arm], 2, []).';
  tot = [max(abs(T(:))) max(abs(K(:))) max(abs(A(:)))];
  [~, ba] = max(tot);
  fprintf('\n4. Verdict\n');
  fprintf('  in the worst case (%s): mostly %s\n', r.name, why{bw});
  fprintf('  largest terms over all cases: torsion %.3f | skew %.3f | arm %.3f kN*m\n', tot);
  if ba ~= bw, fprintf('  over all cases: mostly %s\n', why{ba}); end
  fprintf('  the ratio is taken against max(largest beam moment, 1 kN*m) = %.2f kN*m in that case\n', max(abs(r.residual)) / r.ratio);
end
end
