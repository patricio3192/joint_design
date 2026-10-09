% =========================================================================
% casa_saav / end_plate_column.m
% IPE 240 CANTILEVER - FLUSH END PLATE ON THE CONCRETE COLUMN C4 (same detail
% at B4, D4X, D4Y, D3). The end plate is set on 4 cast-in threaded rods
% (A193 B7) after the joint is cast, over a 30 mm grout layer. The rods end
% in square head plates inside the column hoop cage. All rod tension is taken
% by 2 L-shaped bars ("bastones") lapping into the VCM.
% Checks: lib/end_plate_concrete/check_end_plate_column.m (limits: CLAUDE.md there).
% Open items: notes/end_plate_PENDIENTE.txt. Output: reports/end_plate_column_output.txt
%   octave-cli casa_saav/end_plate_column.m > casa_saav/reports/end_plate_column_output.txt
% Units: N, mm, MPa. Coordinates: x along the column face (0 = cantilever
% axis = column axis), y down from the top of the beams, z into the column.
% =========================================================================
clc; clear;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'lib', 'end_plate_concrete'), fullfile(here, '..', 'lib', 'concrete_common'));

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

R = check_end_plate_column(P);
