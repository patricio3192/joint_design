% =====================================================================
%  casa_saav / collar_joints.m   Beam-to-HSS-column joints with external
%  diaphragm collars (lib/collar_joint), from the ETABS export.
%
%  Steps (switch them on in EDIT 1):
%    build        parse data/gg.txt into data/joint_db/ (~40 s; again only
%                 when the export changes)
%    check        capacity check of the joints (dmj_lib)
%    details      collar plate types + reports/collar_details.pdf
%    sheets       A2 sheets reports/planos_uniones.pdf + beam-to-beam checks
%    compare      direct weld (lib/direct_weld_joint) vs collar on a few joints,
%                 + reports/direct_joints.pdf and collar_joints.pdf
%    equilibrium  why some joints fail the equilibrium / mapping check
%
%  Project data: data/joint_classes.m (what arrives at each joint),
%  data/grid_lines.m (construction grid), data/gg.txt (ETABS export, not in git).
%  Run from anywhere:  octave-cli casa_saav/collar_joints.m
% =====================================================================
here = fileparts(mfilename('fullpath'));
lib  = fullfile(here, '..', 'lib');
addpath(fullfile(lib, 'collar_joint'), fullfile(lib, 'direct_weld_joint'), fullfile(lib, 'etabs'));
source(fullfile(lib, 'collar_joint', 'dmj_lib.m'));
out = fullfile(here, 'reports');
dbd = fullfile(here, 'data', 'joint_db');

% ---- EDIT 1: steps ---------------------------------------------------------
steps.build       = false;
steps.check       = true;
steps.details     = true;
steps.sheets      = true;
steps.compare     = false;
steps.equilibrium = false;

% ---- EDIT 2: the detail (sections, plates and welds live in dmj_lib default_joint)
J = default_joint();
% J.pl.t_cap = 12;  J.pl.t_shf = 12;  J.pl.L_lap = 80;

% ---- EDIT 3: joints to check ----------------------------------------------
%  point unique names; build_joint_db prints the list of joints and their maps
check_joints = 'all';                   % or {'10'}
compare_joints = {'10', '13'};          % direct weld vs collar
equilibrium_joints = {'3', '71', '73'};

% ---- EDIT 4: detail and plan sheets ---------------------------------------
dopts.stab = [8 60 25 3];     % stability plates for S beams: t, length, depth, clearance (mm)
opts.gap  = [5 12];           % beam end to column face, mm: min (clear of the collar fillet), max
opts.proj = 10;               % column top above the upper collar, mm (for the fillet)
opts.stab = [8 60 25 3];      % stability plates for C beams: t, length, depth, clearance (mm)
opts.stab_leg = 5;            % their fillet to the upper collar, mm (min. for an 8 mm plate)
opts.hole_r = 6;              % collar opening corner radius drawn, mm (<= tube outside corner radius)
% beams not in the model, drawn in detail 1: {Y (m), from line, to line}
opts.extra = {4.33 - 0.20, 'A', 'F', ...  % 20 cm south of line 3, below the collars
  'Vigas a 20 cm al sur del eje 3: a nivel inferior, bajo los collarines; no interfieren con ellos.'};
% title block on every sheet: label, value ('\n' starts a new line);
% '@sheet' = sheet title and contents, '@page' = sheet number
opts.titleblock = {
  'PROYECTO:',               'VIVIENDA EDGAR ORTEGA Y FAMILIA'
  'PROPIETARIO:',            'SR. EDGAR ORTEGA'
  'DISEÑO ARQUITECTÓNICO:',  'DAVID SAAVEDRA'
  'DISEÑO ESTRUCTURAL:',     'ING. PATRICIO RODRIGUEZ\nSENESCYT: 1007-15-1429459'
  'CONTENIDO:',              '@sheet'
  'FECHA:',                  'SEPTIEMBRE 2026'
  'LÁMINA:',                 '@page'
};
opts.tbwidths = [15 11 12 15 29 9 9];   % relative column widths

% ======================================================================
% project data, passed to the libraries (data/ is not left on the path)
addpath(fullfile(here, 'data'));
C = joint_classes();                    % what arrives on each side of every joint
G = grid_lines();                       % construction grid
rmpath(fullfile(here, 'data'));

if steps.build
  build_joint_db(fullfile(here, 'data', 'gg.txt'), dbd);
