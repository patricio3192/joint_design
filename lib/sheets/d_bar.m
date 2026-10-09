function it = d_bar(x0, y0, x1, y1, d, s)
% D_BAR  straight bar of diameter d
  it = d_path([x0 y0; x1 y1], d, s);
end
