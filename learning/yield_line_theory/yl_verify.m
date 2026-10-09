% YL_VERIFY  Checks every formula and number of yield_lines.html.
%   octave-cli yl_verify.m      (run from inside yield_line_theory)
%   Units: N, mm, MPa. m_p in N mm/mm = N.
%   Each mechanism is built from the deflection planes of its rigid regions and
%   its work is summed by yl_work.m (slope jumps, no projection rule), so the
%   hand formulas of the page are checked by a different route.

ok = @(c) char('FAIL'*(~c) + 'ok  '*c);   % 4-char flag
Fy = 248;  Fu = 400;                       % A36 plate
mp = @(t, F) F*t.^2/4;

% ---- 1. plastic moment per unit length ---------------------------------------
fprintf('\n1. m_p = Fy t^2/4  (N mm/mm = N)\n');
for t = [6 8 10 12 16 20 25]
    fprintf('   t = %2d   A36 %7.0f   Gr50 %7.0f   phi m_p A36 %7.0f\n', t, mp(t,248), mp(t,345), 0.9*mp(t,248));
end
m12 = mp(12, Fy);
fprintf('   12 mm A36: m_p = %.0f N = %.3f kN m/m;  m_y = Fy t^2/6 = %.0f;  Z/S = %.2f <= 1.6 (F11.1)\n', ...
    m12, m12/1e3, Fy*144/6, m12/(Fy*144/6));

% ---- 2. one-way strips (the V2 models) ---------------------------------------
% strip of width b along y, span L along x; supports at x = 0 and x = L
fprintf('\n2. Strips, span L, width b\n');
L = 40;  b = 25.8;  d = 1;
W = [0 d/(L/2) 0; 2*d -d/(L/2) 0];                 % left half, right half
C = {[0 0; L/2 0; L/2 b; 0 b], [L/2 0; L 0; L b; L/2 b]};
Lp = [L/2 0 L/2 b 1 2 1];                          % positive line at mid-span
Ln = [0 0 0 b 1 0 1; L 0 L b 2 0 1];               % negative lines at fixed supports
V = yl_volume(W, C);                               % unit uniform load
wSS = yl_work(W, Lp)/V;   wFX = yl_work(W, [Lp; Ln])/V;    % pressure, units m_p
pSS = yl_work(W, Lp)/d;     pFX = yl_work(W, [Lp; Ln])/d;
fprintf('   uniform: SS F = w L b = %.4f m_p b/L (8)   fixed %.4f (16)\n', wSS*L^2, wFX*L^2);
fprintf('   point:   SS P = %.4f m_p b/L (4)   fixed %.4f (8)\n', pSS*L/b, pFX*L/b);
Tf = 82.73e3;  bf = 120;                          % V2 ca_calc, edge
Fg = Tf*L/bf;
fprintf('   V2 3b: F = %.2f kN; phi 8 m_p b/L = %.2f kN (D/C %.2f); fixed %.2f kN (D/C %.2f)\n', ...
    Fg/1e3, 0.9*8*m12*b/L/1e3, Fg/(0.9*8*m12*b/L), 0.9*16*m12*b/L/1e3, Fg/(0.9*16*m12*b/L));
Tc = 67.62e3;  e = 12;  bs = 152;
fprintf('   V2 3c: M = T e = %.3f kN m; phi m_p b = %.3f kN m (D/C %.2f)\n', Tc*e/1e6, 0.9*m12*bs/1e6, Tc*e/(0.9*m12*bs));

% ---- 3. simply supported square plate, uniform load ---------------------------
fprintf('\n3. Square plate, simply supported, side a\n');
a = 300;
W = [0 0 2*d/a; 2*d -2*d/a 0; 2*d 0 -2*d/a; 0 2*d/a 0];   % bottom, right, top, left
C = {[0 0; a 0; a/2 a/2], [a 0; a a; a/2 a/2], [a a; 0 a; a/2 a/2], [0 a; 0 0; a/2 a/2]};
Ld = [0 0 a/2 a/2 1 4 1; a 0 a/2 a/2 1 2 1; a a a/2 a/2 2 3 1; 0 a a/2 a/2 3 4 1];
[WI, gp] = yl_work(W, Ld);
k = WI/yl_volume(W, C)*a^2;
fprintf('   diagonals: w = %.4f m_p/a^2 (24)  gap %.1e  %s\n', k, gp, ok(abs(k-24) < 1e-9));
fprintf('   t = 12, a = 300: w = %.3f MPa (upper bound)\n', 24*m12/a^2);

