% =====================================================================
%  dwj_lib.m   Direct-Welded moment Joint - function library  (v1)
%
%  The same joint as dmj_lib.m WITHOUT the collar plates: the beam
%  flanges and web are welded straight onto the HSS column faces.
%  Written to show what the collar is needed for.
%
%  Load it from a driver script with:   source('dwj_lib.m');
%  Every function starts with dwj_, so it can be loaded next to
%  dmj_lib.m without replacing any of its functions.
%
%  Contents
%    1. dwj_default_joint    section and weld data            (edit here)
%    2. dwj_checks           every limit state, tags B, F, W, C, M
%       dwj_sheet_data       inputs and geometry for the PDF check sheet
%    3. dwj_cases_from_res   load cases from the joint database / toolkit
%    4. dwj_run_joint_res    cases + report for one joint
%    5. dwj_report           per-case table and envelope
%    6. dwj_validity         AISC 360-16 Table K2.2A limits of applicability
%
%  Model
%    Beam flange = TRANSVERSE plate on the column face, force
%                  T = |M|/(h - tf) + |N|/2.
%    Beam web    = LONGITUDINAL plate on the same face, carries the shear.
%    A beam in the STRONG direction lands on the face of width B (100 mm),
%    whose side walls are D long (200 mm). A beam in the WEAK direction
%    lands on the face of width D, with side walls B long.
%
%  References: AISC 360-16 Chapter K (K1 parameters, Table K2.2 plate-to-
%  rectangular-HSS, K5 welds), J2.4, J4, G2, F2, F7, H1.  EN 1993-1-8
%  Table 7.13 as an [INFO] cross-check.  Equation numbers are not quoted
%  for Chapter K: check the limit-state names against your edition.
%  Units inside: N, mm.
% =====================================================================
1;

% =====================================================================
% 1. DATA   beam and column are the same as dmj_lib default_joint
% =====================================================================
function J = dwj_default_joint()
  J.E=200000; J.FEXX=480;
  % beam IPE 160, A36
  J.bm.h=160; J.bm.bf=82; J.bm.tf=7.4; J.bm.tw=5; J.bm.r=0;
  J.bm.Fy=250; J.bm.Fu=400; J.bm.Zx=123900;
  % column HSS 200x100x4.  D = face in the STRONG direction.
  J.cl.D=200; J.cl.B=100; J.cl.t=4; J.cl.Fy=250; J.cl.Fu=400;
  % outside corner radius, used by the side wall checks.  AISC K2.2
  % takes 1.5 t when it is not known.
  J.cl.ro=1.5*4;
  % column compression capacity from ETABS steel design; NaN = skip H1-1
  J.cl.phiPn=NaN;
  % welds
  %   fl_type = 'fillet'  fillets both sides of each flange, checked with
  %                       the K5 effective length
  %           = 'cjp'     complete joint penetration, no weld check (the
  %                       flange checks govern)
  J.wl.fl_type='fillet';
  J.wl.leg_fl=5;       % flange fillet leg, each side
  J.wl.leg_web=4;      % web fillet leg, each side
end

function C = dwj_chk(C, tag, name, ref, phiRn, Du, unit, sub)
  if nargin<7 || isempty(unit), unit='F'; end
  if nargin<8, sub=''; end
  C{end+1} = {tag,name,ref,phiRn,Du,Du/phiRn,unit,sub};
end

% a number as it is written in a substitution: 250, 7.4, 0.707, 152128
function s = dwj_n(x)
  if abs(x - round(x)) < 1e-9, s = sprintf('%d', round(x));
  elseif abs(x) >= 1000,       s = sprintf('%.0f', x);
  elseif abs(x) >= 100,        s = sprintf('%.1f', x);
  else,                        s = sprintf('%.4g', x);
  end
end

% fillet weld, AISC J2.4 eq. J2-3, phi 0.75, no directional increase
function r = dwj_weldcap(leg, L, FEXX)
  r = 0.75*0.60*FEXX*0.707*leg*L;
end

function s = dwj_weldsub(leg, Ltxt, FEXX)
  s = sprintf('0.75 x 0.60 x %s x 0.707 x %s x %s', dwj_n(FEXX), dwj_n(leg), Ltxt);
end

