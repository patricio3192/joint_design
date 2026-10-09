function it = d_weld(xt, yt, xe, ye, dr, side, sz, len, all, field, tail, s)
% D_WELD  AWS A2.4 fillet weld symbol: arrow to (xt, yt), elbow (xe, ye), reference line
% to the right (dr = 1) or left (-1); side 'arrow' | 'other' | 'both'; sz, len text;
% all = weld all around, field = field weld flag; tail text; s = triangle colour style
  it = struct('t', 'weld', 'p', [xt yt xe ye], 'dir', dr, 'side', side, 'size', sz, ...
              'len', len, 'all', all, 'field', field, 'tail', tail, 's', s);
end
