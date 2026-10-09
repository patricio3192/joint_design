function W = ca_wide(P, zE)
% CA_WIDE  Study (user 2026-10-05): top anchors opened out beyond the IPE 240 flanges (v = +-120),
%   end plate as a T (top bar at the anchor level), A36 12 mm plates only, with stiffeners:
%   S1 = flange extension (PL 12 in the plane of the top flange, top flush with it, from the flange
%        tip to the plate edge, CJP to the flange tip, fillets to the end plate);
%   R1 = vertical gusset (PL 12, parallel to the web) between the flange tip and the anchor, on S1.
%   Each anchor sits in the corner of S1 (below it) and R1 (inside it). End plate checked with strips
%   (lower bound, DG1 / RAM effective width): the pull of the anchor split between a strip to S1 and
%   a strip to R1, each counting only the width that lands on its support; the extra plate PL 12 on
%   the concrete face (edges welded on the S1 and R1 lines) shares it (equal ratio, as ca_calc).
%   Back plate: one PL 12 per anchor (ca_bpbeam with the anchor at the centre).
%   Anchor and concrete checks: ca_calc with the anchors at v = +-120 and the new levels.
if nargin < 1 || isempty(P), P = ca_inputs(); end
W.vA = 120;                         % anchors, |v|: 6 mm to the steel column rods (100) and to the column bars (142)
W.zA = [-50 -50 -50 30];
if nargin > 1 && ~isempty(zE), W.zA(1:3) = zE; end   % study: level of E, C1, CX            % E, C1, CX under S1, as deep as the crossing-beam bars (-68) allow; CY over S1 (D4: they cross)
W.edge = 45;                        % hole to plate edge: 25 + 20 for the anchors set out of place (user)
W.tS = 12;  W.wS = 6;               % S1: thickness, fillets (top face flush with the flange top, z = 0)
W.dS = 100;                         % S1 depth along the beam (u)
W.vR = 82;  W.tR = 12;  W.wR = 6;   % R1: inner face at v = 82 (flange tip 60 + 22), fillets
W.dR = 80;                          % R1 depth along the beam
W.bw = [50 50 50 80];  W.bh = [50 50 50 80];   % back plate per anchor: under S1 a 50 square (clear of the beam bars at v = 88), over it 80
W.dbl = 1;                          % extra plate PL 12 on the concrete face of the ears
W.x3 = 20;  W.dS2 = 80;             % S2 (anchors under S1): PL 12 under the anchor, its fillet toe x3 from the anchor axis, hung on R1

an = P.an;  st = 1;  Fy = P.st.Fy(st);  Fu = P.st.Fu(st);  t = P.ep.t;  o4 = [1 1 1 1];
mn = 0.9*Fy*t^2/4;                  % phi m_p per unit width, PL 12 A36
Pc = P;  Pc.an.vT = W.vA;  Pc.an.zTt = W.zA;
Pc.bp.w = 2*W.bw(1);  Pc.bp.h = W.bh(1);   % A_brg per anchor = bh bw - hole (ca_calc halves a 2-hole plate)
R = ca_calc(Pc);
T = [R.typ.T];  Ta = T/2;
W.T = T;  W.R = R;

rows = {};
% ---- anchors and concrete: the ca_calc rows that do not depend on the plate layout ----
keep = {'Top anchor, steel in tension', 'Thread stripping', 'Pullout at the back plate', ...
        'Side-face blowout of the back plate towards the pedestal top', 'Anchor reinforcement', ...
        'Unreinforced breakout', 'Top anchors, tension + shear', 'Joint shear', 'Top bars at the face', ...
        'Bearing side, strip below', 'Bearing side, strip beyond', 'Bearing stress on the concrete face', ...
        'Fillet, tension flange', 'Fillets, web to end plate'};
for i = 1:size(R.rows, 1)
    if any(cellfun(@(k) strncmp(R.rows{i,2}, k, numel(k)), keep))
        rows(end+1,:) = R.rows(i,:);
    end
