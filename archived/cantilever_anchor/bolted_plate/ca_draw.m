function F = ca_draw(P, R)
% CA_DRAW  Drawings of the bolted plate anchorage as SVG text.
%   F = ca_draw(P, R) returns one field per figure. All geometry comes from P
%   (ca_inputs) and R (ca_calc), so drawings and numbers cannot differ.
%   Drawing units are mm; z = 0 is the top of the concrete beam and of the steel.
%   Section views: x = u - 200 (column axis at x = 0, outer face at x = -200).
%   The drawing tools at the end are copied from ../cantilever_anchor_double_plate/ca_draw.m
%   (styles grout, form, clash, tmpl added).
F.trib       = fig_trib(P, R);
F.ram_front  = fig_ram_front(P, R);
F.ram_sec    = fig_ram_sec(P, R);
F.edge_elev  = fig_elev(P, R, 1, 9);
F.edge_plan  = fig_plan(P, R, 1);
F.edge_front = fig_front(P, R, 1);
F.c1_plan    = fig_plan(P, R, 2);
F.cor_plan   = fig_plan(P, R, 3);
F.cor_elevX  = fig_elev(P, R, 3, 9);
F.cor_elevY  = fig_elev(P, R, 4, 9);
F.cor_front  = fig_front(P, R, 4);
F.forces     = fig_forces(P, R);
F.cone_E     = fig_cone(P, R, 1);
F.cone_Y     = fig_cone(P, R, 4);
F.plates     = fig_plates(P, R);
F.reinf      = fig_reinf(P, R);
F.reinf_sec  = fig_reinf_sec(P, R);
F.pc_forces  = pc_forces(P, R);
F.pc_geo     = pc_geo(P, R);
F.pc_ten1    = pc_ten1(P, R);
F.pc_ten2    = pc_ten2(P, R);
F.pc_pry     = pc_pry(P, R);
F.pc_brg     = pc_brg(P, R);
F.ta_geo     = ta_geo(P, R);
F.ta_bar     = ta_bar(P, R);
F.ta_bp      = ta_bp(P, R);
F.ta_bpm     = ta_bpm(P, R);
F.ta_brk     = ta_brk(P, R);
F.ta_z0      = ta_z0(P, R);
F.ta_stm     = ta_stm(P, R);
if P.ub.on, F.ta_ubar = ta_ubar(P, R);  F.ta_ubar3 = ta_ubar3(P, R); end
F.ta_sfb     = ta_sfb(P, R);
F.ta_spry    = ta_spry(P, R);
F.ta_sbrk    = ta_sbrk(P, R);
F.ta_sfr     = ta_sfr(P, R);
F.ta_stop    = ta_stop(P, R, 4);
F.ta_arx     = ta_arx(P, R);
F.ta_aru     = ta_aru(P, R);
F.bars       = fig_bars(P, R);
F.grout      = fig_grout(P, R);
F.tol        = fig_tol(P, R);
for s = 1:5
    F.(sprintf('seq%d', s)) = fig_elev(P, R, 1, s);
end
end

