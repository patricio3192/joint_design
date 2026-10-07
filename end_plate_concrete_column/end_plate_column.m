% =========================================================================
% DESIGN SCRIPT: IPE 240 CANTILEVER - FLUSH END PLATE ON A CONCRETE COLUMN
% The end plate is set on 4 cast-in threaded rods (A193 B7) after the joint
% is cast, over a 30 mm grout layer. The rods end in square head plates
% inside the column hoop cage. All rod tension is taken by 2 L-shaped bars
% ("bastones", anchor reinforcement, ACI 17.5.2.1(a)) lapping into the VCM.
% References: AISC 360-16, AISC Design Guide 39 (2023), AISC Design Guide 1
% (2nd ed.), ACI 318-19 (SI forms from its Appendix C).
% Equation list with page numbers: EQUATIONS.txt. Open items: PENDIENTE.txt
% Units inside the script: N, mm, MPa.
% Coordinates: x along the column face (0 = cantilever axis = column axis),
% y down from the top of the beams (= top of IPE = top of end plate),
% z into the column from the concrete face (z = 0) toward the VCM.
% =========================================================================
clc; clear;

% -------------------------------------------------------------------------
% 1. INPUT DATA
% -------------------------------------------------------------------------
Mu_kNm = 12.1;  Vu_kN = 14.1;          % at the column face; top in tension, no reversal
Mu = Mu_kNm * 1e6;  Vu = Vu_kN * 1e3;  % [N*mm], [N]

% Steel beam IPE 240 (IPAC 2023 catalog, ~/scripting/digitalized_catalog_profiles)
h = 240;  bf = 120;  tf = 9.8;  tw = 6.2;  r_fil = 15;  h_web = 190.4;
Fy = 250;  Fu = 400;  E = 200000;      % ASTM A36 [MPa]

% Concrete (column, joint and beams), reinforcement
fc = 210 * 0.0980665;                  % 210 kg/cm2 -> 20.6 MPa (input; 240 possible)
fy_bar = 4200 * 0.0980665;             % 4200 kg/cm2 -> 411.9 MPa
lambda = 1.0;                          % normalweight
psi_cN = 1.0;  psi_cP = 1.0;           % cracked (17.6.2.5.1(b), 17.6.3.3.1(b))
col_b = 400;                           % column 40 x 40
col_top = -105;                        % column top above the beams (y)
y_soffit = 350;                        % beams 30 x 35; column cast up to here (cold joint)
cover = 40;  db_hoop = 10;  db_col = 16;
c_col = cover + db_hoop + db_col/2;    % column bar centre to face = 58 mm
bw_beam = 300;  h_beam = 350;          % VCM (along z, centred in x) and VCS (along x, centred in z)
c_beam = cover + db_hoop + 12/2;       % beam bar centre to beam face = 56 mm

% End plate (A36, 10 or 12 mm available), on 30 mm grout
tp = 12;  bp = 140;  ext = 20;         % ext: plate below the bottom flange [mm]
Fyp = 250;  Fup = 400;
t_grout = 30;

% Anchor rods A193 B7, cast-in, hand tightened (see PENDIENTE item 1)
d_b = 16;  Ab = pi*d_b^2/4;
Ase = pi/4*(d_b - 0.9382*2)^2;         % M16x2 tensile stress area (R17.6.1.2) [mm2]
Fu_rod = 860;  Fy_rod = 720;           % ASTM A193 B7 Table 2 - CONFIRM MILL CERTIFICATE
dh = 18;                               % standard hole M16, AISC Table J3.3M (template needed)
y_t = 42;                              % tension row (from top of plate)
y_s = h - y_t;                         % shear row, symmetric, near the compression flange
g   = 80;                              % gage (column mid bar at x = 0, VCM centre bar at x = 0)
pfi = y_t - tf;

