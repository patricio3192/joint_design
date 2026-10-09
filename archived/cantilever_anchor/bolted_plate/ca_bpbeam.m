function B = ca_bpbeam(P, T, ro)
% CA_BPBEAM  Back plate as a beam along its length (used by ca_calc and ca_anchor_page).
%   Back plate PL t x h x b as a beam along b: uniform pressure w = T/b from the concrete, each anchor
%   pushing back on the ring ro > r > d_h/2 around its hole (ro = 0: a point at the axis). Half plate,
%   x = 0 at the centre. Plastic capacity of the width left at each cut, reduced for the shear.
bp = P.bp;  Fy = P.st.Fy(bp.grade);  Fu = P.st.Fu(bp.grade);  xa = P.an.vT;  rh = P.an.hole/2;
L = bp.w/2;  x = linspace(0, L, 4801)';  dx = x(2) - x(1);  w = T/bp.w;  Ra = w*L;
bn = bp.h - 2*sqrt(max(rh^2 - (x - xa).^2, 0));
if ro == 0
    p = zeros(size(x));  [~, i0] = min(abs(x - xa));  p(i0) = Ra/dx;
else
    c = 2*sqrt(max(ro^2 - (x - xa).^2, 0)) - 2*sqrt(max(rh^2 - (x - xa).^2, 0));  p = Ra*c/(sum(c)*dx);
end
V = cumsum(w - p)*dx;  V = V - V(1);
M = cumsum(V)*dx;  M = M - M(end);
Mp = Fy*bn*bp.t^2/4;  Vp = 0.6*Fy*bn*bp.t;
Cm = 0.9*Mp.*max(1 - (V./Vp).^2, 0);
r = abs(M)./max(Cm, 1);  hole = abs(x - xa) <= rh;
[~, i] = max(r.*hole);
B.x = x;  B.M = M;  B.V = V;  B.bn = bn;  B.Cm = Cm;  B.w = w;  B.Ra = Ra;
B.M0 = abs(M(1));  B.xh = x(i);  B.bh = bn(i);  B.Mh = abs(M(i));  B.Vh = abs(V(i));  B.Ch = Cm(i);
B.Vmx = max(abs(V.*hole));  B.Cvr = 0.75*0.6*Fu*(bp.h - P.an.hole)*bp.t;
[~, j] = min(abs(x - xa));  B.Ma = abs(M(j));  B.Va = max(abs(V));
end