% ===========================================================================
%  figures
% ===========================================================================
function svg = fig_trib(P, R)
% Tributary areas beyond the column face: edge, corner with two beams, corner with one beam
L = P.L;  a0 = P.a0;  s = P.s_edge;  s2 = P.s_half + a0;  Lt = P.Lax;  hc = P.hcb;
c = cv_new(-3300, 15600, -5000, 3900, 0.052);
% --- edge: column axis at (0, 0), cantilever towards -x
c = cv_rect(c, 0, -2900, 1700, 2900, 'conc');
c = cv_rect(c, -Lt, -s/2, -hc, s/2, 'tribx');
c = cv_seg(c, [-Lt -Lt], [-2900 2900], 'dim');
c = cv_bar(c, [-Lt -a0], [0 0], 90, 'steelc');
c = cv_rect(c, -a0, -a0, a0, a0, 'old');
c = cv_seg(c, [-hc -hc], [-2900 2900], 'cl');
c = cv_dim(c, -Lt, -s/2, -hc, -s/2, -450, sprintf('%.2f m loaded', L/1000));
c = cv_dim(c, -Lt, -s/2, 0, -s/2, -1000, sprintf('%.2f m from the column axis', Lt/1000));
c = cv_dim(c, -Lt, -s/2, -Lt, s/2, 550, sprintf('%.2f m', s/1000));
c = cv_text(c, -Lt/2-60, 2650, sprintf('A = %.2f m&#178;', R.kase(1).A), 'middle');
c = cv_text(c, 850, 2550, 'building', 'middle');
c = cv_text(c, -1500, 3500, '<tspan font-weight="bold">EDGE</tspan>', 'start');
c = cv_lead(c, -hc, -2600, 600, -4250, {'face of the concrete beam (0.15 m from the axis):', 'the slab load starts here; the moment is', 'taken at the column face with 1.12 m (conservative)'});
% --- corner, two beams: axis at (X0, 0); X towards -x, Y towards -y
X0 = 6000;
c = cv_poly(c, X0+[0 3300 3300 0], [0 0 3300 3300], 'conc');
sh = P.s_half;
c = cv_poly(c, X0+[-hc -hc -Lt -Lt], [-hc sh sh -Lt], 'tribx');
c = cv_poly(c, X0+[-hc sh sh -Lt], [-hc -hc -Lt -Lt], 'triby');
c = cv_poly(c, X0+[-Lt -hc -hc -Lt], [-Lt -Lt -hc -hc], 'zbrg');
c = cv_seg(c, X0+[-Lt -Lt 3300], [3300 -Lt -Lt], 'dim');
c = cv_bar(c, X0+[-Lt -a0], [0 0], 90, 'steelc');
c = cv_bar(c, X0+[0 0], [-Lt -a0], 90, 'steelc');
c = cv_rect(c, X0-a0, -a0, X0+a0, a0, 'old');
c = cv_dim(c, X0, 0, X0, sh, -650, sprintf('%.2f m', sh/1000));
c = cv_dim(c, X0-Lt, sh, X0-hc, sh, 450, sprintf('%.2f m', L/1000));
c = cv_text(c, X0-Lt/2-100, 1450, 'beam X', 'middle');
c = cv_text(c, X0-Lt/2-100, 1100, sprintf('%.2f m&#178;', R.kase(2).A), 'middle');
c = cv_text(c, X0+1300, -500, sprintf('beam Y: %.2f m&#178;', R.kase(2).A), 'middle');
c = cv_lead(c, X0-Lt+200, -Lt+250, X0-900, -2300, {'grey square: the corner, split on the diagonal (trapezoids);', sprintf('envelope: all of it on one beam, %.2f m&#178;', R.kase(3).A)});
c = cv_text(c, X0+1900, 2700, 'building', 'middle');
c = cv_text(c, X0-1500, 3500, '<tspan font-weight="bold">CORNER, TWO CANTILEVERS</tspan>', 'start');
% --- corner, one beam: axis at (X1, 0), X towards -x, no overhang on the -y side
X1 = 12100;
c = cv_poly(c, X1+[0 3300 3300 0], [-a0 -a0 3300 3300], 'conc');
c = cv_rect(c, X1-Lt, -a0, X1-hc, P.s_half, 'tribx');
c = cv_bar(c, X1+[-Lt -a0], [0 0], 90, 'steelc');
c = cv_rect(c, X1-a0, -a0, X1+a0, a0, 'old');
c = cv_seg(c, X1+[-Lt 3300], [-a0 -a0], 'limit');
c = cv_dim(c, X1-Lt, -a0, X1-Lt, P.s_half, 550, sprintf('%.2f m', s2/1000));
c = cv_dim(c, X1-Lt, -a0, X1-hc, -a0, -450, sprintf('%.2f m', L/1000));
c = cv_text(c, X1-Lt/2-60, 2650, sprintf('A = %.2f m&#178;', R.kase(4).A), 'middle');
c = cv_lead(c, X1+1500, -a0, X1+600, -1500, {'slab edge flush with the column face:', 'no overhang on this side (user)'});
c = cv_text(c, X1+1900, 2700, 'building', 'middle');
c = cv_text(c, X1-1500, 3500, '<tspan font-weight="bold">CORNER, ONE CANTILEVER</tspan>', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_ram_front(P, R)
% The user's RAM model on the column face, seen from outside: what it hits
hb = P.col.b/2;  bm = P.bm;  M = R.ram;  db = P.an.db;
ztop = P.col.top;  zcj = P.col.cj;  yE = 520;  zB = -480;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
c = cv_new(-1200, 1060, -560, 300, 0.58);
c = cv_rect(c, -yE, 0, -hb, P.slab.t, 'slab');  c = cv_rect(c, hb, 0, yE, P.slab.t, 'slab');
c = cv_rect(c, -yE, -P.cb.h, -hb, 0, 'conc');   c = cv_rect(c, hb, -P.cb.h, yE, 0, 'conc');
c = cv_rect(c, -hb, zB, hb, zcj, 'old');
c = cv_rect(c, -hb, zcj, hb, ztop, 'conc');
c = cv_seg(c, [-hb-45 hb+45], [zcj zcj], 'cj');
zc = ztop - P.col.cover - P.col.db/2;
for x = [-xc 0 xc], c = cv_bar(c, [x x], [zB zc], P.col.db, 'col'); end
for y = [-1 1]*P.rod.p, c = cv_bar(c, [y y], [zB ztop+40], P.rod.db, 'rod'); end   % anchored > 1 m below: to the end of the drawing
for v = P.cb.v                                       % beam in line: top bars (sections) and front hooks
    c = cv_bar(c, [v v], [P.cb.zt(1), P.cb.zt(1)-15.5*P.cb.db], P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zt(1), P.cb.db, 'ex');
end
for v = P.cb.v([1 3]), c = cv_circ(c, v, P.cb.zp, P.cb.db, 'ex'); end
for z = P.hoop.z, c = cv_seg(c, [-hb+45 hb-45], [z z], 'hoop'); end
% RAM plate, key, beam
zc0 = -bm.h/2;
c = cv_rect(c, -M.B/2, zc0-M.N/2, M.B/2, zc0+M.N/2, 'platet');
c = cv_rect(c, -M.key(1)/2, zc0-M.key(3)/2, M.key(1)/2, zc0+M.key(3)/2, 'clash');
c = cv_rect(c, -bm.b/2, -bm.tf, bm.b/2, 0, 'steel');
c = cv_rect(c, -bm.b/2, -bm.h, bm.b/2, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -bm.tw/2, -bm.h+bm.tf, bm.tw/2, -bm.tf, 'steel');
for i = 1:size(M.anc,1)
    v = M.v(i);  z = M.z(i);
    if M.keep(i)
        c = cv_circ(c, v, z, P.an.wsh, 'ringok');
        c = cv_circ(c, v, z, db, 'anc');
    else
        c = cv_circ(c, v, z, db, 'exl');
        c = cv_seg(c, v+[-14 14], z+[-14 14], 'crack');  c = cv_seg(c, v+[-14 14], z+[14 -14], 'crack');
    end
end
c = cv_circ(c, 0, M.top, 46, 'xhit');
c = cv_circ(c, 75, M.top, 40, 'xhit');  c = cv_circ(c, -75, M.top, 40, 'xhit');
c = cv_circ(c, 75, M.z2, 36, 'xhit');   c = cv_circ(c, -75, M.z2, 36, 'xhit');
% dims
c = cv_dim(c, -M.B/2, ztop, M.B/2, ztop, 40, sprintf('%g', M.B));
c = cv_dim(c, -75, ztop, 75, ztop, 85, '150');
zz = sort([zc0-M.N/2, M.z2, -bm.h, 0, M.top, zc0+M.N/2]);
for i = 1:numel(zz)-1, c = cv_dim(c, yE, zz(i), yE, zz(i+1), -35, sprintf('%.0f', zz(i+1)-zz(i))); end
% labels
c = cv_lead(c, 0, M.top+20, -560, 250, {'anchor on the beam axis: runs into', sprintf('the mid-face column bar (overlap %.0f mm)', -M.c_mid)});
c = cv_lead(c, -75-14, M.top+8, -560, 170, {sprintf('top row %g mm over the flange: washer', M.pf), sprintf('and nut on the 8 mm fillet (%.0f mm)', M.c_nut)});
c = cv_lead(c, -P.rod.p, 60, -560, 95, sprintf('rods of the steel column: %.0f mm from the anchors at &#177;75', M.c_rod));
c = cv_lead(c, -75, M.z2-16, -560, -40, {sprintf('second row (z = %g): %.0f mm over the beam top', M.z2, M.c_bar), sprintf('bars, %.0f mm with their tolerance', M.c_barT)});
c = cv_lead(c, -100, zc0, -560, -150, {sprintf('shear key %gx%g, %g deep: its pocket cuts', M.key(1), M.key(3), M.key(2)), 'the mid-face bar, the ties and the hook tails'});
c = cv_lead(c, 75, M.z(6), 560, -230, {'the two anchors at 10 left out', '(user, 2026-10-02)'});
c = cv_lead(c, M.B/2-10, zc0-M.N/2+10, 560, -330, sprintf('RAM plate %gx%gx%g', M.B, M.N, M.t));
c = cv_text(c, 0, -440, 'Hardened pedestal', 'middle');
c = cv_text(c, -yE+20, -175, 'Edge beam', 'start');
c = cv_text(c, -1180, 270, '<tspan font-weight="bold">RAM model as drawn, edge column, seen from outside</tspan>', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_ram_sec(P, R)
% The user's RAM model in a section along the beam axis
hb = P.col.b/2;  bm = P.bm;  M = R.ram;  db = P.an.db;  gx = @(u) u - hb;
ztop = P.col.top;  zcj = P.col.cj;  xL = -560;  xR = 700;  zB = -480;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;  xh = hb - P.col.cover - P.col.dtie/2;
c = cv_new(-1060, 1060, -520, 300, 0.58);
c = cv_rect(c, -hb, zB, hb, zcj, 'old');
c = cv_rect(c, -hb, zcj, hb, ztop, 'conc');
c = cv_rect(c, hb, -P.cb.h, xR, 0, 'conc');
c = cv_rect(c, hb, 0, xR, P.slab.t, 'slab');
c = cv_seg(c, [-hb-45 hb+45], [zcj zcj], 'cj');
zc = ztop - P.col.cover - P.col.db/2;
c = cv_bar(c, [-xc -xc], [zB zc], P.col.db, 'col');  c = cv_bar(c, [xc xc], [zB zc], P.col.db, 'col');
for z = P.hoop.z
    c = cv_seg(c, [-xh xh], [z z], 'hoop');
end
zt = max(P.cb.zt);
[x, z] = hook(xR, gx(P.cb.uh), zt, P.cb.db, -1);  c = cv_bar(c, x, z, P.cb.db, 'ex');
c = cv_bar(c, [xR gx(P.cb.uh+10)], P.cb.zb(1)*[1 1], P.cb.db, 'ex');
for v = P.cb.v, c = cv_circ(c, v, zt, P.cb.db, 'ex'); c = cv_circ(c, v, P.cb.zb(1), P.cb.db, 'ex'); end
% plate, key pocket, anchors (L-bolts, eh = 72)
zc0 = -bm.h/2;  tp = M.t;
c = cv_rect(c, gx(0), zc0-30, gx(M.key(2)+10), zc0+30, 'clash');
c = cv_rect(c, gx(-tp), zc0-M.N/2, gx(0), zc0+M.N/2, 'plate');
c = cv_rect(c, gx(0), zc0-M.key(3)/2, gx(M.key(2)), zc0+M.key(3)/2, 'plate');
for z = unique(M.zk)'
    ue = M.hef + db;
    c = cv_bar(c, gx([-tp-30 ue ue]), [z z z-M.eh], db, 'anc');
    c = cv_rect(c, gx(-tp-P.an.twsh-P.an.tnut), z-P.an.nut/2, gx(-tp), z+P.an.nut/2, 'tail');
end
x0 = gx(-tp);
c = cv_rect(c, xL, -bm.h+bm.tf, x0, -bm.tf, 'web');
c = cv_rect(c, xL, -bm.tf, x0, 0, 'steel');  c = cv_rect(c, xL, -bm.h, x0, -bm.h+bm.tf, 'steel');
for z = [0, -bm.tf, -bm.h+bm.tf, -bm.h]
    sg = 1;  if z == -bm.tf || z == -bm.h, sg = -1; end
    c = cv_poly(c, [x0 x0-8 x0], [z z z+sg*8], 'weldfill');
end
c = cv_circ(c, gx(P.cb.uh)+10, M.z2-12, 36, 'xhit');
c = cv_circ(c, gx(-tp)-12, M.top-6, 40, 'xhit');
c = cv_circ(c, -xc, zc0, 46, 'xhit');
% labels
c = cv_lead(c, gx(-tp)-14, M.top+8, -560, 250, {sprintf('top row %g over the flange: washer + nut', M.pf), 'land on the 8 mm fillet'});
c = cv_lead(c, gx(150), M.z2, -560, 60, {sprintf('second row at %g: %.0f mm over the', M.z2, M.c_bar), 'beam top bars (upper layer)'});
c = cv_lead(c, -xc, zc0-20, -560, -150, {sprintf('shear key %g deep: pocket through', M.key(2)), 'the mid-face bar, the front tie legs', 'and the hook tails of the beam bars'});
c = cv_lead(c, gx(M.hef+db), M.top-40, 620, 230, {sprintf('L-bolt, h<sub>ef</sub> = %g, e<sub>h</sub> = %g', M.hef, M.eh), '(RAM: J/L-bolt pullout)'});
c = cv_dim(c, gx(-tp), ztop, gx(M.hef+db), ztop, 40, sprintf('%g', M.hef+db));
c = cv_text(c, -450, -125, bm.name, 'middle');
c = cv_text(c, 0, -440, 'Hardened pedestal', 'middle');
c = cv_text(c, -1040, 270, '<tspan font-weight="bold">RAM model as drawn, section along the beam</tspan>', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function c = draw_anchors_elev(c, P, R, j, gx, show)
% anchors of type j in a section along its beam, with grout, end plate and nuts.
% show = [anchors, nuts on the end plate]
Y = R.typ(j);  an = P.an;  db = an.db;
tp = P.ep.t;  g = P.g;  tw = an.twsh;  tn = an.tnut;
if show(1)
    c = cv_bar(c, gx([-an.out an.uT]), Y.zT*[1 1], db, 'anc');
    bp = P.bp;  hb2 = bp.h/2;
    c = cv_rect(c, gx(bp.u), Y.zT-hb2, gx(bp.u+bp.t), Y.zT+hb2, 'plate');
    c = cv_rect(c, gx(bp.u-tn), Y.zT-an.nut/2, gx(bp.u), Y.zT+an.nut/2, 'tail');
    c = cv_rect(c, gx(bp.u+bp.t), Y.zT-an.wsh/2, gx(bp.u+bp.t+tw), Y.zT+an.wsh/2, 'tail');
    c = cv_rect(c, gx(bp.u+bp.t+tw), Y.zT-an.nut/2, gx(bp.u+bp.t+tw+tn), Y.zT+an.nut/2, 'tail');
    ue = an.uS + tw + tn + an.pp;
    c = cv_bar(c, gx([-an.out ue]), Y.zS*[1 1], db, 'anc');
    c = cv_rect(c, gx(an.uS), Y.zS-an.wsh/2, gx(an.uS+tw), Y.zS+an.wsh/2, 'tail');
    c = cv_rect(c, gx(an.uS+tw), Y.zS-an.nut/2, gx(an.uS+tw+tn), Y.zS+an.nut/2, 'tail');
end
if show(2)
    for z = [Y.zT Y.zS]
        x1 = -g - tp;
        c = cv_rect(c, gx(x1-tw), z-an.wsh/2, gx(x1), z+an.wsh/2, 'tail');
        c = cv_rect(c, gx(x1-tw-tn), z-an.nut/2, gx(x1-tw), z+an.nut/2, 'tail');
    end
end
end

function c = draw_beam_elev(c, P, R, j, gx, xL)
% grout pad, end plate and the steel beam, in a section along the beam
bm = P.bm;  Y = R.typ(j);  x0 = gx(-P.g - P.ep.t);  w = P.w.flange;
c = cv_rect(c, gx(-P.g), Y.ep_bot-15, gx(0), Y.ep_top+15, 'grout');
if P.dbl.on, c = cv_rect(c, gx(-P.g), 0, gx(-P.g+P.dbl.t), Y.ep_top, 'plate'); end
c = cv_rect(c, xL, -bm.h+bm.tf, x0, -bm.tf, 'web');
c = cv_rect(c, xL, -bm.tf, x0, 0, 'steel');
c = cv_rect(c, xL, -bm.h, x0, -bm.h+bm.tf, 'steel');
c = cv_rect(c, x0, Y.ep_bot, gx(-P.g), Y.ep_top, 'plate');
if P.rib.on                                         % rib on the web line, above the top flange
    Ls = Y.ep_top/tan(pi/6);
    c = cv_poly(c, [x0 x0 x0-20 x0-Ls], [0 Y.ep_top Y.ep_top 0], 'rib');
end
for z = [0, -bm.tf, -bm.h+bm.tf, -bm.h]
    sg = 1;  if z == -bm.tf || z == -bm.h, sg = -1; end
    c = cv_poly(c, [x0 x0-w x0], [z z z+sg*w], 'weldfill');
end
end

% ---------------------------------------------------------------------------
function svg = fig_elev(P, R, j, stage)
% Section along the axis of the steel beam of type j (1 E, 2 C1, 3 CX, 4 CY).
% stage = 9: final, with dimensions; stage = 1..5: placing sequence (edge).
hb = P.col.b/2;  bm = P.bm;  gx = @(u) u - hb;  Y = R.typ(j);  an = P.an;  db = an.db;
ztop = P.col.top;  zcj = P.col.cj;  xL = -640;  xR = 760;  zB = -520;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
xh = hb - P.col.cover - P.col.dtie/2;
fin = (stage == 9);  cor = (j >= 3);
if fin
    c = cv_new(-800, 920, -600, 345, 0.62);
else
    c = cv_new(-700, 560, -560, 330, 0.40);  xR = 520;  xL = -620;
end
% layer of the beam in line: lower for E, C1, CX; upper for CY (rule at the corner)
ti = 2;  if j == 4, ti = 1; end
tj = 3 - ti;

% concrete
c = cv_rect(c, -hb, zB, hb, zcj, 'old');
if stage >= 3 || fin
    c = cv_rect(c, -hb, zcj, hb, ztop, 'conc');
    c = cv_rect(c, hb, -P.cb.h, xR, 0, 'conc');
    c = cv_rect(c, hb, 0, xR, P.slab.t, 'slab');
else
    c = cv_rect(c, -hb, zcj, hb, ztop, 'hid');
    c = cv_rect(c, hb, -P.cb.h, xR, 0, 'hid');
end
if fin || stage >= 5, c = cv_rect(c, xL, 0, gx(-P.g-P.ep.t)-60, P.slab.t, 'slab'); end
c = cv_seg(c, [-hb-45 hb+45], [zcj zcj], 'cj');
for x = hb+110 : P.cb.sst : xR-20
    c = cv_seg(c, [x x], [-P.cb.h+45, -45], 'stir');
end

% column bars and hooks
zc = ztop - P.col.ctop - P.col.db/2;
if stage >= 3 || fin
    c = cv_bar(c, [-xc -xc], [zB zc], P.col.db, 'col');
    c = cv_bar(c, [ xc  xc], [zB zc], P.col.db, 'col');
    zh = zc;  if j == 4, zh = P.col.zhB; end          % user 2026-10-05: level A along the anchors of X (E, C1, CX);
    [x, z] = hook(zB, zh+P.col.db/2, 0, P.col.db, 1);   % CY: its north and south mid bars on level B, across X
    c = cv_bar(c, -xc + z(2:end), x(2:end), P.col.db, 'colh');
    c = cv_bar(c,  xc - z(2:end), x(2:end), P.col.db, 'colh');
    if j == 4, for x = [-xc xc] + [-8; 8], c = cv_circ(c, x(1), zc, P.col.db, 'col');  c = cv_circ(c, x(2), zc, P.col.db, 'col'); end, end
else
    c = cv_bar(c, [-xc -xc], [zB ztop+170], P.col.db, 'col');
    c = cv_bar(c, [ xc  xc], [zB ztop+170], P.col.db, 'col');
end

% ties
zz = P.hoop.z;  if j <= 2 && (fin || stage >= 3) && ~isnan(P.hoop.ztop), zz = [zz P.hoop.ztop]; end
for z = zz
    c = cv_seg(c, [-xh xh], [z z], 'hoop');
    c = cv_circ(c, -xh, z, P.hoop.db, 'hoop');
    c = cv_circ(c,  xh, z, P.hoop.db, 'hoop');
end
xt = hb - P.col.cover - P.top.db/2;
for z = P.top.z
    c = cv_bar(c, [-xt xt], [z z], P.top.db, 'tie');
    c = cv_circ(c, -xt, z, P.top.db, 'hoop');
    c = cv_circ(c,  xt, z, P.top.db, 'hoop');
end

% bars of the beam in line, rods of the steel column, crossing bars
zt = P.cb.zt(ti);  zb = P.cb.zbl;  zbx = P.cb.zbc;          % bottom bars: in line on the upper layer (D4 grid 4: lower)
if j == 3, zb = P.cb.zbc;  zbx = P.cb.zbl; end
[x, z] = hook(xR, gx(P.cb.ubh), zb, P.cb.db, 1);  c = cv_bar(c, x, z, P.cb.db, 'ex');
if j <= 2                                           % VCM: 2 bars in contact under the corner top bars
    [x, z] = hook(xR, gx(P.cb.uh + P.cb.db), zt - P.cb.db, P.cb.db, -1);
    c = cv_bar(c, x, z, P.cb.db, 'exh');
end
[x, z] = hook(xR, gx(P.cb.uh), zt, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'ex');
for x = [-1 1]*P.rod.p
    c = cv_bar(c, [x x], [zB ztop+60], P.rod.db, 'rod');                % anchored > 1 m below
end
for v = P.cb.v, c = cv_circ(c, v, P.cb.zt(tj), P.cb.db, 'ex'); end
for v = P.cb.vbot, c = cv_circ(c, v, zbx, P.cb.db, 'ex'); end
if cor                                              % anchors of the other beam cross this section
    o = 7 - j;  Yo = R.typ(o);
    for v = [-1 1]*an.vT
        c = cv_circ(c, v, Yo.zT, db, 'anc');
    end
end

% anchors, grout, plate, beam
if stage >= 2 || fin
    c = draw_anchors_elev(c, P, R, j, gx, [1, fin || stage >= 5]);
end
if stage == 2 || stage == 3                         % template on the form
    c = cv_rect(c, gx(-18), Y.zS-40, gx(-12), Y.zT+40, 'tmpl');
end
if stage >= 4 || fin
    if stage == 4
        c = cv_rect(c, gx(-P.g), Y.ep_bot-15, gx(0), Y.ep_top+15, 'grout');
        c = cv_rect(c, gx(-P.g-P.ep.t), Y.ep_bot, gx(-P.g), Y.ep_top, 'plate');
        if P.dbl.on, c = cv_rect(c, gx(-P.g), 0, gx(-P.g+P.dbl.t), Y.ep_top, 'plate'); end
    else
        c = draw_beam_elev(c, P, R, j, gx, xL);
    end
end

if ~fin
    a = {[-560 0 gx(-10) 0], [-560 Y.zT gx(-an.out)-15 Y.zT], [0 300 0 ztop+20], ...
         [-610 -60 gx(-P.g)-15 -60], [-610 -120 gx(-P.g-P.ep.t)-15 -120]};
    t = {sprintf('1. Top ties 14 at %g and %g, then the joint ties', P.top.z), '2. Back plates lowered from above; anchors pushed in', ...
         '3. Column hooks bent, pour, cure', '4. Survey the anchors; grout pad (or after step 5)', '5. Beam with its end plate, drilled to the survey'};
    t2 = {'closed ties dropped over the column bars', 'from the front, through the template and the back plate; nuts', ...
          'threads taped; template stays until the concrete sets', 'end plate drilled to the measured positions', 'nuts snug + 1/3 turn after the grout cures'};
    q = a{stage};
    c = cv_arrow(c, q(1), q(2), q(3), q(4), '#e3141e');
    c = cv_text(c, -680, 300, ['<tspan font-weight="bold">' t{stage} '</tspan>'], 'start');
    c = cv_text(c, -680, 262, t2{stage}, 'start');
    svg = cv_end(c);
    return
end

% dimensions
tp = P.ep.t;  g = P.g;
c = cv_dim(c, gx(-g-tp), ztop, gx(-g), ztop, 45, sprintf('%g', tp), -12);
c = cv_dim(c, gx(-g), ztop, -hb, ztop, 45, sprintf('%g', g), 10);
c = cv_dim(c, -hb, ztop, gx(P.bp.u), ztop, 45, sprintf('%g  (back plate)', P.bp.u));
c = cv_dim(c, gx(P.bp.u), ztop, gx(P.bp.u+P.bp.t), ztop, 45, sprintf('%g', P.bp.t), 10);
c = cv_dim(c, -hb, ztop, gx(an.uS), ztop, 100, sprintf('%g  (shear anchor nut)', an.uS));
c = cv_dim(c, gx(-an.out), ztop, -hb, ztop, 155, sprintf('%g', an.out));
c = cv_dim(c, -hb, ztop, hb, ztop, 155);
c = cv_dim(c, xR, -P.cb.h, xR, 0, -35);
c = cv_dim(c, xR, 0, xR, P.slab.t, -35);
c = cv_dim(c, xR, 0, xR, ztop, -80, sprintf('%g  (pedestal)', ztop));
zz = sort([Y.ep_bot, -bm.h, Y.zS, 0, Y.zT, Y.ep_top]);
for i = 1:numel(zz)-1
    c = cv_dim(c, xL, zz(i), xL, zz(i+1), 35, sprintf('%.0f', zz(i+1)-zz(i)));
end
c = cv_dim(c, xL, Y.ep_bot, xL, Y.ep_top, 90, sprintf('%.0f  (end plate)', Y.H));
zz = [zcj sort(P.hoop.z) P.top.z];
for i = 1:numel(zz)-1
    c = cv_dim(c, hb, zz(i), hb, zz(i+1), -45);
end

% labels
s1 = {sprintf('2 top anchors %s (|v| = %g), threaded %s both ends,', an.lab, an.vT, an.thr), sprintf('straight, z = %+.0f, L = %.0f', Y.zT, an.out + an.uT)};
c = cv_lead(c, gx(120), Y.zT, -330, 260, s1);
c = cv_lead(c, gx(60), Y.zS, -330, -200, {sprintf('2 shear anchors %s (|v| = %g), straight,', an.lab, an.vS), sprintf('nut + washer at u = %g; compression zone', an.uS)});
c = cv_lead(c, gx(-g-tp/2), Y.ep_bot+25, -330, -420, {sprintf('End plate PL %gx%gx%g %s, shop welded:', tp, P.ep.w, Y.H, P.st.name{P.ep.grade}), sprintf('fillets 8 flanges, 5 web; rib PL %g on the web line', P.rib.t)});
c = cv_lead(c, gx(-g/2), Y.ep_bot-10, -330, -480, sprintf('grout pad %g, non-shrink, f''g &#8805; %g MPa', g, P.fg));
c = cv_lead(c, P.rod.p, 70, 470, 235, sprintf('rods of the steel column: 4 %s%g', '&#216;', P.rod.db));
c = cv_lead(c, gx(P.bp.u+P.bp.t/2), Y.zT+P.bp.h/2-3, 470, 290, {sprintf('back plate PL %gx%gx%g %s, nuts both faces,', P.bp.t, P.bp.h, P.bp.w, P.st.name{P.bp.grade}), 'behind the far column bars and the far ties'});
if j <= 2, st = {sprintf('VCM: 5 %s%g top bars, hooked down: 3 in a row', '&#216;', P.cb.db), '+ 2 in contact under the corner bars (light)'};
else,      st = sprintf('VCS: 3 %s%g top bars, hooked down', '&#216;', P.cb.db); end
c = cv_lead(c, 900, zt+4, 880, -110, st);
s3 = '';  if j <= 2 && ~isnan(P.hoop.ztop), s3 = sprintf('closed tie %s%g at +%g, after the anchors', '&#216;', P.hoop.db, P.hoop.ztop); end
c = cv_lead(c, -xh, P.hoop.z(end), -330, -530, {sprintf('%d layers of 4 straight ties %s%g, as planned', numel(P.hoop.z), '&#216;', P.hoop.db), s3});
c = cv_lead(c, xt-30, P.top.z(1), 380, -20, {sprintf('2 closed ties %s%g at %+g and %+g, under the anchors; %s%g at %+g over them', '&#216;', P.top.db, P.top.z, '&#216;', P.t10.db, P.t10.z), 'ACI 10.7.6.1.5; B1 bears on the upper 14'});
if j <= 3, hs = {sprintf('Mid-face column bars: hooks along the anchors of X,'), sprintf('side by side at z = %+g (level A)', zc)};
else,      hs = {sprintf('Mid-face column bars: hooks along beam Y,'), sprintf('side by side at z = %+g (level B, on the anchors of X)', P.col.zhB)}; end
c = cv_lead(c, -40, ifelse(j == 4, P.col.zhB, zc), -330, 300, hs);
if cor
    if j == 3, so = 'anchors of beam Y (high), in section'; else, so = 'anchors of beam X (low), in section'; end
    c = cv_lead(c, an.vT, Yo.zT, 380, 170, so);
end
c = cv_text(c, -470, 125, 'deck notched around the end plate', 'middle');
c = cv_text(c, hb+55, zcj-18, 'cold joint: column cast earlier', 'start');
c = cv_text(c, -470, -125, bm.name, 'middle');
c = cv_text(c, 580, -185, sprintf('Concrete beam %gx%g', P.cb.b/10, P.cb.h/10), 'middle');
c = cv_text(c, 0, -470, 'Hardened pedestal', 'middle');
c = cv_text(c, -470, 62, sprintf('Composite slab %g', P.slab.t), 'middle');
c = cv_text(c, xR+95, -4, '&#177;0', 'start');
c = cv_text(c, -780, 325, sprintf('<tspan font-weight="bold">Type %s</tspan>: %s', Y.name, Y.where), 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function c = draw_anchors_plan(c, P, R, j, rot)
% anchors of type j in plan, with grout pad and end plate. rot = 0: beam along -x
% (u along +x, v along y); rot = 1: beam along -y (u along +y, v along x).
hb = P.col.b/2;  an = P.an;  db = an.db;  tw = an.twsh;  tn = an.tnut;  Y = R.typ(j);
if rot == 0, mp = @(u, v) deal(u - hb, v); else, mp = @(u, v) deal(v, u - hb); end
c = rect_uv(c, mp, -P.g-P.ep.t, -P.ep.w/2, -P.g, P.ep.w/2, 'plate');
c = rect_uv(c, mp, -P.g, -P.ep.w/2-15, 0, P.ep.w/2+15, 'grout');
if P.dbl.on
    c = rect_uv(c, mp, -P.g, P.dbl.gap/2, -P.g+P.dbl.t, P.ep.w/2, 'plate');
    c = rect_uv(c, mp, -P.g, -P.ep.w/2, -P.g+P.dbl.t, -P.dbl.gap/2, 'plate');
end
c = rect_uv(c, mp, P.bp.u, -P.bp.w/2, P.bp.u+P.bp.t, P.bp.w/2, 'plate');
for sg = [-1 1]
    v = sg*an.vS;                                   % shear anchors, lower (translucent)
    [x, y] = mp([-an.outS an.uS+tw+tn+an.pp], [v v]);  c = cv_bar(c, x, y, db, 'anch');
    c = rect_uv(c, mp, an.uS, v-an.wsh/2, an.uS+tw+tn, v+an.wsh/2, 'tailr');
    v = sg*an.vT;                                   % tension anchors
    [x, y] = mp([-an.out an.uT], [v v]);  c = cv_bar(c, x, y, db, 'anc');
    c = rect_uv(c, mp, P.bp.u-tn, v-an.nut/2, P.bp.u, v+an.nut/2, 'tail');
    c = rect_uv(c, mp, P.bp.u+P.bp.t, v-an.nut/2, P.bp.u+P.bp.t+tw+tn, v+an.nut/2, 'tail');
    c = rect_uv(c, mp, -P.g-P.ep.t-tw-tn, v-an.nut/2, -P.g-P.ep.t, v+an.nut/2, 'tail');
end
end

function c = rect_uv(c, mp, u1, v1, u2, v2, st)
[x1, y1] = mp(u1, v1);  [x2, y2] = mp(u2, v2);
c = cv_rect(c, x1, y1, x2, y2, st);
end

% ---------------------------------------------------------------------------
function svg = fig_plan(P, R, j)
% Plan, all anchors projected. j = 1 edge, 2 corner with one beam, 3 corner with two
% beams (X towards -x with type CX, Y towards -y with type CY).
hb = P.col.b/2;  bm = P.bm;  gx = @(u) u - hb;  an = P.an;
xL = -640;  xR = 780;  yT = 560;  yB = -560;
cor2 = (j == 3);  cor1 = (j == 2);
if cor2, yT = 760;  yB = -660; end
if cor1, yB = -330; end
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
xh = hb - P.col.cover - P.col.dtie/2;
c = cv_new(-780, 920, yB-120, yT+130, 0.56);

% concrete: beam in line with X (to +x), crossing beam (edge: both sides; corners: +y only)
c = cv_rect(c, hb, -P.cb.b/2, xR, P.cb.b/2, 'conc');
c = cv_rect(c, -P.cb.b/2, hb, P.cb.b/2, yT, 'conc');
if j == 1, c = cv_rect(c, -P.cb.b/2, yB, P.cb.b/2, -hb, 'conc'); end
c = cv_rect(c, -hb, -hb, hb, hb, 'conc');

% steel beams up to the end plate
c = cv_rect(c, xL, -bm.b/2, gx(-P.g-P.ep.t), bm.b/2, 'steel');
if P.rib.on
    Ls = R.typ(j - (j == 3)*0).ep_top/tan(pi/6);
    c = cv_rect(c, gx(-P.g-P.ep.t)-Ls, -P.rib.t/2, gx(-P.g-P.ep.t), P.rib.t/2, 'rib');
end
c = cv_seg(c, [xL -hb], [0 0], 'cl');
if cor2
    c = cv_rect(c, -bm.b/2, yB, bm.b/2, gx(-P.g-P.ep.t), 'steel');
    if P.rib.on
        Ls = R.typ(4).ep_top/tan(pi/6);
        c = cv_rect(c, -P.rib.t/2, gx(-P.g-P.ep.t)-Ls, P.rib.t/2, gx(-P.g-P.ep.t), 'rib');
    end
    c = cv_seg(c, [0 0], [yB -hb], 'cl');
end

% beam bars: crossing beam (along y), beam in line with X (along x)
for v = P.cb.v
    uh = P.cb.uh;  if v == 0, uh = P.cb.uh0; end
    if j == 1, c = cv_bar(c, [v v], [yB yT], P.cb.db, 'ex');
    else,      c = cv_bar(c, [v v], [gx(uh+P.cb.db/2) yT], P.cb.db, 'ex'); end
    c = cv_bar(c, [gx(uh+P.cb.db/2) xR], [v v], P.cb.db, 'ex');
end

% ties, column bars, rods of the steel column
c = cv_rect(c, -xh, -xh, xh, xh, 'hoopr');
for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, c = cv_circ(c, sx*xc, sy*xc, P.col.db, 'col'); end
end, end
for sx = [-1 1], for sy = [-1 1], c = cv_circ(c, sx*P.rod.p, sy*P.rod.p, P.rod.db, 'rodc'); end, end

% anchors
if cor2
    c = draw_anchors_plan(c, P, R, 4, 1);
    c = draw_anchors_plan(c, P, R, 3, 0);
else
    c = draw_anchors_plan(c, P, R, j, 0);
end

% dimensions
c = cv_dim(c, -hb, hb, gx(an.uS), hb, 45, sprintf('%g', an.uS));
c = cv_dim(c, -hb, hb, gx(P.bp.u), hb, 95, sprintf('%g  (back plate)', P.bp.u));
c = cv_dim(c, -hb, hb, hb, hb, 145);
c = cv_dim(c, -hb-60, -an.vT, -hb-60, an.vT, 40, sprintf('%g', 2*an.vT));
c = cv_dim(c, -hb-60, -P.ep.w/2, -hb-60, P.ep.w/2, 95, sprintf('%g  (end plate)', P.ep.w));
c = cv_dim(c, xR, -P.cb.b/2, xR, P.cb.b/2, -35);
c = cv_dim(c, -hb, -hb, -hb, hb, 260);
if cor2
    c = cv_dim(c, -an.vT, -hb-60, an.vT, -hb-60, -40, sprintf('%g', 2*an.vT));
end

% labels
c = cv_text(c, -520, 76, [bm.name ' (beam X)'], 'middle');
if cor2
    c = cv_lead(c, gx(250), an.vT, 330, 650, {sprintf('CX: 2 anchors %s low, z = %+.0f, over the flange of X', an.lab, R.typ(3).zT), sprintf('back plate PL %gx%gx%g behind the far ties', P.bp.t, P.bp.h, P.bp.w)});
    c = cv_lead(c, an.vT, gx(300), 330, 480, {sprintf('CY: 2 anchors %s high, z = %+.0f, over the flange of Y,', an.lab, R.typ(4).zT), sprintf('resting on those of X. Y = the beam whose top'), 'bars are on the upper layer (check on site)'});
    c = cv_lead(c, -an.vS, gx(60), -420, -330, {'light red: shear anchors, z = -201,', 'short: X and Y do not cross'});
    c = cv_text(c, 62, -470, [bm.name ' (beam Y)'], 'start');
    c = cv_text(c, 170, yT-40, 'Concrete beam (in line with Y)', 'start');
else
    c = cv_lead(c, gx(250), an.vT, 330, 380, {sprintf('2 top anchors %s, z = %+.0f, straight,', an.lab, R.typ(j).zT), sprintf('back plate PL %gx%gx%g behind the far ties', P.bp.t, P.bp.h, P.bp.w)});
    c = cv_lead(c, gx(60), -an.vS, -420, -250, {sprintf('light red: 2 shear anchors %s', an.lab), sprintf('(lower, z = %.0f), nut at u = %g', R.typ(j).zS, an.uS)});
    if j == 1
        c = cv_text(c, 170, yT-40, 'Edge beam', 'start');
        c = cv_text(c, 170, yB+30, 'Edge beam', 'start');
    else
        c = cv_text(c, 170, yT-40, 'Edge beam (ends here, bars hooked)', 'start');
        c = cv_text(c, 0, -hb-40, 'free face', 'middle');
    end
end
c = cv_lead(c, gx(-P.g-P.ep.t/2), P.ep.w/2-10, -250, 430, {sprintf('end plate PL %gx%g on the beam,', P.ep.t, P.ep.w), sprintf('grout pad %g against the face', P.g)});
c = cv_text(c, 560, -185, 'Concrete beam (in line with X)', 'middle');
c = cv_lead(c, P.rod.p, -P.rod.p, 560, -255, {sprintf('4 rods %s%g of the', '&#216;', P.rod.db), 'steel column base plate'});
c = cv_lead(c, xc, -xc, 300, -330, sprintf('column 8 %s%g', '&#216;', P.col.db));
c = cv_lead(c, -xc, 0, -250, 560, {'mid-face column bar', 'passes between the anchors'});
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_front(P, R, j)
% The column seen from outside, looking along the steel beam of type j (1 E, 4 CY)
hb = P.col.b/2;  bm = P.bm;  Y = R.typ(j);  an = P.an;  db = an.db;
ztop = P.col.top;  zcj = P.col.cj;  yE = 540;  zB = -500;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
xh = hb - P.col.cover - P.col.dtie/2;
c = cv_new(-780, 780, -650, 330, 0.62);
c = cv_rect(c, hb, 0, yE, P.slab.t, 'slab');
c = cv_rect(c, hb, -P.cb.h, yE, 0, 'conc');
if j == 1
    c = cv_rect(c, -yE, 0, -hb, P.slab.t, 'slab');
    c = cv_rect(c, -yE, -P.cb.h, -hb, 0, 'conc');
else                                                % corner: beam X seen from the side, on the X face
    x0 = -hb - P.g - P.ep.t;
    c = cv_rect(c, -yE, -bm.h, x0, 0, 'steel');
    c = cv_rect(c, x0, R.typ(3).ep_bot, -hb-P.g, R.typ(3).ep_top, 'plate');
    c = cv_rect(c, -hb-P.g, R.typ(3).ep_bot-15, -hb, R.typ(3).ep_top+15, 'grout');
end
c = cv_rect(c, -hb, zB, hb, zcj, 'old');
c = cv_rect(c, -hb, zcj, hb, ztop, 'conc');
c = cv_seg(c, [-hb-45 hb+45], [zcj zcj], 'cj');

% crossing beam bars, column bars, rods, ties
ti = 2;  if j == 4, ti = 1; end
xb0 = -yE;  if j == 4, xb0 = -hb + P.cb.uh; end
c = cv_bar(c, [xb0 yE], P.cb.zt(3-ti)*[1 1], P.cb.db, 'ex');
zbf = P.cb.zbc;  if j == 4, zbf = P.cb.zbl; end
c = cv_bar(c, [xb0 yE], zbf*[1 1], P.cb.db, 'ex');
zc = ztop - P.col.ctop - P.col.db/2;
for x = [-xc 0 xc], c = cv_bar(c, [x x], [zB zc], P.col.db, 'col'); end
for y = [-1 1]*P.rod.p, c = cv_bar(c, [y y], [zB ztop+60], P.rod.db, 'rod'); end   % anchored > 1 m below
for z = P.hoop.z, c = cv_seg(c, [-xh xh], [z z], 'hoop'); end
if j == 1 && ~isnan(P.hoop.ztop), c = cv_seg(c, [-xh xh], P.hoop.ztop*[1 1], 'hoop'); end
for z = P.top.z, c = cv_bar(c, [-xh xh], [z z], P.top.db, 'tie'); end

% bars of the beam in line: sections and front hooks
for v = P.cb.v
    c = cv_bar(c, [v v], [P.cb.zt(ti), P.cb.zt(ti)-15.5*P.cb.db], P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zt(ti), P.cb.db, 'ex');
end
for v = P.cb.vbot, c = cv_circ(c, v, ifelse(j == 4, P.cb.zbc, P.cb.zbl), P.cb.db, 'ex'); end
if j == 1, for v = P.cb.v([1 3]), c = cv_circ(c, v, P.cb.zp, P.cb.db, 'ex'); end, end
if j == 4                                           % corner: anchors of X pass under, in section
    c = cv_bar(c, [-hb an.uo-hb], R.typ(3).zT*[1 1], db, 'anch');
end

% grout pad, end plate (translucent), beam section
c = cv_rect(c, -P.ep.w/2-15, Y.ep_bot-15, P.ep.w/2+15, Y.ep_top+15, 'grout');
c = cv_rect(c, -P.ep.w/2, Y.ep_bot, P.ep.w/2, Y.ep_top, 'platet');
if P.dbl.on
    for sg = [-1 1], c = cv_rect(c, sg*P.dbl.gap/2, 0, sg*P.ep.w/2, Y.ep_top, 'hid'); end
end
c = cv_rect(c, -bm.b/2, -bm.tf, bm.b/2, 0, 'steel');
c = cv_rect(c, -bm.b/2, -bm.h, bm.b/2, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -bm.tw/2, -bm.h+bm.tf, bm.tw/2, -bm.tf, 'steel');
if P.rib.on, c = cv_rect(c, -P.rib.t/2, 0, P.rib.t/2, Y.ep_top, 'rib'); end
for z = [Y.zT Y.zS]
    for v = [-1 1]*an.vT
        c = cv_circ(c, v, z, an.wsh, 'ringok');
        c = cv_circ(c, v, z, db, 'anc');
    end
end

% dimensions
c = cv_dim(c, -an.vT, ztop, an.vT, ztop, 45, sprintf('%g', 2*an.vT));
c = cv_dim(c, -P.ep.w/2, ztop, -an.vT, ztop, 45, sprintf('%g', P.ep.w/2-an.vT));
c = cv_dim(c, an.vT, ztop, P.ep.w/2, ztop, 45, sprintf('%g', P.ep.w/2-an.vT));
c = cv_dim(c, -P.ep.w/2, ztop, P.ep.w/2, ztop, 100, sprintf('%g  (end plate)', P.ep.w));
c = cv_dim(c, an.vT, zB, P.rod.p, zB, -40, sprintf('%g', P.rod.p - an.vT), 8);
c = cv_dim(c, 0, zB, an.vT, zB, -40, sprintf('%g', an.vT), -6);
c = cv_dim(c, -xc, zB, xc, zB, -85, sprintf('%g  (column bars)', 2*xc));
c = cv_dim(c, -hb, zB, hb, zB, -125);
zz = sort([Y.ep_bot, -bm.h, Y.zS, 0, Y.zT, Y.ep_top]);
for i = 1:numel(zz)-1
    c = cv_dim(c, yE, zz(i), yE, zz(i+1), -35, num2str(round(10*(zz(i+1)-zz(i)))/10));
end
c = cv_dim(c, yE, Y.zS, yE, Y.zT, -95, sprintf('%.1f  (anchor rows)', Y.zT-Y.zS));
c = cv_dim(c, -yE, -P.cb.h, -yE, 0, 35);
c = cv_dim(c, -yE, 0, -yE, ztop, 35, sprintf('%g', ztop));

% labels
c = cv_lead(c, -P.ep.w/2+8, Y.ep_bot+15, -330, -470, {sprintf('end plate PL %gx%gx%g (translucent)', P.ep.t, P.ep.w, Y.H), sprintf('on a grout pad %g (light)', P.g)});
c = cv_lead(c, an.vT+8, Y.zT+8, 330, 290, {sprintf('2 top anchors %s, %s', an.lab, an.thr), 'circle: washer 30 against the fillets'});
c = cv_lead(c, an.vT, Y.zS-10, 330, -470, sprintf('2 shear anchors %s', an.lab));
c = cv_lead(c, max(P.cb.v), P.cb.zt(ti)-100, 330, -545, {sprintf('top bars %s%g of the beam in line,', '&#216;', P.cb.db), 'hook tails behind the plate'});
c = cv_lead(c, -xc, zc-40, -330, 280, sprintf('column bars %s%g', '&#216;', P.col.db));
c = cv_lead(c, -P.rod.p, 80, -330, 225, sprintf('rods of the steel column %s%g', '&#216;', P.rod.db));
if j == 4
    c = cv_lead(c, -an.vT, R.typ(3).zT, -330, 160, {'anchors of beam X (low), crossing:', 'those of Y rest on them'});
end
c = cv_text(c, 0, -455, 'Hardened pedestal', 'middle');
if j == 1
    c = cv_text(c, -yE+20, -175, 'Edge beam', 'start');
    c = cv_text(c, yE-20, -175, 'Edge beam', 'end');
else
    c = cv_text(c, yE-20, -175, 'beam in line with X', 'end');
    c = cv_text(c, -yE+20, 20, 'beam X (side)', 'start');
end
c = cv_text(c, -760, -620, sprintf('<tspan font-weight="bold">Type %s</tspan>, seen from outside', Y.name), 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_forces(P, R)
% Forces on the end plate, type E (DG1 large moment, rigid plate)
Y = R.typ(1);  D = Y.dg;  bm = P.bm;  tp = P.ep.t;  g = P.g;
c = cv_new(-760, 560, -400, 150, 0.85);
x0 = -g - tp;
c = cv_rect(c, -g, Y.ep_bot-15, 0, Y.ep_top+15, 'grout');
c = cv_rect(c, 0, Y.ep_bot-60, 260, Y.ep_top+60, 'conc');
c = cv_rect(c, x0, Y.ep_bot, -g, Y.ep_top, 'plate');
c = cv_rect(c, -700, -bm.h+bm.tf, x0, -bm.tf, 'web');
c = cv_rect(c, -700, -bm.tf, x0, 0, 'steel');
c = cv_rect(c, -700, -bm.h, x0, -bm.h+bm.tf, 'steel');
% bearing block
c = cv_rect(c, -g, Y.ep_bot, 40, Y.ep_bot + D.Y, 'zbrg');
for z = Y.ep_bot + linspace(4, D.Y-4, 4)
    c = cv_arrow(c, 60, z, 2, z, '#555555');
end
% anchor pull
c = cv_arrow(c, x0, Y.zT, 140, Y.zT, '#c0392b');
c = cv_bar(c, [x0-30 200], [Y.zT Y.zT], P.an.db, 'anch');
% shear
c = cv_arrow(c, -320, 60, -320, -60, '#1f3347');
c = cv_dim(c, -100, Y.ep_bot + D.Y/2, -100, Y.zT, 1, sprintf('lever arm %.1f', D.lev), 0);
c = cv_dim(c, 120, Y.ep_bot, 120, Y.ep_bot + D.Y, -1, sprintf('Y = %.1f', D.Y), 0);
c = cv_dim(c, -60, Y.ep_bot, -60, -bm.h + 0.025*bm.h, -1, sprintf('m = %.0f', D.m), 0);
c = cv_text(c, 150, Y.zT+10, sprintf('T = %.1f kN (2 anchors)', D.T/1e3), 'start');
c = cv_text(c, 150, Y.ep_bot-30, sprintf('C = T, fp = %.1f MPa over Y x %g', D.fp, P.ep.w), 'start');
c = cv_text(c, -310, -75, sprintf('V<sub>u</sub> = %.1f kN', Y.Vu/1e3), 'start');
c = cv_text(c, -690, 125, sprintf('M<sub>u</sub> = %.2f kN m at the column face', Y.Mu/1e6), 'start');
c = cv_text(c, -690, 95, 'T = q Y,  M = T (lever arm)  (DG1 Eq. 3.4.2, 3.4.3, P = 0)', 'start');
c = cv_text(c, -740, -385, '<tspan font-weight="bold">Type E: forces on the end plate</tspan>', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_cone(P, R, j)
% Breakout body of the top anchors and the beam bars inside it (with tolerances)
hb = P.col.b/2;  gx = @(u) u - hb;  Y = R.typ(j);  H = R.hk;  C = R.cone(j);  an = P.an;
c = cv_new(-430, 760, -330, 170, 0.95);
c = cv_rect(c, -hb, -300, hb, P.col.top, 'conc');
c = cv_rect(c, hb, -300, 700, 0, 'conc');
c = cv_bar(c, gx([-40 an.uT]), Y.zT*[1 1], an.db, 'anc');
c = cv_rect(c, gx(P.bp.u), Y.zT-P.bp.h/2, gx(P.bp.u+P.bp.t), Y.zT+P.bp.h/2, 'plate');
% the body: from the apex (start of the bend, hooks short by tol.ua) back to the face at 1:1.5
ua = H.uc - P.tol.ua;
for k = C.used
    rr = min(hypot(C.vb(k) - [-1 1]*an.vT, C.zb(k) - P.tol.zb - (Y.zT + P.tol.za*sign(Y.zT - C.zb(k)))));
    ub = ua - rr/1.5;
    zbk = C.zb(k) - P.tol.zb;
    c = cv_poly(c, gx([ua ub ub]), [Y.zT zbk Y.zT], 'zstrip');
end
k = C.used(1);  zbk = C.zb(k) - P.tol.zb;
[x, z] = hook(700, gx(P.cb.uh + P.tol.ub), zbk, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'ex');
ubk = C.uc_tol(k);
c = cv_dim(c, gx(P.cb.uh + P.tol.ub), zbk-25, gx(ubk), zbk-25, 1, sprintf('%.0f inside (l<sub>dh</sub> = %.0f)', C.ins_tol(k), H.ldh12), 0);
c = cv_dim(c, -hb, P.col.top, gx(ua), P.col.top, 30, sprintf('apex %.0f = back plate %.0f - %g', ua, H.uc, P.tol.ua));
c = cv_circ(c, gx(ua), Y.zT, 9, 'markr');
c = cv_lead(c, gx(250), zbk, 500, 120, {sprintf('bar at |v| = %g, %g low and %g short', abs(C.vb(k)), P.tol.zb, P.tol.ub), sprintf('(as placed: z = %g)', C.zb(k))});
c = cv_lead(c, gx(150), Y.zT + 4, -215, 40, sprintf('top anchor, z = %+.0f (+%g)', Y.zT, P.tol.za));
c = cv_text(c, -420, -310, sprintf('<tspan font-weight="bold">Type %s</tspan>: breakout body (blue), 1 along the anchor : 1.5 across (about 35 deg to the face), and the beam bar that limits it', Y.name), 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_plates(P, R)
% Shop detail of the two end plates: front view with holes, side view with the beam
an = P.an;  bm = P.bm;  tp = P.ep.t;
c = cv_new(-200, 1250, -380, 200, 0.80);
for k = 1:2
    j = 1 + 3*(k == 2);  Y = R.typ(j);  ox = (k-1)*640;
    c = cv_rect(c, ox-P.ep.w/2, Y.ep_bot, ox+P.ep.w/2, Y.ep_top, 'web');
    c = cv_rect(c, ox-bm.b/2, -bm.tf, ox+bm.b/2, 0, 'hidw');
    c = cv_rect(c, ox-bm.b/2, -bm.tf, ox+bm.b/2, 0, 'hid');
    c = cv_rect(c, ox-bm.b/2, -bm.h, ox+bm.b/2, -bm.h+bm.tf, 'hid');
    c = cv_rect(c, ox-bm.tw/2, -bm.h+bm.tf, ox+bm.tw/2, -bm.tf, 'hid');
    for z = [Y.zT Y.zS], for v = [-1 1]*an.vT
        c = cv_circ(c, ox+v, z, an.hole, 'vent');
    end, end
    if P.dbl.on
        for sg = [-1 1], c = cv_rect(c, ox+sg*P.dbl.gap/2, 0, ox+sg*P.ep.w/2, Y.ep_top, 'hid'); end
    end
    if P.rib.on
        c = cv_rect(c, ox-P.rib.t/2, 0, ox+P.rib.t/2, Y.ep_top, 'rib');
        Ls = Y.ep_top/tan(pi/6);
        c = cv_text(c, ox+10, -40, sprintf('rib PL %g on the web line,', P.rib.t), 'start');
        c = cv_text(c, ox+10, -58, sprintf('%.0f long on the top flange', 5*ceil(Ls/5)), 'start');
    end
    c = cv_dim(c, ox-P.ep.w/2, Y.ep_top, ox+P.ep.w/2, Y.ep_top, 30, sprintf('%g', P.ep.w));
    c = cv_dim(c, ox-an.vT, Y.ep_top, ox+an.vT, Y.ep_top, 65, sprintf('%g', 2*an.vT));
    c = cv_dim(c, ox-P.ep.w/2, Y.ep_top, ox-an.vT, Y.ep_top, 65, sprintf('%g', P.ep.w/2-an.vT));
    c = cv_dim(c, ox+an.vT, Y.ep_top, ox+P.ep.w/2, Y.ep_top, 65, sprintf('%g', P.ep.w/2-an.vT));
    zz = sort([Y.ep_bot, -bm.h, Y.zS, 0, Y.zT, Y.ep_top]);
    for i = 1:numel(zz)-1
        c = cv_dim(c, ox+P.ep.w/2, zz(i), ox+P.ep.w/2, zz(i+1), -30, num2str(round(10*(zz(i+1)-zz(i)))/10));
    end
    c = cv_dim(c, ox-P.ep.w/2, Y.ep_bot, ox-P.ep.w/2, Y.ep_top, 30, sprintf('%.0f', Y.H));
    if k == 1, ttl = sprintf('PL %gx%gx%g %s: types E, C1, CX', P.ep.w, Y.H, tp, P.st.name{P.ep.grade});
    else,      ttl = sprintf('PL %gx%gx%g %s: type CY', P.ep.w, Y.H, tp, P.st.name{P.ep.grade}); end
    c = cv_text(c, ox-120, -360, ['<tspan font-weight="bold">' ttl '</tspan>'], 'start');
end
c = cv_text(c, 1000, 120, sprintf('4 holes %s%g, drilled to the', '&#216;', an.hole), 'start');
c = cv_text(c, 1000, 100, 'measured anchor positions', 'start');
c = cv_text(c, 1000, 70, 'fillets: 8 mm on both faces of', 'start');
c = cv_text(c, 1000, 50, 'each flange, 5 mm both sides', 'start');
c = cv_text(c, 1000, 30, 'of the web, 6 mm both sides of', 'start');
c = cv_text(c, 1000, 10, 'the rib (shop)', 'start');
c = cv_text(c, 1000, -20, 'level line: top of steel (z = 0)', 'start');
c = cv_text(c, 1000, -40, 'is marked on both faces', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_reinf(P, R)
% Type E plate, enlarged: (A) extension of the end plate seen from the concrete side, with its
% strips; (B) the extra plate (two pieces) with its strips; (C) bearing zone below the bottom
% flange with the m and n strips. Flange, web and rib are on the other face (dashed).
Y = R.typ(1);  S = R.strip(1);  an = P.an;  bm = P.bm;  D = Y.dg;
B2 = P.ep.w/2;  gp = P.dbl.gap/2;  zt = Y.ep_top;  zb = Y.ep_bot;  v = an.vT;  z = Y.zT;
rt = P.rib.t/2;  rw = P.rib.t/2 + P.rib.w;  wf = P.w.flange;
c = cv_new(-120, 770, -95, 125, 1.75);
% ---- (A)
c = cv_rect(c, -B2, -40, B2, zt, 'web');
c = cv_rect(c, -bm.b/2, -bm.tf, bm.b/2, 0, 'hid');
c = cv_rect(c, -bm.tw/2, -40, bm.tw/2, -bm.tf, 'hid');
c = cv_rect(c, -rt, 0, rt, zt, 'hid');
c = cv_seg(c, [-B2 B2], [wf wf], 'cl');
c = cv_seg(c, [rw rw], [0 zt], 'cl');  c = cv_seg(c, -[rw rw], [0 zt], 'cl');
c = cv_rect(c, v-S.w1/2, wf, v+S.w1/2, z, 'ztol');
c = cv_rect(c, rw, z-S.w2/2, v, z+S.w2/2, 'zgap');
c = cv_circ(c, v, z, P.an.hole, 'vent');  c = cv_circ(c, -v, z, P.an.hole, 'vent');
c = cv_circ(c, v, z, 3, 'mark');
c = cv_dim(c, v+S.w1/2+8, wf, v+S.w1/2+8, z, -1, sprintf('x1 = %g', S.x1), 0);
c = cv_dim(c, v-S.w1/2, -12, v+S.w1/2, -12, -1, sprintf('b1 = %g', S.w1), 0);
c = cv_dim(c, rw, z+S.w2/2+6, v, z+S.w2/2+6, 1, sprintf('x2 = %g', S.x2), 0);
c = cv_dim(c, -B2-8, z-S.w2/2, -B2-8, z+S.w2/2, 1, sprintf('b2 = %g', S.w2), 0);
c = cv_dim(c, -v, zt+8, v, zt+8, 1, sprintf('%g', 2*v), 0);
c = cv_dim(c, B2+30, 0, B2+30, z, -1, sprintf('%g', z), 0);
c = cv_dim(c, B2+30, z, B2+30, zt, -1, sprintf('%g', zt-z), 0);
c = cv_text(c, -B2, -32, 'line: toe of the flange fillet (other face)', 'start');
c = cv_text(c, -110, 115, '<tspan font-weight="bold">A. End plate PL 12 A36, extension, concrete side</tspan>', 'start');
c = cv_text(c, -110, 104, 'green: strip to the flange; orange: strip to the rib', 'start');
% ---- (B)
ox = 290;
c = cv_rect(c, ox-B2, -40, ox+B2, zt, 'hid');
for sg = [-1 1], c = cv_rect(c, ox+sg*gp, 0, ox+sg*B2, zt, 'web'); end
c = cv_rect(c, ox+max(v-S.y1, gp), 0, ox+min(v+S.y1, B2), z, 'ztol');
c = cv_rect(c, ox+gp, max(z-S.y2, 0), ox+v, min(z+S.y2, zt), 'zgap');
c = cv_circ(c, ox+v, z, P.an.hole, 'vent');  c = cv_circ(c, ox-v, z, P.an.hole, 'vent');
c = cv_circ(c, ox+v, z, 3, 'mark');
for sg = [-1 1], c = cv_seg(c, ox+sg*[B2 gp gp], [0 0 zt], 'wside'); end
c = cv_dim(c, ox+B2+8, 0, ox+B2+8, z, -1, sprintf('y1 = %g', S.y1), 0);
c = cv_dim(c, ox+max(v-S.y1, gp), -12, ox+min(v+S.y1, B2), -12, -1, sprintf('b = %g', S.u1), 0);
c = cv_dim(c, ox+gp, z+5, ox+v, z+5, 1, sprintf('y2 = %g', S.y2), 0);
c = cv_dim(c, ox-B2-8, 0, ox-B2-8, zt, 1, sprintf('%g', zt), 0);
c = cv_dim(c, ox-B2, zt+8, ox-gp, zt+8, 1, sprintf('%g', B2-gp), 0);
c = cv_dim(c, ox-gp, zt+8, ox+gp, zt+8, 1, sprintf('%g', 2*gp), 0);
c = cv_text(c, ox-B2, -32, 'z = 0: top of the top flange', 'start');
c = cv_text(c, ox-110, 115, sprintf('<tspan font-weight="bold">B. Extra plate, 2 pieces PL %gx%gx%g A36</tspan>', P.dbl.t, B2-gp, zt), 'start');
c = cv_text(c, ox-110, 104, sprintf('red: fillets %g on the bottom and inner edges; gap %g over the rib', P.dbl.w, P.dbl.gap), 'start');
% ---- (C) bearing zone, shown 240 higher
ox = 590;  dz = 230;  zf = -bm.h + bm.tf;
c = cv_rect(c, ox-B2, zb+dz, ox+B2, -200+dz, 'web');
c = cv_rect(c, ox-bm.b/2, -bm.h+dz, ox+bm.b/2, zf+dz, 'hid');
c = cv_rect(c, ox-bm.tw/2, zf+dz, ox+bm.tw/2, -200+dz, 'hid');
zm = -bm.h + 0.025*bm.h;
c = cv_rect(c, ox-B2, zb+dz, ox+B2, zm+dz, 'zbrg');
c = cv_rect(c, ox+0.4*bm.b, zb+dz, ox+B2, -200+dz, 'zstrip');
c = cv_rect(c, ox-B2, zb+dz, ox-0.4*bm.b, -200+dz, 'zstrip');
c = cv_seg(c, ox+[-B2 B2], (zb + D.Y + dz)*[1 1], 'crack');
c = cv_dim(c, ox+B2+8, zb+dz, ox+B2+8, zm+dz, -1, sprintf('m = %.0f', D.m), 0);
c = cv_dim(c, ox+0.4*bm.b, zb-10+dz, ox+B2, zb-10+dz, -1, sprintf('n = %.0f', D.n), 0);
c = cv_dim(c, ox-B2-8, zb+dz, ox-B2-8, zb+D.Y+dz, 1, sprintf('Y = %.0f', D.Y), 0);
c = cv_dim(c, ox-B2, -200+dz+8, ox+B2, -200+dz+8, 1, sprintf('%g', P.ep.w), 0);
c = cv_text(c, ox-110, 115, '<tspan font-weight="bold">C. Bearing zone below the bottom flange</tspan>', 'start');
c = cv_text(c, ox-110, 104, 'grey: m strip; blue: n strips; dashed: top of the bearing block', 'start');
c = cv_text(c, -110, -88, sprintf('The pull of each top anchor (T/2 = %.1f kN) is shared: %.0f%% by the end plate, %.0f%% by the extra plate (pressed against it under the washer).', Y.Ta/1e3, 100*S.be, 100*(1-S.be)), 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_reinf_sec(P, R)
% Section through a top anchor of type E: grout, extra plate, end plate, flange, rib, nut
Y = R.typ(1);  an = P.an;  bm = P.bm;  tp = P.ep.t;  td = P.dbl.t;  g = P.g;
zt = Y.ep_top;  zb = Y.ep_bot;
c = cv_new(-330, 260, zb-50, zt+70, 1.0);
gx = @(u) u;
c = cv_rect(c, 0, zb-40, 250, zt+40, 'conc');
c = cv_rect(c, -g, zb-15, 0, zt+15, 'grout');
c = cv_rect(c, -g, 0, -g+td, zt, 'plate');
c = cv_rect(c, -g-tp, zb, -g, zt, 'plate');
x0 = -g-tp;
c = cv_rect(c, -320, -bm.tf, x0, 0, 'steel');
c = cv_rect(c, -320, -bm.h, x0, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -320, -bm.h+bm.tf, x0, -bm.tf, 'web');
Ls = zt/tan(pi/6);
c = cv_poly(c, [x0 x0 x0-20 x0-Ls], [0 zt zt 0], 'rib');
for zz = [0 -bm.tf -bm.h+bm.tf -bm.h]
    sg = 1;  if zz == -bm.tf || zz == -bm.h, sg = -1; end
    c = cv_poly(c, [x0 x0-P.w.flange x0], [zz zz zz+sg*P.w.flange], 'weldfill');
end
for zz = [Y.zT Y.zS]
    if zz == Y.zT, o = an.out; else, o = an.outS; end
    c = cv_bar(c, [-o 240], [zz zz], an.db, 'anc');
    c = cv_rect(c, x0-an.twsh, zz-an.wsh/2, x0, zz+an.wsh/2, 'tail');
    c = cv_rect(c, x0-an.twsh-an.tnut, zz-an.nut/2, x0-an.twsh, zz+an.nut/2, 'tail');
end
c = cv_dim(c, x0, zt+12, -g, zt+12, 1, sprintf('%g', tp), 0);
c = cv_dim(c, -g, zt+12, -g+td, zt+12, 1, sprintf('%g', td), 0);
c = cv_dim(c, -g+td, zt+12, 0, zt+12, 1, sprintf('%g', g-td), 0);
c = cv_dim(c, -g, zb-25, 0, zb-25, 1, sprintf('%g', g), 0);
c = cv_dim(c, 20, 0, 20, Y.zT, -1, sprintf('%g', Y.zT), 0);
c = cv_dim(c, 20, Y.zT, 20, zt, -1, sprintf('%g', zt-Y.zT), 0);
c = cv_dim(c, 20, -bm.h, 20, zb, 1, sprintf('%g', P.ep.under), 0);
c = cv_dim(c, 20, Y.zS, 20, 0, 1, sprintf('%.1f', -Y.zS), 0);
c = cv_dim(c, x0-Ls, -25, x0, -25, 1, sprintf('rib %.0f', 5*ceil(Ls/5)), 0);
c = cv_lead(c, -g+td/2, zt-5, 120, zt+55, sprintf('extra plate PL %g (2 pieces)', td));
c = cv_lead(c, -g-tp/2, -120, -200, -150, sprintf('end plate PL %gx%gx%g', tp, P.ep.w, Y.H));
c = cv_lead(c, -g/2, -150, 120, -200, sprintf('grout %g', g));
c = cv_lead(c, x0-an.twsh-6, Y.zT+12, -200, zt+50, 'washer 30 + nut 5/8"');
c = cv_lead(c, x0-30, 20, -250, 30, sprintf('rib PL %g', P.rib.t));
c = cv_text(c, 130, -50, 'concrete face', 'middle');
c = cv_text(c, -320, zt+60, '<tspan font-weight="bold">D. Type E, section through a top anchor (v = 35)</tspan>', 'start');
svg = cv_end(c);
end

% ===========================================================================
%  plate check page: one dimensioned diagram per check (type E)
% ===========================================================================
function svg = pc_forces(P, R)
% Side view at the plate: anchors, bearing block, the lengths of DG1 3.4
Y = R.typ(1);  D = Y.dg;  bm = P.bm;  tp = P.ep.t;  td = P.dbl.t;  g = P.g;
zt = Y.ep_top;  zb = Y.ep_bot;  x0 = -g - tp;
c = cv_new(-330, 330, zb-50, zt+45, 1.15);
c = cv_rect(c, 0, zb-30, 120, zt+30, 'conc');
c = cv_rect(c, -g, zb-10, 0, zt+10, 'grout');
c = cv_rect(c, -g, 0, -g+td, zt, 'plate');
c = cv_rect(c, x0, zb, -g, zt, 'plate');
c = cv_rect(c, -250, -bm.tf, x0, 0, 'steel');
c = cv_rect(c, -250, -bm.h, x0, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -250, -bm.h+bm.tf, x0, -bm.tf, 'web');
c = cv_rect(c, -g, zb, 40, zb + D.Y, 'zbrg');
c = cv_bar(c, [x0-20 110], [Y.zT Y.zT], P.an.db, 'anch');
c = cv_bar(c, [x0-20 110], [Y.zS Y.zS], P.an.db, 'anch');
c = cv_arrow(c, x0-30, Y.zT, 100, Y.zT, '#c0392b');
c = cv_text(c, 105, Y.zT+6, sprintf('T = %.1f kN', D.T/1e3), 'start');
for zz = zb + linspace(5, D.Y-5, 4), c = cv_arrow(c, 60, zz, 2, zz, '#555555'); end
c = cv_text(c, 45, zb - 20, sprintf('C = T at f_p = %.2f MPa', D.fp), 'start');
% dimensions on the left (geometry) and on the right (results)
c = cv_dim(c, -270, 0, -270, Y.zT, -1, sprintf('pf = %g', Y.zT), 0);
c = cv_dim(c, -270, Y.zT, -270, zt, -1, sprintf('%g', zt - Y.zT), 0);
c = cv_dim(c, -270, -bm.h, -270, 0, -1, sprintf('d = %g', bm.h), 0);
c = cv_dim(c, -270, zb, -270, -bm.h, -1, sprintf('%g', P.ep.under), 0);
c = cv_dim(c, -310, zb, -310, zt, -1, sprintf('N = %g', Y.H), 0);
c = cv_dim(c, 200, zb, 200, Y.zT, -1, sprintf('f + N/2 = %g', D.ft), 0);
c = cv_dim(c, 160, zb, 160, zb + D.Y, -1, sprintf('Y = %.1f', D.Y), 0);
c = cv_dim(c, 250, zb + D.Y/2, 250, Y.zT, -1, sprintf('lever = %.1f', D.lev), 0);
c = cv_text(c, -320, zt+35, '<tspan font-weight="bold">1. Forces on the plate (type E)</tspan>', 'start');
c = cv_text(c, -250, -120, sprintf('IPE 240, M = %.2f kN m', Y.Mu/1e6), 'start');
svg = cv_end(c);
end

function svg = pc_geo(P, R)
% Extension of the end plate, column side: what the strips can land on
Y = R.typ(1);  bm = P.bm;  an = P.an;  B2 = P.ep.w/2;  zt = Y.ep_top;
wf = P.w.flange;  rt = P.rib.t/2;  rw = rt + P.rib.w;  v = an.vT;  z = Y.zT;
c = cv_new(-260, 150, -60, 110, 2.4);
c = cv_rect(c, -B2, -30, B2, zt, 'web');
c = cv_rect(c, -bm.b/2, -bm.tf, bm.b/2, 0, 'hid');
c = cv_rect(c, -rt, 0, rt, zt, 'hid');
c = cv_rect(c, -bm.tw/2, -30, bm.tw/2, -bm.tf, 'hid');
c = cv_seg(c, [-bm.b/2-wf bm.b/2+wf], [wf wf], 'limit');
c = cv_seg(c, [rw rw], [wf zt], 'limit');  c = cv_seg(c, -[rw rw], [wf zt], 'limit');
for vv = [-1 1]*v, c = cv_circ(c, vv, z, an.hole, 'vent');  c = cv_circ(c, vv, z, 2.5, 'mark'); end
c = cv_dim(c, 0, zt+8, v, zt+8, 1, sprintf('vT = %g', v), 0);
c = cv_dim(c, v, zt+8, B2, zt+8, 1, sprintf('%g', B2 - v), 0);
c = cv_dim(c, 0, zt+22, B2, zt+22, 1, sprintf('B/2 = %g', B2), 0);
c = cv_dim(c, B2+8, 0, B2+8, z, -1, sprintf('pf = %g', z), 0);
c = cv_dim(c, B2+8, z, B2+8, zt, -1, sprintf('%g', zt - z), 0);
c = cv_dim(c, B2+26, 0, B2+26, wf, -1, sprintf('w = %g', wf), 0);
c = cv_dim(c, 0, -20, rw, -20, -1, sprintf('t_rib/2 + w = %g + %g', rt, P.rib.w), 0);
c = cv_dim(c, 0, -40, bm.b/2+wf, -40, -1, sprintf('bf/2 + w = %g + %g', bm.b/2, wf), 0);
c = cv_lead(c, -40, wf, -135, 30, {'support 1: toe of the flange fillet', sprintf('(z = %g, |v| &#8804; %g)', wf, bm.b/2+wf)});
c = cv_lead(c, -rw, 40, -135, 75, {'support 2: toe of the rib fillet', sprintf('(|v| = %g, z = %g to %g)', rw, wf, zt)});
c = cv_text(c, -255, 104, '<tspan font-weight="bold">2a. End plate extension, column side: the supports</tspan>', 'start');
c = cv_text(c, -255, -55, 'dashed: flange, web and rib (on the beam side); thick lines: the two supports', 'start');
svg = cv_end(c);
end

function svg = pc_ten1(P, R)
% Strips of the end plate around the right top anchor
Y = R.typ(1);  S = R.strip(1);  bm = P.bm;  an = P.an;  B2 = P.ep.w/2;  zt = Y.ep_top;
wf = P.w.flange;  rt = P.rib.t/2;  rw = rt + P.rib.w;  v = an.vT;  z = Y.zT;
c = cv_new(-60, 140, -50, 100, 3.0);
c = cv_rect(c, -30, -15, B2, zt, 'web');
c = cv_seg(c, [-30 bm.b/2+wf], [wf wf], 'limit');
c = cv_seg(c, [rw rw], [wf zt], 'limit');
c = cv_seg(c, [bm.b/2+wf bm.b/2+wf], [-15 wf], 'cl');
c = cv_rect(c, v-S.w1/2, wf, v+S.w1/2, z, 'ztol');
c = cv_rect(c, rw, max(z-S.x2, wf), v, min(z+S.x2, zt), 'zgap');
c = cv_circ(c, v, z, an.hole, 'vent');  c = cv_circ(c, v, z, 2, 'mark');
% strip 1 (to the flange): span x1 (anchor to the fillet toe), width b1 = 2 x1, cut to the support
c = cv_dim(c, v+S.w1/2+6, wf, v+S.w1/2+6, z, -1, sprintf('x1 = %g - %g = %g', z, wf, S.x1), 0);
c = cv_dim(c, v-S.w1/2, -8, v+S.w1/2, -8, -1, sprintf('b1 = %g', S.w1), 0);
c = cv_dim(c, v-S.x1, -26, v, -26, -1, sprintf('%g', S.x1), 0);
c = cv_dim(c, v, -26, v+S.x1, -26, -1, sprintf('%g', S.x1), 0);
% strip 2 (to the rib): span x2, width b2 = 2 x2 cut between the flange fillet and the plate top
c = cv_dim(c, rw, zt+8, v, zt+8, 1, sprintf('x2 = %g - %g = %g', v, rw, S.x2), 0);
c = cv_dim(c, -12, max(z-S.x2, wf), -12, min(z+S.x2, zt), 1, sprintf('b2 = %g', S.w2), 0);
c = cv_text(c, -55, 92, '<tspan font-weight="bold">2b. End plate, right anchor: strip 1 (green) to the flange, strip 2 (orange) to the rib</tspan>', 'start');
c = cv_text(c, -55, -45, sprintf('strip 1 spans %g..%g (inside %g..%g: lands on the flange); strip 2 spans z = %g..%g, cut to %g..%g', v-S.x1, v+S.x1, rw, bm.b/2+wf, z-S.x2, z+S.x2, max(z-S.x2, wf), min(z+S.x2, zt)), 'start');
svg = cv_end(c);
end

function svg = pc_ten2(P, R)
% Strips of the extra plate (right piece)
Y = R.typ(1);  S = R.strip(1);  an = P.an;  B2 = P.ep.w/2;  zt = Y.ep_top;  gp = P.dbl.gap/2;  v = an.vT;  z = Y.zT;
c = cv_new(-60, 140, -50, 100, 3.0);
c = cv_rect(c, -30, -15, B2, zt, 'hid');
c = cv_rect(c, gp, 0, B2, zt, 'web');
c = cv_rect(c, -B2, 0, -gp, zt, 'web');
c = cv_seg(c, [gp B2], [0 0], 'limit');  c = cv_seg(c, [gp gp], [0 zt], 'limit');
c = cv_seg(c, [-gp -30], [0 0], 'limit');  c = cv_seg(c, [-gp -gp], [0 zt], 'limit');
c = cv_rect(c, max(v-S.y1, gp), 0, min(v+S.y1, B2), z, 'ztol');
c = cv_rect(c, gp, max(z-S.y2, 0), v, min(z+S.y2, zt), 'zgap');
c = cv_circ(c, v, z, an.hole, 'vent');  c = cv_circ(c, v, z, 2, 'mark');
c = cv_dim(c, min(v+S.y1, B2)+6, 0, min(v+S.y1, B2)+6, z, -1, sprintf('y1 = %g', S.y1), 0);
c = cv_dim(c, max(v-S.y1, gp), -8, min(v+S.y1, B2), -8, -1, sprintf('b = %g', S.u1), 0);
c = cv_dim(c, gp, zt+8, v, zt+8, 1, sprintf('y2 = %g - %g = %g', v, gp, S.y2), 0);
c = cv_dim(c, -12, 0, -12, zt, 1, sprintf('b = %g', S.u2), 0);
c = cv_dim(c, -gp, -28, gp, -28, -1, sprintf('gap %g', 2*gp), 0);
c = cv_dim(c, gp, -28, B2, -28, -1, sprintf('%g', B2 - gp), 0);
c = cv_text(c, -55, 92, '<tspan font-weight="bold">2c. Extra plate, right piece: strips to its edge welds on the flange line (z = 0) and the rib line</tspan>', 'start');
c = cv_text(c, -55, -45, sprintf('thick lines: the fillet welds that are its supports, over the flange and over the rib (the rib is %g thick, the gap %g)', P.rib.t, 2*gp), 'start');
svg = cv_end(c);
end

function svg = pc_pry(P, R)
% AISC Manual prying, side view at a top anchor: b, b', a; plan: tributary width p
Y = R.typ(1);  bm = P.bm;  an = P.an;  tp = P.ep.t;  td = P.dbl.t;  zt = Y.ep_top;  z = Y.zT;
c = cv_new(-140, 160, -40, 95, 2.6);
c = cv_rect(c, 0, -30, tp, zt, 'plate');
c = cv_rect(c, tp, 0, tp+td, zt, 'plate');
c = cv_rect(c, -120, -bm.tf, 0, 0, 'steel');
c = cv_poly(c, [0 -P.w.flange 0], [0 0 P.w.flange], 'weldfill');
c = cv_bar(c, [-30 70], [z z], an.db, 'anc');
c = cv_rect(c, -an.twsh, z-an.wsh/2, 0, z+an.wsh/2, 'tail');
c = cv_rect(c, -an.twsh-an.tnut, z-an.nut/2, -an.twsh, z+an.nut/2, 'tail');
c = cv_dim(c, 50, 0, 50, z, -1, sprintf('b = %g', z), 0);
c = cv_dim(c, 80, 0, 80, z - an.db/2, -1, sprintf('b'' = b - d/2 = %g', z - an.db/2), 0);
c = cv_dim(c, 50, z, 50, zt, -1, sprintf('a = %g', zt - z), 0);
c = cv_dim(c, -60, 0, -60, P.w.flange, 1, sprintf('%g', P.w.flange), 0);
c = cv_text(c, -135, 88, '<tspan font-weight="bold">3. Prying: section through a top anchor</tspan>', 'start');
c = cv_text(c, -135, -32, sprintf('p = tributary width per anchor = (bf + 25)/2 = %.1f (AISC 358 6.6 limit on the effective width)', (bm.b + 25)/2), 'start');
svg = cv_end(c);
end

function svg = pc_brg(P, R)
% Bearing side, column side view of the bottom of the plate: m and n strips, bearing block Y
Y = R.typ(1);  D = Y.dg;  bm = P.bm;  B2 = P.ep.w/2;  zb = Y.ep_bot;
zm = -bm.h + 0.025*bm.h;  vn = 0.4*bm.b;
c = cv_new(-150, 150, zb-55, -170, 2.4);
c = cv_rect(c, -B2, zb, B2, -185, 'web');
c = cv_rect(c, -bm.b/2, -bm.h, bm.b/2, -bm.h+bm.tf, 'hid');
c = cv_rect(c, -bm.tw/2, -bm.h+bm.tf, bm.tw/2, -185, 'hid');
c = cv_rect(c, -B2, zb, B2, zb + D.Y, 'zbrg');
c = cv_seg(c, [-B2 B2], [zm zm], 'limit');
c = cv_seg(c, [vn vn], [zb -185], 'limit');  c = cv_seg(c, -[vn vn], [zb -185], 'limit');
c = cv_dim(c, B2+8, zb, B2+8, -bm.h, -1, sprintf('%g', P.ep.under), 0);
c = cv_dim(c, B2+8, -bm.h, B2+8, zm, -1, sprintf('%g', 0.025*bm.h), 0);
c = cv_dim(c, B2+34, zb, B2+34, zm, -1, sprintf('m = %g', D.m), 0);
c = cv_dim(c, -B2-8, zb, -B2-8, zb + D.Y, 1, sprintf('Y = %.1f', D.Y), 0);
c = cv_dim(c, vn, zb-10, B2, zb-10, -1, sprintf('n = %g', D.n), 0);
c = cv_dim(c, -vn, zb-10, vn, zb-10, -1, sprintf('0.8 bf = %g', 0.8*bm.b), 0);
c = cv_dim(c, -B2, zb-30, B2, zb-30, -1, sprintf('B = %g', P.ep.w), 0);
c = cv_text(c, -145, -177, '<tspan font-weight="bold">4. Bearing side, column side view: m strip (below the 0.95 d line), n strips (beyond 0.8 bf)</tspan>', 'start');
c = cv_text(c, -B2+4, zb + D.Y + 4, 'top of the bearing block', 'start');
svg = cv_end(c);
end

% ===========================================================================
%  anchor check page: tension anchors and back plate (type E)
% ===========================================================================
function svg = ta_geo(P, R)
% Plan of the edge column at the level of the top anchors
hb = P.col.b/2;  an = P.an;  bp = P.bp;  gx = @(u) u - hb;  bm = P.bm;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;  xh = hb - P.col.cover - P.col.dtie/2;
c = cv_new(-470, 480, -230, 300, 1.15);
c = cv_rect(c, -hb, -hb, hb, hb, 'conc');
c = cv_rect(c, hb, -P.cb.b/2, 330, P.cb.b/2, 'conc');
c = cv_rect(c, -xh, -xh, xh, xh, 'hoopr');
for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, c = cv_circ(c, sx*xc, sy*xc, P.col.db, 'col'); end
end, end
for sx = [-1 1], for sy = [-1 1], c = cv_circ(c, sx*P.rod.p, sy*P.rod.p, P.rod.db, 'rodc'); end, end
c = cv_rect(c, gx(-P.g-P.ep.t), -P.ep.w/2, gx(-P.g), P.ep.w/2, 'plate');
c = cv_rect(c, gx(-P.g), -P.ep.w/2, gx(0), P.ep.w/2, 'grout');
c = cv_rect(c, -320, -bm.b/2, gx(-P.g-P.ep.t), bm.b/2, 'steel');
for v = [-1 1]*an.vT
    c = cv_bar(c, gx([-an.out an.uT]), [v v], an.db, 'anc');
    c = cv_rect(c, gx(bp.u-an.tnut), v-an.nut/2, gx(bp.u), v+an.nut/2, 'tail');
    c = cv_rect(c, gx(bp.u+bp.t+an.twsh), v-an.nut/2, gx(bp.u+bp.t+an.twsh+an.tnut), v+an.nut/2, 'tail');
end
c = cv_rect(c, gx(bp.u), -bp.w/2, gx(bp.u+bp.t), bp.w/2, 'plate');
c = cv_dim(c, -hb, hb+10, gx(bp.u), hb+10, 1, sprintf('%g (bearing face)', bp.u), 0);
c = cv_dim(c, gx(bp.u), hb+10, gx(bp.u+bp.t), hb+10, 1, sprintf('%g', bp.t), 0);
c = cv_dim(c, -hb, hb+38, hb, hb+38, 1, sprintf('%g', P.col.b), 0);
c = cv_dim(c, -hb, hb+66, gx(an.uT), hb+66, 1, sprintf('%.0f (end of the bar)', an.uT), 0);
c = cv_dim(c, gx(P.col.b-P.col.cover), -hb-10, gx(bp.u), -hb-10, -1, sprintf('%g', bp.u-(P.col.b-P.col.cover)), 0);
c = cv_dim(c, gx(P.col.b-P.col.cover-P.col.dtie), -hb-10, gx(P.col.b-P.col.cover), -hb-10, -1, '', 0);
c = cv_dim(c, -hb-20, -an.vT, -hb-20, an.vT, 1, sprintf('s = %g', 2*an.vT), 0);
c = cv_dim(c, gx(250), 0, gx(250), an.vT, -1, sprintf('%g', an.vT), 0);
c = cv_dim(c, gx(250), an.vT, gx(250), P.rod.p, -1, sprintf('%g', P.rod.p-an.vT), 0);
c = cv_dim(c, -hb-60, -bp.w/2, -hb-60, bp.w/2, 1, sprintf('back plate %g', bp.w), 0);
c = cv_lead(c, gx(bp.u+bp.t/2), bp.w/2-5, 250, 170, {sprintf('back plate PL %gx%gx%g %s', bp.t, bp.h, bp.w, P.st.name{bp.grade}), 'behind the far column bars and far ties'});
c = cv_lead(c, xh, -xh+30, 250, -150, sprintf('far ties: outer face at u = %g', P.col.b - P.col.cover));
c = cv_lead(c, xc, 0, 250, -190, sprintf('far mid-face bar: %.0f clear to the nut corners', an.vT - an.nut/sqrt(3) - P.col.db/2));
c = cv_lead(c, -xc, 0, -260, -120, sprintf('front mid-face bar: %.0f clear to the anchors', an.vT - an.db/2 - P.col.db/2));
c = cv_text(c, -460, 290, '<tspan font-weight="bold">A. Plan at the top anchors, z = +29 (type E)</tspan>', 'start');
svg = cv_end(c);
end

function svg = ta_bar(P, R)
% The top anchor bar: lengths, threads, nuts
an = P.an;  bp = P.bp;  L1 = an.out + an.uT;  ub0 = bp.u - an.tnut - 15;
c = cv_new(-110, 430, -70, 70, 1.5);
c = cv_rect(c, 0, -40, bp.u, 40, 'conc');
c = cv_bar(c, [-an.out an.uT], [0 0], an.db, 'anc');
c = cv_bar(c, [-an.out -an.out+100], [0 0], an.db+5, 'anch');
c = cv_bar(c, [ub0 an.uT], [0 0], an.db+5, 'anch');
c = cv_rect(c, bp.u, -bp.h/2, bp.u+bp.t, bp.h/2, 'plate');
c = cv_rect(c, bp.u-an.tnut, -an.nut/2, bp.u, an.nut/2, 'tail');
c = cv_rect(c, bp.u+bp.t, -an.wsh/2, bp.u+bp.t+an.twsh, an.wsh/2, 'tail');
c = cv_rect(c, bp.u+bp.t+an.twsh, -an.nut/2, bp.u+bp.t+an.twsh+an.tnut, an.nut/2, 'tail');
c = cv_dim(c, -an.out, 22, an.uT, 22, 1, sprintf('L = %.0f', L1), 0);
c = cv_dim(c, -an.out, 46, 0, 46, 1, sprintf('%g out of the face', an.out), 0);
c = cv_dim(c, 0, -30, bp.u, -30, -1, sprintf('h_ef = %g (face to bearing face)', bp.u), 0);
c = cv_dim(c, ub0, 46, an.uT, 46, 1, sprintf('%.0f thread', an.uT - ub0), 0);
c = cv_dim(c, bp.u, -30, bp.u+bp.t, -30, -1, sprintf('%g', bp.t), 0);
c = cv_lead(c, bp.u+bp.t+an.twsh+an.tnut/2, -an.nut/2, 330, -60, 'nut + washer: carries T_a');
c = cv_lead(c, bp.u-an.tnut/2, an.nut/2, 250, 62, 'front nut, no washer: positions the plate');
c = cv_text(c, -105, 62, sprintf('<tspan font-weight="bold">B. Top anchor: threaded rod %s %s</tspan>', an.thr, an.grade), 'start');
c = cv_text(c, 60, -2, 'concrete', 'start');
svg = cv_end(c);
end

function svg = ta_bp(P, R)
% Back plate seen along the anchors: tributary areas, strip for bending
Y = R.typ(1);  an = P.an;  bp = P.bp;  a = bp.w/2 - an.vT;
c = cv_new(-110, 110, -60, 60, 3.2);
c = cv_rect(c, -bp.w/2, -bp.h/2, bp.w/2, bp.h/2, 'web');
c = cv_rect(c, 0, -bp.h/2, bp.w/2, bp.h/2, 'ztol');
for v = [-1 1]*an.vT
    c = cv_circ(c, v, 0, an.hole, 'vent');
    c = cv_circ(c, v, 0, an.wsh, 'ringok');
end
c = cv_dim(c, -bp.w/2, bp.h/2+6, bp.w/2, bp.h/2+6, 1, sprintf('b = %g', bp.w), 0);
c = cv_dim(c, -an.vT, bp.h/2+18, an.vT, bp.h/2+18, 1, sprintf('s = %g', 2*an.vT), 0);
c = cv_dim(c, an.vT, -bp.h/2-6, bp.w/2, -bp.h/2-6, -1, sprintf('a = %g', a), 0);
c = cv_dim(c, bp.w/2+6, -bp.h/2, bp.w/2+6, bp.h/2, -1, sprintf('h = %g', bp.h), 0);
c = cv_text(c, -105, 55, '<tspan font-weight="bold">C. Back plate, seen along the anchors</tspan>', 'start');
c = cv_text(c, -105, -55, sprintf('t = %g. Green: bearing area of one anchor = half the plate less its hole; circles: washers %g', bp.t, an.wsh), 'start');
svg = cv_end(c);
end

function svg = ta_bpm(P, R)
% Back plate as a beam along its length (type E): loads, moment and shear along the plate,
% for the nut pushing on its ring (blue) and for a point push at the axis (grey), against
% the capacity of the width left at each cut (red). Lengths along the plate drawn x 2.
B = R.bpb(1);  K = R.bpk;  bp = P.bp;  an = P.an;  L = bp.w/2;  t = bp.t;  rh = an.hole/2;  ro = an.dw/2;
Fy = P.st.Fy(bp.grade);  Fu = P.st.Fu(bp.grade);  sx = 2;
k = unique([1:8:numel(B.x), numel(B.x)]);  xk = B.x(k);
X = sx*[-flipud(xk); xk];  mir = @(v) [flipud(v(k)); v(k)];
km = 150e-6;  kv = 0.6e-3;                          % drawing units per N mm and per N
y1 = 200;  y2 = 60;  y3 = -85;                      % plate, moment axis, shear axis
c = cv_new(-215, 330, -140, 268, 2.2);
% 1. plate, loads
c = cv_rect(c, -sx*L, y1, sx*L, y1 + t, 'web');
for xa = [-1 1]*an.vT
    c = cv_rect(c, sx*(xa - rh), y1, sx*(xa + rh), y1 + t, 'zgap');
end
for x = -L+5 : 10 : L-5                             % concrete pressure, from above
    c = sarrow(c, sx*x, y1 + t + 22, sx*x, y1 + t + 1, '#7f8c8d');
end
for xa = [-1 1]*an.vT                               % nut ring, from below; arrows ~ local push
    for d = [-ro+0.6 : 1.2 : -rh-0.4, rh+0.4 : 1.2 : ro-0.6]
        cc = 2*sqrt(max(ro^2 - d^2, 0)) - 2*sqrt(max(rh^2 - d^2, 0));
        c = sarrow(c, sx*(xa + d), y1 - 4 - 22*cc/(2*sqrt(ro^2 - rh^2)), sx*(xa + d), y1 - 1, '#1f5f8b');
    end
    c = cv_seg(c, sx*[xa xa], [y1 - 36 y1 - 2], 'mA');
end
c = cv_text(c, -sx*L, y1 + t + 30, sprintf('concrete pushes the plate: w = T/b = %.0f N/mm', B.w), 'start');
c = cv_text(c, -sx*L, y1 - 50, sprintf('nuts push back on a ring &#216;%g to &#216;%g (blue); grey: a point push at the axis', an.hole, an.dw), 'start');
c = cv_text(c, sx*L + 8, y1 + 2, sprintf('PL %g; holes &#216;%g in orange', t, an.hole), 'start');
% 2. moment
c = cv_seg(c, sx*[-L L], [y2 y2], 'dim');
c = cv_seg(c, X, y2 + km*mir(0.9*Fy*B.bn*t^2/4), 'limit2');
c = cv_seg(c, X, y2 + km*mir(abs(K.M)), 'mA');
c = cv_seg(c, X, y2 + km*mir(abs(B.M)), 'mB');
c = cv_text(c, sx*L + 8, y2 + km*0.9*Fy*bp.h*t^2/4 - 3, sprintf('&#966;Mp, full width %.3f', 0.9*Fy*bp.h*t^2/4*1e-6), 'start');
c = cv_text(c, sx*L + 8, y2 + km*0.9*Fy*(bp.h - an.hole)*t^2/4 - 3, sprintf('&#966;Mp through the hole %.3f', 0.9*Fy*(bp.h - an.hole)*t^2/4*1e-6), 'start');
c = cv_text(c, 0, y2 + km*B.M0 + 5, sprintf('%.3f', B.M0*1e-6), 'middle');
c = cv_text(c, sx*an.vT, y2 + km*K.Ma + 5, sprintf('%.3f point', K.Ma*1e-6), 'middle');
c = cv_text(c, -sx*an.vT, y2 - 14, sprintf('ring: %.3f at the worst cut through the hole', B.Mh*1e-6), 'middle');
c = cv_text(c, -210, y2 + 20, 'moment |M|, kN m', 'start');
% 3. shear
c = cv_seg(c, sx*[-L L], [y3 y3], 'dim');
c = cv_seg(c, X, y3 + kv*mir(0.75*0.6*Fu*B.bn*t), 'limit2');
c = cv_seg(c, X, y3 + kv*mir(abs(K.V)), 'mA');
c = cv_seg(c, X, y3 + kv*mir(abs(B.V)), 'mB');
c = cv_text(c, sx*L + 8, y3 + kv*0.75*0.6*Fu*bp.h*t - 3, sprintf('&#966;Rn rupture, full width %.0f', 0.75*0.6*Fu*bp.h*t*1e-3), 'start');
c = cv_text(c, sx*L + 8, y3 + kv*B.Cvr - 3, sprintf('through the hole %.0f', B.Cvr*1e-3), 'start');
c = cv_text(c, sx*an.vT, y3 + kv*K.Va + 5, sprintf('%.1f point', K.Va*1e-3), 'middle');
c = cv_text(c, -sx*an.vT, y3 - 14, sprintf('ring: %.1f through the hole', B.Vmx*1e-3), 'middle');
c = cv_text(c, -210, y3 + 20, 'shear |V|, kN', 'start');
c = cv_dim(c, -sx*an.vT, y3 - 26, sx*an.vT, y3 - 26, 1, sprintf('s = %g', 2*an.vT), 0);
c = cv_dim(c, -sx*L, y3 - 42, sx*L, y3 - 42, 1, sprintf('b = %g', bp.w), 0);
c = cv_text(c, -210, 260, '<tspan font-weight="bold">C2. Back plate as a beam along its length (type E); lengths drawn x 2</tspan>', 'start');
svg = cv_end(c);
end

function svg = ta_brk(P, R)
% The breakout of the concrete in front of the back plate (type E), section along the beam:
% the body (apex at the bearing face, 1 : 1.5 as in the anchor reinforcement check), the order in
% which it cracks, and how the beam bars take the pull once it has cracked
Y = R.typ(1);  an = P.an;  bp = P.bp;  hb = P.col.b/2;  gx = @(u) u - hb;  ztop = P.col.top;  cj = P.col.cj;
zt = P.cb.zt(2);  uh = P.cb.uh0;  xR = 520;  k = 1.5;  zA = Y.zT;  C = R.cone(1);
% ACI cone: 1.5 across for 1 along the anchor (56 deg to the axis, about 35 deg to the face);
% section through the anchor axis, apex at the bearing face of the back plate (as in ca_calc)
uT = bp.u - (ztop - zA)/k;                           % upper crack reaches the top of the pedestal
uc = bp.u - (zA - P.col.cj)/k;                       % lower crack reaches the cold joint
rB = hypot(an.vT, zA - zt);                          % centre bar: 35 mm beside the anchor axis
uB = bp.u - rB/k;                                    % where it crosses the body (= ca_calc)
c = cv_new(-440, 760, -615, 240, 0.95);
c = cv_rect(c, -hb, cj, hb, ztop, 'conc');
c = cv_rect(c, hb, -P.cb.h, xR, 0, 'conc');
c = cv_poly(c, gx([bp.u uT 0 0 uc]), [zA ztop ztop cj cj], 'clash');
c = cv_dim(c, gx(0), cj, gx(uc), cj, -30, sprintf('%.0f', uc));         % where the body ends: on the cold joint
c = cv_circ(c, gx(uc), cj, 9, 'markr');
c = cv_text(c, gx(uc) + 14, cj - 40, sprintf('the body ends on the cold joint (z = %g), %.0f from the face', cj, uc), 'start');
% ---- all the reinforcement (projected on this section; bars at other v drawn at their level)
rc = P.col.cover + P.col.dtie + P.col.db/2;  zhA = ztop - P.col.ctop - P.col.db/2;  zhB = P.col.zhB;
for u = [rc P.col.b - rc], c = cv_bar(c, gx([u u]), [cj zhA], P.col.db, 'colh'); end           % column bars
for u = hb + [-8 8], c = cv_circ(c, gx(u), zhB, P.col.db, 'col'); end                      % side mid bars, level B, across, on the A1
c = cv_bar(c, gx([rc rc + 248]), [zhA zhA], P.col.db, 'colh');                               % front / far bars: level-A tails along the anchors
c = cv_bar(c, gx([P.col.b - rc, P.col.b - rc - 248]), [zhA zhA], P.col.db, 'colh');
for u = [hb - P.rod.p, hb + P.rod.p], c = cv_bar(c, gx([u u]), [cj ztop + 60], P.rod.db, 'rod'); end   % anchored > 1 m below
uL = P.col.cover + P.hoop.db/2;  uRt = P.col.b - uL;                                          % joint ties: side legs
for z = P.hoop.z, c = cv_bar(c, gx([uL uRt]), [z z], P.hoop.db, ifelse(z == max(P.hoop.z), 'tie', 'tieh')); end
u14 = rc - P.col.db/2 - P.top.db/2;                                                           % closed ties 14: side legs
for z = P.top.z, c = cv_bar(c, gx([u14 P.col.b - u14]), [z z], P.top.db, 'tie14'); end
if P.ub.on                                                                                    % U-bar (both legs, one behind the other)
    rcu = 3.5*P.ub.db;  tt = linspace(0, pi/2, 10);
    c = cv_bar(c, gx([P.ub.u*ones(1,1), P.ub.u - rcu + rcu*cos(tt), P.ub.u - rcu - 12*P.ub.db]), [R.ub.zU, P.ub.zbot + rcu - rcu*sin(tt), P.ub.zbot], P.ub.db, 'ubar');
end
[x, z] = hook(xR, gx(P.cb.uh + P.cb.db), P.cb.zp, P.cb.db, -1);  c = cv_bar(c, x, z, P.cb.db, 'ex2');   % the 2 extra beam bars
[x, z] = hook(xR, gx(uh), zt, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'exb');
% where each bar crosses the fracture surface (3D: r from the nearest anchor axis, u = 365 - r/1.5)
vL = hb - u14;  vJ = hb - uL;
xs = {bp.u - hypot(an.vT, zA - zt)/k, zt, 'markr'; bp.u - hypot(max(P.cb.v) - an.vT, zA - zt)/k, zt, 'markr'; ...
      bp.u - hypot(max(P.cb.v) - an.vT, zA - P.cb.zp)/k, P.cb.zp, 'markr'; ...
      bp.u - hypot(vL - an.vT, zA - P.top.z(2))/k, P.top.z(2), 'markr'; bp.u - hypot(vL - an.vT, zA - P.top.z(1))/k, P.top.z(1), 'markr'; ...
      bp.u - hypot(vJ - an.vT, zA - max(P.hoop.z))/k, max(P.hoop.z), 'markg';};
for i = 1:size(xs, 1), c = cv_circ(c, gx(xs{i,1}), xs{i,2}, 11, xs{i,3}); end
if P.ub.on, c = cv_circ(c, gx(P.ub.u), zA - sqrt(max(((bp.u - P.ub.u)*k)^2 - (P.ub.v - an.vT)^2, 0)), 11, 'markg'); end
c = cv_bar(c, gx([-an.out an.uT]), [zA zA], an.db, 'anc');
c = cv_rect(c, gx(bp.u), zA - bp.h/2, gx(bp.u + bp.t), zA + bp.h/2, 'plate');
c = cv_rect(c, gx(bp.u - an.tnut), zA - an.nut/2, gx(bp.u), zA + an.nut/2, 'tail');
c = cv_rect(c, gx(bp.u + bp.t), zA - an.nut/2, gx(bp.u + bp.t + an.twsh + an.tnut), zA + an.nut/2, 'tail');
% forces
c = cv_arrow(c, gx(-an.out) + 10, zA, gx(-an.out) - 70, zA, '#c0392b');
c = cv_text(c, gx(-an.out) - 75, zA + 14, sprintf('T = %.0f kN', Y.T/1e3), 'end');
c = cv_arrow(c, gx(bp.u - 8), zA - 12, gx(uB + 12), zt + 10, '#e67e22');
c = cv_arrow(c, gx(uB - 6), zt, gx(uh + 40), zt, '#1f5f8b');
c = cv_circ(c, gx(uB), zt, 16, 'markr');
c = cv_circ(c, gx(uh + P.cb.db/2), zt - 60, 22, 'markr');
% stages
c = cv_text(c, gx(bp.u) + 12, zA + bp.h/2 + 14, '1', 'middle');
c = cv_text(c, gx(uT), ztop + 14, '2', 'middle');
c = cv_text(c, gx(uB), zt - 30, '3', 'middle');
c = cv_text(c, gx(uh + P.cb.db/2) + 22, zt - 64, '4', 'start');
c = cv_lead(c, gx(bp.u - 40), ztop - 10, 260, 205, {'1  first cracks at the edges of the plate,', '   below the service load'});
c = cv_lead(c, gx(uT), ztop, 260, 160, {'2  the crack reaches the top of the pedestal', sprintf('   (%g above the plate): the crack seen in service', ztop - zA)});
c = cv_lead(c, gx(uB), zt, 260, -130, {'3  the crack crosses the beam top bars: from here', '   the bars hold the cracked body (orange: compression', '   from the plate to the bars; blue: tension in the bars)', sprintf('   centre bar, %g beside the anchor axis: r = %.0f, u = %g - %.0f/1.5 = %.0f', an.vT, rB, bp.u, rB, uB)});
c = cv_lead(c, gx(uh + P.cb.db/2), zt - 90, 260, -300, {'4  the hooks hold the bars against the column ties;', '   at the ultimate load the steel yields first'});
% dimensions
c = cv_dim(c, gx(bp.u) + 30, zA, gx(bp.u) + 30, ztop, -1, sprintf('%g', ztop - zA), 0);
c = cv_dim(c, gx(uh), cj + 20, gx(uB), cj + 20, 1, sprintf('%.0f from the crossing to the hook (check: %.0f)', uB - uh, C.ins_nom(2)), 0);
c = cv_dim(c, gx(uT), ztop + 30, gx(bp.u), ztop + 30, 1, sprintf('%.0f', bp.u - uT), 0);
c = cv_dim(c, -hb, cj + 55, gx(bp.u), cj + 55, 1, sprintf('%g', bp.u), 0);
c = cv_text(c, gx(60), ztop - 30, 'breakout body (red)', 'start');
c = cv_lead(c, gx(P.col.b - rc), 0, gx(P.col.b - rc) - 10, ztop + 95, {sprintf('far-face bars, straight up to %+g, hooked along the anchors at %+g:', zhA - 3.5*P.col.db, zhA), 'B1 bears on the tie 14 under the anchors and the tie on them (the vertical part of the orange push)'});
c = cv_text(c, gx(uc) + 40, P.col.cj + 140, '1.5 across : 1 along the anchor', 'start');
c = cv_text(c, gx(uc) + 40, P.col.cj + 120, 'crack at 56 deg to the anchor, 34 deg to the face', 'start');
c = cv_text(c, -435, 222, '<tspan font-weight="bold">G. Breakout of the concrete in front of the back plate (type E), and what holds it</tspan>', 'start');
lg = {'#1a5276', 'beam top bars (anchor reinforcement, ch. 25)'; '#5dade2', '2 extra beam bars at -80 (C4, D4-south)'; ...
      '#145a32', sprintf('side legs of the closed ties 14 at %+g and %+g (under the anchors)', P.top.z); ...
      '#7d3c98', 'joint ties 10 (side legs; -95 nominally within 0.5 hef)'; ...
      '#9a6b00', 'column bars 16 (vertical: not counted); level A along the anchors, level B across on them'; '#117a65', 'rods of the steel column'};
for i = 1:size(lg, 1)
    yy = -425 - 17*i;
    c.b{end+1} = sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="5"%s/>', (-435 - c.x0)*c.s, (c.y1 - yy)*c.s, (-405 - c.x0)*c.s, (c.y1 - yy)*c.s, lg{i,1}, '');
    if strncmp(lg{i,2}, 'proposed', 8)
        c.b{end+1} = sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#ffffff" stroke-width="2"/>', (-432 - c.x0)*c.s, (c.y1 - yy)*c.s, (-408 - c.x0)*c.s, (c.y1 - yy)*c.s);
    end
    c = cv_text(c, -398, yy - 4, lg{i,2}, 'start');
end
c = cv_text(c, -435, -425 - 17*(size(lg, 1) + 1) - 4, 'red rings: where a counted bar crosses the fracture surface; grey: crossing, not counted', 'start');
c = cv_text(c, -435, -425 - 17*(size(lg, 1) + 2) - 4, ['The section is through an anchor. Bars beside it meet the 3D surface nearer the face: u = ' num2str(bp.u) ' - r/1.5, r = distance to the anchor axis'], 'start');
svg = cv_end(c);
end

function svg = ta_z0(P, R)
% Shear across z = 0 (top of the beams): A. section along the cantilever (type E) with the pedestal block
% above the beams that B1 pushes; B. section across the column at the hairpins (u = P.ub2.u). Which
% vertical bars cross the plane and which of them are developed on both sides (ACI 318-19 22.9)
Y = R.typ(1);  an = P.an;  bp = P.bp;  hb = P.col.b/2;  gx = @(u) u - hb;  ztop = P.col.top;  cj = P.col.cj;
zA = Y.zT;  u2 = P.ub2;  d2 = u2.db;  dc = P.col.db;  rc = P.col.cover + P.col.dtie + dc/2;
zhA = ztop - P.col.ctop - dc/2;  xR = 470;  X0 = 980;
c = cv_new(-800, 1560, -500, 300, 0.7);
% ---- A. along the cantilever ----
c = cv_rect(c, -hb, cj, hb, ztop, 'conc');
c = cv_rect(c, hb, -P.cb.h, xR, 0, 'conc');
c = cv_rect(c, -hb, 0, hb, ztop, 'clash');                     % the block above the beams
c = cv_seg(c, [-hb - 30, xR], [0 0], 'cj');
for u = [rc, P.col.b - rc]                                     % column bars, hooked at level A
    sg = 1;  if u > hb, sg = -1; end
    [x, z] = hook(cj, zhA + dc/2, 0, dc, 1);
    c = cv_bar(c, gx(u) + sg*z, x, dc, 'colh');
end
for u = hb + [-1 1]*P.rod.p                                    % steel column rods, base plate and nuts
    c = cv_bar(c, gx([u u]), [cj ztop + 45], P.rod.db, 'rod');
    c = cv_rect(c, gx(u) - 14, ztop + 25, gx(u) + 14, ztop + 37, 'tail');
end
c = cv_rect(c, -170, ztop, 170, ztop + 25, 'platet');
c = cv_bar(c, gx([-an.out an.uT]), [zA zA], an.db, 'anc');
c = cv_rect(c, gx(bp.u), zA - bp.h/2, gx(bp.u + bp.t), zA + bp.h/2, 'plate');
c = cv_rect(c, gx(bp.u - an.tnut), zA - an.nut/2, gx(bp.u), zA + an.nut/2, 'tail');
[x, z] = hook(xR, gx(P.cb.uh + P.cb.db/2), max(P.cb.zt), P.cb.db, -1);  c = cv_bar(c, x, z, P.cb.db, 'exb');
[x, z] = hook(u2.zc, u2.zb - d2/2, 0, d2, -1);                 % hairpin leg, bottom hook towards the cantilever
c = cv_bar(c, gx(u2.u) + z, x, d2, 'ubar');
c = cv_circ(c, gx(u2.u), u2.zc, d2*1.2, 'mark');
% forces
c = cv_arrow(c, gx(-an.out) + 10, zA, gx(-an.out) - 70, zA, '#c0392b');
c = cv_text(c, gx(-an.out) - 75, zA + 14, sprintf('T = %.0f kN', Y.T/1e3), 'end');
c = cv_arrow(c, gx(bp.u) - 10, zA + 40, gx(bp.u) - 120, zA + 40, '#e3141e');
c = cv_arrow(c, -60, 14, -170, 14, '#e3141e');
c = cv_arrow(c, -60, -14, 50, -14, '#1f5f8b');
c = cv_text(c, -hb - 40, 4, 'z = 0', 'end');
% labels
c = cv_lead(c, gx(P.col.b - rc) + 4, zhA, -330, 270, {'column bars Ø16: hook only 90 mm above the plane (needs ~205):', 'developed below, NOT above: do not count (22.9)'});
c = cv_lead(c, gx(hb + P.rod.p), ztop + 30, 260, 270, {'steel column rods 4 Ø12: hooked > 1 m below, base plate', 'and nut above: developed both sides, they count'});
c = cv_lead(c, gx(u2.u), -150, 320, -400, {sprintf('hairpin Ø%g (2): legs cross z = 0, crown over the A1,', d2), 'hooks under the beam bars (alternative)'});
c = cv_lead(c, -120, 70, -330, 200, {'the pedestal block above the beams: B1 pushes it', 'towards the cantilever; it must pass T down across z = 0'});
c = cv_dim(c, hb + 30, 0, hb + 30, ztop, -20, sprintf('%g', ztop));
c = cv_text(c, 0, cj - 30, 'A. Section along the cantilever (type E)', 'middle');
% ---- B. across the column at the hairpins, looking towards the cantilever ----
c = cv_rect(c, X0 - hb, cj, X0 + hb, ztop, 'conc');
c = cv_seg(c, X0 + [-hb - 30, hb + 30], [0 0], 'cj');
for v = [-1 0 1]*(hb - rc)                                     % far-face column bars, 12 behind
    c = cv_bar(c, X0 + [v v], [cj zhA], dc, 'colh');
end
for v = [-1 1]*P.rod.p, c = cv_bar(c, X0 + [v v], [cj ztop + 45], P.rod.db, 'rod'); end
rr = 1.5*d2 + d2/2;  v0 = u2.v;  t = linspace(0, pi/2, 8);
xs = [-v0, -v0, -v0 + rr - rr*cos(t), v0 - rr + rr*sin(t), v0, v0];
zs = [u2.zb, u2.zc - rr, u2.zc - rr + rr*sin(t), u2.zc - rr + rr*cos(t), u2.zc - rr, u2.zb];
c = cv_bar(c, X0 + xs, zs, d2, 'ubar');
for v = [-1 1]*v0, c = cv_circ(c, X0 + v, u2.zb, d2*1.6, 'mark'); end
for v = [-1 1]*an.vT, c = cv_circ(c, X0 + v, zA, an.db, 'anc'); end
c = cv_rect(c, X0 - bp.w/2, zA - bp.h/2, X0 + bp.w/2, zA + bp.h/2, 'hid');
for v = [0 -1 1]*max(P.cb.v), c = cv_circ(c, X0 + v, max(P.cb.zt), P.cb.db, 'ex'); end
for v = [-1 1]*max(P.cb.v), c = cv_circ(c, X0 + v, P.cb.zp, P.cb.db, 'ex'); end
for v = P.cb.bas.v, c = cv_circ(c, X0 + v, P.cb.bas.z, P.cb.db, 'ex'); end
for v = [-1 1]*(hb - (rc - dc/2 - P.top.db/2)), for z = P.top.z, c = cv_circ(c, X0 + v, z, P.top.db, 'new'); end, end
c = cv_dim(c, X0 - v0, u2.zb, X0 + v0, u2.zb, -30, sprintf('%g', 2*v0));
c = cv_dim(c, X0 + hb + 20, u2.zb, X0 + hb + 20, u2.zc + d2/2, -20, sprintf('%g', u2.zc + d2/2 - u2.zb));
c = cv_lead(c, X0 + v0, u2.zc - 10, X0 + 120, 250, {sprintf('hairpin Ø%g: crown over the A1 (%.0f clear),', d2, (u2.v - d2/2) - (an.vT + an.db/2)), sprintf('legs at +-%g, 4 clear to the bastones', v0)});
c = cv_lead(c, X0 - an.vT, zA, X0 - 120, 250, 'A1 (B1 behind, dashed)');
c = cv_lead(c, X0 - v0, u2.zb, X0 - 140, -470, 'bottom hooks (into the page)');
c = cv_text(c, X0, cj - 30, sprintf('B. Across the column at u = %g, looking to the cantilever', u2.u), 'middle');
svg = cv_end(c);
end

function svg = ta_ubar(P, R)
% Supplementary U-bar over the top anchors (type E): A. section along the beam, B. section across
% the beam at the U-bar, looking towards the cantilever face. Geometry from P.ub and R.ub.
Y = R.typ(1);  an = P.an;  bp = P.bp;  ub = P.ub;  hb = P.col.b/2;  gx = @(u) u - hb;  cj = P.col.cj;  top = P.col.top;
zA = Y.zT;  zU = R.ub.zU;  d = ub.db;  zl = P.cb.zt(2);  zh = P.col.top - P.col.ctop - P.col.db/2;
rB = hypot(an.vT, zA - zl);  uB = bp.u - rB/1.5;
rc = 3.5*d;  tail = 12*d;  ri = 2*d + d/2;            % bottom hook radius; top corners: inside diameter 4 d_b
c = cv_new(-430, 1380, -440, 225, 0.66);
% ---- A. section along the beam ----
c = cv_rect(c, -hb, cj, hb, top, 'conc');
c = cv_rect(c, hb, -P.cb.h, 470, 0, 'conc');
for z = P.hoop.z, for u = [P.col.cover + P.hoop.db/2, P.col.b - P.col.cover - P.hoop.db/2], c = cv_circ(c, gx(u), z, P.hoop.db, 'hoop'); end, end
[x, z] = hook(470, gx(P.cb.uh), zl, P.cb.db, -1);  c = cv_bar(c, x, z, P.cb.db, 'ex');
for u = [P.col.b - P.col.cover - P.col.dtie - P.col.db/2 + [-8 8]], c = cv_circ(c, gx(u), zh, P.col.db, 'col'); end
c = cv_bar(c, gx([-an.out an.uT]), [zA zA], an.db, 'anc');
c = cv_rect(c, gx(bp.u), zA - bp.h/2, gx(bp.u + bp.t), zA + bp.h/2, 'plate');
c = cv_rect(c, gx(bp.u - an.tnut), zA - an.nut/2, gx(bp.u), zA + an.nut/2, 'tail');
t = linspace(0, pi/2, 12);                          % U-bar seen from the side: leg and bottom hook
xu = [ub.u*ones(1,1), ub.u - rc + rc*cos(t), ub.u - rc - tail];
zu = [zU, ub.zbot + rc - rc*sin(t), ub.zbot];
c = cv_bar(c, gx(xu), zu, d, 'new');
c = cv_arrow(c, gx(bp.u - 6), zA - 10, gx(uB + 8), zl + 12, '#e67e22');
c = cv_arrow(c, gx(ub.u + 22), zU + 4, gx(ub.u + 22), zU - 46, '#1e8449');
c = cv_text(c, gx(ub.u + 30), zU - 50, sprintf('V = %.2f T = %.0f kN', R.ub.Vt(1)/Y.T, R.ub.Vt(1)/1e3), 'start');
c = cv_dim(c, -hb, top + 18, gx(ub.u), top + 18, 1, sprintf('%g', ub.u), 0);
c = cv_dim(c, gx(ub.u) - 30, ub.zbot, gx(ub.u) - 30, zU, 1, sprintf('%g', zU - ub.zbot), 0);
c = cv_dim(c, gx(ub.u - rc - tail), ub.zbot - 22, gx(ub.u), ub.zbot - 22, -1, sprintf('%.0f', rc + tail), 0);
c = cv_lead(c, gx(ub.u), -120, gx(ub.u) + 70, -200, {sprintf('U-bar &#216;%g, standing across the beam,', d), sprintf('resting on top of both A1, %g from the face', ub.u)});
c = cv_lead(c, gx(uB), zl, gx(uB) + 60, -330, {'orange: compression from the plate to the beam bars;', 'its vertical part is what the U-bar holds down'});
c = cv_text(c, -425, 215, '<tspan font-weight="bold">H. Supplementary U-bar over the top anchors (type E)</tspan>', 'start');
c = cv_text(c, -425, -420, 'A. Section along the beam', 'start');
% ---- B. section across the beam at u = ub.u, looking towards the cantilever face ----
ox = 760;  X = @(v) ox + v;
c = cv_rect(c, X(-hb), cj, X(hb), top, 'conc');
for v = [-1 0 1]*(hb - P.col.cover - P.col.dtie - P.col.db/2), c = cv_bar(c, X([v v]), [cj zh - 40], P.col.db, 'colh'); end
for z = P.hoop.z, c = cv_seg(c, X([-1 1]*(hb - P.col.cover - P.hoop.db/2)), [z z], 'stir'); end
c = cv_bar(c, X([-1 1]*(hb - P.col.cover - P.col.db/2 - 8)), [zh zh], P.col.db, 'colh');
for v = P.cb.v, c = cv_circ(c, X(v), zl, P.cb.db, 'ex'); end
for v = P.cb.v([1 3]), c = cv_circ(c, X(v), P.cb.zp, P.cb.db, 'ex'); end
for v = [-1 1]*an.vT, c = cv_circ(c, X(v), zA, an.db, 'anc'); end
a1 = linspace(pi, pi/2, 10);  a2 = linspace(pi/2, 0, 10);
xs = [-ub.v, -an.vT + ri*cos(a1), an.vT + ri*cos(a2), ub.v];
zs = [ub.zbot, zU - ri + ri*sin(a1), zU - ri + ri*sin(a2), ub.zbot];
c = cv_bar(c, X(xs), zs, d, 'new');
for v = [-1 1]*ub.v, c = cv_circ(c, X(v), ub.zbot, d*1.2, 'new'); end
c = cv_dim(c, X(-ub.v), ub.zbot - 25, X(ub.v), ub.zbot - 25, -1, sprintf('%g', 2*ub.v), 0);
c = cv_dim(c, X(hb) + 18, zU + d/2, X(hb) + 18, zh - P.col.db/2, -1, sprintf('%.0f', (zh - P.col.db/2) - (zU + d/2)), 0);
c = cv_dim(c, X(hb) + 18, zA, X(hb) + 18, zU, -1, sprintf('%g', zU - zA), 0);
c = cv_dim(c, X(-hb) - 18, cj, X(-hb) - 18, top, 1, '', 0);
c = cv_lead(c, X(0), zh, X(hb) + 60, 160, {'column hooks, level A', sprintf('(%.0f mm above the U-bar)', (zh - P.col.db/2) - (zU + d/2))});
c = cv_lead(c, X(an.vT), zA, X(hb) + 60, 95, {'top anchors A1: the U-bar', 'rests on them'});
c = cv_lead(c, X(ub.v), -150, X(hb) + 60, -150, {sprintf('legs %g apart, between the', 2*ub.v), 'beam top bars (5 mm to the corner bars)'});
c = cv_lead(c, X(-ub.v), ub.zbot, X(hb) + 60, -300, {'90 deg hooks towards the face,', sprintf('tails at z = %g', ub.zbot)});
c = cv_text(c, X(-hb), -420, sprintf('B. Section across the beam at u = %g, looking towards the cantilever face', ub.u), 'start');
svg = cv_end(c);
end

function svg = ta_ubar3(P, R)
% The U-bar in 3D (oblique view, true shape across the beam): the column top as a box, the two A1
% with B1, the beam top bars with their hooks, and the U-bar resting on the A1 with its feet
% (90 deg hooks) turned towards the cantilever face. Cabinet projection: u goes into the page.
Y = R.typ(1);  an = P.an;  bp = P.bp;  ub = P.ub;  hb = P.col.b/2;  zA = Y.zT;  zU = R.ub.zU;  d = ub.db;
kk = 0.5/sqrt(2);  X = @(u, v) v + kk*u;  Z = @(u, z) z + kk*u;
c = cv_new(-470, 430, -330, 260, 1.0);
% column top: front face, top face, right side (edges only)
zb = -300;  uf = 0;  ur = P.col.b;
c = cv_seg(c, [X(uf,-hb) X(uf,hb) X(uf,hb) X(uf,-hb) X(uf,-hb)], [Z(uf,zb) Z(uf,zb) Z(uf,P.col.top) Z(uf,P.col.top) Z(uf,zb)], 'dim');
c = cv_seg(c, [X(uf,-hb) X(ur,-hb) X(ur,hb) X(uf,hb)], [Z(uf,P.col.top) Z(ur,P.col.top) Z(ur,P.col.top) Z(uf,P.col.top)], 'dim');
c = cv_seg(c, [X(ur,hb) X(ur,hb)], [Z(ur,P.col.top) Z(ur,zb)], 'dim');
c = cv_seg(c, [X(uf,hb) X(ur,hb)], [Z(uf,zb) Z(ur,zb)], 'dim');
% beam top bars (in line): from the far face to their hooks at the cantilever face
zl = P.cb.zt(2);  uh = P.cb.uh + P.cb.db/2;
for v = P.cb.v
    u0 = uh;  if v == 0, u0 = P.cb.uh0 + P.cb.db/2; end
    c = cv_bar(c, [X(ur + 120, v) X(u0, v) X(u0, v)], [Z(ur + 120, zl) Z(u0, zl) Z(u0, zl - 186)], P.cb.db, 'ex');
end
% B1 and the two A1
c = cv_poly(c, [X(bp.u,-bp.w/2) X(bp.u,bp.w/2) X(bp.u,bp.w/2) X(bp.u,-bp.w/2)], ...
               [Z(bp.u,zA-bp.h/2) Z(bp.u,zA-bp.h/2) Z(bp.u,zA+bp.h/2) Z(bp.u,zA+bp.h/2)], 'platet');
for v = [-1 1]*an.vT, c = cv_bar(c, [X(-an.out, v) X(an.uT, v)], [Z(-an.out, zA) Z(an.uT, zA)], an.db, 'anc'); end
% the U-bar: feet (hooks) towards the face, legs, top arcs over the anchors
ri = 2*d + d/2;  rc = 3.5*d;  tl = 12*d;  t = linspace(0, pi/2, 10)';
foot = @(sv) [ub.u - rc - tl, sv*ub.v, ub.zbot; [ub.u - rc + rc*sin(t), sv*ub.v*ones(10,1), ub.zbot + rc - rc*cos(t)]];
a1 = linspace(pi, pi/2, 10)';  a2 = linspace(pi/2, 0, 10)';
topp = [ub.u*ones(20,1), [-an.vT + ri*cos(a1); an.vT + ri*cos(a2)], [zU - ri + ri*sin(a1); zU - ri + ri*sin(a2)]];
Q = [foot(-1); topp; flipud(foot(1))];
c = cv_bar(c, X(Q(:,1), Q(:,2))', Z(Q(:,1), Q(:,3))', d, 'new');
% labels
c = cv_lead(c, X(ub.u, 0), Z(ub.u, zU), 230, 240, {sprintf('U &#216;%g resting on both A1', d)});
c = cv_lead(c, X(ub.u - rc - tl/2, ub.v), Z(ub.u - rc - tl/2, ub.zbot), 230, -250, {'feet: 90 deg hooks', 'towards the cantilever face'});
c = cv_lead(c, X(60, an.vT), Z(60, zA), -260, 200, {'top anchors A1', 'with back plate B1'});
c = cv_lead(c, X(200, P.cb.v(1)), Z(200, zl), -260, -200, 'beam top bars, hooked at the face');
c = cv_text(c, X(0, 0), Z(0, zb) - 22, 'cantilever face', 'middle');
c = cv_text(c, -465, 250, '<tspan font-weight="bold">C. The U-bar in 3D (type E)</tspan>', 'start');
svg = cv_end(c);
end

function c = sarrow(c, x1, y1, x2, y2, col)
% small arrow
[px, py] = cv_p(c, [x1 x2], [y1 y2]);
a = atan2(py(2)-py(1), px(2)-px(1));  h = 4;
c.b{end+1} = sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="0.9"/>', px(1), py(1), px(2), py(2), col);
c.b{end+1} = sprintf('<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="%s"/>', px(2), py(2), ...
    px(2) - h*cos(a) - 0.5*h*sin(a), py(2) - h*sin(a) + 0.5*h*cos(a), px(2) - h*cos(a) + 0.5*h*sin(a), py(2) - h*sin(a) - 0.5*h*cos(a), col);
end

function svg = ta_sfb(P, R)
% Side-face blowout towards the top of the pedestal: section along the beam and the top of the
% pedestal seen from above, with the spalled body (indicative: the size ACI 17.6.4 implies,
% 3 ca1 to each side of the head on the free surface, 6 ca1 between heads)
Y = R.typ(1);  an = P.an;  bp = P.bp;  hb = P.col.b/2;  gx = @(u) u - hb;  ztop = P.col.top;
ca1 = ztop - Y.zT;  ca2 = hb - an.vT;  r3 = 3*ca1;
c = cv_new(-310, 760, -260, 255, 0.95);
% section along the beam
c = cv_rect(c, -hb, -100, hb, ztop, 'conc');
ub = bp.u - r3;                                     % far end of the spall on the top surface
c = cv_poly(c, gx([bp.u ub P.col.b P.col.b bp.u+bp.t]), [Y.zT-bp.h/2 ztop ztop Y.zT+bp.h/2 Y.zT+bp.h/2], 'clash');
c = cv_bar(c, gx([-20 an.uT]), [Y.zT Y.zT], an.db, 'anc');
c = cv_rect(c, gx(bp.u), Y.zT-bp.h/2, gx(bp.u+bp.t), Y.zT+bp.h/2, 'plate');
c = cv_arrow(c, gx(bp.u-10), Y.zT-34, gx(bp.u-70), Y.zT-34, '#c0392b');
c = cv_text(c, gx(bp.u-75), Y.zT-50, 'the plate pushes the concrete towards the face', 'end');
c = cv_dim(c, gx(bp.u)+28, Y.zT, gx(bp.u)+28, ztop, -1, sprintf('ca1 = %g', ca1), 0);
c = cv_dim(c, gx(ub), ztop+14, gx(bp.u), ztop+14, 1, sprintf('about 3 ca1 = %g', r3), 0);
c = cv_dim(c, -hb, -70, gx(bp.u), -70, -1, sprintf('h_ef = %g > 2.5 ca1 = %.0f', bp.u, 2.5*ca1), 0);
c = cv_dim(c, -hb-15, 0, -hb-15, Y.zT, 1, sprintf('%g', Y.zT), 0);
c = cv_dim(c, -hb-45, 0, -hb-45, ztop, 1, sprintf('%g', ztop), 0);
c = cv_seg(c, [-hb-60 hb+20], [0 0], 'cl');
c = cv_text(c, -hb-62, -4, 'z = 0', 'end');
c = cv_text(c, -hb, ztop+42, sprintf('top of the pedestal, z = +%g (free face, under the base plate)', ztop), 'start');
c = cv_text(c, 0, -150, 'red: blowout body (indicative), the concrete between the plate and the top that spalls off', 'middle');
c = cv_text(c, -245, 245, '<tspan font-weight="bold">D. Side-face blowout: section along the beam, and the top of the pedestal from above</tspan>', 'start');
% top of the pedestal seen from above: u to the right, v up
ox = 300;  pu = @(u) ox + u;
c = cv_rect(c, pu(0), -hb, pu(P.col.b), hb, 'conc');
t = linspace(0, 2*pi, 121);
for v0 = [-1 1]*an.vT                               % spall of each head, clipped by the faces
    x = min(max(bp.u + r3*cos(t), 0), P.col.b);  y = min(max(v0 + r3*sin(t), -hb), hb);
    c = cv_poly(c, pu(x), y, 'clash');
end
c = cv_rect(c, pu(bp.u), -bp.w/2, pu(bp.u+bp.t), bp.w/2, 'plate');
for v = [-1 1]*an.vT, c = cv_bar(c, [pu(-20) pu(an.uT)], [v v], an.db, 'anc'); end
c = cv_dim(c, pu(P.col.b)+18, an.vT, pu(P.col.b)+18, hb, -1, sprintf('ca2 = %g &lt; 3 ca1 = %g', ca2, r3), 0);
c = cv_dim(c, pu(P.col.b)+18, -an.vT, pu(P.col.b)+18, an.vT, -1, sprintf('s = %g', 2*an.vT), 0);
c = cv_seg(c, pu([bp.u bp.u - r3*cos(pi/4)]), [an.vT an.vT + r3*sin(pi/4)], 'dim');
c = cv_text(c, pu(bp.u - r3*cos(pi/4)) - 4, an.vT + r3*sin(pi/4) - 14, sprintf('r = 3 ca1 = %g', r3), 'end');
c = cv_text(c, pu(hb), hb+12, 'side face, free above the beam top: cuts the spall (ca2)', 'middle');
c = cv_text(c, pu(0), -hb-18, 'face of the cantilever, u = 0', 'start');
c = cv_text(c, pu(P.col.b), -hb-18, 'far face', 'end');
c = cv_text(c, pu(hb), -hb-42, sprintf('top of the pedestal from above (z = +%g)', ztop), 'middle');
svg = cv_end(c);
end

function svg = ta_spry(P, R)
% Shear anchors, pryout: section along the beam through a shear anchor (type E). ACI body of
% the group: 1.5 h_ef from the axis at the face, apex at the bearing face of the end nut
Y = R.typ(1);  S = R.shc;  an = P.an;  bm = P.bm;  hb = P.col.b/2;  gx = @(u) u - hb;
ztop = P.col.top;  cj = P.col.cj;  zS = S.zS;  h = S.hef;  zb = -560;
ue = an.uS + an.tnut + an.pp;  up = -P.g - P.ep.t;
c = cv_new(-520, 470, -650, 175, 0.95);
c = cv_rect(c, -hb, zb, hb, ztop, 'conc');
c = cv_rect(c, hb, -P.cb.h, 300, 0, 'conc');
c = cv_seg(c, [-hb hb], [cj cj], 'cj');
c = cv_text(c, hb + 6, cj - 16, sprintf('cold joint z = %g (not an edge)', cj), 'start');
c = cv_text(c, 0, zb + 14, 'the column goes on below: no free edge in the direction of V', 'middle');
% end plate, grout and IPE
c = cv_rect(c, gx(up), Y.ep_bot, gx(-P.g), Y.ep_top, 'plate');
c = cv_rect(c, gx(-P.g), Y.ep_bot, gx(0), Y.ep_top, 'grout');
c = cv_rect(c, -500, -bm.tf, gx(up), 0, 'steel');
c = cv_rect(c, -500, -bm.h, gx(up), -bm.h + bm.tf, 'steel');
c = cv_rect(c, -500, -bm.h + bm.tf, gx(up), -bm.tf, 'web');
% top anchor (faint) and the shear anchor
c = cv_bar(c, gx([-an.out 250]), [Y.zT Y.zT], an.db, 'anch');
c = cv_text(c, gx(250) + 6, Y.zT - 4, 'top anchor (tension)', 'start');
% pryout body
c = cv_poly(c, gx([h 0 0]), [zS zS + 1.5*h zS - 1.5*h], 'clash');
c = cv_bar(c, gx([-an.outS ue]), [zS zS], an.db, 'anc');
c = cv_rect(c, gx(an.uS), zS - an.nut/2, gx(an.uS + an.tnut), zS + an.nut/2, 'tail');
c = cv_rect(c, gx(up - an.twsh - an.tnut), zS - an.nut/2, gx(up - an.twsh), zS + an.nut/2, 'tail');
c = cv_rect(c, gx(up - an.twsh), zS - an.wsh/2, gx(up), zS + an.wsh/2, 'tail');
% forces: V down at the face; the nut kicks up and pulls the body out
c = cv_arrow(c, gx(-52), zS + 95, gx(-52), zS + 14, '#c0392b');
c = cv_text(c, gx(-52), zS + 103, 'V/2 each', 'middle');
c = cv_rect(c, gx(0), zS - an.db/2 - 22, gx(40), zS - an.db/2, 'zbrg');
c = cv_lead(c, gx(20), zS - an.db/2 - 11, gx(130), zS - 75, {'the bar bears down on the concrete', 'next to the face'});
c = cv_arrow(c, gx(an.uS + 8), zS + 16, gx(an.uS + 8), zS + 62, '#7f8c8d');
c = cv_lead(c, gx(55), zS + 55, gx(170), zS + 150, {'pryout: the bar levers about that bearing,', 'the nut lifts and pulls the body behind it out', '(the crater opens on the side away from V)'});
% dimensions
c = cv_dim(c, gx(0), zS - 1.5*h - 34, gx(h), zS - 1.5*h - 34, -1, sprintf('h_ef = %g', h), 0);
c = cv_dim(c, gx(0), zS - 1.5*h, gx(0), zS, 105, sprintf('1.5 h_ef = %g', 1.5*h), 0);
c = cv_dim(c, gx(0), zS, gx(0), zS + 1.5*h, 105, sprintf('1.5 h_ef = %g', 1.5*h), 0);
c = cv_dim(c, gx(0), zS + 1.5*h, gx(0), ztop, 105, sprintf('%.0f', ztop - zS - 1.5*h), 0);
c = cv_dim(c, hb + 18, zS, hb + 18, ztop, -1, sprintf('%.0f to the top: no cut', ztop - zS), 0);
c = cv_dim(c, -hb - 230, 0, -hb - 230, zS, 1, sprintf('%.1f', zS), 0);
c = cv_seg(c, [-500 hb + 10], [0 0], 'cl');
c = cv_text(c, -500, 6, 'z = 0, top of the beams', 'start');
c = cv_text(c, gx(8), zS - 105, 'pryout body', 'start');
c = cv_text(c, -hb, ztop + 10, sprintf('top of the pedestal, z = +%g', ztop), 'start');
c = cv_text(c, -510, 160, '<tspan font-weight="bold">I. Shear anchors: pryout. Section along the beam through a shear anchor (type E)</tspan>', 'start');
svg = cv_end(c);
end

function svg = ta_sbrk(P, R)
% Shear anchors, breakout towards a side face under the torsion couple: plan at the shear
% anchors. Case 1: the near anchor takes half; case 2: the far anchor takes all (R17.7.2.1)
S = R.shc;  an = P.an;  bm = P.bm;  hb = P.col.b/2;  gx = @(u) u - hb;  ue = an.uS + an.tnut + an.pp;
up = -P.g - P.ep.t;  r1 = 1.5*S.ca1(1);  r2 = 1.5*S.ca1(2);
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;  xh = hb - P.col.cover - P.col.dtie/2;
c = cv_new(-470, 560, -320, 330, 1.0);
c = cv_rect(c, -hb, -hb, hb, hb, 'conc');
c = cv_rect(c, hb, -P.cb.b/2, 300, P.cb.b/2, 'conc');
c = cv_poly(c, gx([0 0 r2]), [-an.vS hb hb], 'tribx');
c = cv_poly(c, gx([0 0 r1]), [an.vS hb hb], 'clash');
c = cv_rect(c, -xh, -xh, xh, xh, 'hoopr');
for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, c = cv_circ(c, sx*xc, sy*xc, P.col.db, 'col'); end
end, end
c = cv_rect(c, gx(up), -P.ep.w/2, gx(-P.g), P.ep.w/2, 'plate');
c = cv_rect(c, gx(-P.g), -P.ep.w/2, gx(0), P.ep.w/2, 'grout');
c = cv_rect(c, -460, -bm.b/2, gx(up), bm.b/2, 'steel');
for v = [-1 1]*an.vS
    c = cv_bar(c, gx([-an.outS ue]), [v v], an.db, 'anc');
    c = cv_rect(c, gx(an.uS), v - an.nut/2, gx(an.uS + an.tnut), v + an.nut/2, 'tail');
end
c = cv_arrow(c, gx(-90), an.vS + 15, gx(-90), an.vS + 95, '#c0392b');
c = cv_text(c, gx(-100), an.vS + 70, 'H (torsion), either way:', 'end');
c = cv_text(c, gx(-100), an.vS + 56, 'the same at the other face', 'end');
c = cv_text(c, gx(-100), an.vS + 30, 'V: down, into the page', 'end');
% dimensions
c = cv_dim(c, gx(ue), an.vS, gx(ue), hb, -(gx(P.col.b) + 30 - gx(ue)), sprintf('ca1 = %g (case 1)', S.ca1(1)), 0);
c = cv_dim(c, gx(ue), -an.vS, gx(ue), hb, -(gx(P.col.b) + 75 - gx(ue)), sprintf('ca1 = %g (case 2)', S.ca1(2)), 0);
c = cv_dim(c, gx(0), hb, gx(r1), hb, 18, sprintf('1.5 ca1 = %.0f', r1), 0);
c = cv_dim(c, gx(0), hb, gx(r2), hb, 50, sprintf('1.5 ca1 = %.0f', r2), 0);
c = cv_dim(c, gx(0), -hb, gx(P.col.b), -hb, -22, sprintf('h_a = %g &gt; 1.5 ca1: no thickness cut (psi_h,V = 1)', S.ha), 0);
c = cv_text(c, gx(8), hb - 20, '<tspan font-weight="bold">case 1</tspan>', 'start');
c = cv_text(c, gx(262), hb - 20, '<tspan font-weight="bold">case 2</tspan>', 'start');
c = cv_text(c, gx(0), -hb - 72, 'red, case 1: the near anchor takes H/2 + V/2. Orange, case 2: the far anchor takes all of H + V (holes not welded, R17.7.2.1)', 'start');
c = cv_text(c, 0, hb + 90, 'side face (free): the breakout surfaces reach it', 'middle');
c = cv_text(c, gx(0), -hb - 50, 'face of the cantilever, u = 0', 'start');
c = cv_text(c, -460, 312, sprintf('<tspan font-weight="bold">J. Shear anchors: breakout towards a side face. Plan at z = %.1f</tspan>', S.zS), 'start');
svg = cv_end(c);
end

function svg = ta_sfr(P, R)
% Shear anchors seen on the face of the cantilever: the pryout area A_Nc and the traces of the
% two breakout surfaces (towards the side face v = +200) on this face
Y = R.typ(1);  S = R.shc;  an = P.an;  hb = P.col.b/2;  ztop = P.col.top;  cj = P.col.cj;
zS = S.zS;  h = S.hef;  r1 = 1.5*S.ca1(1);  r2 = 1.5*S.ca1(2);  zb = -640;
c = cv_new(-420, 470, -690, 170, 0.95);
c = cv_rect(c, -hb, zb, hb, ztop, 'conc');
c = cv_seg(c, [-hb hb], [cj cj], 'cj');
c = cv_seg(c, [-hb - 20 hb + 10], [0 0], 'cl');
c = cv_text(c, -hb - 24, -4, 'z = 0', 'end');
c = cv_text(c, -hb - 50, cj - 4, sprintf('cold joint %g', cj), 'end');
% case 2 trace clipped by the top of the pedestal
vt = -an.vS + S.ca1(2)*min(1, (ztop - zS)/r2);
c = cv_poly(c, [-an.vS vt hb hb], [zS ztop ztop zS - r2], 'tribx');
c = cv_poly(c, [an.vS hb hb], [zS zS + r1 zS - r1], 'clash');
c = cv_rect(c, -an.vS - min(hb - an.vS, 1.5*h), zS - 1.5*h, an.vS + min(hb - an.vS, 1.5*h), zS + min(ztop - zS, 1.5*h), 'zstrip');
c = cv_rect(c, -P.ep.w/2, Y.ep_bot, P.ep.w/2, Y.ep_top, 'hid');
for v = [-1 1]*an.vS
    c = cv_circ(c, v, Y.zT, an.db, 'ex');
    c = cv_circ(c, v, zS, an.db, 'anc');
end
c = cv_arrow(c, 0, zS + 70, 0, zS + 12, '#c0392b');
c = cv_text(c, 4, zS + 76, 'V', 'start');
c = cv_arrow(c, hb - 70, zS + 20, hb - 20, zS + 20, '#c0392b');
c = cv_text(c, hb - 72, zS + 26, 'H', 'end');
% dimensions
c = cv_dim(c, -an.vS - 1.5*h, zS - 1.5*h, an.vS + 1.5*h, zS - 1.5*h, -25, sprintf('2 (1.5 h_ef) + s = %.0f', 2*1.5*h + 2*an.vS), 0);
c = cv_dim(c, -hb, zS - 1.5*h, -hb, zS + 1.5*h, 30, sprintf('3 h_ef = %g', 3*h), 0);
c = cv_dim(c, hb, zS, hb, zS + r1, -22, sprintf('1.5 ca1 = %.0f', r1), 0);
c = cv_dim(c, hb, zS - r1, hb, zS, -22, sprintf('%.0f', r1), 0);
c = cv_dim(c, hb, zS - r2, hb, zS, -70, sprintf('1.5 ca1 = %.0f', r2), 0);
c = cv_dim(c, hb, zS, hb, ztop, -70, sprintf('ca2 = %.0f', ztop - zS), 0);
c = cv_dim(c, -hb, Y.zT, -hb, zS, 75, sprintf('%.0f', Y.zT - zS), 0);
lg = {'blue: A_Nc of the pryout body,', sprintf('%.0f x %.0f', 2*1.5*h + 2*an.vS, 3*h), '', 'red: trace of the case 1', 'breakout on this face', '', 'orange: case 2, cut by', 'the top (psi_ed,V)'};
for i = 1:numel(lg), c = cv_text(c, -hb - 12, -400 - 14*(i - 1), lg{i}, 'end'); end
c = cv_lead(c, -an.vS, Y.zT - an.db/2, -150, Y.zT + 45, 'top anchors (grey)');
c = cv_text(c, 0, zb + 14, 'the column goes on below', 'middle');
c = cv_text(c, -410, 155, '<tspan font-weight="bold">K. Face of the cantilever (front view): pryout area and the breakout traces</tspan>', 'start');
svg = cv_end(c);
end

function svg = ta_stop(P, R, j)
% Top anchors of type j seen on the face of the cantilever: the breakout traces towards the side
% face v = +200 (cut by the top of the pedestal) and the pryout area A_Nc (the tension cone cut by
% the top and both sides, h'_ef as in 17.6.2.1.2)
Y = R.typ(j);  St = R.sht;  Q = R.brk(j);  an = P.an;  hb = P.col.b/2;  ztop = P.col.top;
z0 = Y.zT;  r1 = 1.5*St.ca1(1);  r2 = 1.5*St.ca1(2);  ct = ztop - z0;  hp = Q.hefp;  zb = -420;
c = cv_new(-430, 470, -470, 235, 1.05);
c = cv_rect(c, -hb, zb, hb, ztop, 'conc');
c = cv_seg(c, [-hb - 70 hb + 10], [0 0], 'cl');
c = cv_text(c, -hb - 74, -4, 'z = 0', 'end');
c = cv_rect(c, -hb, z0 - 1.5*hp, hb, ztop, 'zstrip');
v2 = -an.vT + St.ca1(2)*min(1, ct/r2);  v1 = an.vT + St.ca1(1)*min(1, ct/r1);
c = cv_poly(c, [-an.vT v2 hb hb], [z0 ztop ztop z0 - r2], 'tribx');
c = cv_poly(c, [an.vT v1 hb hb], [z0 ztop ztop z0 - r1], 'clash');
c = cv_rect(c, -P.ep.w/2, Y.ep_bot, P.ep.w/2, Y.ep_top, 'hid');
for v = [-1 1]*an.vT
    c = cv_circ(c, v, z0, an.db, 'anc');
    c = cv_circ(c, v, R.shc.zS, an.db, 'ex');
end
c = cv_arrow(c, hb - 75, z0 - 25, hb - 25, z0 - 25, '#c0392b');
c = cv_text(c, hb - 78, z0 - 21, 'H', 'end');
c = cv_arrow(c, 0, z0 - 15, 0, z0 - 75, '#7f8c8d');
c = cv_text(c, 4, z0 - 70, 'V/4 each, only if all 4 holes bear', 'start');
% dimensions
c = cv_dim(c, hb, z0, hb, ztop, -22, sprintf('ca2 = %g', ct), 0);
c = cv_dim(c, hb, z0 - r1, hb, z0, -22, sprintf('1.5 ca1 = %.0f', r1), 0);
c = cv_dim(c, hb, z0 - r2, hb, z0 - r1, -22, '', 0);
c = cv_dim(c, hb, z0 - r2, hb, z0, -62, sprintf('1.5 ca1 = %.0f', r2), 0);
c = cv_dim(c, -hb, z0 - 1.5*hp, -hb, z0, 30, sprintf('1.5 h''ef = %.0f', 1.5*hp), 0);
c = cv_dim(c, -an.vT, ztop + 14, an.vT, ztop + 14, 1, sprintf('s = %g', 2*an.vT), 0);
c = cv_dim(c, an.vT, ztop + 40, hb, ztop + 40, 1, sprintf('ca1 = %g (case 1)', St.ca1(1)), 0);
c = cv_dim(c, -an.vT, ztop + 66, hb, ztop + 66, 1, sprintf('ca1 = %g (case 2)', St.ca1(2)), 0);
lg = {'blue: A_Nc of the pryout body', '(the tension cone, cut by the', 'top and both sides)', '', 'red: case 1 trace', 'orange: case 2 trace', '', 'grey: shear anchors'};
for i = 1:numel(lg), c = cv_text(c, -hb - 12, -200 - 14*(i - 1), lg{i}, 'end'); end
c = cv_text(c, -420, 220, sprintf('<tspan font-weight="bold">L. Top anchors of %s (z = %+g) on the face of the cantilever: breakout and pryout</tspan>', Y.name, z0), 'start');
svg = cv_end(c);
end

function svg = ta_arx(P, R)
% Anchor reinforcement, cross-section across the beam at the back plate: distances r
Y = R.typ(1);  C = R.cone(1);  an = P.an;  bm = P.bm;  cb = P.cb;
za = Y.zT + P.tol.za;
c = cv_new(-200, 200, -140, 90, 1.7);
c = cv_rect(c, -cb.b/2, -cb.h, cb.b/2, 0, 'conc');
c = cv_rect(c, -P.col.b/2, 0, P.col.b/2, P.col.top, 'conc');
for v = [-1 1]*an.vT
    c = cv_circ(c, v, Y.zT, an.db, 'exl');
    c = cv_circ(c, v, za, an.db, 'anc');
end
for k = 1:numel(C.vb)
    zbk = C.zb(k);  zbt = zbk - P.tol.zb;
    c = cv_circ(c, C.vb(k), zbk, cb.db, 'exl');
    st = 'ex';  if ~any(C.used == k), st = 'exl'; end
    c = cv_circ(c, C.vb(k), zbt, cb.db, st);
    [rr, i] = min(hypot(C.vb(k) - [-1 1]*an.vT, zbt - za));
    va = an.vT*sign(C.vb(k) + (C.vb(k) == 0));
    c = cv_seg(c, [va C.vb(k)], [za zbt], 'dim');
    c = cv_text(c, (va + C.vb(k))/2 + 4, (za + zbt)/2, sprintf('r = %.1f', rr), 'start');
end
for v = P.cb.v([1 3]), c = cv_circ(c, v, P.cb.zp - P.tol.zb, cb.db, 'exl'); end
c = cv_dim(c, -cb.b/2-10, zbt, -cb.b/2-10, za, 1, sprintf('%g', za - zbt), 0);
c = cv_dim(c, 0, -120, an.vT, -120, -1, sprintf('%g', an.vT), 0);
c = cv_dim(c, an.vT, -120, max(P.cb.v), -120, -1, sprintf('%g', max(P.cb.v) - an.vT), 0);
c = cv_text(c, -195, 82, '<tspan font-weight="bold">E1. Section across the beam in line, near the back plate</tspan>', 'start');
c = cv_text(c, -195, 68, sprintf('light: nominal; solid: with tolerances (anchors +%g, beam bars -%g)', P.tol.za, P.tol.zb), 'start');
c = cv_text(c, -195, -135, sprintf('VCM top line at %g (lower layer) and the 2 bars in contact under the corner bars (not counted)', min(cb.zt)), 'start');
svg = cv_end(c);
end

function svg = ta_aru(P, R)
% Anchor reinforcement, section along the beam: apex, breakout body, inside length
Y = R.typ(1);  C = R.cone(1);  an = P.an;  hb = P.col.b/2;  gx = @(u) u - hb;  H = R.hk;
ua = H.uc - P.tol.ua;
c = cv_new(-230, 380, -300, 150, 1.4);
c = cv_rect(c, -hb, -150, hb, P.col.top, 'conc');
c = cv_rect(c, hb, -P.cb.h+0*150, 360, 0, 'conc');
c = cv_bar(c, gx([-20 an.uT]), (Y.zT+P.tol.za)*[1 1], an.db, 'anc');
c = cv_rect(c, gx(ua), Y.zT+P.tol.za-P.bp.h/2, gx(ua+P.bp.t), Y.zT+P.tol.za+P.bp.h/2, 'plate');
cols = {'zstrip', 'zgap'};  kk = 0;
for k = C.used
    kk = kk + 1;
    zbt = C.zb(k) - P.tol.zb;
    rr = min(hypot(C.vb(k) - [-1 1]*an.vT, zbt - (Y.zT + P.tol.za)));
    ub = ua - rr/1.5;
    uh = C.uh(k) + P.tol.ub;
    if kk > 2, continue; end
    if C.vb(k) == 0, ttl = 'centre bar'; else, ttl = sprintf('bar at |v| = %g', abs(C.vb(k))); end
    zz = zbt;
    c = cv_poly(c, gx([ua ub ub]), [Y.zT+P.tol.za zz Y.zT+P.tol.za], cols{kk});
    [x, z] = hook(360, gx(uh), zz, P.cb.db, -1);
    c = cv_bar(c, x, z, P.cb.db, 'ex');
    c = cv_dim(c, gx(uh), zz-14-24*(kk-1), gx(ub), zz-14-24*(kk-1), -1, sprintf('%s: %.0f inside', ttl, ub - uh), 0);
    c = cv_text(c, gx(ub)+4, zz+30-16*kk, sprintf('%s: r = %.1f, u = %.0f - r/1.5 = %.0f', ttl, rr, ua, ub), 'start');
end
c = cv_dim(c, -hb, P.col.top+10, gx(ua), P.col.top+10, 1, sprintf('apex u = %g - %g = %g', H.uc, P.tol.ua, ua), 0);
c = cv_text(c, -225, 140, '<tspan font-weight="bold">E2. Section along the beam: breakout body (1 along the anchor : 1.5 across) and the beam bars inside it</tspan>', 'start');
c = cv_text(c, -225, -290, sprintf('both bars at z = %g (lower layer, %g low); hooks %g short: outside at u = %g (+%g), centre bar %g (+%g)', min(P.cb.zt)-P.tol.zb, P.tol.zb, P.tol.ub, P.cb.uh, P.tol.ub, P.cb.uh0, P.tol.ub), 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_bars(P, R)
% Shapes of the two anchors (one drawing for all types)
an = P.an;  db = an.db;  H = R.hk;
c = cv_new(-140, 760, -420, 160, 0.85);
L1 = an.out + an.uT;  ub0 = P.bp.u - an.tnut - 15;
c = cv_bar(c, [-an.out an.uT], [0 0], db, 'anc');
c = cv_bar(c, [-an.out, -an.out+100], [0 0], db+5, 'anch');
c = cv_bar(c, [ub0 an.uT], [0 0], db+5, 'anch');
c = cv_rect(c, P.bp.u, -P.bp.h/2, P.bp.u+P.bp.t, P.bp.h/2, 'plate');
c = cv_rect(c, P.bp.u-an.tnut, -an.nut/2, P.bp.u, an.nut/2, 'tail');
c = cv_rect(c, P.bp.u+P.bp.t+an.twsh, -an.nut/2, P.bp.u+P.bp.t+an.twsh+an.tnut, an.nut/2, 'tail');
c = cv_dim(c, -an.out, 8, an.uT, 8, 35, sprintf('%.0f', L1));
c = cv_dim(c, -an.out, 8, -an.out+100, 8, 80, 'threaded rod, full length');
c = cv_dim(c, ub0, 8, an.uT, 8, 80, sprintf('%.0f thread', an.uT - ub0));
c = cv_dim(c, 0, -30, P.bp.u, -30, 1, sprintf('%g = concrete face to back plate', P.bp.u), 0);
c = cv_text(c, -120, -80, sprintf('top anchor: 2 per beam, %s, straight, threaded both ends; back plate PL %gx%gx%g %s, holes %s18', an.lab, P.bp.t, P.bp.h, P.bp.w, P.st.name{P.bp.grade}, '&#216;'), 'start');
c = cv_text(c, -120, -105, sprintf('the face of the concrete is %g from the front end', an.out), 'start');
L2 = an.outS + an.uS + an.twsh + an.tnut + an.pp;
c = cv_bar(c, [-an.outS, -an.outS+L2], [-330 -330], db, 'anc');
c = cv_bar(c, [-an.outS, -an.outS+100], [-330 -330], db+5, 'anch');
c = cv_bar(c, [-an.outS+L2-30, -an.outS+L2], [-330 -330], db+5, 'anch');
c = cv_rect(c, an.uS, -330-an.wsh/2, an.uS+an.twsh, -330+an.wsh/2, 'tail');
c = cv_rect(c, an.uS+an.twsh, -330-an.nut/2, an.uS+an.twsh+an.tnut, -330+an.nut/2, 'tail');
c = cv_dim(c, -an.outS, -322, -an.outS+L2, -322, 35, sprintf('%g', L2));
c = cv_dim(c, 0, -322, an.uS, -322, -50, sprintf('%g  (bearing face of the nut)', an.uS));
c = cv_text(c, 300, -320, sprintf('shear anchor: 2 per beam, %s, threaded both ends,', an.lab), 'start');
c = cv_text(c, 300, -342, 'nut + washer at the inner end', 'start');
c = cv_text(c, -130, 140, '<tspan font-weight="bold">Anchors (same for every type); light red = threaded length</tspan>', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_grout(P, R)
% The plate is not cast flush: grout pad detail and form, type E
Y = R.typ(1);  an = P.an;  bm = P.bm;  tp = P.ep.t;  g = P.g;  db = an.db;
c = cv_new(-620, 330, -380, 200, 1.0);
c = cv_rect(c, 0, -340, 250, 120, 'conc');
c = cv_rect(c, -g, Y.ep_bot-15, 0, Y.ep_top+15, 'grout');
c = cv_rect(c, -g-tp, Y.ep_bot, -g, Y.ep_top, 'plate');
if P.dbl.on, c = cv_rect(c, -g, 0, -g+P.dbl.t, Y.ep_top, 'plate'); end
x0 = -g - tp;
c = cv_rect(c, -300, -bm.h+bm.tf, x0, -bm.tf, 'web');
c = cv_rect(c, -300, -bm.tf, x0, 0, 'steel');  c = cv_rect(c, -300, -bm.h, x0, -bm.h+bm.tf, 'steel');
for z = [Y.zT Y.zS]
    c = cv_bar(c, [-an.out 240], [z z], db, 'anc');
    c = cv_rect(c, x0-an.twsh, z-an.wsh/2, x0, z+an.wsh/2, 'tail');
    c = cv_rect(c, x0-an.twsh-an.tnut, z-an.nut/2, x0-an.twsh, z+an.nut/2, 'tail');
    zl_ = -g + 3 + (z > 0)*P.dbl.on*P.dbl.t;
    c = cv_rect(c, zl_, z-an.nut/2, zl_+an.tnut, z+an.nut/2, 'tailr');          % levelling nut
end
% form: plywood box around the plate, open at the top (head box)
c = cv_arrow(c, -g-60, Y.ep_top+110, -g/2, Y.ep_top+20, '#7f8c8d');
c = cv_text(c, -g-65, Y.ep_top+115, 'grout poured here', 'end');
c = cv_lead(c, -g/2, -120, -330, 120, {sprintf('grout pad %g, non-shrink, flowable,', g), sprintf('f''g &#8805; %g MPa; poured from the top', P.fg)});
c = cv_lead(c, -g+8, Y.zS, -330, -300, {'levelling nut behind the plate (light):', 'sets the plate plumb and the gap;', 'then snug only, it stays in the grout'});
c = cv_lead(c, 0, 80, 60, 170, 'face roughened, wet, no laitance');
c = cv_text(c, -600, 185, '<tspan font-weight="bold">Plate not cast flush: grout pad (type E)</tspan>', 'start');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_tol(P, R)
% Room for site errors of the anchors, front view of type E and section depth
Y = R.typ(1);  an = P.an;  bm = P.bm;  db = an.db;  t = R.tolt;
c = cv_new(-560, 420, -300, 140, 1.05);
c = cv_rect(c, -P.ep.w/2, Y.ep_bot, P.ep.w/2, 100, 'conc');
c = cv_rect(c, -bm.b/2, -bm.tf, bm.b/2, 0, 'steel');
c = cv_poly(c, [-bm.b/2-8 bm.b/2+8 bm.b/2 -bm.b/2], [0 0 8 8], 'weldfill');
c = cv_rect(c, -bm.tw/2, -bm.h/2, bm.tw/2, -bm.tf, 'steel');
c = cv_rect(c, -bm.b/2, -bm.h, bm.b/2, -bm.h+bm.tf, 'steel');
c = cv_bar(c, [0 0], [-250 100], P.col.db, 'col');
for v = [-1 1]*P.rod.p, c = cv_bar(c, [v v], [Y.ep_bot 100], P.rod.db, 'rod'); end
dn = t{1,3};  up = t{2,3};  vin = t{6,3};  vout = t{7,3};
for v = [-1 1]*an.vT
    sg = sign(v);
    c = cv_rect(c, v - sg*vin, Y.zT - dn, v + sg*vout, Y.zT + up, 'ztol');
    c = cv_circ(c, v, Y.zT, an.wsh, 'ringok');
    c = cv_circ(c, v, Y.zT, db, 'anc');
end
c = cv_dim(c, an.vT+vout+20, Y.zT, an.vT+vout+20, Y.zT - dn, 12, sprintf('-%g', dn), 0);
c = cv_dim(c, an.vT+vout+20, Y.zT, an.vT+vout+20, Y.zT + up, -12, sprintf('+%g', up), 0);
c = cv_dim(c, an.vT - vin, Y.zT+up+12, an.vT + vout, Y.zT+up+12, 1, sprintf('-%g / +%g', vin, vout), 0);
c = cv_lead(c, -an.vT, Y.zT - dn, -160, -40, {'green: where the axis of a top anchor', 'may be with nothing else changed', 'down: washer on the fillet; up: cover 40 over the back plate', sprintf('in: mid-face column bar; out: rods %s%g', '&#216;', P.rod.db)});
c = cv_text(c, -550, -150, sprintf('depth: back plate %g towards the face (far ties); deeper: free (nuts)', t{8,3}), 'start');
c = cv_text(c, -550, -172, sprintf('shear anchors: &#177;%.0f in level (joint ties)', t{10,3}), 'start');
c = cv_text(c, -550, -194, 'in the plane of the face: no limit when the end plate', 'start');
c = cv_text(c, -550, -216, 'is drilled to the surveyed anchors', 'start');
c = cv_text(c, -550, 125, '<tspan font-weight="bold">Room for site errors, top anchors of type E (mm)</tspan>', 'start');
svg = cv_end(c);
end

% ===========================================================================
%  drawing tools (copied from ../cantilever_anchor_double_plate/ca_draw.m; styles grout, form,
%  clash, tmpl added)
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
    case 'markg',  a = 'fill="#ffffff" stroke="#7f8c8d" stroke-width="2.0"';
    case 'markp',  a = 'fill="#ffffff" stroke="#145a32" stroke-width="2.2"';
    case 'xhit',   a = 'fill="none" stroke="#e3141e" stroke-width="2.2"';
    case 'zbrg',   a = 'fill="#7f8c8d" fill-opacity="0.30" stroke="#555555" stroke-width="0.8" stroke-dasharray="4 3"';
    case 'grout',  a = 'fill="#b9b2a0" fill-opacity="0.75" stroke="#6b6b6b" stroke-width="0.6"';
    case 'form',   a = 'fill="#c8a165" stroke="#7a5a2a" stroke-width="0.8"';
    case 'clash',  a = 'fill="#e3141e" fill-opacity="0.18" stroke="#e3141e" stroke-width="1.4" stroke-dasharray="5 3"';
    case 'strut',  a = 'fill="#e67e22" fill-opacity="0.35" stroke="#b9770e" stroke-width="1.2"';
    case 'node',   a = 'fill="#ffffff" fill-opacity="0.85" stroke="#111111" stroke-width="1.6"';
    case 'tmpl',   a = 'fill="#34506b" stroke="#142433" stroke-width="0.8"';
    case 'rib',    a = 'fill="#34506b" fill-opacity="0.8" stroke="#142433" stroke-width="0.8"';
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
    case 'mA',    a = 'stroke="#7f8c8d" stroke-width="1.8" stroke-dasharray="6 4"';
    case 'mB',    a = 'stroke="#1f5f8b" stroke-width="2.2"';
    case 'limit2', a = 'stroke="#c0392b" stroke-width="1.6"';
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
    case 'tieh',   col = '#7d3c98';  op = 0.35;
    case 'tie14',  col = '#145a32';
    case 'white',  col = '#ffffff';
    case 'exb',    col = '#1a5276';
    case 'ex2',    col = '#5dade2';
    case 'ubar',   col = '#b9770e';
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
% mutool does not render sub/superscripts well: plain text in the figures (Mu, hef, ...)
b = strrep(strrep(c.b, '<sub>', ''), '</sub>', '');
c.b = strrep(strrep(b, '<sup>', ''), '</sup>', '');
svg = sprintf(['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.0f %.0f" width="%.0f" height="%.0f" ' ...
    'font-family="Helvetica, Arial, sans-serif">\n<rect width="%.0f" height="%.0f" fill="#ffffff"/>\n%s\n</svg>\n'], ...
    c.W, c.H, c.W, c.H, c.W, c.H, strjoin(c.b, sprintf('\n')));
end

function r = ifelse(a, b, c)
if a, r = b; else, r = c; end
end

function svg = ta_stm(P, R)
% Strut-and-tie model of the anchorage, type E (ca_stm): section in the plane of the anchors.
Y = R.typ(1);  an = P.an;  bp = P.bp;  hb = P.col.b/2;  gx = @(u) u - hb;  ztop = P.col.top;  cj = P.col.cj;
S = ca_stm(P, R);  M = S(1);  t = M.theta*pi/180;  z1 = Y.zT;  z2 = M.z2;  u1 = bp.u;  u2 = M.u2;  xR = 560;
rc = P.col.cover + P.col.dtie + P.col.db/2;  kN = 1e-3;
c = cv_new(-560, 720, -470, 230, 0.9);
c = cv_rect(c, -hb, cj, hb, ztop, 'conc');
c = cv_rect(c, hb, -P.cb.h, xR, 0, 'conc');
% vertical tie: the far-face column bars, straight behind B1, hooked along the anchors (level A);
% B1 bears on the tie 14 under the anchors, the tie on them (user 2026-10-05)
zA = P.col.top - P.col.ctop - P.col.db/2;
[x, z] = hook(cj, zA + P.col.db/2, 0, P.col.db, 1);
c = cv_bar(c, gx(P.col.b - rc) - z(2:end), x(2:end), P.col.db, 'colh');
c = cv_circ(c, gx(P.col.b - (rc - P.col.db/2 - P.top.db/2)), P.top.zu, P.top.db, 'col');
% beam top bars (tie), hooked at the face
[x, z] = hook(xR, gx(P.cb.uh + P.cb.db/2), z2, P.cb.db, -1);  c = cv_bar(c, x, z, P.cb.db, 'exb');
% strut S1 (width ws) from N1 to N2, and S2 down from N2
d = [-cos(t), -sin(t)];  nrm = [sin(t), -cos(t)];  w2 = M.ws/2;
p1 = [u1 z1];  p2 = [u2 z2];
Q = [p1 + w2*nrm; p2 + w2*nrm; p2 - w2*nrm; p1 - w2*nrm];
c = cv_poly(c, gx(Q(:,1)), Q(:,2), 'strut');
c = cv_rect(c, gx(u2 - 18), cj + 5, gx(u2 + 18), z2 - 6, 'strut');
% path 2: strut from N1 straight to N3 (end plate compression on the face), hollow
q = M.p2;  t3 = q.theta*pi/180;  n3 = [sin(t3), -cos(t3)];  p3 = [0 q.z3];  wa = q.ws1/2;  wb = q.ws3/2;
Q3 = [p1 + wa*n3; p3 + wb*n3; p3 - wb*n3; p1 - wa*n3];
c.b{end+1} = sprintf('<polygon points="%s" fill="#8e44ad" fill-opacity="0.10" stroke="#8e44ad" stroke-width="1.4" stroke-dasharray="6 4"/>', ...
    sprintf('%.1f,%.1f ', [((gx(Q3(:,1)) - c.x0)*c.s)'; ((c.y1 - Q3(:,2))*c.s)']));
c = cv_circ(c, gx(0) + 13, q.z3, 26, 'node');  c = cv_text(c, gx(0) + 13, q.z3 - 4, 'N3', 'middle');
c = cv_arrow(c, gx(-an.out) - 70, q.z3, gx(-P.g) - 4, q.z3, '#1f4e79');
c = cv_text(c, gx(-an.out) - 75, q.z3 + 14, sprintf('C = T (end plate on the grout, Y = %.0f)', q.Y), 'end');
c = cv_lead(c, gx(bp.u/2), (z1 + q.z3)/2 + 10, gx(-40), -110, {sprintf('PATH 2: strut N1-N3 to the end plate compression, %.1f&#176;', q.theta), sprintf('%.1f kN; V = %.1f kN down the far column bars', q.Fs*kN, q.V*kN)});
% anchors, B1, nuts
c = cv_bar(c, gx([-an.out an.uT]), [z1 z1], an.db, 'anc');
c = cv_rect(c, gx(bp.u), z1 - bp.h/2, gx(bp.u + bp.t), z1 + bp.h/2, 'plate');
c = cv_rect(c, gx(bp.u - an.tnut), z1 - an.nut/2, gx(bp.u), z1 + an.nut/2, 'tail');
c = cv_rect(c, gx(bp.u + bp.t), z1 - an.nut/2, gx(bp.u + bp.t + an.twsh + an.tnut), z1 + an.nut/2, 'tail');
% nodes
c = cv_circ(c, gx(u1), z1, 26, 'node');  c = cv_text(c, gx(u1) - 2, z1 - 4, 'N1', 'middle');
c = cv_circ(c, gx(u2), z2, 26, 'node');  c = cv_text(c, gx(u2), z2 - 4, 'N2', 'middle');
% forces
c = cv_arrow(c, gx(-an.out) + 10, z1, gx(-an.out) - 70, z1, '#c0392b');
c = cv_text(c, gx(-an.out) - 75, z1 + 14, sprintf('T = %.1f kN (tie A1)', M.T*kN), 'end');
c = cv_arrow(c, gx(P.col.b - rc), cj + 60, gx(P.col.b - rc), cj + 10, '#9a6b00');
c = cv_text(c, gx(P.col.b - rc) + 12, cj + 30, sprintf('path 1: V = T tan&#952; = %.1f kN (tie: 2 &#216;%g column bars)', M.V*kN, P.col.db), 'start');
c = cv_arrow(c, gx(400) + 40, z2, gx(xR) - 10, z2, '#1a5276');
c = cv_text(c, gx(xR) - 10, z2 - 26, sprintf('T = %.1f kN (tie: %d &#216;%g beam top bars, z = %g)', M.T*kN, M.n, P.cb.db, z2), 'end');
c = cv_lead(c, gx((u1 + u2)/2), (z1 + z2)/2, 300, 165, {sprintf('PATH 1: strut S1 to the beam bars, T/cos&#952; = %.1f kN, &#952; = %.1f&#176;', M.Fs*kN, M.theta), sprintf('width w<sub>s</sub> = %.0f at N1; V = %.1f kN', M.ws, M.V*kN)});
c = cv_lead(c, gx(u2), (z2 + cj)/2, gx(-40), -260, {'strut S2: V down the joint into the column', '(N2: smeared node on the bars)'});
% dimensions
c = cv_dim(c, gx(u2), z1 + 60, gx(u1), z1 + 60, 1, sprintf('%.0f', u1 - u2), 0);
c = cv_dim(c, gx(u1) + 40, z2, gx(u1) + 40, z1, -1, sprintf('%g', z1 - z2), 0);
c = cv_dim(c, -hb, cj + 25, gx(u2), cj + 25, 1, sprintf('u = %.0f', u2), 0);
c = cv_text(c, -550, 215, '<tspan font-weight="bold">M. Strut-and-tie models of the joint, type E: path 1 to the beam (solid), path 2 to the pedestal (dashed)</tspan>', 'start');
svg = cv_end(c);
end
