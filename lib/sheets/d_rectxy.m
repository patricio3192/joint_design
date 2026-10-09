function it = d_rectxy(x0, y0, x1, y1, s)
% D_RECTXY  rectangle between two corners
  it = d_poly([x0 y0; x1 y0; x1 y1; x0 y1], s);
end
