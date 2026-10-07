function R = ca_calc(P, R)
% CA_CALC  Limit states of the double plate anchorage.
%   R = ca_calc(P, R), P from ca_inputs, R from ca_layout. Units: N, mm, MPa.
%   R.rows  one row per check: {group, limit state, reference, demand(1x3), capacity(1x3),
%           unit, equation for type E with numbers}; columns = types E, CX, CY.
%   Conservative assumptions (user, 2026-10-01): beam bars on the least favourable layer,
%   corner beams VCS, edge VCM pairs in contact (one bar per pair counted).

sq = sqrt(P.fc);  fc = P.fc;  bm = P.bm;  Ab = @(d) pi*d^2/4;
d = P.tr.d;  Ase = P.tr.Ase;  futa = P.tr.futa;
T  = [R.typ.T];  V = [R.typ.V];  zT = arrayfun(@(Y) Y.rowT(1), R.typ);  zS = arrayfun(@(Y) Y.rowS(1), R.typ);
Mu = [R.kase([R.typ.k]).Mu];
rows = {};

% ---- rods (ACI 318-19 chapter 17) ---------------------------------------------
phiNsa = 0.75*Ase*futa;                             % 17.6.1.2, Table 17.5.3(a) ductile
rows = addr(rows, 'Rods', 'Tension rod, steel', '17.6.1.2', T/2, phiNsa*[1 1 1], 'kN', ...
    sprintf('&phi;N<sub>sa</sub> = 0.75 A<sub>se</sub> f<sub>uta</sub> = 0.75 (%g)(%g) = %.1f kN; N<sub>ua</sub> = T/2 = %.1f/2', Ase, futa, phiNsa/1e3, T(1)/1e3));
% torsion at the corner (eccentric load, V2 assumption Tu = Vu b/2, edge half of it),
% taken by a horizontal couple between the tension and the shear rods
Tor = V*bm.b/2;  Tor(1) = Tor(1)/2;
H = Tor./(zT - zS);
VuS = hypot(V/2, H/2);
phiVsa = 0.65*0.6*Ase*futa;                         % 17.7.1.2(b), no grout pad (steel on steel)
rows = addr(rows, 'Rods', 'Shear rod, steel (gravity + torsion)', '17.7.1.2(b)', VuS, phiVsa*[1 1 1], 'kN', ...
    sprintf('&phi;V<sub>sa</sub> = 0.65 (0.6 A<sub>se</sub> f<sub>uta</sub>) = %.1f kN; V<sub>ua</sub> = &radic;[(V/2)&sup2; + (H/2)&sup2;], H = T<sub>u</sub>/(z<sub>T</sub> - z<sub>S</sub>) = %.2f kN', phiVsa/1e3, H(1)/1e3));
rows = addr(rows, 'Rods', 'Tension rod, shear from torsion (interaction 17.8)', '17.8.1', (H/2)/phiVsa, 0.2*[1 1 1], '-', ...
    sprintf('V<sub>ua</sub>/&phi;V<sub>sa</sub> = %.3f &le; 0.2: full tension strength allowed, no interaction', H(1)/2/phiVsa));
% pullout of the back plate, per rod (17.6.3.2.2a), psi_cP = 1 (cracked)
Abrg = (P.bp.h*P.bp.w - 2*Ab(P.tr.hole))/2;
phiNp = 0.70*8*Abrg*fc;
rows = addr(rows, 'Rods', 'Pullout of the back plate (per rod)', '17.6.3.2.2(a)', T/2, phiNp*[1 1 1], 'kN', ...
    sprintf('&phi;N<sub>pn</sub> = 0.70 (8 A<sub>brg</sub> f''<sub>c</sub>), A<sub>brg</sub> = (%gx%g - 2 holes)/2 = %.0f mm&sup2; &rarr; %.0f kN', P.bp.h, P.bp.w, Abrg, phiNp/1e3));
% side-face blowout to the pedestal top (17.6.4), group of 2
for j = 1:3
    ca1 = P.col.top - zT(j);  ca2 = P.col.b/2 - P.tr.vT;
    Nsb = 13*ca1*sqrt(Abrg)*sq;
    f2 = 1;  if ca2 < 3*ca1, f2 = (1 + ca2/ca1)/4; end
    Nsbg(j) = Nsb*f2*min(1 + 2*P.tr.vT/(6*ca1), 2);
    app(j) = R.typ(j).hef > 2.5*ca1;
