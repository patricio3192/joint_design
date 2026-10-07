% =========================================================================
% DESIGN SCRIPT: "SANDWICH" MOMENT CONNECTION (Steel - Concrete - Steel)
% Two IPE 200 beams frame into the two side faces of a concrete beam through
% flush end plates tied together by through-rods cast in the concrete beam.
% References: AISC 360-16, AISC Design Guide 39 (2023), AISC Design Guide 1
% (2nd ed.), ACI 318-19 (SI forms from its Appendix C).
% Equation list with page numbers: EQUATIONS.txt. Open items: PENDIENTE.txt
% Units inside the script: N, mm, MPa.
% =========================================================================
clc; clear;

% -------------------------------------------------------------------------
% 1. INPUT DATA
% -------------------------------------------------------------------------
% Connection demands (governing face)
Mu_kNm = 23.5;          % moment at the end plate [kNm]
Vu_kN  = 21.5;          % shear at this face [kN]
Vu_other_kN = 9.5;      % shear at the opposite face, same rods [kN]

Mu = Mu_kNm * 1e6;      % [N*mm]
Vu = Vu_kN * 1000;      % [N]
Vu_other = Vu_other_kN * 1000;

% Steel beam IPE 200 (IPAC 2023 catalog, ~/scripting/digitalized_catalog_profiles)
h  = 200;               % total depth [mm]
bf = 100;               % flange width [mm]
tf = 8.5;               % flange thickness [mm]
tw = 5.6;               % web thickness [mm]
r_fil = 12;             % root radius [mm]
h_web = 159;            % web clear depth between root radii (catalog 'd') [mm]
Zx = 221e3;  Sx = 194e3;  Iy = 142e4;  ry = 22.4;  J = 6.98e4;   % mm3, mm3, mm4, mm, mm4
Fy = 250;  Fu = 400;  E = 200000;                 % ASTM A36 [MPa]
L_span  = 4800;         % IPE span [mm]
L_brace = 2400;         % IPE crossing at mid-span (shear connection) [mm]

% Concrete beam
bc = 300;               % width = rod length [mm]
hc = 350;               % depth [mm]; IPE top flush with concrete top
fc = 21;                % f'c [MPa]
fy_bar = 4200 * 0.0980665;   % 4200 kg/cm2 -> 411.9 MPa
cover_long = 50;        % clear cover to longitudinal bars [mm]
db_long = 12;  n_top = 3;  n_bot = 3;
db_st = 10;             % closed stirrups, 135 deg hooks
s_typ = 140;            % current stirrup spacing [mm]
s_joint = 110;          % proposed spacing in the joint zone [mm]

% End plate
tp  = 12;               % thickness [mm] (only A36 12 mm available)
bp  = 140;              % width [mm]
ext = 20;               % projection below the bottom flange [mm]; top is flush
Fyp = 250;  Fup = 400;  % ASTM A36 [MPa]

% Through-rods (threaded rod ASTM A193 B7 - see PENDIENTE.txt item 1)
d_b = 16;               % diameter [mm]
Ab  = pi * d_b^2 / 4;   % nominal area [mm2]
Fu_rod = 860;           % ASTM A193 Table 2, B7, d <= 2.5 in: Fu = 125 ksi.
                        % CONFIRM WITH THE SUPPLIER MILL CERTIFICATE.
dh  = 18;               % standard hole M16, AISC Table J3.3M [mm]

% Rod positions (measured from the top face of the IPE = top of concrete)
dist_top = 40;          % tension row [mm]: rod resting on the bottom of a 3/4" sleeve (OD <= 24,
                        % wall <= 2) that rests on the top bars (top of bars at 50): 50 - 2 - 8. pfi >= 30 (Module 1)
pfi = dist_top - tf;    % inner face of top flange to tension row [mm]
g   = 55;               % gage [mm]
dist_bot = 150;         % shear row [mm] (highest feasible row, module 7)

% Welds
FEXX = 482;             % E70XX [MPa]
top_cjp = true;         % top flange weld: true = CJP (agreed), false = PJP below
S_pjp = 6;              % PJP option: bevel depth (flange only beveled) [mm]
pjp_flat = true;        % PJP option: GMAW/FCAW in F/H position (E = S); false: E = S - 3
w_fl  = 6;              % bottom flange fillet leg [mm]
w_web = 6;              % web fillet leg (both sides) [mm]

