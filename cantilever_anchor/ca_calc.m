function R = ca_calc(P)
% CA_CALC  Loads and limit states of the cantilever anchorage (revision 2).
%   R = ca_calc(P), P from ca_inputs. Units: N, mm, MPa (kN and m in the loads).
%   R.kase(k)  1 edge, 2 corner (trapezoid), 3 corner (envelope)
%   R.rows     limit state table, one row per check, demand and strength per case

sq  = sqrt(P.fc);
bm  = P.bm;
ho  = bm.h - bm.tf;                 % lever arm between flange centroids
Ab  = @(d) pi*d^2/4;
kN = 1e-3;  kNm = 1e-6;

% ---- 1. loads -------------------------------------------------------------
R.Ev  = 2/3*P.I*P.eta*P.Z*P.Fa;                     % NEC-SE-DS 3.4.4, fraction of D
R.q   = [1.2*P.qD+1.6*P.qL, (1.2+R.Ev)*P.qD+P.qL, (0.9-R.Ev)*P.qD];   % kN/m2
R.gsw = [1.2, 1.2+R.Ev, 0.9-R.Ev];
R.combo = {'1.2D + 1.6L', '1.2D + Ev + L', '0.9D - Ev'};
L = P.L/1000;  a0 = P.a0/1000;  s = P.s_edge/1000;  s1 = P.s1/1000;  s2 = P.s2/1000 + a0;
nm = {'Edge', 'Corner (trapezoid)', 'Corner (envelope)'};
% levels: bars under the platina, over it; centroid of the bars of each case
% (edge: both rows; corner: the C1 side governs, bars under the platina)
zU = -(bm.tf + P.lug.t)/2 - P.anc.db/2;  zO = -(bm.tf - P.lug.t)/2 + P.anc.db/2;
zbar = [(zU + zO)/2, zU, zU];
zC = -(bm.h - bm.tf/2);                             % compression: bottom flange
R.zbar = zbar;  R.zC = zC;
A  = [s*L, s2*L + L^2/2, s1*L];                     % tributary area beyond the face, m2
S  = [s*L^2/2, s2*L^2/2 + L^3/3, s1*L^2/2];         % its first moment about the face, m3
R.s2f = s2;
for k = 1:3
    K.name = nm{k};  K.A = A(k);  K.S = S(k);
    K.V = R.q*A(k) + R.gsw*bm.w*L;
    K.M = R.q*S(k) + R.gsw*bm.w*L^2/2;
    [dummy, K.jg] = max(K.M(1:2));
    K.Vu = K.V(K.jg)*1e3;  K.Mu = K.M(K.jg)*1e6;
    K.Tf = K.Mu/ho;                                 % flange force
    K.T  = K.Mu/(zbar(k) - zC);                     % pull in the anchor bars (their centroid)
    K.Ma = K.Mu + K.Vu*P.a0;                        % at the column axis
    K.fE = R.Ev*P.qD*S(k)/K.M(2);
    R.kase(k) = K;
end
R.ho = ho;

% ---- 2. anchor layout per case ---------------------------------------------
na  = numel(P.anc.v);  db = P.anc.db;
R.nb  = [2*na, na, na];                             % edge: bars under and over the lug
R.uhmin = [P.anc.uhA, P.anc.uh, P.anc.uh];          % shortest hook of each case
R.zanc = [-(bm.tf+P.lug.t)/2 - db/2, -(bm.tf-P.lug.t)/2 + db/2];   % bar axis under / over the lug
R.As  = R.nb*Ab(db);

% ---- 3. steel beam (AISC 360-16 F2, G2) ------------------------------------
B.Cw  = bm.Iy*ho^2/4;
B.Mp  = P.Fy*bm.Zx;
B.Lp  = 1.76*bm.ry*sqrt(P.E/P.Fy);
B.rts = sqrt(sqrt(bm.Iy*B.Cw)/bm.Sx);
jc    = bm.J/(bm.Sx*ho);
B.Lr  = 1.95*B.rts*P.E/(0.7*P.Fy)*sqrt(jc + sqrt(jc^2 + 6.76*(0.7*P.Fy/P.E)^2));
B.Mn  = ltb(P, B, P.L);   B.phiMn = 0.9*B.Mn;
B.phiMn25 = 0.9*ltb(P, B, 2.5*P.L);                 % cantilever, unbraced tip, load on the top flange
B.phiVn = 1.0*0.6*P.Fy*bm.h*bm.tw;
B.dDL = ((P.qD+P.qL)*s + bm.w)*P.L^4/(8*P.E*bm.Ix);
B.dlim = 2*P.L/360;
R.beam = B;

