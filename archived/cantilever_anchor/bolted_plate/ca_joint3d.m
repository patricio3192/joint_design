function ca_joint3d(P, fname)
% CA_JOINT3D  3D of the joint C4 with all its reinforcement, as an HTML page (three.js, orbit with the
%   mouse, groups on and off). Geometry from ca_inputs: u from the cantilever face into the column,
%   v across, z up from the top of the beams (as the sheets). Bars as tubes along polylines (hooks
%   rounded at 3.5 d for Ø16, 3.5 d for Ø12), ties as rounded rectangles, plates and nuts as boxes.
if nargin < 1 || isempty(P), P = ca_inputs(); end
if nargin < 2, fname = fullfile(fileparts(mfilename('fullpath')), 'reports', 'nudo_c4_3d.html'); end
b = P.col.b;  hb = b/2;  top = P.col.top;  cj = P.col.cj;  an = P.an;  bp = P.bp;  cb = P.cb;
d = P.col.db;  rc = P.col.cover + P.col.dtie + d/2;  c = hb - rc;  rb = 3.5*d;  ht = rb + 12*d;
zA = top - P.col.ctop - d/2;  zB = P.col.zhB;  zlow = cj - 150;
E = {};                                              % {group, kind, data, d or [], colour, opacity}
% ---- column bars and their top hooks (hook table of type E: x = u - hb, y = v) --------------------
H = [-c 0  1 0  0 -8 1;   c 0 -1 0  0  8 1; ...
     -c -c 1 0  0  0 1;   c -c -1 0 0 16 1; ...
     -c c  1 0  0  0 1;   c c  -1 0 0 -16 1; ...
      0 -c 0 1 -8  0 2;   0 c  0 -1 8  0 2];
for i = 1:size(H, 1)
    x = hb + H(i,1) + H(i,5);  y = H(i,2) + H(i,6);  dr = H(i,3:4);  zh = ifelse_j(H(i,7) == 1, zA, zB);
    Q = [x y zlow; x y zh; x + dr(1)*ht, y + dr(2)*ht, zh];
    E(end+1,:) = {'Columna: barras Ø16 y ganchos', 'tube', fillet3(Q, rb), d, ifelse_j(H(i,7) == 1, '#9a6b00', '#d4a017'), 1};
end
% ---- steel column rods -------------------------------------------------------------------------
for x = hb + [-1 1]*P.rod.p, for y = [-1 1]*P.rod.p
    E(end+1,:) = {'Pernos Ø12 de la columna metálica', 'tube', [x y zlow; x y top + 60], P.rod.db, '#2e8b74', 1};
end, end
% ---- ties: joint Ø10, Ø14 under the anchors, Ø10 over them; one pedestal tie under the joint ------
th = P.hoop.db;  a10 = P.col.cover + th/2;
for z = P.hoop.z, E(end+1,:) = {'Estribos Ø10 del nudo', 'tube', ring(a10, b - a10, z, 2*th), th, '#7d3c98', 1}; end
E(end+1,:) = {'Estribos Ø10 del nudo', 'tube', ring(a10, b - a10, cj - 75, 2*th), th, '#7d3c98', 1};
a14 = rc - d/2 - P.top.db/2;
for z = P.top.z, E(end+1,:) = {'Estribos Ø14 (debajo de los anclajes)', 'tube', ring(a14, b - a14, z, 2*P.top.db), P.top.db, '#1e7a46', 1}; end
E(end+1,:) = {'Estribo Ø10 encima de los anclajes', 'tube', ring(a10, b - a10, P.t10.z, 2*th), th, '#b03a9b', 1};
% ---- anchors A1 with B1, A2 ---------------------------------------------------------------------
for v = [-1 1]*an.vT
    E(end+1,:) = {'Anclajes A1, B1, A2', 'tube', [-an.out v an.pf; an.uT v an.pf], an.db, '#c0392b', 1};
    E(end+1,:) = {'Anclajes A1, B1, A2', 'box', [bp.u - an.tnut, v - an.nut/2, an.pf - an.nut/2; bp.u, v + an.nut/2, an.pf + an.nut/2], [], '#7a1f17', 1};
    E(end+1,:) = {'Anclajes A1, B1, A2', 'box', [bp.u + bp.t, v - an.nut/2, an.pf - an.nut/2; an.uT, v + an.nut/2, an.pf + an.nut/2], [], '#7a1f17', 1};
    zS = -(P.bm.h - P.bm.tf) + an.pfS;
    E(end+1,:) = {'Anclajes A1, B1, A2', 'tube', [-an.outS v zS; an.uS + an.tnut v zS], an.db, '#c0392b', 1};
    E(end+1,:) = {'Anclajes A1, B1, A2', 'box', [an.uS, v - an.nut/2, zS - an.nut/2; an.uS + an.tnut, v + an.nut/2, zS + an.nut/2], [], '#7a1f17', 1};
