function F = ca_draw(P, R)
% CA_DRAW  Drawings of the double plate scheme as SVG text.
%   F = ca_draw(P, R) returns one field per figure. All the geometry comes
%   from P (ca_inputs) and R (ca_layout), so drawings and numbers cannot differ.
%   Drawing units are mm; z = 0 is the top of the concrete beam and of the steel.
%   The drawing tools at the end are copied from ../cantilever_anchor_V2/ca_draw.m.
F.edge_elev  = fig_elev(P, R, 1, 9);
F.edge_plan  = fig_plan(P, R, 'edge');
F.edge_front = fig_front(P, R);
F.cor_plan   = fig_plan(P, R, 'corner');
F.cor_elevX  = fig_elev(P, R, 2, 9);
F.cor_elevY  = fig_elev(P, R, 3, 9);
F.assy_E     = fig_assy(P, R, 1);
F.assy_Y     = fig_assy(P, R, 3);
for s = 1:5
    F.(sprintf('seq%d', s)) = fig_elev(P, R, 1, s);
end
end

% ===========================================================================
%  figures
% ===========================================================================
function c = draw_rods_elev(c, P, R, j, gx, st, show)
% rods of assembly type j in a section along its beam, with plates, nuts and
% heads. show = [front plate + shear rods, back plate, tension rods, end plate nuts]
Y = R.typ(j);  d = P.tr.d;  tn = P.tr.tnut;  w2 = P.tr.nut/2;  tw = 4;
zT = Y.rowT(1);  zS = Y.rowS(1);
if show(1)
    c = cv_rect(c, gx(0), Y.fp_bot, gx(P.fp.t), Y.fp_top, 'plate');
    c = cv_bar(c, gx([-P.tr.out Y.rowS(3)]), [zS zS], d, st);
    c = cv_rect(c, gx(P.fp.t), zS-w2, gx(P.fp.t+tn), zS+w2, 'tail');                 % inner nut
    c = cv_rect(c, gx(P.tr.uS), zS-15, gx(P.tr.uS+tw), zS+15, 'tail');               % washer + nut at the end
    c = cv_rect(c, gx(P.tr.uS+tw), zS-w2, gx(P.tr.uS+tw+tn), zS+w2, 'tail');
end
if show(2)
    c = cv_rect(c, gx(P.bp.u), zT-P.bp.h/2, gx(P.bp.u+P.bp.t), zT+P.bp.h/2, 'plate');
end
if show(3)
    c = cv_bar(c, gx([-P.tr.out Y.rowT(3)]), [zT zT], d, st);
    c = cv_rect(c, gx(P.fp.t), zT-w2, gx(P.fp.t+tn), zT+w2, 'tail');
    u2 = P.bp.u + P.bp.t;
    c = cv_rect(c, gx(P.bp.u-tn), zT-w2, gx(P.bp.u), zT+w2, 'tail');
    c = cv_rect(c, gx(u2), zT-15, gx(u2+tw), zT+15, 'tail');
    c = cv_rect(c, gx(u2+tw), zT-w2, gx(u2+tw+tn), zT+w2, 'tail');
end
if show(4)
    for z = [zT zS]
        w3 = w2;  if z == zS, w3 = P.tr.nutS/2; end
        c = cv_rect(c, gx(-P.ep.t-tw), z-15, gx(-P.ep.t), z+15, 'tail');
        c = cv_rect(c, gx(-P.ep.t-tw-tn), z-w3, gx(-P.ep.t-tw), z+w3, 'tail');
    end
end
end

% ---------------------------------------------------------------------------
function c = draw_beam_elev(c, P, R, j, gx, xL)
% steel beam with its shop-welded end plate, in a section along the beam
bm = P.bm;  Y = R.typ(j);  x0 = gx(-P.ep.t);  w = P.w.flange;
c = cv_rect(c, xL, -bm.h+bm.tf, x0, -bm.tf, 'web');
c = cv_rect(c, xL, -bm.tf, x0, 0, 'steel');
c = cv_rect(c, xL, -bm.h, x0, -bm.h+bm.tf, 'steel');
c = cv_rect(c, x0, Y.ep_bot, gx(0), Y.ep_top, 'plate');
for z = [0, -bm.tf, -bm.h+bm.tf, -bm.h]
    sg = 1;  if z == -bm.tf || z == -bm.h, sg = -1; end
    c = cv_poly(c, [x0 x0-w x0], [z z z+sg*w], 'weldfill');
end
end

