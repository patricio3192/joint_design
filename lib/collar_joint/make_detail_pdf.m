function file = make_detail_pdf(DB, M, J, C, outdir, opts)
% MAKE_DETAIL_PDF  Collar detailing sheets: key plan, plate types, one
% plan per joint, and a section of each connection type.
%
%   make_detail_pdf(DB, M, default_joint(), C, 'reports')
%
% DB  joint database (load_joint_db), M  parsed model (joint_db/etabs_model.mat)
% J   collar detail from dmj_lib default_joint (sizes, welds, shear tab)
% C   the project's joint classes (see README.md)
% opts.python  Python command (default 'python3')
% opts.stab    stability plates on the cap for S beams, [t L depth clear] mm
%              (default [8 60 25 3]); drawn, not checked
%
% All geometry is computed here from J and the joint classes
% (C, joint_config.m, collar_types.m); joint_pdf.py only
% draws it.  Writes <outdir>/collar_details.json and .pdf.

  if nargin < 6, opts = struct(); end
  if ~iscell(C), error('make_detail_pdf: give the joint classes C.'); end
  if ~isfield(opts, 'python'), opts.python = 'python3'; end
  if ~isfield(opts, 'stab'),   opts.stab   = [8 60 25 3]; end
  if ~exist(outdir, 'dir'), mkdir(outdir); end
  here = fileparts(mfilename('fullpath'));

  T = collar_types(DB, J, C);
  tstyle = {'plate', 'plate2', 'plate3'};
  typeOf = containers.Map();
  for t = 1:numel(T)
    for k = 1:numel(T(t).joints), typeOf(T(t).joints{k}) = t; end
  end

  B = {blk_h(1, 'Collar details - double collar moment joints'), ...
       blk_p(sprintf(['Plates %g mm (cap) and %g mm (shelf), A36. Strip beyond the column: ' ...
       '%g mm where a beam laps (L_lap %g + gap %g), %g mm at the building edge. ' ...
       'Joint classes from the project; beams on each side from the ETABS model. ' ...
       'Sides are global: W = -X, N = +Y, E = +X, S = -Y.'], J.pl.t_cap, J.pl.t_shf, ...
       J.pl.L_lap + J.st.gap, J.pl.L_lap, J.st.gap, J.pl.w_back))};

  % ---- key plan and schedule
  B = [B, {blk_h(2, 'Key plan'), blk_draw(key_plan(DB, M, J, C, typeOf, tstyle), 150, ...
       ['Plates coloured by type. Beam ends: red M (moment, lapped on cap and shelf), ' ...
        'green S (shear, on the shelf), orange dashed NL (below the collar, shear tab), ' ...
        'grey dotted E (edge, 30 mm strip).'])}];
  rows = {};
  for k = 1:size(C, 1)
    jt = DB.joints(strcmp({DB.joints.joint}, C{k,1}));
    if isempty(jt), continue; end
    [map, Jj] = joint_config(jt, J, C);
    t = typeOf(jt.joint);
    rows{end+1} = {jt.joint, sprintf('%d', map.col), map.strongAxis, strjoin(C(k,2:5), ' '), ...
                   T(t).name, placement(Jj.pl.over, map.strongAxis, J), ...
                   frames(map.shear), frames(map.nl)};
  end
  B = [B, {blk_page(), blk_h(2, 'Joint schedule'), ...
           blk_table({'Joint','Column','Strong axis','W N E S','Plate','Placement', ...
                      'S beams (shelf)','NL beams (tab)'}, rows, ...
                     [0.07 0.08 0.09 0.13 0.07 0.3 0.13 0.13], {}, {}), ...
           blk_note(['Strong axis: global axis of the column''s 200 mm side, where its strong ' ...
                     'beams run. Placement: how the plate outline sits on plan.'])}];

  % ---- plate types
  B = [B, {blk_h(2, 'Plate types')}];
  for t = 1:numel(T)
    n = numel(T(t).joints);
    B = [B, {blk_h(3, sprintf(['Type %s: PL %g x %g, opening %g x %g, cap %g mm and shelf %g mm, ' ...
             '%d joints, %d plates'], T(t).name, T(t).LD, T(t).LB, J.cl.D, J.cl.B, ...
             T(t).t(1), T(t).t(2), n, 2*n)), ...
             blk_draw(type_drawing(T(t), J, tstyle{min(t,3)}), 70, ...
             sprintf(['Joints %s. The opening is the column outline; the fabricator adds ' ...
                      'the fit-up clearance.'], strjoin(T(t).joints, ', ')))}];
  end

  % ---- connection sections
  B = [B, {blk_page(), blk_h(2, 'Connection types, section along the beam'), ...
           blk_h(3, 'M - moment beam: both flanges lapped and welded to the cap and the shelf'), ...
           blk_draw(section_moment(J), 80, ''), ...
           blk_h(3, 'S - shear only: on the shelf, top flange free under the cap'), ...
           blk_draw(section_shear(J, opts.stab), 80, ''), ...
           blk_page(), ...
           blk_h(3, 'NL - beam below the collar: shear tab welded to the column wall, bolted to the web'), ...
           blk_draw(section_tab(J), 100, ''), ...
           blk_note(sprintf(['Shear tab: PL %g, %d M%g bolts in %g mm holes, pitch %g, edge %g ' ...
             '(vertical) and %g (horizontal), bolt line %g mm from the wall, beam end %g mm ' ...
             'from the wall, %g mm fillets both sides. Checked as P1 to P11 in dmj_lib.'], ...
             J.nl.tp, J.nl.nb, J.nl.db, J.nl.dh, J.nl.s, J.nl.Lev, J.nl.Leh, J.nl.ea, ...
             J.nl.gap, J.nl.leg))}];

  % ---- one plan per joint, two per page
  B = [B, {blk_page(), blk_h(2, 'Joint plans (cap level, seen from above)')}];
  for k = 1:size(C, 1)
    jt = DB.joints(strcmp({DB.joints.joint}, C{k,1}));
    if isempty(jt), continue; end
    [map, Jj] = joint_config(jt, J, C);
    t = typeOf(jt.joint);
    if k > 1 && mod(k, 2) == 1, B = [B, {blk_page()}]; end
    B = [B, {blk_h(3, sprintf('Joint %s - type %s - class %s - column %d, strong axis %s', ...
             jt.joint, T(t).name, strjoin(C(k,2:5), ' '), map.col, map.strongAxis)), ...
             blk_draw(joint_plan(map, Jj, tstyle{min(t,3)}, opts.stab), 105, ...
             ['Cap shown; beam parts under the cap dashed. Red: welds (flange 3-sided, ' ...
              'collar around the column). Green: stability plates. Orange: shear tab.'])}];
  end

  doc = struct('title', 'Collar details', 'blocks', {B});
  base = fullfile(outdir, 'collar_details');
  fid = fopen([base '.json'], 'w');
  if fid < 0, error('Cannot write %s.json', base); end
  fprintf(fid, '%s', jsonencode(doc));
  fclose(fid);
  [st, out] = system(sprintf('%s "%s" "%s.json" "%s.pdf"', opts.python, ...
                     fullfile(here, '..', 'printing', 'joint_pdf.py'), base, base));
  fprintf('%s', out);
  if st ~= 0, error('PDF generation failed (see the message above).'); end
  file = [base '.pdf'];