end
rows = addr(rows, 'Rods', 'Side-face blowout to the pedestal top, group', '17.6.4.1, 17.6.4.2', T, 0.70*Nsbg, 'kN', ...
    sprintf('c<sub>a1</sub> = %g, h<sub>ef</sub> = %g &gt; 2.5 c<sub>a1</sub>; N<sub>sb</sub> = 13 c<sub>a1</sub> &radic;A<sub>brg</sub> &radic;f''<sub>c</sub>; group (1 + s/6c<sub>a1</sub>); &phi; = 0.70', P.col.top - zT(1), R.typ(1).hef));
% anchor reinforcement (17.5.2.1(a)): 3 beam top bars, phi 0.75
nb = 3;  phiNar = 0.75*nb*Ab(P.cb.db)*P.fy;
rows = addr(rows, 'Concrete', 'Anchor reinforcement: beam top bars', '17.5.2.1(a), 17.5.3', T, phiNar*[1 1 1], 'kN', ...
    sprintf('&phi;N = 0.75 n A<sub>s</sub> f<sub>y</sub> = 0.75 (%d)(%.0f)(%g) = %.1f kN (unreinforced breakout only %.1f kN)', nb, Ab(P.cb.db), P.fy, phiNar/1e3, R.brk.phiN/1e3));
k = strcmp(R.pre(:,2), 'Beam bars inside the breakout body vs ldh (mm, tolerances on)');
ins = cell2mat(R.pre(k,4))'/1e3;  ldh = R.pre{find(k,1),3}/1e3;
rows = addr(rows, 'Concrete', 'Anchor reinforcement: hook development inside the body', '25.4.3, 17.5.2.1(a)', ldh*[1 1 1], ins, 'mm', ...
    sprintf('l<sub>dh</sub>(&#216;12) = max(f<sub>y</sub> &psi;<sub>c</sub> d<sub>b</sub><sup>1.5</sup>/(23 &radic;f''<sub>c</sub>), 8 d<sub>b</sub>, 150) = %.0f; available %.0f with bars 25 short and 13 low', ldh, ins(1)));
k = strcmp(R.pre(:,2), 'Farthest beam bar from a rod vs 0.5 hef (mm, R17.5.2.1)');
rows = addr(rows, 'Concrete', 'Anchor reinforcement within 0.5 h<sub>ef</sub> of the rods', 'R17.5.2.1', cell2mat(R.pre(k,3))'/1e3, cell2mat(R.pre(k,4))'/1e3, 'mm', ...
    sprintf('farthest counted bar %.0f mm from a rod; 0.5 h<sub>ef</sub> = %.0f', R.pre{find(k,1),3}/1e3, R.pre{find(k,1),4}/1e3));
ld12 = max(P.fy*1.3/(2.1*sq)*P.cb.db, 300);         % top bar, psi_t = 1.3 (25.4.2.3)
rows = addr(rows, 'Concrete', 'Anchor reinforcement: development beyond the body', '25.4.2.3', ld12*[1 1 1], [1 1 1]*1000, 'mm', ...
    sprintf('l<sub>d</sub> = f<sub>y</sub> &psi;<sub>t</sub> d<sub>b</sub>/(2.1 &radic;f''<sub>c</sub>) = %.0f; the bars continue into the beam span (1000 shown only as a marker)', ld12));
% pryout of the shear rods (17.7.3), kcp = 2; edges: two sides, top farther than 1.5 hef or not
for j = 1:3
    hef = P.tr.uS;  ca_s = P.col.b/2 - P.tr.vS;  ct = P.col.top - zS(j);
    ANc = (2*min(ca_s, 1.5*hef) + 2*P.tr.vS)*(min(ct, 1.5*hef) + 1.5*hef);
    ped = 0.7 + 0.3*min(ca_s, ct)/(1.5*hef);  if min(ca_s, ct) >= 1.5*hef, ped = 1; end
    Ncbg(j) = ANc/(9*hef^2)*ped*10*sq*hef^1.5;
end
rows = addr(rows, 'Concrete', 'Pryout of the 2 shear rods', '17.7.3', V, 0.70*2*Ncbg, 'kN', ...
    sprintf('&phi;V<sub>cpg</sub> = 0.70 (2 N<sub>cbg</sub>), h<sub>ef</sub> = %g, k<sub>c</sub> = 10, cracked: N<sub>cbg</sub> = %.1f kN. No concrete edge in the direction of the shear (down)', P.tr.uS, Ncbg(1)/1e3));

