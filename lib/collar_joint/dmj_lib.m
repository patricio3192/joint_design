% =====================================================================
%  dmj_lib.m   Diaphragm Moment Joint - function library  (v4)
%
%  Load it from a driver script with:   source('dmj_lib.m');
%  This file contains NO runs.  It only defines functions.
%
%  Contents
%    1. default_joint      section, plate, weld data        (edit here)
%    2. joint_checks       every limit state, tags T1..M5   (same as v3)
%    3. read_joint_file    reads your ETABS joint export
%    4. build_cases        turns rows into one load case per combination
%    5. run_joint          loops all combinations, prints the envelope
%
%  Checks and references are unchanged from v3; see the manual.
%  Units inside: N, mm.  The ETABS file is read in kN and kN*m.
% =====================================================================
1;   % DO NOT REMOVE: makes Octave treat this file as a script, so that
     % source() defines every function below.  Without it nothing loads.

% =====================================================================
% 1. DATA
% =====================================================================
function J = default_joint()
  J.E=200000; J.FEXX=480;
  % beam IPE 160, A36
  J.bm.h=160; J.bm.bf=82; J.bm.tf=7.4; J.bm.tw=5; J.bm.r=0;
  J.bm.Fy=250; J.bm.Fu=400; J.bm.Zx=123900;
  % column HSS 200x100x4.  D = face in the STRONG direction.
  J.cl.D=200; J.cl.B=100; J.cl.t=4; J.cl.Fy=250; J.cl.Fu=400;
  % collar plates
  J.pl.t_cap=12; J.pl.t_shf=12; J.pl.Fy=250; J.pl.Fu=400;
  J.pl.w_back=30;      % overhang on a side with NO beam
  J.pl.L_lap=80;       % lap over a beam flange (= weld length each side)
  % plate plan size is COMPUTED in plate_geometry() from the beams present
  % welds
  J.wl.leg_fl=5; J.wl.leg_col=4; J.wl.n_cap=1; J.wl.n_shf=1;
  % transverse weld across the flange end: 1 = present (shear lag U = 1.0
  % in T3), 0 = longitudinal welds only (U from AISC Table D3.1 case 4)
  J.wl.transverse=1;
  % column compression capacity from ETABS steel design; NaN = skip H1-1
  J.cl.phiPn = NaN;
  % seat
  % Reaction eccentricity from the column face, for S4.
  %   40 mm was the first bolt row of the bolted scheme.
  %   With the flange WELDED along the lap, the reaction sits nearer the
  %   face; 25 mm is realistic, 40 mm is the conservative bound.
  % Erection gap between the beam end and the column face.  The plate
  % overhang on a beam side is gap + L_lap, so the WELD keeps its full
  % length L_lap on each side of the flange.
  J.st.gap=15;
  % Reaction eccentricity from the column face.  With e_auto = 1 it is
  % computed as gap + L_lap/2, i.e. bearing uniform over the lap, the
  % conservative bound.  Set e_auto = 0 to enter e_react by hand.
  J.st.e_auto=1;
  J.st.e_react=50;
  % Optional rib under the shelf, one each side of every beam, welded to
  % the column wall and to the plate underside.  It turns the shelf from a
  % cantilever into a span between the column face and the rib.
  %   rib_t  = rib thickness, 0 = no rib
  %   rib_d  = rib depth below the plate
  %   rib_at = distance from the column face to the rib, 0 = at the plate edge
  J.st.rib_t=0; J.st.rib_d=60; J.st.rib_at=0;
  % Share of the vertical reaction taken by the SHELF plate.
  %   1.0 = shelf alone (conservative, and what fit-up guarantees)
  %   0.5 = shelf and cap share, a plastic mechanism needs a hinge in both
  J.st.share=.5;
  % Width of plate assumed to bend under the beam.
  %   1 = b_f, no dispersion (very conservative)
  %   2 = b_f + 2*e, 45 degree spread from the load
  %   3 = the same width used for the axial check, so one dispersion
  %       model is used for both actions (default)
  J.st.wmode=1;        % width of plate that works, see joint_checks
  % Width of the strip used for the S8 INTERACTION.  The same width is
  % used for BOTH the axial and the bending term: mixing two widths at
  % one section is not a valid interaction, and taking the wider one for
  % the axial term alone is unconservative.
  %   1 = b_f, no spread (default, needs no argument)
  %   2 = b_f + 2e, 45 degrees from the load
  %   3 = Whitmore, b_f + 2 L_lap tan30 (same as T4)

  % Shear tab for NL beams (class NL in joint_classes): the beam arrives
  % below the collar; a single plate welded to the column wall (fillets
  % both sides) is bolted to the beam web.  Checks P1..P11.
  J.nl.tp=6;  J.nl.Fy=250; J.nl.Fu=400;   % plate; tp <= Fu_col t / Fy (P9)
  J.nl.nb=2;  J.nl.db=16;  J.nl.dh=18;    % bolts: number, diameter, hole (standard)
  J.nl.Fnv=372;                           % bolt shear stress, A325M threads included
  J.nl.s=50;  J.nl.Lev=25;                % pitch, vertical edge distance
  J.nl.ea=40;                             % weld line to bolt line
  J.nl.Leh=30;                            % bolt line to plate free edge
  J.nl.gap=12;                            % beam end to column wall (max of the 5-12 mm range)
  J.nl.leg=4;                             % fillet leg, each side of the plate
  J.nl.face=J.cl.B;                       % face it lands on, set by joint_config
  % NL connection type: 'angle' = seat angle (default), 'tab' = shear tab.
  % The seat angle is welded to the column wall under the beam; the beam's
  % bottom flange sits on it and is welded to it.  The angle spans the
  % flat width of the column face, so its end welds sit next to the side
  % walls, which take the reaction in their plane.  Checks L1..L7.
  J.nl.type='angle';
  J.nl.ang=[75 75 6];                     % seat angle: vertical leg, outstanding leg, thickness
  J.nl.leg_a=4;                           % fillet, angle ends to the column wall (4 mm wall: no larger)
  J.nl.leg_f=4;                           % fillet, beam flange edges to the angle
  J.nl.La=[];                             % angle length; [] = face - 2(1.5 t) - 2 leg_a

  % IPE to IPE shear connections (beam framing into the web of another):
  % supported beam cut top and bottom (double cope), web fillet-welded to
  % the supporting web on both sides.  Checks V1..V6 in vv_checks.
  J.vv.dc=25;                             % cope depth, >= tf + r of the supporting beam + clearance
  J.vv.c=50;                              % cope length, >= (bf - tw)/2 of the supporting beam + clearance
  J.vv.R=12;                              % cope corner radius
  J.vv.leg=4;                             % fillet, each side of the web
  J.vv.Vmin=15e3;                         % design shear, N: at least this