% lower bound fields, checked on a grid: equilibrium (finite differences) and yield
fprintf('   lower bound fields:\n');
lbcheck('two-way, mxy = 0  (square)', @(x,y) [1-4*x.^2/a^2, 1-4*y.^2/a^2, 0*x], a, a, 16/a^2);
lbcheck('Prager, mxy = -4xy/a^2  ', @(x,y) [1-4*x.^2/a^2, 1-4*y.^2/a^2, -4*x.*y/a^2], a, a, 24/a^2);
fprintf('   t = 12, a = 300: lower bound w = %.3f MPa\n', 16*m12/a^2);

% ---- 4. rectangle a x b (a short), simply supported, ridge parameter x --------
fprintf('\n4. Rectangle a x b, simply supported\n');
a = 200;  b = 400;
wx = @(x) 12*(2*b*x + a^2)./(a^2*x.*(3*b - 2*x));            % Bruneau (4.53), units m_p
x0 = a/(2*b)*(-a + sqrt(a^2 + 3*b^2));                        % Bruneau (4.54)
xn = fminbnd(wx, 1, b/2);
x  = 130;                                                     % one mechanism, checked by planes
W = [0 0 2*d/a; 2*d 0 -2*d/a; 0 d/x 0; b*d/x -d/x 0];         % bottom, top, left, right
C = {[0 0; b 0; b-x a/2; x a/2], [b a; 0 a; x a/2; b-x a/2], [0 0; x a/2; 0 a], [b 0; b a; b-x a/2]};
Lr = [x a/2 b-x a/2 1 2 1; 0 0 x a/2 1 3 1; 0 a x a/2 2 3 1; b 0 b-x a/2 1 4 1; b a b-x a/2 2 4 1];
[WI, gp] = yl_work(W, Lr);
fprintf('   x = %g: planes %.6e, (4.53) %.6e  gap %.1e  %s\n', x, WI/yl_volume(W,C), wx(x), gp, ok(abs(WI/yl_volume(W,C)/wx(x)-1) < 1e-9));
r = a/b;  wmin = 24/(a^2*(sqrt(3 + r^2) - r)^2);
fprintf('   x_opt = %.2f (closed form)  %.2f (numerical);  x/a = %.3f\n', x0, xn, x0/a);
fprintf('   w_min = %.4e m_p;  24/(a^2 (sqrt(3+r^2)-r)^2) = %.4e  %s\n', wx(x0), wmin, ok(abs(wx(x0)/wmin-1) < 1e-9));
fprintf('   t = 12: upper %.3f MPa; lower 8(1/a^2+1/b^2) %.3f MPa; strip 8/a^2 %.3f MPa\n', ...
    wmin*m12, 8*(1/a^2 + 1/b^2)*m12, 8/a^2*m12);
lbcheck('two-way, mxy = 0  (2:1)  ', @(x,y) [1-4*x.^2/b^2, 1-4*y.^2/a^2, 0*x], b, a, 8*(1/a^2 + 1/b^2));
fprintf('   bracket vs b/a (units m_p/a^2):\n');
for q = [1 1.5 2 3 4 10]
    fprintf('     b/a = %4.1f  upper %6.3f  lower %6.3f\n', q, 24/(sqrt(3 + 1/q^2) - 1/q)^2, 8*(1 + 1/q^2));
end

