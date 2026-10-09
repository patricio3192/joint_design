function R = ca_calc(P)
% CA_CALC  Loads and limit states of the cantilever anchorage, revision 3 (variant).
%   R = ca_calc(P), P from ca_inputs. Units: N, mm, MPa (kN and m in the loads).
%   R.kase(k)  1 edge, 2 corner (trapezoid), 3 corner (envelope)
%   R.rows     limit state table, one row per check, demand and strength per case
%   R.clr      clearances of the layout (nominal), one row per pair of parts
%
%   One load path for the pull: flange -> embed plate (through its thickness)
%   -> 2 platinas -> side welds -> bars -> hooks. The bars do not touch the plate.

sq  = sqrt(P.fc);
bm  = P.bm;
ho  = bm.h - bm.tf;                 % lever arm between flange centroids
Ab  = @(d) pi*d^2/4;
kN = 1e-3;  kNm = 1e-6;
db = P.anc.db;

% ---- 1. loads -------------------------------------------------------------
R.Ev  = 2/3*P.I*P.eta*P.Z*P.Fa;                     % NEC-SE-DS 3.4.4, fraction of D
R.q   = [1.2*P.qD+1.6*P.qL, (1.2+R.Ev)*P.qD+P.qL, (0.9-R.Ev)*P.qD];   % kN/m2
R.gsw = [1.2, 1.2+R.Ev, 0.9-R.Ev];
R.combo = {'1.2D + 1.6L', '1.2D + Ev + L', '0.9D - Ev'};
L = P.L/1000;  a0 = P.a0/1000;  s = P.s_edge/1000;  s1 = P.s1/1000;  s2 = P.s2/1000 + a0;
nm = {'Edge', 'Corner (trapezoid)', 'Corner (envelope)'};
% levels: flange line, bars under a platina, bars over it. The platinas are
% centred on the top flange, so the bars sit e above or below the flange line.
zf = -bm.tf/2;
e  = (P.pla.t + db)/2;
zU = zf - e;  zO = zf + e;
zbar = [zf, zU, zU];                                % edge: rows over and under balance; corner: C1 (under) governs
zC = -(bm.h - bm.tf/2);                             % compression: bottom flange
R.zf = zf;  R.e = e;  R.zbar = zbar;  R.zC = zC;
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
    K.TO = K.Mu/(zO - zC);                          % corner type C2, bars over the platinas
    K.Ma = K.Mu + K.Vu*P.a0;                        % at the column axis
    K.fE = R.Ev*P.qD*S(k)/K.M(2);
    R.kase(k) = K;
end
R.ho = ho;

% ---- 2. anchor layout per case ---------------------------------------------
% rows [z |v|], each mirrored to +-v (one bar per platina and row)
R.anE  = [zO P.anc.vO; zU P.anc.vU];                % edge, type E
R.anC1 = [zU P.anc.vC(1); zU P.anc.vC(2)];          % corner, type C1: bars under
R.anC2 = [zO P.anc.vC(1); zO P.anc.vC(2)];          % corner, type C2: bars over
R.nb  = [4 4 4];
R.zanc = [zU zO];
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
% side welds: bar lying on the platina, flare-bevel groove filled flush, only
% the reinforcing fillet counts (AISC Table J2.2, note [a]: R < 10 mm)
W.side = fw*P.w.bar*2*P.anc.Lw;                     % per bar
W.bar125 = 1.25*P.fy*Ab(db);                        % bar overstrength, ACI 25.5.7.1 used as the target
W.bmBar = 0.75*0.6*P.fu_bar*P.w.bar*2*P.anc.Lw;     % bar surface along the welds, shear rupture
W.bmPla = 0.75*0.6*P.Fu*P.w.bar*2*P.anc.Lw;         % platina surface along the welds of one bar
% platina to plate: fillet on top and below, full width of each platina, no bar in the way
W.line = fw*P.w.pla*P.pla.w;                        % one fillet line of one platina
W.a    = P.pla.t;                                   % lever arm between the two lines (conservative: the plate thickness)
for k = 1:3
    Tp = R.kase(k).T/2;  Vp = R.kase(k).Vu/2;
    Mp = (k > 1)*Tp*e;                              % corner: bars on one face; edge: the rows balance
    W.Ntop(k) = Tp/2 + Mp/W.a;
    W.root(k) = hypot(W.Ntop(k), Vp/2);             % worst line, per platina
