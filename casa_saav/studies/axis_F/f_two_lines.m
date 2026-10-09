function W = f_two_lines()
% F_TWO_LINES  Estimate (no ETABS run yet): two IPE 140 north-south lines at the third points of B-C instead of
%   one IPE 160 at the middle (user 2026-10-05). Forces scaled from ETABS run 2 of axis F (etabs_F.txt):
%   - each line keeps the slab load F picks up (w north 1.94, south 1.73 kN/m, D): conservative;
%   - tip load from the border beam: interior reaction of a continuous beam over 4 supports (spans 1.59)
%     against 3 supports (spans 2.39): 1.10 x 1.593 / (1.25 x 2.39) = 0.59 of F's 3.32 kN (rigid supports);
%   - moment at VCS north = 1.13 x south (ratio of run 2, slab takes the rest).
%   Connection with through rods Ø20 at the top (no strap): rods in tension and the end plate (12 A36) in
%   bending by strips to the flange and the web (as ca_calc), alone or with a 12 mm extra plate.
here = fileparts(mfilename('fullpath'));
C = f_capacities(fullfile(here, 'capacities.txt'));
ku = 2.58;  Ln = 1.45;  Ls = 1.27;
wn = (5.81 - 3.00)/Ln;  ws = (5.52 - 3.32)/Ls;  P = 1.10*1.593/(1.25*2.39)*3.32;
Ms = P*Ls + ws*Ls^2/2;  Mn = 6.36/5.62*Ms;
Vs = P + ws*Ls;  Vn = wn*Ln/2 + Mn/Ln;
D = struct('Mn', Mn, 'Ms', Ms, 'Vn', Vn, 'Vs', Vs, 'P', P);
S = C.IPE140;
r = {};
r(end+1,:) = {'IPE 140 north: flexure at VCS (Lb 1.45, Cb 1)', ku*Mn, S.phiMn(1450, 1)/1e6, 'kN m'};
r(end+1,:) = {'IPE 140 south cantilever: flexure at VCS (Lb 1.27, Cb 1)', ku*Ms, S.phiMn(1270, 1)/1e6, 'kN m'};
r(end+1,:) = {'IPE 140: shear', ku*max(Vn, Vs), S.phiVn/1e3, 'kN'};
% rods at the top: 2 Ø20 under the top flange at x = +-35, z = -40; compression at the bottom flange
zr = -40;  xr = 35;  zc = -(S.h - S.tf/2);  lev = zr - zc;
T = ku*max(Mn, Ms)*1e6/lev;  Ta = T/2;
Ab = pi*20^2/4;  phiRt = 0.75*0.75*550*Ab;
r(end+1,:) = {'2 rods Ø20 at the top: tension (rebar fu 550, threads)', Ta/1e3, phiRt/1e3, 'kN'};
wf = 6;  ww = 5;  zft = -S.tf - wf;  xwt = S.tw/2 + ww;  xft = S.b/2 + wf;
x1 = zft - zr;  w1 = min(xr + x1, xft) - max(xr - x1, xwt);
x2 = xr - xwt;  w2 = min(zr + x2, zft) - max(zr - x2, zc + S.tf/2 + wf);
k1 = x1/w1;  k2 = x2/w2;  c1 = k1*k2/(k1 + k2);
mp = 0.9*248*12^2/4;  m = c1*Ta;
r(end+1,:) = {sprintf('End plate PL 12 A36 at the rods: strips to the flange (%.0f/%.0f) and the web (%.0f/%.0f)', x1, w1, x2, w2), m/1e3, mp/1e3, 'kN m/m'};
r(end+1,:) = {'Same, with a 12 mm extra plate (half each)', m/2e3, mp/1e3, 'kN m/m'};
Tst = ku*max(Mn, Ms)*1e6/(6 - zc);
r(end+1,:) = {'Alternative: strap PL 12x60 on the top flanges (73 wide): tension yield', Tst/1e3, 0.9*248*12*60/1e3, 'kN'};
% steel per bay (B-C): beams + connection pieces
kgIPE = struct('IPE140', 12.9, 'IPE160', 15.8);  Lb_ = Ln + Ls;  rho = 7.85e-6;
conn = rho*(12*70*584 + 2*12*116*180) + 2*0.4*2.47;          % strap + 2 end plates + 2 rods Ø16 (kg)
W.kg1 = Lb_*kgIPE.IPE160 + conn;  W.kg2 = 2*(Lb_*kgIPE.IPE140 + conn);
W.D = D;  W.rows = r;
f = fopen(fullfile(here, 'two_lines_results.txt'), 'w');
fprintf(f, 'TWO IPE 140 LINES (third points of B-C) instead of one IPE 160: ESTIMATE from ETABS run 2 (f_two_lines.m, %s)\n', datestr(now, 'yyyy-mm-dd'));
fprintf(f, 'Per line, dead: tip load %.2f kN; M at VCS north %.2f / south %.2f kN m; V %.2f / %.2f kN. Factor %.2f.\n\n', P, Mn, Ms, Vn, Vs, ku);
fprintf(f, '%-92s %8s %8s %5s\n', 'Check', 'Demand', 'Capacity', 'D/C');
for i = 1:size(r, 1), fprintf(f, '%-92s %8.1f %8.1f %5.2f  %s\n', r{i,1}, r{i,2}, r{i,3}, r{i,2}/r{i,3}, r{i,4}); end
fprintf(f, '\nSteel per bay B-C (beams 2.72 m + connection across VCS): 1 IPE 160 %.0f kg; 2 IPE 140 %.0f kg (+%.0f%%)\n', W.kg1, W.kg2, 100*(W.kg2/W.kg1 - 1));
fclose(f);
type(fullfile(here, 'two_lines_results.txt'));
end
