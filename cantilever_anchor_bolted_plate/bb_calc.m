function B = bb_calc(P, R)
% BB_CALC  Border beam along the slab edge, between the tips of the IPE 240 cantilevers.
%   B = bb_calc(P, R), P from ca_inputs, R from ca_calc. Units: N, mm, MPa.
%   Simply supported (double pinned) between two cantilever tips. Every IPE (hot rolled) and
%   every rectangular tube of the IPAC 2023 catalog is checked, steel A36, and the lightest one
%   that passes everything is picked per family.
%   Strength: AISC 360-16 F2 (IPE, top flange braced by the deck), F7 (tubes), G2 / G4 shear.
%   Deflection: L/360 under L, L/240 under D + L, bare steel (designed non-composite).
%   Vibration: AISC DG11 2nd ed. Natural frequency of the edge strip (Dunkerley, eq. 3-4) with the
%   border beam composite with the slab above the deck (DG11 3.2: deck attached, Ec x 1.35) and the
%   cantilever tips as supports that move (IPE 240 bending + stretch of the A1 rods); targets:
%   fn >= 9 Hz (no resonance with walking, DG11 2.2.1) and at most 1 mm under 1 kN at midspan.
%   DG11's acceleration (eq. 2-10 above 9 Hz, eq. 4-1 below) is given for information.
cat = '../../../digitalized_catalog_profiles/ipac2023/';
E = P.Es;  Fy = 248;  Ev = R.Ev;
B.L    = [4780 4330];               % spans: south edge B-C and C-D (4780), east edge grid 4 - grid 3 (4330)
B.trib = 1270/2;                    % deck from the grid-4 beam to the slab edge (1270), simple span: half
B.wedge = 0.3;                      % railing on the slab edge (user 2026-10-03: no data, assume): steel tube railing
                                    % with posts, about 30 kg/m, N/mm. Posts anchored into the slab concrete, not to the beam
B.qvL  = 0.29e-3;                   % DG11 Table 3-1, residence: 6 psf
B.beta = 0.02;                      % damping: structure 1% + furniture / fit-out 1% (DG11 Table 4-2)
B.dlim = 1.0;                       % mm under 1 kN at midspan
B.fmin = 9;                         % Hz
% slab: 110 total on a 55 deck, ribs across the border beam: only the 55 above the ribs counts
B.tc = P.slab.t - P.slab.deck;  B.hd = P.slab.deck;
B.Ec = 4700*sqrt(P.fc);  B.n = E/(1.35*B.Ec);       % ACI 19.2.2.1; DG11 3.2 dynamic modulus
L = B.L(1);
% cantilever tip as a spring (per kN at the tip): IPE 240 from the column face, and the rotation
% at the face from the stretch of the 2 A1 rods (end plate to back plate) over the lever arm
Lc = P.L - 50;  bm = P.bm;  an = P.an;
lev = R.typ(1).zT - (-(bm.h - bm.tf/2));             % A1 to the middle of the bottom flange
Lrod = P.g + P.ep.t + P.dbl.t + P.bp.u;             % stretched length of the rods
krot = lev^2*2*E*an.Ase/Lrod;                        % N mm / rad
B.ctip = Lc^3/(3*E*bm.Ix) + Lc^2/krot;              % mm / N
B.ctip_parts = [Lc^3/(3*E*bm.Ix), Lc^2/krot]*1e3;   % mm / kN

S = {};
T = readtable_(fullfile(cat, 'ipac_ipe.csv'));
for i = 1:numel(T.name)
    s.fam = 'IPE';  s.name = T.name{i};  s.h = T.h_mm(i);  s.b = T.b_mm(i);  s.tw = T.tw_mm(i);  s.tf = T.tf_mm(i);
    s.A = T.A_cm2(i)*100;  s.m = T.P_kgm(i);  s.I = T.Ix_cm4(i)*1e4;  s.S = T.Sx_cm3(i)*1e3;  s.Z = T.Zx_cm3(i)*1e3;
    S{end+1} = s;
end
T = readtable_(fullfile(cat, 'ipac_rect_tubes.csv'));
for i = 1:numel(T.B_mm)
    s = struct();  s.fam = 'tube';  s.h = T.H_mm(i);  s.b = T.B_mm(i);  s.tw = T.e_mm(i);  s.tf = T.e_mm(i);
    s.name = sprintf('tubo %gx%gx%g', s.b, s.h, s.tw);
    s.A = T.A_cm2(i)*100;  s.m = T.P_kgm(i);  s.I = T.Ix_cm4(i)*1e4;  s.S = T.Wx_cm3(i)*1e3;
    s.Z = s.b*s.h^2/4 - (s.b - 2*s.tw)*(s.h - 2*s.tw)^2/4;
    if s.h >= 100, S{end+1} = s; end
