function R = ca_layout(P)
% CA_LAYOUT  Layout, clearances and first sizing of the double plate concept.
%   R = ca_layout(P), P from ca_inputs. Units: N, mm, MPa (kN and m in the loads).
%   Scheme stage: geometry first. The strength numbers here are a first sizing
%   only; the full limit-state table comes after the layout is accepted.
%   R.kase(k)  1 edge, 2 corner (trapezoid), 3 corner (envelope)
%   R.typ(j)   1 type E (edge), 2 type CX (corner, rods low), 3 type CY (corner, rods high)
%   R.clr      clearances of the layout (nominal), one row per pair of parts
%   R.pre      first sizing, one row per check

sq  = sqrt(P.fc);
bm  = P.bm;
ho  = bm.h - bm.tf;
Ab  = @(d) pi*d^2/4;
d   = P.tr.d;

% ---- 1. loads (same as ../cantilever_anchor_V2/ca_calc.m) ---------------------
R.Ev  = 2/3*P.I*P.eta*P.Z*P.Fa;                     % NEC-SE-DS 3.4.4, fraction of D
R.q   = [1.2*P.qD+1.6*P.qL, (1.2+R.Ev)*P.qD+P.qL, (0.9-R.Ev)*P.qD];   % kN/m2
R.gsw = [1.2, 1.2+R.Ev, 0.9-R.Ev];
R.combo = {'1.2D + 1.6L', '1.2D + Ev + L', '0.9D - Ev'};
L = P.L/1000;  a0 = P.a0/1000;  s = P.s_edge/1000;  s1 = P.s1/1000;  s2 = P.s2/1000 + a0;
nm = {'Edge', 'Corner (trapezoid)', 'Corner (envelope)'};
A  = [s*L, s2*L + L^2/2, s1*L];
S  = [s*L^2/2, s2*L^2/2 + L^3/3, s1*L^2/2];
for k = 1:3
    K.name = nm{k};
    K.V = R.q*A(k) + R.gsw*bm.w*L;
    K.M = R.q*S(k) + R.gsw*bm.w*L^2/2;
    [dummy, K.jg] = max(K.M(1:2));
    K.Vu = K.V(K.jg)*1e3;  K.Mu = K.M(K.jg)*1e6;
    K.fE = R.Ev*P.qD*S(k)/K.M(2);                   % share of Ev in the moment (17.10.5.1)
    R.kase(k) = K;
end

% ---- 2. rod levels and assembly types ------------------------------------------
z.T  = P.tr.pf;                                     % over the top flange (E, CX)
z.H  = P.tr.zH;                                     % over the top flange, high (CY)
z.S  = -(bm.h - bm.tf) + P.tr.pf;                   % over the bottom flange
z.S2 = P.tr.zS2;                                    % type CY, clear of the CX shear rods
z.C  = -(bm.h - bm.tf/2);                           % compression: bottom flange centroid
R.z = z;
uw = 4;  ut = 2*25.4/11;                            % washer, 2 threads past the nut (11 threads per inch)
uT  = P.bp.u + P.bp.t + uw + P.tr.tnut + ut;        % far end of the rods through the back plate
uS  = P.tr.uS + uw + P.tr.tnut + ut;                % far end of the shear rods
nm = {'E (edge)', 'CX (corner, rods low)', 'CY (corner, rods high)'};
zt = [z.T z.T z.H];
zs = [z.S z.S z.S2];
kk = [1 3 3];                                       % governing load case of each type
for j = 1:3
    Y.name = nm{j};
    Y.rowT = [zt(j) P.tr.vT uT];                    % tension rods [z |v| far end]
    Y.rowS = [zs(j) P.tr.vS uS];                    % shear rods
    Y.head = 'back plate';
    Y.ep_top = zt(j) + P.ep.over;
    Y.ep_bot = -bm.h - P.ep.under;
    Y.fp_top = Y.ep_top + 5;  Y.fp_bot = P.fp.zb;
    Y.hef = P.bp.u;
    Y.lev = zt(j) - z.C;                            % lever arm, tension rods to compression
    Y.k = kk(j);
    Y.T = R.kase(kk(j)).Mu/Y.lev;                   % pull on the 2 tension rods
    Y.V = R.kase(kk(j)).Vu;
    Y.L = ceil([uT uS] + P.tr.out);                 % rod lengths
    R.typ(j) = Y;
end