% Flags
rods_torqued    = false; % false: hand tightened -> ACI Table 17.9.2(a) 4da
splitting_reinf = true;  % true: 2 stirrups next to the rods control splitting (ACI 17.9.1)
slab_on_top     = true;  % slab cast on top of the beam: top face is not a free edge

% Concrete beam forces from the structural model (Vu kN, Mu kNm, Tu kNm)
beam_names = {'N1 left', 'N1 right', 'N2 left', 'N2 right'};
beam_F = [ 34.0 , 20.00 , 4.55 ;
           -7.0 , 21.00 , 0.33 ;
           -7.6 , 17.18 , 0.33 ;
          -30.9 , 17.18 , -7.72 ];
torsion_compat = true;  % compatibility torsion (model uses 0.1 GJ)

S = cell(0, 2);         % summary {name, ratio}

fprintf('==============================================================\n');
fprintf('  LIMIT STATES - SANDWICH CONNECTION (AISC 360-16 / DG 39 / DG 1 / ACI 318-19)\n');
fprintf('==============================================================\n\n');

% -------------------------------------------------------------------------
% MODULE 1: DG 39 TESTED GEOMETRY RANGE (Table 5-1, +/-10 %, Sec. 5.2.1)
% -------------------------------------------------------------------------
in = 25.4;
fprintf('--- 1. DG 39 TABLE 5-1 TESTED RANGE (+/-10%%), two-bolt flush ---\n');
geo_rng = { 'pf (pfi)', pfi, 1+5/16, 2.25 ;
        'g',        g,   2.25,   4.5  ;
        'd',        h,   8,      24   ;      % two-bolt flush lower limit 8 in.
        'bp',       bp,  5,      14   ;
        'tf',       tf,  3/16,   0.75 };
for i = 1:size(geo_rng, 1)
    lo = 0.9 * geo_rng{i,3} * in;  hi = 1.1 * geo_rng{i,4} * in;
    ok = geo_rng{i,2} >= lo && geo_rng{i,2} <= hi;
    fprintf('  %-9s = %6.1f mm   range %6.1f - %6.1f mm   %s\n', ...
            geo_rng{i,1}, geo_rng{i,2}, lo, hi, iif(ok, 'OK', 'OUT OF RANGE'));
end
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 2: COMPRESSION SIDE - CONCRETE BEARING AND PLATE (DG 1 + ACI 22.8)
% -------------------------------------------------------------------------
% Lever arm used by DG 39: tension row to the centre of the compression flange
h1 = h - tf/2 - dist_top;
% Distance from the tension row to the bottom edge of the plate (DG 1: f + N/2)
D  = h + ext - dist_top;
phi_c = 0.65;                         % bearing, ACI Table 21.2.1
y_hole = h + ext - dist_bot;          % shear-row holes, from the plate bottom

fprintf('--- 2. COMPRESSION SIDE (DG 1 Sec. 3.4 + ACI 22.8.3.2) ---\n');
fprintf('  h1 (DG 39, to flange centre) = %.1f mm;  D (to plate bottom edge) = %.1f mm\n', h1, D);

% 2a. Governing model: strict strips (lower bound), see bearing_strips.m
p = struct('bp', bp, 'bf', bf, 'tf', tf, 'tw', tw, 'h', h, 'ext', ext, ...
           'tp', tp, 'Fyp', Fyp, 'phi_b', 0.90, 'fp', NaN, 'D', D, 'Mu', Mu, ...
           'holes_y', y_hole, 'holes_x', [-g/2, g/2], 'dh', dh);
k_conf = 2.0;                         % sqrt(A2/A1), checked below
for it = 1:20
    p.fp = phi_c * 0.85 * fc * k_conf;
    bs = bearing_strips(p);
    if ~bs.ok, break; end
    [k_new, A1, A2] = conf_factor(bp, bs.yt - max(0, ext - bs.c), ...
                        hc - h - ext + max(0, ext - bs.c), h + ext - bs.yt, bc);
    if abs(k_new - k_conf) < 1e-6, break; end
    k_conf = k_new;