% Head plates (one square plate per rod, nut + washer behind)
a_hd = 50;  t_hd = 12;  dw = 30;       % plate side, thickness, washer OD (ISO 7089 M16)
h_nut = 16;  t_wsh = 3;  proj = 5;     % nut height, washer, rod beyond the nut
z_cage = col_b - cover - db_hoop;      % inner face of the back hoop leg = 350
z_tip  = z_cage - 5;                   % rod tip, 5 mm clear to the hoop
hef = z_tip - proj - h_nut - t_wsh - t_hd;      % bearing face of the head plate

% Anchor reinforcement: 2 bastones phi12 (straight leg along z, horizontal hook)
db_bst = 12;  n_bst = 2;
x_bst = 94 - 12;                       % beside the VCM 2nd-row corner pair (x = +/-94)
y_bst = c_beam + 12 + 12;              % 2nd-row level: 56 + 12 (VCS) + 12 = 80
z_hook = c_col + db_col/2;             % hook outer face against the column face bars = 66
psi_t_bst = 1.3;                       % > 300 mm of fresh concrete below (455 mm pour)
ld_good = false;                       % false: Table 25.4.2.3 "other cases" (conservative)

% Joint
frame = 'ordinary';                    % NEC/ACI ordinary moment frame
hoop_y = [110 155 230 305];          % hoop layers inside the joint (y), <= 75 apart (user) [mm]
Mu_VCM = 32.5e6;                       % VCM at the column face [N*mm], top in tension
Mu_VCS = [24.5e6 33.4e6];              % VCS left / right at the column faces
nb_VCM_top = 5;  nb_VCS_top = 3;

% Steel column above: 4 phi12 anchors at 200 mm, 100 mm from the faces
x_sc = [-100 100];  z_sc = [100 300];  d_sc = 12;

% Welds
FEXX = 482;  w_fl = 6;  w_web = 6;     % E70XX; top flange CJP; fillets elsewhere

S = cell(0, 2);
in = 25.4;
fprintf('==============================================================\n');
fprintf('  LIMIT STATES - IPE 240 END PLATE ON CONCRETE COLUMN\n');
fprintf('  (AISC 360-16 / DG 39 / DG 1 / ACI 318-19)\n');
fprintf('==============================================================\n');
fprintf('  fc = %.1f MPa, fy = %.1f MPa, hef = %.0f mm, tp = %.0f, ext = %.0f, g = %.0f\n\n', ...
        fc, fy_bar, hef, tp, ext, g);

% -------------------------------------------------------------------------
% MODULE 2: GEOMETRY AND CLASHES (information; small clashes are solved on site)
% -------------------------------------------------------------------------
fprintf('--- 2. GEOMETRY AND CLASHES (clear distances, mm) ---\n');
% bars running along z: {name, x, y, d}
yb = h_beam - c_beam;                  % bottom row of the beams
zbars = {'anchor T', -g/2, y_t, d_b;  'anchor T', g/2, y_t, d_b;
         'anchor V', -g/2, y_s, d_b;  'anchor V', g/2, y_s, d_b;
         'baston',   -x_bst, y_bst, db_bst;  'baston', x_bst, y_bst, db_bst;
         'VCM top 1', -94, 56, 12;  'VCM top 1', 0, 56, 12;  'VCM top 1', 94, 56, 12;
         'VCM top 2', -94, 80, 12;  'VCM top 2', 94, 80, 12;
         'VCM bot 1', -94, yb, 12;  'VCM bot 1', 0, yb, 12;  'VCM bot 1', 94, yb, 12;
         'VCM bot 2', -94, yb-24, 12;  'VCM bot 2', 94, yb-24, 12};
nz = size(zbars, 1);
for i = 1:6                            % new items against everything
    for j = i+1:nz
        cl = hypot(zbars{i,2} - zbars{j,2}, zbars{i,3} - zbars{j,3}) - (zbars{i,4} + zbars{j,4})/2;
        if cl < 25                     % ACI 25.2.1: max(25, db, 4/3 dagg) for parallel bars
            fprintf('  parallel  %-9s (%4.0f,%4.0f) - %-9s (%4.0f,%4.0f): clear %5.1f\n', zbars{i,1}, ...
                    zbars{i,2}, zbars{i,3}, zbars{j,1}, zbars{j,2}, zbars{j,3}, cl);
        end
    end