end
E(end+1,:) = {'Anclajes A1, B1, A2', 'box', [bp.u, -bp.w/2, an.pf - bp.h/2; bp.u + bp.t, bp.w/2, an.pf + bp.h/2], [], '#34506b', 1};
% ---- beam in line (VCM, behind the far face): top bars hooked down at the cantilever face ------
db = cb.db;  rbb = 3.5*db;  tl = 12*db;  uL = b + 700;  ux = cb.uh + db/2;
for v = [-1 0 1]*max(cb.v)
    E(end+1,:) = {'Viga en línea (VCM): barras superiores', 'tube', fillet3([uL v max(cb.zt); ux v max(cb.zt); ux v max(cb.zt) - rbb - tl], rbb), db, '#1a5276', 1};
end
for v = [-1 1]*max(cb.v)                              % the 2 under the corner bars
    E(end+1,:) = {'Viga en línea (VCM): barras superiores', 'tube', fillet3([uL v cb.zp; ux + db v cb.zp; ux + db v cb.zp - rbb - tl], rbb), db, '#5dade2', 1};
end
ub = cb.bas.uh + db/2;
for v = cb.bas.v                                      % bastones, second layer
    E(end+1,:) = {'Bastones Ø12', 'tube', fillet3([min(b + cb.bas.L, uL) v cb.bas.z; ub v cb.bas.z; ub v cb.bas.z - rbb - tl], rbb), db, '#e67e22', 1};
end
% bottom bars of the beam in line: 2 corner bars hooked up at the cantilever side, the centre straight
% 150 into the joint, the 2 over the corner bars stop at the far face
ubh = cb.ubh + db/2;
for v = [-1 1]*max(cb.vbot)
    E(end+1,:) = {'Viga en línea (VCM): barras inferiores', 'tube', fillet3([uL v cb.zbl; ubh v cb.zbl; ubh v cb.zbl + rbb + tl], rbb), db, '#48c9b0', 1};
    E(end+1,:) = {'Viga en línea (VCM): barras inferiores', 'tube', [uL v cb.zbl + db; b v cb.zbl + db], db, '#48c9b0', 1};
end
E(end+1,:) = {'Viga en línea (VCM): barras inferiores', 'tube', [uL 0 cb.zbl; b - 150 0 cb.zbl], db, '#48c9b0', 1};
% ---- crossing beam (VCS, grid 4): continuous through the joint -----------------------------------
vL = 700;
for x = hb + cb.v
    E(end+1,:) = {'Viga que cruza (eje 4)', 'tube', [x -vL min(cb.zt); x vL min(cb.zt)], db, '#5d6d7e', 1};
    E(end+1,:) = {'Viga que cruza (eje 4)', 'tube', [x -vL cb.zbc; x vL cb.zbc], db, '#5d6d7e', 1};
