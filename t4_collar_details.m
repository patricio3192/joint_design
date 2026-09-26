% =====================================================================
%  t4_collar_details.m   Collar plate types and detailing sheets.
%
%  Reads the joint classes (joint_classes.m), groups the collar plates
%  into types, prints the schedule, and writes reports/collar_details.pdf:
%  key plan, joint schedule, plate types, sections of the three
%  connection types (M, S, NL) and a plan of every joint.
%
%  The plate sizes come from the same J as the capacity checks (t1), so
%  edit the detail in dmj_lib default_joint or below, not in the drawing.
% =====================================================================
here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(here, 'etabs_joints'));
source(fullfile(here, 'dmj_lib.m'));
DB = load_joint_db(fullfile(here, 'joint_db', 'joint_db.mat'));
S  = load(fullfile(here, 'joint_db', 'etabs_model.mat'));  M = S.M;

% ---- EDIT: the detail -----------------------------------------------------
J = default_joint();
% J.pl.L_lap = 80;  J.pl.w_back = 30;
opts.stab = [8 60 25 3];   % stability plates for S beams: t, length, depth, clearance (mm)

% ======================================================================
for k = 1:numel(DB.joints)
  [~, ~, msg] = joint_config(DB.joints(k), J);
  for m = 1:numel(msg), fprintf('WARNING %s\n', msg{m}); end
end

T = collar_types(DB, J);
fprintf('\nCOLLAR PLATE TYPES (cap and shelf share the outline)\n');
for t = 1:numel(T)
  fprintf('  Type %s: PL %g x %g, strips along D %s, along B %s | %2d joints, %2d plates: %s\n', ...
          T(t).name, T(t).LD, T(t).LB, mat2str(T(t).oD), mat2str(T(t).oB), ...
          numel(T(t).joints), 2*numel(T(t).joints), strjoin(T(t).joints, ' '));
end

fprintf('\nDetail sheets:\n');
make_detail_pdf(DB, M, J, fullfile(here, 'reports'), opts);