% ---- 3. clearances (nominal, mm) ------------------------------------------------
% Beam bars: whichever layer is worse for each pair (decision 2026-10-01: assume the
% least favourable). VCM pairs taken as separated (closer to the shear rods).
rc = P.col.cover + P.col.dtie + P.col.db/2;         % column bar axis from a face
zc = P.col.top - P.col.cover - P.col.db/2;          % axis of the column top hooks
rn = P.tr.nut/sqrt(3);  rs = P.tr.nutS/sqrt(3);     % nut corners
cb = P.cb.db/2;  r = d/2;  rt = P.top.db/2;  rh = P.hoop.db/2;
uft = P.col.b - P.col.cover;                        % outer face of the far ties
c = {};
c(end+1,:) = {'Tension rods - mid-face column bars (front and far)', P.tr.vT - r - P.col.db/2, 'all types'};
c(end+1,:) = {'Tension rods - rods of the steel column', P.rod.p - P.rod.db/2 - P.tr.vT - r, 'all types'};
c(end+1,:) = {'Tension rods - the two mid-face hooks, side by side at v = +-8 (parallel)', P.tr.vT - r - P.col.db/2 - P.col.db, 'E: hooks along the beam; corner: along Y'};
c(end+1,:) = {'Corner: rods of X - column hooks bent along Y, where they cross', (zc - P.col.db/2) - (z.T + r), 'hold point: hooks over the rods of X'};
c(end+1,:) = {'Corner: rods of X - rods of Y, where they cross', (z.H - r) - (z.T + r), ''};
c(end+1,:) = {'Edge: rods - closed tie 10 at +50', (P.hoop.ztop - rh) - (z.T + r), 'placed after the rods'};
c(end+1,:) = {'Top ties 14 at +6 - rods of E, CX', (z.T - r) - (P.top.z(2) + rt), 'ties placed before the rods'};
c(end+1,:) = {'Top ties 14: clear between the two', (P.top.z(2) - rt) - (P.top.z(1) + rt), ''};
c(end+1,:) = {'Top tie 14 at -22 - beam top bars (upper layer)', (P.top.z(1) - rt) - (max(P.cb.zt) + cb), ''};
c(end+1,:) = {'Back plate - far ties (outer face)', P.bp.u - uft, 'the back plate is behind the ties'};
c(end+1,:) = {'Back plate - far column bars', P.bp.u - (P.col.b - rc + P.col.db/2), ''};
c(end+1,:) = {'Back plate, outer face - far face of the column', P.col.b - P.bp.u - P.bp.t, 'inside the concrete beam in line (|v| <= 75 < 150)'};
c(end+1,:) = {'Back plate of E, CX, bottom - beam top bars (upper layer)', (z.T - P.bp.h/2) - (max(P.cb.zt) + cb), ''};
c(end+1,:) = {'Back plate of CY, top - top of the pedestal', P.col.top - (z.H + P.bp.h/2), ''};
c(end+1,:) = {'Rods of CY, top - top of the pedestal', P.col.top - (z.H + r), ''};
c(end+1,:) = {'Shear rods - joint ties at -180 and -225', min((-180 - rh) - (z.S + r), (z.S - r) - (-225 + rh)), 'E, CX; ties as planned'};
c(end+1,:) = {'Shear rods CY - joint ties at -135 and -180', min((-135 - rh) - (z.S2 + r), (z.S2 - r) - (-180 + rh)), 'CY; ties as planned'};
c(end+1,:) = {'Shear rods - hook tails of the beam bars (v = 0 and 57)', min(P.tr.vS - r - cb, 57 - cb - P.tr.vS - r), 'VCM pairs separated; 28 or more if not'};
c(end+1,:) = {'Corner: shear rods of X - shear rods of Y, where they cross', (z.S2 - r) - (z.S + r), ''};
c(end+1,:) = {'Front plate, inner face - hooks of the beam bars', P.cb.uh - P.fp.t, ''};
c(end+1,:) = {'Front plate, inner face - ties of the pedestal', P.col.cover - P.fp.t, ''};
c(end+1,:) = {'Front plate of CY, top - top of the pedestal', P.col.top - R.typ(3).fp_top, ''};
c(end+1,:) = {'Heavy nut on the end plate - flange fillet', P.tr.pf - rn - P.w.flange, 'tension rods: pf = d + 1/2 in'};
c(end+1,:) = {'Shear-rod nut on the end plate - web fillet', P.tr.vS - rs - bm.tw/2 - P.w.web, 'regular hex nut; snug tight is enough'};
c(end+1,:) = {'Shear-rod nut on the end plate - bottom flange fillet', P.tr.pf - rs - P.w.flange, ''};
R.clr = c;

