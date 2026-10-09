function it = d_circle(x, y, r, s)
% D_CIRCLE  circle (filled by the style, if it has a fill)
  it = struct('t', 'circle', 'p', [x y r], 's', s);
end