end

  function C = chk(C, tag, name, ref, phiRn, Du, unit)
  if nargin<7, unit='F'; end
  C{end+1} = {tag,name,ref,phiRn,Du,Du/phiRn,unit};
end

% fillet weld, AISC J2.4 eq. J2-3, phi 0.75, no directional increase
function r = weldcap(leg, L, FEXX)
  r = 0.75*0.60*FEXX*0.707*leg*L;
end

% ---------------------------------------------------------------------
%  Plate plan size from the beams actually present.
%    nside(1) = number of sides with a beam in the STRONG direction (1 or 2)
%    nside(2) = same for the WEAK direction
%  Wx runs along the strong direction, Wy along the weak one.
% ---------------------------------------------------------------------
function J = plate_geometry(J, nside)
  p=J.pl; c=J.cl;
  ov = p.L_lap + J.st.gap;                 % overhang on a side WITH a beam
  if isfield(p,'oD') && ~isempty(p.oD)
    % strip on each side set by joint_config from the joint class
    J.pl.Wx = c.D + sum(p.oD);
    J.pl.Wy = c.B + sum(p.oB);
  else
    J.pl.Wx = c.D + nside(1)*ov + (2-nside(1))*p.w_back;
    J.pl.Wy = c.B + nside(2)*ov + (2-nside(2))*p.w_back;
  end
  if isfield(J.st,'e_auto') && J.st.e_auto
    J.pl.e_used = J.st.gap + p.L_lap/2;     % uniform bearing over the lap
  else
    J.pl.e_used = J.st.e_react;
  end
  J.st.e_react = J.pl.e_used;
  % margin of plate beside the column opening, transverse to each force
  J.pl.marg = [ (J.pl.Wy - c.B)/2 , (J.pl.Wx - c.D)/2 ];   % [strong weak]
  % plate width engaged by one flange: Whitmore spread at 30 deg,
  % limited by the plate itself (AISC Manual Part 9 concept)
  wt = [J.pl.Wy J.pl.Wx];
  for d=1:2
    J.pl.b_eff(d) = min(J.bm.bf + 2*p.L_lap*tand(30), wt(d));
  end
end

