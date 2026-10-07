function F = ca_draw(P, R)
% CA_DRAW  Drawings of the cantilever anchorage as SVG text, revision 3 (variant).
%   F = ca_draw(P, R) returns one field per figure. All the geometry comes
%   from P (ca_inputs) and R (ca_calc), so drawings and numbers cannot differ.
%   Drawing units are mm; z = 0 is the top of the concrete beam and of the steel.
F.trib       = fig_trib(P, R);
F.assy_elev  = fig_assy_elev(P, R);
F.assy_plan  = fig_assy_plan(P, R);
F.edge_plan  = fig_plan(P, R, 'edge');
F.edge_elev  = fig_elev(P, R, 'edge', 'A');
F.edge_front = fig_front(P, R);
F.cor_plan   = fig_plan(P, R, 'corner');
F.cor_elevX  = fig_elev(P, R, 'corner', 'A');
F.cor_elevY  = fig_elev(P, R, 'corner', 'B');
F.flow       = fig_flow(P, R);
F.path       = fig_path(P, R);
F.plate_face = fig_plate_face(P, R);
F.plate_mod  = fig_plate_models(P, R);
F.cones      = fig_cones(P, R);
F.dev_edge   = fig_devel(P, R, 1);
F.dev_cor    = fig_devel(P, R, 3);
F.tol        = fig_tol(P, R);
F.ins        = fig_ins(P, R);
F.hoops      = fig_hoops(P, R);
F.tie        = fig_tie(P);
end

% ===========================================================================
%  figures
% ===========================================================================
function [rows, nm] = anchor_rows(P, R, kase, typ)
% anchor rows of one assembly: [z |v|]; edge E, corner C1 (typ A), C2 (typ B)
if strcmp(kase, 'edge'), rows = R.anE;  nm = 'E';
elseif typ == 'A',       rows = R.anC1; nm = 'C1';
else,                    rows = R.anC2; nm = 'C2';
end
end

% ---------------------------------------------------------------------------
function c = draw_platina_elev(c, P, R, gx)
% platina in a section along the beam, with its fillets to the plate
zf = R.zf;  t = P.pla.t;  u1 = P.pl.t;  u2 = P.pl.t + P.pla.L;  w = P.w.pla;
c = cv_rect(c, gx(u1), zf-t/2, gx(u2), zf+t/2, 'plate');
c = cv_poly(c, gx([u1 u1+w u1]), [zf+t/2 zf+t/2 zf+t/2+w], 'weldfill');
c = cv_poly(c, gx([u1 u1+w u1]), [zf-t/2 zf-t/2 zf-t/2-w], 'weldfill');
end

% ---------------------------------------------------------------------------
function svg = fig_elev(P, R, kase, typ)
% Section along the axis of the steel beam. Edge: type E, bars over and under
% the platinas. Corner: typ 'A' beam X with type C1 (bars under), typ 'B' beam
% Y with type C2 (bars over).
hb = P.col.b/2;  bm = P.bm;  gx = @(u) u - hb;  db = P.anc.db;
ti = 1 + (typ == 'B');  tj = 3 - ti;  edge = strcmp(kase, 'edge');
[rows, nm] = anchor_rows(P, R, kase, typ);
ztop = P.col.top;  zcj = P.col.cj;  xL = -640;  xR = 760;  zB = -520;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
xh = hb - P.col.cover - P.col.dtie/2;
c = cv_new(-780, 900, -600, 330, 0.62);

% concrete and slab
c = cv_rect(c, xL, 0, -hb, P.slab.t, 'slab');
c = cv_rect(c, hb, 0, xR, P.slab.t, 'slab');
c = cv_rect(c, -hb, zB, hb, zcj, 'old');
c = cv_rect(c, -hb, zcj, hb, ztop, 'conc');
c = cv_rect(c, hb, -P.cb.h, xR, 0, 'conc');
c = cv_rect(c, -P.cb.b/2, -P.cb.h, P.cb.b/2, 0, 'hid');
c = cv_seg(c, [-hb-45 hb+45], [zcj zcj], 'cj');
for x = hb+110 : P.cb.sst : xR-20
    c = cv_seg(c, [x x], [-P.cb.h+45, -45], 'stir');
end

% steel beam, embed plate, platina
c = cv_rect(c, xL, -bm.h+bm.tf, -hb, -bm.tf, 'web');
c = cv_rect(c, xL, -bm.tf, -hb, 0, 'steel');
c = cv_rect(c, xL, -bm.h, -hb, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -hb, P.pl.zb, gx(P.pl.t), P.pl.zt, 'plate');
c = draw_platina_elev(c, P, R, gx);

% column bars, with the hooks required at the top
zc = ztop - P.col.cover - P.col.db/2;
c = cv_bar(c, [-xc -xc], [zB zc-20], P.col.db, 'col');
c = cv_bar(c, [ xc  xc], [zB zc-36], P.col.db, 'col');
[x, z] = hook(zB, zc+P.col.db/2, 0, P.col.db, 1);
c = cv_bar(c, -xc + z(2:end), x(2:end) - 20, P.col.db, 'colh');
c = cv_bar(c,  xc - z(2:end), x(2:end) - 36, P.col.db, 'colh');

% ties
for z = [P.hoop.z P.hoop.ztop]
    c = cv_seg(c, [-xh xh], [z z], 'hoop');
    c = cv_circ(c, -xh, z, P.hoop.db, 'hoop');
    c = cv_circ(c,  xh, z, P.hoop.db, 'hoop');
end

% bars of the concrete beam in line (drawn: the VCM, with its stacked bars, is the
% beam in line with X; at the corner the VCS in line with Y passes under it)
zt = P.cb.zt(ti);  zb = P.cb.zb(ti);  vcm = (typ == 'A');
c = cv_bar(c, [xR gx(P.cb.uh+10)], [zb zb], P.cb.db, 'ex');
[x, z] = hook(xR, gx(P.cb.uh), zt, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'ex');
if vcm
    c = cv_bar(c, [xR gx(P.cb.uh2+10)], (zb + P.cb.dz)*[1 1], P.cb.db, 'ex');
    [x, z] = hook(xR, gx(P.cb.uh2), zt - P.cb.dz, P.cb.db, -1);
    c = cv_bar(c, x, z, P.cb.db, 'ex');
end
for x = [-1 1]*P.rod.p
    c = cv_bar(c, [x x], [zB ztop+60], P.rod.db, 'rod');
end
% bars that cross the section
for v = P.cb.v
    c = cv_circ(c, v, P.cb.zt(tj), P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zb(tj), P.cb.db, 'ex');
end
if ~edge && ~vcm                                    % the crossing beam is the VCM
    for v = P.cb.vm
        c = cv_circ(c, v, P.cb.zt(tj) - P.cb.dz, P.cb.db, 'ex');
        c = cv_circ(c, v, P.cb.zb(tj) + P.cb.dz, P.cb.db, 'ex');
    end
end
if ~edge
    if typ == 'A', ro = R.anC2; else, ro = R.anC1; end
    for j = 1:size(ro,1)
        for v = ro(j,2)*[-1 1]
            c = cv_circ(c, v, ro(j,1), db, 'anc');
        end
    end
end

% anchor bars: in this section the rows lie one behind the other
for j = size(rows,1):-1:1
    [x, z] = hook(gx(P.anc.u0), gx(P.anc.uh), rows(j,1), db, -1);
    st = 'anc';  if j == 2 && edge, st = 'anch'; end
    c = cv_bar(c, x, z, db, st);
end
for j = 1:size(rows,1)
    c = cv_seg(c, gx(P.pl.t + P.pla.L - [P.anc.Lw 0]), (R.zf + sign(rows(j,1) - R.zf)*(P.pla.t/2 + 2))*[1 1], 'wside');
end

% dimensions
u2 = P.pl.t + P.pla.L;
c = cv_dim(c, -hb, ztop, gx(P.pl.t), ztop, 45, sprintf('%g', P.pl.t), -14);
c = cv_dim(c, gx(P.pl.t), ztop, gx(u2), ztop, 45);
c = cv_dim(c, gx(u2), ztop, gx(P.anc.uh), ztop, 45);
c = cv_dim(c, gx(P.anc.uh), ztop, hb, ztop, 45);
c = cv_dim(c, -hb, ztop, gx(P.anc.u0), ztop, 100, sprintf('%g', P.anc.u0), -12);
c = cv_dim(c, gx(P.anc.u0), ztop, gx(P.anc.uh), ztop, 100);
c = cv_dim(c, -hb, ztop, hb, ztop, 155);
c = cv_dim(c, xR, -P.cb.h, xR, 0, -35);
c = cv_dim(c, xR, 0, xR, P.slab.t, -35);
c = cv_dim(c, xR, 0, xR, ztop, -80, sprintf('%g  (pedestal)', ztop));
c = cv_dim(c, xL, P.pl.zb, xL, -bm.h, 35);
c = cv_dim(c, xL, -bm.h, xL, 0, 35);
c = cv_dim(c, xL, 0, xL, P.pl.zt, 35);
c = cv_dim(c, xL, R.zC, xL, R.zf, 85, sprintf('%g  (lever arm)', R.ho));
zz = [zcj sort(P.hoop.z) 0];
for i = 1:numel(zz)-1
    c = cv_dim(c, hb, zz(i), hb, zz(i+1), -45);
end
c = cv_dim(c, 95, zcj, 95, min(R.dev.zend), 1);

% labels
c = cv_lead(c, gx(P.pl.t/2), -215, -330, -300, sprintf('Embed plate PL %gx%gx%g', P.pl.t, P.pl.w, P.pl.zt-P.pl.zb));
c = cv_lead(c, gx(P.pl.t+P.pla.L/2), R.zf+6, -300, 205, {sprintf('2 platinas PL %gx%gx%g', P.pla.t, P.pla.w, P.pla.L), 'behind the top flange: tension + shear lug'});
if edge
    s1 = {sprintf('4 %s%g: 2 over the platinas (|v| = %g)', '&#216;', db, P.anc.vO), sprintf('+ 2 under them (|v| = %g), hooks at %g', P.anc.vU, P.anc.uh)};
elseif typ == 'A'
    s1 = {sprintf('C1: 4 %s%g welded under the platinas', '&#216;', db), sprintf('axis %+.1f, tail 12 db = %g', rows(1,1), R.dev.tail)};
else
    s1 = {sprintf('C2: 4 %s%g welded over the platinas', '&#216;', db), sprintf('axis %+.1f, tail 12 db = %g', rows(1,1), R.dev.tail)};
end
c = cv_lead(c, 40, rows(1,1), 250, 290, s1);
c = cv_lead(c, gx(u2-20), rows(1,1) - sign(rows(1,1) - R.zf)*8, -330, 150, {sprintf('side welds %g x %g, both sides of each bar', P.w.bar, P.anc.Lw), 'the bars do not touch the plate'});
c = cv_lead(c, P.rod.p, 70, 470, 225, sprintf('rods of the steel column: 4 %s%g, 180%s hooks', '&#216;', P.rod.db, '&#176;'));
if vcm, st = {sprintf('VCM: 5 %s%g top, hooked down;', '&#216;', P.cb.db), '2 of them under the corner bars'};
else,   st = sprintf('VCS: 3 %s%g top bars, hooked down', '&#216;', P.cb.db); end
c = cv_lead(c, 640, zt+4, 660, 165, st);
c = cv_lead(c, -xh, P.hoop.z(end), -330, -400, {sprintf('%d layers of 4 straight ties %s%g', numel(P.hoop.z), '&#216;', P.hoop.db), 'plus one closed tie above the anchors'});
c = cv_lead(c, -40, zc-20, -330, 265, 'Column bars: 90&#176; hooks at the top');
if ~edge
    c = cv_lead(c, ro(end,2), ro(1,1), 250, 245, sprintf('4 %s%g anchors of the other beam, in section', '&#216;', db));