% ---------------------------------------------------------------------------
function svg = fig_elev(P, R, j, stage)
% Section along the axis of the steel beam. j = 1 edge (type E), 2 corner beam X
% (type CX, rods over), 3 corner beam Y (type CY, rods under). stage = 9: final
% layout with dimensions; stage = 1..5: placing sequence at the edge.
hb = P.col.b/2;  bm = P.bm;  gx = @(u) u - hb;  Y = R.typ(j);  d = P.tr.d;
ztop = P.col.top;  zcj = P.col.cj;  xL = -640;  xR = 760;  zB = -520;
xc = hb - P.col.cover - P.col.dtie - P.col.db/2;
xh = hb - P.col.cover - P.col.dtie/2;
fin = (stage == 9);  edge = (j == 1);
show = [stage >= 1, stage >= 2, stage >= 3, stage >= 5];
if fin
    c = cv_new(-780, 900, -600, 330, 0.62);
else
    c = cv_new(-700, 560, -560, 330, 0.40);  xR = 520;  xL = -620;
end
% layers: the beam in line on the upper layer for E and CY, on the lower one for CX
ti = 1 + (j == 2);  tj = 3 - ti;

% concrete and slab
c = cv_rect(c, -hb, zB, hb, zcj, 'old');
if stage >= 4
    c = cv_rect(c, -hb, zcj, hb, ztop, 'conc');
    c = cv_rect(c, hb, -P.cb.h, xR, 0, 'conc');
    c = cv_rect(c, hb, 0, xR, P.slab.t, 'slab');
else
    c = cv_rect(c, -hb, zcj, hb, ztop, 'hid');
    c = cv_rect(c, hb, -P.cb.h, xR, 0, 'hid');
end
if fin, c = cv_rect(c, xL, 0, -hb, P.slab.t, 'slab'); end
c = cv_rect(c, -P.cb.b/2, -P.cb.h, P.cb.b/2, 0, 'hid');
c = cv_seg(c, [-hb-45 hb+45], [zcj zcj], 'cj');
for x = hb+110 : P.cb.sst : xR-20
    c = cv_seg(c, [x x], [-P.cb.h+45, -45], 'stir');
end

% column bars: front and far mid-face bars, in this section on the beam axis
zc = ztop - P.col.cover - P.col.db/2;
if stage >= 4
    c = cv_bar(c, [-xc -xc], [zB zc], P.col.db, 'col');
    c = cv_bar(c, [ xc  xc], [zB zc], P.col.db, 'col');
    if j ~= 2                                       % hooks along this beam, at v = 0 (between the rods), side by side
        [x, z] = hook(zB, zc+P.col.db/2, 0, P.col.db, 1);
        c = cv_bar(c, -xc + z(2:end), x(2:end), P.col.db, 'colh');
        c = cv_bar(c,  xc - z(2:end), x(2:end), P.col.db, 'colh');
    else                                            % hooks along beam Y: out of this section
        c = cv_circ(c, -xc, zc, P.col.db*1.6, 'col');
        c = cv_circ(c,  xc, zc, P.col.db*1.6, 'col');
    end
else
    c = cv_bar(c, [-xc -xc], [zB ztop+170], P.col.db, 'col');
    c = cv_bar(c, [ xc  xc], [zB ztop+170], P.col.db, 'col');
end

% ties
zz = P.hoop.z;  if stage >= 4 && edge, zz = [zz P.hoop.ztop]; end
for z = zz
    c = cv_seg(c, [-xh xh], [z z], 'hoop');
    c = cv_circ(c, -xh, z, P.hoop.db, 'hoop');
    c = cv_circ(c,  xh, z, P.hoop.db, 'hoop');
end
xt = hb - P.col.cover - P.top.db/2;
for z = P.top.z                                     % closed ties 14 at the top (10.7.6.1.5), before the rods
    c = cv_bar(c, [-xt xt], [z z], P.top.db, 'tie');
    c = cv_circ(c, -xt, z, P.top.db, 'hoop');
    c = cv_circ(c,  xt, z, P.top.db, 'hoop');
end

% bars of the concrete beam in line, rods of the steel column, crossing bars
zt = P.cb.zt(ti);  zb = P.cb.zb(ti);
c = cv_bar(c, [xR gx(P.cb.uh+10)], [zb zb], P.cb.db, 'ex');
[x, z] = hook(xR, gx(P.cb.uh), zt, P.cb.db, -1);
c = cv_bar(c, x, z, P.cb.db, 'ex');
for x = [-1 1]*P.rod.p
    c = cv_bar(c, [x x], [zB ztop+60], P.rod.db, 'rod');
