function R = ca_calc(P)
% CA_CALC  Loads, layout, clearances and limit states of the bolted plate anchorage.
%   R = ca_calc(P), P from ca_inputs. Units: N, mm, MPa (kN and m in the loads).
%   R.kase(k)  load cases: 1 edge, 2 corner 2 beams (trapezoid, both at once),
%              3 corner 2 beams (envelope: whole corner square on one beam), 4 corner 1 beam
%   R.typ(j)   connection types: 1 E (edge), 2 C1 (corner, one beam), 3 CX (corner, two
%              beams, beam X: anchors low), 4 CY (corner, two beams, beam Y: anchors high)
%   R.rows     limit states {group, name, reference, demand(1x4), capacity(1x4), unit, note}
%   R.clr      clearances {pair, nominal mm, note}
%   R.tolt     room for site errors {item, direction, room mm, what limits it}
%   R.ram      review of the user's RAM Connection model
%   R.plate    end plate thickness and grade study
%   Conservative choices (user, 2026-10-01): beam bars on the least favourable layer and
%   13 mm off, hooks of the beam bars 25 mm short; corner beams VCS; edge VCM, one bar per
%   stacked pair; concrete cracked; no directional factor on welds.

sq = sqrt(P.fc);  fc = P.fc;  bm = P.bm;  Ab = @(d) pi*d^2/4;
an = P.an;  db = an.db;  o4 = [1 1 1 1];

% ---- 1. loads ----------------------------------------------------------------
R.Ev  = 2/3*P.I*P.eta*P.Z*P.Fa;                     % NEC-SE-DS 3.4.4, fraction of D
R.q   = [1.2*P.qD+1.6*P.qL, (1.2+R.Ev)*P.qD+P.qL, (0.9-R.Ev)*P.qD];   % kN/m2
R.gsw = [1.2, 1.2+R.Ev, 0.9-R.Ev];
R.combo = {'1.2D + 1.6L', '1.2D + Ev + L', '0.9D - Ev'};
L = P.L/1000;  a0 = P.a0/1000;  s = P.s_edge/1000;  s2 = P.s_half/1000 + a0;
nm = {'Edge', 'Corner, 2 beams (trapezoid)', 'Corner, 2 beams (envelope)', 'Corner, 1 beam'};
% tributary beyond the face: width w(x) at the distance x from the face
%   edge: s;  trapezoid: s2 + x (the corner square split on the diagonal);
%   envelope: s2 + L (whole corner square on this beam);  one beam: s2 (no side overhang)
A = [s*L, s2*L + L^2/2, (s2+L)*L, s2*L];            % m2
S = [s*L^2/2, s2*L^2/2 + L^3/3, (s2+L)*L^2/2, s2*L^2/2];   % first moment about the face, m3
R.w = [s, s2, s2+L, s2];
for k = 1:4
    K.name = nm{k};  K.A = A(k);  K.S = S(k);
    K.V = R.q*A(k) + R.gsw*bm.w*L;                  % kN
    K.M = R.q*S(k) + R.gsw*bm.w*L^2/2;              % kN m
    [dummy, K.jg] = max(K.M(1:2));
    K.Mc = K.M(K.jg);  K.Vc = K.V(K.jg);
    K.fE = R.Ev*P.qD*S(k)/K.M(2);                   % Ev share of the moment (17.10.5.1)
    R.kase(k) = K;
end
% user minimum (edge "a bit above 20 kN m", corner 15.55): one factor on every case
R.Mets = (1.2 + R.Ev)*P.etabs.MD + P.etabs.ML;     % ETABS edge cantilever, 1.2D + Ev + L (kN m)
R.Vets = (1.2 + R.Ev)*P.etabs.VD + P.etabs.VL;
R.kM = max([1, P.Mmin(1)/R.kase(1).Mc, P.Mmin(2)/R.kase(3).Mc, R.Mets/R.kase(1).Mc]);
if isfield(P, 'kMforce'), R.kM = P.kMforce; end     % used to find the largest moment the joint takes
for k = 1:4
    R.kase(k).Mu = R.kM*R.kase(k).Mc*1e6;           % N mm
    R.kase(k).Vu = R.kM*R.kase(k).Vc*1e3;           % N
end

% ---- 2. connection types -------------------------------------------------------
tn = {'E', 'C1', 'CX', 'CY'};
wh = {'edge columns', 'corners with one cantilever', 'corner with two cantilevers, beam X', 'corner with two cantilevers, beam Y'};
kk = [1 4 3 3];                                     % load case of each type
zTs = [an.pf an.pf an.pf an.zH];
if isfield(an, 'zTt'), zTs = an.zTt; end           % study override: anchor level per type
zS  = -(bm.h - bm.tf) + an.pfS;                     % shear anchors, over the bottom flange
zC  = -(bm.h - bm.tf/2);                            % bottom flange centroid
nbar = [3 3 3 3];                                   % beam bars counted (VCM: one per stacked pair)
tor = [0.25 0.25 0.25 0.25];                        % torsion Tu = tor*Vu*b/2. User 2026-10-04: the border beam is bolted to
                                                    % the cantilever tips with the bolt group centred on the web (E: the two
                                                    % spans from opposite sides; corners: the beam end past the web): 15 mm of
                                                    % misalignment, several times the pattern-load torsion (was [0.5 1 1 1])
if isfield(P, 'tor'), tor = P.tor; end                % study override (border beam)
jc  = [1.25 1.0 1.0 1.0];                           % joint shear SI coefficient (V2)
for j = 1:4
    Y.name = tn{j};  Y.where = wh{j};  Y.k = kk(j);
    K = R.kase(kk(j));
    Y.Mu = K.Mu;  Y.Vu = K.Vu;
    Y.zT = zTs(j);  Y.zS = zS;  Y.vT = an.vT;  Y.vS = an.vS;
    Y.ep_top = 5*ceil((Y.zT + P.ep.over)/5);  Y.ep_bot = -bm.h - P.ep.under;
    if isfield(P.ep, 'ztop') && ~isempty(P.ep.ztop), Y.ep_top = P.ep.ztop; end   % one plate height for all types
    Y.H = Y.ep_top - Y.ep_bot;
    D = dg1(P, Y.Mu, Y.zT, Y.ep_bot, P.ep.w);
    Y.dg = D;  Y.T = D.T;  Y.lev = D.lev;  Y.Ta = D.T/2;
    Y.Tor = tor(j)*Y.Vu*bm.b/2;
    Y.Hc  = Y.Tor/(Y.zT - Y.zS);                    % horizontal couple, top and bottom anchors
    Y.nbar = nbar(j);  Y.jc = jc(j);
    Y.beam = 'VCS';  if j <= 2, Y.beam = 'VCM'; end   % user 2026-10-02: edge and one-cantilever corners: VCM
    R.typ(j) = Y;
end
R.zC = zC;

% ---- 3. back plate, development ------------------------------------------------------
H.uc = P.bp.u;                                      % apex of the breakout body: bearing face of the back plate
H.hef = P.bp.u;                                     % h_ef of the headed anchors (back plate)
H.Abrg = (P.bp.h*P.bp.w - 2*pi*P.an.hole^2/4)/2;    % bearing area per anchor
H.ldh12 = ldh19(P, P.cb.db, 1.0, 1.0);              % beam bars, as in V2
H.ld12 = max(P.fy*1.3/(2.1*sq)*P.cb.db, 300);       % beam top bar straight (psi_t 1.3), 25.4.2.3
R.hk = H;