end
R.weld = W;

% ---- 5. embed plate and platinas (one load path) ----------------------------
% 5a. through the thickness of the plate: flange footprint against the platinas
G.e    = e;
G.bov  = 2*(min(bm.b/2, P.pla.v0 + P.pla.w) - P.pla.v0);   % flange width backed by the platinas
G.htt  = bm.tf + 2*P.w.flange;                      % flange plus the legs of its fillets
G.plTT = 0.9*P.Fy*G.htt*G.bov;                      % AISC J4.1(a), plate as the connecting element
% 5b. the flange part over the gap between the platinas: plate strip spanning the gap
G.Lgap = 2*P.pla.v0;
G.Fgap = [R.kase.Tf]*min(G.Lgap, bm.b)/bm.b;        % uniform flange stress
G.Mpg  = P.Fy*G.htt*P.pl.t^2/4;                     % strip of width htt, Z = b t^2/4 (F11.1: Z/S = 1.5 < 1.6)
G.phiFgap  = 0.9*8*G.Mpg/G.Lgap;                    % simply supported strip, uniform load (conservative)
G.phiFgapX = 0.9*16*G.Mpg/G.Lgap;                   % fixed ends at the platinas (information)
G.phiVgap  = 1.0*0.6*P.Fy*G.htt*P.pl.t;             % AISC J4.2(a), both ends
% 5c. plate bending from the offset of the bars (corner only): M = T e at the
% root of the platinas, falling linearly to zero at the compression flange
G.bstr = 2*P.pla.w;                                 % strip: the two platina roots, no spread
G.Mstr = [0, R.kase(2).T*e, R.kase(3).T*e];
G.phiMstr = 0.9*P.Fy*G.bstr*P.pl.t^2/4;
G.Vstr = [0, R.kase(2).T - R.kase(2).Tf, R.kase(3).T - R.kase(3).Tf];
% 5d. platina: tension, and tension + bending at its root (corner)
G.Pc = 0.9*P.Fy*P.pla.w*P.pla.t;                    % per platina, AISC J4.1(a) / D2(a)
G.Mc = 0.9*P.Fy*P.pla.w*P.pla.t^2/4;                % per platina, weak axis, F11.1
for k = 1:3
    Pr = R.kase(k).T/2;  Mr = (k > 1)*Pr*e;
    if Pr/G.Pc >= 0.2, G.H1(k) = Pr/G.Pc + 8/9*Mr/G.Mc; else, G.H1(k) = Pr/(2*G.Pc) + Mr/G.Mc; end
