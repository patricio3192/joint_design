function P = ca_inputs()
% CA_INPUTS  Input data of the cantilever anchorage, double plate concept.
%   IPE 240 with a shop-welded end plate, bolted on site to straight threaded
%   rods that cross the joint. Each embedded assembly is a front plate cast
%   flush with the outer face, the rods, and a back plate at the far side of
%   the joint. No site welding.
%   Units: N, mm, MPa. Loads in kN/m2 and kN/m. Levels z are measured from the
%   top of the concrete beam (= top of steel), positive upwards.
%   Distances u are measured from the outer face of the column, into the column.
%   Distances v are measured from the beam axis, across the column.
%   Site data and loads copied from ../cantilever_anchor_V2/ca_inputs.m (2026-10-01).

% --- materials -----------------------------------------------------------
P.fc     = 210*0.0980665;   % concrete, 210 kg/cm2
P.fy     = 420;             % rebar yield (INEN 2167 / A706, weldable)
P.fu_bar = 550;             % rebar tensile strength
P.Es     = 200000;
P.Fy     = 248;             % A36 plates
P.Fu     = 400;
P.E      = 200000;
P.FEXX   = 483;             % E70xx electrode (shop welds only)

% --- loads ---------------------------------------------------------------
P.qD  = 2.5;                % kN/m2
P.qL  = 2.0;                % kN/m2
P.eta = 2.48;  P.Z = 0.25;  P.Fa = 1.4;  P.I = 1.0;   % NEC-SE-DS
P.L      = 1100;            % loaded length from the column face (1.3 m from the axis)
P.a0     = 200;             % column axis to column face
P.s_edge = 4800;            % tributary width, edge beam
P.s1     = 3700;            % corner trapezoid, side at the tip
P.s2     = 2400;            % corner trapezoid, side at the column

% --- steel beam IPE 240 (ipac2023/ipac_ipe.csv) --------------------------
P.bm.name = 'IPE 240';
P.bm.h = 240;  P.bm.b = 120;  P.bm.tw = 6.2;  P.bm.tf = 9.8;  P.bm.r = 15;
P.bm.A  = 3910;      P.bm.w  = 30.7*9.81/1000;   % mm2, kN/m
P.bm.Ix = 3892e4;    P.bm.Sx = 324e3;   P.bm.Zx = 367e3;
P.bm.Iy = 284e4;     P.bm.ry = 26.9;    P.bm.J  = 12.9e4;

% --- concrete column (pedestal) ------------------------------------------
P.col.b     = 400;
P.col.cover = 40;
P.col.dtie  = 10;
P.col.db    = 16;           % 8 bars: 4 corners + 4 mid-face
P.col.top   = 100;          % pedestal top above the beam top
P.col.cj    = -350;         % cold joint (column cast up to the beam soffit)
P.col.s     = 150;          % ties of the pedestal, 10 mm at 15 cm
P.rod.db    = 12;           % 4 anchor rods of the steel column base plate
P.rod.p     = 100;          % at (+-100, +-100) from the column axis

% --- concrete beams 30x35 ------------------------------------------------
P.cb.b  = 300;  P.cb.h = 350;
P.cb.db = 12;   P.cb.v = [-94 0 94];    % VCS: 3 top + 3 bottom (crossing beams, one corner beam)
P.cb.ve = [-94 -57 0 57 94];            % VCM: 5 top + 5 bottom, positions inside the joint once the pairs are separated
P.cb.vb = [-94 -82 0 82 94];            % VCM as built: 2 bars in contact at each corner + 1 in the centre
P.cb.fyt = 420;  P.cb.s = [70 140];     % stirrups: 10 mm at 7 and 14 cm
P.cb.dst = 10;  P.cb.sst = 140;
P.cb.zt = [-56 -68];        % top bars: layer 1, layer 2 (which beam is on top is not known)
P.cb.zb = [-294 -282];      % bottom bars
P.cb.uh  = 50;              % outside of the hook of the beam top bars, from the outer face
P.cb.uh0 = 66;              % same for the centre bar: it stops behind the mid-face column bar
P.slab.t = 110;  P.slab.deck = 55;

