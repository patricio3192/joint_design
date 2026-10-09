function it = d_tri(x, y, sx, sy, s)
% D_TRI  right triangle with the right angle at (x, y), legs sx and sy (signed)
  it = d_poly([x y; x + sx y; x y + sy], s);
end