end
% crossing bars along x: VCS top/bottom rows and the hoop layers
xlev = [68, h_beam - 68, hoop_y];
xnam = [{'VCS top', 'VCS bot'}, repmat({'hoop'}, 1, numel(hoop_y))];
xd   = [12, 12, db_hoop*ones(1, numel(hoop_y))];
for i = 1:6
    for j = 1:numel(xlev)
        cl = abs(zbars{i,3} - xlev(j)) - (zbars{i,4} + xd(j))/2;
        if cl < 10
            fprintf('  crossing  %-9s y=%4.0f - %-8s y=%4.0f: clear %5.1f\n', zbars{i,1}, zbars{i,3}, xnam{j}, xlev(j), cl);
        end
    end
end
% steel-column anchors (vertical) against the bars along z, in plan
for i = 1:6
    cl = min(abs(abs(zbars{i,2}) - abs(x_sc))) - (zbars{i,4} + d_sc)/2;
    if cl < 25
        fprintf('  plan      %-9s x=%4.0f - steel-column anchor x=%4.0f: clear %5.1f\n', zbars{i,1}, zbars{i,2}, x_sc(2), cl);
    end
end
fprintf('  head plates %0.f x %0.f: x from %.0f to %.0f (column mid bar to x = %.0f); z from %.0f to %.0f\n', ...
        a_hd, a_hd, g/2 - a_hd/2, g/2 + a_hd/2, db_col/2, hef, hef + t_hd);
fprintf('  VCS back top bar outer face z = %.0f -> clear to head plate %.0f\n', col_b/2 + bw_beam/2 - c_beam + 6, ...
        hef - (col_b/2 + bw_beam/2 - c_beam + 6));
L_rod = z_tip + t_grout + tp + t_wsh + h_nut + proj;
fprintf('  rod length = %.0f mm (tip at z = %.0f, through %0.f grout + %0.f plate + washer + nut)\n\n', ...
        L_rod, z_tip, t_grout, tp);

% -------------------------------------------------------------------------
% MODULE 3: DG 39 TESTED GEOMETRY RANGE (Table 5-1, +/-10 %, Sec. 5.2.1)
% -------------------------------------------------------------------------
fprintf('--- 3. DG 39 TABLE 5-1 TESTED RANGE (+/-10%%), two-bolt flush ---\n');
geo_rng = {'pfi', pfi, 1+5/16, 2.25;  'g', g, 2.25, 4.5;  'd', h, 8, 24;
           'bp', bp, 5, 14;  'tf', tf, 3/16, 0.75};
for i = 1:size(geo_rng, 1)
    lo = 0.9*geo_rng{i,3}*in;  hi = 1.1*geo_rng{i,4}*in;
    ok = geo_rng{i,2} >= lo && geo_rng{i,2} <= hi;
    fprintf('  %-4s = %6.1f mm   range %6.1f - %6.1f mm   %s\n', geo_rng{i,1}, geo_rng{i,2}, lo, hi, iif(ok, 'OK', 'OUT OF RANGE'));
end
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 4: COMPRESSION SIDE - DG 1 BEARING + PLATE (ACI 22.8.3.2)
% -------------------------------------------------------------------------
phi_c = 0.65;                          % bearing, ACI Table 21.2.1
h1 = h - tf/2 - y_t;                   % DG 39: tension row to compression flange centre
D  = h + ext - y_t;                    % tension row to plate bottom edge
side = (col_b - bp)/2;                 % plate edge to column side face
pb = struct('Mu', Mu, 'D', D, 'bp', bp, 'fp', NaN, 'ext', ext, 'd', h, 'bf', bf, 'Fyp', Fyp);
k_conf = 2.0;
for it = 1:20
    pb.fp = phi_c * 0.85 * fc * k_conf;
    b1 = dg1_bearing(pb);
    if ~b1.ok, break; end
    x2 = min(side, (h + ext - b1.Y) - col_top);   % frustum spread: sides, column top (no edge below)
    k_new = min(2, sqrt((bp + 2*x2)*(b1.Y + 2*x2)/(bp*b1.Y)));
    if abs(k_new - k_conf) < 1e-6, break; end
    k_conf = k_new;