% --- joint ties (as planned for the hooked designs, kept) ------------------
P.hoop.db = 10;
P.hoop.z  = [-90 -135 -180 -225];   % layers within the joint, 4 straight ties each
P.hoop.ztop = 50;              % edge only: closed tie above the rods, placed after them (45 in the hooked designs)
% closed ties at the top of the pedestal: the rods of the steel column base plate are anchor
% bolts in the top of a pedestal, ACI 318-19 10.7.6.1.5: two No. 4 (or three No. 3) within
% 5 in. = 127 mm of the top. Two closed ties 14 mm, dropped over the column bars before the rods.
P.top.db = 14;
P.top.z  = [-22 6];

% --- threaded rods ---------------------------------------------------------
% 5/8"-11 UNC, ASTM A193 B7 (stocked in Ecuador; F1554 is not), heavy hex nuts A194 2H.
% B7: elongation 16 %, reduction of area 50 %: ductile steel element (ACI 318-19 chapter 2).
P.tr.lab  = '5/8"';
P.tr.d    = 15.875;
P.tr.Ase  = 146;               % tensile stress area, 0.226 in2
P.tr.fya  = 724;  P.tr.futa = 860;   % 105 / 125 ksi; futa <= min(1.9 fya, 860 MPa), 17.6.1.2
P.tr.hole = 18;                % standard hole (11/16 in.)
P.tr.nut  = 27;                % heavy hex nut across flats (1 1/16 in.), tension rods
P.tr.nutS = 23.8;              % regular hex nut across flats (15/16 in.), shear rods on the end plate
P.tr.tnut = 16;
P.tr.pf   = 29;                % rod axis to the flange face: d + 1/2 in = 28.6 (AISC DG4, DG16)
P.tr.out  = 60;                % length out of the front plate face
% rods of each assembly type, [z |v| uEnd] each mirrored to +-v; uEnd = far end of the rod
%   type E  (edge) and type CX (corner, beam X): 2 tension rods over the top flange at pf
%   type CY (corner, beam Y): 2 tension rods over the top flange, higher (pf = zH), so that
%       they cross over the rods of X; nothing depends on which beam bars are on top
%   all types: 2 shear rods over the bottom flange; those of CY higher, to cross those of CX
P.tr.vT = 40;                  % tension rods, |v|
P.tr.zH = 56;                  % tension rods of type CY, level
P.tr.vS = 28.5;                % shear rods, |v| (between the hook tails of the beam bars at v = 0 and 57)
P.tr.zS2 = -157;               % shear rods of type CY: midway between the ties at -135 and -180
P.tr.uS  = 180;                % shear rods: bearing face of the inner nut

% --- plates ----------------------------------------------------------------
P.fp.t = 12;  P.fp.w = 180;    % front plate, flush with the outer face (template + bearing)
P.fp.zb = -270;                % bottom
P.bp.t = 16;  P.bp.h = 50;  P.bp.w = 150;   % back plate on the 2 tension rods (all types)
P.bp.u = 365;                  % its bearing face: behind the far column bars and the far tie
P.ep.t = 20;  P.ep.w = 150;    % end plate of the steel beam (shop welded)
P.ep.over = 31;                % above the highest rod (extended plate)
P.ep.under = 15;               % below the bottom flange
P.w.flange = 8;  P.w.web = 5;  % shop fillets, both sides

% --- placing tolerances (applied against the design) -----------------------
P.tol.ub = 25;                 % ends of the beam bars, ACI Table 26.6.2.1(b)
P.tol.zb = 13;                 % level of the beam bars, d > 200 mm, ACI Table 26.6.2.1(a)

% --- frame forces at the edge pedestal, 1.2D + L - Ex (ETABS, at the faces) ---
P.frame.Mcol = 21.04;          % kN m, column
P.frame.Vcol = 15.65;          % kN
P.frame.Mb   = [26 5.126];     % kN m, the two edge beams (signs not certain: added)
end
