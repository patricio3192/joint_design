function F = f_calc()
% F_CALC  Axis F (north-south, halfway between grids B and C): two IPE 160 pieces either side of VCS
%   (grid 4), the north one from the IPE 200 (shear connection), the south one a cantilever to the border
%   beam (shear connection). ETABS dead-load results (etabs_F.txt), live = 0.8 dead (user: qL/qD = 2/2.5).
%   Combinations: 1.2D + 1.6L and 1.2D + Ev + L (Ev = 2/3 eta Z Fa I D, NEC-SE-DS 3.4.4, as ca_calc);
%   uplift at the IPE 200 also with live on the cantilever side only. Writes f_results.txt.
here = fileparts(mfilename('fullpath'));
C = f_capacities(fullfile(here, 'capacities.txt'));
kL = 2.0/2.5;  Ev = 2/3*2.48*0.25*1.4*1.0;
k = [1.2 + 1.6*kL, 1.2 + Ev + kL];  ku = max(k);          % factor on the dead-load results
% ---- ETABS, dead: run 1 (VCS torsion stiffness 1.0) and run 2 (0.1) ------------------------------
runs = struct('name', {'run 1 (VCS torsion x1.0)', 'run 2 (VCS torsion x0.1)'}, ...
    'FnV', {[-3.52 -6.33], [-3.00 -5.81]}, 'FnM', {[0 -7.11], [0 -6.36]}, ...
    'FsV', {[5.20 3.00], [5.52 3.32]}, 'FsM', {[-5.20 0], [-5.62 0]}, ...
    'GV', {[-16.40 -5.30 6.25 17.37], [-16.40 -5.18 6.13 17.30]}, 'GM', {[-11.56 11.72 11.72 -13.70], [-11.44 11.60 11.72 -13.60]}, ...
    'GT', {[-1.05 -1.05 0.86 0.86], [0 0 0 0]}, 'C4M', {-6.1, -5.72}, 'C4V', {7, 6.58});
Ln = 1.45;  a = 0.2;  S = C.IPE160;  V = C.VCS;  S2 = C.IPE200;
r = {};
for q = 1:numel(runs)
    E = runs(q);  t = sprintf(' [%s]', E.name);
    r(end+1,:) = {['F north IPE 160: flexure at VCS (Lb 1.45, Cb 1)' t], ku*abs(E.FnM(2)), S.phiMn(1450, 1)/1e6, 'kN m'};
    r(end+1,:) = {['F north IPE 160: shear' t], ku*max(abs(E.FnV)), S.phiVn/1e3, 'kN'};
    r(end+1,:) = {['F south IPE 160 cantilever: flexure at VCS (Lb 1.27, Cb 1)' t], ku*abs(E.FsM(1)), S.phiMn(1270, 1)/1e6, 'kN m'};
    r(end+1,:) = {['F south IPE 160 cantilever: shear' t], ku*max(abs(E.FsV)), S.phiVn/1e3, 'kN'};
    Mface = [abs(E.GM(1)) - abs(E.GV(1))*a, abs(E.GM(4)) - abs(E.GV(4))*a];
    r(end+1,:) = {['VCS: negative moment at the column faces (B, C)' t], ku*max(Mface), V.phiMn/1e6, 'kN m'};
    r(end+1,:) = {['VCS: positive moment at axis F' t], ku*max(E.GM(2:3)), V.phiMn/1e6, 'kN m'};
    r(end+1,:) = {['VCS: shear' t], ku*max(abs(E.GV)), V.phiVn/1e3, 'kN'};
    r(end+1,:) = {['VCS: torsion against the threshold (22.7.4.1a)' t], ku*max(abs(E.GT)), V.phiTth/1e6, 'kN m'};
    R0Lc = -kL*abs(E.FnM(2))/Ln;  up = min([ku*E.FnV(1), 1.2*E.FnV(1) + 1.6*R0Lc, (1.2 + Ev)*E.FnV(1) + R0Lc]);
    r(end+1,:) = {['IPE 200 at axis F: upward point load from F (live on the cantilever only)' t], abs(up), NaN, 'kN'};
    r(end+1,:) = {['IPE 200 if the uplift alone acted: bottom flange in compression, Lb 4.78' t], abs(up)*4.78/4, S2.phiMn(4780, 1)/1e6, 'kN m'};
    r(end+1,:) = {['Shear connection F tip - border beam IPE 160' t], ku*abs(E.FsV(2)), NaN, 'kN'};
    r(end+1,:) = {['C4 IPE 240 with axis F: moment at the face (factored)' t], ku*abs(E.C4M), NaN, 'kN m'};
end
F.rows = r;  F.ku = ku;  F.k = k;  F.Ev = Ev;
% ---- write ---------------------------------------------------------------------------------------
f = fopen(fullfile(here, 'f_results.txt'), 'w');
fprintf(f, 'AXIS F checks (f_calc.m, %s). Dead results from etabs_F.txt; live = %.1f dead.\n', datestr(now, 'yyyy-mm-dd'), kL);
fprintf(f, 'Factor on the dead results: 1.2D+1.6L = %.2f, 1.2D+Ev+L = %.2f (Ev = %.3f D): used %.2f.\n\n', k, Ev, ku);
fprintf(f, '%-92s %8s %8s %6s\n', 'Check', 'Demand', 'Capacity', 'D/C');
for i = 1:size(r, 1)
    dc = r{i,2}/r{i,3};  if isnan(r{i,3}), dcs = '  -'; else, dcs = sprintf('%5.2f', dc); end
    cap = sprintf('%8.1f', r{i,3});  if isnan(r{i,3}), cap = '       -'; end
    fprintf(f, '%-92s %8.1f %s %6s  %s\n', r{i,1}, r{i,2}, cap, dcs, r{i,4});
end
fclose(f);
type(fullfile(here, 'f_results.txt'));
end