end
fp = pb.fp;
fprintf('--- 4. COMPRESSION SIDE (DG 1 Sec. 3.4, Pr = 0; ACI 22.8.3.2) ---\n');
fprintf('  fp = 0.65*0.85*fc*sqrt(A2/A1) = %.2f MPa (sqrt(A2/A1) = %.2f); grout >= 2fc assumed (DG 1 Sec. 3.1)\n', fp, k_conf);
S(end+1,:) = print_check('Bearing solution exists (D^2 >= 2Mu/(fp bp))', 2*Mu/(fp*bp), D^2, 'mm2', 'DG1 Eq. 3.4.4');
fprintf('  Y = %.1f mm, C = %.1f kN, arm = D - Y/2 = %.1f mm (DG 39 h1 = %.1f mm)\n', b1.Y, b1.C/1e3, b1.arm, h1);
fprintf('  m = %.1f mm -> t = %.2f mm (%s);  n = %.1f mm -> t = %.2f mm\n', b1.m, b1.t_m, ...
        iif(b1.Y >= b1.m, 'Eq. 3.3.14a-1', 'Eq. 3.3.15a-1'), b1.n, b1.t_n);
S(end+1,:) = print_check('Plate, compression side (m, n strips)', b1.t_req, tp, 'mm', 'DG1 3.3.14a-1/15a-1');
fprintf('  Info, t required vs ext:  ');
for e = [10 15 20 25 30]
    pe = pb;  pe.ext = e;  pe.D = h + e - y_t;  be = dg1_bearing(pe);
    fprintf('ext %2d -> %5.2f   ', e, be.t_req);
end
fprintf('\n\n');
arm = min(h1, b1.arm);                 % conservative lever arm for the rods