end

% =====================================================================
%  Geometry helpers.  Plan: x = global X, y = global Y, origin at the
%  column centre, mm.
% =====================================================================

% half sizes of the column on plan, and the plate box [x0 x1 y0 y1]
function [hx, hy, box] = plan_box(over, axis, c)
  if strcmp(axis, 'Y'), hx = c.B/2; hy = c.D/2; else, hx = c.D/2; hy = c.B/2; end
  box = [-hx - over(1), hx + over(3), -hy - over(4), hy + over(2)];
end

% a rectangle in beam coordinates: r along the side direction d from the
% column centre, u across it
function it = side_rect(d, r0, r1, u0, u1, s)
  n = [-d(2) d(1)];
  P = [r0*d + u0*n; r1*d + u0*n; r1*d + u1*n; r0*d + u1*n];
  it = d_poly(P, s);
end

function it = side_line(d, r0, u0, r1, u1, s)
  n = [-d(2) d(1)];
  a = r0*d + u0*n;  b = r1*d + u1*n;
  it = d_line(a(1), a(2), b(1), b(2), s);
end

function s = placement(over, axis, J)
  side = {'W', 'N', 'E', 'S'};
  if strcmp(axis, 'Y'), s = 'long side along Y'; else, s = 'long side along X'; end
  short = find(over < J.pl.L_lap + J.st.gap);
  for i = short
    s = [s sprintf(', %g mm strip to %s', over(i), side{i})];
  end