% ---- steel: end plate, welds, beam (AISC 360-16, DG4/DG16, Manual part 9) ----------
tp = P.ep.t;  bp = P.ep.w;
pf = zT;                                            % rod axis to the face of the top flange
Yp = bp/2*([R.typ.lev]./pf - 1/2);                   % outer yield lines of the DG4 4E mechanism only
phiMpl = 0.9*P.Fy*tp^2*Yp;
rows = addr(rows, 'Steel', 'End plate yield (yield lines around the outer rods)', 'DG4 4E, outer terms', Mu, phiMpl, 'kN m', ...
    sprintf('Y<sub>p</sub> = b<sub>p</sub>/2 (h<sub>0</sub>/p<sub>f</sub> - 1/2) = %.0f (%.0f/%.0f - 0.5) = %.0f mm; &phi;M = 0.9 F<sub>y</sub> t<sub>p</sub>&sup2; Y<sub>p</sub>', bp/2, R.typ(1).lev, pf(1), Yp(1)));
m = pf - P.w.flange;
rows = addr(rows, 'Steel', 'End plate, lower bound: strip b<sub>p</sub> fixed at the weld toe', 'plastic strip', T.*m, 0.9*P.Fy*bp*tp^2/4*[1 1 1], 'kN m', ...
    sprintf('M = T (p<sub>f</sub> - w) = %.1f (%g) ; &phi;M = 0.9 F<sub>y</sub> b<sub>p</sub> t<sub>p</sub>&sup2;/4 = %.2f kN m', T(1)/1e3, m(1), 0.9*P.Fy*bp*tp^2/4/1e6));
bpr = pf - d/2;                                     % b' (Manual 9-21)
tmin = sqrt(4*(T/2).*bpr/(0.9*(bp/2)*P.Fu));
rows = addr(rows, 'Steel', 'End plate thickness for no prying at the demand', 'AISC Manual 9-20a', tmin, tp*[1 1 1], 'mm', ...
    sprintf('t<sub>min</sub> = &radic;[4 T<sub>rod</sub> b''/(&phi; p F<sub>u</sub>)] = &radic;[4 (%.1f kN)(%.1f)/(0.9 (%g)(%g))] = %.1f mm (1 + &delta;&rho;'' taken as 1)', T(1)/2e3, bpr(1), bp/2, P.Fu, tmin(1)));
% shop welds: flange (no directional factor), web
Ff = Mu/(bm.h - bm.tf);
Lf = 2*bm.b - bm.tw;
phiRf = 0.75*0.6*P.FEXX*0.707*P.w.flange*Lf;
rows = addr(rows, 'Steel', 'Shop fillet, tension flange to end plate', 'AISC J2.4', Ff, phiRf*[1 1 1], 'kN', ...
    sprintf('F<sub>f</sub> = M<sub>u</sub>/(h - t<sub>f</sub>); &phi;R = 0.75 (0.6 F<sub>EXX</sub>)(0.707 w) L = 0.75 (0.6)(%g)(0.707)(%g)(%.0f) = %.0f kN, no 1.5 factor', P.FEXX, P.w.flange, Lf, phiRf/1e3));
Lw = 2*(bm.h - 2*bm.tf);
phiRw = 0.75*0.6*P.FEXX*0.707*P.w.web*Lw;
rows = addr(rows, 'Steel', 'Shop fillets, web to end plate (shear)', 'AISC J2.4', V, phiRw*[1 1 1], 'kN', ...
    sprintf('&phi;R = 0.75 (0.6)(%g)(0.707)(%g)(2 x %.0f) = %.0f kN', P.FEXX, P.w.web, Lw/2, phiRw/1e3));
phiBr = 0.75*2.4*d*tp*P.Fu;
rows = addr(rows, 'Steel', 'Bearing of a shear rod on the end plate', 'AISC J3.10', VuS, phiBr*[1 1 1], 'kN', ...
    sprintf('&phi;R = 0.75 (2.4 d t F<sub>u</sub>) = %.0f kN (the rod pushes up, away from the near edge)', phiBr/1e3));
phiMp = 0.9*P.Fy*bm.Zx;  phiVn = 0.6*P.Fy*bm.h*bm.tw;
rows = addr(rows, 'Steel', 'Beam flexure at the face (LTB: see V2, same beam and loads)', 'AISC F2.1', Mu, phiMp*[1 1 1], 'kN m', ...
    sprintf('&phi;M<sub>p</sub> = 0.9 F<sub>y</sub> Z<sub>x</sub> = 0.9 (%g)(%.0f) = %.1f kN m', P.Fy, bm.Zx, phiMp/1e6));