end
% 5e. strength order (nominal): the platina or the bars yield before any weld breaks
G.Py  = P.Fy*P.pla.w*P.pla.t;  G.Mpn = P.Fy*P.pla.w*P.pla.t^2/4;
G.Fmech = fzero(@(F) (F/G.Py)^2 + F*e/G.Mpn - 1, [0 G.Py]);   % corner: eccentric pull that makes the platina root plastic
G.Fbars = 2*W.bar125;                               % two bars on a platina, at 1.25 fy
Fc = min(G.Fbars, G.Fmech);                         % corner: the weaker of bars and platina root
G.Fhier = [G.Fbars/2, (Fc/2 + Fc*e/W.a)*[1 1]];     % force on the worst fillet line when that part yields
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
D.ldhf0 = P.fy*D.psic/(23*sq)*db^1.5;               % the formula alone, psi_r = 1
% the joint ties enclose the hooks only if the hooks end inside them (25.4.3.3);
% hooks behind the far tie legs are not enclosed: psi_r = 1.6
D.encl = P.anc.uh <= P.col.b - P.col.cover - P.col.dtie;
D.psir = 1.0 + 0.6*(~D.encl);
D.ldh = ldh19(db, D.psir, 1.0);
D.ldhf = D.psir*D.ldhf0;
D.ldh_nohoop = ldh19(db, 1.6, 1.0);
D.ldh14 = max([0.24*P.fy*0.7/sq*db, 8*db, 150]);
D.ldh12 = ldh19(P.cb.db, 1.0, 1.0);
D.ld12  = max(P.fy/(2.1*sq)*P.cb.db, 300);
D.ldcol = max(P.fy/(2.1*sq)*P.col.db, 300);
D.ldhcol = ldh19(P.col.db, 1.0, 1.25);
D.colav = P.col.top - P.col.cover - P.col.cj;
D.uend  = P.pl.t + P.pla.L;                         % end of the platina = end of the welds
D.av_nom = P.anc.uh - D.uend;                       % from the end of the welds to the outside of the hook
D.av     = D.av_nom - P.tol.ua;                     % with the shop tolerance
D.tail = 12*db;  D.rb = 3.5*db;
D.zend = R.zanc - D.rb - D.tail;
D.uap  = P.anc.uh - db/2 - D.rb;                    % start of the bend
% ties confining the anchor hooks: layers within 15 db below the highest row (25.4.3.3(b)(1))
ztopr = [zO zU zO];
for k = 1:3
    D.nlay(k) = sum(P.hoop.z < ztopr(k) & P.hoop.z >= ztopr(k) - 15*db);
end
D.nlay(2) = min(D.nlay(2:3));  D.nlay(3) = D.nlay(2);   % corner: the C2 bars over the platinas govern
D.Ath_anc = D.nlay*2*Ab(P.hoop.db);
D.Ath = numel(P.hoop.z)*2*Ab(P.hoop.db);
nVCM = numel(P.cb.v) + numel(P.cb.vm);
D.AhsAll = R.As + [nVCM, numel(P.cb.v), numel(P.cb.v)]*Ab(P.cb.db);
R.dev = D;

% ---- 8. breakout, for information (edge) ------------------------------------
Q.hef = D.uap;
Q.ca_side = P.col.b/2 - max([P.anc.vO P.anc.vU]);
Q.ca_top  = P.col.top - zO;
Q.hefp = max(max(Q.ca_side, Q.ca_top)/1.5, 2*min([P.anc.vO P.anc.vU])/3);
Q.ANc  = P.col.b*(min(Q.ca_top, 1.5*Q.hefp) + 1.5*Q.hefp);
Q.ANco = 9*Q.hefp^2;
Q.ped  = 0.7 + 0.3*min(Q.ca_side, Q.ca_top)/(1.5*Q.hefp);
Q.Nb   = 10*sq*Q.hefp^1.5;
Q.phiN = 0.70*min(Q.ANc/Q.ANco, 4)*Q.ped*Q.Nb;
R.brk = Q;

% ---- 8b. anchor reinforcement: beam top bars crossing the breakout body ------
% Apex of each anchor's cone taken at the start of its bend. A beam bar leaves
% the body of the group where u = max over anchors of (u_apex - r/1.5), r being
% its distance to that anchor axis; its length inside is measured from there to
% the outside of its own hook. The beam bars are taken on the lower layer (which
% beam is on top is not known). With tolerances: beam bars 25 mm shorter at the
% hook and 13 mm lower, anchor hooks 5 mm shorter, platinas 3 mm away.
% Only the bars needed for T are counted, the ones with the longest length inside.
% Levels, conservative: a VCM under a VCS has its top line at z1 - dz and its
% second bars at z1 - 2 dz; a VCS under a VCM passes under the stacked corners,
% at z1 - 2 dz. A VCM corner bar and the bar under it are in contact: a hooked
% bundle is outside ACI (R25.6.1.5), so only one bar of each pair is counted.
zV = P.cb.z1 - P.cb.dz;  zS = P.cb.z1 - 2*P.cb.dz;
vV = [P.cb.v P.cb.vm];  zVb = [zV*ones(size(P.cb.v)) (zV - P.cb.dz)*ones(size(P.cb.vm))];
uhV = [P.cb.uh*ones(size(P.cb.v)) P.cb.uh2*ones(size(P.cb.vm))];  uhV(vV == 0) = P.cb.uh0;
uhS = P.cb.uh*ones(size(P.cb.v));   uhS(P.cb.v == 0) = P.cb.uh0;
CN(1) = cone(P, D, R.anE,  vV, uhV, zVb, R.kase(1).T);
CN(4) = CN(1);                                      % both bars of each pair counted (information)
for v = P.cb.vm                                     % one bar per pair: drop the weaker of the two
    j = find(vV == v);  [m, i] = min(CN(1).ins_tol(j));
    CN(1).ins_tol(j(i)) = -inf;  CN(1).ins_nom(j(i)) = -inf;  CN(1).short(j(i)) = -inf;
