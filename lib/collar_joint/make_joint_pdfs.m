function files = make_joint_pdfs(DB, joints, kinds, C, outdir, opts)
% MAKE_JOINT_PDFS  One PDF check sheet per connection type, covering a
% list of joints, in the style of joint10_handcheck.pdf.
%
%   files = make_joint_pdfs(DB, {'10','13'}, kinds, C, 'reports')
%
%   C               the project's joint classes (see README.md)
%
%   kinds(k).type   'collar' (dmj_lib) or 'direct' (dwj_lib)
%   kinds(k).J      the detail, from default_joint / dwj_default_joint
%   opts.python     Python command                 (default 'python3')
%   opts.seis       regexp marking seismic cases   (default 'E[xy]')
%   opts.skip       cases left out, as map.skip    (default 'RSA')
%
% Every number and every line of text on the sheet is produced here, from
% the libraries.  The library of each type must already be loaded with
% source().  A check shows its capacity with the numbers substituted when
% the library supplies that text (8th field of the check); otherwise only
% the value.
%
% The sheet is written to <outdir>/<type>_joints.json as a list of blocks
% (headings, paragraphs, tables of strings), and
% lib/printing/joint_pdf.py only lays it out as
% <outdir>/<type>_joints.pdf.

  if nargin < 6, opts = struct(); end
  if ~iscell(C), error('make_joint_pdfs: give the joint classes C.'); end
  if ~isfield(opts, 'python'), opts.python = 'python3'; end
  if ~isfield(opts, 'seis'),   opts.seis   = 'E[xy]'; end
  if ~isfield(opts, 'skip'),   opts.skip   = 'RSA'; end
  if ~exist(outdir, 'dir'), mkdir(outdir); end
  here = fileparts(mfilename('fullpath'));
  addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'sheets'));   % d_* items, blk_* blocks
  printer = fullfile(here, '..', 'printing', 'joint_pdf.py');

  files = {};
  for q = 1:numel(kinds)
    kd = kinds(q);
    ti = type_info(kd.type);
    recs = {};
    for n = 1:numel(joints)
      k = find(strcmp({DB.joints.joint}, joints{n}), 1);
      if isempty(k), error('Joint %s is not in the database.', joints{n}); end
      recs{end+1} = joint_record(DB.joints(k), kd, C, opts);
    end

    B = front_blocks(DB, recs, ti, opts);
    for n = 1:numel(recs)
      B = [B, {blk_page()}, joint_blocks(recs{n}, ti, opts)];
    end
    doc = struct('title', ti.title, 'blocks', {B});

    base = fullfile(outdir, [kd.type '_joints']);
    fid = fopen([base '.json'], 'w');
    if fid < 0, error('Cannot write %s.json', base); end
    fprintf(fid, '%s', jsonencode(doc));
    fclose(fid);

    [st, out] = system(sprintf('%s "%s" "%s.json" "%s.pdf"', opts.python, printer, base, base));
    fprintf('%s', out);
    if st ~= 0
      error('PDF generation failed for %s (see the message above).', kd.type);
    end
    files{end+1} = [base '.pdf'];
  end
end

% =====================================================================
%  What differs between the two connection types
% =====================================================================
function ti = type_info(type)
  ti.type = type;
  switch type
    case 'collar'
      ti.title   = 'Diaphragm moment joint (double collar) - check sheet';
      ti.library = 'dmj_lib.m';
      ti.manual  = 'diaphragm_joint_manual.md';
      ti.flange  = {'T4s', 'T4w'};        % checks whose demand is the flange force
      ti.net     = {'T7s', 'T7w'};        % checks whose demand is Mcol / z
      ti.quick   = {'T2', 'T8s'};
      ti.notcovered = ['Column P-M-M interaction unless phiPn is given (take it from ETABS), ' ...
        'beam torsion, lateral-torsional buckling of the cantilevers, the erection cleat, ' ...
        'fatigue, fire, and seismic detailing under AISC 341 (this connection is not ' ...
        'prequalified under AISC 358). Checks marked [MODEL] or [INFO] carry no code ' ...
        'equation: T5, T6, T9, T10, T11, Tc and the lever arm z. Section 8 of the manual ' ...
        'lists them with their risk.'];
    case 'direct'
      ti.title   = 'Direct-welded moment joint (no collar) - check sheet';
      ti.library = 'dwj_lib.m';
      ti.manual  = 'direct_weld_manual.md';
      ti.flange  = {'F1s', 'F1w'};
      ti.net     = {'C1s', 'C1w'};
      ti.quick   = {'B1', 'F1s', 'W2'};
      ti.notcovered = ['Column P-M-M interaction unless phiPn is given (take it from ETABS), ' ...
        'beam torsion, the web as a longitudinal plate under beam axial force, the design ' ...
        'wall thickness 0.93 t of AISC B4.2 for ERW tubes (the nominal t is used), ' ...
        'lateral-torsional buckling, fatigue, fire, and seismic detailing under AISC 341 ' ...
        '(not prequalified under AISC 358). Faces outside the 360-10 Table K1.2A limits (section 2) are ' ...
        'checked with the same equations for comparison only. F6 is an [INFO] cross-check ' ...
        'from EN 1993-1-8, gamma_M5 = 1.0.'];
    otherwise
      error('Unknown connection type %s.', type);
  end
