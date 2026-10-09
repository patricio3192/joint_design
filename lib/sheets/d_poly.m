function it = d_poly(P, s)
% D_POLY  polygon (closed) through the rows of P = [x y; ...], style s
  it = struct('t', 'poly', 'p', reshape(P.', 1, []), 's', s);
end