% ---- 4. first sizing (to be replaced by the full limit-state table) ---------------
fc = P.fc;
pre = {};
for j = 1:3
    Y = R.typ(j);
    Nua = Y.T/2;  Vua = Y.V/2;
    phiNsa = 0.75*P.tr.Ase*P.tr.futa;               % 17.6.1, Table 17.5.3(a), ductile
    phiVsa = 0.65*0.6*P.tr.Ase*P.tr.futa;           % 17.7.1.2(b), no grout pad (steel on steel)
    pre(end+1,:) = {Y.name, 'Rod steel in tension (17.6.1)', Nua, phiNsa};
    pre(end+1,:) = {Y.name, 'Shear rod steel in shear (17.7.1)', Vua, phiVsa};
    % side-face blowout to the pedestal top (17.6.4), hef > 2.5 ca1
    ca1 = P.col.top - Y.rowT(1);
    Abrg = (P.bp.h*P.bp.w - 2*Ab(P.tr.hole))/2;
    if Y.hef > 2.5*ca1
        Nsb = 13*ca1*sqrt(Abrg)*sq;
        ca2 = P.col.b/2 - Y.rowT(2);
        if ca2 < 3*ca1, Nsb = Nsb*(1 + ca2/ca1)/4; end
        Nsbg = Nsb*min(1 + 2*Y.rowT(2)/(6*ca1), 2);
        pre(end+1,:) = {Y.name, 'Side-face blowout, group, to the pedestal top (17.6.4)', Y.T, 0.70*Nsbg};
    end
    % anchor reinforcement: top bars of the beam behind, 17.5.2.1(a). Conservative:
    % corner beams = VCS (3 bars); edge VCM with its pairs in contact counts one bar per pair (3)
    nb = 3;
    pre(end+1,:) = {Y.name, sprintf('Anchor reinforcement, %d top bars of the beam (17.5.2.1)', nb), Y.T, 0.75*nb*Ab(P.cb.db)*P.fy};
    % those bars: on the lower layer and 13 mm lower still, 25 mm short at the hook;
    % apex at the back plate, slope 1 : 1.5 (as in V2)
    if j == 1, vbar = [P.cb.ve P.cb.vb]; else, vbar = P.cb.v; end
    rr = hypot(abs(vbar) - Y.rowT(2), abs(min(P.cb.zt) - Y.rowT(1)) + P.tol.zb);
    uhb = P.cb.uh*ones(size(vbar));  uhb(vbar == 0) = P.cb.uh0;
    ins = min(Y.hef - rr/1.5 - (uhb + P.tol.ub));
    ldh12 = max([P.fy*min(0.01*fc + 0.6, 1)/(23*sq)*P.cb.db^1.5, 8*P.cb.db, 150]);
    pre(end+1,:) = {Y.name, 'Beam bars inside the breakout body vs ldh (mm, tolerances on)', ldh12*1e3, ins*1e3};
    pre(end+1,:) = {Y.name, 'Farthest beam bar from a rod vs 0.5 hef (mm, R17.5.2.1)', max(rr)*1e3, 0.5*Y.hef*1e3};
    % end plate: lower bound, a strip of width bp fixed at the weld toe
    m = Y.rowT(1) - P.w.flange;
    pre(end+1,:) = {Y.name, 'End plate, cantilever strip fixed at the weld toe', Y.T*m, 0.9*P.Fy*P.ep.w*P.ep.t^2/4};
end
R.pre = pre;

% unreinforced breakout of type E, for information (17.6.2), three edges: top, two sides
Q.ca_top = P.col.top - z.T;  Q.ca_side = P.col.b/2 - P.tr.vT;
Q.hefp = max(max(Q.ca_top, Q.ca_side)/1.5, 2*P.tr.vT/3);
Q.ANc  = (Q.ca_top + 1.5*Q.hefp)*(2*Q.ca_side + 2*P.tr.vT);
Q.ANco = 9*Q.hefp^2;
Q.ped  = 0.7 + 0.3*min(Q.ca_top, Q.ca_side)/(1.5*Q.hefp);
Q.Nb   = 10*sq*Q.hefp^1.5;
Q.phiN = 0.70*Q.ANc/Q.ANco*Q.ped*Q.Nb;
R.brk = Q;
end