% =====================================================================
% 2. CHECKS FOR ONE LOAD CASE
%    cs.M    |beam end moment| per beam, N*mm   (magnitude only)
%    cs.V    beam reaction per beam, N, DOWNWARD positive
%    cs.Mcol [strong weak] column-top moment, N*mm, magnitudes
%    cs.Pu   column axial, N, compression positive
% =====================================================================
function C = joint_checks(J, cs)
  b=J.bm; c=J.cl; p=J.pl; w=J.wl;
  z = b.h + (p.t_cap + p.t_shf)/2;          % [MODEL] lever arm
  dpar = [c.D c.B];
  C = {};

  % ---- local checks --------------------------------------------------
  %  Flange force of each beam: moment couple plus half of any axial
  %  force in the beam (drag/collector), whichever beam is worst.
  Tb   = cs.M/z + abs(cs.N)/2;
  Tmax = max(Tb);
  % largest flange force in each direction, for the direction-dependent checks
  Td = [0 0];
  for i=1:numel(Tb), d=cs.dirb(i); Td(d)=max(Td(d),Tb(i)); end
  % beam sides in each direction (1 or 2; 0 = no beam), as in plate_geometry
  nside = [min(sum(cs.dirb==1),2) min(sum(cs.dirb==2),2)];

  % T1: Flange to plate weld (Base check)
  cap_T1 = weldcap(w.leg_fl, 2*p.L_lap + b.bf, J.FEXX);
  C = chk(C,'T1','flange to plate weld (3-sided)','J2.4 (J2-3)', cap_T1, Tmax);
  
  % T1a [INFO] flag, reported ONLY when T1 fails.  AISC J2.4(c), eq. J2-10:
  %   a group of longitudinal and transverse fillets of uniform leg,
  %   loaded through its centre of gravity, may take the larger of
  %   Rnwl + Rnwt (this is T1) and 0.85 Rnwl + 1.5 Rnwt.  The flag says
  %   the extra strength exists; T1 stays the check.
  if Tmax > cap_T1
    Rnwl = weldcap(w.leg_fl, 2*p.L_lap, J.FEXX);
    Rnwt = weldcap(w.leg_fl, b.bf, J.FEXX);
    C = chk(C,'T1a','T1 fails: weld group per J2-10 [INFO]','J2.4(c) (J2-10)', ...
        max(Rnwl + Rnwt, 0.85*Rnwl + 1.5*Rnwt), Tmax);
  end

  C = chk(C,'T2','beam flange gross yielding','J4.1 (J4-1)', 0.90*b.Fy*b.bf*b.tf, Tmax);
  % T3: tension rupture of the flange, J4.1(b): Rn = Fu Ae, Ae = U An.
  %   Shear lag factor U, AISC 360-16 Table D3.1:
  %   - with the transverse weld the load enters the flange directly,
  %     case 1: U = 1.0
  %   - longitudinal welds only, case 4 for a plate (x_bar = 0):
  %     U = 3 l^2 / (3 l^2 + w^2), l = weld length, w = flange width
  if ~isfield(w,'transverse') || w.transverse
    U = 1.0;
  else
    U = 3*p.L_lap^2 / (3*p.L_lap^2 + b.bf^2);
  end
  C = chk(C,'T3','beam flange rupture at the weld',sprintf('J4.1(b), D3 U=%.2f', U), ...
      0.75*b.Fu*U*b.bf*b.tf, Tmax);

  % T3b: Beam Flange Block Shear (AISC J4.3)
  %   Its tension plane is the whole flange section, which is T3 by
  %   itself; the shear planes only add to it, so T3b is always larger
  %   than T3 and cannot govern.  Kept for completeness.
  Agv_bf = 2 * p.L_lap * b.tf;
  Ant_bf = b.bf * b.tf;
  Rn_bs_bf = min(0.60*b.Fy*Agv_bf, 0.60*b.Fu*Agv_bf) + 1.0*b.Fu*Ant_bf;
  C = chk(C,'T3b','beam flange block shear','J4.3 (J4-5)', 0.75*Rn_bs_bf, Tmax);

  % T3c, T3d: Collar Plate Tear-out Block Shear, cap and shelf
  %   Shear planes in the plate along the two weld lines, tension plane
  %   across the flange width.  Each plate carries one flange.
  plt = {'T3c', 'cap', p.t_cap; 'T3d', 'shelf', p.t_shf};
  for q = 1:2
    Agv_pl = 2 * p.L_lap * plt{q,3};
    Ant_pl = b.bf * plt{q,3};
    Rn_bs_pl = min(0.60*p.Fy*Agv_pl, 0.60*p.Fu*Agv_pl) + 1.0*p.Fu*Ant_pl;
    C = chk(C,plt{q,1},[plt{q,2} ' plate block shear tear-out'],'J4.3 (J4-5)', 0.75*Rn_bs_pl, Tmax);
  end

  nm = {'strong','weak'};
  for d=1:2
    if Td(d)==0, continue; end
    % plate yielding over the Whitmore width
    C = chk(C,['T4' nm{d}(1)],['plate yielding at the lap, ' nm{d}],'J4.1 (J4-1)', ...
        0.90*p.Fy*p.b_eff(d)*p.t_cap, Td(d));
    % strips beside the opening: tension, then compression as a short column
    A_str = 2*p.marg(d)*p.t_cap;
    C = chk(C,['T5' nm{d}(1)],['plate strips tension, ' nm{d} ' [MODEL]'],'J4.1 (J4-1)', ...
        0.90*p.Fy*A_str, Td(d));
    rgy = p.t_cap/sqrt(12);  KL_r = 0.65*dpar(d)/rgy;  Fe = pi^2*J.E/KL_r^2;
    if KL_r <= 4.71*sqrt(J.E/p.Fy), Fcr = 0.658^(p.Fy/Fe)*p.Fy; else, Fcr = 0.877*Fe; end
    C = chk(C,['T6' nm{d}(1)],['plate strips compression, ' nm{d} ' [MODEL]'],'E3 (E3-2)', ...
        0.90*Fcr*A_str, Td(d));
        
    % T12 [INFO]: Cap Plate In-Plane Bending (Point 4)
    % Evaluates eccentric force transfer causing in-plane moment on the strips
    M_inplane = (Td(d) / 2) * (p.marg(d) / 2) * 2;
    Z_strip = p.t_cap * p.marg(d)^2 / 4;
    C = chk(C,['T12' nm{d}(1)],['plate in-plane bending, ' nm{d} ' [INFO]'],'cf. F11.1', ...
        0.90 * p.Fy * (2 * Z_strip), M_inplane, 'M');

    % T13 [INFO]: Overhang Wing Buckling (Point 5), EDGE and CORNER joints only
    % Evaluates the unbraced back-width as a stub column.  A w_back wing
    % lies beside the opening, across the force of direction d, on each
    % side of the OTHER direction that has no beam: nw = 2 - nside(3-d).
    % Interior joints have none, so the check is skipped there.
    if isfield(p,'nwing'), nw = p.nwing(d); else, nw = 2 - nside(3-d); end
    if nw > 0
      KL_wing = 1.0 * (p.L_lap + J.st.gap);
      Fe_wing = pi^2 * J.E / (KL_wing/rgy)^2;
      if (KL_wing/rgy) <= 4.71*sqrt(J.E/p.Fy), Fcr_wing = 0.658^(p.Fy/Fe_wing) * p.Fy; else, Fcr_wing = 0.877 * Fe_wing; end
      wt_total = 2*p.marg(d) + dpar(3-d);          % plate width across the force
      wing_demand = Td(d) * (nw * p.w_back / wt_total);
      C = chk(C,['T13' nm{d}(1)],['overhang wing buckling, ' nm{d} ' [INFO]'],'E3', ...
          0.90 * Fcr_wing * (nw * p.w_back * p.t_cap), wing_demand);
    end

    % T10 [INFO] balanced (through) force taken by the COLUMN WALL instead
    %  of the plate.  Two opposite beams pull the wall apart along its
    %  length: the wall carries it as in-plane tension, over a depth taken
    %  as half the wall length (45 degree spread from the loaded edge).
    %  This path is NOT required: T5/T6 already carry the same force in
    %  the plate.  Reported so the alternative path is visible.
    A_wall = 2*(dpar(d)/2)*c.t;
    C = chk(C,['T10' nm{d}(1)],['wall in-plane tension, ' nm{d} ' [INFO]'],'alt. path', ...
        0.90*c.Fy*A_wall, Td(d));
    % T11 [INFO] the side wall carries three actions at the same point:
    %   sigma_h  horizontal, the through force (the T10 mechanism)
    %   sigma_v  vertical, column axial + bending at the extreme fibre
    %   tau      the net force as shear over the stub height
    % Combined with von Mises against 0.90 Fy.  Stresses are taken from
    % the SAME load case, so no envelope-on-envelope.
    Ac  = 2*c.t*(c.D + c.B - 2*c.t);
    if d==1, Sc = (c.B*c.D^3-(c.B-2*c.t)*(c.D-2*c.t)^3)/12/(c.D/2);
    else,    Sc = (c.D*c.B^3-(c.D-2*c.t)*(c.B-2*c.t)^3)/12/(c.B/2); end
    sh = Td(d)/A_wall;
    sv = abs(cs.Pu)/Ac + cs.Mcol(d)/Sc;
    tau= (cs.Mcol(d)/z)/(2*dpar(d)*c.t);
    svm= sqrt(sh^2 + sv^2 - sh*sv + 3*tau^2);
    C = chk(C,['T11' nm{d}(1)],['wall stress interaction, ' nm{d} ' [INFO]'],'von Mises', ...
        0.90*c.Fy, svm, 'S');
  end

  % ---- anchorage per direction: net force = column-top moment / z ----

  tg = {{'T7s','T8s','T9s'},{'T7w','T8w','T9w'}};
  for d=1:2
    Tanc = cs.Mcol(d)/z;
    C = chk(C,tg{d}{1},['collar weld to column, ' nm{d}],'J2.4 (J2-3)', ...
        weldcap(w.leg_col, w.n_cap*2*dpar(d), J.FEXX), Tanc);
    C = chk(C,tg{d}{2},['column walls shear, ' nm{d}],'J4.2 (J4-3)', ...
        0.90*0.60*c.Fy*2*dpar(d)*c.t, Tanc);
    be = min(dpar(d), b.bf + 5*p.t_cap);
    C = chk(C,tg{d}{3},['wall local yielding, ' nm{d} ' [MODEL]'],'cf. J10.2', ...
        0.90*c.Fy*c.t*be, Tanc);
    % ---- informative cross-check: CIDECT DG9 Table 8.3 eq.(2) ---------
    %  Ultimate resistance of an EXTERNAL DIAPHRAGM on an RHS column
    %  (Kamba 2001, Tabuchi et al. 1985).  Derived for SQUARE columns and
    %  for the ranges printed below; ours is rectangular and t_d/t_c is
    %  outside the tested range, so this is a comparison only, never the
    %  design basis.  bc = smaller column face (conservative: P ~ bc^1/3).
    bc = min(c.D,c.B);  hd = p.L_lap;  td = p.t_cap;
    Pbf = 3.17*(c.t/bc)^(2/3)*(td/bc)^(2/3)*((c.t+hd)/bc)^(1/3)*bc^2*p.Fu;
    C = chk(C,['Tc' nm{d}(1)],['CIDECT DG9 T8.3(2), ' nm{d} ' [INFO]'],'CIDECT 8.6', ...
        Pbf, Tanc);
  end

  
  % ---- seat ------------------------------------------------------------
  Vseat = cs.V(:);                     % moment beams and S beams sit on the shelf
  if isfield(cs,'Vs'), Vseat = [Vseat; cs.Vs(:)]; end
  Vmax = max([Vseat; 0]);
  lb = p.L_lap;  k = b.tf + b.r;
  C = chk(C,'S1','beam web local yielding','J10.2 (J10-3)', ...
      1.00*b.Fy*b.tw*(2.5*k+lb), Vmax);
  if lb/b.h > 0.2
    Rn = 0.40*b.tw^2*(1+(4*lb/b.h-0.2)*(b.tw/b.tf)^1.5)*sqrt(J.E*b.Fy*b.tf/b.tw); rf='J10.3 (J10-5b)';
  else
    Rn = 0.40*b.tw^2*(1+3*(lb/b.h)*(b.tw/b.tf)^1.5)*sqrt(J.E*b.Fy*b.tf/b.tw);     rf='J10.3 (J10-5a)';
  end
  C = chk(C,'S2','beam web crippling at the end',rf, 0.75*Rn, Vmax);
  C = chk(C,'S3','bearing on the shelf plate','J7 (J7-1)', 0.75*1.8*p.Fy*b.bf*lb, Vmax);
  % ---- seat: the width of plate that works ---------------------------
  %  J.st.wmode : 1 = b_f, no dispersion (very conservative)
  %               2 = b_f + 2e, 45 degree spread from the load
  %               3 = Whitmore, b_f + 2 L_lap tan30
  %               4 = support-based: the wall the beam faces, plus a
  %                   30 degree spread onto the corners (default).  This
  %                   is the root of the cantilever, which is what
  %                   actually limits the bending width.
  %               5 = the facing wall alone, no corner help (floor)
  %  The SAME width is used for the axial force and for the bending, so
  %  one dispersion model governs both.  It is capped by the geometry:
  %  the wall facing the beam plus a 45 degree spread onto the side walls.
  wall = min(c.D, c.B);                 % wall the beam cantilevers from
  switch J.st.wmode
    case 1, bw = b.bf;
    case 2, bw = b.bf + 2*J.st.e_react;
    case 3, bw = p.b_eff(1);
    case 5, bw = wall;
    otherwise, bw = wall + 2*J.st.e_react*tand(30);
  end
  bw = min(bw, min(c.D,c.B) + 2*J.st.e_react);
  Zs = bw*p.t_shf^2/4;  Ss = bw*p.t_shf^2/6;
  Mn_shf = 0.90*min(p.Fy*Zs, 1.6*p.Fy*Ss);        % F11.1 (F11-1)

  % S10: Shelf Plate Gross Shear Yielding (Point 3)
  %   Same part of the reaction as S4 and S8: share x V.
  C = chk(C,'S10','shelf plate gross shear at root','J4.2 (J4-3)', ...
      1.00 * 0.60 * p.Fy * bw * p.t_shf, J.st.share*Vmax);

  % ---- S4 bending of the shelf ---------------------------------------
  ee = J.st.e_react;
  if J.st.rib_t > 0
    a = J.st.rib_at;  if a<=0, a = J.st.gap + p.L_lap; end
    if ee < a
      M_S4 = J.st.share*Vmax*ee*(a-ee)/a;         % simple span, face to rib
      Rrib = Vmax*ee/a;
    else
      M_S4 = J.st.share*Vmax*(ee-a);  Rrib = Vmax;
    end
  else
    M_S4 = J.st.share*Vmax*ee;                    % cantilever from the face
    Rrib = 0;
  end
  C = chk(C,'S4','shelf plate bending','F11.1 (F11-1)', Mn_shf, M_S4, 'M');

  % ---- S9 ribs, when present ------------------------------------------
  if J.st.rib_t > 0
    C = chk(C,'S9a','rib in shear (2 ribs per beam)','J4.2 (J4-3)', ...
        1.00*0.60*p.Fy*2*J.st.rib_t*J.st.rib_d, Rrib);
    C = chk(C,'S9b','rib welds to wall and plate','J2.4 (J2-3)', ...
        weldcap(w.leg_fl, 2*2*J.st.rib_d, J.FEXX), Rrib);
        
    % S9c: HSS Wall Base Metal Shear Rupture at Ribs
    % The vertical shear is transferred along the two sides of each rib.
    % 2 ribs * 2 failure planes per rib = 4 planes of length rib_d
    shear_area = 4 * J.st.rib_d * c.t;
    C = chk(C,'S9c','HSS wall shear rupture at ribs','J4.2 (J4-4)', ...
        0.75 * 0.60 * c.Fu * shear_area, Rrib);
  end

  % ---- S8 axial and bending on the SAME strip -------------------------
  %  Exact plastic interaction for a rectangle: Mred = Mp (1 - n^2).
  %  Axial load consumes the middle of the section, where the bending
  %  lever arm is smallest, so the interaction is quadratic, not linear.
  Npl = 0.90*p.Fy*bw*p.t_shf;
  nn  = min(max(cs.M)/z / Npl, 1.0);
  C = chk(C,'S8','shelf: axial + bending [Mp(1-n^2)]','F11 / plastic', ...
      Mn_shf*(1-nn^2), M_S4, 'M');
  C = chk(C,'S5','shelf to column weld','J2.4 (J2-3)', ...
      weldcap(w.leg_col, w.n_shf*2*(c.D+c.B), J.FEXX), Vmax);
  hw=(b.h-2*(b.tf+b.r))/b.tw;
  if hw<=2.24*sqrt(J.E/b.Fy), phiv=1.00; else, phiv=0.90; end
  C = chk(C,'S6','beam web shear','G2.1 (G2-1)', phiv*0.6*b.Fy*b.h*b.tw, max(abs(Vseat)));
  % uplift: with welded flanges there is no bearing, the weld carries it
  Vup = max([-cs.V(:); 0]);
  if Vup > 0
    C = chk(C,'S7','flange weld under uplift','J2.4 (J2-3)', ...
        weldcap(w.leg_fl, 2*p.L_lap + b.bf, J.FEXX), Vup);
  end

  % ---- S beams: shear only, bottom flange welded to the shelf ----------
  %  The reaction goes down by bearing (S1..S8).  The bottom flange weld
  %  (same 3-sided weld as the moment beams) carries the beam axial force
  %  and any uplift; the top flange is free under the cap.
  if isfield(cs,'Vs') && ~isempty(cs.Vs)
    Rs = max(sqrt(cs.Ns.^2 + max(-cs.Vs,0).^2));
    C = chk(C,'S11','S beam: bottom flange weld, N + uplift','J2.4 (J2-3)', ...
        weldcap(w.leg_fl, 2*p.L_lap + b.bf, J.FEXX), Rs);
  end

  % ---- NL beams: single plate (shear tab) below the collar -------------
  %  Plate welded to the column wall, bolted to the beam web.  [MODEL]
  %  hinge at the bolt line: bolts take the force only, the weld to the
  %  wall takes it with the moment V ea.  V and N are the largest of any
  %  NL beam at the joint, taken together (conservative).
  if isfield(cs,'Vl') && ~isempty(cs.Vl) && isfield(J.nl,'type') && strcmp(J.nl.type,'angle')
    C = seat_checks(J, C, cs);
  elseif isfield(cs,'Vl') && ~isempty(cs.Vl)
    q  = J.nl;
    Vn = max(abs(cs.Vl));  Nn = max(abs(cs.Nl));  Rn_ = sqrt(Vn^2 + Nn^2);
    Ab = pi*q.db^2/4;
    rb = @(lc, t, Fu) min(1.2*lc*t*Fu, 2.4*q.db*t*Fu);      % J3.10 (J3-6a, J3-6c)
    C = chk(C,'P1','tab: bolt shear','J3.6 (J3-1)', 0.75*q.Fnv*Ab*q.nb, Rn_);
    C = chk(C,'P2','tab: bolt bearing on the plate','J3.10 (J3-6)', ...
        0.75*(rb(q.Lev - q.dh/2, q.tp, q.Fu) + (q.nb-1)*rb(q.s - q.dh, q.tp, q.Fu)), Vn);
    C = chk(C,'P3','tab: bolt bearing on the beam web','J3.10 (J3-6)', ...
        0.75*((q.nb-1)*rb(q.s - q.dh, b.tw, b.Fu) + 2.4*q.db*b.tw*b.Fu), Vn);
    if Nn > 0
      C = chk(C,'P4','tab: web tear-out to the beam end (N)','J3.10 (J3-6c)', ...
          0.75*q.nb*rb(q.ea - q.gap - q.dh/2, b.tw, b.Fu), Nn);
    end
    hp = 2*q.Lev + (q.nb-1)*q.s;                             % plate height
    C = chk(C,'P5','tab: plate shear yielding','J4.2 (J4-3)', 1.00*0.60*q.Fy*hp*q.tp, Vn);
    C = chk(C,'P6','tab: plate shear rupture','J4.2 (J4-4)', ...
        0.75*0.60*q.Fu*(hp - q.nb*q.dh)*q.tp, Vn);
    Agv = (q.Lev + (q.nb-1)*q.s)*q.tp;  Anv = Agv - (q.nb-0.5)*q.dh*q.tp;
    Ant = (q.Leh - q.dh/2)*q.tp;
    C = chk(C,'P7','tab: plate block shear','J4.3 (J4-5)', ...
        0.75*(min(0.60*q.Fu*Anv, 0.60*q.Fy*Agv) + 1.0*q.Fu*Ant), Vn);
    % weld to the wall, two lines of length hp, elastic: shear V, moment
    % V ea and axial N; per mm of weld line
    fv = Vn/(2*hp);  fm = 6*Vn*q.ea/(2*hp^2);  fn = Nn/(2*hp);
    fr = sqrt(fv^2 + (fm + fn)^2);
    C = chk(C,'P8','tab: welds to the column wall (V, V ea, N)','J2.4 (J2-3)', ...
        weldcap(q.leg, 2*hp, J.FEXX), fr*2*hp);
    C = chk(C,'P9','tab: wall vs plate, tp <= Fu t/Fy','360-10 K1.2, Manual Part 10', ...
        c.Fu*c.t/q.Fy, q.tp, 'L');
    C = chk(C,'P10','tab: beam web net shear rupture','J4.2 (J4-4)', ...
        0.75*0.60*b.Fu*(b.h - q.nb*q.dh)*b.tw, Vn);
    C = chk(C,'P11','tab: face B/t <= 40 [INFO]','360-10 Table K1.2A', 40, q.face/c.t, 'R');
  end

  % ---- members (column interaction is left to ETABS) -----------------
  C = chk(C,'M1','beam flexure (no flange holes)','F2.1 (F2-1)', ...
      0.90*b.Zx*b.Fy, max(cs.M), 'M');
  Zcx=c.B*c.D^2/4-(c.B-2*c.t)*(c.D-2*c.t)^2/4;
  Zcy=c.D*c.B^2/4-(c.D-2*c.t)*(c.B-2*c.t)^2/4;
  C = chk(C,'M4','column flexure, strong','F7.1 (F7-1)', 0.90*Zcx*c.Fy, cs.Mcol(1),'M');
  C = chk(C,'M5','column flexure, weak','F7.1 (F7-1)',   0.90*Zcy*c.Fy, cs.Mcol(2),'M');
  if isfield(c,'phiPn') && ~isnan(c.phiPn) && c.phiPn>0
    pr = cs.Pu/c.phiPn;
    mr = cs.Mcol(1)/(0.90*Zcx*c.Fy) + cs.Mcol(2)/(0.90*Zcy*c.Fy);
    if pr>=0.2, rat = pr + 8/9*mr; rf='H1.1 (H1-1a)'; else, rat = pr/2 + mr; rf='H1.1 (H1-1b)'; end
    C = chk(C,'M6','column P-M-M interaction',rf, 1.0, rat);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% =====================================================================