end

function s = frames(f)
  if isempty(f), s = '-'; else, s = strjoin(arrayfun(@num2str, f, 'UniformOutput', false), ', '); end
end

% =====================================================================
%  Key plan: whole floor, true scale
% =====================================================================
function it = key_plan(DB, M, J, C, typeOf, tstyle)
  it = {};
  kb = find(strcmp(M.fr.type, 'Beam'));
  for i = kb.'
    a = 1000*M.pt.xyz(strcmp(M.pt.name, M.fr.ptI{i}), 1:2);
    b = 1000*M.pt.xyz(strcmp(M.pt.name, M.fr.ptJ{i}), 1:2);
    it{end+1} = d_line(a(1), a(2), b(1), b(2), 'grid');
  end
  dirs = [-1 0; 0 1; 1 0; 0 -1];
  for k = 1:size(C, 1)
    jt = DB.joints(strcmp({DB.joints.joint}, C{k,1}));
    if isempty(jt), continue; end
    [map, Jj] = joint_config(jt, J, C);
    p0 = 1000*jt.xyz(1:2);
    [hx, hy, bx] = plan_box(Jj.pl.over, map.strongAxis, J.cl);
    it{end+1} = d_rectxy(p0(1)+bx(1), p0(2)+bx(3), p0(1)+bx(2), p0(2)+bx(4), tstyle{min(typeOf(jt.joint),3)});
    it{end+1} = d_rectxy(p0(1)-hx, p0(2)-hy, p0(1)+hx, p0(2)+hy, 'column');
    face = [hx hy hx hy];
    for s = 1:4
      code = map.sides{s};  d = dirs(s,:);
      r0 = face(s) + Jj.pl.over(s);
      switch code
        case 'M',  st = 'codeM';
        case 'S',  st = 'codeS';
        case 'NL', st = 'codeNL';
        case 'E',  st = 'codeE';
        otherwise, continue
      end
      a = p0 + r0*d;  b = p0 + (r0 + 450)*d;
      it{end+1} = d_line(a(1), a(2), b(1), b(2), st);
    end
    it{end+1} = d_text(p0(1) + bx(2) + 60, p0(2) + bx(4) + 60, jt.joint, 'code', 'start');
  end
  % north arrow
  xs = cellfun(@(q) max(q.p(1:2:end)), it);  ys = cellfun(@(q) max(q.p(2:2:end)), it);
  ax = max(xs) + 900;  ay = max(ys) - 1200;
  it{end+1} = d_poly([ax-180 ay; ax ay+700; ax+180 ay], 'arrow');
  it{end+1} = d_text(ax, ay+800, 'N', 'title', 'middle');
end

% =====================================================================
%  Plate type: the plate itself, fabrication dimensions
% =====================================================================
function it = type_drawing(T, J, style)
  D = J.cl.D;  Bc = J.cl.B;
  a = T.oD(1);  b = T.oB(1);            % larger strips left and bottom
  it = {d_rectxy(0, 0, T.LD, T.LB, style), d_rectxy(a, b, a + D, b + Bc, 'void'), ...
        d_line(a + D/2, -25, a + D/2, T.LB + 25, 'center'), ...
        d_line(-25, b + Bc/2, T.LD + 25, b + Bc/2, 'center')};
  it{end+1} = d_dim(0, 0, a, 0, -30, dim_t(a));
  it{end+1} = d_dim(a, 0, a + D, 0, -30, dim_t(D));
  it{end+1} = d_dim(a + D, 0, T.LD, 0, -30, dim_t(T.LD - a - D));
  it{end+1} = d_dim(0, 0, T.LD, 0, -60, dim_t(T.LD));
  it{end+1} = d_dim(0, 0, 0, b, 30, dim_t(b));
  it{end+1} = d_dim(0, b, 0, b + Bc, 30, dim_t(Bc));
  it{end+1} = d_dim(0, b + Bc, 0, T.LB, 30, dim_t(T.LB - b - Bc));
  it{end+1} = d_dim(0, 0, 0, T.LB, 60, dim_t(T.LB));
  it{end+1} = d_text(a + D/4, b + Bc/2 - 14, sprintf('opening %g x %g', D, Bc), 'small', 'middle');
  it{end+1} = d_text(T.LD + 40, T.LB/2 + 20, sprintf('Type %s', T.name), 'title', 'start');
  it{end+1} = d_text(T.LD + 40, T.LB/2 - 5, sprintf('PL %g (cap), %g (shelf)', T.t(1), T.t(2)), 'label', 'start');
  it{end+1} = d_text(T.LD + 40, T.LB/2 - 25, sprintf('%d off', 2*numel(T.joints)), 'label', 'start');