end

% =====================================================================
%  All checks of one joint, for every load case
% =====================================================================
function rec = joint_record(jt, kd, C, opts)
  [map, Jc] = joint_config(jt, kd.J, C);   % beams by class, collar strips per side
  map.skip = opts.skip;
  nside = [min(numel(map.strong),2) min(numel(map.weak),2)];
  if strcmp(kd.type, 'collar')
    cs = cases_from_res(jt.res, map);
    Jg = plate_geometry(Jc, nside);
  else
    cs = dwj_cases_from_res(jt.res, map);
    Jg = kd.J;
  end

  nc = numel(cs);
  tags = {};  info = {};  cap = [];  dem = [];  dcr = [];
  for n = 1:nc
    if strcmp(kd.type, 'collar'), C = joint_checks(Jg, cs(n));
    else,                         C = dwj_checks(Jg, cs(n), nside); end
    for i = 1:numel(C)
      t = find(strcmp(tags, C{i}{1}));
      if isempty(t)
        tags{end+1} = C{i}{1};  info{end+1} = C{i};
        t = numel(tags);
        cap(t, 1:nc) = NaN;  dem(t, 1:nc) = NaN;  dcr(t, 1:nc) = NaN;
      end
      cap(t, n) = C{i}{4};  dem(t, n) = C{i}{5};  dcr(t, n) = C{i}{6};
      if numel(C{i}) >= 8 && ~isempty(C{i}{8}), info{t}{8} = C{i}{8}; end
    end
  end

  names  = {cs.name};
  isSeis = ~cellfun(@isempty, regexp(names, opts.seis, 'once'));
  worst  = max(dcr, [], 1);

  rec = struct('joint', jt.joint, 'map', map, 'nside', nside, 'J', Jg, 'cs', cs, ...
               'type', kd.type);
  rec.names = names;  rec.isSeis = isSeis;
  rec.tags = tags;  rec.info = info;  rec.cap = cap;  rec.dem = dem;  rec.dcr = dcr;
  rec.gi = pick(worst, ~isSeis);         % governing gravity case
  rec.si = pick(worst, isSeis);          % governing seismic case
  res = reshape([cs.res], 2, []).';
  Mb  = cellfun(@(m) max([m 0]), {cs.M}).'/1e6;
  rec.residual = max(max(abs(res) ./ repmat(max(Mb, 1), 1, 2)));
end

function i = pick(w, sel)
  if ~any(sel), i = []; return; end
  w(~sel) = -Inf;  [~, i] = max(w);
end

% worst case of one check within a group: [dcr, case index], [] if absent
function [d, n] = worst_in(rec, t, sel)
  x = rec.dcr(t, :);  x(~sel) = NaN;
  if all(isnan(x)), d = []; n = []; return; end
  [d, n] = max(x);
end