end
c = cv_text(c, hb+55, zcj-18, 'cold joint: column cast earlier', 'start');
c = cv_text(c, -450, -125, bm.name, 'middle');
c = cv_text(c, 580, -185, sprintf('Concrete beam %gx%g', P.cb.b/10, P.cb.h/10), 'middle');
c = cv_text(c, 0, -470, 'Hardened pedestal', 'middle');
c = cv_text(c, -450, 62, sprintf('Composite slab %g', P.slab.t), 'middle');
c = cv_text(c, xR+95, -4, '&#177;0', 'start');
c = cv_text(c, -760, -570, sprintf('Type %s', nm), 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_front(P, R)
% Edge column seen from outside, looking along the steel beam
hb = P.col.b/2;  bm = P.bm;  db = P.anc.db;
ztop = P.col.top;  zcj = P.col.cj;  yE = 540;  zB = -520;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
xh = hb - P.col.cover - P.col.dtie/2;
c = cv_new(-760, 760, -660, 330, 0.62);

c = cv_rect(c, -yE, 0, -hb, P.slab.t, 'slab');
c = cv_rect(c, hb, 0, yE, P.slab.t, 'slab');
c = cv_rect(c, -yE, -P.cb.h, -hb, 0, 'conc');
c = cv_rect(c, hb, -P.cb.h, yE, 0, 'conc');
c = cv_rect(c, -hb, zB, hb, zcj, 'old');
c = cv_rect(c, -hb, zcj, hb, ztop, 'conc');
c = cv_seg(c, [-hb-45 hb+45], [zcj zcj], 'cj');

% bars of the edge beams, column bars, ties
c = cv_bar(c, [-yE yE], P.cb.zt(2)*[1 1], P.cb.db, 'ex');
c = cv_bar(c, [-yE yE], P.cb.zb(2)*[1 1], P.cb.db, 'ex');
zc = ztop - P.col.cover - P.col.db/2;
c = cv_bar(c, [-xc -xc], [zB zc], P.col.db, 'col');
c = cv_bar(c, [ xc  xc], [zB zc], P.col.db, 'col');
c = cv_bar(c, [0 0], [zB zc], P.col.db, 'col');
for y = [-1 1]*P.rod.p, c = cv_bar(c, [y y], [zB ztop+60], P.rod.db, 'rod'); end
for z = [P.hoop.z P.hoop.ztop]
    c = cv_seg(c, [-xh xh], [z z], 'hoop');
end

% bars of the beam in line: sections and front hooks
for v = P.cb.v
    c = cv_bar(c, [v v], [P.cb.zt(1), P.cb.zt(1)-15.5*P.cb.db], P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zt(1), P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zb(1), P.cb.db, 'ex');
end
for v = P.cb.vm                                     % VCM: second bars under / over the corner bars
    c = cv_circ(c, v, P.cb.zt(1) - P.cb.dz, P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zb(1) + P.cb.dz, P.cb.db, 'ex');
end

% embed plate (translucent), beam section, hidden platinas
c = cv_rect(c, -P.pl.w/2, P.pl.zb, P.pl.w/2, P.pl.zt, 'platet');
c = cv_rect(c, -bm.b/2, -bm.tf, bm.b/2, 0, 'steel');
c = cv_rect(c, -bm.b/2, -bm.h, bm.b/2, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -bm.tw/2, -bm.h+bm.tf, bm.tw/2, -bm.tf, 'steel');
for sg = [-1 1]
    c = cv_rect(c, sg*P.pla.v0, R.zf-P.pla.t/2, sg*(P.pla.v0+P.pla.w), R.zf+P.pla.t/2, 'hidw');
end

% anchors: sections behind the plate, tails at the far side
for j = 1:size(R.anE,1)
    for v = R.anE(j,2)*[-1 1]
        c = cv_bar(c, [v v], [R.anE(j,1)-R.dev.rb, R.anE(j,1)-R.dev.rb-R.dev.tail], db, 'anch');
        c = cv_circ(c, v, R.anE(j,1), db, 'anc');
    end
end

% dimensions
vv = sort([-R.anE(:,2); R.anE(:,2)])';
for i = 1:numel(vv)-1, c = cv_dim(c, vv(i), ztop, vv(i+1), ztop, 45); end
c = cv_dim(c, -P.pla.v0, ztop, P.pla.v0, ztop, 100, sprintf('%g  (free)', 2*P.pla.v0));
c = cv_dim(c, P.pla.v0, ztop, P.pla.v0+P.pla.w, ztop, 100, sprintf('%g', P.pla.w));
c = cv_dim(c, -P.pla.v0-P.pla.w, ztop, -P.pla.v0, ztop, 100, sprintf('%g', P.pla.w));
c = cv_dim(c, -P.pl.w/2, ztop, P.pl.w/2, ztop, 155, sprintf('%g  (plate)', P.pl.w));
vb = sort([P.cb.v vv]);
for i = 1:numel(vb)-1, c = cv_dim(c, vb(i), zB, vb(i+1), zB, -40); end
c = cv_dim(c, -xc, zB, xc, zB, -80, sprintf('%g  (column bars)', 2*xc));
c = cv_dim(c, -hb, zB, hb, zB, -120);
c = cv_dim(c, yE, P.pl.zb, yE, -bm.h, -35);
c = cv_dim(c, yE, -bm.h, yE, 0, -35);
c = cv_dim(c, yE, 0, yE, P.pl.zt, -35);
c = cv_dim(c, yE, P.pl.zb, yE, P.pl.zt, -85, sprintf('%g  (plate)', P.pl.zt-P.pl.zb));
c = cv_dim(c, -yE, -P.cb.h, -yE, 0, 35);
c = cv_dim(c, -yE, 0, -yE, ztop, 35, sprintf('%g', ztop));

% labels
c = cv_lead(c, -P.anc.vO, R.anE(1,1), -330, 215, {sprintf('4 %s%g anchors: 2 over the platinas at &#177;%g', '&#216;', db, P.anc.vO), sprintf('and 2 under them at &#177;%g', P.anc.vU)});
c = cv_lead(c, P.anc.vO, -200, 330, 215, {'tails of the anchor hooks', 'at the far side of the column'});
c = cv_lead(c, 0, -300, -330, -420, {'mid-face column bar, between', 'the two platinas (8 bars in the pedestal)'});
c = cv_lead(c, P.cb.v(end), -150, 330, -420, {sprintf('VCM in line: 5 %s%g top, hooked down;', '&#216;', P.cb.db), 'the 2 extra sit under the corner bars'});
c = cv_lead(c, P.rod.p, 60, 430, 250, sprintf('rods of the steel column %s%g', '&#216;', P.rod.db));
c = cv_lead(c, 330, P.cb.zt(2), 430, 165, 'top bars of the edge beams');
c = cv_lead(c, -P.pl.w/2+8, -120, -430, 165, sprintf('Embed plate PL %gx%gx%g', P.pl.t, P.pl.w, P.pl.zt-P.pl.zb));
c = cv_lead(c, -P.pla.v0-P.pla.w/2, R.zf-P.pla.t/2, -430, 120, {'2 platinas (dashed),', 'behind the top flange'});
c = cv_text(c, -hb-50, zcj-16, 'cold joint', 'end');
c = cv_text(c, 0, -470, 'Hardened pedestal', 'middle');
c = cv_text(c, -400, -185, sprintf('Edge beam %gx%g', P.cb.b/10, P.cb.h/10), 'middle');
c = cv_text(c, 400, -185, sprintf('Edge beam %gx%g', P.cb.b/10, P.cb.h/10), 'middle');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function c = draw_assembly_plan(c, P, rows, gx, rot, ox)
% one assembly in plan: plate, 2 platinas, bars and hook tails. rot = 0: beam
% along -x (u along +x); rot = 1: beam along -y (u along +y), shifted ox in x.
db = P.anc.db;  hb = P.col.b/2;
if nargin < 6, ox = 0; end
sw = @(x, y) deal(x, y);
if rot, sw = @(x, y) deal(y + ox, x); end
for j = 1:size(rows,1)
    for v = rows(j,2)*[-1 1]
        [x, y] = sw([gx(P.anc.u0) gx(P.anc.uh)], [v v]);
        c = cv_bar(c, x, y, db, 'anc');
        [x, y] = sw(gx(P.anc.uh-db/2), v);
        c = cv_circ(c, x, y, db, 'tail');
    end
end
for sg = [-1 1]
    [x, y] = sw([gx(P.pl.t) gx(P.pl.t+P.pla.L)], sg*[P.pla.v0 P.pla.v0+P.pla.w]);
    c = cv_rect(c, x(1), y(1), x(2), y(2), 'platet');
end
[x, y] = sw([gx(0) gx(P.pl.t)], [-P.pl.w/2 P.pl.w/2]);
c = cv_rect(c, x(1), y(1), x(2), y(2), 'plate');
end

function svg = fig_plan(P, R, kase)
% Plan at the level of the anchors. Steel beam X towards -x; in the corner
% column a second steel beam Y towards -y.
hb = P.col.b/2;  bm = P.bm;  gx = @(u) u - hb;  cor = strcmp(kase, 'corner');  db = P.anc.db;
xL = -640;  xR = 780;  yT = 540;  yB = -540;
if cor, yT = 780;  yB = -640; end
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
xh = hb - P.col.cover - P.col.dtie/2;
c = cv_new(-760, 900, yB-130, yT+150, 0.56);

% concrete
c = cv_rect(c, hb, -P.cb.b/2, xR, P.cb.b/2, 'conc');
c = cv_rect(c, -P.cb.b/2, hb, P.cb.b/2, yT, 'conc');
if ~cor, c = cv_rect(c, -P.cb.b/2, yB, P.cb.b/2, -hb, 'conc'); end
c = cv_rect(c, -hb, -hb, hb, hb, 'conc');

% steel beams (top flange)
c = cv_rect(c, xL, -bm.b/2, -hb, bm.b/2, 'steel');
c = cv_seg(c, [xL -hb], [0 0], 'cl');
if cor
    c = cv_rect(c, -bm.b/2, yB, bm.b/2, -hb, 'steel');
    c = cv_seg(c, [0 0], [yB -hb], 'cl');
end

% bars of the crossing beam, then of the beam in line
for v = P.cb.v
    uh = P.cb.uh;  if v == 0, uh = P.cb.uh0; end
    if cor, c = cv_bar(c, [v v], [gx(uh+P.cb.db/2) yT], P.cb.db, 'ex');
    else,   c = cv_bar(c, [v v], [yB yT], P.cb.db, 'ex'); end
end
vb = P.cb.v;                                        % in plan the stacked VCM bars hide under the corner bars
for v = vb
    uh = P.cb.uh;  if v == 0, uh = P.cb.uh0; end    % the centre bar stops behind the mid-face column bar
    c = cv_bar(c, [gx(uh+P.cb.db/2) xR], [v v], P.cb.db, 'ex');
end

% tie, column bars, rods of the steel column
c = cv_rect(c, -xh, -xh, xh, xh, 'hoopr');
for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, c = cv_circ(c, sx*xc, sy*xc, P.col.db, 'col'); end
end, end
for sx = [-1 1], for sy = [-1 1], c = cv_circ(c, sx*P.rod.p, sy*P.rod.p, P.rod.db, 'rodc'); end, end

% assemblies
if cor
    c = draw_assembly_plan(c, P, R.anC1, gx, 0);
    c = draw_assembly_plan(c, P, R.anC2, gx, 1);
    rows = R.anC1;
else
    c = draw_assembly_plan(c, P, R.anE, gx, 0);
    rows = R.anE;
end

% dimensions
u2 = P.pl.t + P.pla.L;
c = cv_dim(c, -hb, hb, gx(P.pl.t), hb, 45, sprintf('%g', P.pl.t), -12);
c = cv_dim(c, gx(P.pl.t), hb, gx(u2), hb, 45);
c = cv_dim(c, gx(u2), hb, gx(P.anc.uh), hb, 45);
c = cv_dim(c, gx(P.anc.uh), hb, hb, hb, 45);
c = cv_dim(c, -hb, hb, hb, hb, 100);
vv = sort([-rows(:,2); rows(:,2)])';
for i = 1:numel(vv)-1, c = cv_dim(c, -hb, vv(i), -hb, vv(i+1), 60); end
c = cv_dim(c, -hb, -P.pl.w/2, -hb, P.pl.w/2, 115, sprintf('%g  (plate)', P.pl.w));
c = cv_dim(c, xR, -P.cb.b/2, xR, P.cb.b/2, -35);
c = cv_dim(c, -P.cb.b/2, yT, P.cb.b/2, yT, 35);
c = cv_dim(c, -hb, -hb, -hb, hb, 175);
if cor
    vy = sort([-R.anC2(:,2); R.anC2(:,2)])';
    for i = 1:numel(vy)-1, c = cv_dim(c, vy(i), -hb, vy(i+1), -hb, -60); end
end

% labels
c = cv_text(c, -470, 76, [bm.name ' (beam X)'], 'middle');
c = cv_lead(c, gx(P.pl.t+P.pla.L/2), -P.pla.v0-P.pla.w+6, -420, -190, {sprintf('2 platinas PL %gx%gx%g,', P.pla.t, P.pla.w, P.pla.L), 'centre free for the column bar'});
if cor, sa = {sprintf('C1: 4 %s%g under the platinas of X', '&#216;', db), 'dots: hook tails going down'};
else,   sa = {sprintf('4 %s%g: 2 over (|v| = %g) + 2 under (|v| = %g)', '&#216;', db, P.anc.vO, P.anc.vU), 'dots: hook tails going down'}; end
c = cv_lead(c, gx(P.anc.uh-db/2), rows(end,2), 240, 330, sa);
c = cv_lead(c, 640, vb(end), 680, 235, sprintf('%d %s%g top bars', numel(vb), '&#216;', P.cb.db));
c = cv_lead(c, P.rod.p, -P.rod.p, 560, -250, {sprintf('4 rods %s%g of the', '&#216;', P.rod.db), 'steel column base plate'});
c = cv_lead(c, xh, -xh+40, 330, -200, sprintf('ties %s%g', '&#216;', P.hoop.db));
c = cv_lead(c, xc, -xc, 300, -330, sprintf('column 8 %s%g', '&#216;', P.col.db));
c = cv_lead(c, -xc, 0, -330, 420, {'mid-face column bar', 'passes between the platinas'});
if cor
    c = cv_text(c, 62, -470, [bm.name ' (beam Y)'], 'start');
    c = cv_lead(c, R.anC2(1,2), 60, -420, 330, {sprintf('C2: 4 %s%g over the platinas of Y,', '&#216;', db), sprintf('%g mm above the bars of X', R.clr{4,2})});
    c = cv_text(c, 170, yT-40, 'Concrete beam (in line with Y)', 'start');
else
    c = cv_text(c, 170, yT-40, 'Edge beam', 'start');
    c = cv_text(c, 170, yB+30, 'Edge beam', 'start');
end
c = cv_text(c, 560, -185, 'Concrete beam (in line with X)', 'middle');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_assy_elev(P, R)
% Shop assembly type E, side view. u = 0 at the outer face of the embed plate.
bm = P.bm;  db = P.anc.db;  uL = -170;  zf = R.zf;  u2 = P.pl.t + P.pla.L;
c = cv_new(-330, 600, -430, 150, 1.0);
c = cv_rect(c, uL, -bm.h+bm.tf, 0, -bm.tf, 'web');
c = cv_rect(c, uL, -bm.tf, 0, 0, 'steel');
c = cv_rect(c, uL, -bm.h, 0, -bm.h+bm.tf, 'steel');
c = cv_rect(c, 0, P.pl.zb, P.pl.t, P.pl.zt, 'plate');
c = draw_platina_elev(c, P, R, @(u) u);
for j = size(R.anE,1):-1:1
    [x, z] = hook(P.anc.u0, P.anc.uh, R.anE(j,1), db, -1);
    st = 'anc';  if j == 2, st = 'anch'; end
    c = cv_bar(c, x, z, db, st);
end
c = cv_seg(c, u2 - [P.anc.Lw 0], (zf + P.pla.t/2 + 2)*[1 1], 'wside');
c = cv_seg(c, u2 - [P.anc.Lw 0], (zf - P.pla.t/2 - 2)*[1 1], 'wside');

c = cv_dim(c, 0, P.pl.zb, P.pl.t, P.pl.zb, -75, sprintf('%g', P.pl.t), -14);
c = cv_dim(c, P.pl.t, P.pl.zb, u2, P.pl.zb, -75);
c = cv_dim(c, u2, P.pl.zb, P.anc.uh, P.pl.zb, -75);
c = cv_dim(c, 0, P.pl.zb, P.anc.u0, P.pl.zb, -105, sprintf('%g', P.anc.u0), -10);
c = cv_dim(c, P.anc.u0, P.pl.zb, P.anc.uh, P.pl.zb, -105, sprintf('%g  (bar, outside of the hook)', P.anc.uh - P.anc.u0));
c = cv_dim(c, 0, P.pl.zb, P.anc.uh, P.pl.zb, -135);
c = cv_dim(c, u2 - P.anc.Lw, R.anE(1,1), u2, R.anE(1,1), -22, sprintf('%g', P.anc.Lw));
c = cv_dim(c, P.anc.uh, R.dev.zend(2), P.anc.uh, R.anE(1,1)-R.dev.rb, -40, sprintf('%g  (12 db)', R.dev.tail));
c = cv_dim(c, P.anc.uh, R.dev.zend(2), P.anc.uh, R.anE(1,1)+db/2, -80);
c = cv_dim(c, uL, P.pl.zb, uL, -bm.h, 30);
c = cv_dim(c, uL, -bm.h, uL, 0, 30);
c = cv_dim(c, uL, 0, uL, P.pl.zt, 30);
c = cv_dim(c, uL, P.pl.zb, uL, P.pl.zt, 75);
c = cv_dim(c, 120, R.anE(2,1), 120, R.anE(1,1), -8, sprintf('%g', R.anE(1,1) - R.anE(2,1)));

c = cv_lead(c, -40, -bm.tf, -150, 95, {sprintf('flanges: fillet %g (site)', P.w.flange), 'both sides, both flanges'});
c = cv_lead(c, -3, -100, -150, -290, {sprintf('web: fillet %g (site)', P.w.web), 'both sides'});
c = cv_lead(c, P.pl.t+3, zf+P.pla.t/2+3, 40, 120, {sprintf('platina to plate: fillet %g, top and bottom,', P.w.pla), 'full width'});
c = cv_lead(c, u2-20, R.anE(1,1)+db/2+2, 150, 95, {sprintf('bar on platina: groove filled flush + fillet %g,', P.w.bar), sprintf('%g long, both sides of each bar', P.anc.Lw)});
c = cv_lead(c, P.anc.u0, R.anE(2,1), 40, -150, {sprintf('bars start %g mm behind the plate:', P.anc.u0 - P.pl.t), 'no weld to the plate'});
c = cv_lead(c, P.anc.uh-20, R.anE(1,1)-25, 420, 95, {sprintf('%s%g, inside bend diameter', '&#216;', db), sprintf('6 db = %g', 6*db)});
c = cv_lead(c, 230, R.anE(1,1), 280, 60, sprintf('bars over the platinas (|v| = %g)', P.anc.vO));
c = cv_lead(c, 200, R.anE(2,1), 250, -60, sprintf('bars under the platinas (|v| = %g)', P.anc.vU));
c = cv_text(c, -85, -125, bm.name, 'middle');
c = cv_text(c, -320, -420, sprintf('Type E shown. C1: 4 bars under the platinas, at |v| = %g and %g. C2: the same, over the platinas.', P.anc.vC), 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_assy_plan(P, R)
% Shop assembly type E, top view
bm = P.bm;  db = P.anc.db;  uL = -170;  u2 = P.pl.t + P.pla.L;
c = cv_new(-330, 600, -200, 200, 1.0);
c = cv_rect(c, uL, -bm.b/2, 0, bm.b/2, 'steel');
c = cv_seg(c, [uL 0], [0 0], 'cl');
% bars under (hidden), platinas, bars over
for v = R.anE(2,2)*[-1 1]
    c = cv_bar(c, [P.anc.u0 P.anc.uh], [v v], db, 'anch');
    c = cv_circ(c, P.anc.uh-db/2, v, db, 'tail');
end
for sg = [-1 1]
    c = cv_rect(c, P.pl.t, sg*P.pla.v0, u2, sg*(P.pla.v0+P.pla.w), 'platet');
end
for v = R.anE(1,2)*[-1 1]
    c = cv_bar(c, [P.anc.u0 P.anc.uh], [v v], db, 'anc');
    c = cv_circ(c, P.anc.uh-db/2, v, db, 'tail');
    for sg = [-1 1]
        c = cv_seg(c, u2 - [P.anc.Lw 0], (v + sg*db/2)*[1 1], 'weld');
    end
end
c = cv_rect(c, 0, -P.pl.w/2, P.pl.t, P.pl.w/2, 'plate');
% mid-face column bar, for reference
c = cv_circ(c, P.col.cover + P.col.dtie + P.col.db/2, 0, P.col.db, 'col');

c = cv_dim(c, P.pl.t, P.pl.w/2, u2, P.pl.w/2, 25, sprintf('%g', P.pla.L));
c = cv_dim(c, u2, P.pl.w/2, P.anc.uh, P.pl.w/2, 25);
c = cv_dim(c, uL, -P.pla.v0, uL, P.pla.v0, 30, sprintf('%g', 2*P.pla.v0));
c = cv_dim(c, uL, P.pla.v0, uL, P.pla.v0+P.pla.w, 30, sprintf('%g', P.pla.w));
c = cv_dim(c, uL, -P.pl.w/2, uL, P.pl.w/2, 75, sprintf('%g  (plate)', P.pl.w));
vv = sort([-R.anE(:,2); R.anE(:,2)])';
for i = 1:numel(vv)-1, c = cv_dim(c, P.anc.uh, vv(i), P.anc.uh, vv(i+1), -35); end
c = cv_dim(c, uL, -bm.b/2, 0, -bm.b/2, -95, 'beam continues');
c = cv_lead(c, u2 - P.anc.Lw/2, R.anE(1,2)+db/2, 330, 150, {sprintf('side welds (yellow): %g mm each side,', P.anc.Lw), 'ending at the end of the platina'});
c = cv_lead(c, 200, -R.anE(2,2), 250, -150, {'bars under the platinas (lighter)', sprintf('at |v| = %g', R.anE(2,2))});
c = cv_lead(c, P.col.cover + P.col.dtie + P.col.db/2, -P.col.db/2, 140, -185, 'mid-face column bar (not part of the assembly)');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_flow(P, R)
% Force flow in the edge joint and the breakout surface of chapter 17
hb = P.col.b/2;  bm = P.bm;  gx = @(u) u - hb;  K = R.kase(1);  db = P.anc.db;
ztop = P.col.top;  zcj = P.col.cj;  xL = -420;  xR = 620;  zB = -470;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
zl = R.zf;  zs = R.zC;  zt = P.cb.zt(1);  zU = R.zanc(1);
c = cv_new(-640, 800, -560, 250, 0.78);
c = cv_rect(c, -hb, zB, hb, zcj, 'old');
c = cv_rect(c, -hb, zcj, hb, ztop, 'conc');
c = cv_rect(c, hb, -P.cb.h, xR, 0, 'conc');
c = cv_seg(c, [-hb-40 hb+40], [zcj zcj], 'cj');

% path 2: diagonal strut to the pedestal
x1 = gx(R.stm.u1);  z1 = R.stm.z1;  x2 = gx(R.stm.u2);  z2 = R.stm.z2;
n = [-(z2-z1), (x2-x1)]/hypot(x2-x1, z2-z1)*28;
c = cv_poly(c, [x1+n(1) x2+n(1) x2-n(1) x1-n(1)], [z1+n(2) z2+n(2) z2-n(2) z1-n(2)], 'strut2');
% path 1: anchors and hooked beam bars side by side, compression into the beam
c = cv_poly(c, [gx(P.cb.uh) gx(P.anc.uh) gx(P.anc.uh) gx(P.cb.uh)], [zU+8 zU+8 zt-10 zt-10], 'strut1');
c = cv_poly(c, [gx(P.pl.t) xR xR gx(P.pl.t)], [zs+25 -300 -350 zs-25], 'strut1');

% steel
c = cv_rect(c, xL, -bm.h+bm.tf, -hb, -bm.tf, 'web');
c = cv_rect(c, xL, -bm.tf, -hb, 0, 'steel');
c = cv_rect(c, xL, -bm.h, -hb, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -hb, P.pl.zb, gx(P.pl.t), P.pl.zt, 'plate');
c = draw_platina_elev(c, P, R, gx);
% bars
c = cv_bar(c, [-xc -xc], [zB ztop-48], P.col.db, 'col');
c = cv_bar(c, [ xc  xc], [zB ztop-48], P.col.db, 'col');
[x, z] = hook(xR, gx(P.cb.uh), zt, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'new');
for j = 1:2
    [x, z] = hook(gx(P.anc.u0), gx(P.anc.uh), R.anE(j,1), db, -1);
    c = cv_bar(c, x, z, db, 'anc');
end

% breakout surface of chapter 17 (slope 1 : 1.5 from the start of the bends)
xk = gx(R.dev.uap);
c = cv_seg(c, [xk - 1.5*(ztop-zU), xk, -hb], [ztop, zU, zU - (xk+hb)/1.5], 'crack');

% forces
c = cv_arrow(c, -hb-20, zl, -hb-130, zl, '#c0392b');
c = cv_text(c, -hb-75, zl+14, sprintf('T = %.0f kN', K.T/1e3), 'middle');
c = cv_arrow(c, -hb-130, zs, -hb-20, zs, '#1f4e79');
c = cv_text(c, -hb-75, zs-28, sprintf('C = %.0f kN', K.T/1e3), 'middle');
c = cv_arrow(c, -hb-60, -60, -hb-60, -140, '#222222');
c = cv_text(c, -hb-72, -105, sprintf('V = %.0f kN', K.Vu/1e3), 'end');
c = cv_arrow(c, xc+28, z1-20, xc+28, z1-110, '#9a6b00');
c = cv_arrow(c, 560, zt+22, 440, zt+22, '#1e8449');

% labels
c = cv_lead(c, 20, zU-20, 330, 190, {'PATH 1: the anchors and the hooked top bars', sprintf('of the concrete beam (%d %s%g, green) side by side', numel(P.cb.v) + numel(P.cb.vm), '&#216;', P.cb.db)});
c = cv_lead(c, 420, -322, 440, -420, {'PATH 1: the flange compression goes', 'straight into the beam'});
c = cv_lead(c, (x1+x2)/2, (z1+z2)/2, -330, -420, {'PATH 2: strut to the pedestal,', sprintf('%.0f deg from the horizontal', R.stm.th*180/pi)});
c = cv_lead(c, xc+28, z1-110, 440, -500, {sprintf('PATH 2: %.0f kN of tension in the inner', K.T*tan(R.stm.th)/1e3), 'column bars, anchored at the top'});
c = cv_lead(c, xk - 0.75*(ztop-zU), zU + (ztop-zU)/2, -330, 205, {'Breakout surface of chapter 17, 1 : 1.5', sprintf('%.0f kN: not relied upon', R.brk.phiN/1e3)});
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_path(P, R)
% Close-up behind the top flange, corner type C1: the one load path
bm = P.bm;  zf = R.zf;  zb = R.zanc(1);  d = P.anc.db;  r = d/2;  t = P.pl.t;  L = P.pla.L;
tp = P.pla.t;  w = P.w.pla;  u2 = t + L;
c = cv_new(-80, 330, -70, 48, 2.6);
c = cv_rect(c, -75, -bm.tf, 0, 0, 'steel');
c = cv_rect(c, -75, -66, 0, -bm.tf, 'web');
c = cv_rect(c, 0, -66, t, 40, 'plate');
c = draw_platina_elev(c, P, R, @(u) u);
c = cv_poly(c, [0 -P.w.flange 0], [0 0 P.w.flange], 'weldfill');
c = cv_poly(c, [0 -P.w.flange 0], [-bm.tf -bm.tf -bm.tf-P.w.flange], 'weldfill');
c = cv_bar(c, [P.anc.u0 150], [zb zb], d, 'anch');
c = cv_seg(c, [u2-P.anc.Lw u2], [zb+r+1.2 zb+r+1.2], 'wside');
% the path
c = cv_arrow(c, -12, zf, -70, zf, '#c0392b');
c = cv_text(c, -40, zf+6, 'flange', 'middle');
c = cv_arrow(c, -2, zf+1, t+9, zf+1, '#e67e22');
c = cv_arrow(c, t+9, zf+1, u2-P.anc.Lw/2, zf+1, '#e67e22');
c = cv_arrow(c, u2-P.anc.Lw/2, zf-2, u2-P.anc.Lw/2, zb+r+3, '#e67e22');
c = cv_arrow(c, u2, zb, 150, zb, '#7b241c');
c = cv_text(c, -75, 36, '1 plate, through its thickness', 'start');
c = cv_text(c, t+3, zf+tp/2+w+12, '2 fillets platina-plate, full width', 'start');
c = cv_text(c, t+L/2+8, zf+8, '3 platina', 'start');
c = cv_text(c, u2+4, zb+r+5, sprintf('4 side welds %g x %g', P.w.bar, P.anc.Lw), 'start');
c = cv_text(c, 155, zb-1, '5 bar, to its hook', 'start');
c = cv_dim(c, t, zb, P.anc.u0, zb, -12, sprintf('%g', P.anc.u0 - t));
c = cv_text(c, P.anc.u0+2, zb-r-8, 'gap: the bar is not welded to the plate', 'start');
c = cv_dim(c, 60, zb, 60, zf, -6, sprintf('e = %g', R.e), 14);
c = cv_text(c, -72, -60, bm.name, 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_plate_face(P, R)
% Embed plate seen from inside the column (back face): where the forces enter.
bm = P.bm;  zf = R.zf;  zc = R.zC;  t = P.pla.t;  v0 = P.pla.v0;  wp = P.pla.w;
hh = R.plate.htt;  Y = R.brg;
c = cv_new(-560, 560, P.pl.zb-70, P.pl.zt+60, 1.0);
c = cv_rect(c, -P.pl.w/2, P.pl.zb, P.pl.w/2, P.pl.zt, 'platet');
% beam outline seen through the plate
c = cv_rect(c, -bm.b/2, -bm.tf, bm.b/2, 0, 'hid');
c = cv_rect(c, -bm.b/2, -bm.h, bm.b/2, -bm.h+bm.tf, 'hid');
c = cv_rect(c, -bm.tw/2, -bm.h+bm.tf, bm.tw/2, -bm.tf, 'hid');
% strip that takes the offset moment (corner): under the two platina roots, down to C
for sg = [-1 1]
    c = cv_rect(c, sg*v0, zc, sg*(v0+wp), zf, 'zstrip');
end
% flange footprint backed by the platinas (through the thickness) and over the gap
for sg = [-1 1]
    c = cv_rect(c, sg*v0, zf-hh/2, sg*min(bm.b/2, v0+wp), zf+hh/2, 'zovl');
end
c = cv_rect(c, -v0, zf-hh/2, v0, zf+hh/2, 'zgap');
% platinas (section through the plate face)
for sg = [-1 1]
    c = cv_rect(c, sg*v0, zf-t/2, sg*(v0+wp), zf+t/2, 'hid');
end
% bearing area behind the compression flange (DG1)
c = cv_rect(c, -bm.b/2-Y.c, zc-bm.tf/2-Y.c, bm.b/2+Y.c, zc+bm.tf/2+Y.c, 'zbrg');

c = cv_dim(c, -v0, P.pl.zt, v0, P.pl.zt, 20, sprintf('%g gap', 2*v0));
c = cv_dim(c, v0, P.pl.zt, v0+wp, P.pl.zt, 20, sprintf('%g', wp));
c = cv_dim(c, -v0-wp, P.pl.zt, -v0, P.pl.zt, 20, sprintf('%g', wp));
c = cv_dim(c, -P.pl.w/2, P.pl.zt, P.pl.w/2, P.pl.zt, 45, sprintf('%g', P.pl.w));
c = cv_dim(c, P.pl.w/2, zf-hh/2, P.pl.w/2, zf+hh/2, -18, sprintf('%.1f', hh));
c = cv_dim(c, P.pl.w/2, zc, P.pl.w/2, zf, -50, sprintf('%.1f', zf - zc));
c = cv_dim(c, -bm.b/2-Y.c, P.pl.zb, bm.b/2+Y.c, P.pl.zb, -25, sprintf('%.0f', bm.b + 2*Y.c));
c = cv_lead(c, -v0-wp/2, zf, -310, 70, {'green: flange backed by a platina,', 'straight through the thickness'});
c = cv_lead(c, 0, zf+hh/2, 130, 75, {'orange: flange over the gap,', sprintf('plate spans %g mm between the platinas', 2*v0)});
c = cv_lead(c, -v0-wp+5, -120, -310, -150, {'blue: plate strip under the two platinas', '(corner: carries T e down to C)'});
c = cv_lead(c, bm.b/2+Y.c-5, zc+bm.tf/2+Y.c-3, 250, -120, {'grey: bearing area behind', 'the compression flange'});
c = cv_text(c, -320, P.pl.zb-55, 'Embed plate seen from inside the column. Dashed: beam and platinas.', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_plate_models(P, R)
% (a) plate over the gap: simply supported strip. (b) plate strip from the
% platina root to the compression flange, corner C1: moment T e falling to zero.
G = R.plate;  K = R.kase(3);  zf = R.zf;  zc = R.zC;
c = cv_new(-20, 760, -300, 70, 0.95);
% (a)
L = G.Lgap*3;  x0 = 30;  yb = -20;
c = cv_rect(c, x0, yb-6, x0+L, yb+6, 'plate');
c = cv_poly(c, x0+[0 -9 9], yb-6+[0 -14 -14], 'vent');
c = cv_poly(c, x0+L+[0 -9 9], yb-6+[0 -14 -14], 'vent');
for x = linspace(x0+6, x0+L-6, 7), c = cv_arrow(c, x, yb+40, x, yb+8, '#e67e22'); end
c = cv_dim(c, x0, yb-30, x0+L, yb-30, 0.01, sprintf('L = %g mm (gap)', G.Lgap));
c = cv_text(c, x0, 55, sprintf('(a) F = %.1f kN over the gap (edge)', G.Fgap(1)/1e3), 'start');
c = cv_text(c, x0, -80, sprintf('M = F L / 8 = %.0f N m', G.Fgap(1)*G.Lgap/8/1e3), 'start');
c = cv_text(c, x0, -97, sprintf('&#966;Mp = 0.9 Fy (%.1f)(%g)&#178;/4 = %.0f N m', G.htt, P.pl.t, 0.9*G.Mpg/1e3), 'start');
c = cv_text(c, x0, -114, sprintf('D/C = %.2f (%.2f with fixed ends)', G.Fgap(1)/G.phiFgap, G.Fgap(1)/G.phiFgapX), 'start');
% (b)
x1 = 420;  s = 1.0;
c = cv_rect(c, x1-6, zc*s, x1+6, (zf+30)*s, 'plate');
c = cv_arrow(c, x1+10, zf, x1+60, zf, '#7b241c');
c = cv_text(c, x1+64, zf+12, sprintf('platinas: T = %.1f kN and T e = %.2f kN m', K.T/1e3, G.Mstr(3)/1e6), 'start');
c = cv_arrow(c, x1-10, zf, x1-60, zf, '#c0392b');
c = cv_text(c, x1-64, zf+12, sprintf('flange %.1f kN', K.Tf/1e3), 'end');
c = cv_arrow(c, x1-60, zc, x1-10, zc, '#1f4e79');
c = cv_arrow(c, x1+60, zc, x1+10, zc, '#1f4e79');
c = cv_text(c, x1+64, zc+4, sprintf('C = %.1f kN (concrete)', K.T/1e3), 'start');
% moment diagram
m = 120/G.Mstr(3);
c = cv_poly(c, [x1+8 x1+8+G.Mstr(3)*m x1+8], [zf zf zc], 'zstrip');
c = cv_text(c, x1+8+G.Mstr(3)*m*0.55, (zf+zc)/2+20, 'plate moment', 'start');
c = cv_dim(c, x1-150, zc, x1-150, zf, 0.01, sprintf('%.1f', zf - zc));
c = cv_text(c, x1-150, 55, '(b) corner C1: plate strip under the platinas', 'start');
c = cv_text(c, x1+80, -150, sprintf('&#966;Mp = 0.9 Fy (2 x %g)(%g)&#178;/4', P.pla.w, P.pl.t), 'start');
c = cv_text(c, x1+80, -167, sprintf('= %.2f kN m, D/C = %.2f', G.phiMstr/1e6, G.Mstr(3)/G.phiMstr), 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_cones(P, R)
% Corner column in plan: breakout bodies of the two groups and the beam bars
% that cross them, with the hooked length of each bar inside the bodies.
hb = P.col.b/2;  gx = @(u) u - hb;  db = P.anc.db;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
c = cv_new(-900, 760, -560, 700, 0.6);
c = cv_rect(c, hb, -P.cb.b/2, 680, P.cb.b/2, 'conc');
c = cv_rect(c, -P.cb.b/2, hb, P.cb.b/2, 680, 'conc');
c = cv_rect(c, -hb, -hb, hb, hb, 'conc');
uap = R.dev.uap;  vm = max(P.anc.vC);  d = (hb - vm)/1.5;
px = [gx(uap), gx(uap)-d, -hb, -hb, gx(uap)-d, gx(uap)];  py = [vm, hb, hb, -hb, -hb, -vm];
c = cv_poly(c, px, py, 'tribx');
c = cv_poly(c, py, px, 'triby');
C1 = R.cone(2);  C2 = R.cone(3);
uh = P.cb.uh*ones(size(P.cb.v));  uh(P.cb.v == 0) = P.cb.uh0;
for i = 1:numel(P.cb.v)
    y = P.cb.v(i);
    c = cv_bar(c, [gx(uh(i)+P.cb.db/2) 680], [y y], P.cb.db, 'ex');
    c = cv_bar(c, [y y], [gx(uh(i)+P.cb.db/2) 680], P.cb.db, 'ex');
    c = cv_circ(c, gx(C1.uc_nom(i)), y, 9, 'mark');
    c = cv_circ(c, y, gx(C2.uc_nom(i)), 9, 'mark');
end
c = draw_assembly_plan(c, P, R.anC1, gx, 0);
c = draw_assembly_plan(c, P, R.anC2, gx, 1);
for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, c = cv_circ(c, sx*xc, sy*xc, P.col.db, 'col'); end
end, end
[m, j] = min(C1.ins_tol(C1.used));  i = C1.used(j);
c = cv_dim(c, gx(uh(i)), C1.vb(i), gx(C1.uc_nom(i)), C1.vb(i), -(260 + C1.vb(i)), sprintf('%.0f inside (%.0f with tolerances) &#8805; %.0f', C1.ins_nom(i), C1.ins_tol(i), R.dev.ldh12));
[m, j] = min(C2.ins_tol(C2.used));  i = C2.used(j);
c = cv_dim(c, C2.vb(i), gx(uh(i)), C2.vb(i), gx(C2.uc_nom(i)), 260 + C2.vb(i), sprintf('%.0f inside (%.0f with tolerances) &#8805; %.0f', C2.ins_nom(i), C2.ins_tol(i), R.dev.ldh12));
c = cv_lead(c, -170, 170, -520, 560, {'breakout body of beam X, type C1', '(orange)'});
c = cv_lead(c, 170, -170, 260, -470, {'breakout body of beam Y, type C2 (blue)'});
c = cv_lead(c, gx(C1.uc_nom(1)), C1.vb(1), 330, 620, {'white dots: where each beam bar', 'leaves the bodies (nominal positions)'});
c = cv_lead(c, 600, P.cb.v(end), 520, 250, {'beam bars continue: straight', sprintf('length needed %.0f, available: the whole beam', R.dev.ld12)});
c = cv_text(c, -hb-20, 0, 'X', 'end');
c = cv_text(c, 0, -hb-30, 'Y', 'middle');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_devel(P, R, k)
% Section along a beam: cone from the anchors (apex at the start of the bend,
% slope 1 : 1.5) and the counted beam bar with the shortest length inside.
% The beam bar is drawn at its nominal place and at its place with tolerances.
hb = P.col.b/2;  bm = P.bm;  gx = @(u) u - hb;  db = P.anc.db;  CN = R.cone(k);
ztop = P.col.top;  zcj = P.col.cj;  xR = 560;
c = cv_new(-900, 760, -440, 280, 0.8);
c = cv_rect(c, -hb, zcj-60, hb, zcj, 'old');
c = cv_rect(c, -hb, zcj, hb, ztop, 'conc');
c = cv_rect(c, hb, -P.cb.h, xR, 0, 'conc');
c = cv_rect(c, -420, -bm.tf, -hb, 0, 'steel');
c = cv_rect(c, -420, -bm.h, -hb, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -420, -bm.h+bm.tf, -hb, -bm.tf, 'web');
c = cv_rect(c, -hb, P.pl.zb, gx(P.pl.t), P.pl.zt, 'plate');
c = draw_platina_elev(c, P, R, gx);
if k == 1, rows = R.anE; ttl = 'EDGE, type E'; else, rows = R.anC2; ttl = 'CORNER, type C2 (bars over), which governs'; end
[m, j] = min(CN.ins_tol(CN.used));  i = CN.used(j);
zb = CN.zb(i);  uh = CN.uh(i);
[x, z] = hook(560, gx(uh + P.tol.ub), zb - P.tol.zb, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'exh');
[x, z] = hook(560, gx(uh), zb, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'ex');
for jj = 1:size(rows,1)
    [x, z] = hook(gx(P.anc.u0), gx(P.anc.uh), rows(jj,1), db, -1);
    c = cv_bar(c, x, z, db, 'anc');
    c = cv_circ(c, gx(R.dev.uap), rows(jj,1), 7, 'mark');
    c = cv_seg(c, [gx(R.dev.uap)-(ztop-rows(jj,1))/1.5, gx(R.dev.uap), gx(R.dev.uap)-(rows(jj,1)-zcj)/1.5], [ztop, rows(jj,1), zcj], 'crack');
end
c = cv_circ(c, gx(CN.uc_nom(i)), zb, 9, 'mark');
c = cv_dim(c, gx(uh), zb, gx(CN.uc_nom(i)), zb, -150, sprintf('%.0f inside the body (nominal); %.0f with tolerances; &#8467;dh = %.0f', CN.ins_nom(i), CN.ins_tol(i), R.dev.ldh12));
c = cv_dim(c, gx(CN.uc_nom(i)), zb, xR, zb, -150, sprintf('continues along the beam, needs %.0f', R.dev.ld12));
c = cv_dim(c, gx(P.pl.t+P.pla.L), ztop, gx(P.anc.uh), ztop, 40, sprintf('%.0f anchor embedment from the end of the welds &#8805; %.0f', P.anc.uh - P.pl.t - P.pla.L, R.dev.ldh));
c = cv_lead(c, gx(P.anc.uh)-60, rows(1,1)+60, -500, 240, {'dashed: surface of the breakout body,', 'slope 1 : 1.5 from the start of the bend (conservative)'});
c = cv_lead(c, gx(CN.uc_nom(i)), zb, 300, 180, {'white dot: where the beam bar leaves the body,', sprintf('computed in 3D (bar at v = %+g)', CN.vb(i))});
c = cv_lead(c, gx(uh + P.tol.ub), zb - P.tol.zb - 60, -560, -300, {sprintf('light: the same bar %g mm shorter and %g mm lower', P.tol.ub, P.tol.zb), '(ACI placing tolerances)'});
c = cv_text(c, -880, -420, ttl, 'start');
svg = cv_end(c);
end

function svg = fig_trib(P, R)
% Tributary areas: edge beam and the two corner beams, beyond the column face
L = P.L;  a0 = P.a0;  s = P.s_edge;  s1 = P.s1;  s2 = P.s2;  X0 = 6600;  Lt = L + a0;
c = cv_new(-2900, 10300, -3700, 3700, 0.062);
% edge: column axis at x = 0
c = cv_rect(c, 0, -2900, 1500, 2900, 'conc');
c = cv_rect(c, -Lt, -s/2, -a0, s/2, 'tribx');
c = cv_seg(c, [-Lt -Lt], [-2900 2900], 'dim');
c = cv_bar(c, [-Lt -a0], [0 0], 90, 'steelc');
c = cv_rect(c, -a0, -a0, a0, a0, 'old');
c = cv_dim(c, -Lt, -s/2, -a0, -s/2, -450, sprintf('%.2f m', L/1000));
c = cv_dim(c, -Lt, -s/2, 0, -s/2, -900, sprintf('%.2f m from the axis', Lt/1000));
c = cv_dim(c, -Lt, -s/2, -Lt, s/2, 500, sprintf('%.2f m', s/1000));
c = cv_text(c, -Lt/2-100, 1100, sprintf('A = %.2f m2', R.kase(1).A), 'middle');
c = cv_text(c, 750, 2500, 'building', 'middle');
c = cv_text(c, -1300, 3350, 'EDGE COLUMN', 'start');
% corner: column axis at (X0, 0)
c = cv_poly(c, X0+[0 3300 3300 0], [0 0 3100 3100], 'conc');
c = cv_poly(c, X0+[-a0 -a0 -Lt -Lt], [-a0 s2 s2 -Lt], 'tribx');
c = cv_poly(c, X0+[-a0 s2 s2 -Lt], [-a0 -a0 -Lt -Lt], 'triby');
c = cv_seg(c, X0+[-Lt -Lt 3300], [3100 -Lt -Lt], 'dim');
c = cv_bar(c, X0+[-Lt -a0], [0 0], 90, 'steelc');
c = cv_bar(c, X0+[0 0], [-Lt -a0], 90, 'steelc');
c = cv_rect(c, X0-a0, -a0, X0+a0, a0, 'old');
c = cv_dim(c, X0-Lt, -Lt, X0-Lt, s2, 500, sprintf('s1 = %.2f m', s1/1000));
c = cv_dim(c, X0, 0, X0, s2, -700, sprintf('%.2f m', s2/1000));
c = cv_dim(c, X0-Lt, s2, X0-a0, s2, 450, sprintf('%.2f m', L/1000));
c = cv_dim(c, X0-Lt, -Lt, X0+s2, -Lt, -550, sprintf('s1 = %.2f m', s1/1000));
c = cv_text(c, X0-Lt/2-150, 1150, 'beam X', 'middle');
c = cv_text(c, X0-Lt/2-150, 800, sprintf('%.2f m2', R.kase(2).A), 'middle');
c = cv_text(c, X0+1200, -620, 'beam Y', 'middle');
c = cv_text(c, X0+1200, -970, sprintf('%.2f m2', R.kase(2).A), 'middle');
c = cv_text(c, X0+1800, 2500, 'building', 'middle');
c = cv_text(c, X0-1300, 3350, 'CORNER COLUMN', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_hoops(P, R)
% One layer of joint ties: four straight bars with 135 degree hooks
hb = P.col.b/2;  xc = hb - P.col.cover - P.col.dtie - P.col.db/2;  xh = xc + P.col.db/2 + P.hoop.db/2;
c = cv_new(-640, 560, -300, 300, 0.95);
c = cv_rect(c, -hb, -hb, hb, hb, 'conc');
cols = {'#7d3c98', '#c0392b', '#1e8449', '#2e86c1'};
e = 6*P.hoop.db + 20;                               % drawn length of the 135 degree hook
K = xh*[-1 -1; 1 -1; 1 1; -1 1];                    % tie corners
for i = 1:4
    p1 = K(i,:);  p2 = K(mod(i,4)+1,:);
    h1 = p1 - sign(p1)*e/sqrt(2);  h2 = p2 - sign(p2)*e/sqrt(2);
    o = 3*(i-2.5);
    c.b{end+1} = sprintf('<polyline points="%s" fill="none" stroke="%s" stroke-width="4" stroke-linejoin="round"/>', ...
        pts(c, [h1(1) p1(1) p2(1) h2(1)]+o*(i==2||i==4), [h1(2) p1(2) p2(2) h2(2)]+o*(i==1||i==3)), cols{i});
end
for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, c = cv_circ(c, sx*xc, sy*xc, P.col.db, 'col'); end
end, end
c = cv_dim(c, -hb, -hb, hb, -hb, -40);
c = cv_dim(c, -xh, hb, xh, hb, 35, sprintf('%.0f (axis of the ties)', 2*xh));
c = cv_lead(c, -xh, 0, -320, 250, {'each face: one straight &#216;10,', '135&#176; hook around both corner bars,', sprintf('hook extension %g mm', max(6*P.hoop.db, 75))});
c = cv_lead(c, xc, xc, 240, 260, {'each corner bar is held', 'by two hooks'});
c = cv_lead(c, xc, 0, 240, -150, {'mid-face bars: wired', 'to the straight part'});
c = cv_text(c, -310, -270, 'outer face (steel beam side)', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_tie(P)
% Bending detail of one straight joint tie with two 135 degree hooks
xc = P.col.b/2 - P.col.cover - P.col.dtie - P.col.db/2;   % corner bar position
d = P.hoop.db;  ri = 2*d;  r = ri + d/2;  ext = max(6*d, 75);
c = cv_new(-260, 420, -60, 175, 1.6);
t = linspace(-pi/2, pi/4, 16);
xr = xc + r*cos(t);  yr = r + r*sin(t);
he = [xr(end) yr(end)] + ext*[-sin(pi/4) cos(pi/4)];
x = [fliplr(-xr) he(1)];  x = [-he(1) fliplr(-xr) xr he(1)];
y = [he(2) fliplr(yr) yr he(2)];
c.b{end+1} = sprintf('<polyline points="%s" fill="none" stroke="#7d3c98" stroke-width="%.1f" stroke-linejoin="round"/>', pts(c, x, y), d*c.s);
for sx = [-1 1]
    bc = [sx*(xc + (ri - P.col.db/2)*cos(-pi/8)), r + (ri - P.col.db/2)*sin(-pi/8)];
    c = cv_circ(c, bc(1), bc(2), P.col.db, 'col');
end
c = cv_dim(c, -xc, 0, xc, 0, -35, sprintf('%.0f straight', 2*xc));
c = cv_dim(c, xr(end), yr(end), he(1), he(2), 14, sprintf('%g', ext));
L = 2*xc + 2*(r*3*pi/4 + ext);
c = cv_lead(c, xc + r, r, 200, 150, {sprintf('bend: inside diameter 4 db = %g mm', 2*ri), 'around the corner bar &#216;16'});
c = cv_lead(c, 0, 0, -60, 120, {sprintf('&#216;%g, cut length about %.0f mm', d, 10*ceil(L/10)), 'one hook bent in the shop,', 'the other bent in place'});
c = cv_text(c, -250, -50, sprintf('4 per layer x %d layers = %d pieces per joint, plus 1 closed tie on top', numel(P.hoop.z), 4*numel(P.hoop.z)), 'start');
svg = cv_end(c);
end


function s = pts(c, x, y)
[px, py] = cv_p(c, x, y);
s = sprintf('%.1f,%.1f ', [px(:)'; py(:)']);
end

% ---------------------------------------------------------------------------
function svg = fig_tol(P, R)
% Plans of the edge and corner joints at the level of the beam top bars:
% the hooks the design counts on, each with how far from the column face it
% may end (all the other tolerances still applied), and the shop tolerances
% of the anchors.
hb = P.col.b/2;  ox = 1350;
c = cv_new(-500, ox+960, -520, 680, 0.72);
c = tol_panel(c, P, R, 0, 'edge');
c = tol_panel(c, P, R, ox, 'corner');
c = cv_text(c, -480, 650, 'EDGE COLUMN', 'start');
c = cv_text(c, ox-480, 650, 'CORNER COLUMN', 'start');
c = cv_text(c, -480, -505, sprintf(['Green: beam top bars the design counts on, with the zone where the outside of their hook may fall. ' ...
    'Grey: not needed. Limits rounded down to 5 mm; they already include bars %g mm low and the shop tolerances.'], P.tol.zb), 'start');
svg = cv_end(c);
end

function c = tol_panel(c, P, R, ox, kase)
hb = P.col.b/2;  gx = @(u) u - hb + ox;  db = P.anc.db;  cor = strcmp(kase, 'corner');
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
xh = hb - P.col.cover - P.col.dtie/2;
L = 300;                                            % drawn length of the beam bars beyond the face
c = cv_rect(c, ox+hb, -P.cb.b/2, ox+hb+L, P.cb.b/2, 'conc');
if cor, c = cv_rect(c, ox-P.cb.b/2, hb, ox+P.cb.b/2, hb+L, 'conc'); end
c = cv_rect(c, ox-hb, -hb, ox+hb, hb, 'conc');
c = cv_rect(c, ox-xh, -xh, ox+xh, xh, 'hoopr');
for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, c = cv_circ(c, ox+sx*xc, sy*xc, P.col.db, 'col'); end
end, end
for sx = [-1 1], for sy = [-1 1], c = cv_circ(c, ox+sx*P.rod.p, sy*P.rod.p, P.rod.db, 'rodc'); end, end
% anchors (light), plates
if cor
    c = draw_assembly_plan(c, P, R.anC1, gx, 0);
    c = draw_assembly_plan(c, P, R.anC2, @(u) u - hb, 1, ox);
    sets = {R.cone(2), 0; R.cone(3), 1};
else
    c = draw_assembly_plan(c, P, R.anE, gx, 0);
    sets = {R.cone(1), 0};
end
% beam top bars of the beam(s) in line
for k = 1:size(sets,1)
    C = sets{k,1};  rot = sets{k,2};
    for i = 1:numel(C.vb)
        v = C.vb(i);  u1 = C.uh(i);  used = any(C.used == i);
        st = 'exh';  if used, st = 'new'; end
        if ~rot
            c = cv_bar(c, [gx(u1+P.cb.db/2) ox+hb+L], [v v], P.cb.db, st);
        else
            c = cv_bar(c, ox+[v v], [u1+P.cb.db/2-hb hb+L], P.cb.db, st);
        end
        if used
            s5 = 5*floor(C.short(i)/5);
            if ~rot
                c = cv_rect(c, gx(u1), v-12, gx(u1+s5), v+12, 'ztol');
                c = cv_seg(c, gx(u1+s5)*[1 1], v+[-15 15], 'limit');
            else
                c = cv_rect(c, ox+v-12, u1-hb, ox+v+12, u1+s5-hb, 'ztol');
                c = cv_seg(c, ox+v+[-15 15], (u1+s5-hb)*[1 1], 'limit');
            end
        end
    end
    % one label per pair of symmetric bars
    for vv = unique(abs(C.vb(C.used)))
        i = find(C.vb == vv, 1);  if isempty(i), i = find(C.vb == -vv, 1); end
        s5 = 5*floor(C.short(i)/5);  lim = C.uh(i) + s5;
        pm = '';  if vv > 0, pm = '&#177;'; end
        txt = {sprintf('hooks at v = %s%g: outside of the hook', pm, vv), sprintf('at most %g mm from the column face', lim), sprintf('(drawn %g, may fall %g short)', C.uh(i), s5)};
        if vv == 0, txt{1} = 'centre bar: outside of the hook'; end
        if ~rot
            c = cv_lead(c, gx(C.uh(i)+s5), vv, ox+hb+L+30, vv*2.6 + 40*sign(vv), txt);
        else
            c = cv_lead(c, ox+vv, C.uh(i)+s5-hb, ox+vv*2.6+60*sign(vv), hb+L+40, txt);
        end
    end
end
% the column face and the anchors
c = cv_seg(c, [ox-hb ox-hb], [-hb-60 hb+60], 'cj');
if cor
    c = cv_lead(c, gx(P.anc.uh-db/2), R.anC1(end,2), ox-60, -400, {sprintf('anchors (shop): hooks at %g &#177; %g from the face,', P.anc.uh, P.tol.ua), sprintf('platinas level with the top flange &#177; %g', P.tol.za)});
    c = cv_text(c, ox-hb-20, -hb-30, 'X face', 'end');
    c = cv_text(c, ox, -hb-50, 'Y face', 'middle');
else
    c = cv_lead(c, gx(P.anc.uh-db/2), R.anE(1,2), ox-60, -400, {sprintf('anchors (shop): hooks at %g &#177; %g from the face,', P.anc.uh, P.tol.ua), sprintf('platinas level with the top flange &#177; %g', P.tol.za)});
    c = cv_lead(c, ox-hb, hb+40, ox-280, hb+200, {'outer face of the column', '(measure from the form)'});
end
c = cv_dim(c, ox-hb, -hb, gx(P.cb.uh), -hb, 40, sprintf('%g', P.cb.uh));
end

% ---------------------------------------------------------------------------
function svg = fig_ins(P, R)
% Placing the edge assembly from above. (a) Plan of the joint as the
% assembly comes down: everything already in place and the assembly at its
% final place; the hook tails are the circles. (b) to (d) The far side
% enlarged, with the clear gaps between the tails and the beam top bars, for
% the possible layouts of those bars.
hb = P.col.b/2;  gx = @(u) u - hb;  db = P.anc.db;  d = P.cb.db;  bm = P.bm;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
c = cv_new(-830, 2180, -420, 430, 0.66);

% ---- (a) plan --------------------------------------------------------------
xR = 330;  yE = 330;
c = cv_rect(c, -P.cb.b/2, -yE, P.cb.b/2, yE, 'conc');            % edge beams
c = cv_rect(c, hb, -P.cb.b/2, xR, P.cb.b/2, 'conc');             % beam in line
c = cv_rect(c, -hb, -hb, hb, hb, 'conc');
c = cv_rect(c, -400, -bm.b/2, -hb, bm.b/2, 'steel');
c = cv_seg(c, [-400 -hb], [0 0], 'cl');
for v = P.cb.v                                                   % edge beams, top bars
    c = cv_bar(c, [v v], [-yE yE], d, 'ex');
end
for v = P.cb.v                                                   % beam in line, top bars (VCM: the extra 2 under the corner ones)
    uh = P.cb.uh;  if v == 0, uh = P.cb.uh0; end
    c = cv_bar(c, [gx(uh+d/2) xR], [v v], d, 'ex');
    c = cv_circ(c, gx(uh+d/2), v, d, 'ex');                      % its hook going down
end
c = draw_ties_plan(c, P, 0, 0, 1);
for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, c = cv_circ(c, sx*xc, sy*xc, P.col.db, 'col'); end
end, end
for sx = [-1 1], for sy = [-1 1], c = cv_circ(c, sx*P.rod.p, sy*P.rod.p, P.rod.db, 'rodc'); end, end
c = draw_assembly_plan(c, P, R.anE, gx, 0);
c = cv_rect(c, gx(280), -112, gx(402), 112, 'zoomb');
c = cv_lead(c, gx(P.pl.t/2), -105, -460, -300, {'embed plate', '(closes the form)'});
c = cv_lead(c, gx(P.pl.t + P.pla.L/2), -P.pla.v0-P.pla.w+8, -460, -220, '2 platinas (blue)');
c = cv_lead(c, 0, R.anE(1,2), -460, 380, {sprintf('anchors %s%g (red); the dark circles', '&#216;', db), 'are the hook tails going down'});
c = cv_lead(c, -xc, 0, -460, 140, 'column bars &#216;16 (brown)');
c = cv_lead(c, -P.rod.p, P.rod.p, -460, 300, sprintf('rods of the steel column %s%g (green)', '&#216;', P.rod.db));
c = cv_lead(c, -hb+P.col.cover+5, -60, -460, -140, {sprintf('joint ties %s%g (purple),', '&#216;', P.hoop.db), sprintf('%d layers at z = %s', numel(P.hoop.z), num2str(P.hoop.z))});
c = cv_lead(c, 260, P.cb.v(end), 120, 405, {sprintf('beam in line (VCM): top bars %s%g (grey), 2 of them', '&#216;', d), 'doubled underneath, hooked down at the face'});
c = cv_lead(c, P.cb.v(end), -yE+20, -460, -380, {'edge beams: top bars (grey),', 'cross the joint lower down'});
c = cv_text(c, -810, 410, '(a) EDGE, PLAN FROM ABOVE', 'start');
c = cv_text(c, gx(341), -135, 'enlarged in (b) to (d)', 'middle');

% ---- (b) far side enlarged, plan; (c) section at the tails -------------------
k = 2.2;  u0 = 290;  u1 = 400;  v0 = 112;  X0 = 560;
T = @(u) X0 + (u - u0)*k;
c = cv_rect(c, T(u0), -v0*k*0.95, T(u1), v0*k*0.95, 'conc');
c = cv_seg(c, T(u1)*[1 1], v0*k*[-0.95 0.95], 'cj');
c = cv_bar(c, T(P.col.b - P.col.cover - P.col.dtie/2)*[1 1], v0*k*[-0.95 0.95], P.hoop.db*k, 'tie');
c = cv_circ(c, T(hb + xc), 0, P.col.db*k, 'col');
for v = P.cb.v
    c = cv_bar(c, [T(u0) T(u1)], [v v]*k, d*k, 'ex');
end
for j = 1:size(R.anE,1)
    for v = R.anE(j,2)*[-1 1]
        c = cv_bar(c, [T(u0) T(P.anc.uh-db/2)], [v v]*k, db*k, 'anch');
        c = cv_circ(c, T(P.anc.uh-db/2), v*k, db*k, 'tail');
        [m, i] = min(abs(P.cb.v - v));  g = m - (db + d)/2;
        st = 'ringok';  if g < 10, st = 'xhit'; end
        if v > 0
            c = cv_circ(c, T(P.anc.uh-db/2), v*k, (db + 8)*k, st);
            c = cv_text(c, T(P.anc.uh-db/2) + 24, (v + (P.cb.v(i)-v)/2)*k - 4, sprintf('%.0f', g), 'start');
        end
    end
end
c = cv_text(c, T(u0), v0*k + 18, '(b) far side, plan: tails (dark red) between the beam top bars', 'start');
c = cv_text(c, T(u1) + 4, -v0*k*0.95 + 12, 'far face', 'start');
c = cv_lead(c, T(P.col.b - P.col.cover - P.col.dtie/2), -v0*k*0.7, T(u0) - 10, -v0*k - 40, {'far tie leg (purple):', 'the tails pass behind it'});
% (c) section at the plane of the tails, looking at the plate
kz = 1.6;  Xc = 1420;  zz = @(z) z*kz + 160;
c = cv_rect(c, Xc - 150*kz, zz(-230), Xc + 150*kz, zz(40), 'conc');
c = cv_seg(c, Xc + [-150 150]*kz, zz(0)*[1 1], 'cl');
for z = P.hoop.z(P.hoop.z > -230)
    c = cv_seg(c, Xc + [-150 150]*kz, zz(z)*[1 1], 'hoopd');
end
for j = 1:size(R.anE,1)
    zt0 = R.anE(j,1) - R.dev.rb;  zt1 = zt0 - R.dev.tail;
    for v = R.anE(j,2)*[-1 1]
        c = cv_bar(c, Xc + v*kz*[1 1], [zz(zt0) zz(zt1)], db*kz, 'anc');
    end
end
for v = P.cb.v
    c = cv_circ(c, Xc + v*kz, zz(P.cb.zt(1)), d*kz, 'ex');
end
for v = P.cb.vm
    c = cv_circ(c, Xc + v*kz, zz(P.cb.zt(1) - P.cb.dz), d*kz, 'ex');
end
c = cv_text(c, Xc - 150*kz, zz(40) + 18, '(c) section at the tails, looking at the plate', 'start');
c = cv_lead(c, Xc + 94*kz, zz(P.cb.zt(1) - P.cb.dz), Xc + 160*kz, zz(-150), {'VCM: corner bar and the', 'bar in contact under it'});
c = cv_lead(c, Xc, zz(P.cb.zt(1)), Xc - 160*kz, zz(-200), {sprintf('VCM top bars in section, z = %g', P.cb.zt(1)), '(the beam in line)'});
c = cv_lead(c, Xc - 150*kz, zz(P.hoop.z(1)), Xc - 160*kz, zz(-110), {'dashed: joint ties,', 'in front of the tails'});
c = cv_lead(c, Xc + R.anE(1,2)*kz, zz(-120), Xc + 160*kz, zz(-60), {'hook tails (red),', '4 per assembly'});
c = cv_text(c, X0, -v0*k - 85, 'Numbers: clear gap, mm, between a hook tail and the nearest beam top bar (the lower half is the same). Red ring: under 10 mm.', 'start');
svg = cv_end(c);
end

function c = draw_ties_plan(c, P, ox, oy, s)
% one layer of joint ties in plan: four straight ties with 135 degree hooks
hb = P.col.b/2;  xc = hb - P.col.cover - P.col.dtie - P.col.db/2;  xh = xc + P.col.db/2 + P.hoop.db/2;
e = 6*P.hoop.db + 20;  K = xh*[-1 -1; 1 -1; 1 1; -1 1];
for i = 1:4
    p1 = K(i,:);  p2 = K(mod(i,4)+1,:);
    h1 = p1 - sign(p1)*e/sqrt(2);  h2 = p2 - sign(p2)*e/sqrt(2);
    c = cv_bar(c, ox + s*[h1(1) p1(1) p2(1) h2(1)], oy + s*[h1(2) p1(2) p2(2) h2(2)], P.hoop.db*s, 'tie');
end
end

% ===========================================================================
%  geometry and drawing tools
% ===========================================================================
function [x, z] = hook(x0, xo, z0, d, dn)
% Axis of a bar from x0 to a 90 degree hook with its outside face at xo.
% Inside bend diameter 6 d, tail 12 d, downwards (dn = -1) or upwards (+1).
sg = sign(xo - x0);  r = 3.5*d;  t = linspace(0, pi/2, 10);
xb = xo - sg*(d/2 + r);
x = [x0, xb + sg*r*sin(t), xo - sg*d/2];
z = [z0, z0 + dn*r*(1 - cos(t)), z0 + dn*(r + 12*d)];
end

function c = cv_new(x0, x1, y0, y1, s)
c.s = s;  c.x0 = x0;  c.y1 = y1;  c.W = (x1-x0)*s;  c.H = (y1-y0)*s;  c.b = {};
end

function [px, py] = cv_p(c, x, y)
px = (x - c.x0)*c.s;  py = (c.y1 - y)*c.s;
end

function a = sty(name)
switch name
    case 'conc',   a = 'fill="#ece9e2" stroke="#6b6b6b" stroke-width="1"';
    case 'old',    a = 'fill="#cfc9bb" stroke="#6b6b6b" stroke-width="1"';
    case 'slab',   a = 'fill="#f6f4ee" stroke="#a5a5a5" stroke-width="0.7"';
    case 'hid',    a = 'fill="none" stroke="#8a8a8a" stroke-width="0.8" stroke-dasharray="6 4"';
    case 'hidw',   a = 'fill="none" stroke="#ffffff" stroke-width="1" stroke-dasharray="5 3"';
    case 'steel',  a = 'fill="#a9bdd1" stroke="#1f3347" stroke-width="1"';
    case 'web',    a = 'fill="#dbe4ed" stroke="#1f3347" stroke-width="0.6"';
    case 'plate',  a = 'fill="#34506b" stroke="#142433" stroke-width="0.8"';
    case 'platet', a = 'fill="#34506b" fill-opacity="0.45" stroke="#142433" stroke-width="0.8"';
    case 'hoopr',  a = 'fill="none" stroke="#7d3c98" stroke-width="3" rx="6"';
    case 'tribx',  a = 'fill="#e67e22" fill-opacity="0.30" stroke="#b9620f" stroke-width="1"';
    case 'triby',  a = 'fill="#2e86c1" fill-opacity="0.30" stroke="#1f5f8b" stroke-width="1"';
    case 'strut1', a = 'fill="#1e8449" fill-opacity="0.22" stroke="none"';
    case 'strut2', a = 'fill="#e67e22" fill-opacity="0.30" stroke="none"';
    case 'vent',   a = 'fill="#ffffff" stroke="#142433" stroke-width="0.8"';
    case 'tail',   a = 'fill="#7b241c" stroke="#ffffff" stroke-width="0.8"';
    case 'anc',    a = 'fill="#c0392b" stroke="#ffffff" stroke-width="0.8"';
    case 'new',    a = 'fill="#1e8449" stroke="#ffffff" stroke-width="0.8"';
    case 'ex',     a = 'fill="#5d6d7e" stroke="#ffffff" stroke-width="0.8"';
    case 'col',    a = 'fill="#9a6b00" stroke="#ffffff" stroke-width="0.8"';
    case 'hoop',   a = 'fill="#7d3c98" stroke="none"';
    case 'rodc',   a = 'fill="#117a65" stroke="#ffffff" stroke-width="0.8"';
    case 'mark',   a = 'fill="#ffffff" stroke="#111111" stroke-width="1.6"';
    case 'weldfill', a = 'fill="#e3141e" stroke="none"';
    case 'zovl',   a = 'fill="#1e8449" fill-opacity="0.45" stroke="#1e8449" stroke-width="0.8"';
    case 'zgap',   a = 'fill="#e67e22" fill-opacity="0.55" stroke="#b9620f" stroke-width="0.8"';
    case 'zstrip', a = 'fill="#2e86c1" fill-opacity="0.22" stroke="#1f5f8b" stroke-width="0.8"';
    case 'ringok', a = 'fill="none" stroke="#111111" stroke-width="1.6"';
    case 'zoomb',  a = 'fill="none" stroke="#111111" stroke-width="1.2" stroke-dasharray="7 4"';
    case 'ztol',   a = 'fill="#1e8449" fill-opacity="0.28" stroke="#1e8449" stroke-width="0.8" stroke-dasharray="3 2"';
    case 'tailr',  a = 'fill="#c0392b" fill-opacity="0.85" stroke="#7b241c" stroke-width="0.6"';
    case 'exl',    a = 'fill="#5d6d7e" fill-opacity="0.35" stroke="#5d6d7e" stroke-width="0.6"';
    case 'markr',  a = 'fill="#ffffff" stroke="#e3141e" stroke-width="2.2"';
    case 'xhit',   a = 'fill="none" stroke="#e3141e" stroke-width="2.2"';
    case 'zbrg',   a = 'fill="#7f8c8d" fill-opacity="0.30" stroke="#555555" stroke-width="0.8" stroke-dasharray="4 3"';
    otherwise,     a = 'fill="none" stroke="#000"';
end
end

function a = lsty(name)
switch name
    case 'dim',   a = 'stroke="#222222" stroke-width="0.7"';
    case 'tick',  a = 'stroke="#222222" stroke-width="1.3"';
    case 'cl',    a = 'stroke="#555555" stroke-width="0.7" stroke-dasharray="12 3 2 3"';
    case 'cj',    a = 'stroke="#111111" stroke-width="1.8" stroke-dasharray="10 5"';
    case 'crack', a = 'stroke="#d35400" stroke-width="1.8" stroke-dasharray="8 4"';
    case 'stir',  a = 'stroke="#aab3bc" stroke-width="1"';
    case 'hoop',  a = 'stroke="#7d3c98" stroke-width="3"';
    case 'weld',  a = 'stroke="#f1c40f" stroke-width="2.5"';
    case 'wside', a = 'stroke="#e3141e" stroke-width="4"';
    case 'lead',  a = 'stroke="#222222" stroke-width="0.6"';
    case 'limit', a = 'stroke="#111111" stroke-width="2.2"';
    case 'hoopd', a = 'stroke="#7d3c98" stroke-width="1.6" stroke-dasharray="6 4"';
    otherwise,    a = 'stroke="#000000" stroke-width="1"';
end
end

function [col, dash, op] = bsty(name)
dash = '';  op = 1;
switch name
    case 'anc',    col = '#c0392b';
    case 'anch',   col = '#c0392b';  op = 0.45;
    case 'new',    col = '#1e8449';
    case 'ex',     col = '#5d6d7e';
    case 'exh',    col = '#5d6d7e';  op = 0.35;
    case 'col',    col = '#9a6b00';
    case 'colh',   col = '#9a6b00';  op = 0.55;
    case 'rod',    col = '#117a65';  op = 0.55;
    case 'steelc', col = '#34506b';
    case 'tie',    col = '#7d3c98';
    otherwise,     col = '#000000';
end
end

function c = cv_rect(c, x0, y0, x1, y1, st)
[px, py] = cv_p(c, min(x0,x1), max(y0,y1));
c.b{end+1} = sprintf('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" %s/>', ...
    px, py, abs(x1-x0)*c.s, abs(y1-y0)*c.s, sty(st));
end

function c = cv_poly(c, x, y, st)
[px, py] = cv_p(c, x, y);
c.b{end+1} = sprintf('<polygon points="%s" %s/>', sprintf('%.1f,%.1f ', [px(:)'; py(:)']), sty(st));
end

function c = cv_circ(c, x, y, d, st)
[px, py] = cv_p(c, x, y);
c.b{end+1} = sprintf('<circle cx="%.1f" cy="%.1f" r="%.1f" %s/>', px, py, max(d*c.s/2, 1.5), sty(st));
end

function c = cv_seg(c, x, y, st)
[px, py] = cv_p(c, x, y);
c.b{end+1} = sprintf('<polyline points="%s" fill="none" %s/>', sprintf('%.1f,%.1f ', [px(:)'; py(:)']), lsty(st));
end

function c = cv_bar(c, x, y, d, st)
[px, py] = cv_p(c, x, y);
[col, dash, op] = bsty(st);
c.b{end+1} = sprintf('<polyline points="%s" fill="none" stroke="%s" stroke-opacity="%.2f" stroke-width="%.1f" stroke-linejoin="round"%s/>', ...
    sprintf('%.1f,%.1f ', [px(:)'; py(:)']), col, op, max(d*c.s, 1.2), dash);
end

function c = cv_text(c, x, y, str, anchor, rot)
[px, py] = cv_p(c, x, y);
tr = '';
if nargin > 5, tr = sprintf(' transform="rotate(%.1f %.1f %.1f)"', rot, px, py); end
c.b{end+1} = sprintf('<text x="%.1f" y="%.1f" font-size="11.5" text-anchor="%s" fill="#111111"%s>%s</text>', px, py, anchor, tr, str);
end

function c = cv_dim(c, x1, y1, x2, y2, off, lab, sh)
% Dimension between two points; off (mm) moves the line to the left of the
% direction 1 -> 2 when positive. sh (px) slides the text along the line.
if nargin < 7 || isempty(lab), lab = sprintf('%g', round(hypot(x2-x1, y2-y1))); end
if nargin < 8, sh = 0; end
d = hypot(x2-x1, y2-y1);  ux = (x2-x1)/d;  uy = (y2-y1)/d;  nx = -uy;  ny = ux;
ax = x1 + off*nx;  ay = y1 + off*ny;  bx = x2 + off*nx;  by = y2 + off*ny;
sg = sign(off);  g = 3/c.s;  e = 4/c.s;
if abs(off) > g
    c = cv_seg(c, [x1+sg*g*nx, ax+sg*e*nx], [y1+sg*g*ny, ay+sg*e*ny], 'dim');
    c = cv_seg(c, [x2+sg*g*nx, bx+sg*e*nx], [y2+sg*g*ny, by+sg*e*ny], 'dim');
end
c = cv_seg(c, [ax bx], [ay by], 'dim');
t = 3.5/c.s;  tx = (ux+nx)/sqrt(2)*t;  ty = (uy+ny)/sqrt(2)*t;
c = cv_seg(c, [ax-tx ax+tx], [ay-ty ay+ty], 'tick');
c = cv_seg(c, [bx-tx bx+tx], [by-ty by+ty], 'tick');
[pm, qm] = cv_p(c, (ax+bx)/2, (ay+by)/2);
ang = atan2(-uy, ux)*180/pi;
if ang >= 90, ang = ang - 180; end
if ang < -90, ang = ang + 180; end
upx = sin(ang*pi/180);  upy = -cos(ang*pi/180);
pm = pm + 3.5*upx + sh*cos(ang*pi/180);  qm = qm + 3.5*upy + sh*sin(ang*pi/180);
c.b{end+1} = sprintf('<text x="%.1f" y="%.1f" font-size="11" text-anchor="middle" fill="#111111" transform="rotate(%.1f %.1f %.1f)">%s</text>', ...
    pm, qm, ang, pm, qm, lab);
end

function c = cv_lead(c, x, y, tx, ty, str)
% Leader from the point (x, y) to a text at (tx, ty); str may be a cell of lines
if ~iscell(str), str = {str}; end
c = cv_seg(c, [x tx], [y ty], 'lead');
[px, py] = cv_p(c, x, y);
c.b{end+1} = sprintf('<circle cx="%.1f" cy="%.1f" r="2" fill="#222222"/>', px, py);
[qx, qy] = cv_p(c, tx, ty);
if tx >= x, an = 'start'; dx = 4; else, an = 'end'; dx = -4; end
if ty < y, qy = qy + 8; end
for i = 1:numel(str)
    c.b{end+1} = sprintf('<text x="%.1f" y="%.1f" font-size="11.5" text-anchor="%s" fill="#111111">%s</text>', ...
        qx+dx, qy+4+13*(i-1), an, str{i});
end
end

function c = cv_arrow(c, x1, y1, x2, y2, col)
[px, py] = cv_p(c, [x1 x2], [y1 y2]);
a = atan2(py(2)-py(1), px(2)-px(1));  h = 9;
hx = px(2) - h*cos(a) + [0, -h*0.45*sin(a), 0,  h*0.45*sin(a)];
hy = py(2) - h*sin(a) + [0,  h*0.45*cos(a), 0, -h*0.45*cos(a)];
c.b{end+1} = sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="2.4"/>', ...
    px(1), py(1), px(2)-h*cos(a), py(2)-h*sin(a), col);
c.b{end+1} = sprintf('<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="%s"/>', ...
    px(2), py(2), hx(2), hy(2), hx(4), hy(4), col);
end

function svg = cv_end(c)
svg = sprintf(['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.0f %.0f" width="%.0f" height="%.0f" ' ...
    'font-family="Helvetica, Arial, sans-serif">\n<rect width="%.0f" height="%.0f" fill="#ffffff"/>\n%s\n</svg>\n'], ...
    c.W, c.H, c.W, c.H, c.W, c.H, strjoin(c.b, sprintf('\n')));
end