end
fp = p.fp;
fprintf('  fp(max) = phi*0.85*fc*sqrt(A2/A1) = 0.65*0.85*%.0f*%.2f = %.2f MPa  [ACI 22.8.3.2]\n', fc, k_conf, fp);
if bs.ok
    fprintf('  A1 (bounding rectangle) = %.0f mm2, A2 = %.0f mm2, sqrt(A2/A1) = %.2f (cap 2)\n', A1, A2, sqrt(A2/A1));
    fprintf('  Strict strips: c = %.1f mm (DG 1 Eq. 3.3.14a-1 solved for length)\n', bs.c);
    fprintf('  Pressure field from plate bottom up to y = %.1f mm; web zone width = %.1f mm\n', bs.yt, bs.web_zone_width);
    fprintf('  C = %.1f kN at %.1f mm from plate bottom -> real lever arm = %.1f mm\n', bs.C/1e3, bs.ybar, bs.arm);
end
S(end+1,:) = print_check('Bearing: moment carried by compression zone', Mu/1e6, bs.Mmax/1e6, 'kNm', 'DG1 3.4.1 / ACI 22.8.3.2');
S(end+1,:) = print_check('Plate strip below flange (ext <= c)', ext, bs.c, 'mm', 'DG1 Eq. 3.3.14a-1');
S(end+1,:) = print_check('Plate strip beyond flange tip ((bp-bf)/2 <= c)', (bp-bf)/2, bs.c, 'mm', 'DG1 Eq. 3.3.14a-1');
arm_real = bs.arm;
if arm_real < h1
    fprintf('  FLAG: real lever arm (%.1f mm) < DG 39 h1 (%.1f mm): the flange-centre\n', arm_real, h1);
    fprintf('        assumption is NOT conservative here; bolts are also checked with the real arm.\n');
end

% 2b. Information: DG 1 literal (uniform pressure over bp x Y)
Ylit2 = D^2 - 2*Mu/(fp*bp);
fprintf('  Info, DG 1 literal (uniform fp over bp x Y, Eq. 3.4.3 with Pr = 0):\n');
if Ylit2 < 0
    fprintf('    no solution (Eq. 3.4.4 not met): bearing over bp cannot balance Mu.\n');
else
    Y  = D - sqrt(Ylit2);
    m  = ext + 0.025*h;               % DG 1: m = (N - 0.95d)/2, one-sided here
    n_ = (bp - 0.8*bf)/2;             % DG 1 Sec. 3.1.2: n = (B - 0.8bf)/2
    l_up = max(0, Y - ext - tf);
    if Y >= m, t_m = 1.49*m*sqrt(fp/Fyp); else, t_m = 2.11*sqrt(fp*Y*(m - Y/2)/Fyp); end
    fprintf('    Y = %.1f mm, arm = %.1f mm, T per bolt = %.1f kN\n', Y, D - Y/2, fp*bp*Y/2/1e3);
    fprintf('    t req: m = %.1f mm -> %.1f mm (Eq. 3.3.14a/15a); n = %.1f mm -> %.1f mm;\n', m, t_m, n_, 1.49*n_*sqrt(fp/Fyp));
    fprintf('           strip above flange %.1f mm -> %.1f mm (not a DG 1 check). tp = %.0f mm\n', l_up, 1.49*l_up*sqrt(fp/Fyp), tp);
end
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 3: ROD TENSION (AISC 360-16 J3.6, Table J3.2; DG 39 Table 5-2)
% -------------------------------------------------------------------------
Fnt = 0.75 * Fu_rod;                  % Table J3.2, threaded parts (Sec. A3.4)
Fnv = 0.450 * Fu_rod;                 % Table J3.2, threads not excluded
phi_r = 0.75;
phi_Rn_t = phi_r * Fnt * Ab;          % (J3-1)
Tu_rod_DG39 = Mu / h1 / 2;            % 2 rods in the tension row
Tu_rod_real = Mu / arm_real / 2;

fprintf('--- 3. ROD TENSION (A193 B7: Fnt = 0.75Fu = %.0f MPa) ---\n', Fnt);
S(end+1,:) = print_check('Rod tension, DG 39 arm h1', Tu_rod_DG39/1e3, phi_Rn_t/1e3, 'kN', 'J3-1, Table J3.2; DG39 Tab.5-2');
S(end+1,:) = print_check('Rod tension, real arm (strict strips)', Tu_rod_real/1e3, phi_Rn_t/1e3, 'kN', 'J3-1, Table J3.2');
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 4: END PLATE, TENSION SIDE (DG 39 Table 5-2, Sec. 5.1.1-5.1.2)
% -------------------------------------------------------------------------
s = sqrt(bp * g) / 2;
pfi_calc = pfi;
if pfi_calc > s
    pfi_calc = s;                     % Table 5-2 note: use pfi = s if pfi > s
