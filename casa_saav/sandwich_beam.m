% =========================================================================
% casa_saav / sandwich_beam.m
% "SANDWICH" MOMENT CONNECTION (Steel - Concrete - Steel): two IPE 200 beams
% frame into the two side faces of a concrete beam 30 x 35 through flush end
% plates tied together by through-rods cast in the concrete beam
% (A, B, C, D on grids 10 and 11; F4, G4).
% Checks: lib/sandwich_concrete/check_sandwich_beam.m (limits: CLAUDE.md there).
% Open items (PENDIENTE.txt): notes/sandwich_PENDIENTE.txt. Output: reports/sandwich_beam_output.txt
%   octave-cli casa_saav/sandwich_beam.m > casa_saav/reports/sandwich_beam_output.txt
% Units: N, mm, MPa.
% =========================================================================
clc; clear;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'lib', 'sandwich_concrete'), fullfile(here, '..', 'lib', 'concrete_common'));

% connection demands
P.load = struct('Mu_kNm', 23.5, ...      % moment at the end plate (governing face)
                'Vu_kN', 21.5, ...       % shear at this face
                'Vu_other_kN', 9.5);     % shear at the opposite face, same rods

% steel beam IPE 200 (IPAC 2023 catalog, ~/scripting/digitalized_catalog_profiles), ASTM A36
P.beam = struct('name', 'IPE 200', 'h', 200, 'bf', 100, 'tf', 8.5, 'tw', 5.6, ...
                'r_fil', 12, ...         % root radius
                'h_web', 159, ...        % web clear depth between root radii (catalog 'd')
                'Zx', 221e3, 'Sx', 194e3, 'Iy', 142e4, 'ry', 22.4, 'J', 6.98e4, ...  % mm3, mm3, mm4, mm, mm4
                'Fy', 250, 'Fu', 400, 'E', 200000, ...
                'L_span', 4800, ...      % IPE span
                'L_brace', 2400);        % IPE crossing at mid-span (shear connection)

% concrete beam
P.cbeam = struct('bc', 300, ...          % width = rod length
                 'hc', 350, ...          % depth; IPE top flush with concrete top
                 'fc', 21, 'fy_bar', 4200 * 0.0980665, ...   % 4200 kg/cm2 -> 411.9 MPa
                 'cover_long', 50, ...   % clear cover to longitudinal bars
                 'cover_spec', 40, ...   % ACI Table 20.5.1.3.1: beams, not exposed (1.5 in.)
                 'db_long', 12, 'n_top', 3, 'n_bot', 3, ...
                 'db_st', 10, ...        % closed stirrups, 135 deg hooks
                 's_typ', 140, ...       % current stirrup spacing
                 's_joint', 110, ...     % proposed spacing in the joint zone
                 'torsion_compat', true);% compatibility torsion (model uses 0.1 GJ)
% concrete beam forces from the structural model (Vu kN, Mu kNm, Tu kNm)
P.cbeam.names = {'N1 left', 'N1 right', 'N2 left', 'N2 right'};
P.cbeam.F = [ 34.0 , 20.00 , 4.55 ;
              -7.0 , 21.00 , 0.33 ;
              -7.6 , 17.18 , 0.33 ;
             -30.9 , 17.18 , -7.72 ];

% end plate (only A36 12 mm available); ext: projection below the bottom flange, top flush
P.plate = struct('tp', 12, 'bp', 140, 'ext', 20, 'Fyp', 250, 'Fup', 400);

% through-rods: threaded rod ASTM A193 B7 (see PENDIENTE.txt item 1)
P.rods = struct('d_b', 16, ...
                'Fu', 860, ...           % A193 Table 2, B7, d <= 2.5 in: 125 ksi. CONFIRM MILL CERTIFICATE
                'dh', 18, ...            % standard hole M16, AISC Table J3.3M
                'dist_top', 50 - 16/2, ...  % tension row from the top of the IPE (= top of concrete)
                'g', 55, ...             % gage
                'dist_bot', 150, ...     % shear row (highest feasible row, module 7)
                'torqued', false, ...    % hand tightened -> ACI Table 17.9.2(a) 4da
                'splitting_reinf', true);% 2 stirrups next to the rods control splitting (ACI 17.9.1)

% welds, E70XX
P.weld = struct('FEXX', 482, ...
                'top_cjp', true, ...     % top flange: CJP (agreed); false = PJP below
                'S_pjp', 6, ...          % PJP option: bevel depth (flange only beveled)
                'pjp_flat', true, ...    % PJP option: GMAW/FCAW in F/H position (E = S); false: E = S - 3
                'w_fl', 6, ...           % bottom flange fillet leg
                'w_web', 6);             % web fillet leg (both sides)

P.slab_on_top = true;                    % slab cast on top: the beam top is not a free edge

R = check_sandwich_beam(P);