end
for v = P.cb.v
    c = cv_circ(c, v, P.cb.zt(tj), P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zb(tj), P.cb.db, 'ex');
end
% corner: rods of the other beam cross this section
if j > 1
    o = 5 - j;  Yo = R.typ(o);
    for v = [-1 1]
        c = cv_circ(c, v*Yo.rowT(2), Yo.rowT(1), d, 'anc');
        c = cv_circ(c, v*Yo.rowS(2), Yo.rowS(1), d, 'anc');
    end
end

% the assembly, and the beam
c = draw_rods_elev(c, P, R, j, gx, 'anc', show);
if stage >= 5, c = draw_beam_elev(c, P, R, j, gx, xL); end

if ~fin
    % placing sequence: arrow and caption
    a = {[-560 Y.rowS(1) gx(-P.tr.out)-15 Y.rowS(1)], [gx(P.bp.u+8) 300 gx(P.bp.u+8) Y.rowT(1)+P.bp.h/2+12], ...
         [-560 Y.rowT(1) gx(-P.tr.out)-15 Y.rowT(1)], [0 300 0 ztop+20], [-610 -120 gx(-P.ep.t)-15 -120]};
    t = {'1. Top ties, then front plate + 2 shear rods', '2. Back plate lowered from above', ...
         '3. Tension rods pushed in through both plates', '4. Hooks bent, tie at +50 (edge), formwork, pour', ...
         '5. Beam bolted after curing'};
    t2 = {'ties dropped over the column bars; plate pushed in', 'behind the far column bars and the far tie', ...
          'nuts on both faces of both plates, from above', 'threads taped; holes in the form for the rods', ...
          'end plate against the front plate; shims if needed'};
    q = a{stage};
    c = cv_arrow(c, q(1), q(2), q(3), q(4), '#e3141e');
    c = cv_text(c, -680, 300, ['<tspan font-weight="bold">' t{stage} '</tspan>'], 'start');
    c = cv_text(c, -680, 262, t2{stage}, 'start');
    svg = cv_end(c);
    return
end

% dimensions
u2 = P.bp.u + P.bp.t;
uh = [P.fp.t, P.bp.u, u2];
c = cv_dim(c, -hb, ztop, gx(uh(1)), ztop, 45, sprintf('%g', P.fp.t), -14);
c = cv_dim(c, gx(uh(1)), ztop, gx(uh(2)), ztop, 45);
c = cv_dim(c, gx(uh(2)), ztop, gx(uh(3)), ztop, 45, sprintf('%g', uh(3)-uh(2)), -9);
c = cv_dim(c, gx(uh(3)), ztop, hb, ztop, 45, sprintf('%g', P.col.b-uh(3)), 13);
c = cv_dim(c, gx(-P.tr.out), ztop, -hb, ztop, 100);
c = cv_dim(c, -hb, ztop, gx(Y.rowT(3)), ztop, 100, sprintf('%.0f  (tension rod inside)', Y.rowT(3)));
c = cv_dim(c, -hb, ztop, gx(Y.rowS(3)), ztop, 155, sprintf('%.0f  (shear rod inside)', Y.rowS(3)));
c = cv_dim(c, -hb, ztop, hb, ztop, 210);
c = cv_dim(c, xR, -P.cb.h, xR, 0, -35);
c = cv_dim(c, xR, 0, xR, P.slab.t, -35);
c = cv_dim(c, xR, 0, xR, ztop, -80, sprintf('%g  (pedestal)', ztop));
c = cv_dim(c, xL, Y.ep_bot, xL, -bm.h, 35, sprintf('%g', P.ep.under), 10);
c = cv_dim(c, xL, -bm.h, xL, 0, 35);
if Y.ep_top > 0, c = cv_dim(c, xL, 0, xL, Y.ep_top, 35); end
c = cv_dim(c, xL, R.z.C, xL, Y.rowT(1), 85, sprintf('%.0f  (lever arm)', Y.lev));
% rod levels against the flanges
c = cv_dim(c, -hb+30, 0, -hb+30, Y.rowT(1), -1, sprintf('%g', Y.rowT(1)), 0);
zz = [zcj sort(P.hoop.z) P.top.z 0];
for i = 1:numel(zz)-1
    c = cv_dim(c, hb, zz(i), hb, zz(i+1), -45);
end
if edge, c = cv_dim(c, hb, 0, hb, P.hoop.ztop, -45); end