% =====================================================================
%  Sheet content
% =====================================================================
function B = front_blocks(DB, recs, ti, opts)
  B = {blk_h(1, ti.title), blk_p(sprintf(['Library %s, manual %s. Forces from %s, joint ' ...
       'database built %s; sheet generated %s. RSA combinations are excluded. Load ' ...
       'combinations matching ''%s'' are reported as seismic, the rest as gravity. ' ...
       'One section per joint follows.'], ti.library, ti.manual, DB.source, DB.built, ...
       datestr(now), opts.seis))};
  rows = {};  red = {};
  for n = 1:numel(recs)
    r = recs{n};
    [d, t, c] = governing(r);
    rows{end+1} = {r.joint, sprintf('%d', r.map.col), mat2str(r.map.strong), ...
                   mat2str(r.map.weak), [r.tags{t} ' ' r.info{t}{2}], sprintf('%.2f', d), r.names{c}};
    if d > 1, red{end+1} = [n 6]; end
  end
  B = [B, {blk_h(2, 'Summary'), blk_table({'Joint','Column','Strong','Weak', ...
       'Governing check','DCR','Case'}, rows, [0.07 0.08 0.11 0.11 0.37 0.07 0.19], {6}, red)}];
end

function [d, t, c] = governing(r)
  [dd, cc] = max(r.dcr, [], 2);
  [d, t] = max(dd);  c = cc(t);
end