% column section properties: area and elastic moduli [strong weak]
function [Ac, S] = dwj_colprops(c)
  Ac = 2*c.t*(c.D + c.B - 2*c.t);
  S  = [ (c.B*c.D^3-(c.B-2*c.t)*(c.D-2*c.t)^3)/12/(c.D/2), ...
         (c.D*c.B^3-(c.D-2*c.t)*(c.B-2*c.t)^3)/12/(c.B/2) ];
end

% geometry that does not depend on the load case, [strong weak] where paired
%   z      flange centre to flange centre
%   Bface  width of the face each beam lands on
%   dpar   side wall length along the force
%   Bt     face slenderness B/t
%   beta   bf / Bface, <= 1
%   le     K5 effective length of the flange fillets, both sides together
%   Lw     web weld length, each side
function G = dwj_geometry(J)
  b=J.bm; c=J.cl;
  G.z     = b.h - b.tf;
  G.Bface = [c.B c.D];
  G.dpar  = [c.D c.B];
  G.Bt    = G.Bface/c.t;
  G.beta  = min(b.bf./G.Bface, 1.0);
  G.le    = min(2*(10./G.Bt)*(c.Fy*c.t/(b.Fy*b.tf))*b.bf, 2*b.bf);
  G.Lw    = b.h - 2*(b.tf + b.r);
end

% chord stress function, AISC K1 / EN 1993-1-8 kn (same form)
%   U  = Pu/(Fy Ag) + Mcol/(Fy S), compression only
%   Qf = 1.3 - 0.4 U/beta <= 1.0   (face in compression)
%   The loaded face is taken as in compression whenever U > 0, which
%   can only lower Qf.
function Qf = dwj_Qf(J, cs, d, beta)
  c = J.cl;  [Ac, S] = dwj_colprops(c);
  U  = max(cs.Pu,0)/(c.Fy*Ac) + cs.Mcol(d)/(c.Fy*S(d));
  Qf = min(1.0, 1.3 - 0.4*U/beta);
end