end
CN(1) = pick(CN(1), P, D, R.kase(1).T);
CN(2) = cone(P, D, R.anC1, P.cb.v,  uhS, zS, R.kase(3).T);
CN(3) = cone(P, D, R.anC2, P.cb.v,  uhS, zS, R.kase(3).TO);
R.zV = zV;  R.zS = zS;
R.cone = CN;
R.cone_label = {'edge, type E (VCM, one bar of each stacked pair)', 'corner, type C1, bars under (VCS)', 'corner, type C2, bars over (VCS)', 'edge, VCM, both bars of each pair (information)'};
% corner columns of the table: the worse of C1 and C2, each with its own pull
for k = 2:3
    T1 = R.kase(k).T;  T2 = R.kase(k).TO;
    r1 = max(T1/(0.75*P.fy*CN(2).k*Ab(P.cb.db)), D.ldh12/CN(2).inside);
    r2 = max(T2/(0.75*P.fy*CN(3).k*Ab(P.cb.db)), D.ldh12/CN(3).inside);
    if r1 >= r2, X.gov(k) = 2; X.T(k) = T1; else, X.gov(k) = 3; X.T(k) = T2; end
end
X.gov(1) = 1;  X.T(1) = R.kase(1).T;
for k = 1:3
    c = CN(X.gov(k));
    X.n(k) = c.k;  X.As(k) = c.k*Ab(P.cb.db);  X.phiN(k) = 0.75*X.As(k)*P.fy;
    X.ins(k) = c.inside;  X.ins_nom(k) = c.inside_nom;  X.rmax(k) = c.rmax;
end
X.half_hef = 0.5*D.uap;                             % R17.5.2.1: effective within 0.5 hef of the anchor
d = P.cb.h + P.cb.z1;                               % top line on top (joint shear, information)
dV = P.cb.h + mean(zVb);  dS = P.cb.h + zS;         % beam negative moment, conservative levels
X.d = [dV dS dS];
X.nb = [nVCM, numel(P.cb.v), numel(P.cb.v)];
X.phiMn = 0.9*X.nb*Ab(P.cb.db)*P.fy.*(X.d - X.nb*Ab(P.cb.db)*P.fy/(1.7*P.fc*P.cb.b));
R.ar = X;

% ---- 10. joint shear (15.4.2) ------------------------------------------------
J.coef = [1.25 1.0 1.0];                            % SI values of Table 15.4.2.3: 15 psi -> 1.25, 12 psi -> 1.0
J.phiVn = 0.75*J.coef*sq*P.col.b^2;
Mb = sum(abs(P.frame.Mb))*1e6;                      % edge beams, other direction
J.Vu_other = Mb/(0.875*d) - P.frame.Vcol*1e3;
R.joint = J;

% ---- 11. strut and tie: angle and tension in the inner column bars ----------
M.u1 = P.anc.uh - db/2;   M.z1 = zU;
M.u2 = P.pl.t + 30;       M.z2 = zC;
M.th = atan((M.z1 - M.z2)/(M.u1 - M.u2));
M.phiTcol = 0.75*3*Ab(P.col.db)*P.fy;               % three bars on the inner face
R.stm = M;