function B = joint_blocks(r, ti, opts)
  J = r.J;  b = J.bm;  c = J.cl;  nm = {'strong','weak'};
  if min(r.nside) == 2,     kind = 'interior (X)';
  elseif min(r.nside) > 0 && max(r.nside) == 2, kind = 'T';
  elseif min(r.nside) > 0,  kind = 'corner (L)';
  else,                     kind = 'one direction';
  end
  nb = numel(r.map.strong) + numel(r.map.weak);
  intro = sprintf(['Joint %s, %s, %d beams (h = %s, bf = %s) on HSS %sx%sx%s, column %d. ' ...
    'Strong beams %s, weak beams %s. Companion to %s and %s. Units N, mm throughout; ' ...
    'results shown in kN and kNm. AISC 360-16, LRFD.'], r.joint, kind, nb, num(b.h), ...
    num(b.bf), num(c.D), num(c.B), num(c.t), r.map.col, mat2str(r.map.strong), ...
    mat2str(r.map.weak), ti.library, ti.manual);
  [d, tg, cg] = governing(r);
  gov = sprintf(['Governing: %s %s, DCR %.2f, case %s. Gravity DCR = worst over the ' ...
    'gravity combinations, seismic DCR = worst over combinations matching ''%s''.'], ...
    r.tags{tg}, r.info{tg}{2}, d, r.names{cg}, opts.seis);
  if r.residual > 0.10
    gov = [gov sprintf([' Equilibrium/mapping residual %.0f%% of the largest beam ' ...
      'moment: check the map, or beam torsion at this joint.'], 100*r.residual)];
  end
  if isfield(r.map, 'sides')
    intro = [intro sprintf([' Class (W N E S): %s; shear only on the shelf %s; below the ' ...
      'collar on a shear tab %s.'], strjoin(r.map.sides, ' '), mat2str(r.map.shear), mat2str(r.map.nl))];
  end
  B = {blk_h(1, ['Joint ' r.joint]), blk_p(intro), blk_p(gov)};

  % ---- 1. index
  rows = {};  red = {};  varies = false;
  for t = 1:numel(r.tags)
    [dg, ng] = worst_in(r, t, ~r.isSeis);
    [ds, ns] = worst_in(r, t, r.isSeis);
    [~, ne]  = worst_in(r, t, true(size(r.isSeis)));
    cc = r.cap(t, ~isnan(r.cap(t, :)));
    capt = val(r.cap(t, ne), r.info{t}{7});
    if max(cc) - min(cc) > 1e-6*max(abs(cc)), capt = [capt ' *']; varies = true; end
    rows{end+1} = {r.tags{t}, r.info{t}{2}, r.info{t}{3}, capt, dcrtxt(dg), dcrtxt(ds)};
    if ~isempty(dg) && dg > 1, red{end+1} = [t 5]; end
    if ~isempty(ds) && ds > 1, red{end+1} = [t 6]; end
  end
  note = 'DCR above 1.00 in red. Tags marked [MODEL] or [INFO] are engineering models, not code equations.';
  if varies
    note = ['* the capacity depends on the load case; the value shown is at the case ' ...
            'governing the envelope, see section 5. ' note];
  end
  B = [B, {blk_h(2, '1. Index of limit states'), ...
           blk_table({'Tag','Limit state','Reference','Capacity','Gravity DCR','Seismic DCR'}, ...
                     rows, [0.07 0.33 0.2 0.14 0.13 0.13], {4,5,6}, red), blk_note(note), blk_page()}];

  % ---- 2. data
  B = [B, {blk_h(2, '2. Data'), blk_h(3, 'Materials and sections'), ...
           blk_table({'Item','Symbol','Value','Note'}, materials_rows(J), [0.34 0.12 0.18 0.36], {}, {})}];
  if strcmp(r.type, 'collar'), T = collar_data(J, r.nside); else, T = dwj_sheet_data(J, r.nside); end
  for k = 1:numel(T)
    w = [0.34 0.12 0.18 0.36];  if numel(T{k}{2}) == 3, w = [0.4 0.3 0.3]; end
    B = [B, {blk_h(3, T{k}{1}), blk_table(T{k}{2}, T{k}{3}, w, {}, {})}];
  end
  B = [B, {blk_page()}];

  % ---- 3. demands
  ci = {r.gi, r.si};
  hdr = {'Quantity','How it is obtained','Gravity','Seismic'};
  rows = {row3('Load combination', 'from ETABS', ci, @(n) r.names{n})};
  bm = [r.map.strong r.map.weak];  dr = [ones(1,numel(r.map.strong)) 2*ones(1,numel(r.map.weak))];
  for i = 1:numel(bm)
    rows{end+1} = row3(sprintf('Beam %d moment (%s)', bm(i), nm{dr(i)}), '|M3| at the beam end', ...
                       ci, @(n) sprintf('%.2f kNm', r.cs(n).M(i)/1e6));
  end
  for i = 1:numel(bm)
    rows{end+1} = row3(sprintf('Beam %d axial', bm(i)), 'P at the beam end', ...
                       ci, @(n) sprintf('%.2f kN', r.cs(n).N(i)/1e3));
  end
  rows = [rows, { ...
    row3('Column-top moment, strong', [r.map.colM ' at the column top'], ci, @(n) sprintf('%.2f kNm', r.cs(n).Mcol(1)/1e6)), ...
    row3('Column-top moment, weak', 'other axis', ci, @(n) sprintf('%.2f kNm', r.cs(n).Mcol(2)/1e6)), ...
    row3('Largest reaction', '-F1 on the joint, column axes', ci, @(n) sprintf('%.2f kN', max([r.cs(n).V 0])/1e3)), ...
    row3('Column axial', '-P at the column top', ci, @(n) sprintf('%.2f kN', r.cs(n).Pu/1e3))}];
  for d = 1:2
    t = find(strcmp(r.tags, ti.flange{d}));
    if ~isempty(t)
      rows{end+1} = row3(['Flange force, ' nm{d}], ['|M|/z + |N|/2, demand of ' ti.flange{d}], ...
                         ci, @(n) sprintf('%.1f kN', r.dem(t, n)/1e3));
    end
  end
  for d = 1:2
    t = find(strcmp(r.tags, ti.net{d}));
    if ~isempty(t)
      rows{end+1} = row3(['Net force, ' nm{d}], ['M_col / z, demand of ' ti.net{d}], ...
                         ci, @(n) sprintf('%.1f kN', r.dem(t, n)/1e3));
    end
  end
  B = [B, {blk_h(2, '3. Demands'), blk_table(hdr, rows, [0.28 0.3 0.21 0.21], {3,4}, {}), ...
           blk_note(['The gravity and seismic columns are the combinations with the largest ' ...
                     'DCR of any check in each group.'])}];

  % ---- 4. capacities
  rows = {};
  for t = 1:numel(r.tags)
    [~, ne] = worst_in(r, t, true(size(r.isSeis)));
    rows{end+1} = {r.tags{t}, r.info{t}{3}, subtxt(r.info{t}), val(r.cap(t, ne), r.info{t}{7})};
  end
  B = [B, {blk_h(2, '4. Capacities, with numbers substituted'), ...
           blk_table({'Tag','Reference','Substitution','Result'}, rows, [0.07 0.19 0.56 0.18], {4}, {})}];
  if ~any(cellfun(@(x) numel(x) >= 8 && ~isempty(x{8}), r.info))
    B = [B, {blk_note(sprintf(['%s does not supply the substituted formulas; the table ' ...
             'shows the capacities only.'], ti.library))}];
  end
  B = [B, {blk_page()}];

  % ---- 5. capacities that depend on the load case
  rows = {};  red = {};
  for t = 1:numel(r.tags)
    cc = r.cap(t, ~isnan(r.cap(t, :)));
    if ~(max(cc) - min(cc) > 1e-6*max(abs(cc))), continue; end
    row = {r.tags{t}, r.info{t}{2}};
    for g = 1:2
      if g == 1, sel = ~r.isSeis; else, sel = r.isSeis; end
      [dd, n] = worst_in(r, t, sel);
      if isempty(dd)
        row = [row, {'-', '-', '-', '-'}];
      else
        row = [row, {r.names{n}, val(r.cap(t,n), r.info{t}{7}), val(r.dem(t,n), r.info{t}{7}), ...
                     sprintf('%.2f', dd)}];
        if dd > 1, red{end+1} = [numel(rows)+1, 2+4*g]; end
      end
    end
    rows{end+1} = row;
  end
  if ~isempty(rows)
    B = [B, {blk_h(2, '5. Capacities that depend on the load case'), ...
             blk_p(['These capacities change with the forces of the case (for example the axial ' ...
                    'force in the shelf, or the column stress through Qf). Each is shown at its ' ...
                    'worst gravity and worst seismic combination.']), ...
             blk_table({'Tag','Limit state','Gravity case','Capacity','Demand','DCR', ...
                        'Seismic case','Capacity','Demand','DCR'}, rows, ...
                       [0.06 0.18 0.13 0.1 0.1 0.06 0.13 0.1 0.1 0.06], {4,5,6,8,9,10}, red)}];
  end

  % ---- 6. quick checks
  tags = [r.tags(tg), ti.quick];
  [~, keep] = unique(tags, 'stable');  tags = tags(keep);
  B = [B, {blk_h(2, '6. Checks to do first')}];
  k = 0;
  for q = 1:numel(tags)
    t = find(strcmp(r.tags, tags{q}));
    if isempty(t), continue; end
    [~, ne] = worst_in(r, t, true(size(r.isSeis)));
    k = k + 1;
    s = subtxt(r.info{t});
    if strcmp(s, '-'), s = ''; else, s = [s ' = ']; end
    B = [B, {blk_p(sprintf('%d. %s %s (%s): %s%s, against a demand of %s in %s.', k, ...
             r.tags{t}, r.info{t}{2}, r.info{t}{3}, s, val(r.cap(t,ne), r.info{t}{7}), ...
             val(r.dem(t,ne), r.info{t}{7}), r.names{ne}))}];
  end
  B = [B, {blk_p(['If these match, the units, the resistance factors and the forces are ' ...
                  'right, and the rest is the same arithmetic with different areas.']), ...
           blk_h(2, '7. What is not on this sheet'), blk_p(ti.notcovered)}];
