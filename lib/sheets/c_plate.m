function it = c_plate(L)
% C_PLATE  Rectangular plate with rows of holes, seen on its face, top edge at
% y = 0 (y up), centred on x = 0: {plate, holes, dims}.
%
%   L.b, L.H   width and height        L.g      gage (holes at x = +/- g/2)
%   L.rows     hole rows, distance from the top edge     L.dh   hole diameter
%   L.s        plate style ('r_eplate')                   L.off  dimension offsets
%              [bottom, top, side] (default [-30 30 30])
% Dimensions: width (bottom), gage (top), and the chain top -> rows -> bottom (right).
  if ~isfield(L, 's'), L.s = 'r_eplate'; end
  if ~isfield(L, 'off'), L.off = [-30 30 30]; end
  it = {d_rectxy(-L.b/2, -L.H, L.b/2, 0, L.s)};
  for v = -L.rows(:)', for x = [-1 1]*L.g/2, it{end+1} = d_circle(x, v, L.dh/2, 'void'); end, end
  it{end+1} = d_dim(-L.b/2, -L.H, L.b/2, -L.H, L.off(1), sprintf('%g', L.b));
  it{end+1} = d_dim(-L.g/2, 0, L.g/2, 0, L.off(2), sprintf('%g', L.g));
  y = [0, L.rows(:)', L.H];
  for k = 1:numel(y) - 1
    it{end+1} = d_dim(L.b/2, -y(k), L.b/2, -y(k+1), L.off(3), sprintf('%g', y(k+1) - y(k)));
  end
end
