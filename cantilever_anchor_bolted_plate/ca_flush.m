function W = ca_flush(P, MuE, zE)
% CA_FLUSH  Study (user 2026-10-05): top anchors lowered INSIDE the beam depth, just under the top flange,
%   either side of the web (flush end plate). Each anchor sits in the corner of the top flange and the
%   web: end plate PL 12 + extra plate PL 12 (A36), strips to both (lower bound, as ca_calc / ca_wide).
%   No plate above the flange, no rib. Back plate: one PL 12 square per anchor, clear of the beam bars at
%   the far face (v = 0, +-88). The user's minimum moment is dropped (with axis F): MuE sets E (C4/B4);
%   C1, CX, CY keep their current design moments (no F there yet).
if nargin < 1 || isempty(P), P = ca_inputs(); end
if nargin < 2 || isempty(MuE), MuE = 16.5; end
if nargin < 3 || isempty(zE), zE = -40; end
W.vA = 35;  W.zA = zE*[1 1 1 1];  W.zA(4) = zE + 16;      % CY crosses CX: 16 over it (to be laid out)
W.bw = 50;  W.bh = 50;                                     % back plates: squares, v 10..60 (bars at 0 and 88 clear)
an = P.an;  Fy = P.st.Fy(1);  o4 = [1 1 1 1];  mp = 0.9*Fy*P.ep.t^2/4;  bm = P.bm;
R0 = ca_calc(P);  Mu0 = [R0.typ.Mu];                       % current design moments (N mm)
Pc = P;  Pc.an.vT = W.vA;  Pc.an.zTt = W.zA;  Pc.bp.w = 2*W.bw;  Pc.bp.h = W.bh;
Pc.kMforce = MuE*1e6/R0.kase(1).Mc/1e6;                    % E at MuE
R = ca_calc(Pc);
kfix = Mu0(2:4)./[R.typ(2:4).Mu];                          % C1, CX, CY back to their current moments
T = [R.typ.T];  T(2:4) = T(2:4).*kfix;  Ta = T/2;
W.T = T;  W.R = R;
rows = {};
keep = {'Top anchor, steel in tension', 'Thread stripping', 'Pullout at the back plate', ...
        'Side-face blowout of the back plate towards the pedestal top', 'Anchor reinforcement: top bars', ...
        'Anchor reinforcement: beam bars inside', 'Anchor reinforcement within', 'Bearing side, strip below', 'Bearing side, strip beyond', ...
        'Bearing stress on the concrete face', 'Fillet, tension flange', 'Top bars at the face'};
for i = 1:size(R.rows, 1)
    if any(cellfun(@(k) strncmp(R.rows{i,2}, k, numel(k)), keep))
        q = R.rows(i,:);
        if numel(q{4}) == 4 && any(strncmp(q{2}, {'Top anchor, steel', 'Thread', 'Pullout', 'Side-face', 'Anchor reinforcement: top bars'}, 8))
            q{4}(2:4) = q{4}(2:4).*kfix;                   % demand in proportion to T
        end
        rows(end+1,:) = q;
    end
end
% back plate squares
for j = 1:4
    Pb = P;  Pb.an.vT = 0;  Pb.bp.w = W.bw;  Pb.bp.h = W.bh;
    B(j) = ca_bpbeam(Pb, Ta(j), an.dw/2);