% ---- 12. shear: the two upper platinas are the shear lug (17.11) --------------
H.Aef = 2*P.pla.w*min(2*P.pla.t, P.pla.L);           % 17.11.2.1.1(a): within 2 t of the plate
H.phiVbrg = 0.65*1.7*P.fc*H.Aef;                    % psi_brg = 1: no axial load on the attachment
H.hef = D.uap;  H.hsl = P.pla.L;  H.csl = e;        % 17.11.1.1.8
H.ca1 = P.col.b/2;
H.Vb  = 3.7*sq*H.ca1^1.5;
H.hz  = min(P.col.top + bm.tf/2, 1.5*H.ca1) + P.pla.t + min(1.5*H.ca1, -P.col.cj);
H.AVc = H.hz*min(P.pl.t + P.pla.L + 1.5*H.ca1, P.col.b) - P.pla.t*P.pla.L;
H.AVco = 4.5*H.ca1^2;
H.phiVcb = 0.65*2*H.AVc/H.AVco*1.2*H.Vb;
R.shear = H;

% ---- 13. bearing behind the compression flange --------------------------------
Y.fp = 0.65*0.85*P.fc*2;                            % sqrt(A2/A1) = 2, see the report
Y.c  = sqrt(2*(0.9*P.Fy*P.pl.t^2/4)/Y.fp);
Y.A1 = (bm.tf + 2*Y.c)*(bm.b + 2*Y.c);
Y.phiBn = Y.fp*Y.A1;
R.brg = Y;

% ---- 14. torsion ------------------------------------------------------------
O.Treal = R.q(2)*bm.b/4/1000*(s2*L - L^2/2)*1e6;
O.Tu = [R.kase.Vu]*bm.b/2;  O.Tu(1) = O.Tu(1)/2;
O.H  = O.Tu/ho;
R.tor = O;

% ---- 15. pedestal, 8 bars, P = 0 --------------------------------------------
Z.rho = 8*Ab(P.col.db)/P.col.b^2;
[Z.phiMn0, Z.c0]  = ped_flex(P, 0);
[Z.phiMn45, Z.c45] = ped_flex(P, pi/4);
Z.Mx = R.kase(1).Ma;  Z.My = P.frame.Mcol*1e6;      % edge: cantilever + frame, added
Z.thE = atan2(Z.My, Z.Mx);
Z.phiMnE = ped_flex(P, Z.thE);
Z.Avf  = 8*Ab(P.col.db);                            % all column bars cross the 35 degree plane
Z.phiVsf = min(0.75*1.4*Z.Avf*P.fy, 0.75*0.2*P.fc*P.col.b*(P.col.b - P.pl.t - P.pla.L)/cosd(35));
dp = P.col.b - (P.col.cover + P.col.dtie + P.col.db/2);
Z.phiVn = 0.75*(0.17*sq*P.col.b*dp + 2*Ab(P.col.dtie)*420*dp/P.col.s);
R.ped = Z;
for j = 1:2
    As = nVCM*Ab(P.cb.db);  dj = X.d(1);  if j == 2, As = numel(P.cb.v)*Ab(P.cb.db); dj = X.d(2); end
    CB(j).As = As;  CB(j).d = dj;
    CB(j).phiMn = 0.9*As*P.fy*(dj - As*P.fy/(1.7*P.fc*P.cb.b));
    Vc = 0.17*sq*P.cb.b*d;  Vmax = 0.66*sq*P.cb.b*d;
    CB(j).Vc = Vc;
    CB(j).phiVn = 0.75*(Vc + min(2*Ab(P.cb.dst)*P.cb.fyt*d./P.cb.s, Vmax));
end
R.cb = CB;

