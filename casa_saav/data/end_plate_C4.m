function P = end_plate_C4()
% END_PLATE_C4  Input of the end plate on the concrete column C4 (same detail at
% B4, D4X, D4Y, D3), for lib/end_plate_concrete: the checks
% (check_end_plate_column) and the 3D model (model_end_plate_column) read the
% same P, so the drawing cannot drift from the calculation.
% Units: N, mm, MPa. Coordinates: x along the column face (0 = cantilever
% axis = column axis), y down from the top of the beams, z into the column.
% Fields marked (model) are used only by the 3D model, not by the checks.
  % demands at the column face; top in tension, no reversal
  P.load = struct('Mu_kNm', 12.1, 'Vu_kN', 14.1);

  % steel beam IPE 240 (IPAC 2023 catalog, ~/scripting/digitalized_catalog_profiles), ASTM A36
  P.beam = struct('name', 'IPE 240', 'h', 240, 'bf', 120, 'tf', 9.8, 'tw', 6.2, 'r_fil', 15, ...
                  'h_web', 190.4, 'Fy', 250, 'Fu', 400, 'E', 200000);

  % concrete (column, joint and beams) and reinforcement
  P.concrete = struct('fc', 210 * 0.0980665, ...      % 210 kg/cm2 -> 20.6 MPa (240 possible)
                      'fy_bar', 4200 * 0.0980665, ... % 4200 kg/cm2 -> 411.9 MPa
                      'lambda', 1.0, ...              % normalweight
                      'psi_cN', 1.0, 'psi_cP', 1.0);  % cracked (17.6.2.5.1(b), 17.6.3.3.1(b))
  P.column = struct('b', 400, ...                     % column 40 x 40
                    'top', -105, ...                  % column top above the beams (y)
                    'cover', 40, 'db_hoop', 10, 'db_bar', 16);
  P.cbeam = struct('bw', 300, 'h', 350, 'db_bar', 12);   % VCM (along z) and VCS (along x), 30 x 35

  % end plate (A36, 10 or 12 mm available), on 30 mm grout; ext: plate below the bottom flange
  P.plate = struct('tp', 12, 'bp', 140, 'ext', 20, 'Fyp', 250, 'Fup', 400, 't_grout', 30);

  % anchor rods A193 B7 M16x2, cast-in, hand tightened (see PENDIENTE item 1)
  P.rods = struct('d_b', 16, 'pitch', 2, ...
                  'Fu', 860, 'Fy', 720, ...  % ASTM A193 B7 Table 2 - CONFIRM MILL CERTIFICATE
                  'dh', 18, ...              % standard hole M16, AISC Table J3.3M (template needed)
                  'y_t', 42, ...             % tension row (from top of plate)
                  'g', 80);                  % gage (column mid bar at x = 0, VCM centre bar at x = 0)

  % head plates (one square plate per rod, nut + washer behind), washer ISO 7089 M16
  P.head = struct('a', 50, 't', 12, 'dw', 30, 'h_nut', 16, 't_wsh', 3, 'proj', 5, ...
                  'clear_tip', 5);           % rod tip 5 mm clear to the back hoop

  % anchor reinforcement: 2 bastones phi12 (straight leg along z, hook down)
  P.bastones = struct('db', 12, 'n', 2, ...
                      'x', 94 - 12, ...      % beside the VCM 2nd-row corner pair (x = +/-94)
                      'y', 56 + 12 + 12, ... % 2nd-row level: c_beam 56 + 12 (VCS) + 12 = 80
                      'psi_t', 1.3, ...      % > 300 mm of fresh concrete below (455 mm pour)
                      'ld_good', false);     % Table 25.4.2.3 "other cases" (conservative)

  % joint (ACI Ch. 15)
  yb = 350 - 56;                             % bottom row of the beams (h - c_beam)
  P.joint.frame = 'ordinary';                % NEC/ACI ordinary moment frame
  P.joint.hoop_y = [110 155 230 305];        % hoop layers inside the joint (y), <= 75 apart (user)
  P.joint.Mu_long = 32.5e6;                  % VCM at the column face [N*mm], top in tension
  P.joint.Mu_trans = [24.5e6 33.4e6];        % VCS left / right at the column faces
  P.joint.top_y = [56 56 56 80 80];          % VCM top bars: 3 at c_beam, 2 in the 2nd row
  % Table 15.4.2.3: column "other" (extends 105 mm < h above, 15.2.6);
  %   z (VCM): beam "other", confined by VCS on both faces (15.2.8) -> 15 (in-lb) = 1.25 (SI)
  %   x (VCS): beam continuous, not confined (steel cantilever)       -> 15 (in-lb) = 1.25 (SI)
  P.joint.gamma = 1.25;
  % VCM bars along z, for the clash list: {name, x, y, d}
  P.joint.bars_z = {'VCM top 1', -94, 56, 12;  'VCM top 1', 0, 56, 12;  'VCM top 1', 94, 56, 12;
                    'VCM top 2', -94, 80, 12;  'VCM top 2', 94, 80, 12;
                    'VCM bot 1', -94, yb, 12;  'VCM bot 1', 0, yb, 12;  'VCM bot 1', 94, yb, 12;
                    'VCM bot 2', -94, yb-24, 12;  'VCM bot 2', 94, yb-24, 12};

  % steel column above: 4 phi12 anchors at 200 mm, 100 mm from the faces (x = +/-100)
  P.steel_col = struct('x', [-100 100], 'd', 12);

  % welds: E70XX; top flange CJP; fillets elsewhere
  P.weld = struct('FEXX', 482, 'w_fl', 6, 'w_web', 6);
  % ---- (model) detailing chosen on the sheet; the model checks it against R ----
  P.column.bars_side = 3;                    % bars per face (8 bars: corners + mid)
  P.column.ties_top = struct('y', [-42 -28], 'd', 14);   % 2 ties Ø14 above the beams
  P.rods.L = 440;                            % rod as bought: >= R.L_rod (411) + 20 margin (user)
  P.rods.leveling = true;                    % leveling washer + nut inside the grout gap
  P.head.nw = 24;                            % nut across flats (5/8"-11 UNC heavy hex)
  P.bastones.L = 1220;                       % straight leg from the hook face, >= R.L_bst (1217)
  P.bastones.tail = 200;                     % hook tail, down (12db = 144 does not fit across)
  P.steel_col.z = [100 300];                 % steel-column anchors in plan (z), at x = P.steel_col.x
  P.steel_col.y = [-165 300];                % from 60 above the column top down into the joint
end