% -------------------------------------------------------------------------
% MODULE 5: ROD TENSION (AISC J3.6 / DG 39 Table 5-2; ACI 17.6.1)
% -------------------------------------------------------------------------
Fnt = 0.75 * Fu_rod;                   % AISC Table J3.2, threaded parts
futa = min([Fu_rod, 1.9*Fy_rod, 860]); % ACI 17.6.1.2
T_rod = Mu / arm / 2;                  % 2 rods in the tension row
fprintf('--- 5. ROD TENSION (arm = %.1f mm, T per rod = %.1f kN) ---\n', arm, T_rod/1e3);
S(end+1,:) = print_check('Rod rupture, no prying: 2*phi*Pt*h1 (thick plate)', Mu/1e6, 0.75*2*Fnt*Ab*h1/1e6, 'kNm', 'DG39 Tab.5-2; J3-1');
S(end+1,:) = print_check('Rod tension, real arm', T_rod/1e3, 0.75*Fnt*Ab/1e3, 'kN', 'AISC J3-1, Table J3.2');
S(end+1,:) = print_check('Anchor steel in tension phi*Nsa', T_rod/1e3, 0.75*Ase*futa/1e3, 'kN', 'ACI 17.6.1.2, T.17.5.3(a)');
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 6: END PLATE, TENSION SIDE (DG 39 Table 5-2, Eq. 5-4a: thick plate)
% -------------------------------------------------------------------------
s = sqrt(bp*g)/2;
pfi_c = min(pfi, s);                   % Table 5-2 note
Yp = (bp/2)*(h1*(1/pfi_c + 1/s)) + (2/g)*(h1*(pfi_c + s));
gamma_r = 0.80;                        % (5-1) flush
t_req_54 = sqrt(1.10*Mu/(gamma_r*0.90*Fyp*Yp));
fprintf('--- 6. END PLATE, TENSION SIDE (DG 39), s = %.1f mm, Yp = %.1f mm ---\n', s, Yp);
S(end+1,:) = print_check('End-plate yielding phi*Mpl', Mu/1e6, 0.90*Fyp*tp^2*Yp/1e6, 'kNm', 'DG39 Tab.5-2');
S(end+1,:) = print_check('Plate thickness, thick plate (no prying)', t_req_54, tp, 'mm', 'DG39 Eq. 5-4a, 5-1');
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 7: ROD SHEAR (compression-side rods take Vu, DG 39 Sec. 3.1 p. 49)
% -------------------------------------------------------------------------
V_rod = Vu / 2;
Fnv = 0.450 * Fu_rod;                  % Table J3.2, threads not excluded
lc  = (y_s - y_t) - dh;                % plate pushed down: clear distance to the hole above
Rn_br = min(1.2*lc*tp*Fup, 2.4*d_b*tp*Fup);
fprintf('--- 7. ROD SHEAR (V per rod = %.1f kN) ---\n', V_rod/1e3);
S(end+1,:) = print_check('Rod shear (AISC, Fnv = 0.450Fu)', V_rod/1e3, 0.75*Fnv*Ab/1e3, 'kN', 'AISC J3-1, Table J3.2');
S(end+1,:) = print_check('Anchor steel in shear, grout pad x0.80', V_rod/1e3, 0.65*0.80*0.6*Ase*futa/1e3, 'kN', 'ACI 17.7.1.2b, 17.7.1.2.1');
S(end+1,:) = print_check('Bearing / tearout at plate hole', V_rod/1e3, 0.75*Rn_br/1e3, 'kN', 'AISC J3-6a, J3-6c');
fprintf('  Info, friction (DG 1 Sec. 3.5.1, mu = 0.40): phi*mu*C = %.1f kN vs Vu = %.1f kN (not counted)\n\n', ...
        0.75*0.40*b1.C/1e3, Vu/1e3);

% -------------------------------------------------------------------------
% MODULE 8: ANCHORS IN CONCRETE, TENSION (ACI 17.6) + ANCHOR REINFORCEMENT
% -------------------------------------------------------------------------
fprintf('--- 8. TENSION ANCHORS IN CONCRETE (hef = %.0f mm) ---\n', hef);
Abrg = a_hd^2 - pi*d_b^2/4;
Np = 8 * Abrg * fc;                    % (17.6.3.2.2a)
S(end+1,:) = print_check('Pullout of the head plate', T_rod/1e3, 0.70*psi_cP*Np/1e3, 'kN', 'ACI 17.6.3.2.2a, T.17.5.3(c)');
ca_top = y_t - col_top;  ca_side = col_b/2 - g/2;
ca1 = min(ca_top, ca_side);
if hef > 2.5*ca1
    Nsb = 13*ca1*sqrt(Abrg)*lambda*sqrt(fc);
    S(end+1,:) = print_check('Side-face blowout', T_rod/1e3, 0.70*Nsb/1e3, 'kN', 'ACI 17.6.4.1');
else
    fprintf('  Side-face blowout: hef = %.0f <= 2.5ca1 = %.0f mm -> not applicable (17.6.4.1)\n', hef, 2.5*ca1);
end
bk = aci_tension_breakout(hef, g, 0, 2, [ca_side ca_side ca_top Inf], fc, lambda, psi_cN);
fprintf('  Info, plain-concrete breakout: 3 edges < 1.5hef -> hef'' = %.0f mm (17.6.2.1.2);\n', bk.hef_used);
fprintf('        phi*Ncbg = %.1f kN vs 2T = %.1f kN -> replaced by anchor reinforcement (17.5.2.1(a))\n', ...
        0.70*bk.Ncbg/1e3, 2*T_rod/1e3);
