function it = c_nut(x, y, dir, N, s)
% C_NUT  Washer and nut on a rod along x, seen from the side: {washer, nut}.
% The washer starts at x and both go in the direction dir (+1 or -1).
%
%   N.wsh, N.nut  washer and nut thickness     N.dw, N.nw  washer OD and nut width
%   s             style (e.g. 'r_nut', or 'r_ancg' for parts placed later)
  if dir > 0
    it = {d_rectxy(x, y - N.dw/2, x + N.wsh, y + N.dw/2, s), ...
          d_rectxy(x + N.wsh, y - N.nw/2, x + N.wsh + N.nut, y + N.nw/2, s)};
  else
    it = {d_rectxy(x - N.wsh, y - N.dw/2, x, y + N.dw/2, s), ...
          d_rectxy(x - N.wsh - N.nut, y - N.nw/2, x - N.wsh, y + N.nw/2, s)};
  end
end
