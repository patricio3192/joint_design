function P = ca_inputs()
% CA_INPUTS  Input data of the cantilever anchorage, bolted plate concept.
%   IPE 240 with a shop-welded end plate, bolted on site to phi 16 threaded
%   rebar anchors cast into the joint. The end plate is NOT cast flush: it is
%   put on after the pour, over a grout pad. Starting point: the user's RAM
%   Connection model (anclaje voladizo.pdf, 2026-10-01), plate 250x350x12,
%   5 phi 16 anchors, shear key.
%   Units: N, mm, MPa. Loads in kN/m2. Levels z are measured from the top of
%   the concrete beam (= top of steel), positive upwards. Distances u are
%   measured from the outer face of the column, into the column. Distances v
%   are measured from the beam axis, across the column.
%   Site data copied from ../cantilever_anchor_double_plate/ca_inputs.m (2026-10-02).

% --- materials -----------------------------------------------------------
P.fc     = 210*0.0980665;   % concrete, 210 kg/cm2
P.fy     = 420;             % rebar yield (INEN 2167 / A706, weldable)
P.fu_bar = 550;             % rebar tensile strength
P.Es     = 200000;
P.Fy     = 248;             % A36 (beam IPE 240 taken as A36 too)
P.Fu     = 400;
P.E      = 200000;
P.FEXX   = 483;             % E70xx electrode (shop welds only)
P.fg     = 28;              % commercial non-shrink grout (ASTM C1107), minimum 28-day strength, user 2026-10-03:
                            % 280 kg/cm2 (DG1 2.10 advises 2 f'c; the bearing check uses the concrete). In Cuenca:
                            % SikaGrout-212 (Disensa; 30 kg, ~60 MPa at 28 d, layers 3..50 mm) or INTACO Maxibed Grout
% end plate steels compared (user: A36 12 mm fails slightly, A588 or 14 mm A36 pass in RAM)
P.st.name = {'A36', 'Gr50'};   % Gr50: A572 Gr50 or A588 Gr A (Fy 345); Fu taken as A572's 450
P.st.Fy   = [248 345];
P.st.Fu   = [400 450];
P.st.t    = [12 14 16 18 20];

% --- loads ---------------------------------------------------------------
P.qD  = 2.5;                % kN/m2 (unchanged, user 2026-10-02)
P.qL  = 2.0;                % kN/m2
P.eta = 2.48;  P.Z = 0.25;  P.Fa = 1.4;  P.I = 1.0;   % NEC-SE-DS
P.Lax  = 1270;              % cantilever from the column axis (user 2026-10-02)
P.hcb  = 150;               % half width of the concrete beam framing into the column
P.L    = P.Lax - P.hcb;     % loaded length 1120 (user: "1.27 - 0.15 = 1.12 m"); the moment is
                            % taken at the column face with this whole length as lever (conservative)
P.a0     = 200;             % column axis to column face
P.s_edge = 4800;            % tributary width, edge cantilever (two half spans of 2.4 m)
P.s_half = 2400;            % half span next to a corner cantilever
P.Mmin   = [20.5 15.55];    % kN m, user minimum design moments: edge "a bit above 20", corner 15.55
% user's ETABS model (2026-10-02), edge cantilever B16 at the column face, load cases D and L.
% It loads the cantilever more than the tributary areas above: its 1.2D + Ev + L sets the design.
P.etabs.MD = 8.8515;  P.etabs.VD = 9.5162;     % kN m, kN
P.etabs.ML = 6.3393;  P.etabs.VL = 6.7970;
% concrete beams in line, moment at the column face (kN m): [1.2D+1.6L+0.5Lr, 1.2D-Ey-0.3Ex+L+0.2S]
% (the model includes the cantilever and its slab, but not Ev)
P.etabs.Mbeam_edge   = [35.3045 38.7901];        % B6, VCM
P.etabs.Mbeam_corner = [23.5648 31.2704];        % B48, VCM (5 bars, user)
% largest positive moment in the beam in line, 0.5 m from the column face (always above the value at the
% face; user 2026-10-03): C4 (E) 3.5; D4 along grid 4 (CX) 6.2, along grid D (CY) 6.6; C1 not given: 6.6
P.etabs.Mpos = [3.5 6.6 6.2 6.6];                % kN m, types E, C1, CX, CY
% largest negative moment at the face of the beam in line (user 2026-10-04, seismic combinations, with the cantilever):
% B4 along B 30.0, D3 along 3 23.0, D4 along 4 24.3 kN m; C1 takes B4's (D3 has bastones: 5 bars too)
P.etabs.Mneg = [NaN 30.0 24.3 NaN];

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
P.col.ctop   = 10;          % top cover of the column top hooks of level A (user 2026-10-05, was 20: the tie 10 over the
                           % anchors at +52 then sits 6 mm off the bent bars instead of 13). User 2026-10-05: the hooks no longer
                           % rest on the anchors; the far-face bars stay straight down from +16 (bend radius 3.5 db)
                           % past the tie 14 at +10, which B1 bears on. Below ACI Table 20.5.1.3.1 (40): the user's
                           % choice (the base plate grout and the slab are on top)
P.col.cmin   = 10;          % least top cover (anchors 15 high: level B at +60, level A at +82 still clears it)
P.col.zhB    = 45;          % column top hooks, level B: the two mid bars of the faces along the cantilever (E) or of
                           % the north and south faces (D4), hooked across, resting on the A1 (of X at D4):
                           % an.pf + rod radius + db/2 = 44.9. Level A at top - ctop - db/2 = +72: the corners and
                           % the other two mid bars, hooked along the anchors (of X at D4). User 2026-10-05: this
                           % orientation (was level A across, on the B1 nuts; B along the A1 at +29; level C at D4)
P.rod.db    = 12;           % 4 anchor rods of the steel column base plate
P.rod.p     = 100;          % at (+-100, +-100) from the column axis

% --- concrete beams 30x35, centred on the column ---------------------------
P.cb.b  = 300;  P.cb.h = 350;
P.cb.db = 12;   P.cb.v = [-88 0 88];    % VCS: 3 top + 3 bottom. In the joint: the corner bars (+-94 in the beam)
                                        % are pushed 6 mm in, against the rods of the steel column at +-100
                                        % (user 2026-10-03: rods kept, more room for the pour than rods at +-112)
P.cb.vbm = 94;                          % corner bars in the beam (cover 40 + stirrup 10 + 6)
P.cb.vb = [-88 0 88];                   % VCM: same top line + 2 bars in contact UNDER the corner bars
P.cb.zt = [-56 -68];        % top bars: beam on top, beam underneath (not known which)
P.cb.zp = -80;              % VCM: the 2 bars in contact under the corner bars
P.cb.zb = [-294 -282];      % bottom bars
% bottom bars (user 2026-10-03): VCM 5 Ø12 like the top (3 in a row + 2 over the corner bars), VCS 3 Ø12.
% No moment reversal at the joint: only the 2 corner bars are hooked up (ACI 18.3.2, 9.7.7: 2 bars
% developed at the face); the centre bar goes straight 150 into the joint (9.7.3.8.2); the 2 extra
% bars of the VCM stop at the face of the column. Hooks behind the bend of the 2 extra top bars;
% the beam in line on the upper bottom layer (D4: grid D over grid 4).
P.cb.zbl  = -282;           % beam in line (hooked here)
P.cb.zbc  = -294;           % crossing beam (continuous; at D4 grid 4, hooked too)
P.cb.vbot = [-88 0 88];     % bottom bars in the joint (row of 3), all beams
P.cb.vbh  = [-88 88];       % hooked: the corner bars
P.cb.Lst  = 150;            % centre bottom bar: straight, into the joint
P.cb.ubh  = 126;            % outside of the bottom hooks from the cantilever face (tail axis 132): behind the A2 end nuts.
                            % Was 120: with the corner bars at +-88 the D4 tails of grids 4 and D came 7.8 apart (now 16.3)
P.cb.uh  = 50;              % outside of the hook of the beam top bars, from the outer face
P.cb.uh0 = 66;              % same for the centre bar: it stops behind the mid-face column bar
P.cb.dst = 10;  P.cb.sst = 140;
% bastones (user 2026-10-03/04): 2 extra Ø12 top bars at the support of the beam in line, only at E (C4): the corners
% have margin without them once the border beam connection is centred. In the second layer (-80), packed beside the
% 2 bars under the corner bars, at v = +-76 (in contact with them in the span: a 2-bar bundle, ACI 25.6.1). Their 90 deg
% hooks are staggered 16 mm behind those of the bars beside them, so the hooks do not touch (R25.6.1.1, R25.6.1.5):
% top line stays 3 bars with 76 mm gaps for the pour.
P.cb.bas.on    = 1;
P.cb.bas.types = [1 0 1 0];      % E, C1, CX, CY. User 2026-10-04: also D3 (a C1, grid 3: 3 bars) and D4X (CX, grid 4: 3 bars);
                                 % C1 is left without them in the calc: B4 has none (D3 is conservative there)
P.cb.bas.zt    = [-80 -68 -68 -80];   % level by type: C4 second layer (-80); D3 / D4X beside the corner bars of the
                                 % beam in line, on its own level (-68): grid D's 2 bars cross at -80
P.cb.bas.at    = {'C4', 'D3', 'D4X'};  % joints with bastones (2 each)
P.cb.nin       = [5 5 3 5];      % top bars of the beam in line: C4, B4 (VCM 5); D3, D4X (VCS 3); D4Y (VCM 5)
P.cb.bas.v     = [-76 76];
P.cb.bas.z     = P.cb.zp;        % second layer, -80
P.cb.bas.uh    = P.cb.uh + P.cb.db + 16;   % outside of the hook from the cantilever face: 78 (the bar beside it: 62)
P.cb.bas.L     = 1500;           % into the beam in line from the column face (about a third of the 4.78 m span)
P.slab.t = 110;  P.slab.deck = 55;

% --- joint ties ----------------------------------------------------------------
P.hoop.db = 10;
P.hoop.s  = 75;                      % user 2026-10-05: uniform spacing, -95 / -170 / -245 / -320: clear of the beam bars,
P.hoop.z  = -95 - P.hoop.s*(0:3);   % 18 / 31 mm from the A2 (-201), -320 above the soffit (-350). Before: 4 layers of joint ties. User 2026-10-04: spread over the joint depth for the
                                    % pour (were -95 -135 -180 -225, inherited). -160 / -245 keep 28 / 31 mm to the A2
                                    % at -201; -310 is 5 mm under the bottom bars of the crossing beam (-294)
P.hoop.zold = [-95 -135 -180 -225]; % previous layout, for the comparison in the anchorage check
P.hoop.ztop = NaN;             % the closed tie at +50 of the hooked designs is dropped: the two ties of
                               % 10.7.6.1.5 at -26 / -8 close the pedestal top, and +50 limited the anchors
% ACI 318-19 10.7.6.1.5: the rods of the steel column base plate need two No. 4 ties within
% 127 mm of the pedestal top. Two closed ties 14 mm, dropped over the column bars first.
% History: -22 / +6 (double plate), -26 / -8 (hooks), -25 / -7, -25 / -11 (a pair in contact).
% User 2026-10-05: both under the anchors (B1 bears on the upper one), a tie 10 over them (P.t10); levels set after the anchors.
P.top.db = 14;
P.top.zp = NaN;             % (proposed third tie 14 at -41: dropped)

% --- anchors: commercial threaded rod 5/8"-11 UNC, ASTM A193 B7 (user 2026-10-03: instead of threaded
% Ø16 rebar, nobody threads anything; cut from 3.66 m bars, Global Pernos / Multipernos). Second
% choice F1554 Gr 55 (galvanized): A1 0.72, A2 steel 0.84. Grade 2 / Gr 36 rod fails: not allowed.
% B7: elongation 16 % >= 14, reduction of area 50 % >= 30: ductile steel element (ACI 2.3).
P.an.db   = 15.875;         % 5/8"
P.an.lab  = '5/8"';
P.an.grade = 'ASTM A193 B7';
P.an.thr  = '5/8"-11 UNC';
P.an.Ase  = 146;            % tensile stress area of 5/8"-11 UNC (0.226 in2)
P.an.fya  = 724;  P.an.futa = 860;   % B7: 105 / 125 ksi; futa <= min(1.9 fya, 860), 17.6.1.2
P.an.thd  = [11/25.4, 13.87, 14.20, 1.0];   % threads per mm, nut minor dia max (2B), rod pitch dia min (2A), crest factor (rolled/cut on round rod: 1)
P.an.hole = 18;             % standard hole (11/16" = 17.5): the end plate is drilled to the as-built anchors
P.an.nut  = 24;             % hex nut 5/8"-11 grade 8 (SAE J995): 15/16" = 23.8 across flats (heavy hex A194 2H: 27, also fits)
P.an.tnut = 14;             % 35/64" = 13.9 high
P.an.pp   = 0;              % embedded ends cut flush with the nut (full engagement, AISC); the front projection is in an.out
P.an.wsh  = 30;             % flat washer Ø30 x 3 (ISO 7089 M16, hole 17: fits the 5/8" rod)
P.an.twsh = 3;
P.an.dw   = 22;             % bearing face of the 15/16" nut: the nut pushes on a ring 18..22
% tension anchors: 2 over the top flange, straight, nuts on a back plate at the far side
% (user 2026-10-02: back plate instead of hooks). |v| = 40 so that the 45 deg strip of the end
% plate from each anchor lands on the flange (strict lower bound).
P.an.vT  = 35;
P.an.pf  = 29;              % axis to the face of the top flange (d + 13, room for nut and fillet)
P.an.zH  = 45;              % corner beam Y: the anchors rest on those of beam X (29 + 15.9) and on the level-B column
                            % hooks of D4 (top at 37). User 2026-10-03: was 56 (11 mm over X), lowered so that the north
                            % corner hooks (level C) can sit on the Y anchors and their B1 nuts with 25 cover
P.an.uo  = 390;             % (hooked version only, not used)
% shear anchors: 2 over the bottom flange (compression zone), straight, nut + washer at the end
P.an.vS  = 35;
P.an.pfS = 29;              % axis to the inner face of the bottom flange
P.an.uS  = 100;             % bearing face of the end nut (h_ef)
P.an.out = 80;              % top anchors, out of the concrete face: grout 30 + extra plate 12 + plate 12 + washer + nut + 3 pitches
P.an.outS = 65;             % shear anchors: grout 30 + plate 12 + washer + nut + 3 pitches

% --- back plate: behind the far column bars and the far ties, one per beam ------------
P.bp.t = 12;  P.bp.h = 45;  P.bp.w = 120;  P.bp.grade = 1;   % PL 12x45x120 A36 (hole 22.5 from the long edges, AISC Table J3.4M: 22)
P.bp.u = P.col.b - (P.col.cover + P.col.dtie - P.top.db);   % 364: the bearing face against the back leg of the upper tie 14
                            % (user 2026-10-05; was 365); far ties 10 end at u = 360
P.an.uT = P.bp.u + P.bp.t + P.an.twsh + P.an.tnut + P.an.pp;     % far end of the tension anchors
% ties 14 (user 2026-10-05): one under the front nuts of B1 (a flat down) of the anchors at an.pf, in contact
% with the B1 face and with the straight far-face column bars (level-A hooks bend from +26 up).
% User 2026-10-05 (later): both ties 14 under the anchors, a closed tie 10 over them.
P.top.zu = floor(P.an.pf - P.an.nut/2 - P.top.db/2);                % +10
P.top.z  = [P.col.top - 124, P.top.zu];                             % -24 / +10: both within 127 of the top
P.t10.db = 10;                                                      % closed tie 10 over the anchors (as the joint ties, 6.4):
P.t10.z  = ceil(P.an.pf + P.an.nut/2 + P.t10.db/2) + 6;             % +52, 6 over the B1 front nuts (flats up)
P.t10.zD4 = ceil(P.an.zH + P.an.nut/2 + P.t10.db/2) + 1;            % D4: +63, over the nuts of the Y back plate
% shear across z = 0 (user 2026-10-05): the pull enters the pedestal above the beam top (B1 from +6.5 to +51.5)
% and must pass down into the joint across z = 0. Shear friction (ACI 22.9, monolithic, mu = 1.4) with
% inverted U-bars over the A1, in front of B1: legs down past the beam bars, 90 deg hooks at the bottom
P.ub2.n  = 2;               % U-bars (2 legs each)
P.ub2.db = 12;
P.ub2.u  = 330;             % legs, from the cantilever face (front nuts of B1 from 350)
P.ub2.v  = 60;              % legs at v = +-60: 11 clear to the A1, 4 to the bastones (+-76, at -80), clear of the beam bars (0, +-88)
P.ub2.zc = 62;              % crown axis: over the A1, under the level-A tails (+82)
P.ub2.zb = -300;            % bottom hooks (90 deg, ldh), under the beam bars, above the soffit

% --- end plate (shop welded to the beam) and grout pad -------------------------
P.ep.w     = 160;           % user had 250: the DG1 cantilever beyond the flange tips, n = (B - 0.8 bf)/2,
                            % is 77 at B = 250 (bearing side 1.60 with 12 mm Gr50); 160 gives n = 32
P.ep.over  = 26;            % above the top anchor row (edge distance; AISC Table J3.4M: 22 for M16),
                            % top edge rounded up to 5 mm: E, C1, CX 250 x 350 (as RAM), CY 250 x 380
P.ep.under = 25;            % below the bottom flange (RAM plate: 55): m = 31 for the bearing side
P.ep.under2 = 55;           % the user's RAM plate, compared in the plate study
P.ep.ztop  = 85;            % one plate for all types (user 2026-10-02): top at +85 (was CY: 56 + 29; CY now at 45); the
                            % holes are drilled to the surveyed anchors, at +29 or +56
P.ep.t     = 12;            % user 2026-10-02: 12 mm A36 (14 and 18 mm, and Gr50, not found)
P.ep.grade = 1;             % A36
% extra plate on the concrete face of the end plate, over the extension above the top flange:
% two pieces with a gap over the rib, each welded along the flange line (z = 0) and the rib
% line, so that each carries its share of the anchor pull straight to the same supports
% (two plates in parallel, not composite)
P.dbl.on  = 1;
P.dbl.t   = 12;  P.dbl.grade = 1;   % A36
P.dbl.gap = 24;             % over the rib; 12 mm left between the toes of the two inner fillets
P.dbl.w   = 6;              % fillets on the bottom edge (flange line) and the inner edge (rib line) only;
                            % the outer and top edges are flush with the end plate and are not welded
P.w.flange = 8;  P.w.web = 5;  % shop fillets, both sides
% rib on the web line above the top flange (AISC DG4 extended stiffened end plate, 4ES):
% needed at CY (12 mm plate, anchors 56 over the flange), used on every type (one detail)
P.rib.on = 1;
P.rib.t  = 12;              % >= t_web (Fy_beam/Fy_rib) = 6.2, DG4
P.rib.w  = 6;               % fillets both sides, to the end plate and to the flange
P.g = 30;                   % grout pad thickness (18 under the extra plate; check the grout's minimum)

% --- the user's RAM Connection model (anclaje voladizo.pdf) --------------------
% plate 250 x 351 x 12 centred on the IPE 240; anchors [v, plate coordinate from the centre]
P.ram.B = 250;  P.ram.N = 351;  P.ram.t = 12;
P.ram.anc = [75 80; 75 140; -75 80; -75 140; 0 140; 75 10; -75 10];
P.ram.keep = [1 1 1 1 1 0 0];   % user: the two at 10 are left out (5 anchors)
P.ram.Mu = 18.72;  P.ram.Vu = 17.02;  P.ram.Tmax = 15.11;   % id2 = 1.2D + L + E, kN m / kN
P.ram.hef = 330;  P.ram.eh = 72;
P.ram.key = [250 100 10];       % shear key b x depth x t
P.ram.caTop = 860;              % concrete above the top anchors assumed by RAM (tension breakout)

% --- supplementary U-bar over the top anchors (user 2026-10-03, "peace of mind") ---------
% The pull enters at the anchors (+29) and leaves along the beam top bars (-56 / -68): the
% compression from the back plate down to the bars needs a vertical tie at the plate, which ACI's
% anchor-reinforcement method leaves to the concrete. One U-bar per beam, standing across the beam,
% resting on top of both A1 just in front of the B1 nuts, legs down into the joint with 90 deg hooks.
% Not possible at CY (its anchors at +56 are right under the column hooks).
P.ub.on    = 0;             % DROPPED (user 2026-10-03): the level-A column hooks now rest on the A1 / B1 nuts
P.ub.db    = 16;            % one U-bar 16 (two 12 do not fit: the second lands on the grid-4 bar at u = 294)
P.ub.u     = 335;           % from the cantilever face; front nut on B1 at 350 (7 mm clear)
P.ub.v     = 75;            % leg axes at v = +-75: the corner arcs (inside diameter 4 d_b) clear the anchors
P.ub.zbot  = -250;          % hook tails, between the joint tie at -225 and the beam bottom bars
P.ub.types = [1 1 1 0];     % E, C1, CX yes; CY no

% --- border beam at the slab edge (user 2026-10-03/04): IPE 160 A36, simply supported between the cantilever
% tips (bb_calc, bb_page). Connection (user 2026-10-04, option a): a tip plate PL 10x150x240 welded across the end
% of each IPE 240 cantilever; the IPE 160 web bolted flat to it, its inner half-flanges (top and bottom) cut flush
% with the web over the plate (they would hit the cantilever). Bolt group centred on the cantilever web: 4 bolts at
% x = +-35 where the beam passes the tip; where two beams end at a tip (C9, D9) each takes the 2 bolts on its side.
P.bb.name = 'IPE 160';  P.bb.h = 160;  P.bb.b = 82;  P.bb.tw = 5.0;  P.bb.tf = 7.4;  P.bb.r = 9;
P.bb.tp   = [10 150 240];       % tip plate: thickness, width (across the cantilever), height
P.bb.wtp  = 5;                  % fillets of the tip plate to the IPE 240, all around
P.bb.bolt = 16;  P.bb.hole = 18;  P.bb.Fnv = 372;   % M16 ASTM A325 (or ISO 8.8), threads included: Table J3.2
P.bb.bx   = 35;                 % bolt columns at x = +-35 from the cantilever web (head 13 mm clear of its web fillet;
                                % at D3 the slab edge is 60 past the web: end distance 25 >= 22, Table J3.4M)
P.bb.bz   = [-50 -110];         % bolt rows (z), inside the clear web depth of the IPE 160
P.bb.gap  = 10;                 % between two beam ends at one tip
P.bb.cl   = 10;                 % cope beyond the tip plate edge
P.bb.ext  = 75;                 % beam end past the cantilever axis where it ends there alone (B9)
P.bb.tab  = [8 90 120];         % E9 corner: shear tab on the web of the east beam, 2 bolts

% --- IPE 200 floor beams to the concrete beams VCM (user's concept 2026-10-04, layout 2026-10-04) --------
% IPE 200 between grids 3 and 4 at the thirds (trib. 1443), spans A-B, B-C, C-D; reaction at each end into the
% VCM 30x35 of grids A, B, C, D through a plate on the face and 4 through rods Ø20 cast in the VCM (placed
% before the pour, plates drilled after measuring them). Web only welded to the plate (simple shear).
P.s2.name = 'IPE 200';  P.s2.h = 200;  P.s2.b = 100;  P.s2.tw = 5.6;  P.s2.tf = 8.5;  P.s2.r = 12;
P.s2.vb = 300;  P.s2.vh = 350;      % VCM width, depth
P.s2.pl = [10 300 300];             % plate PV: t, width, height, A36 (user)
P.s2.ztop = -10;                    % plate top below the top of the VCM (z = 0 = top of the IPE 200)
P.s2.z = [-40 -200];                % rod rows (user 2026-10-04): upper ON the VCM top bars (rod bottom -50 = top of the -56 bars), tied to them,
                                    % 310 from the soffit (cone 0.41; under the bars at -105: 0.49); lower raised from -260 (0.71) to -200 (0.40)
                                    % from -260 (cone 0.71) to -200 (0.40; upper row 0.45), with Ev x Omega0
P.s2.v = 110;                       % rods at +-110 from the IPE web axis
P.s2.db = 20;  P.s2.hole = 22;  P.s2.thr = 'M20x2.5';  P.s2.nut = [18 30];   % nut height, across flats
P.s2.wsh = [37 3];  P.s2.pp = 8;    % washer OD, t; thread past the nut
P.s2.w = 5;  P.s2.wz = [-25 -175];  % web fillet both sides, from z = -25 to -175
P.s2.gap = 10;                      % flanges to the plate (not welded)
P.s2.stir = 70;                     % VCM stirrups at +-70 from the IPE axis (spacing 140): rods 40 from a stirrup
P.s2.zbar = -56;                    % VCM top bars (axis), as the VCM
P.s2.bars = [-56 3; -68 2; -294 3; -282 2];   % VCM 5 + 5 Ø12 in the span (user): level, number (the 2 under / over the corner bars)

% --- placing tolerances --------------------------------------------------------
P.tol.ub = 25;                 % ends of the beam bars, ACI Table 26.6.2.1(b)
P.tol.zb = 13;                 % level of the beam bars, d > 200 mm, ACI Table 26.6.2.1(a)
P.tol.za = 15;                 % anchors: level, held by the template: +15 / -5 (E, C1, CX); CY +0 / -5. High
                               % anchors lift level B, and level A over it (cover down to cmin)
P.tol.ua = 10;                 % back plate set 10 short (nuts)

% --- frame forces at the edge pedestal, 1.2D + L - Ex (ETABS, at the faces) ---
P.frame.Mcol = 21.04;          % kN m, column
P.frame.Vcol = 15.65;          % kN
P.frame.Mb   = [26 5.126];     % kN m, the two edge beams (signs not certain: added)
P.room = [32 16];              % kN m left in the VCM / VCS for the support moment (rev. 2 report)
end
