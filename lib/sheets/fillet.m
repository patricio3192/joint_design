function Q = fillet(Q0, r, n)
% FILLET  round the inner corners of the polyline Q0 with radius r (n segments per arc)
  if nargin < 3, n = 10; end
  N = size(Q0, 1);  Q = Q0(1,:);
  for i = 2:N-1
    A = Q0(i-1,:);  Bv = Q0(i,:);  C = Q0(i+1,:);
    u1 = (A - Bv)/norm(A - Bv);  u2 = (C - Bv)/norm(C - Bv);
    th = acos(max(-1, min(1, u1*u2')));
    if r <= 0 || th > pi - 1e-6, Q = [Q; Bv]; continue; end
    t = r/tan(th/2);  T1 = Bv + u1*t;
    Cc = Bv + (u1 + u2)/norm(u1 + u2)*r/sin(th/2);
    T2 = Bv + u2*t;
    a1 = atan2(T1(2) - Cc(2), T1(1) - Cc(1));  a2 = atan2(T2(2) - Cc(2), T2(1) - Cc(1));
    da = mod(a2 - a1 + pi, 2*pi) - pi;
    a = a1 + da*(0:n)'/n;
    Q = [Q; Cc(1) + r*cos(a), Cc(2) + r*sin(a)];
  end
  Q = [Q; Q0(N,:)];
end
