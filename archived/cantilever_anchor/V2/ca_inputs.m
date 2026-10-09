function P = ca_inputs()
% CA_INPUTS  Input data of the cantilever anchorage, revision 3 (variant).
%   IPE 240, two platinas per beam with the centre free for the mid-face
%   column bar, Ø12 anchors welded on the platinas only (one load path).
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
P.cb.db = 12;   P.cb.v = [-94 0 94];    % top line of every beam: 2 corners + centre (VCS: these 3 bars, top and bottom)
P.cb.vm = [-94 94];                     % VCM: 5 top + 5 bottom; the 2 extra bars sit under the top corner bars (over the bottom ones), in contact
P.cb.fyt = 420;  P.cb.s = [70 140];     % stirrups: 10 mm at 7 and 14 cm
P.cb.dst = 10;  P.cb.sst = 140;
P.cb.zt = [-56 -80];        % top line as drawn: beam in line on top; crossing beam under the stacked VCM corners
P.cb.zb = [-294 -270];      % bottom line as drawn: beam in line; crossing beam over the stacked VCM corners
P.cb.z1 = -56;              % top line of whichever beam is on top (which one is not known)
P.cb.dz = 12;               % VCM: second bar in contact under each top corner bar
P.cb.uh  = 50;              % outside of the hook of the beam top bars, from the outer face
P.cb.uh0 = 66;              % same for the centre bar: it stops behind the mid-face column bar
P.cb.uh2 = 62;              % VCM second bars: their hooks sit inside the hooks of the corner bars
P.slab.t = 110;  P.slab.deck = 55;

% --- embedded assembly ---------------------------------------------------
P.pl.t = 12;   P.pl.w = 220; P.pl.zt = 30;  P.pl.zb = -270;    % embed plate
P.pla.t = 12;  P.pla.v0 = 20;  P.pla.w = 76;  P.pla.L = 70;    % 2 platinas per beam, from |v| = v0 to v0 + w, centred on the top flange
P.anc.db = 12;                 % hooked bars welded on the platinas only
P.anc.vO = 70;                 % edge: bar over each platina, |v|; tails pass between the beam top bars at 0 and 94
P.anc.vU = 33;                 % edge: bar under each platina, |v| (near the centre bar of the beam)
P.anc.vC = [33 70];            % corner: two bars on one face of each platina, |v|
P.anc.u0 = 30;                 % start of the bars, clear of the platina-to-plate fillet
P.anc.uh = 380;                % outside of the hook, all bars: the tails pass behind the far tie legs (inside the beam in line, no cover needed)
P.anc.Lw = 50;                 % side welds bar to platina, each side, ending at the end of the platina
P.w.flange = 8;  P.w.web = 5;  P.w.pla = 8;  P.w.bar = 6;

% --- placing tolerances (applied against the design) -----------------------
P.tol.ub = 25;                 % ends of the beam bars, ACI Table 26.6.2.1(b)
P.tol.zb = 13;                 % level of the beam bars, d > 200 mm, ACI Table 26.6.2.1(a)
P.tol.ua = 5;                  % shop: hook of the anchors
P.tol.za = 3;                  % shop: level of the platinas

% --- joint ties ------------------------------------------------------------
P.hoop.db = 10;
P.hoop.z  = [-95 -135 -180 -225];   % layers within the joint, 4 straight ties each; the top one under the stacked VCM bars
P.hoop.ztop = 45;              % closed tie above the anchors

% --- frame forces at the edge pedestal, 1.2D + L - Ex (ETABS, at the faces) ---
P.frame.Mcol = 21.04;          % kN m, column
P.frame.Vcol = 15.65;          % kN
P.frame.Mb   = [26 5.126];     % kN m, the two edge beams (signs not certain: added)
end
