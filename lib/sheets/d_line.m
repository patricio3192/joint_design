function it = d_line(x0, y0, x1, y1, s)
% D_LINE  line segment
  it = struct('t', 'line', 'p', [x0 y0 x1 y1], 's', s);
end