end
Yp = (bp / 2) * (h1 * (1/pfi_calc + 1/s)) + (2 / g) * (h1 * (pfi_calc + s));
phi_b = 0.90;
gamma_r = 0.80;                       % (5-1) flush end plate
phi_Mn = phi_b * Fyp * tp^2 * Yp;
t_req_55 = sqrt(Mu / (gamma_r * phi_b * Fyp * Yp));            % (5-5a) thin plate
t_req_54 = sqrt(1.10 * Mu / (gamma_r * phi_b * Fyp * Yp));     % (5-4a) thick plate

fprintf('--- 4. END PLATE, TENSION SIDE (DG 39) ---\n');
fprintf('  s = %.1f mm, Yp = %.1f mm\n', s, Yp);
S(end+1,:) = print_check('End-plate yielding phi*Mpl (Table 5-2)', Mu/1e6, phi_Mn/1e6, 'kNm', 'DG39 Tab.5-2');
S(end+1,:) = print_check('Plate thickness, thick plate Eq. 5-4a', t_req_54, tp, 'mm', 'DG39 Eq.5-4a, 5-1');
fprintf('  Info: Eq. 5-5a (thin plate, needs prying check) t_req = %.2f mm\n', t_req_55);
fprintf('  NOTE: both DG 39 paths reported; see PENDIENTE.txt item 2.\n\n');

% -------------------------------------------------------------------------
% MODULE 5: ROD SHEAR AND BEARING ON THE PLATE (AISC 360-16 J3.6, J3.10)
% -------------------------------------------------------------------------
Vu_rod = max(Vu, Vu_other) / 2;       % shear row (2 rods) takes the face shear
phi_Rn_v = phi_r * Fnv * Ab;          % (J3-1)
lc = (dist_bot - dist_top) - dh;      % clear distance to the hole above (plate pushed down)
Rn_br = min(1.2 * lc * tp * Fup, 2.4 * d_b * tp * Fup);   % (J3-6c), (J3-6a)
fprintf('--- 5. ROD SHEAR AND PLATE BEARING ---\n');
S(end+1,:) = print_check('Rod shear (Fnv = 0.450Fu)', Vu_rod/1e3, phi_Rn_v/1e3, 'kN', 'J3-1, Table J3.2');
S(end+1,:) = print_check('Bearing / tearout at plate hole', Vu_rod/1e3, 0.75*Rn_br/1e3, 'kN', 'J3-6a, J3-6c');
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 6: CONCRETE BREAKOUT IN SHEAR, PLAIN CONCRETE (ACI 318-19 17.7.2)
% -------------------------------------------------------------------------
% Shear acts downward, toward the bottom face of the concrete beam. Only the
% shear row is loaded (17.7.2.1.1, critical row). No anchor or supplementary
% reinforcement is counted ("cone alone"): psi_c,V = 1.0 (cracked, bars of
% 12 mm < No. 13), phi = 0.70 (Table 17.5.3(b), cast-in, Condition B).
% Each rod is loaded at both faces of the beam. ACI covers loading from one
% face only, so two models are reported:
%   B (governs): one concrete body, demand = sum of both faces, AVc depth =
%     min(2*1.5*ca1, bc) (both cones overlap), psi_h with ha = bc.
%   A (info)   : each face alone with half the width, ha = bc/2. It sums to
%     more than a single face on the full width, so it is not used.
phi_cb = 0.70;  psi_c = 1.0;  lambda_a = 1.0;
ca1 = hc - dist_bot;
le  = bc;                              % embedded length, capped at 8da inside
bB  = aci_shear_breakout(ca1, g, 4, bc, d_b, le, fc, lambda_a, psi_c, min(3*ca1, bc));
bA  = aci_shear_breakout(ca1, g, 2, bc/2, d_b, le, fc, lambda_a, psi_c, []);
fprintf('--- 6. CONCRETE BREAKOUT IN SHEAR (ACI 17.7.2), ca1 = %.0f mm ---\n', ca1);
fprintf('  Vb = min(%.1f, %.1f) = %.1f kN (le = %.0f mm)\n', bB.Vb1/1e3, bB.Vb2/1e3, bB.Vb/1e3, bB.le);
fprintf('  Model B: AVc = %.0f x %.0f = %.0f mm2, AVco = %.0f mm2, psi_h = %.2f\n', bB.width, bB.depth, bB.AVc, bB.AVco, bB.psi_h);
S(end+1,:) = print_check('Breakout, model B (both faces, one body)', (Vu + Vu_other)/1e3, phi_cb*bB.Vcbg/1e3, 'kN', 'ACI 17.7.2.1b');
fprintf('  Info, model A (one face, ha = bc/2): phi*Vcbg = %.1f kN vs Vu = %.1f kN\n\n', phi_cb*bA.Vcbg/1e3, Vu/1e3);