% ---- 16. clearances of the layout (nominal, mm) --------------------------------
rc = P.col.cover + P.col.dtie + P.col.db/2;         % column bar axis from a face
urod = P.col.b/2 - P.rod.p;                         % base-plate rods, near row
c = {};
c(end+1,:) = {'Platina, inner edge - mid-face column bar', P.pla.v0 - P.col.db/2, 'the bar may be nudged on site'};
c(end+1,:) = {'Platina, end - rod of the steel column', urod - P.rod.db/2 - D.uend, 'both are within |v| = 94..106'};
c(end+1,:) = {'Outer bar - rod of the steel column', P.rod.p - P.rod.db/2 - max([P.anc.vO P.anc.vU P.anc.vC]) - db/2, 'along the whole bar'};
c(end+1,:) = {'Corner: bars of X - bars of Y, where they cross', (zO - db/2) - (zU + db/2), 'the platina thickness'};
c(end+1,:) = {'Bar over the platina - closed tie on top', (P.hoop.ztop - P.hoop.db/2) - (zO + db/2), ''};
c(end+1,:) = {'Bar under the platina - beam top bars, upper layer', (zU - db/2) - (P.cb.z1 + P.cb.db/2), sprintf('%g with the beam bars %g mm high', (zU - db/2) - (P.cb.z1 + P.tol.zb + P.cb.db/2), P.tol.zb)};
c(end+1,:) = {'Lowest top bars (stacked VCM corner, or VCS under it) - tie layer below', (P.cb.z1 - 2*P.cb.dz - P.cb.db/2) - (max(P.hoop.z) + P.hoop.db/2), sprintf('top bars at z = %g; ties at z = %g', P.cb.z1 - 2*P.cb.dz, max(P.hoop.z))};
c(end+1,:) = {'Hook tail - mid-face column bar, far face', min([P.anc.vO P.anc.vU P.anc.vC]) - db/2 - P.col.db/2, ''};
c(end+1,:) = {'Hook tails over and under the platina (edge), clear', abs(P.anc.vU - P.anc.vO) - db, 'ACI 25.2.1: at least 25'};
c(end+1,:) = {'Hook tail - outer face of the far tie legs', P.anc.uh - P.tol.ua - db - (P.col.b - P.col.cover), sprintf('with the hook %g mm short; the tails go behind the ties', P.tol.ua)};
c(end+1,:) = {'Hook, outside - far face of the column', P.col.b - P.anc.uh, 'inside the beam in line (|v| <= 150): no cover needed'};
va = unique([P.anc.vO P.anc.vU P.anc.vC]);  g = inf;
for v = va, g = min(g, min(abs(P.cb.v - v)) - (db + P.cb.db)/2); end
c(end+1,:) = {'Hook tails - beam top bars, in plan', g, 'the tails come down between them'};
c(end+1,:) = {'Corner: end of the platinas of X - nearest bar of Y', (P.col.b/2 - D.uend) - max(P.anc.vC) - db/2, ''};
c(end+1,:) = {'Weld toe - inner edge of the platina', min([P.anc.vO P.anc.vU P.anc.vC]) - db/2 - P.w.bar - P.pla.v0, ''};
c(end+1,:) = {'Weld toe - outer edge of the platina', P.pla.v0 + P.pla.w - (max([P.anc.vO P.anc.vU P.anc.vC]) + db/2 + P.w.bar), ''};
c(end+1,:) = {'End of the welds - start of the bend', D.uap - D.uend, 'at least 2 db = 24 (AWS D1.4, as quoted by PCI)'};
c(end+1,:) = {'Bar start - toe of the platina fillet', P.anc.u0 - P.pl.t - P.w.pla, 'the fillet runs the full width'};
R.clr = c;