% anchor reinforcement (bastones): strength, position, development both sides
As_bst = n_bst * pi*db_bst^2/4;
S(end+1,:) = print_check('Anchor reinforcement, 2 bastones', 2*T_rod/1e3, 0.75*As_bst*fy_bar/1e3, 'kN', 'ACI 17.5.2.1(a), 17.5.3');
r_bst = hypot(x_bst - g/2, y_bst - y_t);        % to the nearest tension rod
S(end+1,:) = print_check('Baston within 0.5hef of the rod', r_bst, 0.5*hef, 'mm', 'ACI R17.5.2.1');
fprintf('  Info: with the edge-reduced hef'' = %.0f mm the limit would be %.1f mm (PENDIENTE).\n', bk.hef_used, 0.5*bk.hef_used);
z_c = hef - r_bst/1.5;                 % where the baston crosses the 35 deg breakout surface
dl = aci_dev_lengths(db_bst, fy_bar, fc, lambda, psi_t_bst, ld_good, 1.0, 1.0);
fprintf('  baston at (%.0f, %.0f): r = %.1f mm, crosses the breakout surface at z = %.0f mm\n', x_bst, y_bst, r_bst, z_c);
fprintf('  (psi_r = 1.0: hook spacing %.0f >= 6db; psi_o = 1.0: inside the core, side cover %.0f >= 65; psi_c = %.2f)\n', ...
        2*x_bst, col_b/2 - x_bst - db_bst/2, dl.psi_c);
S(end+1,:) = print_check('Baston hook side: ldh <= z_c - z_hook', dl.ldh, z_c - z_hook, 'mm', 'ACI 25.4.3.1, T.25.4.3.2');
z_end = z_c + dl.ld;
fprintf('  Straight side: ld = %.0f mm (Table 25.4.2.3, %s, psi_t = %.1f) -> bar end at z >= %.0f mm,\n', ...
        dl.ld, iif(ld_good, 'good', 'other cases'), psi_t_bst, z_end);
fprintf('  i.e. %.0f mm past the column back face into the VCM; baston straight length >= %.0f mm from the hook face.\n\n', ...
        z_end - col_b, z_end - z_hook);

% -------------------------------------------------------------------------
% MODULE 9: SHEAR ANCHORS IN CONCRETE (ACI 17.7)
% -------------------------------------------------------------------------
fprintf('--- 9. SHEAR ANCHORS IN CONCRETE ---\n');
bv = aci_tension_breakout(hef, g, 0, 2, [ca_side ca_side y_s - col_top Inf], fc, lambda, psi_cN);
kcp = 2.0;                             % hef >= 65 mm
S(end+1,:) = print_check('Pryout, shear row (Ncpg = Ncbg)', Vu/1e3, 0.70*kcp*bv.Ncbg/1e3, 'kN', 'ACI 17.7.3.1b, T.17.5.3(c)');
fprintf('  (hef'' = %.0f mm). Breakout in shear 17.7.2: no free edge below (column continues,\n', bv.hef_used);
fprintf('  cold joint at the beam soffit ignored, agreed) -> not applicable.\n');
fprintf('  Interaction 17.8: tension rods carry no shear, shear rods no tension (DG 39) -> not applicable.\n\n');