% =====================================================================
% 2. CHECKS FOR ONE LOAD CASE
%    cs.M    |beam end moment| per beam, N*mm
%    cs.V    beam reaction per beam, N, downward positive
%    cs.N    beam axial force per beam, N
%    cs.dirb direction of each beam, 1 strong / 2 weak
%    cs.Mcol [strong weak] column-top moment, N*mm, magnitudes
%    cs.Pu   column axial, N, compression positive
%    nside   [strong weak] number of beams in each direction
%  Each check carries the capacity with its numbers substituted, for
%  the PDF check sheet.
% =====================================================================
function C = dwj_checks(J, cs, nside)
  b=J.bm; c=J.cl; w=J.wl;
  G = dwj_geometry(J);
  z = G.z;  dpar = G.dpar;
  N = @dwj_n;
  C = {};

  Tb   = cs.M/z + abs(cs.N)/2;
  Tmax = max([Tb 0]);
  Td = [0 0];
  for i=1:numel(Tb), d=cs.dirb(i); Td(d)=max(Td(d),Tb(i)); end

  % ---- beam side --------------------------------------------------------
  C = dwj_chk(C,'B1','beam flange gross yielding','J4.1 (J4-1)', ...
      0.90*b.Fy*b.bf*b.tf, Tmax, 'F', ...
      sprintf('0.90 x %s x %s x %s', N(b.Fy), N(b.bf), N(b.tf)));

  % ---- flange on the column face, per direction ------------------------
  nm = {'strong','weak'};
  for d=1:2
    if Td(d)==0, continue; end
    s    = nm{d}(1);
    B    = G.Bface(d);
    Bt   = G.Bt(d);
    beta = G.beta(d);

    % F1 local yielding of the flange due to uneven load distribution:
    %    only the width 10/(B/t) * Bp near the side walls is effective.
    Rn = min(10/Bt*c.Fy*c.t*b.bf, b.Fy*b.tf*b.bf);
    C = dwj_chk(C,['F1' s],['flange eff. width yielding, ' nm{d}], ...
        'K2.2 plate local yield', 0.95*Rn, Td(d), 'F', ...
        sprintf('0.95 x min(10/%s x %s x %s x %s , %s x %s x %s)', N(Bt), N(c.Fy), ...
                N(c.t), N(b.bf), N(b.Fy), N(b.tf), N(b.bf)));

    % F2 shear yielding (punching) of the face, 0.85B <= Bp <= B-2t
    if b.bf >= 0.85*B && b.bf <= B - 2*c.t
      Bep = min(10*b.bf/Bt, b.bf);
      C = dwj_chk(C,['F2' s],['face punching shear, ' nm{d}], ...
          'K2.2 shear yielding', 0.95*0.60*c.Fy*c.t*(2*b.tf + 2*Bep), Td(d), 'F', ...
          sprintf('Bep=%s: 0.95 x 0.60 x %s x %s x (2x%s + 2x%s)', N(Bep), N(c.Fy), ...
                  N(c.t), N(b.tf), N(Bep)));
    end

    % F3, F4 side walls, only when the flange covers the flat width
    %    (beta = 1 in K2.2; taken here as Bp >= B - 2t) [MODEL]
    if b.bf >= B - 2*c.t
      C = dwj_chk(C,['F3' s],['side wall local yielding, ' nm{d}], ...
          'K2.2 sidewall yield', 1.00*2*c.Fy*c.t*(5*c.ro + b.tf), Td(d), 'F', ...
          sprintf('1.00 x 2 x %s x %s x (5x%s + %s)', N(c.Fy), N(c.t), N(c.ro), N(b.tf)));
      Qf = dwj_Qf(J, cs, d, beta);
      H  = dpar(d);
      if nside(d)==2
        Rn = 48*c.t^3/(H-3*c.t)*sqrt(J.E*c.Fy)*Qf;  phi = 0.90;  rf = 'K2.2 crippling, cross';
        sb = sprintf('0.90 x 48 x %s^3/(%s-3x%s) x sqrt(E Fy) x Qf=%.3f', N(c.t), N(H), N(c.t), Qf);
      else
        Rn = 1.6*c.t^2*(1 + 3*b.tf/(H-3*c.t))*sqrt(J.E*c.Fy)*Qf;  phi = 0.75;  rf = 'K2.2 crippling, T';
        sb = sprintf('0.75 x 1.6 x %s^2 x (1 + 3x%s/(%s-3x%s)) x sqrt(E Fy) x Qf=%.3f', ...
                     N(c.t), N(b.tf), N(H), N(c.t), Qf);
      end
      C = dwj_chk(C,['F4' s],['side wall crippling, ' nm{d}], rf, phi*Rn, Td(d), 'F', sb);
    end

    % F5 flange fillet welds, K5 effective length (both sides together)
    if strcmpi(w.fl_type,'fillet')
      C = dwj_chk(C,['F5' s],['flange welds, K5 eff. length, ' nm{d}], ...
          'K5 + J2.4 (J2-3)', dwj_weldcap(w.leg_fl, G.le(d), J.FEXX), Td(d), 'F', ...
          sprintf('le=%s: %s', N(G.le(d)), dwj_weldsub(w.leg_fl, N(G.le(d)), J.FEXX)));
    end

    % F6 [INFO] chord face failure, EN 1993-1-8 Table 7.13, beta <= 0.85
    %    kn has the same form as Qf.  gamma_M5 = 1.0.
    if beta <= 0.85
      kn = dwj_Qf(J, cs, d, beta);
      Rn = kn*c.Fy*c.t^2*(2 + 2.8*beta)/sqrt(1 - 0.9*beta);
      C = dwj_chk(C,['F6' s],['face plastification, ' nm{d} ' [INFO]'], ...
          'EN1993-1-8 T7.13', Rn, Td(d), 'F', ...
          sprintf('kn=%.3f: %.3f x %s x %s^2 x (2 + 2.8x%.3f)/sqrt(1 - 0.9x%.3f)', ...
                  kn, kn, N(c.Fy), N(c.t), beta, beta));
    end
  end

  % ---- net force into the column, both directions -----------------------
  %  Same demand as dmj T8: column-top moment / lever arm, carried by
  %  the two walls parallel to the force.
  for d=1:2
    C = dwj_chk(C,['C1' nm{d}(1)],['column walls shear, ' nm{d}],'J4.2 (J4-3)', ...
        0.90*0.60*c.Fy*2*dpar(d)*c.t, cs.Mcol(d)/z, 'F', ...
        sprintf('0.90 x 0.60 x %s x 2 x %s x %s', N(c.Fy), N(dpar(d)), N(c.t)));
  end

  % ---- web on the column face -------------------------------------------
  Vmax = max(abs([cs.V(:); 0]));
  C = dwj_chk(C,'W1','web fillet welds, 2 sides','J2.4 (J2-3)', ...
      dwj_weldcap(w.leg_web, 2*G.Lw, J.FEXX), Vmax, 'F', ...
      dwj_weldsub(w.leg_web, ['2 x ' N(G.Lw)], J.FEXX));
  % W2 longitudinal plate under shear: the wall must not rupture before
  %    the web yields, tp <= Fu t / Fyp.  Demand and capacity in mm.
  C = dwj_chk(C,'W2','wall vs web thickness, tw <= Fu t/Fy','K2.2 long. plate shear', ...
      c.Fu*c.t/b.Fy, b.tw, 'L', sprintf('%s x %s / %s', N(c.Fu), N(c.t), N(b.Fy)));
  hw = G.Lw/b.tw;
  if hw<=2.24*sqrt(J.E/b.Fy), phiv=1.00; else, phiv=0.90; end
  C = dwj_chk(C,'W3','beam web shear','G2.1 (G2-1)', phiv*0.6*b.Fy*b.h*b.tw, Vmax, 'F', ...
      sprintf('%.2f x 0.60 x %s x %s x %s', phiv, N(b.Fy), N(b.h), N(b.tw)));

  % ---- members ----------------------------------------------------------
  C = dwj_chk(C,'M1','beam flexure','F2.1 (F2-1)', 0.90*b.Zx*b.Fy, max([cs.M 0]), 'M', ...
      sprintf('0.90 x %s x %s', N(b.Zx), N(b.Fy)));
  Zcx=c.B*c.D^2/4-(c.B-2*c.t)*(c.D-2*c.t)^2/4;
  Zcy=c.D*c.B^2/4-(c.D-2*c.t)*(c.B-2*c.t)^2/4;
  C = dwj_chk(C,'M4','column flexure, strong','F7.1 (F7-1)', 0.90*Zcx*c.Fy, cs.Mcol(1),'M', ...
      sprintf('0.90 x %s x %s', N(Zcx), N(c.Fy)));
  C = dwj_chk(C,'M5','column flexure, weak','F7.1 (F7-1)',   0.90*Zcy*c.Fy, cs.Mcol(2),'M', ...
      sprintf('0.90 x %s x %s', N(Zcy), N(c.Fy)));
  if isfield(c,'phiPn') && ~isnan(c.phiPn) && c.phiPn>0
    pr = cs.Pu/c.phiPn;
    mr = cs.Mcol(1)/(0.90*Zcx*c.Fy) + cs.Mcol(2)/(0.90*Zcy*c.Fy);
    if pr>=0.2, rat = pr + 8/9*mr; rf='H1.1 (H1-1a)'; else, rat = pr/2 + mr; rf='H1.1 (H1-1b)'; end
    C = dwj_chk(C,'M6','column P-M-M interaction',rf, 1.0, rat, 'R', ...
        sprintf('Pr/Pc = %.3f, Mr/Mc = %.3f', pr, mr));
  end