% -------------------------------------------------------------------------
% MODULE 7: SHEAR-ROW POSITION SWEEP (information; dist_bot is an input)
% -------------------------------------------------------------------------
% Breakout capacity grows with ca1, so the best row is the highest one that
% (1) keeps the whole rod hole inside the compression field (no tension in the
%     shear rods, so no J3.7 interaction is needed),
% (2) keeps the vertical spacing to the tension row (AISC J3.3, ACI Table
%     17.9.2(a) unless splitting reinforcement is provided),
% (3) leaves pf >= 0.9*(1 5/16 in.) to the bottom flange (DG 39 Table 5-1
%     lower bound, used as wrench clearance).
if splitting_reinf
    s_min_v = 3 * d_b;                % AISC J3.3 preferred 3d
else
    s_min_v = max(3*d_b, iif(rods_torqued, 6, 4) * d_b);
end
pf_min = 0.9 * (1 + 5/16) * in;
fprintf('--- 7. SHEAR-ROW POSITION SWEEP (dist from top of IPE) ---\n');
fprintf('  %8s %8s %10s %12s %8s\n', 'dist', 'ca1', 'y_field', 'phiVcbg_B', 'feasible');
best = NaN;
for db_try = (dist_top + s_min_v):2:(h - tf - pf_min)
    pp = p;  pp.holes_y = h + ext - db_try;
    bt = bearing_strips(pp);
    inside = bt.ok && (pp.holes_y + dh/2 <= bt.yt);   % whole hole inside the field
    ca1_t = hc - db_try;
    bb = aci_shear_breakout(ca1_t, g, 4, bc, d_b, le, fc, lambda_a, psi_c, min(3*ca1_t, bc));
    if inside && isnan(best), best = db_try; end
    if mod(db_try - dist_top - s_min_v, 10) == 0 || (inside && db_try == best)
        fprintf('  %8.0f %8.0f %10.1f %12.1f %8s\n', db_try, ca1_t, bt.yt, phi_cb*bb.Vcbg/1e3, iif(inside, 'yes', 'no'));
    end
end
fprintf('  Highest feasible shear row: dist_bot = %.0f mm (input uses %.0f mm)\n\n', best, dist_bot);

% -------------------------------------------------------------------------
% MODULE 8: SPACING AND EDGE DISTANCES (AISC J3.3, J3.4; ACI 17.9)
% -------------------------------------------------------------------------
fprintf('--- 8. SPACING AND EDGE DISTANCES ---\n');
S(end+1,:) = print_check('AISC min spacing, gage (2 2/3 d)', 8/3*d_b, g, 'mm', 'AISC J3.3');
S(end+1,:) = print_check('AISC min spacing, rows (2 2/3 d)', 8/3*d_b, dist_bot - dist_top, 'mm', 'AISC J3.3');
S(end+1,:) = print_check('AISC min edge, plate side', 22, (bp - g)/2, 'mm', 'AISC Table J3.4M');
S(end+1,:) = print_check('AISC min edge, plate top', 22, dist_top, 'mm', 'AISC Table J3.4M');
S(end+1,:) = print_check('AISC min edge, plate bottom', 22, h + ext - dist_bot, 'mm', 'AISC Table J3.4M');
s_aci = iif(rods_torqued, 6, 4) * d_b;
fprintf('  ACI Table 17.9.2(a): min spacing %s = %.0f mm; gage = %.0f mm, rows = %.0f mm\n', ...
        iif(rods_torqued, '6da (torqued)', '4da (not torqued)'), s_aci, g, dist_bot - dist_top);