end
% ---- concrete, IPE 240 and end plate (transparent) --------------------------------------------
E(end+1,:) = {'Hormigón', 'box', [0 -hb zlow; b hb top], [], '#bfb6a5', 0.12};
E(end+1,:) = {'Hormigón', 'box', [b -cb.b/2 -cb.h; uL cb.b/2 0], [], '#bfb6a5', 0.08};
E(end+1,:) = {'Hormigón', 'box', [hb - cb.b/2 -vL -cb.h; hb + cb.b/2 -hb 0], [], '#bfb6a5', 0.08};
E(end+1,:) = {'Hormigón', 'box', [hb - cb.b/2 hb -cb.h; hb + cb.b/2 vL 0], [], '#bfb6a5', 0.08};
u0 = -P.g - P.ep.t;  uI = -500;
E(end+1,:) = {'IPE 240 y placa extremo (después)', 'box', [u0 -P.ep.w/2 -P.bm.h - P.ep.under; -P.g P.ep.w/2 P.ep.ztop], [], '#5d7b99', 0.35};
E(end+1,:) = {'IPE 240 y placa extremo (después)', 'box', [uI -P.bm.b/2 -P.bm.tf; u0 P.bm.b/2 0], [], '#5d7b99', 0.35};
E(end+1,:) = {'IPE 240 y placa extremo (después)', 'box', [uI -P.bm.b/2 -P.bm.h; u0 P.bm.b/2 -P.bm.h + P.bm.tf], [], '#5d7b99', 0.35};
E(end+1,:) = {'IPE 240 y placa extremo (después)', 'box', [uI -P.bm.tw/2 -P.bm.h + P.bm.tf; u0 P.bm.tw/2 -P.bm.tf], [], '#5d7b99', 0.35};
% ---- JSON and page ------------------------------------------------------------------------------
js = cell(1, size(E, 1));
for i = 1:size(E, 1)
    Q = E{i,3};  pts = sprintf('[%.1f,%.1f,%.1f],', Q');  pts = ['[' pts(1:end-1) ']'];
    dd = E{i,4};  if isempty(dd), dd = 0; end
    js{i} = sprintf('{"g":"%s","k":"%s","p":%s,"d":%.2f,"c":"%s","o":%.2f}', E{i,1}, E{i,2}, pts, dd, E{i,5}, E{i,6});
end
data = ['[' strjoin(js, ',') ']'];
html = fileread(fullfile(fileparts(mfilename('fullpath')), 'ca_joint3d_template.html'));
html = strrep(html, '/*DATA*/[]', data);
fid = fopen(fname, 'w');  fprintf(fid, '%s', html);  fclose(fid);
fprintf('%s\n', fname);
end

function Q = ring(a0, a1, z, r)
% closed tie: rectangle a0..a1 in u and in v - hb .. (column axis at u = v + hb), rounded corners r
hb = (a0 + a1)/2;
C = [a0 a0 z; a1 a0 z; a1 a1 z; a0 a1 z; a0 a0 z];  C(:,2) = C(:,2) - hb;
C = [C(1,:) + [r 0 0]; C(2:4,:); C(1,:); C(1,:) + [r 0 0]];
Q = fillet3(C, r);
end

function Q = fillet3(Q0, r)
% round the corners of the 3D polyline Q0 (N x 3) with radius r at the bar axis
N = size(Q0, 1);  Q = Q0(1,:);  n = 8;
for i = 2:N-1
    A = Q0(i-1,:);  B = Q0(i,:);  C = Q0(i+1,:);
    u1 = (A - B)/norm(A - B);  u2 = (C - B)/norm(C - B);
    th = acos(max(-1, min(1, u1*u2')));
    if r <= 0 || th > pi - 1e-6, Q = [Q; B]; continue; end
    t = r/tan(th/2);  T1 = B + u1*t;  T2 = B + u2*t;
    Cc = B + (u1 + u2)/norm(u1 + u2)*r/sin(th/2);
    e1 = (T1 - Cc)/norm(T1 - Cc);  e2 = (T2 - Cc)/norm(T2 - Cc);
    ph = acos(max(-1, min(1, e1*e2')));
    for k = 0:n
        s = k/n;  w1 = sin((1 - s)*ph)/sin(ph);  w2 = sin(s*ph)/sin(ph);
        Q = [Q; Cc + r*(w1*e1 + w2*e2)];
    end
end
Q = [Q; Q0(N,:)];
end

function r = ifelse_j(c, a, b)
if c, r = a; else, r = b; end
end