end

function row = row3(label, how, ci, f)
  row = {label, how};
  for g = 1:2
    if isempty(ci{g}), row{end+1} = '-'; else, row{end+1} = f(ci{g}); end
  end
end

function rows = materials_rows(J)
  b = J.bm;  c = J.cl;
  if isfield(c, 'phiPn') && ~isnan(c.phiPn), pp = sprintf('%.1f kN', c.phiPn/1e3); else, pp = 'not given'; end
  rows = { ...
    {'Elastic modulus', 'E', [num(J.E) ' MPa'], ''}, ...
    {'Electrode', 'FEXX', [num(J.FEXX) ' MPa'], ''}, ...
    {'Beam yield / tensile', 'Fy, Fu', [num(b.Fy) ' / ' num(b.Fu) ' MPa'], ''}, ...
    {'Beam depth', 'h', [num(b.h) ' mm'], ''}, ...
    {'Beam flange width', 'bf', [num(b.bf) ' mm'], ''}, ...
    {'Beam flange thickness', 'tf', [num(b.tf) ' mm'], ''}, ...
    {'Beam web thickness', 'tw', [num(b.tw) ' mm'], ''}, ...
    {'Beam root radius', 'r', [num(b.r) ' mm'], ''}, ...
    {'Beam plastic modulus', 'Zx', [num(b.Zx) ' mm3'], ''}, ...
    {'Column side, strong direction', 'D', [num(c.D) ' mm'], sprintf('HSS %sx%sx%s', num(c.D), num(c.B), num(c.t))}, ...
    {'Column side, weak direction', 'B', [num(c.B) ' mm'], ''}, ...
    {'Column wall', 't', [num(c.t) ' mm'], 'nominal'}, ...
    {'Column yield / tensile', 'Fy, Fu', [num(c.Fy) ' / ' num(c.Fu) ' MPa'], ''}, ...
    {'Column compression capacity', 'phiPn', pp, 'from ETABS; enables M6 (H1-1)'}};