end

for k = 1:numel(S)
    s = S{k};
    % loads (N/mm)
    wD = P.qD*1e-3*B.trib + s.m*9.81e-3 + B.wedge;  wL = P.qL*1e-3*B.trib;
    wu = max([1.4*wD, 1.2*wD + 1.6*wL, (1.2 + Ev)*wD + wL]);
    s.wD = wD;  s.wL = wL;  s.wu = wu;
    s.Mu = wu*L^2/8;  s.Vu = wu*L/2;
    % flexure
    if strcmp(s.fam, 'IPE')
        lf = s.b/2/s.tf;  lpf = 0.38*sqrt(E/Fy);  lrf = 1.0*sqrt(E/Fy);
        Mp = Fy*s.Z;
        if lf <= lpf, Mn = Mp; else, Mn = Mp - (Mp - 0.7*Fy*s.S)*(lf - lpf)/(lrf - lpf); end   % F3.2(a)
        Aw = s.h*s.tw;  htw = (s.h - 2*s.tf)/s.tw;
        if htw <= 2.24*sqrt(E/Fy), phv = 1.0; Cv = 1; else, phv = 0.9; Cv = min(1, 1.10*sqrt(5.34*E/Fy)/htw); end
        Vn = 0.6*Fy*Aw*Cv;  s.cls = ifelse(lf <= lpf, 'compact', 'noncompact flange');
    else
        t = s.tw;  bt = (s.b - 3*t)/t;  ht = (s.h - 3*t)/t;
        Mp = Fy*s.Z;  lp = 1.12*sqrt(E/Fy);  lr = 1.40*sqrt(E/Fy);
        if bt <= lp
            Mn = Mp;  s.cls = 'compact';
        elseif bt <= lr
            Mn = min(Mp, Mp - (Mp - Fy*s.S)*(3.57*bt*sqrt(Fy/E) - 4.0));  s.cls = 'noncompact flange';   % F7-2
        else
            be = min(s.b - 3*t, 1.92*t*sqrt(E/Fy)*(1 - 0.38/bt*sqrt(E/Fy)));   % F7-4, effective flange
            bo = s.b - 3*t;  Se = eff_S(s.b, s.h, t, bo - be);  Mn = Fy*Se;  s.cls = 'slender flange';
        end
        if ht > 5.70*sqrt(E/Fy), Mn = NaN; s.cls = 'slender web'; end
        Aw = 2*(s.h - 3*t)*t;  kv = 5;
        if ht <= 1.10*sqrt(kv*E/Fy), Cv = 1; else, Cv = 1.10*sqrt(kv*E/Fy)/ht; end
        phv = 0.9;  Vn = 0.6*Fy*Aw*Cv;                  % G4, Cv2 from G2.2
    end
    s.phiMn = 0.9*Mn;  s.phiVn = phv*Vn;
    s.dcM = s.Mu/s.phiMn;  s.dcV = s.Vu/s.phiVn;
    % deflections, bare steel
    d5 = @(w, I) 5*w*L^4/(384*E*I);
    s.dL = d5(wL, s.I);  s.dDL = d5(wD + wL, s.I);
    s.dcL = s.dL/(L/360);  s.dcDL = s.dDL/(L/240);
    % vibration: composite transformed I (DG11 3.2), edge member: half the spacing <= 0.2 L
    be = min(B.trib, 0.2*L);  Ac = be/B.n*B.tc;  yc = B.hd + B.tc/2;          % concrete above the top of steel
    ys = -s.h/2;  yb = (s.A*ys + Ac*yc)/(s.A + Ac);
    s.It = s.I + s.A*(ys - yb)^2 + be/B.n*B.tc^3/12 + Ac*(yc - yb)^2;
    wv = P.qD*1e-3*B.trib + s.m*9.81e-3 + B.wedge + B.qvL*B.trib;            % actual weight, N/mm
    s.dj = d5(wv, s.It);
    s.dg = B.ctip*wv*L;                              % a tip carries a whole span (half from each side)
    s.fj = 0.18*sqrt(9810/s.dj);  s.fn = 0.18*sqrt(9810/(s.dj + s.dg));
    s.fn_rigid = s.fj;
    s.fn2 = 0.18*sqrt(9810/(s.dj + s.dg*(B.ctip + B.ctip_parts(2)*1e-3)/B.ctip));   % connection twice as flexible
    s.d1k = 1000*L^3/(48*E*s.It) + 0.5*B.ctip*1000;  % midspan under 1 kN, tips each take 0.5 kN
    % DG11 acceleration (information): W = w B L, B = Cj (Ds/Dj)^0.25 L <= 2/3 floor width; free
    % edge Cj = 1; floor width = the strip (1270), or 3 bays if the slab is taken as continuous
    Ds = (B.tc + B.hd/2)^3/(12*B.n);  Dj = s.It/(2*B.trib);
    Bj = min((Ds/Dj)^0.25*L, 2/3*2*B.trib);
    s.W = wv/B.trib*Bj*L;  s.Bj = Bj;  Wlb = s.W/4.448;      % weight per unit area x panel
    if s.fn > 9
        h = 5 + (s.fn > 11) + (s.fn > 13.2);  fst = min(2.2, s.fn/h);
        s.ag = 154/Wlb*fst^1.43/s.fn^0.3*(1 - exp(-4*pi*h*B.beta))/(h*pi*B.beta);   % eq. 2-10
    else
        s.ag = 65*exp(-0.35*s.fn)/(B.beta*Wlb);                                       % eq. 4-1
    end
    % effect on the cantilever (anchorage): its tip carries the beam over a whole span
    s.dMu = (1.2 + Ev)*s.m*9.81e-3*L*P.L*1e-6;      % kN m, at the column face, lever P.L as in ca_calc
    s.pass = [[s.dcM s.dcV s.dcL s.dcDL] <= 1, s.fn >= B.fmin, s.d1k <= B.dlim];
    S{k} = s;