% ---- 4. welds (AISC 360-16 J2.4) -------------------------------------------
fw = 0.75*0.60*P.FEXX*0.707;                        % N/mm2 of leg x length
W.fw = fw;
W.Lf = bm.b + (bm.b - bm.tw - 2*bm.r);
W.flange = fw*P.w.flange*W.Lf;                      % no directional increase is used anywhere
W.Lw  = 2*(bm.h - 2*bm.tf - 2*bm.r);
W.web = fw*P.w.web*W.Lw;
% plate to platina and bar ends: one continuous bead; along the platina it is
% lost only where a bar sits against the plate (one bar diameter per bar)
W.gap = P.anc.db;
W.Lface = [P.lug.w, P.lug.w - numel(P.anc.v)*W.gap];   % face without bars, face with bars
W.Llug = [2*W.Lface(2), W.Lface(1) + W.Lface(2), W.Lface(1) + W.Lface(2)];
W.side = fw*P.w.bar*2*P.anc.Lw;                     % per bar, two side fillets on the lug
W.Lend = 0.75*pi*db;                                % end fillet on the plate, 3/4 of the perimeter
W.endw = fw*P.w.end*W.Lend;                         % ring around the bar end: not a linear group
W.bar  = W.side + W.endw;                           % simple sum, information only (J2.4(c) needs one leg size)
W.bead = fw*P.w.lug*W.Llug;                    % platina-to-plate part of the bead (carries V)
W.ring = R.nb*W.endw;                              % bar-end part of the bead, all bars (carries T)
W.bar125 = 1.25*P.fy*Ab(db);
R.weld = W;

% ---- 5. lug and plate -------------------------------------------------------
G.lugY = 0.9*P.Fy*min(P.lug.w, bm.b + 2*P.pl.t)*P.lug.t;
G.plTT = 0.9*P.Fy*(bm.tf + 2*P.w.flange)*bm.b;
G.e    = abs(zU - (-bm.tf/2));                     % offset flange line to bar axis
G.Mpl  = [R.kase(1).Tf/2, R.kase(2).Tf, R.kase(3).Tf]*G.e;   % edge: two rows, +-e, half each
G.phiMpl = 0.9*P.Fy*P.pl.w*P.pl.t^2/4;
% path B: the platina carries T at the flange line and hands it to the bars at
% their axis; the offset e is taken by the platina + bars welded together
Ap = P.lug.w*P.lug.t;  Ab2 = numel(P.anc.v)*Ab(db);  yb = G.e;          % bars e below the platina axis
yp = (Ab2*yb)/(Ap + Ab2);                            % plastic neutral axis measured from the platina axis ...
if Ab2 < Ap                                          % ... it lies inside the platina when the bars are smaller
    zpna = (Ap - Ab2)/(2*P.lug.w) - P.lug.t/2;        % from the platina axis, towards the bars (+)
    Zc = P.lug.w*((P.lug.t/2 + zpna)^2 + (P.lug.t/2 - zpna)^2)/2 + Ab2*(yb - zpna);
else
    Zc = Ap*yb;
end
G.phiMpB = 0.9*P.Fy*Zc;
G.MB = [0, R.kase(2).T, R.kase(3).T]*G.e;            % edge: the two rows balance
R.plate = G;

% ---- 6. bars --------------------------------------------------------------
N.phiNy  = 0.75*R.As*P.fy;                          % 17.5.3 / 23.7.2, phi = 0.75
futa = min([P.fu_bar, 1.9*P.fy, 860]);
N.phiNsa = 0.75*R.As*futa;
N.phiVsa = 0.65*0.6*R.As*futa;
R.anc = N;