% labels
fpH = Y.fp_top - Y.fp_bot;  epH = Y.ep_top - Y.ep_bot;
c = cv_lead(c, gx(P.fp.t/2), -250, -330, -330, {sprintf('Front plate PL %gx%gx%g, flush with the face', P.fp.t, P.fp.w, fpH), 'template for the rods + bearing plate'});
c = cv_lead(c, gx(-P.ep.t/2), Y.ep_bot+20, -330, -400, {sprintf('End plate PL %gx%gx%g, shop welded', P.ep.t, P.ep.w, epH), 'fillets 8 on the flanges, 5 on the web, both sides'});
s1 = {sprintf('2 rods %s B7 over the top flange (|v| = %g)', P.tr.lab, Y.rowT(2)), sprintf('nuts on both faces of both plates, L = %g', Y.L(1))};
c = cv_lead(c, gx(P.bp.u+P.bp.t/2), Y.rowT(1)+P.bp.h/2-4, 380, 290, {sprintf('Back plate PL %gx%gx%g', P.bp.t, P.bp.h, P.bp.w), 'behind the far column bars and the far tie'});
c = cv_lead(c, gx(60), Y.rowT(1), -330, 230, s1);
c = cv_lead(c, gx(110), Y.rowS(1), -330, -190, {sprintf('2 shear rods %s B7 (|v| = %g), L = %g', P.tr.lab, Y.rowS(2), Y.L(2)), 'in the compression zone: shear only'});
c = cv_lead(c, P.rod.p, 70, 470, 225, sprintf('rods of the steel column: 4 %s%g', '&#216;', P.rod.db));
if j == 1, st = sprintf('VCM: 5 %s%g top bars, hooked down', '&#216;', P.cb.db);
else,      st = sprintf('3 %s%g top bars, hooked down', '&#216;', P.cb.db); end
c = cv_lead(c, 640, zt+4, 600, -110, st);
if edge, s3 = sprintf('closed tie %s%g at +%g, placed after the rods', '&#216;', P.hoop.db, P.hoop.ztop); else, s3 = ''; end
c = cv_lead(c, -xh, P.hoop.z(end), -330, -470, {sprintf('%d layers of 4 straight ties %s%g, as planned', numel(P.hoop.z), '&#216;', P.hoop.db), s3});
c = cv_lead(c, xt-30, P.top.z(1), 380, -15, {sprintf('2 closed ties %s%g at %+g and %+g:', '&#216;', P.top.db, P.top.z), 'ACI 10.7.6.1.5, before the rods'});
if j ~= 2
    c = cv_lead(c, -40, zc, -330, 290, {'Column top hooks along this beam;', 'the two at v = 0 side by side'});
else
    c = cv_lead(c, -xc, zc, -330, 290, 'Column top hooks bent along beam Y, over these rods');
end
if j > 1
    if j == 2, so = {'rods of beam Y (high) and its', 'shear rods, in section'};
    else,      so = {'rods of beam X (low) and its', 'shear rods, in section'}; end
    c = cv_lead(c, Yo.rowT(2), Yo.rowT(1), 380, 160, so);
end
c = cv_text(c, -450, 125, 'deck notched around the end plate', 'middle');
c = cv_text(c, hb+55, zcj-18, 'cold joint: column cast earlier', 'start');
c = cv_text(c, -450, -125, bm.name, 'middle');
c = cv_text(c, 580, -185, sprintf('Concrete beam %gx%g', P.cb.b/10, P.cb.h/10), 'middle');
c = cv_text(c, 0, -470, 'Hardened pedestal', 'middle');
c = cv_text(c, -450, 62, sprintf('Composite slab %g', P.slab.t), 'middle');
c = cv_text(c, xR+95, -4, '&#177;0', 'start');
c = cv_text(c, -760, -570, sprintf('Type %s', Y.name), 'start');
svg = cv_end(c);
end

function r = ifelse(a, b, c)
if a, r = b; else, r = c; end
end