% ---- 17. limit state table --------------------------------------------------
T = [R.kase.T];  Tf = [R.kase.Tf];  V = [R.kase.Vu];  Ma = [R.kase.Ma];  o3 = [1 1 1];
r = {};
r(end+1,:) = {'Beam', 'Flexure, lateral-torsional buckling', 'AISC F2', [R.kase.Mu]*kNm, B.phiMn*kNm*o3, 'kN m', ''};
r(end+1,:) = {'Beam', 'Flexure, effective length 2.5 L (tip unbraced, load on top)', 'AISC F2', [R.kase.Mu]*kNm, B.phiMn25*kNm*o3, 'kN m', ''};
r(end+1,:) = {'Beam', 'Shear', 'AISC G2.1', V*kN, B.phiVn*kN*o3, 'kN', ''};
r(end+1,:) = {'Beam', 'Top flange in tension (flange force)', 'AISC J4.1(a)', Tf*kN, 0.9*P.Fy*bm.b*bm.tf*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Flange to embed plate (site)', 'AISC J2.4', Tf*kN, W.flange*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Web to embed plate (site)', 'AISC J2.4', V*kN, W.web*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Platina to plate, worst fillet line (T, V, T e)', 'AISC J2.4', W.root*kN, W.line*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Side welds of one bar', 'AISC J2.4, Table J2.2', T/4*kN, W.side*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Side welds stronger than the bar (1.25 fy Ab)', 'ACI 25.5.7.1 (as target)', W.bar125*kN*o3, W.side*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Platina fillet stronger than what it connects', 'AISC J2.4', G.Fhier*kN, W.line*kN*o3, 'kN', ''};
r(end+1,:) = {'Welds', 'Bar and platina surfaces along the side welds', 'AISC J4.2(b)', W.bar125*kN*o3, min(W.bmBar, W.bmPla)*kN*o3, 'kN', ''};
r(end+1,:) = {'Plates', 'Embed plate through its thickness (flange to platinas)', 'AISC J4.1(a)', Tf*kN, G.plTT*kN*o3, 'kN', ''};
r(end+1,:) = {'Plates', 'Embed plate over the gap, bending (simply supported)', 'AISC F11.1', G.Fgap*kN, G.phiFgap*kN*o3, 'kN', ''};
r(end+1,:) = {'Plates', 'Embed plate over the gap, shear', 'AISC J4.2(a)', G.Fgap/2*kN, G.phiVgap*kN*o3, 'kN', ''};
r(end+1,:) = {'Plates', 'Embed plate, bending from the bar offset', 'AISC F11.1', G.Mstr*kNm, G.phiMstr*kNm*o3, 'kN m', ''};
r(end+1,:) = {'Plates', 'Platina, tension yielding', 'AISC J4.1(a)', T/2*kN, G.Pc*kN*o3, 'kN', ''};
r(end+1,:) = {'Plates', 'Platina root, tension + bending', 'AISC H1.1, F11.1', G.H1, o3, '-', ''};
r(end+1,:) = {'Concrete', 'Bearing behind the compression flange', 'ACI 22.8.3.2, AISC DG1', Tf*kN, Y.phiBn*kN*o3, 'kN', ''};
r(end+1,:) = {'Anchors', 'Anchor bars, tension (yield)', 'ACI 17.5.3, 23.7.2', T*kN, N.phiNy*kN, 'kN', ''};
r(end+1,:) = {'Anchors', 'Hook development, from the end of the welds', 'ACI 25.4.3.1', D.ldh*o3, D.av*o3, 'mm', ''};
if D.encl
    r(end+1,:) = {'Anchors', 'Ties confining the anchor hooks', 'ACI 25.4.3.3(b)(1)', 0.4*R.As, D.Ath_anc, 'mm2', ''};
