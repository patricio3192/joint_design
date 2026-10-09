function it = c_rc_section(S)
% C_RC_SECTION  Rectangular concrete section, origin at the bottom centre (y up):
% outline, closed stirrup with two 135 deg hooks at the top-left corner bar, bars.
%
%   S.b, S.h          section (mm)
%   S.ct              stirrup axis from the faces (cover + db_st/2), S.dst stirrup
%                     diameter, S.rb bend radius on the axis (default 8)
%   S.hook            [offset along the sides from the corner, leg length] (default [22 60])
%   S.bars            [x y d; ...] bar centres (y from the bottom) and diameters
%   S.bar_s           cell of bar styles, one per bar (or one style for all, default 'r_bm1')
%   S.s, S.st         concrete and stirrup styles (default 'r_conc', 'r_tieS')
% Returns the outline, the two stirrup pieces and the bars, in that order; add
% texts and then c_rc_dims(S) for the overall dimensions.
  if ~isfield(S, 'rb'), S.rb = 8; end
  if ~isfield(S, 'hook'), S.hook = [22 60]; end
  if ~isfield(S, 's'), S.s = 'r_conc'; end
  if ~isfield(S, 'st'), S.st = 'r_tieS'; end
  if ~isfield(S, 'bars'), S.bars = zeros(0, 3); end
  if ~isfield(S, 'bar_s'), S.bar_s = 'r_bm1'; end
  b = S.b;  h = S.h;  ct = S.ct;
  it = {d_rectxy(-b/2, 0, b/2, h, S.s)};
  TL = [-b/2 + ct, h - ct];  w = S.hook(2)*[1 -1]/sqrt(2);  m = [0, h - ct];
  e1 = TL + [S.hook(1) 0];  e2 = TL + [0 -S.hook(1)];   % both hooks wrap the corner bar, pointing inward
  it{end+1} = d_path(fillet([e1 + w; e1; TL; -b/2 + ct, ct; b/2 - ct, ct; b/2 - ct, h - ct; m], S.rb), S.dst, S.st);
  it{end+1} = d_path(fillet([m; TL; e2; e2 + w], S.rb), S.dst, S.st);
  for k = 1:size(S.bars, 1)
    if iscell(S.bar_s), st = S.bar_s{k}; else, st = S.bar_s; end
    it{end+1} = d_circle(S.bars(k,1), S.bars(k,2), S.bars(k,3)/2, st);
  end
end
