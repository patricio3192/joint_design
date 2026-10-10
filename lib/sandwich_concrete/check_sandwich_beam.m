function R = check_sandwich_beam(P)
% CHECK_SANDWICH_BEAM  "Sandwich" moment connection (steel - concrete - steel):
% two steel I beams frame into the two side faces of a concrete beam through
% flush end plates tied together by through-rods cast in the concrete beam.
% The face with the larger moment is checked, with the shear of the other face
% on the same rods. AISC 360-16, AISC Design Guide 39 (2023), AISC Design
% Guide 1 (2nd ed.), ACI 318-19 (SI forms, Appendix C). Equations: EQUATIONS.txt.
%
%   R = check_sandwich_beam(P)
%
% Prints the report (modules 1-12 and the summary) and returns
%   R.checks {name, ratio; ...}, R.governing, R.ratio, R.arm (real lever arm),
%   R.h1 (DG 39 arm), R.best_dist_bot (highest feasible shear row), R.k_conf.
% Units: N, mm, MPa (moments in P.load in kN*m, shears in kN).
%
% P fields (casa_saav/sandwich_beam.m is a complete example):
%   load    Mu_kNm, Vu_kN (governing face), Vu_other_kN (opposite face, same rods)
%   beam    name, h, bf, tf, tw, r_fil, h_web, Zx, Sx, Iy, ry, J, Fy, Fu, E,
%           L_span, L_brace (unbraced lengths checked for LTB)
%   cbeam   concrete beam: bc (width = rod length), hc, fc, fy_bar, cover_long,
%           cover_spec, db_long, n_top, n_bot, db_st, s_typ (current stirrup
%           spacing), s_joint (joint zone), torsion_compat,
%           names {...} and F [Vu kN, Mu kNm, Tu kNm; ...] at its checked sections
%   plate   tp, bp, ext (below the bottom flange; top flush), Fyp, Fup
%   rods    d_b, Fu, dh, dist_top (tension row from the top), g (gage),
%           dist_bot (shear row), torqued, splitting_reinf
%   weld    FEXX, top_cjp (false: PJP with S_pjp, pjp_flat), w_fl, w_web
%   slab_on_top  true: the top of the concrete beam is not a free edge
% Limits: lib/sandwich_concrete/CLAUDE.md.

  % ---- unpack (the checks below use these names) ----------------------------
  Mu_kNm = P.load.Mu_kNm;  Vu_kN = P.load.Vu_kN;  Vu_other_kN = P.load.Vu_other_kN;
  Mu = Mu_kNm * 1e6;  Vu = Vu_kN * 1000;  Vu_other = Vu_other_kN * 1000;
  b = P.beam;  bm_name = b.name;
  h = b.h;  bf = b.bf;  tf = b.tf;  tw = b.tw;  r_fil = b.r_fil;  h_web = b.h_web;
  Zx = b.Zx;  Sx = b.Sx;  Iy = b.Iy;  ry = b.ry;  J = b.J;
  Fy = b.Fy;  Fu = b.Fu;  E = b.E;  L_span = b.L_span;  L_brace = b.L_brace;
  c = P.cbeam;  bc = c.bc;  hc = c.hc;  fc = c.fc;  fy_bar = c.fy_bar;  cover_long = c.cover_long;
  db_long = c.db_long;  n_top = c.n_top;  n_bot = c.n_bot;  db_st = c.db_st;
  s_typ = c.s_typ;  s_joint = c.s_joint;  torsion_compat = c.torsion_compat;
  beam_names = c.names;  beam_F = c.F;
  tp = P.plate.tp;  bp = P.plate.bp;  ext = P.plate.ext;  Fyp = P.plate.Fyp;  Fup = P.plate.Fup;
  d_b = P.rods.d_b;  Ab = pi * d_b^2 / 4;  Fu_rod = P.rods.Fu;  dh = P.rods.dh;
  dist_top = P.rods.dist_top;  pfi = dist_top - tf;  g = P.rods.g;  dist_bot = P.rods.dist_bot;
  rods_torqued = P.rods.torqued;  splitting_reinf = P.rods.splitting_reinf;
  FEXX = P.weld.FEXX;  top_cjp = P.weld.top_cjp;  S_pjp = P.weld.S_pjp;  pjp_flat = P.weld.pjp_flat;
  w_fl = P.weld.w_fl;  w_web = P.weld.w_web;
  slab_on_top = P.slab_on_top;

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
  cover_req = P.cbeam.cover_spec;       % specified cover (ACI Table 20.5.1.3.1)
  fprintf('  ACI min edge (not torqued) = specified cover %.0f mm; top rod clear cover = %.0f mm\n', cover_req, dist_top - d_b/2);
  if slab_on_top
      fprintf('  -> slab cast on top: the beam top is not a free edge, requirement met.\n');
  else
      S(end+1,:) = print_check('ACI min edge, top rods (clear cover)', cover_req, dist_top - d_b/2, 'mm', 'ACI Table 17.9.2(a)');
  end
  fprintf('  Rods run parallel to the stirrup legs: place them between stirrups.\n\n');

  % -------------------------------------------------------------------------
  % MODULE 9: STEEL BEAM (AISC 360-16 F2, G2)
  % -------------------------------------------------------------------------
  fprintf('--- 9. %s: FLEXURE AND SHEAR ---\n', bm_name);
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
  S = [S; end_plate_welds(Mu, Vu, P.beam, P.weld, ext, pfi)];

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
  R = struct('checks', {S}, 'governing', S{imax,1}, 'ratio', rmax, 'arm', arm_real, ...
             'h1', h1, 'best_dist_bot', best, 'k_conf', k_conf);
end