% ---- 4. clearances (nominal, mm) ---------------------------------------------------
r  = db/2;  rh = P.hoop.db/2;  rt = P.top.db/2;  cb = P.cb.db/2;
rc = P.col.cover + P.col.dtie + P.col.db/2;         % column bar axis from a face
zc = P.col.top - P.col.ctop - P.col.db/2;           % axis of the column top hooks (level A)
uft = P.col.b - P.col.cover;                        % outer face of the far ties
utb = P.col.b - P.col.cover - rt;                   % axis of the back leg of the top ties (14)
ub1 = P.bp.u - an.tnut;                             % front nut on the back plate (no washer), front face
hb_ = P.bp.h/2;
c = {};
c(end+1,:) = {'Anchors - mid-face column bars (front and far)', an.vT - r - P.col.db/2, 'all types'};
c(end+1,:) = {'Anchors - rods of the steel column (v = 100)', P.rod.p - P.rod.db/2 - an.vT - r, 'all types'};
% the rods of the steel column go down more than 1 m below z = 0 (in place before the joint): every
% beam bar of the joint meets them
c(end+1,:) = {sprintf('Rods of the steel column (+-%g) - beam corner bars (+-%g in the joint), both beams, top and bottom', P.rod.p, max(P.cb.v)), P.rod.p - max(abs(P.cb.v)) - (P.rod.db + P.cb.db)/2, sprintf('in contact: pushed %g mm in from +-%g (the beam), slope about 1:%.0f', P.cb.vbm - max(P.cb.v), P.cb.vbm, (P.col.b/2 - P.rod.p + 50)/(P.cb.vbm - max(P.cb.v)))};
c(end+1,:) = {'Rods of the steel column - inner face of the column ties', (P.col.b/2 - P.col.cover - P.col.dtie) - (P.rod.p + P.rod.db/2), sprintf('room for the pour beside the rod + beam bar pair (rods at +-%g instead: %g to the beam bars, %g here)', P.rod.p + 12, P.rod.p + 12 - P.cb.vbm - (P.rod.db + P.cb.db)/2, (P.col.b/2 - P.col.cover - P.col.dtie) - (P.rod.p + 12 + P.rod.db/2))};
c(end+1,:) = {sprintf('Rods of the steel column - bottom-hook tails (u = %g, v = %g)', P.cb.ubh + P.cb.db/2, max(P.cb.v)), hypot((P.col.b/2 - P.rod.p) - (P.cb.ubh + P.cb.db/2), P.rod.p - max(abs(P.cb.v))) - (P.rod.db + P.cb.db)/2, ''};
zB = P.col.zhB;  zu = P.top.zu;  zl = min(P.top.z);  rbc = 3.5*P.col.db;
c(end+1,:) = {'Level-B hooks (side mid bars, across) - top anchors under them', (zB - P.col.db/2) - (an.pf + r), 'resting on them (E, C1, CX; D4: north and south mid bars on the anchors of X)'};
c(end+1,:) = {'Level-A hooks (along the anchors) - level-B hooks under them, where they cross', (zc - P.col.db/2) - (zB + P.col.db/2), ''};
c(end+1,:) = {'Column hooks of level A - top of the pedestal (cover)', P.col.ctop, 'ACI Table 20.5.1.3.1: 40; 10 by the user (base plate grout and slab on top)'};
c(end+1,:) = {'D4: level-A hooks - anchors of Y, where they cross', (zc - P.col.db/2) - (an.zH + r), ''};
c(end+1,:) = {'D4: level-A hook (north corner, u = 350 from the south face) - front nuts of the Y back plate', (zc - P.col.db/2) - (an.zH + an.nut/sqrt(3)), 'over them'};
c(end+1,:) = {'D4: level-B hooks (v = 8) - anchors of Y beside them', an.vT - r - 8 - P.col.db/2, ''};
c(end+1,:) = {'Corner: anchors of X - anchors of Y, where they cross', (an.zH - r) - (an.pf + r), 'Y resting on X'};
c(end+1,:) = {'Anchors of Y - top of the pedestal', P.col.top - (an.zH + r), 'under the base plate of the steel column'};
c(end+1,:) = {sprintf('Far-face column bars: straight part above the tie 14 under the anchors (+%g)', zu), (zc - rbc) - zu, sprintf('level-A bends start at %+g: the tie bears on the straight bars', zc - rbc)};
c(end+1,:) = {sprintf('Tie 14 under the anchors (%+g) - front nuts of B1 (a flat down)', zu), (an.pf - an.nut/2) - (zu + rt), 'right under them (E, C1, CX)'};
c(end+1,:) = {sprintf('Tie 14 under the anchors (%+g) - top anchors', zu), (an.pf - r) - (zu + rt), ''};
c(end+1,:) = {'B1 face - back leg of the ties 14', P.bp.u - (P.col.b - (P.col.cover + P.col.dtie - P.top.db)), 'in contact (E, C1, CX)'};
c(end+1,:) = {'B1 bottom edge - contact line with the tie 14 under the anchors (its axis)', zu - (an.pf - hb_), 'B1 of E, C1, CX'};
t1 = P.t10;  r1 = t1.db/2;
c(end+1,:) = {sprintf('Tie 10 over the anchors (%+g) - front nuts of B1 (flats up)', t1.z), (t1.z - r1) - (an.pf + an.nut/2), 'E, C1, CX'};
c(end+1,:) = {sprintf('Tie 10 over the anchors (%+g) - level-A hooks over it', t1.z), (zc - P.col.db/2) - (t1.z + r1), 'where the tails cross its legs'};
c(end+1,:) = {sprintf('Tie 10 over the anchors (%+g) - bars in the level-A bend (plan gap)', t1.z), rbc - sqrt(rbc^2 - (t1.z - (zc - rbc))^2), sprintf('bends start at %+g; at 20 cover the gap is 13', zc - rbc)};
c(end+1,:) = {sprintf('D4: tie 10 over the anchors (%+g) - front nuts of the Y back plate (flats up)', t1.zD4), (t1.zD4 - r1) - (an.zH + an.nut/2), ''};
c(end+1,:) = {sprintf('D4: tie 10 over the anchors (%+g) - level-A hooks over it', t1.zD4), (zc - P.col.db/2) - (t1.zD4 + r1), ''};
u2 = P.ub2;  r2 = u2.db/2;
c(end+1,:) = {sprintf('U-bars over the A1 (shear across z = 0): legs (v = %g) - A1', u2.v), (u2.v - r2) - (an.vT + r), ''};
c(end+1,:) = {'U-bars: legs - bastones beside them (v = 76, at -80)', (min(abs(P.cb.bas.v)) - P.cb.db/2) - (u2.v + r2), ''};
c(end+1,:) = {'U-bars: crown - level-A hooks over it', (zc - P.col.db/2) - (u2.zc + r2), ''};
c(end+1,:) = {'U-bars: legs (u) - front nuts of B1', (P.bp.u - an.tnut) - (u2.u + r2), ''};
c(end+1,:) = {'U-bars: legs - rods of the steel column (u = 300, v = 100)', hypot(P.col.b/2 + P.rod.p - u2.u, P.rod.p - u2.v) - r2 - P.rod.db/2, ''};
c(end+1,:) = {'Ties 14: clear between the two', (zu - rt) - (zl + rt), 'room for the concrete'};
c(end+1,:) = {sprintf('Lower tie 14 (%+g) - beam top bars (upper layer)', zl), (zl - rt) - (max(P.cb.zt) + cb), ''};
c(end+1,:) = {'Ties 14 - top of the pedestal (lowest)', P.col.top - zl, 'ACI 10.7.6.1.5: both within 127 of the top'};
c(end+1,:) = {'Back plate - outer face of the far ties', P.bp.u - uft, 'the back plate is behind the far ties'};
c(end+1,:) = {'Front nut on the back plate (corners) - far mid-face column bar (v = 0)', an.vT - an.nut/sqrt(3) - P.col.db/2, 'side by side, same depth'};
c(end+1,:) = {'Back plate of E, C1, CX - top of the pedestal', P.col.top - (an.pf + hb_), 'cover; the slab is cast against it later'};
c(end+1,:) = {'Back plate of CY - top of the pedestal', P.col.top - (an.zH + hb_), 'under the base plate grout of the steel column'};
c(end+1,:) = {'End of the tension anchors - far face of the column', P.col.b - an.uT, 'above the beam top the slab covers it later'};
c(end+1,:) = {'Corner: back plate of X - anchors of Y', (P.bp.u - P.col.b/2) - an.vT - r, 'no conflict'};
zTa = min(P.hoop.z(P.hoop.z > zS));  zTb = max(P.hoop.z(P.hoop.z < zS));          % joint ties above and below the A2
c(end+1,:) = {sprintf('Shear anchors - joint ties at %g and %g', zTa, zTb), min((zTa - rh) - (zS + r), (zS - r) - (zTb + rh)), ''};
c(end+1,:) = {'Lowest joint tie - bottom bars of the crossing beam (above it)', (P.cb.zbc - P.cb.db/2) - (min(P.hoop.z) + rh), ''};
c(end+1,:) = {'Shear anchors - hook tails of the beam bars (v = 0)', an.vS - r - cb, 'at u = 50'};
c(end+1,:) = {'Corner: end nut of the shear anchors of X - shear anchors of Y', (P.col.b/2 - an.uS - an.twsh - an.tnut) - an.vS - an.wsh/2 - r, 'they do not cross (short)'};
wr = an.wsh/2;
c(end+1,:) = {'Washer under the nut - fillet of the top flange', an.pf - wr - P.w.flange, 'washer OD 30'};
c(end+1,:) = {'Washer under the nut - fillet of the bottom flange', an.pfS - wr - P.w.flange, ''};
c(end+1,:) = {'Washer under the nut - web fillet', an.vS - wr - bm.tw/2 - P.w.web, ''};
c(end+1,:) = {'Washer under the nut - rib fillet', an.vT - wr - P.rib.t/2 - P.rib.w, ''};
c(end+1,:) = {'Hole to the plate top edge (AISC Table J3.4M: 22)', min([R.typ.ep_top] - [R.typ.zT]), 'type CY; E, C1, CX: more'};
if P.ub.on                                          % supplementary U-bar (E, C1, CX), resting on the A1
    ub = P.ub;  zU = an.pf + an.db/2 + ub.db/2;
    c(end+1,:) = {'U-bar (resting on the A1) - level-A column hooks above', (zc - P.col.db/2) - (zU + ub.db/2), 'this is the room left for the A1 to be higher'};
    c(end+1,:) = {'U-bar legs - top anchors', ub.v - ub.db/2 - an.vT - an.db/2, ''};
    c(end+1,:) = {'U-bar legs - VCM corner bars (v = 94)', max(abs(P.cb.v)) - P.cb.db/2 - ub.v - ub.db/2, 'crossing at right angles'};
    c(end+1,:) = {'U-bar - front nut on the back plate', (P.bp.u - an.tnut) - (ub.u + ub.db/2), ''};
    c(end+1,:) = {'U-bar - grid-4 / crossing beam top bars (u = 294)', (ub.u - ub.db/2) - (P.col.b/2 + max(P.cb.v) + P.cb.db/2), ''};
    c(end+1,:) = {'U-bar - rods of the steel column (u = 300, v = 100)', min(P.rod.p - P.rod.db/2 - ub.v - ub.db/2, (ub.u - ub.db/2) - (P.col.b/2 + P.rod.p + P.rod.db/2)), ''};
    c(end+1,:) = {'U-bar hook tail - joint tie at -225', (min(P.hoop.z) - P.hoop.db/2) - (ub.zbot + ub.db/2), ''};
    c(end+1,:) = {'U-bar hook tail - beam bottom bars', (ub.zbot - ub.db/2) - (max(P.cb.zb) + P.cb.db/2), ''};
end
if P.cb.bas.on                                      % bastones (E only): second layer beside the -80 bars, staggered 90 deg hooks
    bs = P.cb.bas;  ubT = bs.uh + cb;  ubX = P.cb.uh + P.cb.db + cb;        % hook tail axes: bastón, the -80 bar beside it
    c(end+1,:) = {'Top line (3 bars) with the bastones in the second layer, clear', max(P.cb.v) - 2*cb, 'pour: was 32 with the bastones in the top line'};
    c(end+1,:) = {'Bastón - the -80 bar beside it, in the span', max(P.cb.v) - max(bs.v) - 2*cb, 'in contact: a 2-bar bundle (ACI 25.6.1)'};
    c(end+1,:) = {'Bastón hook tail - tail of the -80 bar beside it (staggered)', hypot(ubT - ubX, max(P.cb.v) - max(bs.v)) - 2*cb, sprintf('tails at u = %g and %g', ubX, ubT)};
    c(end+1,:) = {'Bastón hook tail - shear anchors A2 (v = 35)', max(bs.v) - an.vS - cb - r, 'the tail passes beside the A2'};
    c(end+1,:) = {'Bastón hook tail - bottom-hook tails (u = 132, v = 88)', hypot((P.cb.ubh + cb) - ubT, max(P.cb.vbh) - max(bs.v)) - 2*cb, ''};
    c(end+1,:) = {'Bastón (-80) - crossing beam top bars (-68) above it', (min(P.cb.zt) - cb) - (bs.z + cb), 'resting under them, as the -80 bars'};
    % D3, D4X: bastones on the level of the beam in line (-68), beside its corner bars; hook tails at u = uh + 6
    c(end+1,:) = {'D3, D4X: bastón (-68) - corner bar beside it', max(P.cb.v) - max(bs.v) - 2*cb, 'in contact: a 2-bar bundle'};
    c(end+1,:) = {'D3, D4X: bastón hook tail - crossing -80 bars of grid D (u = 112)', (P.col.b/2 - max(P.cb.v)) - ubT - 2*cb, 'the tail passes in front of them'};
end
% bottom bars of the beam in line, hooked up in the joint: clearances in the section along the
% cantilever (same v) and in plan at the shear anchors (z of A2)
Bh = bothooks(P, zS);  R.bot = Bh;
for i = 1:size(Bh.clr, 1), c(end+1,:) = Bh.clr(i,:); end
R.clr = c;

% ---- 5. limit states -----------------------------------------------------------------
T  = [R.typ.T];  Ta = T/2;  V = [R.typ.Vu];  Mu = [R.typ.Mu];  Hc = [R.typ.Hc];
zT = [R.typ.zT];
rows = {};
% anchors, steel
phiNsa = 0.75*an.Ase*an.futa;                       % 17.6.1.2, Table 17.5.3(a), ductile
rows = addr(rows, 'Anchors', sprintf('Top anchor, steel in tension (%s %s)', an.thr, an.grade), '17.6.1.2', Ta, phiNsa*o4, 'kN', ...
    sprintf('&phi;N<sub>sa</sub> = 0.75 A<sub>se</sub> f<sub>uta</sub> = 0.75 (%g)(%g) = %.1f kN; N<sub>ua</sub> = T/2', an.Ase, an.futa, phiNsa/1e3));
% thread stripping of the rod (external thread) inside one nut: shear area per FED-STD-H28,
% n threads per mm, nut minor diameter D1 max, rod pitch diameter d2 min, engagement = nut height
% - 1 (chamfer), crest factor (0.75 for threads cut on ribbed bar, 1 on round rod)
Le = an.tnut - 1;  th = an.thd;
Asn = pi*th(1)*Le*th(2)*(1/(2*th(1)) + 0.57735*(th(3) - th(2)))*th(4);
phiNst = 0.75*0.6*an.futa*Asn;
rows = addr(rows, 'Anchors', sprintf('Thread stripping of the rod inside the nut (%g high)', an.tnut), 'FED-STD-H28', Ta, phiNst*o4, 'kN', ...
    sprintf('A<sub>s</sub> = &pi; n L<sub>e</sub> D<sub>1,max</sub> [1/(2n) + 0.577 (d<sub>2,min</sub> &minus; D<sub>1,max</sub>)] = %.0f mm&sup2;, L<sub>e</sub> = %g; &phi;N = 0.75 (0.6 f<sub>uta</sub>) A<sub>s</sub> = %.1f kN. Stripping %.0f kN &gt; rod rupture A<sub>se</sub> f<sub>uta</sub> = %.0f kN: the rod breaks first (nut grade 8 or A194 2H)', ...
    Asn, Le, phiNst/1e3, 0.6*an.futa*Asn/1e3, an.Ase*an.futa/1e3));