% 2b. SEAT ANGLE for NL beams (the beam arrives below the collar)
%     AISC Manual Part 10 unstiffened seat, with J10 for the beam web.
%     Reaction R = largest downward V of any NL beam; N = its axial force.
% =====================================================================
function C = seat_checks(J, C, cs)
  b=J.bm; c=J.cl; q=J.nl;
  tA = q.ang(3);  Lv = q.ang(1);  Lo = q.ang(2);
  La = q.La;
  if isempty(La), La = q.face - 2*1.5*c.t - 2*q.leg_a; end
  R  = max([cs.Vl(:); 0]);  Nn = max(abs(cs.Nl));  Rup = max([-cs.Vl(:); 0]);
  lb = Lo - q.gap;                                  % bearing length on the seat
  k  = b.tf + b.r;
  C = chk(C,'L1','seat: beam web local yielding','J10.2 (J10-3)', ...
      1.00*b.Fy*b.tw*(2.5*k + lb), R);
  if lb/b.h > 0.2
    Rn = 0.40*b.tw^2*(1+(4*lb/b.h-0.2)*(b.tw/b.tf)^1.5)*sqrt(J.E*b.Fy*b.tf/b.tw); rf='J10.3 (J10-5b)';
  else
    Rn = 0.40*b.tw^2*(1+3*(lb/b.h)*(b.tw/b.tf)^1.5)*sqrt(J.E*b.Fy*b.tf/b.tw);     rf='J10.3 (J10-5a)';
  end
  C = chk(C,'L2','seat: beam web crippling',rf, 0.75*Rn, R);
  % outstanding leg in bending, critical section t + 10 mm from the back
  % of the angle (Manual Part 10), reaction at the middle of the bearing
  e  = max(q.gap + lb/2 - (tA + 10), 0);
  C = chk(C,'L3','seat: angle leg bending','F11.1 (F11-1)', ...
      0.90*J.pl.Fy*La*tA^2/4, R*e, 'M');
  C = chk(C,'L4','seat: angle leg shear yielding','J4.2 (J4-3)', ...
      1.00*0.60*J.pl.Fy*La*tA, R);
  % welds at the two ends of the vertical leg, length Lv each, elastic:
  % shear R, moment R ew, axial N; per mm of weld line
  ew = q.gap + lb/2;
  fv = R/(2*Lv);  fm = 3*R*ew/Lv^2;  fn = Nn/(2*Lv);
  C = chk(C,'L5','seat: angle end welds to the wall','J2.4 (J2-3)', ...
      weldcap(q.leg_a, 2*Lv, J.FEXX), sqrt(fv^2 + (fm + fn)^2)*2*Lv);
  % [MODEL] the end welds sit next to the side walls, which carry the
  % reaction in their plane
  C = chk(C,'L6','seat: side walls in shear [MODEL]','J4.2 (J4-3)', ...
      1.00*0.60*c.Fy*c.t*2*Lv, R);
  C = chk(C,'L7','seat: flange welds to the angle (N, uplift)','J2.4 (J2-3)', ...
      weldcap(q.leg_f, 2*lb, J.FEXX), sqrt(Nn^2 + Rup^2));