end

% =====================================================================
% 2b. DATA FOR THE PDF CHECK SHEET
%     Returns {title, header, rows} tables of the inputs and of the
%     derived geometry, as strings.
% =====================================================================
function T = dwj_sheet_data(J, nside)
  b=J.bm; c=J.cl; w=J.wl;
  G = dwj_geometry(J);  N = @dwj_n;
  nm = {'strong','weak'};
  if strcmpi(w.fl_type,'fillet'), ft = 'fillets both sides of each flange'; else, ft = 'CJP'; end
  rows = { ...
    {'Flange weld type', 'fl_type', w.fl_type, ft}, ...
    {'Flange fillet leg', 'leg_fl', [N(w.leg_fl) ' mm'], 'each side'}, ...
    {'Web fillet leg', 'leg_web', [N(w.leg_web) ' mm'], 'each side'}, ...
    {'Web weld length', 'Lw', [N(G.Lw) ' mm'], 'h - 2 (tf + r), each side'}, ...
    {'Lever arm', 'z', [N(G.z) ' mm'], 'h - tf'}, ...
    {'Column outside corner radius', 'ro', [N(c.ro) ' mm'], '1.5 t when not known'}};
  for d = 1:2
    rows = [rows, { ...
      {['Face width, ' nm{d} ' beams'], 'B_face', [N(G.Bface(d)) ' mm'], 'column side the beam lands on'}, ...
      {['Face slenderness, ' nm{d}], 'B/t', sprintf('%.1f', G.Bt(d)), 'K2.2A: <= 35 flange, <= 40 web'}, ...
      {['Width ratio, ' nm{d}], 'beta', sprintf('%.3f', G.beta(d)), 'bf / B_face'}, ...
      {['Side wall length, ' nm{d}], 'H', [N(G.dpar(d)) ' mm'], 'along the force'}, ...
      {['K5 effective weld length, ' nm{d}], 'le', sprintf('%.1f mm', G.le(d)), ...
       '2 (10/(B/t)) (Fy t / Fyb tf) bf <= 2 bf'}}];
  end
  valid = {};
  for d = 1:2
    if nside(d)==0, continue; end
    valid = [valid, { ...
      {[nm{d} ' face, flange: B/t <= 35'], sprintf('%.1f', G.Bt(d)), dwj_yn(G.Bt(d)<=35)}, ...
      {[nm{d} ' face, web: B/t <= 40'],    sprintf('%.1f', G.Bt(d)), dwj_yn(G.Bt(d)<=40)}, ...
      {[nm{d} ' face: 0.25 < beta <= 1.0'], sprintf('%.2f', b.bf/G.Bface(d)), ...
       dwj_yn(b.bf/G.Bface(d)>0.25 && b.bf/G.Bface(d)<=1.0)}}];
  end
  valid = [valid, { ...
    {'column Fy <= 360 MPa', N(c.Fy), dwj_yn(c.Fy<=360)}, ...
    {'column Fy/Fu <= 0.8', sprintf('%.2f', c.Fy/c.Fu), dwj_yn(c.Fy/c.Fu<=0.8)}}];
  T = { {'Welds and column faces', {'Item','Symbol','Value','How it is obtained'}, rows}, ...
        {'AISC 360-16 Table K2.2A, limits of applicability', {'Limit','Value',''}, valid} };
