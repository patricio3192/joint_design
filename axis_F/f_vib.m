function V = f_vib()
% F_VIB  Floor vibration of the cantilever edge (bay B-C), without and with axis F: hand estimate with
%   assumed stiffnesses (user 2026-10-05: "assume reasonable values"). AISC Design Guide 11 (2nd ed.):
%   fn = 0.18 sqrt(g / Delta), Delta = deflection of the edge under the weight it carries in the mode;
%   walking: ap/g = Po exp(-0.35 fn) / (beta W) <= 0.5 % (residential), Po = 0.29 kN; for fn > 9 Hz the
%   walking resonance criterion stops governing (DG11 ch. 6: stiffness, about 1 kN/mm at the worst point).
%   Two scenarios: LOW (bare steel, cracked concrete 0.35 Ig, flexible joint) and HIGH (slab acting with the
%   beams at small amplitudes: steel I x 2, concrete 0.7 Ig with dynamic E = 1.35 Ec, stiffer joint).
%   Weight in the mode: qD 2.5 + 0.5 live = 3.0 kPa (DG11: actual live, not design live).
here = fileparts(mfilename('fullpath'));
g = 9.81e3;  Es = 200e6;  Ec = 4700*sqrt(210*0.0980665)*1e3;     % kN/m2
q = 3.0;  aS = 1.27;  L = 4.78;  wrail = 0.30 + 0.158;          % edge strip depth (m), bay, railing + border IPE 160 (kN/m)
I160 = 869e-8;  I240 = 3892e-8;  Ivc = 0.3*0.35^3/12;           % m4
cases = struct('name', {'LOW', 'HIGH'}, 'ks', {1, 2}, 'kc', {0.35, 0.7*1.35}, 'Sj', {5000, 20000});
for c = 1:2
    K = cases(c);
    EIb = Es*I160*K.ks;  EIc = Es*I240*K.ks;  EIf = Es*I160*K.ks;  EIv = Ec*K.kc*Ivc;
    Kback = 4*EIv/L;                                             % beam in line behind the column (far end ~fixed)
    wb = q*aS/2 + wrail;                                         % border beam line load (half the strip)
    wc = q*0.5;                                                  % slab straight on the IPE 240 (0.5 m strip)
    a = 1.12;                                                    % IPE 240 from the column face
    % ---- without F: border beam simply spanning 4.78 between the tips ----
    P = wb*L;  M = P*a + wc*a^2/2;
    dC = P*a^3/(3*EIc) + wc*a^4/(8*EIc) + (M/K.Sj + M/Kback)*a;
    dB = 5*wb*L^4/(384*EIb);
    D0 = dC + dB;
    % ---- with F: border beam over 3 supports (spans 2.39), F tip a support ----
    l2 = L/2;  PF = 1.25*wb*l2;  wF = q*0.65;  aF = 1.27;  Lb = 1.45;
    MF = PF*aF + wF*aF^2/2;  thF = MF*Lb/(3*EIf);                % backspan pinned at the IPE 200, strap continuity
    RV = PF + wF*aF + MF/Lb;  dV = RV*L^3/(150*EIv);             % VCS at midspan, ends partly fixed
    dF = PF*aF^3/(3*EIf) + wF*aF^4/(8*EIf) + thF*aF + dV;
    P2 = 0.375*wb*l2*2;  M2 = P2*a + wc*a^2/2;
    dC2 = P2*a^3/(3*EIc) + wc*a^4/(8*EIc) + (M2/K.Sj + M2/Kback)*a;
    dB2 = wb*l2^4/(185*EIb);
    D1 = max(dF, dC2) + dB2;
    fn = 0.18*sqrt(g./([D0 D1]*1e3));                              % Delta in mm
    % walking (only meaningful below 9 Hz); W: edge strip of the bay and part of the next ones
    W = [25 40];  beta = 0.03;
    ap = 0.29*exp(-0.35*fn)./(beta*W(c))*100;
    % point load stiffness at the worst point (1 kN at the F tip / at the edge midspan)
    k0 = 1/(L^3/(48*EIb) + (a^3/(3*EIc) + (a/K.Sj + a/Kback)*a)/2);  % midspan of the border beam, tips half
    k1 = 1/(aF^3/(3*EIf) + aF*Lb/(3*EIf)*aF + (1 + aF/Lb)^2*L^3/(150*EIv));
    V(c) = struct('name', K.name, 'D', [D0 D1]*1e3, 'fn', fn, 'ap', ap, 'k', [k0 k1]/1e3, 'parts0', [dC dB]*1e3, 'parts1', [dF dC2 dB2]*1e3);
end
f = fopen(fullfile(here, 'vib_results.txt'), 'w');
fprintf(f, 'EDGE VIBRATION, bay B-C, without / with axis F (f_vib.m, %s): HAND ESTIMATE, assumed stiffnesses\n', datestr(now, 'yyyy-mm-dd'));
fprintf(f, 'Weight 3.0 kPa (D 2.5 + live 0.5); DG11 fn = 0.18 sqrt(g/Delta); walking ap/g = 0.29 exp(-0.35 fn)/(0.03 W).\n');
fprintf(f, 'LOW: bare steel, concrete 0.35 Ig, joint S_j 5000 kN m/rad. HIGH: steel I x2 (slab acting), concrete 0.7 Ig x 1.35 E, S_j 20000.\n\n');
for c = 1:2
    v = V(c);
    fprintf(f, '%s\n', v.name);
    fprintf(f, '  without F: Delta %.1f mm (IPE 240 tips %.1f + border beam %.1f) -> fn %.1f Hz, ap/g %.1f %%, 1 kN at mid-edge: %.2f kN/mm\n', v.D(1), v.parts0, v.fn(1), v.ap(1), v.k(1));
    fprintf(f, '  with F:    Delta %.1f mm (F tip %.1f, IPE 240 tips %.1f, border beam %.1f) -> fn %.1f Hz, ap/g %.1f %%, 1 kN at the F tip: %.2f kN/mm\n', v.D(2), v.parts1, v.fn(2), v.ap(2), v.k(2));
end
fprintf(f, '\nCriteria (residential): fn >= 9 Hz and about 1 kN/mm, or ap/g <= 0.5 %% if fn < 9 Hz.\n');
fclose(f);  type(fullfile(here, 'vib_results.txt'));
end