end

% =====================================================================
%  Joint plan
% =====================================================================
function it = joint_plan(map, J, style, stab)
  c = J.cl;  b = J.bm;  p = J.pl;  q = J.nl;  o = p.over;
  [hx, hy, bx] = plan_box(o, map.strongAxis, c);
  dirs = [-1 0; 0 1; 1 0; 0 -1];  face = [hx hy hx hy];  ext = 170;
  side = {'W', 'N', 'E', 'S'};
  it = {};  under = {};  over_ = {};
  for s = 1:4
    code = map.sides{s};  d = dirs(s,:);  f = face(s);  pe = f + o(s);
    switch code
      case {'M', 'S'}
        it{end+1}    = side_rect(d, pe, pe + ext, -b.bf/2, b.bf/2, 'beam');
        under{end+1} = side_rect(d, f + J.st.gap, pe, -b.bf/2, b.bf/2, 'hidden');
        if strcmp(code, 'M')
          over_{end+1} = side_line(d, f + J.st.gap, -b.bf/2, pe, -b.bf/2, 'weld');
          over_{end+1} = side_line(d, f + J.st.gap,  b.bf/2, pe,  b.bf/2, 'weld');
          over_{end+1} = side_line(d, pe, -b.bf/2, pe, b.bf/2, 'weld');
        else
          u0 = b.bf/2 + stab(4);
          over_{end+1} = side_rect(d, pe - stab(2) - 10, pe - 10,  u0,  u0 + stab(1), 'stab');
          over_{end+1} = side_rect(d, pe - stab(2) - 10, pe - 10, -u0, -u0 - stab(1), 'stab');
        end
      case 'NL'
        it{end+1}    = side_rect(d, pe, pe + ext, -b.bf/2, b.bf/2, 'beam');
        under{end+1} = side_rect(d, f + q.gap, pe, -b.bf/2, b.bf/2, 'hidden');
        over_{end+1} = side_rect(d, f, f + q.ea + q.Leh, b.tw/2, b.tw/2 + q.tp, 'tabh');
        over_{end+1} = side_line(d, f + q.ea, -b.bf/2 + 8, f + q.ea, b.bf/2 - 8, 'cut');
      case 'E'
        a = pe + 12;
        if s == 1 || s == 3, it{end+1} = d_line(d(1)*a, bx(3) - 40, d(1)*a, bx(4) + 40, 'edge');
        else,                it{end+1} = d_line(bx(1) - 40, d(2)*a, bx(2) + 40, d(2)*a, 'edge'); end
    end
    % side label: just outside the beam, near its end
    switch code
      case {'M', 'S', 'NL'}, lab = sprintf('%s: %s, beam %d', side{s}, code, map.at(s)); r = pe + ext;
      case 'E', lab = sprintf('%s: edge, %g mm strip', side{s}, o(s)); r = pe + 20;
      otherwise, lab = sprintf('%s: no beam', side{s}); r = pe + 20;
    end
    switch s
      case 1, pt = [-r, b.bf/2 + 8];       a_ = 'start';
      case 3, pt = [ r, b.bf/2 + 8];       a_ = 'end';
      case 2, pt = [b.bf/2 + 8,  r - 12];  a_ = 'start';
      case 4, pt = [b.bf/2 + 8, -r + 4];   a_ = 'start';
    end
    if strcmp(code, 'N') && s == 4, pt = [b.bf/2 + 8, -r - 16]; end
    if strcmp(code, 'E') || strcmp(code, 'N')
      if s == 1, pt = [-r, bx(4) + 12]; a_ = 'end'; elseif s == 3, pt = [r, bx(4) + 12]; a_ = 'start'; end
    end
    over_{end+1} = d_text(pt(1), pt(2), lab, 'code', a_);
  end
  it{end+1} = d_rectxy(bx(1), bx(3), bx(2), bx(4), style);
  it = [it, under];
  it{end+1} = d_rectxy(-hx, -hy, hx, hy, 'column');
  it{end+1} = d_rectxy(-hx + c.t, -hy + c.t, hx - c.t, hy - c.t, 'void');
  g = 2;                                                   % collar weld all round
  it{end+1} = d_poly([-hx-g -hy-g; hx+g -hy-g; hx+g hy+g; -hx-g hy+g; -hx-g -hy-g; -hx-g -hy-g+0.01], 'weld');
  it = [it, over_];
  % dimensions: chains below and left, beyond the beams
  e = ext + 45;
  it{end+1} = d_dim(bx(1), bx(3), -hx, bx(3), -e, dim_t(o(1)), 'before');
  it{end+1} = d_dim(-hx, bx(3), hx, bx(3), -e, dim_t(2*hx));
  it{end+1} = d_dim(hx, bx(3), bx(2), bx(3), -e, dim_t(o(3)));
  it{end+1} = d_dim(bx(1), bx(3), bx(2), bx(3), -(e + 30), dim_t(bx(2) - bx(1)));
  it{end+1} = d_dim(bx(1), bx(3), bx(1), -hy, e, dim_t(o(4)), 'before');
  it{end+1} = d_dim(bx(1), -hy, bx(1), hy, e, dim_t(2*hy));
  it{end+1} = d_dim(bx(1), hy, bx(1), bx(4), e, dim_t(o(2)));
  it{end+1} = d_dim(bx(1), bx(3), bx(1), bx(4), e + 30, dim_t(bx(4) - bx(3)));
  % north arrow
  ax = bx(2) + ext + 90;  ay = bx(4) + 40;
  it{end+1} = d_poly([ax-9 ay; ax ay+35; ax+9 ay], 'arrow');
  it{end+1} = d_text(ax, ay + 42, 'N', 'title', 'middle');