phiVsa = 0.80*0.65*0.6*an.Ase*an.futa;              % 17.7.1.2(b) x 0.80, built-up grout pad 17.7.1.2.1
VuS = hypot(V/2, Hc/2);
rows = addr(rows, 'Anchors', 'Shear anchor, steel (gravity + torsion), grout pad', '17.7.1.2(b), 17.7.1.2.1', VuS, phiVsa*o4, 'kN', ...
    sprintf('&phi;V<sub>sa</sub> = 0.80 (0.65)(0.6 A<sub>se</sub> f<sub>uta</sub>) = %.1f kN; V<sub>ua</sub> = &radic;[(V/2)&sup2; + (H/2)&sup2;]', phiVsa/1e3));
% if the 4 holes bear at once (holes drilled to the anchors), the top anchors also take shear
Vt = hypot(V/4, Hc/2);
inter = Ta/phiNsa + Vt/phiVsa;
rows = addr(rows, 'Anchors', 'Top anchor, tension + shear if all 4 bear (interaction)', '17.8.3', inter, 1.2*o4, '-', ...
    sprintf('N<sub>ua</sub>/&phi;N<sub>n</sub> + V<sub>ua</sub>/&phi;V<sub>n</sub> &le; 1.2, V<sub>ua</sub> = &radic;[(V/4)&sup2; + (H/2)&sup2;] = %.1f kN', Vt(1)/1e3));
% back plate: pullout, side-face blowout to the pedestal top, bending
phiNp = 0.70*8*H.Abrg*fc;                           % 17.6.3.2.2(a), psi_cP = 1 (cracked)
rows = addr(rows, 'Anchors', 'Pullout at the back plate (per anchor)', '17.6.3.2.2(a)', Ta, phiNp*o4, 'kN', ...
    sprintf('&phi;N<sub>pn</sub> = 0.70 (8 A<sub>brg</sub> f''<sub>c</sub>), A<sub>brg</sub> = (%gx%g - 2 holes)/2 = %.0f mm&sup2;: %.0f kN', P.bp.h, P.bp.w, H.Abrg, phiNp/1e3));
for j = 1:4
    ca1 = P.col.top - zT(j);  ca2 = P.col.b/2 - an.vT;
    Nsb = 13*ca1*sqrt(H.Abrg)*sq;
    if ca2 < 3*ca1, Nsb = Nsb*(1 + ca2/ca1)/4; end
    Nsbg(j) = Nsb*min(1 + 2*an.vT/(6*ca1), 2);
end
rows = addr(rows, 'Anchors', 'Side-face blowout of the back plate towards the pedestal top (group)', '17.6.4.1, 17.6.4.2', T, 0.70*Nsbg, 'kN', ...
    sprintf('h<sub>ef</sub> = %g &gt; 2.5 c<sub>a1</sub>, c<sub>a1</sub> = %g: N<sub>sb</sub> = 13 c<sub>a1</sub> &radic;A<sub>brg</sub> &radic;f''<sub>c</sub> (x (1 + c<sub>a2</sub>/c<sub>a1</sub>)/4 when c<sub>a2</sub> &lt; 3c<sub>a1</sub>), group (1 + s/6c<sub>a1</sub>); &phi; = 0.70', H.hef, P.col.top - zT(1)));
% shear across z = 0: the pedestal above the beam top takes the pull at B1 and passes it down into the
% joint (D4: the pulls of X and Y on the same stub, added as vectors). Shear friction, 22.9.4.2, monolithic
% concrete mu = 1.4, steel: the legs of the inverted U-bars (developed: crown over the A1, hooks below)
Avf = P.ub2.n*2*pi*P.ub2.db^2/4;  phiVnf = 0.75*1.4*Avf*P.fy;
Ac0 = P.col.b^2;  phiVmax = 0.75*min([0.2*fc, 3.3 + 0.08*fc, 11])*Ac0;   % 22.9.4.4
Vz0 = T;  Vz0([3 4]) = hypot(T(3), T(4));
rows = addr(rows, 'Concrete', 'Shear across z = 0 (pedestal above the beam top): shear friction with the U-bars', '22.9.4.2', Vz0, min(phiVnf, phiVmax)*o4, 'kN', ...
    sprintf('%d U-bars &#216;%g over the A1 (%d legs, A<sub>vf</sub> = %.0f mm&sup2;): &phi;V<sub>n</sub> = 0.75 (1.4) A<sub>vf</sub> f<sub>y</sub> = %.0f kN; D4: X and Y together', P.ub2.n, P.ub2.db, 2*P.ub2.n, Avf, phiVnf/1e3));
% back plate as a beam along its length: uniform bearing from the concrete, the nut of each
% anchor pushing back on a ring around the hole (d_w of the nut); net width through the holes
for j = 1:4
    Bb(j) = ca_bpbeam(P, T(j), P.an.dw/2);
end
R.bpb = Bb;  R.bpk = ca_bpbeam(P, T(1), 0);            % R.bpk: point reaction at the axis (comparison)
phiMbp = 0.9*P.st.Fy(P.bp.grade)*P.bp.h*P.bp.t^2/4;
rows = addr(rows, 'Anchors', 'Back plate bending between the anchors (full section)', 'AISC F11', [Bb.M0], phiMbp*o4, 'kN m', ...
    sprintf('M = R s/2 &minus; w b&sup2;/8 = %.3f kN m (does not depend on how the nut spreads its push); &phi;M<sub>p</sub> = 0.9 F<sub>y</sub> h t&sup2;/4 = %.3f kN m', Bb(1).M0/1e6, phiMbp/1e6));
rows = addr(rows, 'Anchors', 'Back plate through the hole: bending + shear (net section)', 'AISC F11, J4.2', [Bb.Mh], [Bb.Ch], 'kN m', ...
    sprintf('worst cut through the hole at %.1f from the centre: net width %.1f, M = %.3f kN m, V = %.1f kN; &phi;M<sub>p,net</sub> (1 &minus; (V/V<sub>p</sub>)&sup2;) = %.3f kN m', Bb(1).xh, Bb(1).bh, Bb(1).Mh/1e6, Bb(1).Vh/1e3, Bb(1).Ch/1e6));
rows = addr(rows, 'Anchors', 'Back plate shear rupture through the hole', 'AISC J4.2(b)', [Bb.Vmx], [Bb.Cvr], 'kN', ...
    sprintf('&phi;R<sub>n</sub> = 0.75 &times; 0.6 F<sub>u</sub> (h &minus; d<sub>h</sub>) t = %.1f kN', Bb(1).Cvr/1e3));
% shear anchors, concrete. Shear on the group: V down (gravity; 0.9D - Ev still pushes down)
% and the torsion couple H across the beam (towards a side face, either way).
%   down: no free edge (the column goes on below): no breakout down; pryout behind the anchors
%   across: breakout towards the side face, 17.7.2, cases 1 and 2 of R17.7.2.1 (holes not welded)
%   V down is parallel to the side faces: 2 x the perpendicular value, psi_ed,V = 1 (17.7.2.1(c))
S = shear_conc(P, V, Hc);  R.shc = S;
rows = addr(rows, 'Anchors', 'Pryout of the 2 shear anchors', '17.7.3', S.Vg, S.phiVcp*o4, 'kN', ...
    sprintf('&phi;V<sub>cpg</sub> = 0.70 k<sub>cp</sub> N<sub>cbg</sub>, k<sub>cp</sub> = 2, h<sub>ef</sub> = %g, k<sub>c</sub> = 10, cracked: N<sub>cbg</sub> = %.1f kN; V<sub>u</sub> = &radic;(V&sup2; + H&sup2;) on the group', S.hef, S.Ncbg/1e3));
rows = addr(rows, 'Anchors', 'Shear breakout of the shear anchors towards a side face, case 1 (near anchor)', '17.7.2, R17.7.2.1', sqrt(S.ell1), o4, '-', ...
    sprintf('near anchor, c<sub>a1</sub> = %g: &radic;[(H/2 / &phi;V<sub>cb</sub>)&sup2; + (V/2 / 2&phi;V<sub>cb</sub>)&sup2;], &phi;V<sub>cb</sub> = %.1f kN (&perp; edge), %.1f kN (&#8741; edge)', S.ca1(1), S.phiVb(1)/1e3, S.phiVp(1)/1e3));
rows = addr(rows, 'Anchors', 'Shear breakout of the shear anchors towards a side face, case 2 (far anchor)', '17.7.2, R17.7.2.1', sqrt(S.ell2), o4, '-', ...
    sprintf('far anchor takes all, c<sub>a1</sub> = %g: &radic;[(H / &phi;V<sub>cbg</sub>)&sup2; + (V / 2&phi;V<sub>cbg</sub>)&sup2;], &phi;V<sub>cbg</sub> = %.1f kN (&perp;), %.1f kN (&#8741;)', S.ca1(2), S.phiVb(2)/1e3, S.phiVp(2)/1e3));
% concrete: unreinforced breakout of the top anchors, for information
for j = 1:4
    Q = brk(P, R.typ(j).zT, an.vT, H.hef);
    phiNcb(j) = Q.phiN;  R.brk(j) = Q;
end
rows = addr(rows, 'Concrete', 'Unreinforced breakout of the 2 top anchors (why anchor reinforcement)', '17.6.2', T, phiNcb, 'kN', ...
    sprintf('top of the pedestal %g mm over the anchors, sides at %g: h''<sub>ef</sub> = %.0f (17.6.2.1.2), &phi;N<sub>cbg</sub> = %.1f kN. Not relied upon', ...
    P.col.top - an.pf, P.col.b/2 - an.vT, R.brk(1).hefp, phiNcb(1)/1e3), 'info');
% anchor reinforcement: top bars of the beam in line. Which bars count (V2 method): the ones
% with the longest length inside the breakout body, as many as make the larger of the two
% ratios (steel, length inside) smallest. Apex at the bearing face of the back plate, slope
% 1 along the anchor : 1.5 across; beam bars 13 low and 25 short, anchors P.tol.za high, back plate 10 short.
% Levels: lower layer (-68) for E, C1, CX; CY is by rule the corner beam whose top bars are on
% the upper layer (-56): its anchors are the high ones. VCM: the upper bar of each stacked pair.
vV = P.cb.v;  zlay = [min(P.cb.zt) min(P.cb.zt) min(P.cb.zt) max(P.cb.zt)];
uhb = [P.cb.uh P.cb.uh0 P.cb.uh];
for j = 1:4
    vVj = vV;  uhj = uhb;  zbj = zlay(j)*[1 1 1];
    if P.cb.bas.on && P.cb.bas.types(j)            % bastones: second layer, staggered hooks
        vVj = [vV P.cb.bas.v];  uhj = [uhb P.cb.bas.uh*[1 1]];  zbj = [zbj P.cb.bas.zt(j)*[1 1]];
    end
    Cn = cone(P, H, [R.typ(j).zT an.vT], vVj, uhj, zbj, T(j));
    Cs(j) = Cn;  ins(j) = Cn.inside;  ins_nom(j) = Cn.inside_nom;  rmax(j) = Cn.rmax;  kb(j) = Cn.k;
end
R.cone = Cs;
phiNar = 0.75*kb*Ab(P.cb.db)*P.fy;
rows = addr(rows, 'Concrete', 'Anchor reinforcement: top bars of the beam in line, steel', '17.5.2.1(a), Table 17.5.3', T, phiNar, 'kN', ...
    sprintf('&phi;N = 0.75 n A<sub>s</sub> f<sub>y</sub> = 0.75 (n)(%.0f)(%g); n = %d / %d / %d / %d bars counted (E counts the centre bar too, hooked at u = %g)', Ab(P.cb.db), P.fy, kb, P.cb.uh0));