end
% side-face blowout towards the side face (c_a1 = 80), each anchor alone (the other is 240 away, at the other face)
for j = 1:4
    ca1 = P.col.b/2 - W.vA;  ca2 = P.col.top - W.zA(j);
    Abrg = W.bw(j)*W.bh(j) - pi*an.hole^2/4;
    Nsb = 13*ca1*sqrt(Abrg)*sqrt(P.fc);
    if ca2 < 3*ca1, Nsb = Nsb*(1 + ca2/ca1)/4; end
    phiNsb(j) = 0.70*Nsb;
end
rows(end+1,:) = {'Anchors', sprintf('Side-face blowout towards the side face (c<sub>a1</sub> = %g)', P.col.b/2 - W.vA), '17.6.4.1', Ta, phiNsb, 'kN', ...
    sprintf('N<sub>sb</sub> = 13 c<sub>a1</sub> &radic;A<sub>brg</sub> &radic;f''<sub>c</sub> (1 + c<sub>a2</sub>/c<sub>a1</sub>)/4, c<sub>a2</sub> = top of the pedestal; one anchor; &phi; = 0.70: %.0f kN', phiNsb(1)/1e3), ''};
% ---- back plate, one per anchor ----------------------------------------------------------
for j = 1:4
    Pb = P;  Pb.an.vT = 0;  Pb.bp.w = W.bw(j);  Pb.bp.h = W.bh(j);
    B(j) = ca_bpbeam(Pb, Ta(j), an.dw/2);
end
rows(end+1,:) = {'Back plate', sprintf('PL %gx%gx%g per anchor (CY %gx%g): bending through the hole (net, with shear)', P.bp.t, W.bh(1), W.bw(1), W.bh(4), W.bw(4)), 'AISC F11, J4.2', [B.Mh], [B.Ch], 'kN m', ...
    sprintf('anchor at the centre, nut on a ring %g..%g; net width %.0f; M = %.3f kN m', an.hole, an.dw, B(1).bh, B(1).Mh/1e6), ''};
rows(end+1,:) = {'Back plate', 'Shear rupture through the hole', 'AISC J4.2(b)', [B.Vmx], [B.Cvr], 'kN', '', ''};
% ---- end plate: strips to S1 and R1 ------------------------------------------------------
% anchor over S1 (zA > 0): S1 fillet toe at +wS, R1 on S1 going up, ear top at zA + edge;
% anchor under S1 (zA < 0): toe at -(tS + wS), R1 under S1 going down, ear bottom at zA - edge
vRt = W.vR + W.tR + W.wR;           % toe of the R1 fillet on the anchor side
for j = 1:4
    zA = W.zA(j);  vE = W.vA + W.edge;  up = zA > 0;  s2 = ~up;    % S2 only under S1
    if up, zS = W.wS;  zE = 5*ceil((zA + W.edge)/5);  zD = 0;
    else,  zS = -W.tS - W.wS;  zD = -W.tS;  zE = zA - W.x3 - W.wS - W.tS - 8; end   % ear bottom: under S2 and its fillet
    zS2 = zA - W.x3;                                 % S2 fillet toe (anchor side)
    x1 = abs(zA - zS);  w1 = min(W.vA + x1, vE) - max(W.vA - x1, vRt);
    x2 = W.vA - vRt;
    zlo = min(zS, zE);  zhi = max(zS, zE);  if s2, zlo = zS2; end
    w2 = min(zA + x2, zhi) - max(zA - x2, zlo);
    k = [x1/w1, x2/w2];
    if s2, x3 = W.x3;  w3 = min(W.vA + x3, vE) - max(W.vA - x3, vRt);  k(3) = x3/w3; end
    c1 = 1/sum(1./k);  sh = (1./k)/sum(1./k);      % strip shares (S1, R1, S2): all at the same moment
    % extra plate: edges welded on the S1 line (z = zD), the R1 line (v = vR) and, under S1, the S2 line
    y1 = abs(zA - zD);  u1 = min(W.vA + y1, vE) - max(W.vA - y1, W.vR);
    y2 = W.vA - W.vR;  u2 = min(zA + y2, max(zD, zE)) - max(zA - y2, min(zD, zE));
    q = [y1/u1, y2/u2];
    if s2, y3 = W.x3 + W.wS;  u3 = min(W.vA + y3, vE) - max(W.vA - y3, W.vR);  q(3) = y3/u3; end
    c2 = 1/sum(1./q);
    be = 1;  if W.dbl, be = c2/(c1 + c2); end        % share in the end plate (same ratio in both)
    ms(j) = be*c1*Ta(j);  R2(j) = (1 - be)*Ta(j);
    al = sh(1);  F3(j) = 0;  if s2, F3(j) = sh(3)*be*Ta(j) + (1 - be)*Ta(j)*(1/q(3))/sum(1./q); end
    S(j) = struct('zE', zE, 'x1', x1, 'w1', w1, 'x2', x2, 'w2', w2, 'c1', c1, 'al', al, 'y1', y1, 'u1', u1, 'y2', y2, 'u2', u2, 'c2', c2, 'be', be, 'sh', sh);
    Lw(j) = (vE - W.vR)*(1 + s2) + abs(zE - zD);     % extra plate: S1-line, inner edge and S2-line welds