% -------------------------------------------------------------------------
% MODULE 10: HEAD PLATES (bending, DG 1-type cantilever from the washer)
% -------------------------------------------------------------------------
q_hd = T_rod / Abrg;
l_hd = (a_hd - dw)/2;
fprintf('--- 10. HEAD PLATES %0.fx%0.fx%0.f A36 (washer OD %0.f) ---\n', a_hd, a_hd, t_hd, dw);
S(end+1,:) = print_check('Head plate bending (full-width cantilever)', q_hd*a_hd*l_hd^2/2/1e3, 0.90*Fyp*a_hd*t_hd^2/4/1e3, 'kN*mm', 'DG1-type strip, J4 (assumed)');
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 11: SPACING AND EDGE DISTANCES (AISC J3.3, J3.4; ACI 17.9)
% -------------------------------------------------------------------------
fprintf('--- 11. SPACING AND EDGE DISTANCES ---\n');
S(end+1,:) = print_check('AISC min spacing, gage (2 2/3 d)', 8/3*d_b, g, 'mm', 'AISC J3.3');
S(end+1,:) = print_check('AISC min spacing, rows (2 2/3 d)', 8/3*d_b, y_s - y_t, 'mm', 'AISC J3.3');
S(end+1,:) = print_check('AISC min edge, plate side', 22, (bp - g)/2, 'mm', 'AISC Table J3.4M');
S(end+1,:) = print_check('AISC min edge, plate top', 22, y_t, 'mm', 'AISC Table J3.4M');
S(end+1,:) = print_check('AISC min edge, plate bottom', 22, h + ext - y_s, 'mm', 'AISC Table J3.4M');
S(end+1,:) = print_check('ACI min spacing 4da (not torqued)', 4*d_b, min(g, y_s - y_t), 'mm', 'ACI Table 17.9.2(a)');
S(end+1,:) = print_check('ACI min edge = cover (column top, sides)', cover, min(ca_top, ca_side) - d_b/2, 'mm', 'ACI Table 17.9.2(a)');
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 12: IPE 240 SHEAR AT THE CONNECTION (AISC G2)
% -------------------------------------------------------------------------
fprintf('--- 12. IPE 240 SHEAR ---\n');
if h_web/tw > 2.24*sqrt(E/Fy), error('h/tw > 2.24sqrt(E/Fy): use G2.1(b)'); end
S(end+1,:) = print_check('Shear yielding (phi = 1.0, Cv1 = 1.0)', Vu/1e3, 0.6*Fy*h*tw/1e3, 'kN', 'AISC G2-1, G2.1(a)');
fprintf('  Member flexure / LTB of the cantilever: from the frame model (PENDIENTE).\n\n');

% -------------------------------------------------------------------------
% MODULE 13: WELDS (AISC 360-16 J2, J4; DG 39 Sec. 3.7.5)
% -------------------------------------------------------------------------
fprintf('--- 13. WELDS (E70XX, FEXX = %.0f MPa) ---\n', FEXX);
Ru_fl = max(Mu/(h - tf), 0.60*Fy*bf*tf);          % DG39 (3-38a)
S(end+1,:) = print_check('CJP top flange, base metal', Ru_fl/1e3, 0.90*Fy*bf*tf/1e3, 'kN', 'Table J2.5, J4-1; DG39 3-38a');
L_fl = bf + (bf - tw - 2*r_fil);
kds  = 1.5;                                        % (J2-5), theta = 90 deg
S(end+1,:) = print_check('Bottom flange fillet min size', 5, w_fl, 'mm', 'AISC Table J2.4');
S(end+1,:) = print_check('Bottom flange fillet max size (t-2)', w_fl, tf - 2, 'mm', 'AISC J2.2b');
S(end+1,:) = print_check('Bottom flange fillet (designed for Ru)', Ru_fl/1e3, 0.75*0.60*FEXX*kds*0.707*w_fl*L_fl/1e3, 'kN', 'AISC J2-4, J2-5');
Tuw = Mu/(h - tf);                                 % (3-39), (3-40)
lwt = min(pfi + 6*in, h - 2*tf);
Tuwd = max(Tuw, 0.60*Fy*tw*lwt);                   % (3-41a)
S(end+1,:) = print_check('Web tension yielding near tension rods', Tuw/1e3, 0.90*Fy*tw*lwt/1e3, 'kN', 'DG39 3-40; J4-1');
S(end+1,:) = print_check('Web weld, tension region', Tuwd/1e3, 0.75*2*0.60*FEXX*0.707*w_web*lwt*kds/1e3, 'kN', 'DG39 3-41a; J2-4, J2-5');
lwv = min(h - 2*tf - lwt, h/2 - tf);
if lwv <= 0, error('no web weld left for shear: use the combined check of the sandwich script'); end
S(end+1,:) = print_check('Web weld, shear region', Vu/1e3, 0.75*2*0.60*FEXX*0.707*w_web*lwv/1e3, 'kN', 'J2-4 (theta = 0)');
S(end+1,:) = print_check('Web shear rupture at weld', Vu/1e3, 0.75*0.60*Fu*lwv*tw/1e3, 'kN', 'AISC J4-4');
fprintf('\n');