rows = addr(rows, 'Concrete', 'Anchor reinforcement: beam bars inside the breakout body (tolerances against)', '17.5.2.1(a), 25.4.3', H.ldh12*o4, ins, 'mm', ...
    sprintf('l<sub>dh</sub>(&#216;12) = %.0f; available %.0f (nominal %.0f): apex at the back plate (u = %g), beam bars %g low and %g short, anchors %g high, back plate %g short', ...
    H.ldh12, ins(1), ins_nom(1), H.uc, P.tol.zb, P.tol.ub, P.tol.za, P.tol.ua));
rows = addr(rows, 'Concrete', 'Anchor reinforcement within 0.5 h<sub>ef</sub> of the anchors', 'R17.5.2.1', rmax, 0.5*H.uc*o4, 'mm', ...
    sprintf('farthest counted bar %.0f mm from an anchor; 0.5 h<sub>ef</sub> = %.0f', rmax(1), 0.5*H.uc));
if P.ub.on                                          % supplementary U-bar: vertical tie at the back plate
    ub = P.ub;  zl = P.cb.zt(2);  Vt = zeros(1, 4);  avU = zeros(1, 4);
    for j = 1:4
        rB = hypot(an.vT, R.typ(j).zT - zl);        % centre bar, beside the anchor axis
        Vt(j) = T(j)*(R.typ(j).zT - zl)/(rB/1.5)*ub.types(j);   % steepest path: plate to the crossing
        avU(j) = (R.typ(j).zT - P.bp.h/2) - (ub.zbot - ub.db/2);
    end
    phiU = 0.75*2*Ab(ub.db)*P.fy;
    R.ub = struct('Vt', Vt, 'phi', phiU, 'ldh', ldh19(P, ub.db, 1.0, 1.0), 'avail', avU, 'zU', an.pf + an.db/2 + ub.db/2);
    rows = addr(rows, 'Concrete', 'Supplementary U-bar over the top anchors: vertical tie (not at CY)', '23.7 (tie), supplementary', Vt, phiU*o4, 'kN', ...
        sprintf(['steepest path, from the plate down to where the centre bar crosses the body: V = T (z<sub>A</sub> - z<sub>bars</sub>)/(r/1.5) = %.2f T; ' ...
                 'U &#216;%g, 2 legs: &phi;T = 0.75 &times; 2 &times; %.0f &times; %g = %.0f kN'], Vt(1)/T(1), ub.db, Ab(ub.db), P.fy, phiU/1e3));
    rows = addr(rows, 'Concrete', 'Supplementary U-bar: legs developed below the plate (hooks)', '25.4.3', R.ub.ldh*o4, avU, 'mm', ...
        sprintf('l<sub>dh</sub>(&#216;%g) = %.0f (hooks 2 &times; %g apart, &psi;<sub>r</sub> = 1); available from the bottom of the plate (z = %g) to the outside of the hook (z = %g): %.0f', ...
        ub.db, R.ub.ldh, 2*ub.v, an.pf - P.bp.h/2, ub.zbot - ub.db/2, avU(1)));
end
% ---- stress test: every bar crossing the body counted as a HOOKED ANCHOR (17.6.3.2.2b, no bond),
% user 2026-10-03. Beam top bars (top line; + the 2 extra at -80 where they are not in contact:
% C4 and D4-south), the side legs of the closed ties 14 (P.top.z) (anchored by their front corner),
% the 4-piece tie at -95 (135 deg hooks), and a possible third closed tie 14 at -41. Only bars
% within 0.5 h_ef of an anchor, with their hook inside the body (at the cantilever face).
Np1 = @(db) 0.70*0.9*P.fc*4.5*db*db;                % phi N_p of one hooked bar, e_h = 4.5 d_b, cracked
legv = P.col.b/2 - (P.col.cover + P.col.dtie + P.col.db/2 - P.col.db/2 - P.top.db/2);   % v of the tie legs (axis 43 from a face)
hka.kb = [R.cone.k];  hka.pair = [2 0 0 2];
hka.r14 = zeros(2, 4);  hka.r10 = zeros(1, 4);  hka.r41 = zeros(1, 4);
for j = 1:4
    zA = R.typ(j).zT + P.tol.za;
    hka.r14(:,j) = hypot(legv - an.vT, zA - P.top.z(:));
    hka.r10(j) = hypot(P.col.b/2 - P.col.cover - P.hoop.db/2 - an.vT, zA - max(P.hoop.z));
    hka.r41(j) = hypot(legv - an.vT, zA - P.top.zp);
end
hka.n14 = 2*sum(hka.r14 <= 0.5*H.uc, 1);  hka.n10 = 2*(hka.r10 <= 0.5*H.uc);  hka.n41 = 2*(hka.r41 <= 0.5*H.uc);
hka.Nb = hka.kb*Np1(P.cb.db);  hka.Np = hka.pair*Np1(P.cb.db);
hka.N14 = hka.n14*Np1(P.top.db);  hka.N10 = hka.n10*Np1(P.hoop.db);  hka.N41 = hka.n41*Np1(P.top.db);
hka.one = [Np1(P.cb.db) Np1(P.top.db) Np1(P.hoop.db)];
% every joint-tie layer, old and new layout: side legs (parallel to the anchors) at v = +-(b/2 - 45);
% they count if within 0.5 h_ef of an anchor (R17.5.2.1); the breakout surface at 35 deg to the face
% (R17.6.2.1) is crossed at u = u_apex - r tan 35, with the front corner of the tie (u = 45) inside
vJ = P.col.b/2 - P.col.cover - P.hoop.db/2;  t35 = tand(35);
for k = 1:2
    if k == 1, zz = P.hoop.zold; else, zz = P.hoop.z; end
    L = struct('z', zz, 'rn', hypot(vJ - an.vT, R.typ(1).zT - zz), 'rt', hypot(vJ - an.vT, R.typ(1).zT + P.tol.za - zz));
    L.ucn = H.uc - L.rn*t35;  L.uct = H.uc - P.tol.ua - L.rt*t35;
    L.in_n = L.rn <= 0.5*H.uc;  L.in_t = L.rt <= 0.5*H.uc;
    hka.lay(k) = L;
end
hka.zlim = [R.typ(1).zT, R.typ(1).zT + P.tol.za] - sqrt((0.5*H.uc)^2 - (vJ - an.vT)^2);   % lowest level that counts
R.hka = hka;
rows = addr(rows, 'Concrete', 'Stress test: beam top bars as hooked anchors (no bond)', '17.6.3.2.2(b)', T, hka.Nb, 'kN', ...
    sprintf('&phi;N<sub>p</sub> = 0.70 &times; 0.9 f''<sub>c</sub> (4.5 d<sub>b</sub>) d<sub>b</sub> = %.1f kN per &#216;12; %d / %d / %d / %d bars', hka.one(1)/1e3, hka.kb), 'info');
rows = addr(rows, 'Concrete', 'Stress test: beam bars + column ties as hooked anchors (no bond)', '17.6.3.2.2(b)', T, hka.Nb + hka.Np + hka.N14 + hka.N10, 'kN', ...
    sprintf('+ 2 extra beam bars (C4, D4-south), %d legs &#216;14 (%.1f kN each), %d / %d / %d / %d legs &#216;10 at %g (%.1f kN each)', hka.n14(1), hka.one(2)/1e3, hka.n10, max(P.hoop.z), hka.one(3)/1e3), 'info');
rows = addr(rows, 'Concrete', 'Anchor reinforcement developed beyond the body', '25.4.2.3', H.ld12*o4, 1000*o4, 'mm', ...
    sprintf('l<sub>d</sub> = f<sub>y</sub> &psi;<sub>t</sub> d<sub>b</sub>/(2.1 &radic;f''<sub>c</sub>) = %.0f; the bars continue into the beam span (1000 is only a marker)', H.ld12), 'info');

% ---- end plate: DG1 (column base reading, as RAM) and DG4/DG16 (end plate) ----------
st = P.ep.grade;  Fy = P.st.Fy(st);  Fu = P.st.Fu(st);  tp = P.ep.t;
mn = 0.9*Fy*tp^2/4;                                 % phi Mn per unit width, N mm/mm
for j = 1:4
    D = R.typ(j).dg;
    mt(j) = D.Mt;  mb(j) = D.Mb;  m45(j) = D.M45;
    Yl(j) = ylin(P, R.typ(j).zT, R.typ(j).zT, R.typ(j).ep_top - R.typ(j).zT, P.rib.on);
    Yl0(j) = ylin(P, R.typ(j).zT, R.typ(j).zT, 0, 0);
end
% strict strip (lower bound) with the rib. Lamina 1 = end plate: the pull of each anchor is split
% between a 45 deg strip to the top flange (x1 = to the weld toe) and one to the rib (x2 = to its
% weld toe); each strip counts only the width that lands on its support (flange + weld, rib).
% Lamina 2 = extra plate (if any), loaded through contact under the washer (compression), with
% strips to its own edge welds on the flange line (z = 0) and on the rib line (gap edge).
% Each lamina carries the share that equalises the two (not composite: capacities add, t^2 each).
for j = 1:4
    Yj = R.typ(j);
    x1 = Yj.zT - P.w.flange;
    w1 = min(an.vT + x1, bm.b/2 + P.w.flange) - max(an.vT - x1, P.rib.on*(P.rib.t/2 + P.rib.w));
    x2 = an.vT - P.rib.t/2 - P.rib.w;
    w2 = min(Yj.zT + x2, Yj.ep_top) - max(Yj.zT - x2, P.w.flange);
    k1 = x1/w1;  k2 = x2/w2;                         % moment per unit width per unit load
    c1 = k1*k2/(k1 + k2);  al = k2/(k1 + k2);        % lamina 1, best split
    if ~P.rib.on, c1 = k1;  al = 1; end              % no rib: strip to the flange only
    SL(j).x1 = x1;  SL(j).w1 = w1;  SL(j).x2 = x2;  SL(j).w2 = w2;  SL(j).al = al;  SL(j).c1 = c1;
    if P.dbl.on
        y1 = Yj.zT;                                  % to the bottom edge weld (z = 0)
        u1 = min(an.vT + y1, P.ep.w/2) - max(an.vT - y1, P.dbl.gap/2);
        y2 = an.vT - P.dbl.gap/2;                    % to the inner edge weld
        u2 = min(Yj.zT + y2, Yj.ep_top) - max(Yj.zT - y2, 0);
        q1 = y1/u1;  q2 = y2/u2;
        c2 = q1*q2/(q1 + q2);  al2 = q2/(q1 + q2);
        if ~P.rib.on, c2 = q1;  al2 = 1; end         % no rib behind the gap: no support on that line
        mn1 = 0.9*P.st.Fy(P.ep.grade)*P.ep.t^2/4;  mn2 = 0.9*P.st.Fy(P.dbl.grade)*P.dbl.t^2/4;
        be = (mn1/c1)/(mn1/c1 + mn2/c2);             % share to the end plate: both at the same ratio
        SL(j).y1 = y1;  SL(j).u1 = u1;  SL(j).y2 = y2;  SL(j).u2 = u2;  SL(j).al2 = al2;  SL(j).c2 = c2;  SL(j).be = be;
        ms(j) = be*c1*Ta(j);                         % end plate moment per unit width
        R2(j) = (1 - be)*Ta(j);                      % pull carried by the extra plate, per anchor
    else
        SL(j).be = 1;  ms(j) = c1*Ta(j);  R2(j) = 0;
    end