% ---- 5. point load: polygon fans -> circle ------------------------------------
fprintf('\n5. Point load, regular n-gon of triangles (circumradius R)\n');
R = 50;
for n = [3 4 5 6 8 12 24 96]
    ph = 2*pi*(0:n)/n;  P = R*[cos(ph') sin(ph')];
    W = zeros(n,3);  Lf = zeros(0,7);
    for i = 1:n
        p1 = P(i,:);  p2 = P(i+1,:);  nv = [p2(2)-p1(2), p1(1)-p2(1)];  nv = nv/norm(nv);
        if p1*nv' < 0, nv = -nv; end                         % outward normal of the edge
        h = p1*nv';                                          % apex (origin) to the edge
        W(i,:) = [d, -d*nv/h];                               % w = d (1 - nv.p/h): d at the apex, 0 on the edge
        Lf(end+1,:) = [0 0 p1 i 1+mod(i-2,n) 1];             % positive radial line
        Lf(end+1,:) = [p1 p2 i 0 1];                         % negative edge
    end
    [WI, gp] = yl_work(W, Lf);
    fprintf('   n = %2d: positive only %.4f m_p, with negative edges %.4f m_p  (2n tan(pi/n) = %.4f) gap %.0e\n', ...
        n, WI/2, WI, 2*n*tan(pi/n), gp);
end
fprintf('   circle: 2 pi = %.4f, 4 pi = %.4f;  t = 12: 4 pi m_p = %.1f kN, phi %.1f kN\n', 2*pi, 4*pi, 4*pi*m12/1e3, 0.9*4*pi*m12/1e3);
c = 20;  Rr = 100;
fprintf('   patch r = %g on a clamped circle R = %g (cone): P = 4 pi m_p/(1-2c/3R) = %.2f m_p\n', c, Rr, 4*pi/(1 - 2*c/(3*Rr)));

% ---- 6. line / patch load between two clamped edges (AISC Fig. C-J10.10) -------
fprintf('\n6. Patch c x bp between clamped edges, span L\n');
L = 164;  c = 120;  bp = 22;  t = 10;
for ee = [0.25 0.5 0.75]*L
    [Pw, gp, sl] = patchmech(L, c, bp, ee);
    Pf = 8*(c + 2*ee)/(L - bp) + 4*L/ee;
    fprintf('   e = %5.1f: planes %.4f m_p, hand m_p[8(c+2e)/(L-bp) + 4L/e] = %.4f  gap %.0e slip %.0e  %s\n', ...
        ee, Pw, Pf, gp, sl, ok(abs(Pw/Pf-1) < 1e-9));
end
eo = sqrt(L*(L - bp))/2;  [Pmin, gp] = patchmech(L, c, bp, eo);
eta = c/L;  be = bp/L;
K213 = 4*(2*eta/(1 - be) + 4/sqrt(1 - be));
fprintf('   e_opt = sqrt(L(L-bp))/2 = %.1f: %.4f m_p;  4[2eta/(1-beta) + 4/sqrt(1-beta)] = %.4f  %s\n', eo, Pmin, K213, ok(abs(Pmin/K213-1) < 1e-9));
fprintf('   bp -> 0: e = L/2, P = m_p (8c/L + 16) = %.3f m_p\n', 8*c/L + 16);
fprintf('   HEB 240 web, t = %g, A36: m_p = %.0f N; Pn = %.1f kN; phi 0.9 -> %.1f kN\n', t, mp(t,Fy), K213*mp(t,Fy)/1e3, 0.9*K213*mp(t,Fy)/1e3);
% the same pattern without the transverse triangles is not a mechanism
W = [0 d/(L/2) 0; 2*d -d/(L/2) 0];
Lbad = [0 -c/2-20 L/2 -c/2 1 0 1; 0 c/2+20 L/2 c/2 1 0 1];
[WI, gp] = yl_work(W, Lbad);
fprintf('   trapezoids touching the still plate on their sloping sides: gap %.2f (plate torn)  %s\n', gp, ok(gp > 0.1));