end

% =====================================================================
%  Sections along a beam: x from the column face (0) toward the beam,
%  y up from the top of the shelf (0)
% =====================================================================
function it = column_cut(J, ytop, ybot)
  c = J.cl;
  it = {d_rectxy(-c.t, ybot, 0, ytop, 'column'), d_rectxy(-60, ybot, -c.t, ytop, 'void'), ...
        d_line(-60, ybot, -60, ytop, 'cut'), d_text(-32, ybot - 14, 'column wall', 'small', 'middle')};
end

function it = beam_elev(x0, x1, ybot, b, style)
  it = {d_rectxy(x0, ybot, x1, ybot + b.h, style), ...
        d_line(x0, ybot + b.tf, x1, ybot + b.tf, 'grid'), ...
        d_line(x0, ybot + b.h - b.tf, x1, ybot + b.h - b.tf, 'grid'), ...
        d_line(x1, ybot - 10, x1, ybot + b.h + 10, 'cut')};
end

function it = section_moment(J)
  b = J.bm;  p = J.pl;  g = J.st.gap;  ov = p.L_lap + g;  h = b.h;  x1 = ov + 170;
  ytop = h + p.t_cap;
  it = column_cut(J, ytop, -p.t_shf - 90);
  it = [it, beam_elev(g, x1, 0, b, 'beam')];
  it{end+1} = d_rectxy(0, -p.t_shf, ov, 0, 'plate');            % shelf
  it{end+1} = d_rectxy(0, h, ov, ytop, 'plate');                % cap
  % welds: flange edges along the lap, transverse at the plate ends, collar
  it{end+1} = d_line(g, 0, ov, 0, 'weld');
  it{end+1} = d_line(g, h, ov, h, 'weld');
  it{end+1} = d_tri(ov, h, 6, 6, 'weldf');                      % cap end on the top flange
  it{end+1} = d_tri(ov, 0, 6, -6, 'weldf');                     % shelf end under the bottom flange
  it{end+1} = d_tri(0, ytop, 5, 5, 'weldf');                    % cap to column, top face
  it{end+1} = d_tri(0, 0, 5, 5, 'weldf');                       % shelf to column
  % dimensions
  it{end+1} = d_dim(0, -p.t_shf, g, -p.t_shf, -30, dim_t(g));
  it{end+1} = d_dim(g, ytop, ov, ytop, 30, dim_t(p.L_lap));
  it{end+1} = d_dim(0, ytop, ov, ytop, 55, dim_t(ov));
  it{end+1} = d_dim(x1, 0, x1, h, -25, dim_t(h));
  it{end+1} = d_dim(x1, h, x1, ytop, -25, dim_t(p.t_cap));
  it{end+1} = d_dim(x1, -p.t_shf, x1, 0, -25, dim_t(p.t_shf));
  it{end+1} = d_dim(x1, -p.t_shf/2, x1, h + p.t_cap/2, -60, ['z = ' dim_t(h + (p.t_cap + p.t_shf)/2)]);
  xn = x1 + 75;
  it{end+1} = d_text(xn, ytop - 4, 'cap: laid on the top flange, field welded', 'label', 'start');
  it{end+1} = d_text(xn, -p.t_shf - 2, 'shelf: under the bottom flange, shop welded', 'label', 'start');
  it{end+1} = d_text(xn, h/2 + 8, sprintf('both flanges: %g mm fillets, 3-sided', J.wl.leg_fl), 'red', 'start');
  it{end+1} = d_text(xn, h/2 - 6, sprintf('(both edges over the lap + across the end)'), 'small', 'start');
  it{end+1} = d_text(-66, ytop - 4, sprintf('collar welds %g mm', J.wl.leg_col), 'red', 'end');
  it{end+1} = d_text(-66, ytop - 16, 'all round the column', 'red', 'end');
