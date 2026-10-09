function Q = jm_fillet3(Q0, r, n)
% JM_FILLET3  round the corners of a 3D polyline Q0 = [x y z; ...] with radius r
% (n segments per arc, default 6). Closed polylines (last = first) keep the
% first corner sharp.
  if nargin < 3, n = 6; end
  N = size(Q0, 1);  Q = Q0(1,:);
  for i = 2:N-1
    A = Q0(i-1,:);  B = Q0(i,:);  C = Q0(i+1,:);
    u1 = (A - B)/norm(A - B);  u2 = (C - B)/norm(C - B);
    th = acos(max(-1, min(1, u1*u2')));
    t = r/tan(th/2);
    if r <= 0 || th > pi - 1e-6 || t > 0.5*min(norm(A - B), norm(C - B)), Q = [Q; B]; continue; end
    Cc = B + (u1 + u2)/norm(u1 + u2)*r/sin(th/2);
    T1 = B + u1*t;  T2 = B + u2*t;
    e1 = (T1 - Cc)/r;  e2 = (T2 - Cc)/r;
    w = acos(max(-1, min(1, e1*e2')));
    for k = 0:n                                   % slerp from e1 to e2
      a = w*k/n;
      Q = [Q; Cc + r*(sin(w - a)*e1 + sin(a)*e2)/sin(w)];
    end
  end
  Q = [Q; Q0(N,:)];
end
