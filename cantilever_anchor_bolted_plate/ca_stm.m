function S = ca_stm(P, R, bn1, thfix)
% CA_STM  Strut-and-tie model of the anchorage (ACI 318-19 chapter 23, permitted for anchor
%   reinforcement by R17.5.2.1). One model per connection type, in the vertical plane of the anchors.
%   S = ca_stm(P, R)          node N1 at the back plate taken as anchoring two ties (beta_n = 0.6)
%   S = ca_stm(P, R, 0.8)     the same with beta_n = 0.8 (the hooks bear on the nuts: one tie)
%
%   N1  back plate B1: tie A1 (the 2 anchors, anchored by B1), vertical tie V (2 far-face column
%       bars, straight behind B1 and hooked along the anchors above it, level A), strut S1. B1 bears
%       on the tie 14 under the anchors and the tie on those bars (user 2026-10-05). Faces: B1 bearing face (h x w),
%       and the horizontal width wV from the B1 face to the front of the far-face bars.
%   S1  strut from N1 down towards the cantilever face, at theta to the horizontal
%   N2  on the beam top bars (tie into the beam in line): smeared CCT node; its vertical force goes
%       down the joint into the column (strut S2), its vertical face width wt is chosen so that the
%       node face stress is within its limit (R23.8.1), the strut width there equals ws at N1.
%   theta is the designer's choice (lower bound): every theta between 25 deg (23.2.7, strut to the
%   horizontal ties) and 65 deg (strut to the vertical tie) is tried, the one with the smallest
%   largest D/C is kept, leaving out the concrete at N1 (the anchor head: chapter 17, see below).
if nargin < 3 || isempty(bn1), bn1 = 0.6; end
if nargin < 4, thfix = []; end                     % study: path-1 angle fixed (deg), scalar or per type
fc = P.fc;  an = P.an;  bp = P.bp;  phi = 0.75;              % Table 21.2.1(g)
rc = P.col.cover + P.col.dtie + P.col.db/2;
Abar = pi*P.cb.db^2/4;  Acol = pi*P.col.db^2/4;
ldh = R.hk.ldh12;
hB = bp.h;  bB = bp.w;  An1 = 2*R.hk.Abrg;                  % B1 bearing face, net of the holes
wV = bp.u - (P.col.b - rc - P.col.db/2);                    % B1 face to the front of the far-face bars (30)
th = (25:0.5:65)*pi/180;
for j = 1:4
    Y = R.typ(j);  T = Y.T;  z1 = Y.zT;
    z2 = min(P.cb.zt);  if j == 4, z2 = max(P.cb.zt); end   % tie level, as in the anchor reinforcement check
    n = R.cone(j).k;                                        % beam bars in the tie (the ones counted by 17.5.2.1)
    % confinement of the strut end and node at B1 (Table 23.4.3(b)): A2 similar and concentric,
    % limited by the distance from the plate to the top of the pedestal
    e = P.col.top - (z1 + hB/2);
    A1b = hB*bB;  A2b = (hB + 2*e)*(bB + 2*e);  bc = min(sqrt(A2b/A1b), 2);
    fsn = 0.85*bc*min(0.75, bn1)*fc;                        % strut end at N1: min(beta_s, beta_n)
    fn1 = 0.85*bc*bn1*fc;                                   % N1 bearing face
    fn2 = 0.85*1.0*0.8*fc;                                  % N2: CCT, no bearing surface (beta_c = 1)
    % out-of-plane width at N2: the strut tapers (R23.4.2) from the B1 width to the width of the bar
    % group of the tie (outer faces of the corner bars), no more than a 1:2 spread on each side
    b2 = min(2*max(abs(P.cb.v)) + P.cb.db, bB + (z1 - z2));
    best = inf;  thj = th;  if ~isempty(thfix), thj = thfix(min(j, numel(thfix)))*pi/180; end
    for k = 1:numel(thj)
        t = thj(k);
        Fs = T/cos(t);  V = T*tan(t);                       % equilibrium at N1
        u2 = bp.u - (z1 - z2)/tan(t);                       % N2 on the tie
        ws = hB*cos(t) + wV*sin(t);                         % strut width at N1 (R23.2.6)
        d = [T/(phi*2*an.Ase*an.fya), ...                   % tie A1 (23.7.2)
             T/(phi*n*Abar*P.fy), ...                       % tie of beam bars
             V/(phi*2*Acol*P.fy), ...                       % vertical tie: 2 column bars
             (T/An1)/(phi*fn1), ...                         % N1, B1 face (23.9.1)
             (Fs/(ws*bB))/(phi*fsn)];                       % strut S1 at N1 (23.4.1a with beta_n)
        % N2: wt from R23.8.1 (wt <= Fnt/(fce b)), strut face ws2 = wt cos + lb sin with lb = ws/sin
        % (the strut arriving from N1 keeps its width): stress Fs/(ws b) against the N2 limit
        d(6) = (Fs/(ws*b2))/(phi*fn2);
        % tie of beam bars developed beyond the extended nodal zone of N2, towards the hooks
        % (23.8.3): from u2 - ws/(2 sin) to the outside of the hooks, tolerances against (25 short)
        avail = u2 - ws/(2*sin(t)) - (P.cb.uh + P.tol.ub);
        d(7) = ldh/max(avail, eps);
        % the concrete at N1 is the head of the anchors: its bearing is checked by chapter 17 (17.6.3, 17.6.4,
        % test-based); d(4) and d(5) are reported for information and do not steer theta
        if max(d([1 2 3 6 7])) < best
            best = max(d([1 2 3 6 7]));
            M = struct('theta', t*180/pi, 'Fs', Fs, 'V', V, 'u2', u2, 'z2', z2, 'ws', ws, 'dc', d, 'avail', avail);
        end
    end
    % ---- path 2 (pedestal, as in revision 2): one strut from N1 straight to N3, the compression of the
    % end plate on the face (DG1 bearing block: length Y from the bottom edge of the plate, width ep.w);
    % V = T tan(theta) goes down the far column bars, the push of S3 down the front of the column.
    D = Y.dg;  u3 = 0;  z3 = Y.ep_bot + D.Y/2;  t3 = atan((z1 - z3)/(bp.u - u3));
    bc3 = min(sqrt(P.col.b*(D.Y + 2*(Y.ep_bot - P.col.cj))/(P.ep.w*D.Y)), 2);   % A2 on the face, Table 23.4.3(b)
    fn3 = 0.85*bc3*1.0*fc;  fs3 = 0.85*bc3*0.75*fc;                             % CCC node; strut end, beta_s 0.75
    F2 = T/cos(t3);  V2 = T*tan(t3);  ws1b = hB*cos(t3) + wV*sin(t3);  ws3 = D.Y*cos(t3);
    p2.theta = t3*180/pi;  p2.Fs = F2;  p2.V = V2;  p2.z3 = z3;  p2.Y = D.Y;  p2.ws1 = ws1b;  p2.ws3 = ws3;  p2.bc3 = bc3;
    p2.fn3 = fn3;  p2.fs3 = fs3;
    p2.dc = [T/(phi*2*an.Ase*an.fya), V2/(phi*2*Acol*P.fy), (T/An1)/(phi*fn1), (F2/(ws1b*bB))/(phi*fsn), ...
             (T/(D.Y*P.ep.w))/(phi*fn3), (F2/(ws3*P.ep.w))/(phi*fs3), 1*(t3 < 25*pi/180 || t3 > 65*pi/180)];
    M.p2 = p2;
    M.T = T;  M.b2 = b2;  M.n = n;  M.bc = bc;  M.A2 = A2b;  M.fsn = fsn;  M.fn1 = fn1;  M.fn2 = fn2;  M.e = e;
    S(j) = M;
end
end