end

function it = section_shear(J, stab)
  b = J.bm;  p = J.pl;  g = J.st.gap;  ov = p.L_lap + g;  h = b.h;  x1 = ov + 170;
  ytop = h + p.t_cap;
  it = column_cut(J, ytop, -p.t_shf - 90);
  it = [it, beam_elev(g, x1, 0, b, 'beam')];
  it{end+1} = d_rectxy(0, -p.t_shf, ov, 0, 'plate');
  it{end+1} = d_rectxy(0, h, ov, ytop, 'plate');
  it{end+1} = d_rectxy(ov - stab(2) - 10, h - stab(3), ov - 10, h, 'stab');   % behind the flange
  it{end+1} = d_line(ov - stab(2) - 10, h, ov - 10, h, 'weld');
  it{end+1} = d_line(g, 0, ov, 0, 'weld');
  it{end+1} = d_tri(ov, 0, 6, -6, 'weldf');
  it{end+1} = d_tri(0, ytop, 5, 5, 'weldf');
  it{end+1} = d_tri(0, 0, 5, 5, 'weldf');
  it{end+1} = d_dim(0, -p.t_shf, g, -p.t_shf, -30, dim_t(g));
  it{end+1} = d_dim(g, ytop, ov, ytop, 30, dim_t(p.L_lap));
  it{end+1} = d_dim(ov - stab(2) - 10, ytop, ov - 10, ytop, 55, dim_t(stab(2)));
  it{end+1} = d_dim(x1, h - stab(3), x1, h, -25, dim_t(stab(3)));
  xn = x1 + 60;
  it{end+1} = d_text(xn, ytop - 4, 'top flange NOT welded to the cap: free to rotate', 'red', 'start');
  it{end+1} = d_text(xn, h - 22, sprintf('2 stability plates PL %g x %g x %g, one each side', stab(1), stab(2), stab(3)), 'label', 'start');
  it{end+1} = d_text(xn, h - 34, sprintf('of the flange, welded to the cap only, %g mm clear', stab(4)), 'label', 'start');
  it{end+1} = d_text(xn, -p.t_shf - 2, sprintf('bottom flange: %g mm fillets, 3-sided, to the shelf', J.wl.leg_fl), 'red', 'start');
  it{end+1} = d_text(xn, h/2, 'reaction by bearing on the shelf', 'small', 'start');
end