end
R.strip = SL;
if P.dbl.on
    rows = addr(rows, 'End plate', sprintf('Tension side: end plate PL %g + extra plate PL %g (%s), strips to flange and rib', tp, P.dbl.t, P.st.name{st}), 'lower bound (strip), DG1 3.4.3', ms, mn*o4, 'kN m/m', ...
        sprintf('end plate: x<sub>1</sub> = %g / b<sub>1</sub> = %g, x<sub>2</sub> = %g / b<sub>2</sub> = %g; extra plate: y<sub>1</sub> = %g / b = %g, y<sub>2</sub> = %g / b = %g; %.0f%% of T<sub>a</sub> = %.1f kN in the end plate: m = %.2f kN m/m; &phi;m<sub>p</sub> = %.2f', ...
        SL(1).x1, SL(1).w1, SL(1).x2, SL(1).w2, SL(1).y1, SL(1).u1, SL(1).y2, SL(1).u2, 100*SL(1).be, Ta(1)/1e3, ms(1)/1e3, mn/1e3));
    Ld = (P.ep.w/2 - P.dbl.gap/2) + [R.typ.ep_top];   % bottom + inner edge welds of one piece
    phiRd = 0.75*0.6*P.FEXX*0.707*P.dbl.w*Ld;
    rows = addr(rows, 'End plate', 'Extra plate: edge welds on the flange and rib lines (one piece)', 'AISC J2.4', R2, phiRd, 'kN', ...
        sprintf('pull in the extra plate (1 - %.2f) T<sub>a</sub> = %.1f kN; fillet %g over %.0f mm: &phi;R = %.0f kN', SL(1).be, R2(1)/1e3, P.dbl.w, Ld(1), phiRd(1)/1e3));
else
    rows = addr(rows, 'End plate', sprintf('Tension side, strips to the flange and to the rib (PL %g %s)', tp, P.st.name{st}), 'lower bound (strip), DG1 3.4.3', ms, mn*o4, 'kN m/m', ...
        sprintf('x<sub>1</sub> = %g / b<sub>1</sub> = %g, x<sub>2</sub> = %g / b<sub>2</sub> = %g: m = %.2f kN m/m; &phi;m<sub>p</sub> = %.2f', SL(1).x1, SL(1).w1, SL(1).x2, SL(1).w2, ms(1)/1e3, mn/1e3));
end
bp_ = min(P.ep.w, bm.b + 25);  gg = 2*an.vT;  ss_ = 0.5*sqrt(bp_*gg);
if P.rib.on
    rows = addr(rows, 'End plate', 'Yield lines with the rib (upper bound)', 'DG4 4ES, outer bolts only', Mu, 0.9*Fy*tp^2*Yl, 'kN m', ...
        sprintf('Y<sub>p</sub> = b<sub>p</sub>/2 h<sub>0</sub> (1/s + 1/(2p<sub>f</sub>)) + (2/g) h<sub>0</sub> (d<sub>e</sub> + p<sub>f</sub>): E %.0f mm, CY %.0f mm', Yl(1), Yl(4)), 'info');
    Rr = 2*(1 - [SL.al]).*[SL.be].*Ta;              % force taken by the rib from the two anchors (end plate share)
    Lr = [R.typ.ep_top] - 15;                       % rib-to-plate fillets, less a 15 mm corner clip
    phiRr = 0.75*0.6*P.FEXX*0.707*P.rib.w*2*Lr;
    rows = addr(rows, 'End plate', 'Rib-to-end-plate fillets (strip reaction of both anchors)', 'AISC J2.4', Rr, phiRr, 'kN', ...
        sprintf('R = 2 (1 - %.2f)(%.2f) T<sub>a</sub> = %.1f kN; &phi;R = 0.75 (0.6)(%g)(0.707)(%g)(2 x %.0f) = %.0f kN', SL(1).al, SL(1).be, Rr(1)/1e3, P.FEXX, P.rib.w, Lr(1), phiRr(1)/1e3));
    Ls_ = [R.typ.ep_top]/tan(pi/6);
    phiRf2 = 0.75*0.6*P.FEXX*0.707*P.rib.w*2*(Ls_ - 15);
    rows = addr(rows, 'End plate', 'Rib-to-flange fillets', 'AISC J2.4', Rr, phiRf2, 'kN', ...
        sprintf('rib %.0f long on the flange (h<sub>st</sub>/tan 30&deg;): &phi;R = %.0f kN', Ls_(1), phiRf2(1)/1e3));
    rows = addr(rows, 'End plate', 'Rib: thickness', 'DG4 4ES', bm.tw*P.Fy/248*o4, P.rib.t*o4, 'mm', ...
        sprintf('t<sub>s</sub> &ge; t<sub>w</sub> F<sub>yb</sub>/F<sub>ys</sub> = %.1f; length along the flange &ge; h<sub>st</sub>/tan 30&deg; (E %.0f, CY %.0f mm)', bm.tw, R.typ(1).ep_top/tan(pi/6), R.typ(4).ep_top/tan(pi/6)));
end
rows = addr(rows, 'End plate', 'Tension side without the rib, full width', 'DG1 3.4.3, Eq. 3.4.5a', mt, mn*o4, 'kN m/m', ...
    sprintf('M<sub>pl</sub> = T x/B, x = p<sub>f</sub> + t<sub>f</sub>/2 = %.1f: %.2f kN m/m', R.typ(1).dg.x, mt(1)/1e3), 'info');
rows = addr(rows, 'End plate', 'Bearing side, strip below the bottom flange (m)', 'DG1 3.4.2', mb, mn*o4, 'kN m/m', ...
    sprintf('f<sub>p</sub> = %.1f MPa, Y = %.1f, m = %.0f: M<sub>pl</sub> = %.2f kN m/m (f<sub>p</sub> m&sup2;/2 if Y &ge; m, else f<sub>p</sub> Y (m - Y/2))', R.typ(1).dg.fp, R.typ(1).dg.Y, R.typ(1).dg.m, mb(1)/1e3));
rows = addr(rows, 'End plate', 'Bearing side, strip beyond the flange tips (n)', 'DG1 3.4.2 (n for m)', arrayfun(@(Y) Y.dg.Mbn, R.typ), mn*o4, 'kN m/m', ...
    sprintf('n = (B - 0.8 b<sub>f</sub>)/2 = (%g - 0.8 x %g)/2 = %.0f: M<sub>pl</sub> = %.2f kN m/m', P.ep.w, bm.b, R.typ(1).dg.n, R.typ(1).dg.Mbn/1e3));
rows = addr(rows, 'End plate', 'Tension side, RAM''s 45&deg; strips per anchor, no rib', 'DG1 Fig. 3.1.1', m45, mn*o4, 'kN m/m', ...
    'b<sub>eff</sub> = 2 x per anchor: M<sub>pl</sub> = (T/2) x/(2x) = T/4 per mm; ignores the rib', 'info');
teff = sqrt(tp^2 + P.dbl.on*P.dbl.t^2*P.st.Fy(P.dbl.grade)/Fy);   % same plastic capacity
bpr = P.an.pf - db/2;  pp = min(P.ep.w, bm.b + 25)/2;
tmin = sqrt(4*Ta*bpr/(0.9*pp*Fu));
rows = addr(rows, 'End plate', 'No prying (AISC Manual): t &ge; t<sub>min</sub>', 'AISC Manual Eq. 9-20a', tmin, teff*o4, 'mm', ...
    sprintf('t<sub>min</sub> = &radic;[4 T<sub>a</sub> b''/(&phi; p F<sub>u</sub>)], b'' = %g, p = %.1f: %.1f mm; t<sub>eff</sub> = &radic;(t<sub>1</sub>&sup2; + t<sub>2</sub>&sup2;) = %.1f', bpr, pp, tmin(1), teff));
rows = addr(rows, 'End plate', 'No prying, strict: 1.11 m &le; &phi;m<sub>p</sub> on the strip moment', 'DG16 2.2 (thick plate)', 1.11*ms, mn*o4, 'kN m/m', ...
    'the plate stays elastic at 1/1.11 of the strip demand');
Ff = Mu/(bm.h - bm.tf);  Lf = 2*bm.b - bm.tw;
phiRf = 0.75*0.6*P.FEXX*0.707*P.w.flange*Lf;
rows = addr(rows, 'End plate', 'Fillet, tension flange to end plate (site)', 'AISC J2.4', Ff, phiRf*o4, 'kN', ...
    sprintf('F<sub>f</sub> = M<sub>u</sub>/(h - t<sub>f</sub>); &phi;R = 0.75 (0.6)(%g)(0.707)(%g)(%.0f) = %.0f kN, no 1.5 factor', P.FEXX, P.w.flange, Lf, phiRf/1e3));
Lw = 2*(bm.h - 2*bm.tf);
phiRw = 0.75*0.6*P.FEXX*0.707*P.w.web*Lw;
rows = addr(rows, 'End plate', 'Fillets, web to end plate (shear, site)', 'AISC J2.4', V, phiRw*o4, 'kN', ...
    sprintf('&phi;R = 0.75 (0.6)(%g)(0.707)(%g)(2 x %.0f) = %.0f kN', P.FEXX, P.w.web, Lw/2, phiRw/1e3));
phiBr = 0.75*2.4*db*tp*Fu;
rows = addr(rows, 'End plate', 'Bearing of a shear anchor on the end plate', 'AISC J3.10', VuS, phiBr*o4, 'kN', ...
    sprintf('&phi;R = 0.75 (2.4 d t F<sub>u</sub>) = %.0f kN', phiBr/1e3));
% bearing on the face: DG1 uses f_p,max with sqrt(A2/A1) = 1 in the plate checks above; the face
% (400 wide, top of the pedestal 100 over the beam top) allows a concentric A2 similar to A1
for j = 1:4
    Yj = R.typ(j);  hA = Yj.ep_top - Yj.ep_bot;  zc_ = (Yj.ep_top + Yj.ep_bot)/2;
    k2 = min([P.col.b/P.ep.w, 2*(P.col.top - zc_)/hA, 2]);
    fpr(j) = 0.65*0.85*fc*min(k2, 2);
end
rows = addr(rows, 'End plate', 'Bearing stress on the concrete face (grout pad)', 'DG1 3.1.1, ACI 22.8.3.2', arrayfun(@(Y) Y.dg.fp, R.typ), fpr, 'MPa', ...
    sprintf('used f<sub>p</sub> = 0.65 (0.85 f''<sub>c</sub>) = %.1f MPa; allowed with &radic;(A<sub>2</sub>/A<sub>1</sub>) = %.2f: %.1f MPa. Grout f''<sub>g</sub> &ge; %g MPa', R.typ(1).dg.fp, fpr(1)/R.typ(1).dg.fp, fpr(1), P.fg));
% strict: DG1 with f_p at the full allowed value (sqrt(A2/A1) of the face): shorter block, higher pressure
for j = 1:4
    Ds(j) = dg1(P, R.typ(j).Mu, R.typ(j).zT, R.typ(j).ep_bot, P.ep.w, fpr(j));
end
R.dgs = Ds;
rows = addr(rows, 'End plate', 'Bearing side at f<sub>p,max</sub> with &radic;(A<sub>2</sub>/A<sub>1</sub>): m and n strips (strict)', 'DG1 3.4.2', max([Ds.Mb], [Ds.Mbn]), mn*o4, 'kN m/m', ...
    sprintf('f<sub>p</sub> = %.1f MPa, Y = %.1f: m strip %.2f, n strip %.2f kN m/m', Ds(1).fp, Ds(1).Y, Ds(1).Mb/1e3, Ds(1).Mbn/1e3));

% ---- steel beam -----------------------------------------------------------------------
B.Mp = P.Fy*bm.Zx;  ho = bm.h - bm.tf;
B.Lp = 1.76*bm.ry*sqrt(P.E/P.Fy);
B.Cw = bm.Iy*ho^2/4;  B.rts = sqrt(sqrt(bm.Iy*B.Cw)/bm.Sx);
jj = bm.J/(bm.Sx*ho);
B.Lr = 1.95*B.rts*P.E/(0.7*P.Fy)*sqrt(jj + sqrt(jj^2 + 6.76*(0.7*P.Fy/P.E)^2));
B.phiMn25 = 0.9*ltb(P, B, 2.5*P.L);
rows = addr(rows, 'Beam', sprintf('%s flexure, LTB with L<sub>b</sub> = 2.5 L (tip free, load on top)', bm.name), 'AISC F2.2', Mu, B.phiMn25*o4, 'kN m', ...
    sprintf('L<sub>b</sub> = 2.5 (%g) = %.0f mm, C<sub>b</sub> = 1: &phi;M<sub>n</sub> = %.1f kN m (&phi;M<sub>p</sub> = %.1f)', P.L, 2.5*P.L, B.phiMn25/1e6, 0.9*B.Mp/1e6));