% ---------------------------------------------------------------------------
function c = draw_assembly_plan(c, P, R, j, rot)
% one assembly in plan, with the end plate of its beam. rot = 0: beam along -x
% (u along +x, v along y); rot = 1: beam along -y (u along +y, v along x).
hb = P.col.b/2;  Y = R.typ(j);  d = P.tr.d;  tn = P.tr.tnut;  w2 = P.tr.nut/2;  tw = 4;
if rot == 0, mp = @(u, v) deal(u - hb, v); else, mp = @(u, v) deal(v, u - hb); end
c = rect_uv(c, mp, -P.ep.t, -P.ep.w/2, 0, P.ep.w/2, 'plate');
c = rect_uv(c, mp, 0, -P.fp.w/2, P.fp.t, P.fp.w/2, 'plate');
for sg = [-1 1]
    % shear rods, lower (translucent)
    v = sg*Y.rowS(2);
    [x, y] = mp([-P.tr.out Y.rowS(3)], [v v]);  c = cv_bar(c, x, y, d, 'anch');
    c = rect_uv(c, mp, P.tr.uS, v-15, P.tr.uS+tw+tn, v+15, 'tailr');
    % tension rods
    v = sg*Y.rowT(2);
    [x, y] = mp([-P.tr.out Y.rowT(3)], [v v]);  c = cv_bar(c, x, y, d, 'anc');
    c = rect_uv(c, mp, P.fp.t, v-w2, P.fp.t+tn, v+w2, 'tail');
    c = rect_uv(c, mp, -P.ep.t-tw-tn, v-w2, -P.ep.t, v+w2, 'tail');
    c = rect_uv(c, mp, P.bp.u-tn, v-w2, P.bp.u, v+w2, 'tail');
    c = rect_uv(c, mp, P.bp.u+P.bp.t, v-w2, P.bp.u+P.bp.t+tw+tn, v+w2, 'tail');
end
c = rect_uv(c, mp, P.bp.u, -P.bp.w/2, P.bp.u+P.bp.t, P.bp.w/2, 'plate');
end

function c = rect_uv(c, mp, u1, v1, u2, v2, st)
[x1, y1] = mp(u1, v1);  [x2, y2] = mp(u2, v2);
c = cv_rect(c, x1, y1, x2, y2, st);
end

% ---------------------------------------------------------------------------
function svg = fig_plan(P, R, kase)
% Plan, all rods projected. Steel beam X towards -x; in the corner column a
% second steel beam Y towards -y. Tension rods solid, shear rods (lower) light.
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

% steel beams (top flange), up to the end plate
c = cv_rect(c, xL, -bm.b/2, gx(-P.ep.t), bm.b/2, 'steel');
c = cv_seg(c, [xL -hb], [0 0], 'cl');
if cor
    c = cv_rect(c, -bm.b/2, yB, bm.b/2, gx(-P.ep.t), 'steel');
    c = cv_seg(c, [0 0], [yB -hb], 'cl');
end

% bars of the crossing beam (or of beam Y), then of the beam in line with X
for v = P.cb.v
    uh = P.cb.uh;  if v == 0, uh = P.cb.uh0; end
    if cor, c = cv_bar(c, [v v], [gx(uh+P.cb.db/2) yT], P.cb.db, 'ex');
    else,   c = cv_bar(c, [v v], [yB yT], P.cb.db, 'ex'); end
end
if cor, vb = P.cb.v; else, vb = P.cb.ve; end
for v = vb
    uh = P.cb.uh;  if v == 0, uh = P.cb.uh0; end
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
    c = draw_assembly_plan(c, P, R, 3, 1);
    c = draw_assembly_plan(c, P, R, 2, 0);
    YX = R.typ(2);  YY = R.typ(3);
else
    c = draw_assembly_plan(c, P, R, 1, 0);
    YX = R.typ(1);
end

% dimensions
c = cv_dim(c, -hb, hb, gx(P.fp.t), hb, 45, sprintf('%g', P.fp.t), -12);
c = cv_dim(c, gx(P.fp.t), hb, gx(P.bp.u), hb, 45);
c = cv_dim(c, gx(P.bp.u), hb, gx(P.bp.u+P.bp.t), hb, 45, sprintf('%g', P.bp.t), -9);
c = cv_dim(c, gx(P.bp.u+P.bp.t), hb, hb, hb, 45, sprintf('%g', P.col.b-P.bp.u-P.bp.t), 12);
c = cv_dim(c, -hb, hb, hb, hb, 100);
vv = sort([-YX.rowT(2) -YX.rowS(2) YX.rowS(2) YX.rowT(2)]);
c = cv_dim(c, -hb-60, -YX.rowT(2), -hb-60, YX.rowT(2), 40, sprintf('%g', 2*YX.rowT(2)));
c = cv_dim(c, -hb-60, -YX.rowS(2), -hb-60, YX.rowS(2), 90, sprintf('%g  (shear rods)', 2*YX.rowS(2)));
c = cv_dim(c, -hb-60, -P.fp.w/2, -hb-60, P.fp.w/2, 145, sprintf('%g  (plates)', P.fp.w));
c = cv_dim(c, xR, -P.cb.b/2, xR, P.cb.b/2, -35);
c = cv_dim(c, -P.cb.b/2, yT, P.cb.b/2, yT, 35);
c = cv_dim(c, -hb, -hb, -hb, hb, 260);
if cor
    c = cv_dim(c, -YY.rowT(2), -hb-60, YY.rowT(2), -hb-60, -40, sprintf('%g', 2*YY.rowT(2)));