% ---- 7. development (ACI 318-19 25.4.3 and 318-14 25.4.3) --------------------
D.psic = min(0.01*P.fc + 0.6, 1.0);                % SI form, ACI 318-19 Appendix E (f'c/15000 + 0.6 in psi)
ldh19 = @(d, pr, po) max([P.fy*pr*po*D.psic/(23*sq)*d^1.5, 8*d, 150]);
D.ldh = ldh19(db, 1.0, 1.0);
D.ldh_nohoop = ldh19(db, 1.6, 1.0);
D.ldh14 = max([0.24*P.fy*0.7/sq*db, 8*db, 150]);
D.ldh12 = ldh19(P.cb.db, 1.0, 1.0);
D.ld12  = max(P.fy/(2.1*sq)*P.cb.db, 300);
D.ldcol = max(P.fy/(2.1*sq)*P.col.db, 300);
D.ldhcol = ldh19(P.col.db, 1.0, 1.25);
D.colav = P.col.top - P.col.cover - P.col.cj;
D.av_plate = R.uhmin - P.pl.t;                      % embedment from the back of the plate
D.av_lug   = R.uhmin - P.pl.t - P.lug.L;            % from the end of the lug
D.lap      = R.uhmin - P.Lb.uh;                     % overlap with the front hooks of the beam bars
D.Ath = numel(P.hoop.z)*2*Ab(P.hoop.db);
D.tail = 12*db;  D.rb = 3.5*db;
D.zend = R.zanc - D.rb - D.tail;
R.dev = D;

% ---- 8. breakout, for information (edge, lower bars) ------------------------
Q.hef = D.av_plate(1);
Q.ca_side = P.col.b/2 - max(P.anc.v);
Q.ca_top  = P.col.top - R.zanc(1);
Q.hefp = max(max(Q.ca_side, Q.ca_top)/1.5, max(diff(P.anc.v))/3);
Q.ANc  = P.col.b*(min(Q.ca_top, 1.5*Q.hefp) + 1.5*Q.hefp);
Q.ANco = 9*Q.hefp^2;
Q.ped  = 0.7 + 0.3*min(Q.ca_side, Q.ca_top)/(1.5*Q.hefp);
Q.Nb   = 10*sq*Q.hefp^1.5;
Q.phiN = 0.70*min(Q.ANc/Q.ANco, 4)*Q.ped*Q.Nb;
R.brk = Q;

% ---- 8b. beam bars crossing the breakout body (conservative) -------------------
% Apex of each anchor's cone taken at the start of its bend (earlier than the
% bearing at the hook, so the body is smaller). A beam bar leaves the body of
% the group where u = max over anchors of (u_apex - r/1.5), r being its
% distance to that anchor axis. Its length inside the body is measured from
% that point to the outside of its own hook.
cases = {{[R.zanc(1) P.anc.uhA; R.zanc(2) P.anc.uh], P.cb.ve, P.cb.zt(1)}, ...
         {[R.zanc(1) P.anc.uh], P.cb.v, P.cb.zt(2)}, ...
         {[R.zanc(2) P.anc.uh], P.cb.v, P.cb.zt(2)}};
for k = 1:3
    an = cases{k}{1};  vb = cases{k}{2};  zb = cases{k}{3};
    uc = zeros(size(vb));
    for i = 1:numel(vb)
        best = -inf;
        for j = 1:size(an,1)
            uap = an(j,2) - db/2 - D.rb;
            for va = P.anc.v
                r = hypot(vb(i) - va, zb - an(j,1));
                best = max(best, uap - r/1.5);
            end
        end
        uc(i) = best;
    end
    CN(k).vb = vb;  CN(k).zb = zb;  CN(k).uc = uc;
    CN(k).inside = min(uc) - P.Lb.uh;               % hooked length inside the body
    CN(k).rmax = max(abs(vb)) + max(abs(P.anc.v));
end
R.cone = CN;
% as built: pairs in contact at the corners (edge)
an = cases{1}{1};  vb = P.cb.vb;  zb = cases{1}{3};  uc = zeros(size(vb));
for i = 1:numel(vb)
    best = -inf;
    for j = 1:size(an,1)
        for va = P.anc.v
            best = max(best, an(j,2) - db/2 - D.rb - hypot(vb(i) - va, zb - an(j,1))/1.5);
        end
    end
    uc(i) = best;
end
R.cone_built.vb = vb;  R.cone_built.uc = uc;  R.cone_built.inside = min(uc) - P.Lb.uh;
R.corner_label = {'edge (VCM, 5 top)', 'corner X (VCS, 3 top)', 'corner Y (VCS, 3 top)'};
D.AhsAll = [R.As(1) + numel(P.cb.ve)*Ab(P.cb.db), R.As(2) + numel(P.cb.v)*Ab(P.cb.db), R.As(3) + numel(P.cb.v)*Ab(P.cb.db)];
R.dev = D;

% ---- 9. anchor reinforcement: top bars of the concrete beam in line --------------
X.n   = [numel(P.cb.ve), numel(P.cb.v), numel(P.cb.v)];   % corner: VCS, the weaker beam
X.As  = X.n*Ab(P.cb.db);
X.phiN = 0.75*X.As*P.fy;
d = P.cb.h + P.cb.zt(1);
X.phiMn = 0.9*X.As*P.fy.*(d - X.As*P.fy/(1.7*P.fc*P.cb.b));
R.ar = X;