phiVn = 0.6*P.Fy*bm.h*bm.tw;
rows = addr(rows, 'Beam', sprintf('%s shear', bm.name), 'AISC G2.1', V, phiVn*o4, 'kN', sprintf('&phi;V<sub>n</sub> = 1.0 (0.6 F<sub>y</sub> d t<sub>w</sub>) = %.0f kN', phiVn/1e3));
w_s = ((P.qD + P.qL)*R.w + bm.w);                   % kN/m = N/mm, service
B.def = w_s*P.L^4/(8*P.E*bm.Ix);
rows = addr(rows, 'Beam', 'Tip deflection under D + L (beam only)', 'NEC, L/180 for cantilevers', B.def, P.L/180*o4, 'mm', ...
    sprintf('&delta; = w L<sup>4</sup>/(8 E I) = %.1f mm; plus the rotation of the connection', B.def(1)), 'info');
R.beam = B;

% ---- joint, beams, pedestal ---------------------------------------------------------
phiVj = 0.75*[R.typ.jc]*sq*P.col.b^2;
rows = addr(rows, 'Joint', 'Joint shear (the pull T crosses the joint)', '15.4.2.3', T, phiVj, 'kN', ...
    sprintf('&phi;V<sub>n</sub> = 0.75 (%.2f) &radic;f''<sub>c</sub> A<sub>j</sub> = %.0f kN, A<sub>j</sub> = %g&sup2;', R.typ(1).jc, phiVj(1)/1e3, P.col.b));
% concrete beam in line, at the column face: the user's ETABS moments include the cantilever but
% not Ev; Ev of the cantilever is added to the seismic combination, all of it into the beam
% (none to the columns). Edge = B6; corners = B48 (both VCM, 5 bars; one per stacked pair is NOT
% a limit here: all 5 bars work in flexure). Bars on the lower layer (conservative).
nBj = 2*P.cb.bas.on*P.cb.bas.types;                 % bastones per type
nB = nBj(1);  nin = P.cb.nin;                       % top bars of the beam in line (5 VCM, 3 VCS)
zl = min(P.cb.zt);                                  % its top line in the joint (lower layer, conservative)
zc5 = (3*zl + (nin - 3)*P.cb.zp + nBj.*P.cb.bas.zt)./(nin + nBj);  dcb5 = P.cb.h + zc5;  dcb = dcb5(1);
As5v = (nin + nBj)*Ab(P.cb.db);  a5v = As5v*P.fy/(0.85*fc*P.cb.b);  a5 = a5v(1);
phiMcb = 0.9*As5v*P.fy.*(dcb5 - a5v/2);
MevE = R.Ev*(P.etabs.MD + P.etabs.VD*P.col.b/1000);              % kN m
kc_ = [1, R.kase(4).Mc/R.kase(1).Mc, R.kase(3).Mc/R.kase(1).Mc, R.kase(3).Mc/R.kase(1).Mc];   % corners scaled
Mb = [P.etabs.Mbeam_edge; P.etabs.Mbeam_corner; P.etabs.Mbeam_corner; P.etabs.Mbeam_corner];
for j = find(~isnan(P.etabs.Mneg)), Mb(j,:) = [0 P.etabs.Mneg(j)]; end      % the user's moments at that joint
Mfar = max(Mb(:,1)', Mb(:,2)' + MevE*kc_)*1e6;
rows = addr(rows, 'Joint', 'Concrete beam in line (ETABS, with the cantilever) + E<sub>v</sub> of the cantilever', '22.2', Mfar, phiMcb, 'kN m', ...
    sprintf(['M<sub>u</sub> = ETABS M<sup>-</sup> at the face + E<sub>v</sub> share (E: B6 max(%.1f, %.1f + %.1f) = %.1f); C1 B4 30.0, CX grid 4 24.3 (user). ' ...
             'Bars: C4 5 + 2 bastones, C1 5, CX 3 + 2 bastones, CY 5; &phi;M<sub>n</sub> = 0.9 A<sub>s</sub> f<sub>y</sub> (d - a/2): %.1f / %.1f / %.1f / %.1f kN m'], ...
    Mb(1,1), Mb(1,2), MevE, Mfar(1)/1e6, phiMcb/1e6));
% upper bound: the anchor pull T added to the bar force of the beam moment. It counts the cantilever's share of
% M twice (that share is the same force), so it is safe; the exact sum takes M without that share.
Fb = Mfar./(dcb5 - a5v/2);  Fcap = 0.9*As5v*P.fy;
rows = addr(rows, 'Joint', 'Top bars at the face: T + M/jd (upper bound, the cantilever counted twice)', '22.2, 17.5.2.1', T + Fb, Fcap, 'kN', ...
    sprintf('T + M<sub>u</sub>/(d - a/2) &le; 0.9 A<sub>s</sub> f<sub>y</sub>; E: %.1f + %.1f = %.1f kN; capacity %.0f kN', T(1)/1e3, Fb(1)/1e3, (T(1) + Fb(1))/1e3, Fcap(1)/1e3));
As3 = 3*Ab(P.cb.db);  d3 = P.cb.h + min(P.cb.zt);  a3 = As3*P.fy/(0.85*fc*P.cb.b);
phiM3 = 0.9*As3*P.fy*(d3 - a3/2)*o4;
rows = addr(rows, 'Joint', 'Same, counting only the 3 bars of the top line (the 2 in contact under them are a hooked bundle, R25.6.1.5)', '22.2, R25.6.1.5', Mfar, phiM3, 'kN m', ...
    sprintf('3 &#216;12, d = %.0f: &phi;M<sub>n</sub> = %.1f kN m. Your beam design: check, or separate the stacked bars at their hooks', d3, phiM3(1)/1e6), 'info');
R.phiM3 = phiM3;
dp = P.col.b - rc;
phiVp = 0.75*(0.17*sq*P.col.b*dp + 2*Ab(P.col.dtie)*420*dp/P.col.s);
rows = addr(rows, 'Joint', 'Pedestal shear if all of T went into the pedestal', '22.5', T, phiVp*o4, 'kN', ...
    sprintf('&phi;V<sub>n</sub> = 0.75 (0.17 &radic;f''<sub>c</sub> b d + A<sub>v</sub> f<sub>yt</sub> d/s) = %.0f kN', phiVp/1e3));
% top anchors in shear, concrete side. They always take the torsion couple H (across, towards a
% side face, with the top of the pedestal at c_a2 above); V down only if all 4 holes bear (V/4
% each). V down points away from the top face: no breakout up; the top face is where a pryout
% crater opens, which the pryout check (2 N_cbg, cone cut by the top) covers. Tension + shear 17.8.
dcr = @(nm) rows{find(strncmp(rows(:,2), nm, numel(nm)), 1), 4}./rows{find(strncmp(rows(:,2), nm, numel(nm)), 1), 5};
nT = max([dcr('Top anchor, steel in tension'); dcr('Pullout at the back plate'); dcr('Side-face blowout of the back plate'); ...
          [R.cone.nTi]], [], 1);
St = shear_top(P, R, [R.typ.Vu], [R.typ.Hc], nT, 0.80*0.65*0.6*an.Ase*an.futa);
R.sht = St;
rows = addr(rows, 'Anchors', 'Top anchors, concrete in shear: torsion couple H (V on the shear anchors)', '17.7.2, 17.7.3', St.s(1,:), o4, '-', ...
    sprintf('largest of: breakout to a side face, case 1 (H/2, c<sub>a1</sub> = %g) and case 2 (H, c<sub>a1</sub> = %g), top of the pedestal %g above (&psi;<sub>ed,V</sub>, A<sub>Vc</sub> cut); pryout 2 N<sub>cbg</sub> (cone cut by the top); steel', St.ca1(1), St.ca1(2), St.ctop(1)));
rows = addr(rows, 'Anchors', 'Top anchors, tension + shear (H): interaction', '17.8', St.int(1,:), o4, '-', ...
    'N/&phi;N<sub>n</sub> (largest tension ratio: steel, pullout, blowout, anchor reinforcement steel with every beam bar still developed inside the body) + V/&phi;V<sub>n</sub> &le; 1.2 (shown /1.2); either alone when the other is &le; 0.2');
rows = addr(rows, 'Anchors', 'Top anchors, tension + shear if all 4 holes bear (V/4 each): interaction', '17.8', St.int(2,:), o4, '-', ...
    'if exceeded, the concrete at the top anchors cracks and their share of V moves to the shear anchors (designed for all of V, as in case 2 of R17.7.2.1); H stays', 'info');
rows = addr(rows, 'Concrete', 'Beam bottom bars: hook developed in the joint (from the far face)', '25.4.3', H.ldh12*o4, R.bot.dev*o4, 'mm', ...
    sprintf('l<sub>dh</sub>(&#216;12) = %.0f; available %g (outside of the hooks at %g from the cantilever face)', H.ldh12, R.bot.dev, P.cb.ubh));
% positive moment in the beam in line near the joint: only the 2 hooked corner bars are taken as developed
% (ACI 18.3.2 minimum, 9.7.7); ETABS moment 0.5 m from the face used at the face (conservative)
dbt = -P.cb.zbl;  Asb = 2*pi*P.cb.db^2/4;  ab = Asb*P.fy/(0.85*fc*P.cb.b);  phiMb = 0.9*Asb*P.fy*(dbt - ab/2);
rows = addr(rows, 'Concrete', 'Beam bottom bars: positive moment near the joint, 2 hooked bars only (ETABS)', '9.5, 22.2, 18.3.2', P.etabs.Mpos*1e6, phiMb*o4, 'kN m', ...
    sprintf('ETABS, 0.5 m from the face, taken at the face; &phi;M<sub>n</sub> = 0.9 A<sub>s</sub> f<sub>y</sub>(d - a/2), 2 &#216;%g, d = %g, a = %.1f: %.1f kN m', P.cb.db, dbt, ab, phiMb*1e-6));
R.rows = rows;
R.rows = rows;
R.Mfar = Mfar;  R.phiMcb = phiMcb;

% ---- 6. end plate study (type E) ------------------------------------------------------
% (a) the user's plate, 250 wide, 55 below the bottom flange, 12 mm A36, with the real loads
Du = dg1(P, R.typ(1).Mu, an.pf, -bm.h - 55, 250);
mnA = 0.9*P.st.Fy(1)*12^2/4;  mnG = 0.9*P.st.Fy(2)*12^2/4;
PS.user = [Du.Mb Du.Mbn]/mnA;                       % m and n sides
PS.n250 = dg1(P, R.typ(1).Mu, an.pf, -bm.h - P.ep.under, 250).Mbn/mnG;   % 250 wide, 12 mm Gr50
% (b) thickness and grade with the proposed geometry
for g = 1:2
    for i = 1:2
        mn_ = 0.9*P.st.Fy(g)*P.st.t(i)^2/4;
        PS.tab{g,i} = [ms(1), mb(1), R.typ(1).dg.Mbn, 1.11*ms(1), m45(1)]/mn_;
        PS.tab{g,i}(6) = R.typ(1).Mu/(0.9*P.st.Fy(g)*P.st.t(i)^2*Yl(1));
    end
end
R.plate = PS;

