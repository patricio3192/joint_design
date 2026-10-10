function R = check_sandwich_column(P)
% CHECK_SANDWICH_COLUMN  "Sandwich" connection on a concrete COLUMN: two steel
% I beams on opposite faces of the column, in one line, with flush end plates
% tied together by through-rods cast across the column. The face with the
% larger moment is checked (the other face's shear on the same rods), plus the
% opposite plate pressed against its face by the rod tension, and the joint
% shear of the column (ACI Ch. 15). Steel side and bearing as
% lib/sandwich_concrete (same equations, same helpers).
% AISC 360-16, AISC DG 39 (2023), DG 1 (2nd ed.), ACI 318-19 (SI). Equations: EQUATIONS.txt.
%
%   R = check_sandwich_column(P)
%
% Prints the report (modules 1-11 and the summary) and returns R.checks
% {name, ratio; ...}, R.governing, R.ratio, R.arm (real lever arm), R.h1,
% R.k_conf, R.T_rod (per rod), R.dT_B (rod tension pressed on the other face),
% R.Vj (joint shear), R.L_rod (rod length).
% Units: N, mm, MPa (moments in kN*m, shears in kN).
%
% P fields (examples/example_sandwich_column.m is a complete input):
%   load    Mu_A_kNm, Vu_A_kN, Mu_B_kNm, Vu_B_kN  both faces, top in tension (>= 0)
%   beam    name, h, bf, tf, tw, r_fil, h_web, Zx, Sx, Iy (WEAK axis), ry, J, Fy, Fu,
%           E, L_span, L_brace (same beam on both faces). Build it with
%           aisc_beam('IPE 200', Fy, Fu) (lib/profiles) and add L_span, L_brace.
%   column  b (face width, along the plates), h (depth = rod length in concrete),
%           top (column top above the top of the beams; Inf if it continues),
%           fc, fy_bar, lambda, cover (specified), db_hoop, db_bar, hoop_y (tie
%           levels in the joint, y down from the top of the beams), gamma (ACI
%           Table 15.4.2.3 coefficient in SI = in-lb value x 0.083; the user
%           picks the row: ask, do not assume)
%   plate   tp, bp, ext (below the bottom flange; top flush), Fyp, Fup, t_grout
%   rods    d_b, Fu, dh, dist_top (tension row), g (gage), dist_bot (shear row),
%           torqued, splitting_reinf (true only if ties or stirrups enclose the
%           rods right next to them, ACI 17.9.1: then the 17.9.2 spacing is
%           waived; engineer's call), t_wsh, h_nut, dw, nw, proj (nut data)
%   weld    FEXX, top_cjp, S_pjp, pjp_flat, w_fl, w_web
% Limits: lib/sandwich_column/CLAUDE.md.

  % ---- unpack ---------------------------------------------------------------------
  MA = P.load.Mu_A_kNm*1e6;  MB = P.load.Mu_B_kNm*1e6;
  if MA < 0 || MB < 0, error('both moments must put the top in tension (see CLAUDE.md)'); end
  if MA >= MB, gov = 'A'; Mu = MA; Mo = MB; Vu = P.load.Vu_A_kN*1e3; Vu_other = P.load.Vu_B_kN*1e3;
  else,        gov = 'B'; Mu = MB; Mo = MA; Vu = P.load.Vu_B_kN*1e3; Vu_other = P.load.Vu_A_kN*1e3; end
  b = P.beam;  h = b.h;  bf = b.bf;  tf = b.tf;  tw = b.tw;  h_web = b.h_web;
  Fy = b.Fy;  E = b.E;
  C = P.column;  fc = C.fc;  lambda = C.lambda;
  tp = P.plate.tp;  bp = P.plate.bp;  ext = P.plate.ext;  Fyp = P.plate.Fyp;  Fup = P.plate.Fup;
  r = P.rods;  d_b = r.d_b;  Ab = pi*d_b^2/4;  dh = r.dh;
  dist_top = r.dist_top;  dist_bot = r.dist_bot;  g = r.g;  pfi = dist_top - tf;
  in = 25.4;  phi_c = 0.65;
  S = cell(0, 2);
  L_rod = C.h + 2*(P.plate.t_grout + tp + r.t_wsh + r.h_nut + r.proj);

  fprintf('==============================================================\n');
  fprintf('  LIMIT STATES - SANDWICH ON A CONCRETE COLUMN %gx%g, %s both faces\n', C.b, C.h, b.name);
  fprintf('  (AISC 360-16 / DG 39 / DG 1 / ACI 318-19)\n');
  fprintf('==============================================================\n');
  fprintf('  Governing face %s: Mu = %.1f kNm, Vu = %.1f kN; other face Mu = %.1f kNm, Vu = %.1f kN\n\n', ...
          gov, Mu/1e6, Vu/1e3, Mo/1e6, Vu_other/1e3);

  % ---- 1. DG 39 tested range ----------------------------------------------------------
  fprintf('--- 1. DG 39 TABLE 5-1 TESTED RANGE (+/-10%%), two-bolt flush ---\n');
  geo_rng = {'pf (pfi)', pfi, 1+5/16, 2.25;  'g', g, 2.25, 4.5;  'd', h, 8, 24;
             'bp', bp, 5, 14;  'tf', tf, 3/16, 0.75};
  for i = 1:size(geo_rng, 1)
    lo = 0.9*geo_rng{i,3}*in;  hi = 1.1*geo_rng{i,4}*in;
    ok = geo_rng{i,2} >= lo && geo_rng{i,2} <= hi;
    fprintf('  %-9s = %6.1f mm   range %6.1f - %6.1f mm   %s\n', geo_rng{i,1}, geo_rng{i,2}, lo, hi, iif(ok, 'OK', 'OUT OF RANGE'));
  end
  fprintf('\n');

  % ---- 2. compression side of the governing face (strict strips) ------------------------
  h1 = h - tf/2 - dist_top;  D = h + ext - dist_top;
  side = (C.b - bp)/2;                         % plate edge to the column side face
  p = struct('bp', bp, 'bf', bf, 'tf', tf, 'tw', tw, 'h', h, 'ext', ext, 'tp', tp, 'Fyp', Fyp, ...
             'phi_b', 0.90, 'fp', NaN, 'D', D, 'Mu', Mu, 'holes_y', h + ext - dist_bot, ...
             'holes_x', [-g/2 g/2], 'dh', dh);
  [bs, k_conf, A1, A2] = strips(p, phi_c, fc, side, C);
  p.fp = phi_c*0.85*fc*k_conf;  fp = p.fp;
  fprintf('--- 2. COMPRESSION SIDE, FACE %s (DG 1 + ACI 22.8.3.2, strict strips) ---\n', gov);
  fprintf('  h1 (DG 39) = %.1f mm;  D = %.1f mm;  plate edge to column side = %.0f mm\n', h1, D, side);
  fprintf('  fp = 0.65*0.85*fc*sqrt(A2/A1) = %.2f MPa (sqrt(A2/A1) = %.2f; A1 = %.0f, A2 = %.0f mm2)\n', fp, k_conf, A1, A2);
  S(end+1,:) = print_check('Bearing: moment carried by compression zone', Mu/1e6, bs.Mmax/1e6, 'kNm', 'DG1 3.4.1 / ACI 22.8.3.2');
  if ~bs.ok, error('the compression zone cannot carry Mu: thicker plate or larger bp'); end
  fprintf('  c = %.1f mm; C = %.1f kN at %.1f mm from the plate bottom -> real arm = %.1f mm\n', bs.c, bs.C/1e3, bs.ybar, bs.arm);
  S(end+1,:) = print_check('Plate strip below flange (ext <= c)', ext, bs.c, 'mm', 'DG1 Eq. 3.3.14a-1');
  S(end+1,:) = print_check('Plate strip beyond flange tip ((bp-bf)/2 <= c)', (bp - bf)/2, bs.c, 'mm', 'DG1 Eq. 3.3.14a-1');
  arm = bs.arm;
  if arm < h1, fprintf('  FLAG: real arm %.1f < DG 39 h1 %.1f: rods also checked with the real arm.\n', arm, h1); end
  fprintf('\n');

  % ---- 3. rod tension ----------------------------------------------------------------
  Fnt = 0.75*r.Fu;  Fnv = 0.450*r.Fu;
  T_rod = Mu/arm/2;
  fprintf('--- 3. ROD TENSION (A193 B7: Fnt = 0.75Fu = %.0f MPa; anchored by the opposite plate) ---\n', Fnt);
  S(end+1,:) = print_check('Rod tension, DG 39 arm h1', Mu/h1/2/1e3, 0.75*Fnt*Ab/1e3, 'kN', 'J3-1, Table J3.2; DG39 Tab.5-2');
  S(end+1,:) = print_check('Rod tension, real arm (strict strips)', T_rod/1e3, 0.75*Fnt*Ab/1e3, 'kN', 'J3-1, Table J3.2');
  fprintf('\n');

  % ---- 4. end plate, tension side ------------------------------------------------------
  s = sqrt(bp*g)/2;  pfi_c = min(pfi, s);
  Yp = (bp/2)*(h1*(1/pfi_c + 1/s)) + (2/g)*(h1*(pfi_c + s));
  fprintf('--- 4. END PLATE, TENSION SIDE (DG 39), s = %.1f mm, Yp = %.1f mm ---\n', s, Yp);
  S(end+1,:) = print_check('End-plate yielding phi*Mpl (Table 5-2)', Mu/1e6, 0.90*Fyp*tp^2*Yp/1e6, 'kNm', 'DG39 Tab.5-2');
  S(end+1,:) = print_check('Plate thickness, thick plate Eq. 5-4a', sqrt(1.10*Mu/(0.80*0.90*Fyp*Yp)), tp, 'mm', 'DG39 Eq.5-4a, 5-1');
  fprintf('  Info: Eq. 5-5a (thin plate, needs prying check) t_req = %.2f mm\n\n', sqrt(Mu/(0.80*0.90*Fyp*Yp)));

  % ---- 5. rod shear and plate bearing ----------------------------------------------------
  V_rod = max(Vu, Vu_other)/2;
  lc = (dist_bot - dist_top) - dh;
  Rn_br = min(1.2*lc*tp*Fup, 2.4*d_b*tp*Fup);
  fprintf('--- 5. ROD SHEAR AND PLATE BEARING (V per rod = %.1f kN) ---\n', V_rod/1e3);
  S(end+1,:) = print_check('Rod shear (Fnv = 0.450Fu)', V_rod/1e3, 0.75*Fnv*Ab/1e3, 'kN', 'J3-1, Table J3.2');
  S(end+1,:) = print_check('Bearing / tearout at plate hole', V_rod/1e3, 0.75*Rn_br/1e3, 'kN', 'J3-6a, J3-6c');
  fprintf('\n');

  % ---- 6. the other face: its plate pressed by the rod tension (own model) -------------------
  if Mo > 0
    po = p;  po.Mu = Mo;  bo = strips(po, phi_c, fc, side, C);
    T_o = Mo/bo.arm;
  else
    T_o = 0;
  end
  dT = 2*T_rod - T_o;                          % rod pull not balanced by the other beam's top flange
  q = struct('bp', bp, 'bf', bf, 'tf', tf, 'tw', tw, 'tp', tp, 'Fyp', Fyp, 'phi_b', 0.90, 'fp', NaN, ...
             'holes_y', dist_top, 'holes_x', [-g/2 g/2], 'dh', dh);
  band = 2*dist_top;                           % band centred on the tension rods
  k_t = conf_factor(bp, band, side, min(side, C.top), C.h);
  q.fp = phi_c*0.85*fc*k_t;
  tb = top_band_bearing(q, band);
  fprintf('--- 6. OTHER FACE: PLATE PRESSED BY THE RODS (own model, EQUATIONS.txt) ---\n');
  fprintf('  rods pull 2T = %.1f kN; the other beam''s top flange takes %.1f kN; the rest\n', 2*T_rod/1e3, T_o/1e3);
  fprintf('  dT = %.1f kN bears on the column through the plate band 0-%.0f mm from the top\n', dT/1e3, band);
  fprintf('  (strict strips, c = %.1f mm, A = %.0f mm2, fp = %.2f MPa, sqrt(A2/A1) = %.2f)\n', tb.c, tb.A, q.fp, k_t);
  if dT > 0
    S(end+1,:) = print_check('Other face: bearing of the top band', dT/1e3, tb.C/1e3, 'kN', 'ACI 22.8.3.2; own band');
  else
    fprintf('  dT <= 0: the other face top is not pressed.\n');
  end
  fprintf('\n');

  % ---- 7. spacing and edge distances ----------------------------------------------------------
  fprintf('--- 7. SPACING AND EDGE DISTANCES ---\n');
  S(end+1,:) = print_check('AISC min spacing, gage (2 2/3 d)', 8/3*d_b, g, 'mm', 'AISC J3.3');
  S(end+1,:) = print_check('AISC min spacing, rows (2 2/3 d)', 8/3*d_b, dist_bot - dist_top, 'mm', 'AISC J3.3');
  S(end+1,:) = print_check('AISC min edge, plate side', 22, (bp - g)/2, 'mm', 'AISC Table J3.4M');
  S(end+1,:) = print_check('AISC min edge, plate top', 22, dist_top, 'mm', 'AISC Table J3.4M');
  S(end+1,:) = print_check('AISC min edge, plate bottom', 22, h + ext - dist_bot, 'mm', 'AISC Table J3.4M');
  s_aci = iif(r.torqued, 6, 4)*d_b;
  if min(g, dist_bot - dist_top) < s_aci && r.splitting_reinf
    fprintf('  ACI min spacing %.0f mm not met; WAIVED per ACI 17.9.1 by supplementary reinforcement\n', s_aci);
    fprintf('  (column ties next to the rods). ACI gives no sizing rule: engineering judgment.\n');
  else
    S(end+1,:) = print_check(sprintf('ACI min spacing %dda', iif(r.torqued, 6, 4)), s_aci, min(g, dist_bot - dist_top), 'mm', 'ACI Table 17.9.2(a)');
  end
  e_min = iif(r.torqued, 6*d_b, C.cover);
  S(end+1,:) = print_check('ACI min edge, rods to column side (clear)', e_min, C.b/2 - g/2 - d_b/2, 'mm', 'ACI Table 17.9.2(a)');
  if isfinite(C.top)
    S(end+1,:) = print_check('ACI min edge, top rods to column top (clear)', e_min, C.top + dist_top - d_b/2, 'mm', 'ACI Table 17.9.2(a)');
  end
  fprintf('\n');

  % ---- 8. steel beam ----------------------------------------------------------------
  fprintf('--- 8. %s: FLEXURE AND SHEAR ---\n', b.name);
  fprintf('  bf/2tf = %.2f <= 0.38sqrt(E/Fy) = %.2f; h/tw = %.1f <= 3.76sqrt(E/Fy) = %.1f (Table B4.1b)\n', ...
          bf/(2*tf), 0.38*sqrt(E/Fy), h_web/tw, 3.76*sqrt(E/Fy));
  if bf/(2*tf) > 0.38*sqrt(E/Fy) || h_web/tw > 3.76*sqrt(E/Fy), error('beam not compact: F2 does not apply'); end
  for Lb = [b.L_brace, b.L_span]
    f2 = aisc_f2_ltb(E, Fy, b.Zx, b.Sx, b.Iy, b.J, h - tf, b.ry, Lb, 1.0);
    S(end+1,:) = print_check(sprintf('Flexure LTB, Lb = %.1f m, Cb = 1', Lb/1000), Mu/1e6, 0.9*f2.Mn/1e6, 'kNm', 'AISC F2-1..F2-6');
  end
  if h_web/tw > 2.24*sqrt(E/Fy), error('h/tw > 2.24sqrt(E/Fy): use G2.1(b)'); end
  S(end+1,:) = print_check('Shear yielding', Vu/1e3, 0.6*Fy*h*tw/1e3, 'kN', 'AISC G2-1, G2-2');
  fprintf('\n');

  % ---- 9. welds ----------------------------------------------------------------
  S = [S; end_plate_welds(Mu, Vu, b, P.weld, ext, pfi, 9)];

  % ---- 10. joint (ACI Ch. 15) ---------------------------------------------------------
  % Horizontal shear on a plane at mid-height of the joint (15.4.1.1): top, the
  % net rod pull dT on the other face; bottom, C(A) - C(B) = dT. Column shear
  % above would reduce it: not counted.
  Vj = max(dT, 0);
  bj = min([C.b, bp + C.h]);                   % 15.4.2.4 with the plate width as beam width
  Aj = C.h*bj;
  fprintf('--- 10. JOINT (ACI Ch. 15) ---\n');
  fprintf('  Vu,j = unbalanced flange force = %.1f kN; Aj = %.0f x %.0f = %.0f mm2; gamma = %.2f (input)\n', ...
          Vj/1e3, C.h, bj, Aj, C.gamma);
  S(end+1,:) = print_check('Joint shear', Vj/1e3, 0.75*C.gamma*lambda*sqrt(fc)*Aj/1e3, 'kN', 'ACI 15.4.2, T.15.4.2.3');
  if isfield(C, 'hoop_y') && ~isempty(C.hoop_y)
    n_in = sum(C.hoop_y > 0 & C.hoop_y < h);
    fprintf('  Tie layers within the beam depth: %d (>= 2) -> %s [ACI 15.3.1.3]\n', n_in, iif(n_in >= 2, 'OK', 'NOT OK'));
    S(end+1,:) = print_check('Joint tie spacing within the beam depth', max(diff([0, sort(C.hoop_y(C.hoop_y > 0 & C.hoop_y < h)), h])), 200, 'mm', 'ACI 15.3.1.4 (8 in.)');
    for y = C.hoop_y
      cl = min(abs(y - [dist_top dist_bot])) - (d_b + C.db_hoop)/2;
      if cl < 10, fprintf('  tie at y = %g: %.0f mm clear to a rod row (see the clash list of the model)\n', y, cl); end
    end
  end
  fprintf('  Unbalanced moment %.1f kNm goes into the column (design it in the frame model).\n\n', (Mu - Mo)/1e6);

  % ---- 11. not applicable ------------------------------------------------------------
  fprintf('--- 11. NOT APPLICABLE / NOT CHECKED HERE ---\n');
  fprintf('  Through-rods tie plate to plate: breakout in tension, pullout, side-face blowout\n');
  fprintf('  and pryout do not apply. Shear breakout: no free edge below (the column continues).\n');
  fprintf('  Column axial-flexure design, beam member design away from the joint: frame model.\n\n');

  % ---- summary ----------------------------------------------------------------------
  fprintf('==============================================================\n');
  fprintf('  SUMMARY (ratio = demand / capacity)\n');
  fprintf('==============================================================\n');
  for i = 1:size(S, 1)
    fprintf('  %-50s %5.2f  %s\n', S{i,1}, S{i,2}, iif(S{i,2} <= 1, 'OK', '<-- NOT OK'));
  end
  [rmax, imax] = max(cell2mat(S(:,2)));
  fprintf('  Governing: %s (%.2f)\n', S{imax,1}, rmax);
  fprintf('==============================================================\n');
  R = struct('checks', {S}, 'governing', S{imax,1}, 'ratio', rmax, 'arm', arm, 'h1', h1, 'k_conf', k_conf, ...
             'T_rod', T_rod, 'dT_B', dT, 'Vj', Vj, 'L_rod', L_rod, 'gov_face', gov);
end

% ---------------------------------------------------------------------------
function [bs, k, A1, A2] = strips(p, phi_c, fc, side, C)
  % strict strips with sqrt(A2/A1) from the column face: frustum limited by the
  % column sides, the column top (if any) and the column depth (both faces loaded)
  k = 2.0;  A1 = NaN;  A2 = NaN;
  for it = 1:20
    p.fp = phi_c*0.85*fc*k;
    bs = bearing_strips(p);
    if ~bs.ok, break; end
    H = bs.yt - max(0, p.ext - bs.c);
    d_top = (p.h + p.ext - bs.yt) + C.top;
    [k_new, A1, A2] = conf_factor(p.bp, H, side, min(side, d_top), C.h);
    if abs(k_new - k) < 1e-6, break; end
    k = k_new;
  end
end