end
B.S = S;
% the cantilever with the border beam: the deck strip and the beam reach its tip as a point load
% (the deck spans from the grid-4 beam to the border beam). Edge (E): half a span each side.
% Corner tips (CY at D9, CX at E4): half the main span + the 1270 corner piece (overhang).
B.lev = P.L;                                        % lever used for the cantilever moment (ca_calc)
B.tipspan = [L, B.L(1)/2 + 150, B.L(2)/2 + 1270, B.L(1)/2 + 1270];  % beam length on each tip: E, C1, CX, CY
for k = 1:numel(B.S)
    s = B.S{k};
    Pu = ((1.2 + Ev)*s.wD + s.wL)*B.tipspan;        % N, 1.2D + Ev + L (governs the cantilever)
    s.Mcant = (Pu*B.lev + (1.2 + Ev)*P.bm.w*B.lev^2/2)*1e-6;   % kN m at the face, + IPE 240 weight
    % user 2026-10-03: the ETABS model already has the border beam and the deck spanning to it; only
    % the railing is new: design moment + its tip load
    s.Mrail = (1.2 + Ev)*B.wedge*B.tipspan*B.lev*1e-6;
    s.Mnew  = [R.typ.Mu]*1e-6 + s.Mrail;
    B.S{k} = s;
end

m = cellfun(@(s) s.m, S);  ok = cellfun(@(s) all(s.pass), S);  fam = cellfun(@(s) s.fam, S, 'UniformOutput', false);
okS = cellfun(@(s) all(s.pass(1:4)), S);
for f = {'IPE', 'tube'}
    i = find(strcmp(fam, f{1}) & ok);  [~, j] = min(m(i));  B.best.(f{1}) = S{i(j)};
    i = find(strcmp(fam, f{1}) & okS);  [~, j] = min(m(i));  B.strength.(f{1}) = S{i(j)};
end
end

function Se = eff_S(b, h, t, hole)
% section modulus of a box with an ineffective strip 'hole' wide in the compression flange (centred)
yc_parts = [];  A = [];  I0 = [];
A(1) = b*t;           yc_parts(1) = h - t/2;   I0(1) = b*t^3/12;        % top flange
A(2) = -hole*t;       yc_parts(2) = h - t/2;   I0(2) = -hole*t^3/12;
A(3) = b*t;           yc_parts(3) = t/2;       I0(3) = b*t^3/12;
A(4) = 2*t*(h - 2*t); yc_parts(4) = h/2;       I0(4) = 2*t*(h - 2*t)^3/12;
yb = sum(A.*yc_parts)/sum(A);  I = sum(I0 + A.*(yc_parts - yb).^2);
Se = I/max(h - yb, yb);
end

function T = readtable_(f)
% CSV with a header line into a struct of columns (text columns as cells)
fid = fopen(f, 'r');  hdr = strsplit(strtrim(fgetl(fid)), ',');  C = {};
while true
    l = fgetl(fid);  if ~ischar(l), break; end
    if isempty(strtrim(l)), continue; end
    C(end+1,:) = strsplit(strtrim(l), ',');
end
fclose(fid);
for j = 1:numel(hdr)
    v = str2double(C(:,j));
    if all(isnan(v)), T.(hdr{j}) = C(:,j); else, T.(hdr{j}) = v; end
end
end

function r = ifelse(a, b, c)
if a, r = b; else, r = c; end
end