end
rows(end+1,:) = {'Back plate', sprintf('PL %gx%gx%g per anchor: bending through the hole (net, with shear)', P.bp.t, W.bh, W.bw), 'AISC F11, J4.2', [B.Mh], [B.Ch], 'kN m', '', ''};
% end plate: the anchor in the corner of the top flange (above) and the web (inside)
wf = P.w.flange;  ww = P.w.web;  zft = -bm.tf - wf;  xwt = bm.tw/2 + ww;  xft = bm.b/2 + wf;
for j = 1:4
    zA = W.zA(j);
    x1 = zft - zA;  w1 = min(W.vA + x1, xft) - max(W.vA - x1, xwt);
    x2 = W.vA - xwt;  w2 = min(zA + x2, zft) - max(zA - x2, -bm.h + bm.tf + wf);
    k1 = x1/w1;  k2 = x2/w2;  c1 = k1*k2/(k1 + k2);
    % extra plate on the concrete face, one per anchor: edges welded on the flange line and the web line
    y1 = -bm.tf - zA;  u1 = min(W.vA + y1, xft) - max(W.vA - y1, P.dbl.gap/2);
    y2 = W.vA - P.dbl.gap/2;  u2 = min(zA + y2, -bm.tf) - max(zA - y2, -bm.h/2);
    c2 = (y1/u1)*(y2/u2)/((y1/u1) + (y2/u2));
    be = c2/(c1 + c2);  ms(j) = be*c1*Ta(j);  ms1(j) = c1*Ta(j);
    S(j) = struct('x1', x1, 'w1', w1, 'x2', x2, 'w2', w2, 'c1', c1, 'be', be);
end
rows(end+1,:) = {'End plate', 'End plate PL 12 alone: strips to the top flange and the web', 'DG1 3.4.3 (strip)', ms1, mp*o4, 'kN m/m', ...
    sprintf('E: x1 = %.0f / b1 = %.0f, x2 = %.0f / b2 = %.0f', S(1).x1, S(1).w1, S(1).x2, S(1).w2), 'info'};
rows(end+1,:) = {'End plate', 'End plate PL 12 + extra plate PL 12 (A36): strips to the top flange and the web', 'DG1 3.4.3 (strip)', ms, mp*o4, 'kN m/m', '', ''};
rows(end+1,:) = {'End plate', 'Same, no prying (strict): 1.11 m', 'DG16 2.2', 1.11*ms, mp*o4, 'kN m/m', '', ''};
W.rows = rows;  W.S = S;
% clearances (mm)
nutc = an.nut/sqrt(3);
W.cl = {'nut corner - top flange fillet toe', (zft) - (W.zA(1) + nutc);
        'nut corner - web fillet toe', (W.vA - nutc) - xwt;
        'anchor - beam top bars of the crossing beam (-68, top -62)', (W.zA(1) - an.db/2) - (min(P.cb.zt) + P.cb.db/2);
        'back plate (v 10..60) - beam bar at v = 0', (W.vA - W.bw/2) - P.cb.db/2;
        'back plate - beam corner bar at v = 88', (max(P.cb.v) - P.cb.db/2) - (W.vA + W.bw/2);
        'back plate top - z = 0 (under the beam top: no block above)', 0 - (W.zA(1) + W.bh/2)};
here = fileparts(mfilename('fullpath'));
f = fopen(fullfile(here, 'reports', 'flush_results.txt'), 'w');
fprintf(f, 'FLUSH END PLATE study (ca_flush.m, %s): A1 at v = +-%g, z = %g (CY %g); Mu E = %.1f kN m (C1, CX, CY as now)\n', datestr(now, 'yyyy-mm-dd'), W.vA, zE, W.zA(4), MuE);
fprintf(f, 'T = %s kN\n\n%-96s %s\n', mat2str(T/1e3, 3), 'Check', 'E     C1    CX    CY');
for i = 1:size(rows, 1)
    d = rows{i,4};  c = rows{i,5};  if numel(c) ~= numel(d), c = c(1)*ones(size(d)); end
    fl = '';  if numel(rows(i,:)) >= 8 && strcmp(rows{i,8}, 'info'), fl = 'info'; end
    fprintf(f, '%-96s %s %s\n', [rows{i,1} ': ' rows{i,2}](1:min(96, end)), sprintf('%5.2f ', d./c), fl);
end
fprintf(f, '\nClearances (mm)\n');
for i = 1:size(W.cl, 1), fprintf(f, '%7.1f  %s\n', W.cl{i,2}, W.cl{i,1}); end
fclose(f);  type(fullfile(here, 'reports', 'flush_results.txt'));
end