% -------------------------------------------------------------------------
% MODULE 14: BEAM-COLUMN JOINT (ACI 318-19 Ch. 15), ordinary frame
% -------------------------------------------------------------------------
fprintf('--- 14. JOINT (ACI Ch. 15, %s frame) ---\n', frame);
% Joint shear from the beam top-bar tension (15.4.1.1(a)); the opposite
% member and the column shear would reduce it: not counted (conservative).
Aj = col_b * min([col_b, bw_beam + col_b, 2*col_b/2]);         % 15.4.2.4
d_VCM = h_beam - (3*c_beam + 2*(c_beam + 24))/nb_VCM_top;       % centroid of 5 top bars
d_VCS = h_beam - (c_beam + 12);                                 % VCS top bars at y = 68
Tb = @(M, d) 0.85*fc*bw_beam*(d - sqrt(d^2 - 2*M/(0.85*fc*bw_beam)));   % T = C, rect. block
T_z = Tb(Mu_VCM, d_VCM);  T_x = Tb(max(Mu_VCS), d_VCS);
% Table 15.4.2.3: column "other" (extends 105 mm < h above, 15.2.6);
%   z (VCM): beam "other", confined by VCS on both faces (15.2.8) -> 15 (in-lb) = 1.25 (SI)
%   x (VCS): beam continuous, not confined (steel cantilever)       -> 15 (in-lb) = 1.25 (SI)
Vn_j = 1.25 * lambda * sqrt(fc) * Aj;
fprintf('  Aj = %.0f mm2; T(VCM top) = %.1f kN (d = %.0f), T(VCS top) = %.1f kN (d = %.0f)\n', Aj, T_z/1e3, d_VCM, T_x/1e3, d_VCS);
S(end+1,:) = print_check('Joint shear, VCM / cantilever direction', T_z/1e3, 0.75*Vn_j/1e3, 'kN', 'ACI 15.4.2, T.15.4.2.3');
S(end+1,:) = print_check('Joint shear, VCS direction', T_x/1e3, 0.75*Vn_j/1e3, 'kN', 'ACI 15.4.2, T.15.4.2.3');
% transverse reinforcement: not confined in x -> 15.3.1.2 to 15.3.1.4 apply
n_in = sum(hoop_y > 0 & hoop_y < h_beam);
fprintf('  Hoop layers within the beam depth: %d (>= 2 required) -> %s [ACI 15.3.1.3]\n', n_in, iif(n_in >= 2, 'OK', 'NOT OK'));
S(end+1,:) = print_check('Joint hoop spacing (incl. to top/soffit)', max(diff([0, sort(hoop_y), h_beam])), 200, 'mm', 'ACI 15.3.1.4 (8 in.)');
fprintf('  Hoop levels must clear the rods (y = %.0f, %.0f) and bastones (y = %.0f) by >= %.0f mm\n', ...
        y_t, y_s, y_bst, (d_b + db_hoop)/2);
fprintf('  Column bars phi16 end with standard hooks turned toward the column centre (15.3.3.2).\n\n');

% -------------------------------------------------------------------------
% MODULE 15: NOT APPLICABLE / NOT CHECKED HERE
% -------------------------------------------------------------------------
fprintf('--- 15. NOT APPLICABLE / NOT CHECKED HERE ---\n');
fprintf('  Shear breakout (no edge below), tension-shear interaction (separate rows), prying\n');
fprintf('  (thick plate by Eq. 5-4a). Beams VCM/VCS and column design, steel-column anchors\n');
fprintf('  (uplift), IPE member flexure: outside this script (see PENDIENTE).\n\n');

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