end

% labels
c = cv_text(c, -520, 76, [bm.name ' (beam X)'], 'middle');
if cor
    c = cv_lead(c, gx(170), YX.rowT(2), 330, 640, {sprintf('CX: 2 rods %s low, z = %+.0f, over the flange of X', P.tr.lab, YX.rowT(1)), sprintf('back plate PL %gx%gx%g', P.bp.t, P.bp.h, P.bp.w)});
    c = cv_lead(c, YY.rowT(2), gx(250), 330, 470, {sprintf('CY: 2 rods %s high, z = %+.0f, over the flange of Y', P.tr.lab, YY.rowT(1)), 'they cross 11 mm over the rods of X'});
    c = cv_lead(c, -YY.rowS(2), gx(120), -420, -330, {'light red: shear rods (lower)', sprintf('X at %.0f, Y at %.0f', YX.rowS(1), YY.rowS(1))});
    c = cv_text(c, 62, -470, [bm.name ' (beam Y)'], 'start');
    c = cv_text(c, 170, yT-40, 'Concrete beam (in line with Y)', 'start');
else
    c = cv_lead(c, gx(170), YX.rowT(2), 330, 360, {sprintf('2 rods %s over the top flange, |v| = %g', P.tr.lab, YX.rowT(2)), sprintf('back plate PL %gx%gx%g', P.bp.t, P.bp.h, P.bp.w)});
    c = cv_lead(c, gx(140), -YX.rowS(2), -420, -230, {sprintf('light red: 2 shear rods %s (lower,', P.tr.lab), sprintf('z = %.0f), |v| = %g', YX.rowS(1), YX.rowS(2))});
    c = cv_text(c, 170, yT-40, 'Edge beam', 'start');
    c = cv_text(c, 170, yB+30, 'Edge beam', 'start');
end
c = cv_lead(c, gx(-P.ep.t/2), P.ep.w/2-10, -250, 400, {sprintf('end plate PL %gx%g on the beam,', P.ep.t, P.ep.w), sprintf('front plate PL %gx%g flush with the face', P.fp.t, P.fp.w)});
c = cv_text(c, 560, -185, 'Concrete beam (in line with X)', 'middle');
c = cv_lead(c, P.rod.p, -P.rod.p, 560, -250, {sprintf('4 rods %s%g of the', '&#216;', P.rod.db), 'steel column base plate'});
c = cv_lead(c, xc, -xc, 300, -330, sprintf('column 8 %s%g', '&#216;', P.col.db));
c = cv_lead(c, -xc, 0, -250, 560, {'mid-face column bar', 'passes between the rods'});
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_front(P, R)
% Edge column seen from outside, looking along the steel beam
hb = P.col.b/2;  bm = P.bm;  Y = R.typ(1);  d = P.tr.d;
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
for x = [-xc 0 xc], c = cv_bar(c, [x x], [zB zc], P.col.db, 'col'); end
for y = [-1 1]*P.rod.p, c = cv_bar(c, [y y], [zB ztop+60], P.rod.db, 'rod'); end
for z = [P.hoop.z P.hoop.ztop]
    c = cv_seg(c, [-xh xh], [z z], 'hoop');
end
for z = P.top.z, c = cv_bar(c, [-xh xh], [z z], P.top.db, 'tie'); end

% bars of the beam in line: sections and front hooks
for v = P.cb.ve
    c = cv_bar(c, [v v], [P.cb.zt(1), P.cb.zt(1)-15.5*P.cb.db], P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zt(1), P.cb.db, 'ex');
    c = cv_circ(c, v, P.cb.zb(1), P.cb.db, 'ex');
end

% front plate (translucent), end plate outline, beam section
c = cv_rect(c, -P.fp.w/2, Y.fp_bot, P.fp.w/2, Y.fp_top, 'platet');
c = cv_rect(c, -P.ep.w/2, Y.ep_bot, P.ep.w/2, Y.ep_top, 'hid');
c = cv_rect(c, -bm.b/2, -bm.tf, bm.b/2, 0, 'steel');
c = cv_rect(c, -bm.b/2, -bm.h, bm.b/2, -bm.h+bm.tf, 'steel');
c = cv_rect(c, -bm.tw/2, -bm.h+bm.tf, bm.tw/2, -bm.tf, 'steel');