end

% =====================================================================
% 2c. IPE TO IPE SHEAR CONNECTION
%     Supported beam double coped (dc top and bottom, length c), web
%     fillet-welded to the supporting web on both sides over the remaining
%     depth.  V = design shear (N), nsup = beams framing into the same
%     supporting web at that point (1 or 2), for its web shear.
%     AISC 360-16 J4, J2.4 and Manual Part 9 (coped beams).
% =====================================================================
function C = vv_checks(J, V, nsup)
  b = J.bm;  q = J.vv;
  V  = max(V, q.Vmin);
  ho = b.h - 2*q.dc;                               % web left after the copes
  C = {};
  C = chk(C,'V1','coped web: shear yielding','J4.2 (J4-3)', 1.00*0.60*b.Fy*ho*b.tw, V);
  C = chk(C,'V2','coped web: shear rupture','J4.2 (J4-4)', 0.75*0.60*b.Fu*ho*b.tw, V);
  Sn = b.tw*ho^2/6;
  C = chk(C,'V3','coped web: flexural yielding at the cope','Manual Part 9', ...
      0.90*b.Fy*Sn, V*q.c, 'M');
  fd  = 3.5 - 7.5*q.dc/b.h;                        % double cope, dc <= 0.2 d
  Fcr = min(0.62*pi*J.E*b.tw^2*fd/(q.c*ho), b.Fy);
  C = chk(C,'V4','coped web: local buckling (double cope)','Manual Part 9', ...
      0.90*Fcr*Sn, V*q.c, 'M');
  C = chk(C,'V5','web to web fillet welds, both sides','J2.4 (J2-3)', ...
      weldcap(q.leg, 2*ho, J.FEXX), V);
  C = chk(C,'V6','supporting web: shear rupture at the welds','J4.2 (J4-4)', ...
      0.75*0.60*b.Fu*b.tw*ho, nsup*V);
