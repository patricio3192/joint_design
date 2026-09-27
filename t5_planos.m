% =====================================================================
%  t5_planos.m   A2 sheets for the structural drawings (Spanish).
%
%  Writes reports/planos_uniones.pdf:
%    lámina 1  general plan of the joints and joint schedule
%    lámina 2  collar plate types and connection details
%    lámina 3+ plan of every joint
%  and prints the beam-to-beam and seat checks here (not on the sheets).
%
%  Inputs: joint_classes.m (what arrives at each joint), grid_lines.m
%  (construction grid), and the detail J from dmj_lib default_joint.
% =====================================================================
here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(here, 'etabs_joints'));
source(fullfile(here, 'dmj_lib.m'));
DB = load_joint_db(fullfile(here, 'joint_db', 'joint_db.mat'));
S  = load(fullfile(here, 'joint_db', 'etabs_model.mat'));  M = S.M;

% ---- EDIT ---------------------------------------------------------------
J = default_joint();
opts.gap  = 10;               % beam end to column face on the drawings, mm (<=)
opts.proj = 10;               % column top above the upper collar, mm (for the fillet)
opts.stab = [8 60 25 3];      % stability plates for C beams: t, length, depth, clearance (mm)
% opts.project = 'Nombre del proyecto';

% ======================================================================
for k = 1:numel(DB.joints)
  [~, ~, msg] = joint_config(DB.joints(k), J);
  for m = 1:numel(msg), fprintf('WARNING %s\n', msg{m}); end
end

% beam to beam shear connections: every location, worst check
P = plan_layout(M, DB);
fprintf('\nBEAM TO BEAM SHEAR CONNECTIONS (design V = max(model, %.0f kN))\n', J.vv.Vmin/1e3);
fprintf('  %-5s %-5s %-4s %-12s %-10s %8s  %s\n', 'point', 'near', 'kind', 'cut beams', 'support', 'V (kN)', 'worst check');
worst = 0;
for v = P.vv
  C = vv_checks(J, max(v.V), v.nsup);
  d = cellfun(@(x) x{6}, C);  [w, i] = max(d);  worst = max(worst, w);
  fprintf('  %-5s %5.2f,%5.2f %-4s %-12s %-10s %8.2f  %s %s DCR %.2f\n', v.pt, v.xy, v.kind, ...
          strjoin(v.coped, ','), strjoin(v.support, ','), max(v.V)/1e3, C{i}{1}, C{i}{2}, w);
end
fprintf('  cope %g x %g mm (depth x length), web left %g mm, fillet %g mm both sides; worst DCR %.2f\n', ...
        J.vv.dc, J.vv.c, J.bm.h - 2*J.vv.dc, J.vv.leg, worst);

fprintf('\nSheets:\n');
make_plan_sheets(DB, M, J, fullfile(here, 'reports'), opts);