end

% =====================================================================
% 3. CASES FROM THE joint_forces() TOOLKIT / JOINT DATABASE
%    Same as dmj_lib cases_from_res, kept here so the libraries stay
%    independent.
%    res = joint_forces output, loc = [P V2 V3 T M2 M3] member local,
%    ref = [F1 F2 F3 M1 M2 M3] on the joint in the COLUMN's axes.
% =====================================================================
function cs = dwj_cases_from_res(res, map)
  strong = cellfun(@num2str, num2cell(map.strong), 'UniformOutput', false);
  weak   = cellfun(@num2str, num2cell(map.weak),   'UniformOutput', false);
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

function E = dwj_run_joint_res(J, res, map, title_str)
  cs = dwj_cases_from_res(res, map);
  E  = dwj_report(J, cs, map, title_str);
end

% =====================================================================
% 5. REPORT
% =====================================================================
function E = dwj_report(J, cs, map, title_str)
  nside = [min(numel(map.strong),2) min(numel(map.weak),2)];
  b=J.bm; c=J.cl;

  fprintf('\n================ %s  (DIRECT WELD, no collar) ================\n', title_str);
  fprintf('strong beams %s | weak beams %s | column %d (%s = strong)\n', ...
     mat2str(map.strong), mat2str(map.weak), map.col, map.colM);
  fprintf('%d load cases after filtering and removing duplicates\n', numel(cs));
  fprintf('FACES : strong beams on the %.0f mm face, weak beams on the %.0f mm face, wall %.1f mm\n', ...
     c.B, c.D, c.t);
  if strcmpi(J.wl.fl_type,'fillet')
    fprintf('WELDS : flange fillets %.0f mm both sides | web fillets %.0f mm both sides\n', ...
       J.wl.leg_fl, J.wl.leg_web);
  else
    fprintf('WELDS : flanges CJP | web fillets %.0f mm both sides\n', J.wl.leg_web);
  end
  dwj_validity(J, nside);

  fprintf('\n%-26s %8s %8s %8s %7s %7s  %11s  %5s\n','case','max|Mb|','Mcol s','Mcol w', ...
         'Vmax','Pu','residual s/w','DCR');
  fprintf('%-26s %8s %8s %8s %7s %7s  %11s\n','','kNm','kNm','kNm','kN','kN','kNm');
  E = struct();  worst_res = 0;
  for n=1:numel(cs)
    C = dwj_checks(J, cs(n), nside);
    d = cellfun(@(x) x{6}, C);
    fprintf('%-26s %8.2f %8.2f %8.2f %7.1f %7.1f  %5.2f/%5.2f  %5.2f\n', ...
       cs(n).name, max([cs(n).M 0])/1e6, cs(n).Mcol(1)/1e6, cs(n).Mcol(2)/1e6, ...
       max([cs(n).V 0])/1e3, cs(n).Pu/1e3, cs(n).res(1), cs(n).res(2), max(d));
    worst_res = max([worst_res, abs(cs(n).res)./max(max([cs(n).M 0])/1e6, 1)]);
    for i=1:numel(C)
      t = C{i}{1};
      if ~isfield(E,t) || C{i}{6} > E.(t).dcr
        E.(t) = struct('name',C{i}{2},'ref',C{i}{3},'cap',C{i}{4}, ...
                       'dem',C{i}{5},'dcr',C{i}{6},'unit',C{i}{7},'case',cs(n).name);
      end
    end
  end

  fprintf('\nEquilibrium / mapping check: largest residual = %.1f%% of the largest beam moment', 100*worst_res);
  if worst_res > 0.10
    fprintf('   *** CHECK map, or beam torsion at this joint\n');
  else
    fprintf('   ok\n');
  end

  fprintf('\nENVELOPE: governing case for every limit state\n');
  fprintf('  %-4s %-38s %-22s %11s %11s %6s  %s\n','tag','limit state','reference', ...
         'capacity','demand','DCR','governing case');
  f = fieldnames(E);  wmax = 0; wtag = '';
  for i=1:numel(f)
    e = E.(f{i});
    if e.dcr<=1, fl=' ok'; else, fl='***'; end
    switch e.unit
      case 'F', cap = sprintf('%8.1f kN', e.cap/1e3);  dem = sprintf('%8.1f kN', e.dem/1e3);
      case 'M', cap = sprintf('%7.2f kNm', e.cap/1e6); dem = sprintf('%7.2f kNm', e.dem/1e6);
      case 'L', cap = sprintf('%8.2f mm', e.cap);      dem = sprintf('%8.2f mm', e.dem);
      otherwise, cap = sprintf('%11.3f', e.cap);       dem = sprintf('%11.3f', e.dem);
    end
    fprintf('  %-4s %-38s %-22s %11s %11s %6.2f %s %s\n', f{i}, e.name, e.ref, ...
       cap, dem, e.dcr, fl, e.case);
    if e.dcr > wmax, wmax = e.dcr; wtag = f{i}; end
  end
  fprintf('\n  GOVERNING: %s %s, DCR %.2f, case %s\n', wtag, E.(wtag).name, wmax, E.(wtag).case);
  if ~isfield(E,'M6')
    fprintf('  Column P-M-M: set J.cl.phiPn from ETABS to run H1-1 here.\n');
  end