% ---- 7. the user's RAM model ----------------------------------------------------------
M = P.ram;  zc0 = -bm.h/2;                          % plate centre on the beam centre
M.z = zc0 + M.anc(:,2);  M.v = M.anc(:,1);
k = find(M.keep);
M.zk = M.z(k);  M.vk = M.v(k);
M.top = max(M.zk);                                  % top row level
M.pf = M.top;                                       % top row above the flange face (z = 0)
M.sp = min(abs(diff(unique(M.zk))));                % row spacing
M.c_mid  = min(abs(M.vk)) - r - P.col.db/2;         % anchor at v = 0 vs the mid-face bar (negative = through it)
M.c_rod  = P.rod.p - P.rod.db/2 - max(abs(M.vk)) - r;
zr2 = max(M.zk(M.zk < 0));                          % second row
M.z2 = zr2;
M.c_bar  = (zr2 - r) - (max(P.cb.zt) + cb);         % second row over the beam top bars (upper layer)
M.c_barT = M.c_bar - P.tol.zb;
M.c_nut  = M.pf - P.an.wsh/2 - P.w.flange;          % washer over the flange fillet
% loads
M.Mnew = R.typ(1).Mu/1e6;  M.Vnew = R.typ(1).Vu/1e3;
% J-bolt pullout as RAM, cracked (17.6.3.2.2b, psi_cP = 1.0) against RAM's own Tmax
M.phiNp_c = 0.70*0.9*fc*M.eh*db;
M.phiNp_u = 1.4*M.phiNp_c;
% breakout with the real top edge (pedestal top 80 over the top row), 318-19, cracked
cT = P.col.top - M.top;  cS = P.col.b/2 - 75;
hp = max(max(cT, cS)/1.5, 150/3);
M.hefp = hp;
M.ANc = (cT + M.sp + 1.5*hp)*(2*cS + 150);
M.ANco = 9*hp^2;
M.ped = 0.7 + 0.3*min(cT, cS)/(1.5*hp);
M.Nb = 10*sq*hp^1.5;
M.phiNcbg = 0.70*M.ANc/M.ANco*M.ped*M.Nb;
M.Tsum5 = 3*15.11e3 + 2*10.59e3;                    % RAM's anchor forces, 5 anchors kept
% shear key pocket: 100 deep, 250 wide, at the plate centre
M.key_u = M.key(2);  M.key_hits = {};
if M.key_u + 10 > rc - P.col.db/2, M.key_hits{end+1} = sprintf('mid-face column bar at u = %g, v = 0', rc); end
if M.key_u + 10 > P.col.cover, M.key_hits{end+1} = sprintf('front legs of the joint ties at u = %g', P.col.cover + rh); end
if M.key_u + 10 > P.cb.uh - P.cb.db, M.key_hits{end+1} = sprintf('hook tails of the beam bars at u = %g (v = 0, &plusmn;%g)', P.cb.uh - cb, max(P.cb.v)); end
R.ram = M;

% ---- 8. room for site errors (with everything else nominal) ---------------------------
t = {};
t(end+1,:) = {'Top anchors', 'lower (z)', an.pf - P.an.wsh/2 - P.w.flange, sprintf('washer on the flange fillet; the tie 14 under the B1 nuts (%+g) goes down with them', P.top.zu)};
t(end+1,:) = {'Top anchors E, C1, CX', 'higher (z)', (zc - zB - P.col.db) + (P.col.ctop - P.col.cmin), sprintf('level B rides on them; level A over it, its top cover %g down to %g', P.col.ctop, P.col.cmin)};
t(end+1,:) = {'Top anchors CY', 'lower (z)', (an.zH - r) - (an.pf + r), 'resting on the anchors of X and the level-B hooks'};
t(end+1,:) = {'Top anchors CY', 'higher (z)', (P.t10.zD4 - P.t10.db/2) - (an.zH + an.nut/2), sprintf('front nuts under the tie 10 at %+g', P.t10.zD4)};
t(end+1,:) = {'Top anchors CX (D4)', 'higher (z)', 0, 'the anchors of Y rest on them'};
t(end+1,:) = {'Top anchors', 'towards the axis (v)', an.vT - r - P.col.db/2, 'mid-face column bar'};
t(end+1,:) = {'Top anchors', 'away from the axis (v)', P.rod.p - P.rod.db/2 - an.vT - r, 'rods of the steel column; the strip check is redone beyond 10'};
t(end+1,:) = {'Back plate', 'towards the face (u)', 0, 'against the ties 14'};
t(end+1,:) = {'Back plate', 'deeper (u)', Inf, 'free (nuts); the bar ends may reach into the slab zone'};
t(end+1,:) = {'Shear anchors', 'up or down (z)', min((zTa - rh) - (zS + r), (zS - r) - (zTb + rh)), sprintf('joint ties at %g / %g (ties can be moved)', zTa, zTb)};
t(end+1,:) = {'Shear anchors', 'lower (z)', an.pfS - P.an.wsh/2 - P.w.flange, 'washer reaches the bottom flange fillet'};
t(end+1,:) = {'Any anchor', 'in the plane of the face', Inf, 'none if the end plate is drilled to the surveyed anchors'};
t(end+1,:) = {'Beam bars (anchor reinforcement)', 'level and ends', NaN, sprintf('already in the checks: %g low, %g short (ACI 26.6.2.1)', P.tol.zb, P.tol.ub)};
R.tolt = t;
end

% =====================================================================================
function D = dg1(P, Mu, zT, zbot, B, fpx)
% AISC DG1 2nd ed. 3.4, large moment, Pu = 0: rectangular bearing block at
% f_p,max (sqrt(A2/A1) = 1) at the compression edge of the plate (z = zbot).
bm = P.bm;
D.fp = 0.65*0.85*P.fc;                              % DG1 3.1.1, phi_c = 0.65
if nargin > 5, D.fp = fpx; end                      % strict: f_p,max with sqrt(A2/A1)
q = D.fp*B;
D.ft = zT - zbot;                                   % anchors to the compression edge (f + N/2)
D.Y = D.ft - sqrt(D.ft^2 - 2*Mu/q);                 % Eq. 3.4.3 with Pr = 0
D.T = q*D.Y;                                        % Eq. 3.4.2
D.lev = D.ft - D.Y/2;
D.m = (-bm.h + 0.025*bm.h) - zbot;                  % to the 0.95 d line (DG1 3.1.2)
D.n = (B - 0.8*bm.b)/2;                             % beyond the flange tips (DG1 3.1.2)
mb_ = @(c) (D.Y >= c)*D.fp*c^2/2 + (D.Y < c)*D.fp*D.Y*(c - D.Y/2);   % Eq. 3.3.14 / 3.3.15 forms
D.Mb = mb_(D.m);  D.Mbn = mb_(D.n);
D.x = zT + bm.tf/2;                                 % Eq. 3.4.6: anchor to the centre of the flange
D.Mt = D.T*D.x/B;                                   % Eq. 3.4.5a, per unit width
D.M45 = D.T/4;                                      % per anchor (T/2) over b_eff = 2x, times x
end

function Yp = ylin(P, zT, pf, de, rib)
% DG4 extended end plate, outer bolt row only, effective width bf + 25 (AISC 358 6.6).
% rib = 0: 4E outer terms; rib = 1: 4ES outer terms (stiffener on the web line), de = edge distance
bm = P.bm;
bp = min(P.ep.w, bm.b + 25);
h0 = zT + (bm.h - bm.tf/2);
if rib
    g = 2*P.an.vT;  s = 0.5*sqrt(bp*g);
    Yp = bp/2*h0*(1/s + 1/(2*pf)) + 2/g*h0*(de + pf);
else
    Yp = bp/2*(h0/pf - 1/2);
end
end

function r = ifelse(a, b, c)
if a, r = b; else, r = c; end
end

function Q = brk(P, zT, vT, hef)
% concrete breakout of the 2 top anchors, three edges (top, two sides), 17.6.2
cT = P.col.top - zT;  cS = P.col.b/2 - vT;
Q.hefp = min(hef, max(max(cT, cS)/1.5, 2*vT/3));
Q.ANc  = (cT + 1.5*Q.hefp)*(2*cS + 2*vT);
Q.ANco = 9*Q.hefp^2;
Q.ped  = 0.7 + 0.3*min(cT, cS)/(1.5*Q.hefp);
Q.Nb   = 10*sqrt(P.fc)*Q.hefp^1.5;
Q.phiN = 0.70*Q.ANc/Q.ANco*Q.ped*Q.Nb;
end

function l = ldh19(P, db, psr, pso)
% ACI 318-19 25.4.3.1(a), SI (Appendix E): psi_c = 0.01 f'c + 0.6
psc = min(0.01*P.fc + 0.6, 1.0);
l = max([P.fy*psr*pso*psc/(23*sqrt(P.fc))*db^1.5, 8*db, 150]);
end

function C = cone(P, H, an, vb, uh, zb, T)
% Beam bars at v = vb, level zb, hook outside at uh, against the anchor row an = [z |v|]
% (mirrored to +-v). Apex at the start of the anchor bend, 1 along the anchor : 1.5 across (V2).
for i = 1:numel(vb)
    bn = -inf;  bt = -inf;  rn = inf;
    za = an(1);  zt = za + P.tol.za*sign(za - zb(i));
    for va = an(2)*[-1 1]
        r  = hypot(vb(i) - va, zb(i) - za);
        rt = hypot(vb(i) - va, zb(i) - P.tol.zb - zt);
        if H.uc - r/1.5 > bn, bn = H.uc - r/1.5;  rn = r; end
        bt = max(bt, H.uc - P.tol.ua - rt/1.5);
    end
    C.uc_nom(i) = bn;  C.uc_tol(i) = bt;  C.r(i) = rn;
end
C.vb = vb;  C.zb = zb;  C.uh = uh;
C.ins_nom = C.uc_nom - uh;
C.ins_tol = C.uc_tol - uh - P.tol.ub;
Ab = pi*P.cb.db^2/4;
[s, o] = sort(C.ins_tol, 'descend');
n = numel(s);
dc = max(T./(0.75*P.fy*Ab*(1:n)), H.ldh12./max(s(1:n), eps));
k = find(dc <= min(dc) + 1e-9, 1, 'last');
C.k = k;  C.used = sort(o(1:k));
C.inside = s(k);
C.inside_nom = min(C.ins_nom(C.used));
C.rmax = max(C.r(C.used));
% for tension + shear (17.8): the steel ratio with as many bars as are still developed inside
% the body (the count above balances steel and length; here only the force ratio matters)
dcs = T./(0.75*P.fy*Ab*(1:n));  okl = H.ldh12./max(s(1:n), eps) <= 1;
C.kTi = k;  if any(okl), C.kTi = find(okl, 1, 'last'); end
C.nTi = dcs(C.kTi);
end

function Mn = ltb(P, B, Lb)
% AISC 360-16 F2.2 with Cb = 1.0 (cantilever, F1)
bm = P.bm;
if Lb <= B.Lp
    Mn = B.Mp;
elseif Lb <= B.Lr
    Mn = min(B.Mp, B.Mp - (B.Mp - 0.7*P.Fy*bm.Sx)*(Lb - B.Lp)/(B.Lr - B.Lp));
else
    ho = bm.h - bm.tf;  x = Lb/B.rts;
    Mn = min(B.Mp, pi^2*P.E/x^2*sqrt(1 + 0.078*bm.J/(bm.Sx*ho)*x^2)*bm.Sx);
end
end