% rods and the nuts on the end plate (circle through the nut corners)
for row = [Y.rowT; Y.rowS]'
    for v = row(2)*[-1 1]
        nt = P.tr.nut;  if row(1) == Y.rowS(1), nt = P.tr.nutS; end
        c = cv_circ(c, v, row(1), 2*nt/sqrt(3), 'ringok');
        c = cv_circ(c, v, row(1), d, 'anc');
    end
end

% dimensions
c = cv_dim(c, -Y.rowT(2), ztop, Y.rowT(2), ztop, 45, sprintf('%g', 2*Y.rowT(2)));
c = cv_dim(c, -P.ep.w/2, ztop, P.ep.w/2, ztop, 100, sprintf('%g  (end plate)', P.ep.w));
c = cv_dim(c, -P.fp.w/2, ztop, P.fp.w/2, ztop, 155, sprintf('%g  (front plate)', P.fp.w));
c = cv_dim(c, -Y.rowS(2), zB, Y.rowS(2), zB, -40, sprintf('%g', 2*Y.rowS(2)));
c = cv_dim(c, -xc, zB, xc, zB, -80, sprintf('%g  (column bars)', 2*xc));
c = cv_dim(c, -hb, zB, hb, zB, -120);
zz = sort([Y.fp_bot, Y.ep_bot, -bm.h, Y.rowS(1), 0, Y.rowT(1), Y.ep_top, Y.fp_top]);
for i = 1:numel(zz)-1
    c = cv_dim(c, yE, zz(i), yE, zz(i+1), -35, sprintf('%.0f', zz(i+1)-zz(i)));
end
c = cv_dim(c, -yE, -P.cb.h, -yE, 0, 35);
c = cv_dim(c, -yE, 0, -yE, ztop, 35, sprintf('%g', ztop));

% labels
c = cv_lead(c, -P.fp.w/2+8, Y.fp_bot+15, -330, -470, {sprintf('front plate PL %gx%gx%g (translucent)', P.fp.t, P.fp.w, Y.fp_top-Y.fp_bot), 'dashed: end plate of the beam'});
c = cv_lead(c, Y.rowT(2)+8, Y.rowT(1)+8, 330, 270, {sprintf('2 rods %s B7 over the flange,', P.tr.lab), 'circle: heavy nut corners'});
c = cv_lead(c, Y.rowS(2), Y.rowS(1)-10, 330, -440, sprintf('2 shear rods %s B7 (regular nuts)', P.tr.lab));
c = cv_lead(c, 94, P.cb.zt(1)-100, 330, -95, {sprintf('VCM top bars %s%g and their', '&#216;', P.cb.db), 'hook tails, behind the plate'});
c = cv_lead(c, -xc, zc-40, -330, 270, sprintf('column bars %s%g', '&#216;', P.col.db));
c = cv_lead(c, -P.rod.p, 80, -330, 220, sprintf('rods of the steel column %s%g', '&#216;', P.rod.db));
c = cv_text(c, -yE+20, -175, 'Edge beam', 'start');
c = cv_text(c, yE-20, -175, 'Edge beam', 'end');
c = cv_text(c, 0, -470, 'Hardened pedestal', 'middle');
svg = cv_end(c);
end

% ---------------------------------------------------------------------------
function svg = fig_assy(P, R, j)
% Shop drawing of the embedded assembly: side view (top) and plan (bottom).
% u = 0 at the outer face of the front plate.
Y = R.typ(j);  d = P.tr.d;  tn = P.tr.tnut;  w2 = P.tr.nut/2;  tw = 4;
gx = @(u) u;  oy = -480;                            % the plan is drawn 420 lower, v -> oy + v
c = cv_new(-170, 560, -640, 260, 1.15);
show = [1 1 1 0];
c = draw_rods_elev(c, P, R, j, gx, 'anc', show);
c = cv_seg(c, [-120 520], [0 0], 'cl');
c = cv_text(c, 525, -4, 'top of steel', 'start');
% plan
mp = @(u, v) deal(u, oy + v);
for sg = [-1 1]
    for row = [Y.rowT; Y.rowS]'
        v = sg*row(2);
        st = 'anc';  if row(1) == Y.rowS(1), st = 'anch'; end
        c = cv_bar(c, [-P.tr.out row(3)], oy + [v v], d, st);
        c = rect_uv(c, mp, P.fp.t, v-w2, P.fp.t+tn, v+w2, 'tail');
    end
    v = sg*Y.rowS(2);
    c = rect_uv(c, mp, P.tr.uS, v-15, P.tr.uS+tw+tn, v+15, 'tailr');
    v = sg*Y.rowT(2);
    c = rect_uv(c, mp, P.bp.u-tn, v-w2, P.bp.u, v+w2, 'tail');
    c = rect_uv(c, mp, P.bp.u+P.bp.t, v-w2, P.bp.u+P.bp.t+tw+tn, v+w2, 'tail');
