function it = d_dim(x0, y0, x1, y1, off, txt, pos)
% D_DIM  aligned dimension p0 -> p1, dimension line at off (model mm) to the left;
% pos = 'after' | 'before': where the text goes when it does not fit
  if nargin < 7, pos = 'after'; end
  it = struct('t', 'dim', 'p', [x0 y0 x1 y1], 'o', off, 'txt', txt, 'pos', pos);
end
