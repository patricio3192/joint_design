function F = ca_draw(P, R)
% CA_DRAW  Drawings of the cantilever anchorage as SVG text.
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
F.cones      = fig_cones(P, R);
F.dev_edge   = fig_devel(P, R, 1);
F.dev_cor    = fig_devel(P, R, 2);
F.hoops      = fig_hoops(P, R);
F.tie        = fig_tie(P);
F.wf_plate   = fig_wf_plate(P, R);
F.wf_paths   = fig_wf_paths(P, R);
end

% ===========================================================================
%  figures
% ===========================================================================
function svg = fig_elev(P, R, kase, typ)
% Section along the axis of the steel beam. typ 'A': bars under the lug
% (edge beam, corner beam X). typ 'B': bars over the lug (corner beam Y).
hb = P.col.b/2;  bm = P.bm;  gx = @(u) u - hb;
ti = 1 + (typ == 'B');  tj = 3 - ti;
za = R.zanc(ti);  zo = R.zanc(tj);  edge = strcmp(kase, 'edge');
ztop = P.col.top;  zcj = P.col.cj;  xL = -640;  xR = 760;  zB = -520;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
xh = hb - P.col.cover - P.col.dtie/2;
c = cv_new(-760, 900, -590, 330, 0.62);

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

% steel beam and embedded plates
c = cv_rect(c, xL, -bm.h+bm.tf, -hb, -bm.tf, 'web');
c = cv_rect(c, xL, -bm.tf, -hb, 0, 'steel');
c = cv_rect(c, xL, -bm.h, -hb, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -hb, P.pl.zb, gx(P.pl.t), P.pl.zt, 'plate');
zl = -bm.tf/2;
c = cv_rect(c, gx(P.pl.t), zl-P.lug.t/2, gx(P.pl.t+P.lug.L), zl+P.lug.t/2, 'plate');
zs = -bm.h + bm.tf/2;
c = cv_rect(c, gx(P.pl.t), zs-P.stf.t/2, gx(P.pl.t+P.stf.L), zs+P.stf.t/2, 'plate');

% column bars, with the hooks required at the top
zc = ztop - P.col.cover - P.col.db/2;
c = cv_bar(c, [-xc -xc], [zB zc-20], P.col.db, 'col');
c = cv_bar(c, [ xc  xc], [zB zc-36], P.col.db, 'col');
[x, z] = hook(zB, zc+P.col.db/2, 0, P.col.db, 1);
c = cv_bar(c, -xc + z(2:end), x(2:end) - 20, P.col.db, 'colh');
c = cv_bar(c,  xc - z(2:end), x(2:end) - 36, P.col.db, 'colh');

% hoops
for z = [P.hoop.z P.hoop.ztop]
    c = cv_seg(c, [-xh xh], [z z], 'hoop');
    c = cv_circ(c, -xh, z, P.hoop.db, 'hoop');
    c = cv_circ(c,  xh, z, P.hoop.db, 'hoop');
end

% bars of the concrete beam in line
zt = P.cb.zt(ti);  zb = P.cb.zb(ti);
c = cv_bar(c, [xR gx(P.Lb.uh+10)], [zb zb], P.cb.db, 'ex');
[x, z] = hook(xR, gx(P.Lb.uh), zt, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'ex');
if ~isempty(P.Lb.v)
    [x, z] = hook(xR, gx(P.Lb.uh), P.Lb.z(ti), P.Lb.db, -1);
    c = cv_bar(c, x, z, P.Lb.db, 'new');
end
% anchor rods of the steel column, behind the section
for x = [-1 1]*P.rod.p
    c = cv_bar(c, [x x], [zB ztop+60], P.rod.db, 'rod');
end

% bars that cross the section
for v = P.cb.v
    c = cv_circ(c, v, P.cb.zt(tj), P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zb(tj), P.cb.db, 'ex');
end
if strcmp(kase, 'corner')
    for v = P.Lb.v, c = cv_circ(c, v, P.Lb.z(tj), P.Lb.db, 'new'); end
    for v = P.anc.v
        c = cv_circ(c, v, zo, P.anc.db, 'anc');
        if typ == 'A'
            c = cv_bar(c, [v v], [zo-R.dev.rb, R.dev.zend(tj)], P.anc.db, 'anch');
        end
    end
end

% anchor bars
[x, z] = hook(gx(P.pl.t), gx(P.anc.uh), za, P.anc.db, -1);
c = cv_bar(c, x, z, P.anc.db, 'anc');
if edge
    [x, z] = hook(gx(P.pl.t), gx(P.anc.uhA), R.zanc(1), P.anc.db, -1);
    c = cv_bar(c, x, z, P.anc.db, 'anc');
end
uk = P.anc.uh;  if edge, uk = P.anc.uhA; end

% dimensions
c = cv_dim(c, -hb, ztop, gx(P.pl.t), ztop, 45, sprintf('%g', P.pl.t), -14);
c = cv_dim(c, gx(P.pl.t), ztop, gx(P.pl.t+P.lug.L), ztop, 45);
if edge
    c = cv_dim(c, gx(P.pl.t+P.lug.L), ztop, gx(uk), ztop, 45);
    c = cv_dim(c, gx(uk), ztop, gx(P.anc.uh), ztop, 45);
else
    c = cv_dim(c, gx(P.pl.t+P.lug.L), ztop, gx(P.anc.uh), ztop, 45);
