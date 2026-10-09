function K = f_conn()
% F_CONN  Moment connection of axis F across VCS (the two IPE 160 pieces, hogging on both sides).
%   Tension: top strap PL t x w over VCS, fillet-welded on top of both top flanges (it sits 12 mm proud
%   of z = 0, under the slab). Compression: bottom flange through an end plate PL 12 bearing on the VCS
%   face (grout or shim). Shear: 2 through rods Ø20 (cast in VCS, AV type) at the bottom, nuts outside
%   both end plates. A36 12 mm plates only (user). Forces from f_calc.m (envelope of the two ETABS runs).
%   z = 0 top of VCS and of the IPE 160; x across F (web at 0). Writes conn_results.txt.
here = fileparts(mfilename('fullpath'));
C = f_capacities(fullfile(here, 'capacities.txt'));
Fy = 248;  Fu = 400;  FEXX = 483;  fc = 210*0.0980665;  S = C.IPE160;
% ---- demands (f_results.txt, envelope) ----
Mu = [18.3 14.5]*1e6;  Vu = [16.3 14.2]*1e3;            % north, south (N mm, N)
% ---- geometry ----
G.ts = 12;  G.ws = 70;  G.lap = 120;  G.gap = 10;                % strap: thickness, width, lap on each flange; grout gap
G.Ls = 300 + 2*(G.gap + 12 + G.lap);                         % strap length: VCS + gap + end plate + lap, each side (590)
G.wf = 6;                                                    % strap fillets (both edges + end, on the flange)
G.tp = 12;  G.bp = 116;  G.hp = 180;                         % end plate: t, width (n strip), height (z 0 to -180)
G.wwp = 5;                                                   % web-to-end-plate fillets, both sides
G.nr = 2;  G.dr = 16;  G.xr = 35;  G.zr = -120;  G.Fur = 550; % bottom rods (Ø16 rebar, threaded M16, fu >= 550): edge 23 >= 22 (J3.4M)
G.nut = 13.9;                                                % M16 nut, half across corners
zs = G.ts/2;  zc = -(S.h - S.tf/2);  lev = zs - zc;          % strap centroid to bottom flange centroid
T = Mu/lev;                                                  % strap tension = bottom compression, each side
rw = 0.75*0.6*FEXX*0.707*G.wf;                               % fillet, N/mm
r = {};
r(end+1,:) = {'Strap PL 12x70: tension yield (gross)', max(T), 0.9*Fy*G.ts*G.ws, 'kN', sprintf('T = M/%.0f mm (strap to bottom flange)', lev)};
r(end+1,:) = {'Strap: tension rupture (no holes)', max(T), 0.75*Fu*G.ts*G.ws, 'kN', ''};
Lw = 2*G.lap + G.ws;
r(end+1,:) = {sprintf('Strap to top flange: fillets %g, 2 x %g + %g', G.wf, G.lap, G.ws), max(T), rw*Lw, 'kN', 'site, flat position'};
r(end+1,:) = {'IPE 160 top flange in tension under the strap (gross)', max(T)*(S.h - S.tf)/lev*0 + max(Mu)/(S.h - S.tf), 0.9*Fy*S.b*S.tf, 'kN', 'flange force M/(d - tf) before the strap takes it'};
% bearing of the bottom flange zone on the VCS face: DG1 3.1.1, f_p,max with sqrt(A2/A1) = 2 (the VCS face,
% 350 high and continuous along VCS, holds a concentric A2 >= 4 A1 around the block)
fp = 0.65*0.85*fc*2;  Y = max(T)/(fp*G.bp);
r(end+1,:) = {'End plate bearing block on the VCS face (DG1): length Y below the bottom flange zone', Y, (G.hp + zc) + S.tf/2 + 40, 'mm', sprintf('f_p = %.1f MPa over b = %g; available from the plate bottom to 40 above the flange', fp, G.bp)};
n = (G.bp - 0.8*S.b)/2;  mp = 0.9*Fy*G.tp^2/4;
Mn_ = fp*n^2/2;
r(end+1,:) = {'End plate bending beyond the flange tips (n strip, DG1 3.1.2)', Mn_, mp, 'kN m/m', sprintf('n = (%g - 0.8 x %g)/2 = %.0f', G.bp, S.b, n)};
m = (G.hp + zc) - S.tf/2 - 0.05*S.h;  m = max(m, 0);
r(end+1,:) = {'End plate bending below the bottom flange (m strip)', fp*min(Y, m)*(m - min(Y, m)/2), mp, 'kN m/m', sprintf('m = %.0f', m)};
% shear: rods
Ab = pi*G.dr^2/4;  phiRv = 0.75*0.45*G.Fur*Ab;  phiRb = 0.75*2.4*G.dr*G.tp*Fu;
r(end+1,:) = {sprintf('%d rods Ø%g: shear (threads in the plane)', G.nr, G.dr), max(Vu), G.nr*phiRv, 'kN', 'AISC J3.6, F_nv = 0.45 F_u'};
r(end+1,:) = {'Rods: bearing on the end plate PL 12', max(Vu), G.nr*phiRb, 'kN', 'AISC J3.10'};
Lweb = 2*(S.h - 2*S.tf - 2*S.r);
r(end+1,:) = {sprintf('Web to end plate: fillets %g both sides', G.wwp), max(Vu), 0.75*0.6*FEXX*0.707*G.wwp*Lweb, 'kN', sprintf('%.0f mm', Lweb)};
% clearances
cl = {};
cl(end+1,:) = {'Rod nut (M16, corner 13.9) - bottom flange fillet toe', (G.zr - G.nut) - (zc + S.tf/2 + 6) , 'mm'};
cl(end+1,:) = {'Rod nut - web fillet toe', (G.xr - G.nut) - (S.tw/2 + G.wwp), 'mm'};
cl(end+1,:) = {'Rods in VCS (z = -120) - top bars (-56) and bottom bars (-294)', min(-56 - 6 - (G.zr + G.dr/2), (G.zr - G.dr/2) - (-294 + 6)), 'mm'};
cl(end+1,:) = {'Rods (x = +-35) - VCS stirrups at x = +-70 (spacing 140 centred on F)', 70 - 5 - (G.xr + G.dr/2), 'mm'};
cl(end+1,:) = {'Rod to end plate edge (x); AISC J3.4M minimum 22 for M16', G.bp/2 - G.xr, 'mm'};
K.rows = r;  K.cl = cl;  K.G = G;  K.T = T;
f = fopen(fullfile(here, 'conn_results.txt'), 'w');
fprintf(f, 'AXIS F: moment connection across VCS (f_conn.m, %s). Mu = %.1f / %.1f kN m, Vu = %.1f / %.1f kN (north / south).\n', datestr(now, 'yyyy-mm-dd'), Mu/1e6, Vu/1e3);
fprintf(f, 'Strap PL %gx%gx%g A36 on both top flanges (proud 12 over z = 0); end plates PL %gx%gx%g A36 bearing on the VCS faces;\n', G.ts, G.ws, G.Ls, G.tp, G.bp, G.hp);
fprintf(f, '%d rods Ø%g through VCS at x = +-%g, z = %g. Strap tension T = %.0f / %.0f kN.\n\n', G.nr, G.dr, G.xr, G.zr, T/1e3);
fprintf(f, '%-88s %9s %9s %5s\n', 'Check', 'Demand', 'Capacity', 'D/C');
for i = 1:size(r, 1)
    u = r{i,4};  sc = 1e3;  if strcmp(u, 'kN m/m'), sc = 1e3; elseif strcmp(u, 'mm'), sc = 1; end
    fprintf(f, '%-88s %9.1f %9.1f %5.2f  %s  %s\n', r{i,1}, r{i,2}/sc, r{i,3}/sc, r{i,2}/r{i,3}, u, r{i,5});
end
fprintf(f, '\nClearances (mm)\n');
for i = 1:size(cl, 1), fprintf(f, '%8.1f  %s\n', cl{i,2}, cl{i,1}); end
fclose(f);
type(fullfile(here, 'conn_results.txt'));
end
