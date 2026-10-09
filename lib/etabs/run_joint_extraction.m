% RUN_JOINT_EXTRACTION  Example driver - edit file names and joint below.
clear; clc;

% ---- 1. ETABS exports (text or CSV), any grouping, same units everywhere.
%      One big .txt holding all tables is fine.
d = 'C:\myproject\etabs_export\';
M = load_etabs_model({[d 'tables.txt']});
%   or: M = load_etabs_model({[d 'forces.txt'], [d 'points.txt']});

% ---- 2. one joint
joint = '10';                            % ETABS point UNIQUE name
[res, chk] = joint_forces(M, joint);     % ref axes = the column's local axes

% keep only load combinations (drop Dead, Live, Modal, RSA X ...)
res = res(strcmp({res.ctype}, 'Combination'));

print_joint_forces(res, chk, joint);
write_joint_forces(res, ['joint_' joint '.csv']);

% ---- 3. all column tops in one go
tops = unique(M.fr.ptJ(strcmp(M.fr.type, 'Column')));
for k = 1:numel(tops)
  r = joint_forces(M, tops{k});
  r = r(strcmp({r.ctype}, 'Combination'));
  write_joint_forces(r, ['joint_' tops{k} '.csv']);
  ALL.(['J' regexprep(tops{k}, '\W', '_')]) = r;   % keep for your design function
end