% ---- 7. T-stub: three modes ------------------------------------------------------
fprintf('\n7. T-stub, m = 35, n = 30, leff = 150, 2 rods 16 mm (Fu 400), phi from AISC\n');
m = 35;  n = 30;  le = 150;  db = 16;
Ab = pi*db^2/4;  Bn = 0.75*400*Ab;  B = 0.75*Bn;   % AISC J3.6, Table J3.2: Fnt = 0.75 Fu; phi 0.75
fprintf('   rod: Fnt Ab = %.1f kN, phi rn = %.1f kN; n <= 1.25 m: %s\n', Bn/1e3, B/1e3, ok(n <= 1.25*m));
for t = [8 10 12 14 16 20]
    M = 0.9*mp(t,Fy)*le;
    F1 = 4*M/m;  F2 = (2*M + n*2*B)/(m + n);  F3 = 2*B;
    [Fm, im] = min([F1 F2 F3]);
    fprintf('   t = %2d: mode 1 %6.1f  mode 2 %6.1f  mode 3 %6.1f kN  -> mode %d\n', t, F1/1e3, F2/1e3, F3/1e3, im);
end
M12 = 0.9*mp(12,Fy)*le;
F2 = (2*M12 + n*2*B)/(m + n);
fprintf('   t = 12 mode 2: F = %.1f kN, prying Q = B - F/2 = %.1f kN per rod, moment at the bolt Q n = %.2f kN m <= M = %.2f\n', ...
    F2/1e3, (B - F2/2)/1e3, (B - F2/2)*n/1e6, M12/1e6);
t12 = sqrt(m*n*2*B/(2*m + 4*n)/(0.9*Fy*le/4));     % mode 1 = mode 2: M = m n 2B/(2m + 4n)
t23 = sqrt(4*m*B/(0.9*Fy*le));                     % mode 2 = mode 3: M = m B
fprintf('   modes 1|2 at t = %.2f mm, modes 2|3 at t = %.2f mm\n', t12, t23);
bpr = m - db/2;  tc = sqrt(4*B*bpr/(0.9*le*Fu));
fprintf('   AISC no prying (Segui 7.18, alpha = 0): t = sqrt(4 B b''/(phi p Fu)) = %.2f mm (b'' = %g, p = %g)\n', tc, bpr, le);
fprintf('   same equation with m and Fy: %.2f mm;  ratio sqrt(m Fu/(b'' Fy)) = %.3f\n', t23, sqrt(m*Fu/(bpr*Fy)));
fprintf('   EC3 circular pattern: leff = 2 pi m = %.0f mm -> mode 1 per rod = 2 M/m = 4 pi m_p  %s\n', 2*pi*m, ok(abs(2*(mp(1,1)*2*pi*m)/m - 4*pi*mp(1,1)) < 1e-12));

% ---- 8. flush end plate, two bolts per row (DG 16 Table 3-2) ------------------
fprintf('\n8. Flush end plate, IPE 240, two bolts per row\n');
h = 240;  tf = 9.8;  bpl = 140;  g = 70;  pf = 35;
h1 = h - tf - pf - tf/2;  s = sqrt(bpl*g)/2;
Ydg = bpl/2*(h1*(1/pf + 1/s) - 1/2) + 2/g*(h1*(pf + s));
Yme = bpl/2*h1*(1/pf + 1/s) + 2/g*h1*(pf + s);
[Mw, gp, sl] = flushmech(bpl, g, pf, s, h1);
fprintf('   h1 = %.1f, s = %.1f (pf < s: %s)\n', h1, s, ok(pf < s));
fprintf('   planes: M/(Fy t^2 theta) = %.2f;  main terms %.2f  %s;  gap %.0e slip %.0e\n', Mw/4, Yme, ok(abs(Mw/4/Yme-1) < 1e-9), gp, sl);
fprintf('   DG 16 Y = %.1f mm (the -bp/4 term: %.1f, %.1f %%)\n', Ydg, -bpl/4, 100*bpl/4/Yme);
for t = [10 12 16]
    fprintf('   t = %2d: phi Mpl = 0.9 Fy t^2 Y = %.1f kN m\n', t, 0.9*Fy*t^2*Ydg/1e6);
end
fprintf('   V2 edge Mu = 19.05 kN m\n\n');

% ---- local functions are in separate files: lbcheck.m, patchmech.m, flushmech.m