end
c = cv_dim(c, gx(P.anc.uh), ztop, hb, ztop, 45);
c = cv_dim(c, gx(P.pl.t), ztop, gx(uk), ztop, 100, sprintf('%g  (shortest hook embedment)', uk - P.pl.t));
c = cv_dim(c, -hb, ztop, hb, ztop, 155);
c = cv_dim(c, xR, -P.cb.h, xR, 0, -35);
c = cv_dim(c, xR, 0, xR, P.slab.t, -35);
c = cv_dim(c, xR, 0, xR, ztop, -80, sprintf('%g  (pedestal)', ztop));
c = cv_dim(c, xL, P.pl.zb, xL, -bm.h, 35);
c = cv_dim(c, xL, -bm.h, xL, 0, 35);
c = cv_dim(c, xL, 0, xL, P.pl.zt, 35);
c = cv_dim(c, xL, zs, xL, zl, 85, sprintf('%g  (lever arm)', R.ho));
zz = [zcj sort(P.hoop.z) 0];
for i = 1:numel(zz)-1
    c = cv_dim(c, hb, zz(i), hb, zz(i+1), -45);
end
c = cv_dim(c, 95, zcj, 95, min(R.dev.zend), 1);

% labels
c = cv_lead(c, gx(P.pl.t/2), -215, -330, -300, sprintf('Embed plate PL %gx%gx%g', P.pl.t, P.pl.w, P.pl.zt-P.pl.zb));
c = cv_lead(c, gx(P.pl.t+P.stf.L/2), zs-6, -330, -345, sprintf('Bottom stiffener PL %gx%gx%g', P.stf.t, P.stf.w, P.stf.L));
c = cv_lead(c, gx(P.pl.t+P.lug.L/2), zl+6, -300, 205, {sprintf('Lug PL %gx%gx%g', P.lug.t, P.lug.w, P.lug.L), 'tension + shear key'});
if edge
    s1 = {sprintf('2 %s%g under the lug (hook at %g)', '&#216;', P.anc.db, P.anc.uhA), sprintf('+ 2 %s%g over the lug (hook at %g)', '&#216;', P.anc.db, P.anc.uh)};
elseif typ == 'A'
    s1 = {sprintf('2 %s%g welded under the lug', '&#216;', P.anc.db), sprintf('axis %+.0f, tail 12 db = %g', za, R.dev.tail)};
else
    s1 = {sprintf('2 %s%g welded over the lug', '&#216;', P.anc.db), sprintf('axis %+.0f, tail 12 db = %g', za, R.dev.tail)};
end
c = cv_lead(c, 40, za, 250, 290, s1);
c = cv_lead(c, P.rod.p, 70, 470, 225, sprintf('rods of the steel column: 4 %s%g, 180%s hooks', '&#216;', P.rod.db, '&#176;'));
if edge, nt = numel(P.cb.ve); else, nt = numel(P.cb.v); end
c = cv_lead(c, 640, zt+4, 660, 165, sprintf('%d %s%g top bars, hooked down', nt, '&#216;', P.cb.db));
c = cv_lead(c, -xh, P.hoop.z(end), -330, -400, {sprintf('%d layers of 4 straight ties %s%g', numel(P.hoop.z), '&#216;', P.hoop.db), 'plus one closed tie above the anchors'});
c = cv_lead(c, -40, zc-20, -330, 265, 'Column bars: 90&#176; hooks at the top (verify)');
if strcmp(kase, 'corner')
    c = cv_lead(c, P.anc.v(end), zo, 250, 245, sprintf('%d %s%g anchors of the other beam, in section', numel(P.anc.v), '&#216;', P.anc.db));