function it = section_tab(J)
  b = J.bm;  p = J.pl;  q = J.nl;  h = b.h;  ov = p.L_lap + J.st.gap;
  clr = 20;                                      % below the shelf
  yb  = -p.t_shf - clr - h;                      % bottom of the NL beam
  x1  = ov + 170;
  hp  = 2*q.Lev + (q.nb - 1)*q.s;
  yc  = yb + h/2;                                % tab centred on the web
  ytop = h + p.t_cap;
  it = column_cut(J, ytop, yb - 40);
  it{end+1} = d_rectxy(0, -p.t_shf, ov, 0, 'plate');
  it{end+1} = d_rectxy(0, h, ov, ytop, 'plate');
  it{end+1} = d_text(ov/2, ytop + 8, 'cap (moment beams on the other sides)', 'small', 'middle');
  it{end+1} = d_text(ov + 8, -p.t_shf/2 - 3, 'shelf', 'label', 'start');
  it = [it, beam_elev(q.gap, x1, yb, b, 'beam')];
  it{end+1} = d_rectxy(0, yc - hp/2, q.ea + q.Leh, yc + hp/2, 'tab');
  it{end+1} = d_line(0, yc - hp/2, 0, yc + hp/2, 'weld');
  for i = 1:q.nb
    yb_ = yc + hp/2 - q.Lev - (i-1)*q.s;
    it{end+1} = d_circle(q.ea, yb_, q.dh/2, 'bolt');
  end
  yt = yc + hp/2;  y0 = yc - hp/2;
  it{end+1} = d_dim(0, y0, q.gap, y0, -(y0 - yb) - 20, dim_t(q.gap));
  it{end+1} = d_dim(0, y0, q.ea, y0, -(y0 - yb) - 45, dim_t(q.ea));
  it{end+1} = d_dim(q.ea, y0, q.ea + q.Leh, y0, -(y0 - yb) - 45, dim_t(q.Leh));
  it{end+1} = d_dim(q.ea + q.Leh, yt, q.ea + q.Leh, yt - q.Lev, -25, dim_t(q.Lev));
  if q.nb > 1
    it{end+1} = d_dim(q.ea + q.Leh, yt - q.Lev, q.ea + q.Leh, yt - q.Lev - (q.nb-1)*q.s, -25, dim_t((q.nb-1)*q.s));
  end
  it{end+1} = d_dim(q.ea + q.Leh, y0, q.ea + q.Leh, y0 + q.Lev, -25, dim_t(q.Lev));
  it{end+1} = d_dim(x1, yb, x1, yb + h, -25, dim_t(h));
  it{end+1} = d_dim(x1, yb + h, x1, -p.t_shf, -25, dim_t(clr));
  xn = x1 + 60;
  it{end+1} = d_text(xn, yc + 8, sprintf('shear tab PL %g x %g x %g, %d M%g', q.tp, q.ea + q.Leh, hp, q.nb, q.db), 'label', 'start');
  it{end+1} = d_text(xn, yc - 6, sprintf('%g mm fillets both sides to the column wall', q.leg), 'red', 'start');
  it{end+1} = d_text(xn, yb + 4, 'bottom flange free', 'small', 'start');
  it{end+1} = d_text(x1 - 10, yb + h + 8, 'top flange clear of the shelf', 'small', 'end');
end

% ---------------------------------------------------------------------
%  drawing items and blocks (see joint_pdf.py)
% ---------------------------------------------------------------------
function s = dim_t(v)
  if abs(v - round(v)) < 1e-6, s = sprintf('%d', round(v)); else, s = sprintf('%.1f', v); end
end

function it = d_poly(P, s)
  it = struct('t', 'poly', 'p', reshape(P.', 1, []), 's', s);
end

function it = d_rectxy(x0, y0, x1, y1, s)
  it = d_poly([x0 y0; x1 y0; x1 y1; x0 y1], s);
end

function it = d_tri(x, y, sx, sy, s)
  it = d_poly([x y; x + sx y; x y + sy], s);
end

function it = d_line(x0, y0, x1, y1, s)
  it = struct('t', 'line', 'p', [x0 y0 x1 y1], 's', s);
end

function it = d_circle(x, y, r, s)
  it = struct('t', 'circle', 'p', [x y r], 's', s);
end

function it = d_text(x, y, txt, s, a)
  it = struct('t', 'text', 'p', [x y], 'txt', txt, 's', s, 'a', a);
end

% pos: where the text goes when it does not fit between the ticks,
% 'after' (past the second point, default) or 'before' (before the first)
function it = d_dim(x0, y0, x1, y1, off, txt, pos)
  if nargin < 7, pos = 'after'; end
  it = struct('t', 'dim', 'p', [x0 y0 x1 y1], 'o', off, 'txt', txt, 'pos', pos);
end

function b = blk_draw(items, h, cap)
  b = struct('k', 'drawing', 'items', {items}, 'h', h, 'cap', cap);
end

function b = blk_h(level, text)
  b = struct('k', sprintf('h%d', level), 't', text);
end

function b = blk_p(text)
  b = struct('k', 'p', 't', text);
end

function b = blk_note(text)
  b = struct('k', 'note', 't', text);
end

function b = blk_page()
  b = struct('k', 'page');
end

function b = blk_table(head, rows, widths, right, red)
  b = struct('k', 'table', 'head', {head}, 'rows', {rows}, 'w', widths, ...
             'right', {right}, 'red', {red});
end