end
DB = load_joint_db(fullfile(dbd, 'joint_db.mat'));
S  = load(fullfile(dbd, 'etabs_model.mat'));  M = S.M;
if ischar(check_joints), check_joints = {DB.joints.joint}; end

% ---- check: capacity of every joint ----------------------------------------
if steps.check
  SUM = {};
  for n = 1:numel(check_joints)
    k = find(strcmp({DB.joints.joint}, check_joints{n}), 1);
    if isempty(k)
      error('Joint %s is not in the database. Available: %s', check_joints{n}, ...
            strjoin({DB.joints.joint}, ' '));
    end
    jt  = DB.joints(k);
    % beams by class (joint_classes.m) and the collar strip on each side
    [map, Jj, msg] = joint_config(jt, J, C);
    map.skip = 'RSA';                     % signed combinations only
    for m = 1:numel(msg), fprintf('WARNING %s\n', msg{m}); end
    if ~isempty(map.skew)
      fprintf('NOTE joint %s: beams %s are skew to the column axes\n', ...
              jt.joint, mat2str(map.skew));
    end

    E = run_joint_res(Jj, jt.res, map, sprintf('JOINT %s', jt.joint));

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
end

% ---- details: collar plate types and detail sheets --------------------------
if steps.details
  for k = 1:numel(DB.joints)
    [~, ~, msg] = joint_config(DB.joints(k), J, C);
    for m = 1:numel(msg), fprintf('WARNING %s\n', msg{m}); end
  end
  T = collar_types(DB, J, C);
  fprintf('\nCOLLAR PLATE TYPES (cap and shelf share the outline)\n');
  for t = 1:numel(T)
    fprintf('  Type %s: PL %g x %g, strips along D %s, along B %s | %2d joints, %2d plates: %s\n', ...
            T(t).name, T(t).LD, T(t).LB, mat2str(T(t).oD), mat2str(T(t).oB), ...
            numel(T(t).joints), 2*numel(T(t).joints), strjoin(T(t).joints, ' '));
  end
  fprintf('\nDetail sheets:\n');
  make_detail_pdf(DB, M, J, C, out, dopts);
end

% ---- sheets: A2 plan sheets and beam-to-beam checks ---------------------------
if steps.sheets
  for k = 1:numel(DB.joints)
    [~, ~, msg] = joint_config(DB.joints(k), J, C);
    for m = 1:numel(msg), fprintf('WARNING %s\n', msg{m}); end
  end
  % beam to beam shear connections: every location, worst check
  P = plan_layout(M, DB, G);
  fprintf('\nBEAM TO BEAM SHEAR CONNECTIONS (design V = max(model, %.0f kN))\n', J.vv.Vmin/1e3);
  fprintf('  %-5s %-5s %-4s %-12s %-10s %8s  %s\n', 'point', 'near', 'kind', 'cut beams', 'support', 'V (kN)', 'worst check');
  worst = 0;
  for v = P.vv
    V = vv_checks(J, max(v.V), v.nsup);
    d = cellfun(@(x) x{6}, V);  [w, i] = max(d);  worst = max(worst, w);
    fprintf('  %-5s %5.2f,%5.2f %-4s %-12s %-10s %8.2f  %s %s DCR %.2f\n', v.pt, v.xy, v.kind, ...
            strjoin(v.coped, ','), strjoin(v.support, ','), max(v.V)/1e3, V{i}{1}, V{i}{2}, w);
  end
  fprintf('  cope %g x %g mm (depth x length), web left %g mm, fillet %g mm both sides; worst DCR %.2f\n', ...
          J.vv.dc, J.vv.c, J.bm.h - 2*J.vv.dc, J.vv.leg, worst);
  fprintf('\nSheets:\n');
  make_plan_sheets(DB, M, J, C, G, out, opts);
end

% ---- compare: direct weld vs collar ---------------------------------------
if steps.compare
  source(fullfile(lib, 'direct_weld_joint', 'dwj_lib.m'));
  % J.wl.fl_type = 'cjp' in the direct-weld detail: flanges CJP instead of fillets
  compare_direct_weld(DB, compare_joints, dwj_default_joint(), J, C, out);
end

% ---- equilibrium: why a joint fails the equilibrium / mapping check -----------
if steps.equilibrium
  explain_joint_equilibrium(DB, M, equilibrium_joints);
end
