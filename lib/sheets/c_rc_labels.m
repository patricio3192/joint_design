function it = c_rc_labels(S, o)
% C_RC_LABELS  reinforcement callouts to the right of a concrete section, written
% from the bars themselves: "3Ø14" for each layer (beams) or "8Ø16" for all the
% bars (columns), plus the stirrup text, each with a leader.
%   it = c_rc_labels(S)                     % S as c_rc_section (b, h, ct, bars)
%   it = c_rc_labels(S, struct('kind', 'column', 'st', 'Est. Ø10 c/15'))
% o.kind  'beam' (default: one label per layer, top layer first) | 'column'
% o.st    stirrup text (e.g. 'Est. Ø8 c/15'); leader to the right leg at mid-height
% o.x     x of the texts (default b/2 + 120);  o.y0  y of the section bottom (0)
% o.ls    text style ('bsm'), o.lst stirrup text style ('tie')
% For a section centred on its axis (c_column_tie) pass o.y0 = -h/2.
  if nargin < 2, o = struct(); end
  if ~isfield(o, 'kind'), o.kind = 'beam'; end
  if ~isfield(o, 'x'), o.x = S.b/2 + 120; end
  if ~isfield(o, 'y0'), o.y0 = 0; end
  if ~isfield(o, 'ls'), o.ls = 'bsm'; end
  if ~isfield(o, 'lst'), o.lst = 'tie'; end
  B = S.bars;  it = {};
  if strcmp(o.kind, 'column')
    [~, k] = max(B(:,1) + 1e-3*B(:,2));
    it = [it, c_leader(o.x, B(k,2) + S.h*0.25, B(k,1:2), bars_txt(B(:,3)), o.ls)];
  else
    ys = unique(round(B(:,2)));  ys = sort(ys, 'descend');
    for i = 1:numel(ys)
      g = B(abs(B(:,2) - ys(i)) < 1, :);
      [~, k] = max(g(:,1));
      it = [it, c_leader(o.x, ys(i) + (ys(i) > o.y0 + S.h/2)*40 - (ys(i) <= o.y0 + S.h/2)*40, ...
                         g(k,1:2), bars_txt(g(:,3)), o.ls)];
    end
  end
  if isfield(o, 'st')
    xs = S.b/2 - S.ct;
    it = [it, c_leader(o.x, o.y0 + S.h/2 - 20, [xs, o.y0 + S.h/2], o.st, o.lst)];
  end
end

function t = bars_txt(d)
  % "3Ø14" or "2Ø16 + 2Ø12"
  u = unique(d);  parts = {};
  for v = fliplr(u(:)'), parts{end+1} = sprintf('%dØ%g', sum(d == v), v); end
  t = strjoin(parts, ' + ');
end