end
c = cv_text(c, hb+55, zcj-18, 'cold joint: column cast earlier', 'start');
c = cv_text(c, -450, -105, bm.name, 'middle');
c = cv_text(c, 580, -185, sprintf('Concrete beam %gx%g', P.cb.b/10, P.cb.h/10), 'middle');
c = cv_text(c, 0, -470, 'Hardened pedestal', 'middle');
c = cv_text(c, -450, 62, sprintf('Composite slab %g', P.slab.t), 'middle');
c = cv_text(c, xR+95, -4, '&#177;0', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_front(P, R)
% Edge column seen from outside, looking along the steel beam
hb = P.col.b/2;  bm = P.bm;
za = R.zanc(1);  ztop = P.col.top;  zcj = P.col.cj;  yE = 540;  zB = -520;
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

% bars of the edge beams, column bars, hoops
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
for v = P.cb.ve
    c = cv_bar(c, [v v], [P.cb.zt(1), P.cb.zt(1)-15.5*P.cb.db], P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zb(1), P.cb.db, 'ex');
end
for v = P.Lb.v
    c = cv_bar(c, [v v], [P.Lb.z(1), P.Lb.z(1)-15.5*P.Lb.db], P.Lb.db, 'new');
end

% embed plate (translucent), beam section, hidden plates
c = cv_rect(c, -P.pl.w/2, P.pl.zb, P.pl.w/2, P.pl.zt, 'platet');
c = cv_rect(c, -bm.b/2, -bm.tf, bm.b/2, 0, 'steel');
c = cv_rect(c, -bm.b/2, -bm.h, bm.b/2, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -bm.tw/2, -bm.h+bm.tf, bm.tw/2, -bm.tf, 'steel');
zl = -bm.tf/2;  zs = -bm.h + bm.tf/2;
c = cv_rect(c, -P.lug.w/2, zl-P.lug.t/2, P.lug.w/2, zl+P.lug.t/2, 'hidw');
c = cv_rect(c, -P.stf.w/2, zs-P.stf.t/2, P.stf.w/2, zs+P.stf.t/2, 'hidw');

% anchors: sections behind the plate, tails at the far side
for v = P.anc.v
    c = cv_bar(c, [v v]+3, [za-R.dev.rb, R.dev.zend(1)], P.anc.db, 'anch');
    c = cv_bar(c, [v v]-3, [R.zanc(2)-R.dev.rb, R.dev.zend(2)], P.anc.db, 'anch');
    c = cv_circ(c, v, za, P.anc.db, 'anc');
    c = cv_circ(c, v, R.zanc(2), P.anc.db, 'anc');
end

% dimensions
v = P.anc.v;
for i = 1:numel(v)-1, c = cv_dim(c, v(i), ztop, v(i+1), ztop, 45); end
c = cv_dim(c, -P.lug.w/2, ztop, P.lug.w/2, ztop, 100, sprintf('%g  (lug)', P.lug.w));
c = cv_dim(c, -P.pl.w/2, ztop, P.pl.w/2, ztop, 155, sprintf('%g  (plate)', P.pl.w));
vv = sort([P.cb.ve P.anc.v]);
for i = 1:numel(vv)-1, c = cv_dim(c, vv(i), zB, vv(i+1), zB, -40); end
c = cv_dim(c, -xc, zB, xc, zB, -80, sprintf('%g  (column bars)', 2*xc));
c = cv_dim(c, -hb, zB, hb, zB, -120);
c = cv_dim(c, yE, P.pl.zb, yE, -bm.h, -35);
c = cv_dim(c, yE, -bm.h, yE, 0, -35);
c = cv_dim(c, yE, 0, yE, P.pl.zt, -35);
c = cv_dim(c, yE, P.pl.zb, yE, P.pl.zt, -85, sprintf('%g  (plate)', P.pl.zt-P.pl.zb));
c = cv_dim(c, -yE, -P.cb.h, -yE, 0, 35);
c = cv_dim(c, -yE, 0, -yE, ztop, 35, sprintf('%g', ztop));

% labels
c = cv_lead(c, v(1), za, -330, 215, {sprintf('4 %s%g anchors: 2 under and 2 over', '&#216;', P.anc.db), 'the lug, same vertical line'});
c = cv_lead(c, v(end), -200, 330, 215, {'tails of the anchor hooks', 'at the far side of the column'});
c = cv_lead(c, 0, -300, -330, -420, {'mid-face column bar', '(8 bars in the pedestal)'});
c = cv_lead(c, P.cb.ve(end), -150, 330, -420, {sprintf('%d %s%g top bars of the', numel(P.cb.ve), '&#216;', P.cb.db), 'beam in line, hooked down'});
c = cv_lead(c, P.rod.p, 60, 430, 250, sprintf('rods of the steel column %s%g', '&#216;', P.rod.db));
c = cv_lead(c, 330, P.cb.zt(2), 430, 165, 'top bars of the edge beams');
c = cv_lead(c, -P.pl.w/2+8, -120, -430, 165, sprintf('Embed plate PL %gx%gx%g', P.pl.t, P.pl.w, P.pl.zt-P.pl.zb));
c = cv_text(c, -hb-50, zcj-16, 'cold joint', 'end');
c = cv_text(c, 0, -470, 'Hardened pedestal', 'middle');
c = cv_text(c, -400, -185, sprintf('Edge beam %gx%g', P.cb.b/10, P.cb.h/10), 'middle');
c = cv_text(c, 400, -185, sprintf('Edge beam %gx%g', P.cb.b/10, P.cb.h/10), 'middle');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_plan(P, R, kase)
% Plan at the level of the anchors. Steel beam X towards -x; in the corner
% column a second steel beam Y towards -y.
hb = P.col.b/2;  bm = P.bm;  gx = @(u) u - hb;  cor = strcmp(kase, 'corner');
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

% steel beams (top flange), embed plates
c = cv_rect(c, xL, -bm.b/2, -hb, bm.b/2, 'steel');
c = cv_seg(c, [xL -hb], [0 0], 'cl');
if cor
    c = cv_rect(c, -bm.b/2, yB, bm.b/2, -hb, 'steel');
    c = cv_seg(c, [0 0], [yB -hb], 'cl');
end

% bars of the crossing beam (second layer), then of the beam in line
for v = P.cb.v
    if cor, c = cv_bar(c, [v v], [gx(P.Lb.uh+P.cb.db/2) yT], P.cb.db, 'ex');
    else,   c = cv_bar(c, [v v], [yB yT], P.cb.db, 'ex'); end
end
if cor
    for v = P.Lb.v, c = cv_bar(c, [v v], [gx(P.Lb.uh+P.Lb.db/2) yT], P.Lb.db, 'new'); end
end
if cor, vb = P.cb.v; else, vb = P.cb.ve; end
for v = vb, c = cv_bar(c, [gx(P.Lb.uh+P.cb.db/2) xR], [v v], P.cb.db, 'ex'); end
for v = P.Lb.v, c = cv_bar(c, [gx(P.Lb.uh+P.Lb.db/2) xR], [v v], P.Lb.db, 'new'); end

% hoop, column bars, anchor rods of the steel column
c = cv_rect(c, -xh, -xh, xh, xh, 'hoopr');
for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, c = cv_circ(c, sx*xc, sy*xc, P.col.db, 'col'); end
end, end
for sx = [-1 1], for sy = [-1 1], c = cv_circ(c, sx*P.rod.p, sy*P.rod.p, P.rod.db, 'rodc'); end, end

% assembly X: bars under the lug
for v = P.anc.v
    c = cv_bar(c, [gx(P.pl.t) gx(P.anc.uh)], [v v], P.anc.db, 'anc');
    c = cv_circ(c, gx(P.anc.uh-P.anc.db/2), v, P.anc.db, 'tail');
    if ~cor, c = cv_circ(c, gx(P.anc.uhA-P.anc.db/2), v, P.anc.db, 'tail'); end
end
c = cv_rect(c, gx(P.pl.t), -P.lug.w/2, gx(P.pl.t+P.lug.L), P.lug.w/2, 'platet');
c = cv_rect(c, -hb, -P.pl.w/2, gx(P.pl.t), P.pl.w/2, 'plate');
if cor
    % assembly Y: bars over the lug
    c = cv_rect(c, -P.lug.w/2, gx(P.pl.t), P.lug.w/2, gx(P.pl.t+P.lug.L), 'platet');
    for v = P.anc.v
        c = cv_bar(c, [v v], [gx(P.pl.t) gx(P.anc.uh)], P.anc.db, 'anc');
        c = cv_circ(c, v, gx(P.anc.uh-P.anc.db/2), P.anc.db, 'tail');
    end
    c = cv_rect(c, -P.pl.w/2, -hb, P.pl.w/2, gx(P.pl.t), 'plate');
end

% dimensions
c = cv_dim(c, gx(P.pl.t), hb, gx(P.pl.t+P.lug.L), hb, 45, sprintf('%g', P.lug.L), 12);
if ~cor
    c = cv_dim(c, gx(P.pl.t+P.lug.L), hb, gx(P.anc.uhA), hb, 45);
    c = cv_dim(c, gx(P.anc.uhA), hb, gx(P.anc.uh), hb, 45);
else
    c = cv_dim(c, gx(P.pl.t+P.lug.L), hb, gx(P.anc.uh), hb, 45);
end
c = cv_dim(c, gx(P.anc.uh), hb, hb, hb, 45);
c = cv_dim(c, -hb, hb, hb, hb, 100);
v = P.anc.v;
for i = 1:numel(v)-1, c = cv_dim(c, -hb, v(i), -hb, v(i+1), 60); end
c = cv_dim(c, -hb, -P.pl.w/2, -hb, P.pl.w/2, 115, sprintf('%g  (plate)', P.pl.w));
c = cv_dim(c, xR, -P.cb.b/2, xR, P.cb.b/2, -35);
c = cv_dim(c, -P.cb.b/2, yT, P.cb.b/2, yT, 35);
c = cv_dim(c, -hb, -hb, -hb, hb, 175);
if cor
    for i = 1:numel(v)-1, c = cv_dim(c, v(i), -hb, v(i+1), -hb, -60); end
    c = cv_dim(c, hb, gx(P.pl.t), hb, gx(P.anc.uh), -45, sprintf('%g', P.anc.uh - P.pl.t));
end

% labels
c = cv_text(c, -470, 66, [bm.name ' (beam X)'], 'middle');
c = cv_lead(c, gx(P.pl.t+P.lug.L/2), -P.lug.w/2+6, -420, -170, sprintf('Lug PL %gx%gx%g', P.lug.t, P.lug.w, P.lug.L));
if cor, sa = sprintf('2 %s%g anchors of beam X, under the lug', '&#216;', P.anc.db);
else,   sa = sprintf('4 %s%g anchors: 2 under + 2 over the lug', '&#216;', P.anc.db); end
c = cv_lead(c, gx(P.anc.uh-P.anc.db/2), v(end), 240, 330, {sa, 'dots: hook tails going down'});
c = cv_lead(c, 640, vb(end), 680, 235, sprintf('%d %s%g top bars', numel(vb), '&#216;', P.cb.db));
c = cv_lead(c, P.rod.p, -P.rod.p, 560, -250, {sprintf('4 rods %s%g of the', '&#216;', P.rod.db), 'steel column base plate'});
c = cv_lead(c, xh, -xh+40, 330, -200, sprintf('hoops %s%g', '&#216;', P.hoop.db));
c = cv_lead(c, xc, -xc, 300, -330, sprintf('column 8 %s%g', '&#216;', P.col.db));
if cor
    c = cv_text(c, 62, -470, [bm.name ' (beam Y)'], 'start');
    c = cv_lead(c, v(1), 60, -420, 330, {sprintf('2 %s%g anchors of beam Y', '&#216;', P.anc.db), 'over the lug, above the bars of X'});
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
% Shop assembly, side view. u = 0 at the outer face of the embed plate.
bm = P.bm;  za = R.zanc(1);  zb = R.zanc(2);  uL = -170;
c = cv_new(-330, 560, -380, 150, 1.0);
c = cv_rect(c, uL, -bm.h+bm.tf, 0, -bm.tf, 'web');
c = cv_rect(c, uL, -bm.tf, 0, 0, 'steel');
c = cv_rect(c, uL, -bm.h, 0, -bm.h+bm.tf, 'steel');
c = cv_rect(c, 0, P.pl.zb, P.pl.t, P.pl.zt, 'plate');
zl = -bm.tf/2;  zs = -bm.h + bm.tf/2;
c = cv_rect(c, P.pl.t, zl-P.lug.t/2, P.pl.t+P.lug.L, zl+P.lug.t/2, 'plate');
c = cv_rect(c, P.pl.t, zs-P.stf.t/2, P.pl.t+P.stf.L, zs+P.stf.t/2, 'plate');
[x, z] = hook(P.pl.t, P.anc.uhA, za, P.anc.db, -1);
c = cv_bar(c, x, z, P.anc.db, 'anc');
[x, z] = hook(P.pl.t, P.anc.uh, zb, P.anc.db, -1);
c = cv_bar(c, x, z, P.anc.db, 'anc');

c = cv_dim(c, 0, P.pl.zb, P.pl.t, P.pl.zb, -75, sprintf('%g', P.pl.t), -14);
c = cv_dim(c, P.pl.t, P.pl.zb, P.pl.t+P.lug.L, P.pl.zb, -75, sprintf('%g', P.lug.L), 12);
c = cv_dim(c, P.pl.t+P.lug.L, P.pl.zb, P.anc.uhA, P.pl.zb, -75);
c = cv_dim(c, P.anc.uhA, P.pl.zb, P.anc.uh, P.pl.zb, -75);
c = cv_dim(c, 0, P.pl.zb, P.anc.uhA, P.pl.zb, -105);
c = cv_dim(c, 0, P.pl.zb, P.anc.uh, P.pl.zb, -135);
c = cv_dim(c, P.anc.uh, R.dev.zend(2), P.anc.uh, zb+P.anc.db/2, -30);
c = cv_dim(c, P.anc.uh, R.dev.zend(2), P.anc.uh, zb-R.dev.rb, -70, sprintf('%g  (12 db)', R.dev.tail));
c = cv_dim(c, uL, P.pl.zb, uL, -bm.h, 30);
c = cv_dim(c, uL, -bm.h, uL, 0, 30);
c = cv_dim(c, uL, 0, uL, P.pl.zt, 30);
c = cv_dim(c, uL, P.pl.zb, uL, P.pl.zt, 75);

c = cv_lead(c, -40, -bm.tf, -150, 95, {sprintf('flanges: fillet %g', P.w.flange), 'both sides, both flanges'});
c = cv_lead(c, -3, -100, -150, -290, {sprintf('web: fillet %g', P.w.web), 'both sides'});
c = cv_lead(c, P.pl.t+3, zl+P.lug.t/2, 40, 120, sprintf('lug to plate: fillet %g, top and bottom', P.w.lug));
c = cv_lead(c, P.pl.t+P.lug.L/2, za-2, 150, -120, {sprintf('each bar: end on the plate, fillet %g all round', P.w.end), sprintf('+ fillet %g on both sides along the lug', P.w.bar)});
c = cv_lead(c, P.pl.t+P.stf.L, zs, 150, -200, {sprintf('stiffener PL %gx%gx%g', P.stf.t, P.stf.w, P.stf.L), sprintf('fillet %g, top and bottom', P.w.stf)});
c = cv_lead(c, P.anc.uh-20, za-25, 390, 95, {sprintf('%s%g, inside bend diameter', '&#216;', P.anc.db), sprintf('6 db = %g', 6*P.anc.db)});
c = cv_lead(c, 190, zb, 250, 60, 'bars on top of the lug: hook at 350');
c = cv_lead(c, 120, za, 60, -60, 'bars under the lug: hook at 270');
c = cv_text(c, -85, -105, bm.name, 'middle');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_assy_plan(P, R)
% Shop assembly, top view
bm = P.bm;  uL = -170;  v = P.anc.v;
c = cv_new(-330, 560, -190, 190, 1.0);
c = cv_rect(c, uL, -bm.b/2, 0, bm.b/2, 'steel');
c = cv_seg(c, [uL 0], [0 0], 'cl');
for i = 1:numel(v)
    c = cv_bar(c, [P.pl.t P.anc.uh], [v(i) v(i)], P.anc.db, 'anc');
    c = cv_circ(c, P.anc.uh-P.anc.db/2, v(i), P.anc.db, 'tail');
end
c = cv_rect(c, P.pl.t, -P.lug.w/2, P.pl.t+P.lug.L, P.lug.w/2, 'platet');
for i = 1:numel(v)
    for sg = [-1 1]
        c = cv_seg(c, P.pl.t + P.lug.L/2 + P.anc.Lw/2*[-1 1], (v(i)+sg*P.anc.db/2)*[1 1], 'weld');
    end
    c = cv_seg(c, P.pl.t*[1 1]+1, v(i)+P.anc.db/2*[-1 1], 'weld');
end
c = cv_rect(c, 0, -P.pl.w/2, P.pl.t, P.pl.w/2, 'plate');

c = cv_dim(c, P.pl.t, P.pl.w/2, P.pl.t+P.lug.L, P.pl.w/2, 25, sprintf('%g', P.lug.L), 12);
c = cv_dim(c, P.pl.t+P.lug.L, P.pl.w/2, P.anc.uh, P.pl.w/2, 25);
c = cv_dim(c, P.anc.uh, v(1), P.anc.uh, v(end), -35);
c = cv_dim(c, uL, -P.lug.w/2, uL, P.lug.w/2, 30, sprintf('%g  (lug)', P.lug.w));
c = cv_dim(c, uL, -P.pl.w/2, uL, P.pl.w/2, 75, sprintf('%g  (plate)', P.pl.w));
c = cv_dim(c, uL, -bm.b/2, 0, -bm.b/2, -75, 'beam continues');
c = cv_lead(c, P.pl.t+P.lug.L/2, v(1)-P.anc.db/2, 330, -130, sprintf('welds (yellow): end on the plate + %g each side on the lug', P.anc.Lw));
c = cv_lead(c, 150, v(end), 250, 140, 'top view: the bars under the lug are hidden below these');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
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
function svg = fig_flow(P, R)
% Force flow in the edge joint and the breakout surface of chapter 17
hb = P.col.b/2;  bm = P.bm;  gx = @(u) u - hb;  K = R.kase(1);
za = R.zanc(2);  ztop = P.col.top;  zcj = P.col.cj;  xL = -420;  xR = 620;  zB = -470;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
zl = -bm.tf/2;  zs = -bm.h + bm.tf/2;  zt = P.cb.zt(1);
c = cv_new(-640, 800, -560, 250, 0.78);
c = cv_rect(c, -hb, zB, hb, zcj, 'old');
c = cv_rect(c, -hb, zcj, hb, ztop, 'conc');
c = cv_rect(c, hb, -P.cb.h, xR, 0, 'conc');
c = cv_seg(c, [-hb-40 hb+40], [zcj zcj], 'cj');

% path 2: diagonal strut to the pedestal
x1 = gx(R.stm.u1);  z1 = R.stm.z1;  x2 = gx(R.stm.u2);  z2 = R.stm.z2;
n = [-(z2-z1), (x2-x1)]/hypot(x2-x1, z2-z1)*28;
c = cv_poly(c, [x1+n(1) x2+n(1) x2-n(1) x1-n(1)], [z1+n(2) z2+n(2) z2-n(2) z1-n(2)], 'strut2');
% path 1: lap of the hooked bars and compression into the beam
c = cv_poly(c, [gx(P.Lb.uh) gx(P.anc.uh) gx(P.anc.uh) gx(P.Lb.uh)], [za+8 za+8 zt-10 zt-10], 'strut1');
c = cv_poly(c, [gx(P.pl.t) xR xR gx(P.pl.t)], [zs+25 -300 -350 zs-25], 'strut1');

% steel
c = cv_rect(c, xL, -bm.h+bm.tf, -hb, -bm.tf, 'web');
c = cv_rect(c, xL, -bm.tf, -hb, 0, 'steel');
c = cv_rect(c, xL, -bm.h, -hb, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -hb, P.pl.zb, gx(P.pl.t), P.pl.zt, 'plate');
c = cv_rect(c, gx(P.pl.t), zl-P.lug.t/2, gx(P.pl.t+P.lug.L), zl+P.lug.t/2, 'plate');
c = cv_rect(c, gx(P.pl.t), zs-P.stf.t/2, gx(P.pl.t+P.stf.L), zs+P.stf.t/2, 'plate');
% bars
c = cv_bar(c, [-xc -xc], [zB ztop-48], P.col.db, 'col');
c = cv_bar(c, [ xc  xc], [zB ztop-48], P.col.db, 'col');
[x, z] = hook(xR, gx(P.Lb.uh), zt, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'new');
[x, z] = hook(gx(P.pl.t), gx(P.anc.uh), za, P.anc.db, -1);
c = cv_bar(c, x, z, P.anc.db, 'anc');
[x, z] = hook(gx(P.pl.t), gx(P.anc.uhA), R.zanc(1), P.anc.db, -1);
c = cv_bar(c, x, z, P.anc.db, 'anc');

% breakout surface of chapter 17 (slope 1 : 1.5 from the hooks)
xk = gx(P.anc.uhA - P.anc.db/2);  za = R.zanc(1);
c = cv_seg(c, [xk - 1.5*(ztop-za), xk, -hb], [ztop, za, za - (xk+hb)/1.5], 'crack');

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
c = cv_lead(c, 20, za-20, 330, 190, {'PATH 1: the anchors lap with the hooked top bars', sprintf('of the concrete beam (%d %s%g, green)', numel(P.cb.ve), '&#216;', P.cb.db)});
c = cv_lead(c, 420, -322, 440, -420, {'PATH 1: the flange compression goes', 'straight into the beam'});
c = cv_lead(c, (x1+x2)/2, (z1+z2)/2, -330, -420, {'PATH 2: strut to the pedestal,', sprintf('%.0f deg from the horizontal', R.stm.th*180/pi)});
c = cv_lead(c, xc+28, z1-110, 440, -500, {sprintf('PATH 2: %.0f kN of tension in the inner', K.T*tan(R.stm.th)/1e3), 'column bars, anchored at the top'});
c = cv_lead(c, xk - 0.75*(ztop-za), za + (ztop-za)/2, -330, 205, {'Breakout surface of chapter 17, 1 : 1.5', sprintf('%.0f kN: not relied upon', R.brk.phiN/1e3)});
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_cones(P, R)
% Corner column in plan: breakout bodies of the two groups and the beam bars
% that cross them, with the hooked length of each bar inside the bodies.
hb = P.col.b/2;  gx = @(u) u - hb;  v = P.anc.v;  db = P.anc.db;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
c = cv_new(-900, 760, -560, 700, 0.6);
c = cv_rect(c, hb, -P.cb.b/2, 680, P.cb.b/2, 'conc');
c = cv_rect(c, -P.cb.b/2, hb, P.cb.b/2, 680, 'conc');
c = cv_rect(c, -hb, -hb, hb, hb, 'conc');
uap = P.anc.uh - db/2 - R.dev.rb;  d = (hb - max(v))/1.5;
px = [gx(uap), gx(uap)-d, -hb, -hb, gx(uap)-d, gx(uap)];  py = [v(end), hb, hb, -hb, -hb, v(1)];
c = cv_poly(c, px, py, 'tribx');
c = cv_poly(c, py, px, 'triby');
CN = R.cone(2);
for i = 1:numel(CN.vb)
    y = CN.vb(i);
    c = cv_bar(c, [gx(P.Lb.uh+P.cb.db/2) 680], [y y], P.cb.db, 'ex');
    c = cv_bar(c, [y y], [gx(P.Lb.uh+P.cb.db/2) 680], P.cb.db, 'ex');
    c = cv_circ(c, gx(CN.uc(i)), y, 9, 'mark');
    c = cv_circ(c, y, gx(R.cone(3).uc(i)), 9, 'mark');
end
for i = 1:numel(v)
    c = cv_bar(c, [gx(P.pl.t) gx(P.anc.uh)], [v(i) v(i)], db, 'anc');
    c = cv_bar(c, [v(i) v(i)], [gx(P.pl.t) gx(P.anc.uh)], db, 'anc');
end
c = cv_rect(c, -hb, -P.pl.w/2, gx(P.pl.t), P.pl.w/2, 'plate');
c = cv_rect(c, -P.pl.w/2, -hb, P.pl.w/2, gx(P.pl.t), 'plate');
for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, c = cv_circ(c, sx*xc, sy*xc, P.col.db, 'col'); end
end, end
[m, i] = min(CN.uc);
c = cv_dim(c, gx(P.Lb.uh), CN.vb(i), gx(CN.uc(i)), CN.vb(i), -60-CN.vb(i)-10, sprintf('%.0f inside &#8805; %.0f', CN.uc(i)-P.Lb.uh, R.dev.ldh12));
[m, i] = min(R.cone(3).uc);
c = cv_dim(c, R.cone(3).vb(i), gx(P.Lb.uh), R.cone(3).vb(i), gx(R.cone(3).uc(i)), 60+R.cone(3).vb(i)+10, sprintf('%.0f inside &#8805; %.0f', R.cone(3).uc(i)-P.Lb.uh, R.dev.ldh12));
c = cv_lead(c, -170, 170, -520, 560, {'breakout body of beam X', '(orange)'});
c = cv_lead(c, 170, -170, 260, -470, {'breakout body of beam Y (blue)'});
c = cv_lead(c, gx(CN.uc(2)), CN.vb(2), 330, 620, {'white dots: where each beam bar', 'leaves the bodies (conservative)'});
c = cv_lead(c, 600, P.cb.v(end), 520, 250, {'beam bars continue: straight', sprintf('length needed %.0f, available: the whole beam', R.dev.ld12)});
c = cv_text(c, -hb-20, 0, 'X', 'end');
c = cv_text(c, 0, -hb-30, 'Y', 'middle');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_devel(P, R, k)
% Section along a beam: cone from the anchors (conservative apex at the start
% of the bend, slope 1 : 1.5) and the beam top bar that it crosses first.
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
zl = -bm.tf/2;
c = cv_rect(c, gx(P.pl.t), zl-P.lug.t/2, gx(P.pl.t+P.lug.L), zl+P.lug.t/2, 'plate');
if k == 1, rows = [R.zanc(1) P.anc.uhA; R.zanc(2) P.anc.uh]; else, rows = [R.zanc(1) P.anc.uh]; end
[m, i] = min(CN.uc);  zb = CN.zb;
[x, z] = hook(560, gx(P.Lb.uh), zb, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'ex');
for j = 1:size(rows,1)
    [x, z] = hook(gx(P.pl.t), gx(rows(j,2)), rows(j,1), db, -1);
    c = cv_bar(c, x, z, db, 'anc');
    ua = rows(j,2) - db/2 - R.dev.rb;
    c = cv_circ(c, gx(ua), rows(j,1), 7, 'mark');
    c = cv_seg(c, [gx(ua)-(ztop-rows(j,1))/1.5, gx(ua), gx(ua)-(rows(j,1)-zcj)/1.5], [ztop, rows(j,1), zcj], 'crack');
end
c = cv_circ(c, gx(CN.uc(i)), zb, 9, 'mark');
c = cv_dim(c, gx(P.Lb.uh), zb, gx(CN.uc(i)), zb, -95, sprintf('%.0f inside the body &#8805; &#8467;dh = %.0f', CN.uc(i)-P.Lb.uh, R.dev.ldh12));
c = cv_dim(c, gx(CN.uc(i)), zb, xR, zb, -95, sprintf('continues along the beam, needs %.0f', R.dev.ld12));
c = cv_dim(c, gx(P.pl.t), ztop, gx(min(rows(:,2))), ztop, 40, sprintf('%.0f anchor embedment &#8805; %.0f', min(rows(:,2))-P.pl.t, R.dev.ldh));
c = cv_lead(c, gx(min(rows(:,2)))-60, rows(1,1)+60, -500, 240, {'dashed: surface of the breakout body,', 'slope 1 : 1.5 from the start of the bend (conservative)'});
c = cv_lead(c, gx(CN.uc(i)), zb, 300, 180, {'white dot: where the beam bar leaves the body,', sprintf('computed in 3D for the worst bar (v = %+g)', CN.vb(i))});
if k == 1, t = 'EDGE'; else, t = 'CORNER, beam X'; end
c = cv_text(c, -880, -420, t, 'start');
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

% ---------------------------------------------------------------------------
function svg = fig_wf_plate(P, R)
% Forces on the embed plate, corner type C1 (bars under the platina)
bm = P.bm;  K = R.kase(3);  zf = -bm.tf/2;  zb = R.zanc(1);  zc = R.zC;  d = P.anc.db;
c = cv_new(-330, 470, -265, 95, 1.0);
c = cv_rect(c, -140, -bm.tf, 0, 0, 'steel');
c = cv_rect(c, -140, -bm.h, 0, -bm.h + bm.tf, 'steel');
c = cv_rect(c, -140, -bm.h + bm.tf, 0, -bm.tf, 'web');
c = cv_rect(c, 0, P.pl.zb, P.pl.t, P.pl.zt, 'plate');
c = cv_rect(c, P.pl.t, zf - P.lug.t/2, P.pl.t + P.lug.L, zf + P.lug.t/2, 'plate');
c = cv_rect(c, P.pl.t, zc - P.stf.t/2, P.pl.t + P.stf.L, zc + P.stf.t/2, 'plate');
c = cv_bar(c, [P.pl.t 200], [zb zb], d, 'anc');
c = cv_arrow(c, -20, zf, -120, zf, '#c0392b');
c = cv_text(c, -125, zf + 10, sprintf('T flange = %.1f kN', K.Tf/1e3), 'end');
c = cv_arrow(c, -120, zc, -20, zc, '#1f4e79');
c = cv_text(c, -125, zc + 10, sprintf('C = %.1f kN', K.Tf/1e3), 'end');
c = cv_arrow(c, 200, zb, 300, zb, '#c0392b');
c = cv_text(c, 305, zb + 10, sprintf('T bars = %.1f kN', K.T/1e3), 'start');
c = cv_arrow(c, 150, zc, 55, zc, '#1f4e79');
c = cv_text(c, 155, zc + 10, sprintf('C concrete = %.1f kN', K.T/1e3), 'start');
c = cv_dim(c, -200, zc, -200, zf, 0.01, sprintf('%g', zf - zc));
c = cv_dim(c, 240, zc, 240, zb, 0.01, sprintf('%g', zb - zc));
c = cv_dim(c, 150, zb, 150, zf, -6, sprintf('e = %g', zf - zb), 18);
c = cv_text(c, -70, -100, 'IPE 200', 'middle');
c = cv_text(c, 6, P.pl.zt + 8, 'placa', 'middle');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_wf_paths(P, R)
% Close-up at the top platina, corner type C1: the three paths
bm = P.bm;  zf = -bm.tf/2;  zb = R.zanc(1);  d = P.anc.db;  r = d/2;  t = P.pl.t;  L = P.lug.L;
zt = zf + P.lug.t/2;  zl = zf - P.lug.t/2;  w = P.w.end;
c = cv_new(-75, 330, -62, 40, 2.6);
c = cv_rect(c, -70, -bm.tf, 0, 0, 'steel');
c = cv_rect(c, -70, -58, 0, -bm.tf, 'web');
c = cv_rect(c, 0, -60, t, 30, 'plate');
c = cv_rect(c, t, zl, t + L, zt, 'plate');
c = cv_bar(c, [t 110], [zb zb], d, 'anch');
c = cv_poly(c, [t t+w t], [zb-r zb-r zb-r-w], 'weldfill');
c = cv_poly(c, [t t+w t], [zt zt zt+w], 'weldfill');
c = cv_seg(c, [t+L-P.anc.Lw t+L], [zl-1.2 zl-1.2], 'wside');
% path A
c = cv_arrow(c, t+2, zb, 125, zb, '#7b241c');
c = cv_text(c, 128, zb - 1, 'A: bead around the bar end, carries T', 'start');
% path B
c = cv_arrow(c, t+2, zf+2, t+L-6, zf+2, '#e67e22');
c = cv_arrow(c, t+L-6, zf, t+L-6, zb+r+1, '#e67e22');
c = cv_text(c, t+L+4, zf + 8, 'B: platina + side welds 6 x 25, also carries all of T', 'start');
% path C
c = cv_arrow(c, 34, -55, 34, zl-1, '#1f4e79');
c = cv_arrow(c, t/2, zt, t/2, zt+16, '#1f4e79');
c = cv_text(c, 39, -54, 'C: V. The concrete pushes the platina up (between the bars).', 'start');
c = cv_text(c, -6, zt+22, 'the bead takes V to the plate', 'end');
c = cv_arrow(c, -8, zf, -60, zf, '#c0392b');
c = cv_text(c, -35, zf + 5, 'T flange', 'middle');
svg = cv_end(c);
end

function s = pts(c, x, y)
[px, py] = cv_p(c, x, y);
s = sprintf('%.1f,%.1f ', [px(:)'; py(:)']);
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
    case 'col',    col = '#9a6b00';
    case 'colh',   col = '#9a6b00';  op = 0.55;
    case 'rod',    col = '#117a65';  op = 0.55;
    case 'steelc', col = '#34506b';
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