if g < s_aci
    if splitting_reinf
        fprintf('  -> gage below ACI minimum; WAIVED per ACI 17.9.1 by supplementary reinforcement\n');
        fprintf('     (2 stirrups, one each side of the rods). ACI gives no sizing rule: engineering judgment.\n');
    else
        S(end+1,:) = print_check('ACI min spacing, gage', s_aci, g, 'mm', 'ACI Table 17.9.2(a)');
    end
end
cover_req = 40;                       % ACI Table 20.5.1.3.1: beams, not exposed (1.5 in.)
fprintf('  ACI min edge (not torqued) = specified cover %.0f mm; top rod clear cover = %.0f mm\n', cover_req, dist_top - d_b/2);
if slab_on_top
    fprintf('  -> slab cast on top: the beam top is not a free edge, requirement met.\n');
else
    S(end+1,:) = print_check('ACI min edge, top rods (clear cover)', cover_req, dist_top - d_b/2, 'mm', 'ACI Table 17.9.2(a)');
end
fprintf('  Rods run parallel to the stirrup legs: place them between stirrups.\n\n');

% -------------------------------------------------------------------------
% MODULE 9: STEEL BEAM IPE 200 (AISC 360-16 F2, G2)
% -------------------------------------------------------------------------
fprintf('--- 9. IPE 200: FLEXURE AND SHEAR ---\n');
lam_f = bf/(2*tf);  lam_w = h_web/tw;
fprintf('  bf/2tf = %.2f <= 0.38sqrt(E/Fy) = %.2f; h/tw = %.1f <= 3.76sqrt(E/Fy) = %.1f (Table B4.1b, compact)\n', ...
        lam_f, 0.38*sqrt(E/Fy), lam_w, 3.76*sqrt(E/Fy));
ho = h - tf;
Cb = 1.0;                             % conservative (F1); bottom flange in compression at the joint
for Lb = [L_brace, L_span]
    f2 = aisc_f2_ltb(E, Fy, Zx, Sx, Iy, J, ho, ry, Lb, Cb);
    fprintf('  Lb = %.0f mm: Lp = %.0f, Lr = %.0f mm, phiMp = %.1f kNm, eq. %s\n', Lb, f2.Lp, f2.Lr, 0.9*f2.Mp/1e6, f2.eq);
    S(end+1,:) = print_check(sprintf('Flexure LTB, Lb = %.1f m, Cb = 1', Lb/1000), Mu/1e6, 0.9*f2.Mn/1e6, 'kNm', 'AISC F2-1..F2-6');
end
if lam_w <= 2.24*sqrt(E/Fy)
    phi_v = 1.00;  Cv1 = 1.0;         % G2.1(a), (G2-2)
else
    error('h/tw > 2.24sqrt(E/Fy): use G2.1(b)');
end
Vn = 0.6 * Fy * (h*tw) * Cv1;         % (G2-1), Aw = d*tw
S(end+1,:) = print_check('Shear yielding', Vu/1e3, phi_v*Vn/1e3, 'kN', 'AISC G2-1, G2-2');
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 10: WELDS (AISC 360-16 J2, J4; DG 39 Sec. 3.7.5)
% -------------------------------------------------------------------------
fprintf('--- 10. WELDS (E70XX, FEXX = %.0f MPa) ---\n', FEXX);
Ru_fl = max(Mu/(h - tf), 0.60*Fy*bf*tf);          % DG39 (3-38a), no axial force
fprintf('  Flange weld demand Ru = max(Mu/(d-tf), 0.60Fy bf tf) = max(%.1f, %.1f) = %.1f kN\n', ...
        Mu/(h-tf)/1e3, 0.60*Fy*bf*tf/1e3, Ru_fl/1e3);
% Top flange: plate flush on top -> groove weld, flange beveled
if top_cjp
    % CJP, matching filler (E70XX): joint strength controlled by the base metal
    fprintf('  Top flange CJP groove weld, E70XX matching filler\n');
    S(end+1,:) = print_check('CJP top flange, base metal (flange yielding)', Ru_fl/1e3, 0.90*Fy*bf*tf/1e3, 'kN', 'Table J2.5, J4-1');