end

% =====================================================================
% 3. READ THE ETABS JOINT FILE
%    Each data line:  Frame Type End <case name, may contain spaces> v1..v6
%    Section A = member local axes, section B = forces on the joint.
% =====================================================================
function [A, B] = read_joint_file(fname)
  fid = fopen(fname,'r');
  if fid<0, error('cannot open %s', fname); end
  A = struct('frame',{},'type',{},'endc',{},'case',{},'v',{});
  B = A;  sec = '';
  while true
    ln = fgetl(fid);  if ~ischar(ln), break; end
    s = strtrim(ln);
    if isempty(s) || strncmp(s,'===',3) || strncmp(s,'Frame',5), continue; end
    if strncmp(s,'A)',2), sec='A'; continue; end
    if strncmp(s,'B)',2), sec='B'; continue; end
    tk = strsplit(s);  tk = tk(~cellfun(@isempty,tk));
    if numel(tk) < 10, continue; end
    r.frame = str2double(tk{1});
    r.type  = tk{2};
    r.endc  = tk{3};
    r.case  = strjoin(tk(4:end-6),' ');
    r.v     = str2double(tk(end-5:end));
    if any(isnan(r.v)), error('bad numbers in line: %s', ln); end
    if sec=='A', A(end+1)=r; else, B(end+1)=r; end
  end
  fclose(fid);
end

function r = getrow(T, frame, cname)
  r = [];
  for i=1:numel(T)
    if T(i).frame==frame && strcmp(T(i).case,cname), r = T(i).v; return; end
  end
  error('no row for frame %d, case "%s"', frame, cname);
end

% =====================================================================
% 4. BUILD LOAD CASES
%    map.strong   frames of the beams in the STRONG direction
%    map.weak     frames of the beams in the WEAK direction
%    map.col      frame of the column below the joint
%    map.colM     column local moment for the strong direction: 'M3' or 'M2'
%    map.skip     cases containing this text are ignored, e.g. 'RSA'
%
%    Values taken:
%      beam |M|  = |M3| from section A (member local, major axis)
%      beam V    = -F1  from section B (F1 is vertical in column axes;
%                  negative = pushing the joint down)
%      column    = M3, M2 and P from section A
%    Max/Min rows of static combinations are identical; duplicates are
%    dropped automatically.
% =====================================================================
function [cs, info] = build_cases(A, B, map)
  names = unique({A.case},'stable');
  names = names(cellfun(@isempty, strfind(names, map.skip)));
  beams = [map.strong map.weak];
  dirb  = [ones(1,numel(map.strong)) 2*ones(1,numel(map.weak))];
  if strcmp(map.colM,'M3'), ic=[6 5]; else, ic=[5 6]; end   % [strong weak] in v(4:6)
  cs = struct('name',{},'M',{},'V',{},'N',{},'dirb',{},'Mcol',{},'Pu',{},'res',{});
  keys = {};
  for n=1:numel(names)
    nm = names{n};
    M = zeros(1,numel(beams)); V = M; N = M;
    for i=1:numel(beams)
      a = getrow(A, beams(i), nm);  bb = getrow(B, beams(i), nm);
      M(i) = abs(a(6))*1e6;          % kN*m -> N*mm
      V(i) = -bb(1)*1e3;             % kN -> N, downward positive
      N(i) = a(1)*1e3;               % beam axial force, N
    end
    ac = getrow(A, map.col, nm);  bc = getrow(B, map.col, nm);
    Mcol = abs([ac(ic(1)) ac(ic(2))])*1e6;
    Pu   = -ac(1)*1e3;
    % EQUILIBRIUM + MAPPING CHECK, in column axes (kN*m).
    % Strong direction: column moment + moments of the beams you declared
    % as STRONG must sum to ~0.  Same for weak.  Only the declared beams
    % are summed, so a wrong map.strong / map.weak / map.colM leaves a
    % large residual (the missing beam moments) and is flagged.
    rs = bc(ic(1)); rw = bc(ic(2));
    for i=1:numel(beams)
      bb = getrow(B, beams(i), nm);
      if dirb(i)==1, rs = rs + bb(ic(1)); else, rw = rw + bb(ic(2)); end
    end
    % drop exact duplicates (Max = Min for static combinations)
    key = sprintf('%.3f ', [M V N Mcol Pu]);
    if any(strcmp(keys,key)), continue; end
    keys{end+1} = key;
    cs(end+1) = struct('name',nm,'M',M,'V',V,'N',N,'dirb',dirb, ...
                       'Mcol',Mcol,'Pu',Pu,'res',[rs rw]);
  end
  info.beams = beams; info.dirb = dirb;