end
r(end+1,:) = {'Concrete', 'Breakout without reinforcement (not used)', 'ACI 17.6.2', T*kN, Q.phiN*kN*o3, 'kN', 'info'};
r(end+1,:) = {'Concrete', 'Beam top bars as anchor reinforcement', 'ACI 17.5.2.1(a)', X.T*kN, X.phiN*kN, 'kN', ''};
r(end+1,:) = {'Concrete', 'Beam bars inside the breakout body, with tolerances', 'ACI 17.5.2.1(a), 25.4.3.1', D.ldh12*o3, X.ins, 'mm', ''};
r(end+1,:) = {'Concrete', 'Same, nominal positions', 'ACI 17.5.2.1(a), 25.4.3.1', D.ldh12*o3, X.ins_nom, 'mm', 'info'};
r(end+1,:) = {'Concrete', 'Beam bars counted within 0.5 hef of an anchor', 'ACI R17.5.2.1', X.rmax, X.half_hef*o3, 'mm', ''};
r(end+1,:) = {'Concrete', 'Ties confining all the hooks of the joint', 'ACI 25.4.3.3', 0.4*D.AhsAll, D.Ath*o3, 'mm2', ''};
r(end+1,:) = {'Concrete', 'Joint shear', 'ACI 15.4.2', T*kN, J.phiVn*kN, 'kN', ''};
r(end+1,:) = {'Shear', 'Platinas as shear lug, bearing', 'ACI 17.11.2.1', V*kN, H.phiVbrg*kN*o3, 'kN', ''};
r(end+1,:) = {'Shear', 'Shear lug breakout parallel to the side faces', 'ACI 17.11.3.2', V*kN, H.phiVcb*kN*o3, 'kN', ''};
r(end+1,:) = {'Shear', 'Shear lug: hef / hsl >= 2.5', 'ACI 17.11.1.1.8(a)', 2.5*o3, H.hef/H.hsl*o3, '-', ''};
r(end+1,:) = {'Shear', 'Plane at 35 deg from the lug to the far face', 'ACI 22.9', [V(1) 2*V(2) 2*V(3)]*kN, Z.phiVsf*kN*o3, 'kN', ''};
r(end+1,:) = {'Shear', 'Bars, tension + all of V (with the torsion couple)', 'ACI 17.8.3, 17.11.1.1.3', T./N.phiNsa + hypot(V, O.H)./N.phiVsa, 1.2*o3, '-', ''};
r(end+1,:) = {'Torsion', 'Couple at the bottom flange: friction 0.4 C', 'AISC DG1', O.H*kN, 0.75*0.4*T*kN, 'kN', ''};
r(end+1,:) = {'Frame', 'Concrete beam, negative moment (path 1)', 'ACI 22.3', Ma*kNm, X.phiMn*kNm, 'kN m', 'frame'};
r(end+1,:) = {'Frame', 'Pedestal, bending (path 2)', 'ACI 22.4', [hypot(Z.Mx, Z.My) sqrt(2)*Ma(2) sqrt(2)*Ma(3)]*kNm, [Z.phiMnE Z.phiMn45 Z.phiMn45]*kNm, 'kN m', 'frame'};
r(end+1,:) = {'Frame', 'Pedestal, inner bars (path 2)', 'ACI 23.7.2', T*tan(M.th)*kN, M.phiTcol*kN*o3, 'kN', 'frame'};
R.rows = r;
end

% ---------------------------------------------------------------------------
function C = cone(P, D, an, vb, uh, zb, T)
% Beam bars at |v| = vb, level zb, hook outside at uh, against the anchor rows
% an = [z |v|] (mirrored to +-v). Nominal and with the placing tolerances.
db = P.anc.db;
if isscalar(zb), zb = zb*ones(size(vb)); end
C.vb = vb;  C.zb = zb;  C.uh = uh;
for i = 1:numel(vb)
    bn = -inf;  bt = -inf;  rn = inf;
    for j = 1:size(an,1)
        za = an(j,1);  zt = za + P.tol.za*sign(za - zb(i));
        for va = an(j,2)*[-1 1]
            r  = hypot(vb(i) - va, zb(i) - za);
            rt = hypot(vb(i) - va, zb(i) - P.tol.zb - zt);
            if D.uap - r/1.5 > bn, bn = D.uap - r/1.5;  rn = r; end
            bt = max(bt, D.uap - P.tol.ua - rt/1.5);
        end
    end
    C.uc_nom(i) = bn;  C.uc_tol(i) = bt;  C.r(i) = rn;
end
C.ins_nom = C.uc_nom - uh;
C.ins_tol = C.uc_tol - uh - P.tol.ub;
C = pick(C, P, D, T);
C.short = C.ins_tol + P.tol.ub - D.ldh12;           % how much each hook may fall short, the other tolerances still applied
end

function C = pick(C, P, D, T)
% How many beam bars to count: the ones with the longest length inside are
% taken first; k is chosen so that the larger of the two ratios (strength,
% length inside) is the smallest (on a tie, more bars).
Ab = pi*P.cb.db^2/4;
[s, o] = sort(C.ins_tol, 'descend');
n = sum(isfinite(s));
dc = max(T./(0.75*P.fy*Ab*(1:n)), D.ldh12./max(s(1:n), eps));
k = find(dc <= min(dc) + 1e-9, 1, 'last');
C.k = k;  C.used = sort(o(1:k));
C.inside = s(k);
C.inside_nom = min(C.ins_nom(C.used));
C.rmax = max(C.r(C.used));
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
