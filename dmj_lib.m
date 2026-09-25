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
1;

% =====================================================================
% 1. DATA
% =====================================================================
function J = default_joint()
  J.E=200000; J.FEXX=480;
  % beam IPE 160, A36
  J.bm.h=160; J.bm.bf=82; J.bm.tf=7.4; J.bm.tw=5; J.bm.r=9;
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
  J.st.share=1.0;
  % Width of plate assumed to bend under the beam.
  %   1 = b_f, no dispersion (very conservative)
  %   2 = b_f + 2*e, 45 degree spread from the load
  %   3 = the same width used for the axial check, so one dispersion
  %       model is used for both actions (default)
  J.st.wmode=4;        % width of plate that works, see joint_checks
  % Width of the strip used for the S8 INTERACTION.  The same width is
  % used for BOTH the axial and the bending term: mixing two widths at
  % one section is not a valid interaction, and taking the wider one for
  % the axial term alone is unconservative.
  %   1 = b_f, no spread (default, needs no argument)
  %   2 = b_f + 2e, 45 degrees from the load
  %   3 = Whitmore, b_f + 2 L_lap tan30 (same as T4)

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
  J.pl.Wx = c.D + nside(1)*ov + (2-nside(1))*p.w_back;
  J.pl.Wy = c.B + nside(2)*ov + (2-nside(2))*p.w_back;
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

  C = chk(C,'T1','flange to plate weld (3-sided)','J2.4 (J2-3)', ...
      weldcap(w.leg_fl, 2*p.L_lap + b.bf, J.FEXX), Tmax);
  C = chk(C,'T2','beam flange gross yielding','J4.1 (J4-1)', ...
      0.90*b.Fy*b.bf*b.tf, Tmax);
  C = chk(C,'T3','beam flange rupture at the weld','J4.2 / D3 (J4-2)', ...
      0.75*b.Fu*b.bf*b.tf, Tmax);
      % Base metal rupture at the fusion line (sides in shear, front in tension)
% Shear capacity: phi * 0.6 * Fu * shear_area
% Tension capacity: phi * Fu * tension_area
Vn_sides = 0.75 * 0.60 * b.Fu * (2 * p.L_lap) * b.tf;
Tn_front = 0.75 * b.Fu * b.bf * b.tf;

  C = chk(C,'T3b','base metal rupture at weld','J4.2 (J4-4)', ...
      Vn_sides + Tn_front, Tmax);
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
  Vmax = max([cs.V(:); 0]);
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
  C = chk(C,'S6','beam web shear','G2.1 (G2-1)', phiv*0.6*b.Fy*b.h*b.tw, max(abs(cs.V)));
  % uplift: with welded flanges there is no bearing, the weld carries it
  Vup = max([-cs.V(:); 0]);
  if Vup > 0
    C = chk(C,'S7','flange weld under uplift','J2.4 (J2-3)', ...
        weldcap(w.leg_fl, 2*p.L_lap + b.bf, J.FEXX), Vup);
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
  cs = struct('name',{},'M',{},'V',{},'N',{},'dirb',{},'Mcol',{},'Pu',{},'res',{});
  keys = {};
  for n=1:numel(names)
    nm = names{n};
    sel = strcmp({res.ocase}, nm);
    M=zeros(1,numel(beams)); V=M; N=M; rs=0; rw=0; ok=true;
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
    key  = sprintf('%.3f ', [M V N Mcol Pu]);
    if any(strcmp(keys,key)), continue; end       % Max = Min duplicates
    keys{end+1} = key;
    cs(end+1) = struct('name',nm,'M',M,'V',V,'N',N,'dirb',dirb, ...
                       'Mcol',Mcol,'Pu',Pu,'res',[rs rw]);
  end
  if isempty(cs), error('no complete load case found: check map.strong/weak/col'); end
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