end

% =====================================================================
% 5. RUN ALL CASES, PRINT PER-CASE SUMMARY AND ENVELOPE
% =====================================================================
function E = run_joint(J, fname, map, title_str)
  [A,B] = read_joint_file(fname);
  [cs, info] = build_cases(A,B,map);
  E = report_joint(J, cs, map, sprintf('%s  [file %s]', title_str, fname));
end

% =====================================================================
% 5b. CASES FROM THE joint_forces() TOOLKIT
%     res = output of joint_forces(M, joint), already filtered to the
%     combinations you want.  Fields used: frame, type, endIJ, ocase,
%     ctype, loc = [P V2 V3 T M2 M3], ref = [F1 F2 F3 M1 M2 M3] on the
%     joint in the reference axes (use the COLUMN's axes).
% =====================================================================
function cs = cases_from_res(res, map)
  strong = cellfun(@num2str, num2cell(map.strong), 'uni', 0);
  weak   = cellfun(@num2str, num2cell(map.weak),   'uni', 0);
  colf   = num2str(map.col);
  beams  = [strong weak];
  dirb   = [ones(1,numel(strong)) 2*ones(1,numel(weak))];
  if strcmp(map.colM,'M3'), ic=[6 5]; else, ic=[5 6]; end

  names = unique({res.ocase},'stable');
  if isfield(map,'skip') && ~isempty(map.skip)
    names = names(cellfun(@isempty, strfind(names, map.skip)));
  end
  % shear-only beams (class S, on the shelf) and beams below the collar
  % (class NL, shear tab): only their V and N are used
  shr = {};  nlb = {};
  if isfield(map,'shear'), shr = cellfun(@num2str, num2cell(map.shear), 'uni', 0); end
  if isfield(map,'nl'),    nlb = cellfun(@num2str, num2cell(map.nl),    'uni', 0); end
  cs = struct('name',{},'M',{},'V',{},'N',{},'dirb',{},'Mcol',{},'Pu',{},'res',{}, ...
              'Vs',{},'Ns',{},'Vl',{},'Nl',{});
  keys = {};
  for n=1:numel(names)
    nm = names{n};
    sel = strcmp({res.ocase}, nm);
    M=zeros(1,numel(beams)); V=M; N=M; rs=0; rw=0; ok=true;
    [Vs, Ns, oks] = shear_beams(res, sel, shr);
    [Vl, Nl, okl] = shear_beams(res, sel, nlb);
    ok = oks && okl;
    for i=1:numel(beams)
      k = find(sel & strcmp({res.frame}, beams{i}), 1);
      if isempty(k), ok=false; break; end
      M(i) = abs(res(k).loc(6))*1e6;      % member major-axis moment
      N(i) =     res(k).loc(1)*1e3;       % beam axial
      V(i) =    -res(k).ref(1)*1e3;       % downward on the joint
      if dirb(i)==1, rs = rs + res(k).ref(ic(1)); else, rw = rw + res(k).ref(ic(2)); end
    end
    kc = find(sel & strcmp({res.frame}, colf), 1);
    if ~ok || isempty(kc), continue; end
    Mcol = abs([res(kc).loc(ic(1)) res(kc).loc(ic(2))])*1e6;
    Pu   = -res(kc).loc(1)*1e3;
    rs   = rs + res(kc).ref(ic(1));  rw = rw + res(kc).ref(ic(2));
    key  = sprintf('%.3f ', [M V N Mcol Pu Vs Ns Vl Nl]);
    if any(strcmp(keys,key)), continue; end       % Max = Min duplicates
    keys{end+1} = key;
    cs(end+1) = struct('name',nm,'M',M,'V',V,'N',N,'dirb',dirb, ...
                       'Mcol',Mcol,'Pu',Pu,'res',[rs rw], ...
                       'Vs',Vs,'Ns',Ns,'Vl',Vl,'Nl',Nl);
  end
  if isempty(cs), error('no complete load case found: check map.strong/weak/col'); end
end

% V (downward on the joint, N) and N (axial, N) of a list of beams in one case
function [V, N, ok] = shear_beams(res, sel, frames)
  V = zeros(1, numel(frames));  N = V;  ok = true;
  for i = 1:numel(frames)
    k = find(sel & strcmp({res.frame}, frames{i}), 1);
    if isempty(k), ok = false; return; end
    V(i) = -res(k).ref(1)*1e3;
    N(i) =  res(k).loc(1)*1e3;
  end
end

function E = run_joint_res(J, res, map, title_str)
  cs = cases_from_res(res, map);
  E  = report_joint(J, cs, map, title_str);
end

% =====================================================================
% 5c. REPORT
% =====================================================================
function E = report_joint(J, cs, map, title_str)
  nside = [min(numel(map.strong),2) min(numel(map.weak),2)];
  J = plate_geometry(J, nside);

  printf('\n================ %s ================\n', title_str);
  printf('strong beams %s | weak beams %s | column %d (%s = strong)\n', ...
     mat2str(map.strong), mat2str(map.weak), map.col, map.colM);
  if isfield(map,'sides')
    printf('class W N E S: %s | shear on shelf %s | below collar (tab) %s\n', ...
       strjoin(map.sides,' '), mat2str(map.shear), mat2str(map.nl));
  end
  printf('%d load cases after filtering and removing duplicates\n', numel(cs));
  printf('PLATES: %.0f x %.0f mm  | cap %.0f mm, shelf %.0f mm | weld lap %.0f + gap %.0f, back %.0f\n', ...
     J.pl.Wx, J.pl.Wy, J.pl.t_cap, J.pl.t_shf, J.pl.L_lap, J.st.gap, J.pl.w_back);
  printf('        strips beside the opening: %.0f mm (strong), %.0f mm (weak)\n', ...
     J.pl.marg(1), J.pl.marg(2));
  wl={'one line, upper face','both faces'};
  printf('WELDS : flange to plate %.0f mm 3-sided | collar %.0f mm | shelf collar: %s\n', ...
     J.wl.leg_fl, J.wl.leg_col, wl{J.wl.n_shf});
  swm={'b_f (no spread)','b_f + 2e (45 deg)','Whitmore', ...
       'wall + 2e tan30 (support-based)','facing wall alone'};
  if J.st.rib_t>0
    printf('RIBS  : %.0f mm thick x %.0f mm deep, 2 per beam, at the plate edge\n', ...
       J.st.rib_t, J.st.rib_d);
  else
    printf('RIBS  : none, the shelf is a cantilever from the column face\n');
  end
  printf('SEAT  : gap = %.0f mm | e = %.0f mm | shelf takes %.0f%% of V | width %s (both actions)\n\n', ...
     J.st.gap, J.st.e_react, 100*J.st.share, swm{J.st.wmode});

  printf('%-26s %8s %8s %8s %7s %7s  %11s  %5s\n','case','max|Mb|','Mcol s','Mcol w', ...
         'Vmax','Pu','residual s/w','DCR');
  printf('%-26s %8s %8s %8s %7s %7s  %11s\n','','kNm','kNm','kNm','kN','kN','kNm');
  E = struct();  worst_res = 0;
  for n=1:numel(cs)
    C = joint_checks(J, cs(n));
    d = cellfun(@(x) x{6}, C);
    printf('%-26s %8.2f %8.2f %8.2f %7.1f %7.1f  %5.2f/%5.2f  %5.2f\n', ...
       cs(n).name, max(cs(n).M)/1e6, cs(n).Mcol(1)/1e6, cs(n).Mcol(2)/1e6, ...
       max(cs(n).V)/1e3, cs(n).Pu/1e3, cs(n).res(1), cs(n).res(2), max(d));
    worst_res = max([worst_res, abs(cs(n).res)./max(max(cs(n).M)/1e6, 1)]);
    for i=1:numel(C)
      t = C{i}{1};
      if ~isfield(E,t) || C{i}{6} > E.(t).dcr
        E.(t) = struct('name',C{i}{2},'ref',C{i}{3},'cap',C{i}{4}, ...
                       'dem',C{i}{5},'dcr',C{i}{6},'unit',C{i}{7},'case',cs(n).name);
      end
    end
  end

  printf('\nEquilibrium / mapping check: largest residual = %.1f%% of the largest beam moment', 100*worst_res);
  if worst_res > 0.10
    printf('   *** CHECK map.strong / map.weak / map.colM\n');
  else
    printf('   ok\n');
  end

  printf('\nENVELOPE: governing case for every limit state\n');
  printf('  %-4s %-36s %-16s %11s %11s %6s  %s\n','tag','limit state','reference', ...
         'capacity','demand','DCR','governing case');
  f = fieldnames(E);  wmax = 0; wtag = '';
  for i=1:numel(f)
    e = E.(f{i});
    if e.dcr<=1, fl=' ok'; else, fl='***'; end
    if strcmp(e.unit,'S')
      printf('  %-4s %-36s %-16s %7.0f MPa %7.0f MPa %6.2f %s %s\n', f{i}, e.name, e.ref, ...
         e.cap, e.dem, e.dcr, fl, e.case);
    elseif strcmp(e.unit,'F')
      printf('  %-4s %-36s %-16s %8.1f kN %8.1f kN %6.2f %s %s\n', f{i}, e.name, e.ref, ...
         e.cap/1e3, e.dem/1e3, e.dcr, fl, e.case);
    elseif strcmp(e.unit,'L')
      printf('  %-4s %-36s %-16s %8.2f mm %8.2f mm %6.2f %s %s\n', f{i}, e.name, e.ref, ...
         e.cap, e.dem, e.dcr, fl, e.case);
    elseif strcmp(e.unit,'R')
      printf('  %-4s %-36s %-16s %11.2f %11.2f %6.2f %s %s\n', f{i}, e.name, e.ref, ...
         e.cap, e.dem, e.dcr, fl, e.case);
    else
      printf('  %-4s %-36s %-16s %7.2f kNm %7.2f kNm %6.2f %s %s\n', f{i}, e.name, e.ref, ...
         e.cap/1e6, e.dem/1e6, e.dcr, fl, e.case);
    end
    if e.dcr > wmax, wmax = e.dcr; wtag = f{i}; end
  end
  printf('\n  GOVERNING: %s %s, DCR %.2f, case %s\n', wtag, E.(wtag).name, wmax, E.(wtag).case);
  if ~isfield(E,'M6')
    printf('  Column P-M-M: set J.cl.phiPn from ETABS to run H1-1 here.\n');
  end
end

% =====================================================================
%  CIDECT DG9 chapter 8.6 validity check for the external diaphragm.
%  Call once per joint: cidect_validity(J)
% =====================================================================
function cidect_validity(J)
  c=J.cl; p=J.pl;
  bc = min(c.D,c.B); hd = p.L_lap; td = p.t_cap;
  r1 = bc/c.t;  r2 = hd/bc;  r3 = td/c.t;  r4 = (bc/2+hd)/td;  r4lim = 240/sqrt(p.Fy);
  printf('\nCIDECT DG9 Table 8.3 eq.(2), validity (bc = %.0f mm):\n', bc);
  printf('   bc/tc     = %5.1f   (17 to 67)      %s\n', r1, merge(r1>=17 && r1<=67,'ok','OUT'));
  printf('   hd/bc     = %5.2f   (0.07 to 0.40)  %s\n', r2, merge(r2>=0.07 && r2<=0.40,'ok','OUT'));
  printf('   td/tc     = %5.2f   (0.75 to 2.0)   %s\n', r3, merge(r3>=0.75 && r3<=2.0,'ok','OUT'));
  printf('   (bc/2+hd)/td = %4.1f  (<= %4.1f)      %s\n', r4, r4lim, merge(r4<=r4lim,'ok','OUT'));
  Pbf = 3.17*(c.t/bc)^(2/3)*(td/bc)^(2/3)*((c.t+hd)/bc)^(1/3)*bc^2*p.Fu;
  printf('   P_bf* = %.0f kN (ultimate, unfactored)\n', Pbf/1e3);
end