end

% inputs of the collar and the plate size from dmj_lib plate_geometry
function T = collar_data(J, nside)
  p = J.pl;  w = J.wl;  st = J.st;
  if isfield(p, 'oD'), sD = mat2str(p.oD); sB = mat2str(p.oB);
  else, sD = sprintf('%d beam side(s)', nside(1)); sB = sprintf('%d beam side(s)', nside(2)); end
  wm = {'bf, no dispersion', 'bf + 2e, 45 degrees', 'Whitmore', ...
        'wall + 2e tan30, support-based', 'facing wall alone'};
  if st.rib_t > 0, rib = sprintf('%s x %s mm, 2 per beam', num(st.rib_t), num(st.rib_d)); else, rib = 'none'; end
  if isfield(st, 'e_auto') && st.e_auto, eh = 'gap + L_lap/2 (e_auto)'; else, eh = 'input'; end
  plates = { ...
    {'Cap plate thickness', 't_cap', [num(p.t_cap) ' mm'], 'input'}, ...
    {'Shelf plate thickness', 't_shf', [num(p.t_shf) ' mm'], 'input'}, ...
    {'Plate yield / tensile', 'Fy, Fu', [num(p.Fy) ' / ' num(p.Fu) ' MPa'], 'input'}, ...
    {'Lap over each beam flange', 'L_lap', [num(p.L_lap) ' mm'], 'input; also the weld length each side'}, ...
    {'Erection gap', 'gap', [num(st.gap) ' mm'], 'input'}, ...
    {'Overhang, side with no beam', 'w_back', [num(p.w_back) ' mm'], 'input'}, ...
    {'Plate size, strong direction', 'Wx', [num(p.Wx) ' mm'], ['D + strips ' sD]}, ...
    {'Plate size, weak direction', 'Wy', [num(p.Wy) ' mm'], ['B + strips ' sB]}, ...
    {'Strip beside opening, strong / weak', 'marg', [num(p.marg(1)) ' / ' num(p.marg(2)) ' mm'], 'plate_geometry'}, ...
    {'Whitmore width, strong / weak', 'b_eff', [num(p.b_eff(1)) ' / ' num(p.b_eff(2)) ' mm'], 'plate_geometry'}, ...
    {'Flange weld leg', 'leg_fl', [num(w.leg_fl) ' mm'], 'three-sided'}, ...
    {'Collar weld leg', 'leg_col', [num(w.leg_col) ' mm'], ''}, ...
    {'Collar weld lines, cap / shelf', 'n_cap, n_shf', [num(w.n_cap) ' / ' num(w.n_shf)], '1 = one face, 2 = both faces'}};
  seat = { ...
    {'e_react, reaction eccentricity', [num(st.e_react) ' mm'], eh}, ...
    {'share, part of V on the shelf', sprintf('%.2f', st.share), '1.0 shelf alone, 0.5 both plates'}, ...
    {'bending width (wmode)', wm{st.wmode}, 'same width for S4 and S8'}, ...
    {'ribs under the shelf', rib, ''}};
  T = { {'Plates and welds', {'Item','Symbol','Value','How it is obtained'}, plates}, ...
        {'Seat switches', {'Switch','Value used','Note'}, seat} };
end

% ---------------------------------------------------------------------
%  formatting
% ---------------------------------------------------------------------
function s = num(x)
  if abs(x - round(x)) < 1e-9, s = sprintf('%d', round(x));
  elseif abs(x) >= 100,        s = sprintf('%.1f', x);
  else,                        s = sprintf('%.4g', x);
  end
end

function s = val(v, unit)
  switch unit
    case 'F', s = sprintf('%.1f kN', v/1e3);
    case 'M', s = sprintf('%.3f kNm', v/1e6);
    case 'S', s = sprintf('%.1f MPa', v);
    case 'L', s = sprintf('%.2f mm', v);
    otherwise, s = sprintf('%.3f', v);
  end
end

function s = dcrtxt(d)
  if isempty(d), s = '-'; else, s = sprintf('%.2f', d); end
end

function s = subtxt(info)
  if numel(info) >= 8 && ~isempty(info{8}), s = info{8}; else, s = '-'; end
end

% Blocks (blk_*) for joint_pdf.py: lib/sheets.
