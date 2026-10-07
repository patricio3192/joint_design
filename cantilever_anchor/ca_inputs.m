function P = ca_inputs()
% CA_INPUTS  Input data of the cantilever anchorage.
%   Units: N, mm, MPa. Loads in kN/m2 and kN/m. Levels z are measured from the
%   top of the concrete beam (= top of steel), positive upwards.
%   Distances u are measured from the outer face of the column, into the column.
%   Distances v are measured from the beam axis, across the column.

% --- materials -----------------------------------------------------------
P.fc     = 210*0.0980665;   % concrete, 210 kg/cm2
P.fy     = 420;             % rebar yield (INEN 2167 / A706, weldable)
P.fu_bar = 550;             % rebar tensile strength
P.Es     = 200000;
P.Fy     = 248;             % A36
P.Fu     = 400;
P.E      = 200000;
P.FEXX   = 483;             % E70xx electrode (E7018)

% --- loads ---------------------------------------------------------------
P.qD  = 2.5;                % kN/m2 (rev 2: was 3.0)
P.qL  = 2.0;                % kN/m2
P.eta = 2.48;  P.Z = 0.25;  P.Fa = 1.4;  P.I = 1.0;   % NEC-SE-DS
P.L      = 1100;            % loaded length from the column face (rev 2: 1.3 m from the axis)
P.a0     = 200;             % column axis to column face
P.s_edge = 4800;            % tributary width, edge beam
P.s1     = 3700;            % corner trapezoid, side at the tip
P.s2     = 2400;            % corner trapezoid, side at the column

% --- steel beam IPE 200 (ipac2023/ipac_ipe.csv) ------------------------------
P.bm.name = 'IPE 200';
P.bm.h = 200;  P.bm.b = 100;  P.bm.tw = 5.6;  P.bm.tf = 8.5;  P.bm.r = 12;
P.bm.A  = 2850;      P.bm.w  = 22.4*9.81/1000;   % mm2, kN/m
P.bm.Ix = 1943e4;    P.bm.Sx = 194e3;   P.bm.Zx = 221e3;
P.bm.Iy = 142e4;     P.bm.ry = 22.4;    P.bm.J  = 6.98e4;

% --- concrete column (pedestal) ------------------------------------------
P.col.b     = 400;
P.col.cover = 40;
P.col.dtie  = 10;
P.col.db    = 16;           % 8 bars: 4 corners + 4 mid-face (rev 2)
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
P.cb.zt = [-56 -68];        % top bars: layer 1 (beam in line), layer 2 (crossing beam)
P.cb.zb = [-294 -282];      % bottom bars
P.slab.t = 110;  P.slab.deck = 55;

% --- embedded assembly ---------------------------------------------------
P.pl.t = 12;   P.pl.w = 220;  P.pl.zt = 30;  P.pl.zb = -230;   % embed plate
P.lug.t = 12;  P.lug.w = 110; P.lug.L = 30;                    % top lug, stops before the mid-face column bar
P.stf.t = 12;  P.stf.w = 110; P.stf.L = 30;                    % bottom plate, same piece as the lug
P.anc.db = 16;                 % hooked bars welded to the lug and to the plate
P.anc.v  = [-35 35];
P.anc.uh = 350;                % outside of the hook, bars over the lug (type B) and corner X
P.anc.uhA = 270;               % outside of the hook, bars under the lug at the edge column
P.anc.Lw = 25;                 % side welds bar to lug, each side
P.w.flange = 8;  P.w.web = 5;  P.w.lug = 8;  P.w.stf = 6;  P.w.bar = 6;  P.w.end = 8;

% --- added reinforcement -------------------------------------------------
P.Lb.db  = 16;                 % L bars added to the top of the beam in line
P.Lb.v   = [];                 % rev 2: not needed
P.Lb.z   = [-58 -74];          % axis: layer 1 (beam in line), layer 2 (crossing beam)
P.Lb.ext = 1500;               % length beyond the far column face
P.Lb.uh  = 50;                 % outside of the front hook, from the column face
P.hoop.db = 10;
P.hoop.z  = [-90 -135 -180 -225];   % hoop layers within the joint, 4 straight ties each
P.hoop.ztop = 45;              % closed hoop above the anchors

% --- frame forces at the edge pedestal, 1.2D + L - Ex (ETABS, at the faces) ---
P.frame.Mcol = 21.04;          % kN m, column
P.frame.Vcol = 15.65;          % kN
P.frame.Mb   = [26 5.126];     % kN m, the two edge beams (signs not certain: added)
end