% ---- 10. joint shear (15.4.2) ------------------------------------------------
J.coef = [1.25 1.0 1.0];                            % SI values of Table 15.4.2.3: 15 psi -> 1.25, 12 psi -> 1.0
J.phiVn = 0.75*J.coef*sq*P.col.b^2;
Mb = sum(abs(P.frame.Mb))*1e6;                      % edge beams, other direction
J.Vu_other = Mb/(0.875*d) - P.frame.Vcol*1e3;
R.joint = J;

% ---- 11. strut and tie: angle and tension in the inner column bars ----------
M.u1 = P.anc.uh - db/2;   M.z1 = R.zanc(1);
M.u2 = P.pl.t + 30;       M.z2 = -(bm.h - bm.tf/2);
M.th = atan((M.z1 - M.z2)/(M.u1 - M.u2));
M.phiTcol = 0.75*3*Ab(P.col.db)*P.fy;               % three bars on the inner face
R.stm = M;

% ---- 12. shear ------------------------------------------------------------
H.Aef = P.lug.w*min(2*P.lug.t, P.lug.L);
H.phiVbrg = 0.65*1.7*P.fc*H.Aef;
H.phiMlug = 0.9*P.Fy*P.lug.w*P.lug.t^2/4;
H.ca1 = P.col.b/2;
H.Vb  = 3.7*sq*H.ca1^1.5;
H.hz  = min(P.col.top + bm.tf/2, 1.5*H.ca1) + P.lug.t + min(1.5*H.ca1, -P.col.cj);
H.AVc = H.hz*min(P.pl.t + P.lug.L + 1.5*H.ca1, P.col.b) - P.lug.t*P.lug.L;
H.AVco = 4.5*H.ca1^2;
H.phiVcb = 0.65*2*H.AVc/H.AVco*1.2*H.Vb;
R.shear = H;

% ---- 13. bearing behind the compression flange --------------------------------
Y.fp = 0.65*0.85*P.fc*2;
Y.c  = sqrt(2*(0.9*P.Fy*P.pl.t^2/4)/Y.fp);
Y.A1 = (bm.tf + 2*Y.c)*(bm.b + 2*Y.c);
Y.phiBn = Y.fp*Y.A1;
R.brg = Y;

% ---- 14. torsion ------------------------------------------------------------
O.Treal = R.q(2)*bm.b/4/1000*(s2*L - L^2/2)*1e6;
O.Tu = [R.kase.Vu]*bm.b/2;  O.Tu(1) = O.Tu(1)/2;
O.H  = O.Tu/ho;
O.phiH = 0.75*0.85*P.fc*P.lug.t*P.lug.L;
R.tor = O;

% ---- 15. pedestal, 8 bars, P = 0 --------------------------------------------
Z.rho = 8*Ab(P.col.db)/P.col.b^2;
[Z.phiMn0, Z.c0]  = ped_flex(P, 0);
[Z.phiMn45, Z.c45] = ped_flex(P, pi/4);
Z.Mx = R.kase(1).Ma;  Z.My = P.frame.Mcol*1e6;      % edge: cantilever + frame, added
Z.thE = atan2(Z.My, Z.Mx);
Z.phiMnE = ped_flex(P, Z.thE);
R.ped = Z;

% ---- 15b. shear through the pedestal on a 35 degree plane, and member strengths ----
Z.Avf  = 8*Ab(P.col.db);                            % all column bars cross the plane
Z.phiVsf = min(0.75*1.4*Z.Avf*P.fy, 0.75*0.2*P.fc*P.col.b*(P.col.b - P.pl.t - P.lug.L)/cosd(35));
dp = P.col.b - (P.col.cover + P.col.dtie + P.col.db/2);
Z.phiVn = 0.75*(0.17*sq*P.col.b*dp + 2*Ab(P.col.dtie)*420*dp/P.col.s);
R.ped = Z;
for j = 1:2
    As = numel(P.cb.ve)*Ab(P.cb.db);  if j == 2, As = numel(P.cb.v)*Ab(P.cb.db); end
    CB(j).As = As;
    CB(j).phiMn = 0.9*As*P.fy*(d - As*P.fy/(1.7*P.fc*P.cb.b));
    Vc = 0.17*sq*P.cb.b*d;  Vmax = 0.66*sq*P.cb.b*d;
    CB(j).Vc = Vc;
    CB(j).phiVn = 0.75*(Vc + min(2*Ab(P.cb.dst)*P.cb.fyt*d./P.cb.s, Vmax));
