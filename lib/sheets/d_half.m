function it = d_half(x, y, r, up, s)
% D_HALF  half circle: the end of a bar that turns toward the viewer (up = 1: upper half)
  a = linspace(0, pi, 13)';  if up < 0, a = a + pi; end
  it = d_poly([x + r*cos(a), y + r*sin(a)], s);
end
