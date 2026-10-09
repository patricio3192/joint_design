function it = c_dim_chain(P, off, fmt)
% C_DIM_CHAIN  Consecutive dimensions between the points P = [x y; ...] (in
% order along a line), dimension line at off, text sprintf(fmt, length) ('%g').
  if nargin < 3, fmt = '%g'; end
  it = {};
  for k = 1:size(P, 1) - 1
    it{end+1} = d_dim(P(k,1), P(k,2), P(k+1,1), P(k+1,2), off, sprintf(fmt, norm(P(k+1,:) - P(k,:))));
  end
end