end
W.S = S;
rows(end+1,:) = {'End plate', sprintf('Ear: end plate PL %g + extra plate PL %g (A36), strips to S1 and R1', t, t), 'lower bound (strip), DG1 3.4.3', ms, mn*o4, 'kN m/m', ...
    sprintf('E: x<sub>1</sub> = %g / b<sub>1</sub> = %g, x<sub>2</sub> = %g / b<sub>2</sub> = %g; extra plate y<sub>1</sub> = %g / %g, y<sub>2</sub> = %g / %g; %.0f%% of T<sub>a</sub> = %.1f kN in the end plate: m = %.2f kN m/m; &phi;m<sub>p</sub> = %.2f', ...
    S(1).x1, S(1).w1, S(1).x2, S(1).w2, S(1).y1, S(1).u1, S(1).y2, S(1).u2, 100*S(1).be, Ta(1)/1e3, ms(1)/1e3, mn/1e3), ''};
rows(end+1,:) = {'End plate', 'Ear, no prying (strict): 1.11 m &le; &phi;m<sub>p</sub>', 'DG16 2.2', 1.11*ms, mn*o4, 'kN m/m', '', ''};
phiW2 = 0.75*0.6*P.FEXX*0.707*W.wS*Lw;
rows(end+1,:) = {'End plate', 'Extra plate: edge welds on the S1 and R1 lines', 'AISC J2.4', R2, phiW2, 'kN', sprintf('fillet %g over %.0f mm', W.wS, Lw(1)), ''};
% ---- S1: carries the whole pull of the anchor (R1 hangs on it) back to the flange tip ----
eS = W.vA - P.bm.b/2;               % flange tip to the anchor line
MS = Ta*eS;  phiMS = 0.9*Fy*W.tS*W.dS^2/4;  phiVS = 1.0*0.6*Fy*W.tS*W.dS;
rows(end+1,:) = {'Stiffeners', sprintf('S1 PL %gx%g: in-plane bending at the flange tip (CJP to the tip)', W.tS, W.dS), 'AISC F11', MS, phiMS*o4, 'kN m', ...
    sprintf('M = T<sub>a</sub> (v<sub>A</sub> - b<sub>f</sub>/2) = T<sub>a</sub> x %g; &phi;M<sub>p</sub> = 0.9 F<sub>y</sub> t d&sup2;/4 = %.2f kN m', eS, phiMS/1e6), ''};