else
    E_pjp = iif(pjp_flat, S_pjp, S_pjp - 3);   % Table J2.1, 45 deg bevel
    if S_pjp > tf, error('PJP bevel depth larger than tf'); end
    fprintf('  Top flange PJP: S = %.1f mm, E = %.1f mm (%s)\n', S_pjp, E_pjp, iif(pjp_flat, 'GMAW/FCAW F,H: E = S', 'SMAW or V/OH: E = S - 3'));
    S(end+1,:) = print_check('PJP min effective throat', 5, E_pjp, 'mm', 'AISC Table J2.3');
    S(end+1,:) = print_check('PJP top flange, weld metal', Ru_fl/1e3, 0.80*0.60*FEXX*E_pjp*bf/1e3, 'kN', 'AISC Table J2.5');
    S(end+1,:) = print_check('PJP top flange, base metal (rupture)', Ru_fl/1e3, 0.75*Fu*E_pjp*bf/1e3, 'kN', 'Table J2.5, J4-2');
end
% Bottom flange: fillet both faces (outer full width, inner faces between root radii)
L_fl = bf + (bf - tw - 2*r_fil);
kds  = 1 + 0.5*sind(90)^1.5;                       % (J2-5), theta = 90 deg
S(end+1,:) = print_check('Bottom flange fillet min size', 5, w_fl, 'mm', 'AISC Table J2.4');
S(end+1,:) = print_check('Bottom flange fillet max size (t-2)', w_fl, tf - 2, 'mm', 'AISC J2.2b');
S(end+1,:) = print_check('Bottom flange fillet (designed for Ru)', Ru_fl/1e3, 0.75*0.60*FEXX*kds*0.707*w_fl*L_fl/1e3, 'kN', 'AISC J2-4, J2-5');
fprintf('  (bottom flange is in compression; Ru used in case of moment reversal; ext = %.0f mm >= w)\n', ext);
% Web: tension region near the tension rods, rest in shear (DG 39 Sec. 3.7.5, Example 5.2-1)
Tuw = (2/2) * Mu/(h - tf);                         % (3-39), (3-40): ntrib/n = 2/2
lwt_DG = pfi + 6*in;
lwt = min(lwt_DG, h - 2*tf);
Tyw = Fy * tw * lwt;
Tuwd = max(Tuw, 0.60*Fy*tw*lwt);                   % (3-41a)
S(end+1,:) = print_check('Web tension yielding near tension rods', Tuw/1e3, 0.90*Tyw/1e3, 'kN', 'DG39 3-40; J4-1');
S(end+1,:) = print_check('Web weld, tension region', Tuwd/1e3, 0.75*2*0.60*FEXX*0.707*w_web*lwt*kds/1e3, 'kN', 'DG39 3-41a; J2-4, J2-5');
lt   = h - 2*tf - lwt;
l05  = h/2 - tf;
lwv  = min(lt, l05);
if lt >= l05                                       % tension region leaves at least the lower half for shear
    S(end+1,:) = print_check('Web weld, shear region', Vu/1e3, 0.75*2*0.60*FEXX*0.707*w_web*lwv/1e3, 'kN', 'J2-4 (theta = 0)');
    S(end+1,:) = print_check('Web shear rupture at weld', Vu/1e3, 0.75*0.60*Fu*lwv*tw/1e3, 'kN', 'AISC J4-4');
else
    fprintf('  FLAG: DG 39 tension length pfi + 6 in. = %.0f mm covers the whole web of this\n', lwt_DG);
    fprintf('        shallow beam; no weld is left for shear. Lower half of the web (%.1f mm)\n', l05);
    fprintf('        checked for tension + shear together (resultant at angle theta, J2-5).\n');
    ft = Tuwd / (2*lwt);  fv = Vu / (2*l05);       % N/mm per weld
    th = atand(ft / fv);
    S(end+1,:) = print_check('Web weld, tension + shear (lower half)', sqrt(ft^2 + fv^2), ...
        0.75*0.60*FEXX*0.707*w_web*(1 + 0.5*sind(th)^1.5), 'N/mm', 'J2-4, J2-5 (deviation)');
    S(end+1,:) = print_check('Web shear rupture at weld (lower half)', Vu/1e3, 0.75*0.60*Fu*l05*tw/1e3, 'kN', 'AISC J4-4');