rows = addr(rows, 'Steel', 'Beam shear', 'AISC G2.1', V, phiVn*[1 1 1], 'kN', ...
    sprintf('&phi;V<sub>n</sub> = 1.0 (0.6 F<sub>y</sub> d t<sub>w</sub>) = %.0f kN', phiVn/1e3));

% ---- plates on the concrete ----------------------------------------------------
% front plate: bottom flange compression spread 1:1 through end plate + front plate
sp = tp + P.fp.t;
for j = 1:3
    hb_ = bm.tf + sp + min(sp, (-bm.h) - R.typ(j).fp_bot);
    A1(j) = (bm.b + 2*sp)*hb_;
end
phiBn = 0.65*0.85*fc*A1;                            % ACI 22.8.3.2, sqrt(A2/A1) taken as 1
rows = addr(rows, 'Plates', 'Bearing of the front plate under the bottom flange', 'ACI 22.8.3.2', T, phiBn, 'kN', ...
    sprintf('C = T; A<sub>1</sub> = (b + 2&middot;%g)(t<sub>f</sub> + spread) = %.0f mm&sup2;; &phi;B = 0.65 (0.85 f''<sub>c</sub> A<sub>1</sub>), &radic;(A<sub>2</sub>/A<sub>1</sub>) = 1', sp, A1(1)));
% back plate: uniform bearing, supports at the rods, overhangs beyond
wq = T/P.bp.w;  a = P.bp.w/2 - P.tr.vT;
Mbp = wq*a^2/2;
phiMbp = 0.9*P.Fy*P.bp.h*P.bp.t^2/4;
rows = addr(rows, 'Plates', 'Back plate bending (overhang beyond the rods)', 'plastic, AISC F11', Mbp, phiMbp*[1 1 1], 'kN m', ...
    sprintf('w = T/b = %.0f N/mm; M = w a&sup2;/2, a = %g; &phi;M = 0.9 F<sub>y</sub> h t&sup2;/4 = %.3f kN m', wq(1), a, phiMbp/1e6));

% ---- joint, beam, pedestal --------------------------------------------------------
coef = [1.25 1.0 1.0];                              % SI values of Table 15.4.2.3 (V2)
phiVj = 0.75*coef*sq*P.col.b^2;
rows = addr(rows, 'Joint', 'Joint shear (pull T crosses the joint)', '15.4.2.3', T, phiVj, 'kN', ...
    sprintf('&phi;V<sub>n</sub> = 0.75 (%.2f) &radic;f''<sub>c</sub> A<sub>j</sub> = %.0f kN, A<sub>j</sub> = %g&sup2;', coef(1), phiVj(1)/1e3, P.col.b));
dcb = P.cb.h + P.cb.zt(1);  nbar = [5 3 3];
As = nbar*Ab(P.cb.db);
phiMcb = 0.9*As*P.fy.*(dcb - As*P.fy/(1.7*fc*P.cb.b));
Mfar = Mu + V*P.col.b;                              % cantilever moment carried to the far face
rows = addr(rows, 'Joint', 'Concrete beam behind: cantilever moment alone vs &phi;M<sub>n</sub>', '22.2', Mfar, phiMcb, 'kN m', ...
    sprintf('M = M<sub>u</sub> + V<sub>u</sub> (0.4 m) = %.1f kN m, all of it into the beam (none to the column); &phi;M<sub>n</sub> with all top bars (VCM 5, VCS 3)', Mfar(1)/1e6));
dp = P.col.b - (P.col.cover + P.col.dtie + P.col.db/2);
phiVp = 0.75*(0.17*sq*P.col.b*dp + 2*Ab(P.col.dtie)*420*dp/P.col.s);
rows = addr(rows, 'Joint', 'Pedestal shear if all of T went into the pedestal', '22.5', T, phiVp*[1 1 1], 'kN', ...
    sprintf('&phi;V<sub>n</sub> = 0.75 (0.17 &radic;f''<sub>c</sub> b d + A<sub>v</sub> f<sub>yt</sub> d/s) = %.0f kN', phiVp/1e3));

R.rows = rows;
R.H = H;  R.Tor = Tor;
R.room = [32 16 16]*1e6;                            % room left in the concrete beams (README, V2)
end

function rows = addr(rows, g, n, ref, D, C, u, eq)
rows(end+1,:) = {g, n, ref, D, C, u, eq};
end