end
R.cb = CB;

% ---- 16. limit state table --------------------------------------------------
T = [R.kase.T];  Tf = [R.kase.Tf];  V = [R.kase.Vu];  Ma = [R.kase.Ma];  o3 = [1 1 1];
r = {};
r(end+1,:) = {'Beam', 'Flexure, lateral-torsional buckling', 'AISC F2', [R.kase.Mu]*kNm, B.phiMn*kNm*o3, 'kN m', ''};
r(end+1,:) = {'Beam', 'Flexure, effective length 2.5 L (tip unbraced, load on top)', 'AISC F2', [R.kase.Mu]*kNm, B.phiMn25*kNm*o3, 'kN m', ''};
r(end+1,:) = {'Beam', 'Shear', 'AISC G2.1', V*kN, B.phiVn*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Flange to embed plate (site)', 'AISC J2.4', Tf*kN, W.flange*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Web to embed plate (site)', 'AISC J2.4', V*kN, W.web*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Path A: bead around the bar ends carries T alone', 'AISC J2.4', T*kN, W.ring*kN, 'kN', ''};
r(end+1,:) = {'Welds', 'Bead platina-plate: carries V (shear key)', 'AISC J2.4', V*kN, W.bead*kN, 'kN', ''};
r(end+1,:) = {'Welds', 'Path B: side welds carry T alone', 'AISC J2.4', T./R.nb*kN, W.side*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Path B: bead platina-plate carries T and V', 'AISC J2.4', hypot(T, V)*kN, W.bead*kN, 'kN', ''};
r(end+1,:) = {'Plates', 'Path B: platina + bars, bending from the offset', 'AISC F11', G.MB*kNm, G.phiMpB*kNm*o3, 'kN m', ''};
r(end+1,:) = {'Welds', 'One bar: end + side welds added (information)', 'AISC J2.4', T./R.nb*kN, W.bar*kN*o3, 'kN', 'info'};
r(end+1,:) = {'Welds', 'Bar surface under the end bead, shear rupture', 'AISC J4.2(b)', T./R.nb*kN, 0.75*0.6*P.fu_bar*P.w.end*W.Lend*kN*o3, 'kN', ''};
r(end+1,:) = {'Beam', 'Top flange in tension (flange force)', 'AISC J4.1(a)', Tf*kN, 0.9*P.Fy*bm.b*bm.tf*kN*o3, 'kN', ''};
r(end+1,:) = {'Plates', 'Platina, tension yielding', 'AISC J4.1(a)', T*kN, G.lugY*kN*o3, 'kN', ''};
r(end+1,:) = {'Plates', 'Embed plate, through the thickness', 'AISC J4.1(a)', Tf*kN, G.plTT*kN*o3, 'kN', ''};
r(end+1,:) = {'Plates', 'Path A: embed plate, bending from the offset', 'AISC F11', G.Mpl*kNm, G.phiMpl*kNm*o3, 'kN m', ''};
r(end+1,:) = {'Anchors', 'Anchor bars, tension (yield)', 'ACI 17.5.3, 23.7.2', T*kN, N.phiNy*kN, 'kN', ''};
r(end+1,:) = {'Anchors', 'Hook development, from the plate', 'ACI 25.4.3.1', D.ldh*o3, D.av_plate, 'mm', ''};
r(end+1,:) = {'Anchors', 'Hook development, from the end of the lug', 'ACI 25.4.3.1', D.ldh*o3, D.av_lug, 'mm', ''};
r(end+1,:) = {'Concrete', 'Breakout without reinforcement (not used)', 'ACI 17.6.2', T*kN, Q.phiN*kN*o3, 'kN', 'info'};
r(end+1,:) = {'Concrete', 'Beam top bars as anchor reinforcement', 'ACI 17.5.2.1(a)', T*kN, X.phiN*kN, 'kN', ''};
r(end+1,:) = {'Concrete', 'Beam bars inside the breakout body, hooked', 'ACI 17.5.2.1(a), 25.4.3.1', D.ldh12*o3, [CN(1).inside, min([CN(2:3).inside]), min([CN(2:3).inside])], 'mm', ''};
r(end+1,:) = {'Concrete', 'Hoops confining all the hooks of the joint', 'ACI 25.4.3.3', 0.4*D.AhsAll, D.Ath*o3, 'mm2', ''};
r(end+1,:) = {'Concrete', 'Joint shear', 'ACI 15.4.2', T*kN, J.phiVn*kN, 'kN', ''};
r(end+1,:) = {'Concrete', 'Bearing behind the compression flange', 'ACI 22.8.3.2', T*kN, Y.phiBn*kN*o3, 'kN', ''};
r(end+1,:) = {'Shear', 'Lug bearing (shear key)', 'ACI 17.11.2.1', V*kN, H.phiVbrg*kN*o3, 'kN', ''};
r(end+1,:) = {'Shear', 'Lug breakout parallel to the side faces', 'ACI 17.11.3.2', V*kN, H.phiVcb*kN*o3, 'kN', ''};
r(end+1,:) = {'Shear', 'Plane at 35 deg from the lug to the far face', 'ACI 22.9', [V(1) 2*V(2) 2*V(3)]*kN, Z.phiVsf*kN*o3, 'kN', ''};
r(end+1,:) = {'Shear', 'Bars, tension + shear (with the torsion couple)', 'ACI 17.8.3', T./N.phiNsa + hypot(V, O.H)./N.phiVsa, 1.2*o3, '-', ''};
r(end+1,:) = {'Torsion', 'Couple at the bottom flange: friction 0.4 C', 'AISC DG1', O.H*kN, 0.75*0.4*T*kN, 'kN', ''};
r(end+1,:) = {'Frame', 'Concrete beam, negative moment (path 1)', 'ACI 22.3', Ma*kNm, X.phiMn*kNm, 'kN m', 'frame'};
r(end+1,:) = {'Frame', 'Pedestal, bending (path 2)', 'ACI 22.4', [hypot(Z.Mx, Z.My) sqrt(2)*Ma(2) sqrt(2)*Ma(3)]*kNm, [Z.phiMnE Z.phiMn45 Z.phiMn45]*kNm, 'kN m', 'frame'};
r(end+1,:) = {'Frame', 'Pedestal, inner bars (path 2)', 'ACI 23.7.2', T*tan(M.th)*kN, M.phiTcol*kN*o3, 'kN', 'frame'};
R.rows = r;
end

% ---------------------------------------------------------------------------
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

% ---------------------------------------------------------------------------
function [phiMn, c] = ped_flex(P, th)
% Design moment of the pedestal at zero axial load, 8 bars. The compression
% side is in the direction (cos th, sin th).
h  = P.col.b/2;
e  = h - P.col.cover - P.col.dtie - P.col.db/2;
cor  = h*[-1 -1; 1 -1; 1 1; -1 1];
bars = e*[-1 -1; 1 -1; 1 1; -1 1; 0 -1; 1 0; 0 1; -1 0];
Ab = pi*P.col.db^2/4;
n  = [cos(th); sin(th)];
dmax = max(cor*n);
dbar = dmax - bars*n;
lo = 1;  hi = 2*P.col.b;
for it = 1:60
    c = (lo + hi)/2;
    [F, Mn] = sect(c);
    if F > 0, hi = c; else lo = c; end
end
et = 0.003*(max(dbar) - c)/c;
phi = min(0.9, max(0.65, 0.65 + 0.25*(et - P.fy/P.Es)/0.003));
phiMn = phi*Mn;
    function [F, M] = sect(c)
        a = 0.85*c;
        [Ac, cen] = clip(cor, n, dmax - a);
        es = 0.003*(c - dbar)/c;
        fs = max(min(P.Es*es, P.fy), -P.fy);
        fs(dbar < a) = fs(dbar < a) - 0.85*P.fc;
        F = 0.85*P.fc*Ac + sum(fs)*Ab;
        M = 0.85*P.fc*Ac*(cen*n) + sum(fs.*(bars*n))*Ab;
    end
end

function [A, cen] = clip(p, n, d0)
q = zeros(0,2);  m = size(p,1);
for i = 1:m
    a = p(i,:);  b = p(mod(i,m)+1,:);
    da = a*n - d0;  db = b*n - d0;
    if da >= 0, q(end+1,:) = a; end
    if da*db < 0, q(end+1,:) = a + (b-a)*da/(da-db); end
end
x = q(:,1);  y = q(:,2);  x2 = x([2:end 1]);  y2 = y([2:end 1]);
w = x.*y2 - x2.*y;
A = sum(w)/2;
cen = [sum((x+x2).*w), sum((y+y2).*w)]/(6*A);
A = abs(A);
end