end
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 11: CONCRETE BEAM SHEAR + TORSION (ACI 318-19 22.5, 22.7, 9.5-9.7)
% -------------------------------------------------------------------------
sec = struct('bw', bc, 'h', hc, 'fc', fc, 'fy', fy_bar, 'fyt', fy_bar, 'lambda', 1.0, ...
             'cover_long', cover_long, 'db_long', db_long, 'n_top', n_top, 'n_bot', n_bot, ...
             'db_st', db_st, 's', s_joint, 'compat', torsion_compat);
fprintf('--- 11. CONCRETE BEAM %dx%d, %d+%d phi%d, stirrups phi%d @ %d mm (joint zone) ---\n', ...
        bc, hc, n_top, n_bot, db_long, db_st, s_joint);
for i = 1:numel(beam_names)
    Fi = beam_F(i,:);
    rb = aci_beam_shear_torsion(sec, Fi(1)*1e3, Fi(2)*1e6, Fi(3)*1e6);
    fprintf('  %s: Vu = %.1f kN, Mu = %.2f kNm, Tu = %.2f kNm; phiTth = %.2f, phiTcr = %.2f kNm -> torsion %s\n', ...
        beam_names{i}, Fi(1), Fi(2), Fi(3), rb.phi*rb.Tth/1e6, rb.phi*rb.Tcr/1e6, iif(rb.tors, 'REQUIRED', 'neglected (22.7.1.1)'));
    tag = beam_names{i};
    S(end+1,:) = print_check([tag ' section limit (V+T)'], rb.lhs, rb.rhs, 'MPa', 'ACI 22.7.7.1a / 22.5.1.2');
    S(end+1,:) = print_check([tag ' stirrups (Av+2At)/s'], rb.trans_req, rb.trans_prov, 'mm2/mm', 'ACI 22.5.8.5.3, 22.7.6.1a');
    S(end+1,:) = print_check([tag ' stirrups minimum'], rb.trans_min, rb.trans_prov, 'mm2/mm', 'ACI 9.6.4.2 / 9.6.3.4');
    S(end+1,:) = print_check([tag ' stirrup spacing'], sec.s, rb.s_max, 'mm', 'ACI 9.7.6.3.3, T.9.7.6.2.2');
    S(end+1,:) = print_check([tag ' long. tension face (As+Al/2)'], rb.As_tens_req, rb.As_face_prov, 'mm2', 'ACI 22.2, 22.7.6.1b, 9.6.4.3');
    S(end+1,:) = print_check([tag ' long. compression face (Al/2)'], rb.As_comp_req, rb.As_face_prov, 'mm2', 'ACI 22.7.6.1b, 9.6.4.3');
    if rb.eps_t < 0.005
        fprintf('  FLAG: eps_t = %.4f < 0.005, phi = 0.90 not valid (Table 21.2.2)\n', rb.eps_t);
    end
end
fprintf('  Torsion bars: row gap %.0f mm <= 300 (9.7.5.1); db = %d mm >= max(0.042s, 10) (9.7.5.2).\n', rb.row_gap, db_long);
fprintf('  With s = %d mm (current): ph/8 = %.1f mm -> %s. Torsion stirrups must extend\n', s_typ, rb.ph/8, iif(s_typ <= rb.ph/8, 'OK', 'NOT OK'));
fprintf('  (bt + d) beyond where the model torsion exceeds phiTth (9.7.6.3.2).\n\n');

% -------------------------------------------------------------------------
% MODULE 12: LIMIT STATES NOT APPLICABLE (through-rods tie plate to plate)
% -------------------------------------------------------------------------
fprintf('--- 12. NOT APPLICABLE ---\n');
fprintf('  Concrete breakout in tension (17.6.2), pullout (17.6.3),\n');
fprintf('  side-face blowout (17.6.4), pryout (17.7.3).\n\n');

% -------------------------------------------------------------------------
% SUMMARY
% -------------------------------------------------------------------------
fprintf('==============================================================\n');
fprintf('  SUMMARY (ratio = demand / capacity)\n');
fprintf('==============================================================\n');
for i = 1:size(S, 1)
    fprintf('  %-50s %5.2f  %s\n', S{i,1}, S{i,2}, iif(S{i,2} <= 1, 'OK', '<-- NOT OK'));
end
[rmax, imax] = max(cell2mat(S(:,2)));
fprintf('  Governing: %s (%.2f)\n', S{imax,1}, rmax);
fprintf('==============================================================\n');