function B = bothooks(P, zS)
% Bottom bars of the beams in line (corner bars P.cb.vbh hooked, P.cb.vbot in the joint), hooked up near the cantilever face,
% against everything else at the same v (section along the cantilever) and in plan at the level of
% the shear anchors. The crossing beam has its bottom bars at the same v positions.
cb = P.cb;  d = cb.db;  r = 3.5*d;  xR = 700;  hb = P.col.b/2;  an = P.an;  vb = cb.vbot;  vh = cb.vbh;
ut = cb.uh + d/2;  ut0 = cb.uh0 + d/2;  up = ut + d;    % top-bar tails, tail of the extra bars
ub = cb.ubh + d/2;                                       % bottom-bar tails
uc = hb - vb;                                            % crossing bottom bars, from the face
dmin = @(A, Bq) min(min(sqrt((A(:,1) - Bq(:,1)').^2 + (A(:,2) - Bq(:,2)').^2)));
c = {};
Qb = hkline(xR, ub, cb.zbl, 1, d);  Qbl = hkline(xR, ub, cb.zbc, 1, d);
Qt = hkline(xR, ut, max(cb.zt), -1, d);  Qt2 = hkline(xR, ut, min(cb.zt), -1, d);
Qp = hkline(xR, up, cb.zp, -1, d);  Qt0 = hkline(xR, ut0, max(cb.zt), -1, d);
c(end+1,:) = {'Bottom hooks - bend of the 2 extra top bars (-80)', dmin(Qb, Qp) - d, sprintf('tail top at %g; corner bars (v = %g)', cb.zbl + r + 12*d, max(cb.v))};
c(end+1,:) = {'Bottom hooks - top bars of the beam in line (bend and tail)', min([dmin(Qb, Qt), dmin(Qb, Qt2), dmin(Qb, Qt0)]) - d, ''};
B.crossU = dmin(Qb, [uc' cb.zbc*ones(numel(uc), 1)]) - d;
B.crossL = dmin(Qbl, [uc' cb.zbl*ones(numel(uc), 1)]) - d;
c(end+1,:) = {sprintf('Bottom hooks on the upper layer (%g) - crossing bottom bars below (u = %s)', cb.zbl, sprintf('%g ', uc)), B.crossU, 'E, C1, D3; D4 grid D. 0 = resting on them'};
c(end+1,:) = {sprintf('D4: grid-4 bottom hooks on the lower layer (%g) - grid-D bottom bars above', cb.zbc), B.crossL, 'no bar of grid D crosses the bends'};
c(end+1,:) = {sprintf('Bottom-hook tails - crossing top bars at u = %g', min(uc)), min(dmin(Qb, [min(uc) cb.zt(1)]), dmin(Qb, [min(uc) cb.zt(2)])) - d, ''};
% A2 end: washer (u = uS..uS+twsh, radius wsh/2) and nut (radius to the corners), tails at v = 47
vn = min(abs(vh));  u0 = an.uS;  u1 = an.uS + an.twsh;  u2 = u1 + an.tnut;
cw = max(0, ub - d/2 - u1);  cn = max(0, ub - d/2 - u2);
dw_ = hypot(cw, max(0, (vn - d/2) - (an.vS + an.wsh/2)));  dn_ = hypot(cn, max(0, (vn - d/2) - (an.vS + an.nut/sqrt(3))));
if ub - d/2 <= u2 && vn - d/2 <= an.vS + an.nut/sqrt(3), dn_ = -1; end
c(end+1,:) = {sprintf('End nut of A2 - bottom-hook tail at v = %g', vn), min(dw_, dn_), sprintf('nut at u = %g..%g, tail at u = %g', u1, u2, ub)};
% plan at z of A2, D4 (two beams end there): every vertical tail and column bar
gc = P.col.cover + P.col.dtie + P.col.db/2;  xc = hb - gc;
x = xc*[-1 0 1 -1 1 -1 0 1];  y = xc*[-1 -1 -1 0 0 1 1 1];  dd = P.col.db*ones(1, 8);  lab = repmat({'column bar'}, 1, 8);
nb = numel(vh);
pts = {hb - [ut ut0 ut], cb.v, 'grid-4 top tail';  hb - ub*ones(1, nb), vh, 'grid-4 bottom tail'; ...
       cb.v, -hb + [ut ut0 ut], 'grid-D top tail';  cb.v([1 3]), -hb + up*[1 1], 'grid-D extra tail';  vh, -hb + ub*ones(1, nb), 'grid-D bottom tail'; ...
       P.rod.p*[-1 1 -1 1], P.rod.p*[-1 -1 1 1], 'rod'};
for k = 1:size(pts, 1)
    x = [x pts{k,1}];  y = [y pts{k,2}];  dd = [dd d*ones(1, numel(pts{k,1}))];  lab = [lab repmat(pts(k,3), 1, numel(pts{k,1}))];
end
best = inf;  bi = '';
for i = 1:numel(x), for j = i+1:numel(x)
    cl = hypot(x(i) - x(j), y(i) - y(j)) - (dd(i) + dd(j))/2;
    if strcmp(lab{i}, lab{j}) || abs(cl) < 0.5, continue; end      % own group, or in contact by design
    if cl < best, best = cl;  bi = sprintf('%s - %s', lab{i}, lab{j}); end
end, end
c(end+1,:) = {'D4 plan at A2: closest two vertical bars (other than tails in contact)', best, bi};
c(end+1,:) = {'D4: south A2 (x = 35) - grid-4 bottom tails', (hb - ub) - an.vS - an.db/2 - d/2, ''};
if P.ub.on
    U = P.ub;  du = U.db;
    c(end+1,:) = {'U-bar foot - bottom bars of the beam in line (E, C1)', min(abs(abs(vb) - U.v)) - d/2 - du/2, ''};
    uy = hb - U.v;
    c(end+1,:) = {'D4 (CX): U-bar foot (south leg) - grid-D bottom hooks', dmin(Qb, [uy U.zbot]) - (d + du)/2, 'negative: the U-bar does not fit at CX with these hooks'};
end
B.clr = c;  B.ub = ub;  B.ut = [ut ut0 up];  B.dev = P.col.b - cb.ubh;
end

function Q = hkline(xR, ut, z0, dir, d)
% axis of a beam bar from xR to a 90 degree hook whose tail axis is at ut, turned up (dir = 1) or
% down (-1): bend radius 3.5 d at the axis, tail 12 d; sampled every 1 mm or so
r = 3.5*d;  t = linspace(0, pi/2, 60)';
L1 = linspace(xR, ut + r, ceil((xR - ut - r)))';
A = [ut + r - r*sin(t), z0 + dir*(r - r*cos(t))];
L2 = linspace(z0 + dir*r, z0 + dir*(r + 12*d), 12*d)';
Q = [L1, z0*ones(size(L1)); A; ut*ones(size(L2)), L2];
end

function S = shear_top(P, R, V, H, nT, phiVsa)
% Top anchors (2 Ø16, back plate at h_ef = bp.u) in shear, per type: row 1 H only, row 2 H + V/4
% per anchor. Breakout to a side face (cases 1, 2), pryout of the group (2 N_cbg of the cone cut
% by the top), steel; then 17.8 with the largest tension ratio nT.
an = P.an;  sq = sqrt(P.fc);  hb = P.col.b/2;  da = an.db;  zT = [R.typ.zT];
S.hef = P.bp.u;  S.le = min(S.hef, 8*da);  S.ha = P.col.b;  S.ca1 = [hb - an.vT, hb + an.vT];
S.ctop = P.col.top - zT;
Vp = [0*V; V];                                      % V on the pair of top anchors / 2 per anchor below
for j = 1:4
    for i = 1:2
        c1 = S.ca1(i);  r = 1.5*c1;  ct = S.ctop(j);
        Vb = min(0.6*(S.le/da)^0.2*sqrt(da)*sq*c1^1.5, 3.7*sq*c1^1.5);
        Avc = (min(ct, r) + r)*min(S.ha, r);  Avco = 4.5*c1^2;
        ped = min(1, 0.7 + 0.3*min(ct, r)/r);  ph = max(1, sqrt(r/S.ha));
        S.Vb(i,j) = Vb;  S.Avc(i,j) = Avc;  S.Avco(i,j) = Avco;  S.pedV(i,j) = ped;
        S.phiVb(i,j) = 0.70*Avc/Avco*ped*ph*Vb;      % perpendicular to the side face
        S.phiVp(i,j) = 0.70*2*Avc/Avco*ph*Vb;        % parallel (V down), psi_ed,V = 1
    end
    S.phiVcp(j) = 2*R.brk(j).phiN;                  % 0.70 k_cp N_cbg, k_cp = 2
    for k = 1:2
        v4 = Vp(k,j)/4;
        b1 = hypot(H(j)/2/S.phiVb(1,j), v4/S.phiVp(1,j));
        b2 = hypot(H(j)/S.phiVb(2,j), 2*v4/S.phiVp(2,j));
        cp = hypot(H(j), 2*v4)/S.phiVcp(j);
        sa = hypot(H(j)/2, v4)/phiVsa;
        S.b1(k,j) = b1;  S.b2(k,j) = b2;  S.cp(k,j) = cp;  S.sa(k,j) = sa;
        s = max([b1 b2 cp sa]);  S.s(k,j) = s;
        if s <= 0.2, S.int(k,j) = nT(j);
        elseif nT(j) <= 0.2, S.int(k,j) = s;
        else, S.int(k,j) = (nT(j) + s)/1.2; end
    end
end
S.nT = nT;
end

function S = shear_conc(P, V, H)
% Concrete in shear for the 2 shear anchors (Ø16 with an end nut at u = hef), ACI 318-19, SI,
% cracked, psi_c,V = 1 (no edge reinforcement counted), lambda = 1, phi = 0.70 (Condition B).
an = P.an;  sq = sqrt(P.fc);  hb = P.col.b/2;  da = an.db;
S.hef = an.uS;  S.zS = -(P.bm.h - P.bm.tf) + an.pfS;  S.vS = an.vS;
S.ctop = P.col.top - S.zS;                          % up to the top of the pedestal
S.ha = P.col.b;                                     % member depth along the anchors
% pryout, 17.7.3: the tension cone of the group, kcp = 2 (hef >= 65)
caS = hb - an.vS;  h = S.hef;
S.ANc = (2*min(caS, 1.5*h) + 2*an.vS)*(min(S.ctop, 1.5*h) + 1.5*h);
S.ANco = 9*h^2;  S.pedN = min(1, 0.7 + 0.3*caS/(1.5*h));
S.Nb = 10*sq*h^1.5;
S.Ncbg = S.ANc/S.ANco*S.pedN*S.Nb;
S.phiVcp = 0.70*2*S.Ncbg;
S.Vg = hypot(V, H);
% breakout across, towards a side face: case 1 near anchor, case 2 far anchor (all of the shear)
S.le = min(S.hef, 8*da);
S.ca1 = [hb - an.vS, hb + an.vS];
for i = 1:2
    c1 = S.ca1(i);  r = 1.5*c1;
    Vb = min(0.6*(S.le/da)^0.2*sqrt(da)*sq*c1^1.5, 3.7*sq*c1^1.5);
    Avc = (min(S.ctop, r) + r)*min(S.ha, r);       % up to the top, down the column
    Avco = 4.5*c1^2;
    ped = min(1, 0.7 + 0.3*min(S.ctop, r)/r);
    ph = max(1, sqrt(r/S.ha));
    S.Vb(i) = Vb;  S.Avc(i) = Avc;  S.Avco(i) = Avco;  S.pedV(i) = ped;  S.ph(i) = ph;
    S.Vcb(i) = Avc/Avco*ped*1.0*ph*Vb;
    S.phiVb(i) = 0.70*S.Vcb(i);
    S.phiVp(i) = 0.70*2*Avc/Avco*1.0*ph*Vb;        % parallel to the edge, psi_ed,V = 1
end
% interaction of the two components (EN 1992-4 7.2.2.5, psi_alpha,V; ACI checks each alone)
S.ell1 = (H/2/S.phiVb(1)).^2 + (V/2/S.phiVp(1)).^2;
S.ell2 = (H/S.phiVb(2)).^2 + (V/S.phiVp(2)).^2;
S.perp = [max(H/2)/S.phiVb(1), max(H)/S.phiVb(2)];
S.par  = [max(V/2)/S.phiVp(1), max(V)/S.phiVp(2)];
end

function rows = addr(rows, g, n, ref, D, C, u, eq, flag)
if nargin < 9, flag = ''; end
rows(end+1,:) = {g, n, ref, D, C, u, eq, flag};
end