end
c = rect_uv(c, mp, 0, -P.fp.w/2, P.fp.t, P.fp.w/2, 'plate');
c = rect_uv(c, mp, P.bp.u, -P.bp.w/2, P.bp.u+P.bp.t, P.bp.w/2, 'plate');
c = cv_seg(c, [-120 520], [oy oy], 'cl');

% dimensions, side view
zT = Y.rowT(1);  zS = Y.rowS(1);
c = cv_dim(c, -P.tr.out, Y.fp_top, 0, Y.fp_top, 30);
c = cv_dim(c, 0, Y.fp_top, P.fp.t, Y.fp_top, 30, sprintf('%g', P.fp.t), -10);
c = cv_dim(c, P.fp.t, Y.fp_top, P.bp.u, Y.fp_top, 30);
c = cv_dim(c, P.bp.u, Y.fp_top, P.bp.u+P.bp.t, Y.fp_top, 30, sprintf('%g', P.bp.t), 10);
c = cv_dim(c, -P.tr.out, Y.fp_top, Y.rowT(3), Y.fp_top, 65, sprintf('%g  (rod)', Y.L(1)));
c = cv_dim(c, -P.tr.out, Y.fp_bot, Y.rowS(3), Y.fp_bot, -30, sprintf('%g  (shear rod)', Y.L(2)));
c = cv_dim(c, 0, Y.fp_bot, P.tr.uS, Y.fp_bot, -65, sprintf('%g', P.tr.uS));
zz = sort([Y.fp_bot, zS, 0, zT, Y.fp_top]);
for i = 1:numel(zz)-1
    c = cv_dim(c, -P.tr.out, zz(i), -P.tr.out, zz(i+1), 30, sprintf('%.0f', zz(i+1)-zz(i)));
end
c = cv_dim(c, P.bp.u+P.bp.t, zT-P.bp.h/2, P.bp.u+P.bp.t, zT+P.bp.h/2, -45, sprintf('%g', P.bp.h));
% dimensions, plan
c = cv_dim(c, -P.tr.out, oy-Y.rowT(2), -P.tr.out, oy+Y.rowT(2), 30, sprintf('%g', 2*Y.rowT(2)));
c = cv_dim(c, -P.tr.out, oy-P.fp.w/2, -P.tr.out, oy+P.fp.w/2, 70, sprintf('%g', P.fp.w));
c = cv_dim(c, P.tr.uS+30, oy-Y.rowS(2), P.tr.uS+30, oy+Y.rowS(2), -20, sprintf('%g', 2*Y.rowS(2)));
c = cv_dim(c, P.bp.u+P.bp.t+40, oy-P.bp.w/2, P.bp.u+P.bp.t+40, oy+P.bp.w/2, -10, sprintf('%g', P.bp.w));
% labels
if j < 3, ttl = 'Assembly type E (edge) = type CX (corner, rods low)'; else, ttl = 'Assembly type CY (corner, rods high)'; end
c = cv_text(c, -160, 235, ['<tspan font-weight="bold">' ttl '</tspan>'], 'start');
c = cv_text(c, -160, 213, 'side view (top) and plan (bottom); u = 0 at the outer face of the front plate', 'start');
c = cv_text(c, 300, oy-P.fp.w/2-45, 'plan: light red = shear rods (lower)', 'middle');
c = cv_lead(c, P.fp.t/2, Y.fp_bot+20, 300, -200, {sprintf('front plate PL %gx%gx%g,', P.fp.t, P.fp.w, Y.fp_top-Y.fp_bot), sprintf('holes %s%g, nuts on both faces', '&#216;', P.tr.hole)});
svg = cv_end(c);
end

% ===========================================================================
%  drawing tools (copied unchanged from ../cantilever_anchor_V2/ca_draw.m)
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
