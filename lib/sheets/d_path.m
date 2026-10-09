function it = d_path(Q, d, s)
% D_PATH  a bar of diameter d along the polyline Q = [x y; ...] (filled outline, mitred joints)
  k = [true; any(abs(diff(Q)) > 1e-9, 2)];  Q = Q(k,:);  N = size(Q, 1);
  T = zeros(N, 2);
  for i = 1:N
    t = Q(min(i+1, N),:) - Q(max(i-1, 1),:);  T(i,:) = t/norm(t);
  end
  Nn = [-T(:,2) T(:,1)];  sc = ones(N, 1);
  for i = 2:N-1
    s1 = Q(i,:) - Q(i-1,:);  s1 = s1/norm(s1);
    sc(i) = 1/max(Nn(i,:)*[-s1(2); s1(1)], 0.5);
  end
  it = d_poly([Q + Nn.*(d/2*sc); flipud(Q - Nn.*(d/2*sc))], s);
end