rows(end+1,:) = {'Stiffeners', 'S1: shear at the flange tip', 'AISC G2.1', Ta, phiVS*o4, 'kN', '', ''};
LS = (W.vA + W.edge) - P.bm.b/2 - 15;   % S1 to end plate, both faces, less a 15 mm clip
phiWS = 0.75*0.6*P.FEXX*0.707*W.wS*2*LS;
rows(end+1,:) = {'Stiffeners', 'S1 to end plate: fillets both faces', 'AISC J2.4', Ta, phiWS*o4, 'kN', sprintf('2 x %.0f mm, fillet %g', LS, W.wS), ''};
FR = Ta.*(1 - [S.al]);              % strip 2 to R1 (end plate share) plus the extra plate inner edge: all of it taken by R1, as an upper value
for j = 1:4, FR(j) = (1 - S(j).al)*S(j).be*Ta(j) + R2(j); end   % R1 + S2 strips and the extra plate (upper value)
MR = FR.*abs(W.zA - 0);  phiMR = 0.9*Fy*W.tR*W.dR^2/4;
rows(end+1,:) = {'Stiffeners', sprintf('R1 PL %gx%g: cantilever from S1', W.tR, W.dR), 'AISC F11', MR, phiMR*o4, 'kN m', '', ''};
LR = W.dR - 15;  phiWR = 0.75*0.6*P.FEXX*0.707*W.wR*2*LR;
rows(end+1,:) = {'Stiffeners', 'R1 to S1: fillets both faces', 'AISC J2.4', FR, phiWR*o4, 'kN', sprintf('2 x %.0f mm', LR), ''};
eS2 = W.vA - (W.vR + W.tR);  MS2 = F3*eS2;  phiMS2 = 0.9*Fy*W.tS*W.dS2^2/4;
rows(end+1,:) = {'Stiffeners', sprintf('S2 PL %gx%g (under the anchor): cantilever from R1', W.tS, W.dS2), 'AISC F11', MS2, phiMS2*o4, 'kN m', ...
    sprintf('M = F<sub>S2</sub> x %g; E: F<sub>S2</sub> = %.1f kN', eS2, F3(1)/1e3), ''};
LS2 = W.dS2 - 15;  phiWS2 = 0.75*0.6*P.FEXX*0.707*W.wS*2*LS2;
rows(end+1,:) = {'Stiffeners', 'S2 to R1: fillets both faces', 'AISC J2.4', F3, phiWS2*o4, 'kN', sprintf('2 x %.0f mm', LS2), ''};
W.F3 = F3;
W.rows = rows;
% ---- HTML table for reports/anclas_anchas.html (read by sketch_wide_anchors.py) ----
here = fileparts(mfilename('fullpath'));
fid = fopen(fullfile(here, 'reports', 'anclas_anchas_dc.html'), 'w');
fprintf(fid, '<table><tr><th>Grupo</th><th>Verificación</th><th>Referencia</th><th>E</th><th>C1</th><th>CX</th><th>CY</th></tr>\n');
for i = 1:size(rows, 1)
    d = rows{i,4};  c = rows{i,5};  if numel(c) ~= numel(d), c = c(1)*ones(size(d)); end;  r = d./c;
    info = numel(rows(i,:)) >= 8 && strcmp(rows{i,8}, 'info');
    cells = arrayfun(@(x) sprintf('<td style="text-align:right%s">%.2f</td>', ifelse_w(x > 1 && ~info, ';color:#c0392b;font-weight:bold', ''), x), r, 'UniformOutput', false);
    fprintf(fid, '<tr%s><td>%s</td><td>%s</td><td>%s</td>%s</tr>\n', ifelse_w(info, ' style="color:#888"', ''), rows{i,1}, ...
            [rows{i,2} ifelse_w(info, ' (info)', '')], rows{i,3}, [cells{:}]);
end
fprintf(fid, '</table>\n');  fclose(fid);
% ---- print ----
fprintf('\nWide anchors (v = +-%g, z = %s): T = %s kN\n', W.vA, mat2str(W.zA), mat2str(T/1e3, 3));
fprintf('%-11s %-92s %s\n', '', '', 'E     C1    CX    CY');
for i = 1:size(rows, 1)
    d = rows{i,4};  c = rows{i,5};  if numel(c) ~= numel(d), c = c(1)*ones(size(d)); end;  r = d./c;
    fl = '';  if numel(rows(i,:)) >= 8 && strcmp(rows{i,8}, 'info'), fl = 'info'; end
    fprintf('%-11s %-92s %s %s\n', rows{i,1}, rows{i,2}(1:min(92, end)), sprintf('%5.2f ', r), fl);
end
end

function r = ifelse_w(c, a, b)
  if c, r = a; else, r = b; end
end
