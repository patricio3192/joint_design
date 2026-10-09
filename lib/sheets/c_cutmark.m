function it = c_cutmark(p, e, L, o)
% C_CUTMARK  Section cut across a member at p: two short strokes and the letter,
% e = unit direction of the member.  Sizes in model mm (o.k scales them all):
% strokes from 260 to 480 from the axis, letter 120 beyond, 60 along e and down.
  if nargin < 4, o = struct(); end
  if ~isfield(o, 'k'), o.k = 1; end
  n = [-e(2) e(1)];  it = {};  k = o.k;
  for sg = [-1 1]
    a = p + sg*260*k*n;  b = p + sg*480*k*n;
    it{end+1} = d_line(a(1), a(2), b(1), b(2), 'lead');
    it{end+1} = d_text(b(1) + sg*n(1)*120*k + 60*k*e(1), b(2) + sg*n(2)*120*k - 60*k, L, 'code', 'middle');
  end
end