end

% =====================================================================
% 6. LIMITS OF APPLICABILITY, AISC 360-16 Table K2.2A
%    Printed per direction that has beams.  Outside these limits the
%    Chapter K equations are not a design basis.
% =====================================================================
function ok = dwj_validity(J, nside)
  b=J.bm; c=J.cl;
  Bface = [c.B c.D];  nm = {'strong','weak'};
  fprintf('K2.2A limits of applicability:\n');
  ok = true;
  for d=1:2
    if nside(d)==0, continue; end
    Bt = Bface(d)/c.t;  beta = b.bf/Bface(d);
    r = [Bt<=35, Bt<=40, beta>0.25 && beta<=1.0];
    fprintf('   %-6s face B/t = %4.1f  flange <= 35 %-3s | web <= 40 %-3s | beta = %.2f (0.25 to 1.0) %s\n', ...
       nm{d}, Bt, dwj_yn(r(1)), dwj_yn(r(2)), beta, dwj_yn(r(3)));
    ok = ok && all(r);
  end
  rm = [c.Fy<=360, c.Fy/c.Fu<=0.8];
  fprintf('   column Fy = %.0f MPa (<= 360) %s | Fy/Fu = %.2f (<= 0.8) %s\n', ...
     c.Fy, dwj_yn(rm(1)), c.Fy/c.Fu, dwj_yn(rm(2)));
  ok = ok && all(rm);
  if ~ok
    fprintf('   *** outside K2.2A: the Chapter K checks for that face are indicative only\n');
  end
end

function s = dwj_yn(tf)
  if tf, s = 'ok'; else, s = 'OUT'; end
end
