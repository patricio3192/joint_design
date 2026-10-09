function it = jm_view(M, view, o)
% JM_VIEW  orthographic view of a joint model as lib/sheets drawing items.
%   it = jm_view(M, view, o)
% view = {u, v} picks the drawing axes from the model axes, e.g. {'x', '-y'}
% (horizontal = x, vertical = -y); the depth is the third axis.
% o (optional):
%   cut      [lo hi] along the depth: only what lies in this slab is drawn, bars
%            are clipped to it (a section); default everything
%   cut_conc [lo hi] the same for concrete pieces (default o.cut)
%   skip     {kind or grp, ...} pieces left out;  only {grp, ...} draw only these
%   style    struct kind -> style, overrides the piece style
% Bar segments running along the depth are drawn as circles; boxes as
% rectangles. Order: concrete, pieces placed before the pour, then after.
  if nargin < 3, o = struct(); end
  if ~isfield(o, 'cut'), o.cut = [-Inf Inf]; end
  if ~isfield(o, 'cut_conc'), o.cut_conc = o.cut; end
  if ~isfield(o, 'skip'), o.skip = {}; end
  if ~isfield(o, 'only'), o.only = {}; end
  ax = 'xyz';
  [iu, su] = axis_of(view{1});  [iv, sv] = axis_of(view{2});
  iw = setdiff(1:3, [iu iv]);
  pc = M.pc;
  ord = 2*ones(1, numel(pc));
  ord(strcmp({pc.kind}, 'concrete')) = 1;  ord(strcmp({pc.phase}, 'after')) = 3;
  [~, idx] = sort(ord);
  it = {};
  for i = idx
    p = pc(i);
    if any(strcmp(p.kind, o.skip)) || any(strcmp(p.grp, o.skip)), continue; end
    if ~isempty(o.only) && ~any(strcmp(p.grp, o.only)), continue; end
    s = p.style;
    if isfield(o, 'style') && isfield(o.style, p.kind), s = o.style.(p.kind); end
    cut = o.cut;  if strcmp(p.kind, 'concrete'), cut = o.cut_conc; end
    if strcmp(p.type, 'box')
      if p.pts(2,iw) < cut(1) || p.pts(1,iw) > cut(2), continue; end
      it{end+1} = d_rectxy(su*p.pts(1,iu), sv*p.pts(1,iv), su*p.pts(2,iu), sv*p.pts(2,iv), s);
      continue
    end
    Q = p.pts;  run = zeros(0, 2);               % consecutive in-plane segments -> one path
    for k = 1:size(Q, 1) - 1
      a = Q(k,:);  b = Q(k+1,:);  dl = b - a;
      if abs(dl(iw)) > 0.95*norm(dl)              % along the depth: seen end-on
        it = flush(it, run, p.d, s);  run = zeros(0, 2);
        w0 = min(a(iw), b(iw));  w1 = max(a(iw), b(iw));
        if w1 >= cut(1) && w0 <= cut(2), it{end+1} = d_circle(su*a(iu), sv*a(iv), p.d/2, s); end
        continue
      end
      [t0, t1] = clip(a(iw), b(iw), cut);
      if t0 >= t1, it = flush(it, run, p.d, s);  run = zeros(0, 2);  continue; end
      A = a + t0*dl;  B = a + t1*dl;
      PA = [su*A(iu), sv*A(iv)];  PB = [su*B(iu), sv*B(iv)];
      if isempty(run) || norm(run(end,:) - PA) > 1e-6, it = flush(it, run, p.d, s);  run = PA; end
      run = [run; PB];
    end
    it = flush(it, run, p.d, s);
  end
end

function it = flush(it, run, d, s)
  if size(run, 1) >= 2 && max(sqrt(sum(diff(run).^2, 2))) > 1e-6, it{end+1} = d_path(run, d, s); end
end

function [i, sg] = axis_of(a)
  sg = 1;  if a(1) == '-', sg = -1;  a = a(2:end); end
  i = find('xyz' == a);
end

function [t0, t1] = clip(wa, wb, cut)
  % part of the segment (parameter 0..1) inside the depth slab
  if abs(wb - wa) < 1e-12
    if wa >= cut(1) && wa <= cut(2), t0 = 0; t1 = 1; else, t0 = 1; t1 = 0; end
    return
  end
  ta = (cut(1) - wa)/(wb - wa);  tb = (cut(2) - wa)/(wb - wa);
  t0 = max(0, min(ta, tb));  t1 = min(1, max(ta, tb));
end
