function F = jm_clash(M, o)
% JM_CLASH  clear distances between the pieces of a joint model (jm_new, jm_bar,
% jm_box) and the list of what is too close.
%   F = jm_clash(M, o)
% Every pair with at least one new piece is checked, except pieces of the same
% assembly (grp), assemblies listed in each other's touch, and concrete. Bars are
% cylinders along their polyline (flat ends), boxes are axis-parallel boxes.
% Classes, most severe first:
%   CLASH    the pieces overlap (clear < -tol)
%   spacing  parallel rebar/rods closer than max(smin, db1, db2, 4/3 dagg)
%            (ACI 318-19 25.2.1, for concrete to flow between them)
%   contact  touching (|clear| <= tol): normal for tied crossing bars
%   tight    0 < clear < o.tight (information)
% o (optional): smin 25, dagg 19 (aggregate size), tol 0.5, tight 10,
%   par_deg 10 (angle below which two bars are parallel), print true.
% F: struct array cls, a, b (names), clear, need, at ([x y z] between the
%   closest points), rule.
  def = struct('smin', 25, 'dagg', 19, 'tol', 0.5, 'tight', 10, 'par_deg', 10, 'print', true);
  if nargin < 2, o = struct(); end
  f = fieldnames(o);  for i = 1:numel(f), def.(f{i}) = o.(f{i}); end
  o = def;
  pc = M.pc;  n = numel(pc);
  bb = zeros(2, 3, n);
  for i = 1:n
    if strcmp(pc(i).type, 'bar'), bb(:,:,i) = [min(pc(i).pts, [], 1) - pc(i).d/2; max(pc(i).pts, [], 1) + pc(i).d/2];
    else, bb(:,:,i) = pc(i).pts; end
  end
  reach = max([o.smin, 4/3*o.dagg, [pc.d]]) + o.tight;
  F = struct('cls', {}, 'a', {}, 'b', {}, 'clear', {}, 'need', {}, 'at', {}, 'rule', {});
  cpar = cosd(o.par_deg);
  for i = 1:n-1
    A = pc(i);
    if strcmp(A.kind, 'concrete'), continue; end
    for j = i+1:n
      B = pc(j);
      if strcmp(B.kind, 'concrete') || ~(A.new || B.new), continue; end
      if strcmp(A.grp, B.grp) || any(strcmp(A.grp, B.touch)) || any(strcmp(B.grp, A.touch)), continue; end
      g = max(bb(1,:,j) - bb(2,:,i), bb(1,:,i) - bb(2,:,j));
      if norm(max(g, 0)) > reach, continue; end
      [c, at, par] = pair_clear(A, B, cpar);
      need = 0;  rule = 'interference';
      if par && any(strcmp(A.kind, {'rebar', 'rod'})) && any(strcmp(B.kind, {'rebar', 'rod'}))
        need = max([o.smin, A.d, B.d, 4/3*o.dagg]);  rule = 'ACI 25.2.1 parallel bars';
      end
      if c < -o.tol, cls = 'CLASH';
      elseif c < need - o.tol, cls = 'spacing';
      elseif c <= o.tol, cls = 'contact';
      elseif c < o.tight, cls = 'tight';
      else, continue; end
      F(end+1) = struct('cls', cls, 'a', A.name, 'b', B.name, 'clear', c, 'need', need, 'at', at, 'rule', rule);
    end
  end
  if isempty(F), rank = []; else
    [~, rank] = ismember({F.cls}, {'CLASH', 'spacing', 'contact', 'tight'});
    [~, k] = sortrows([rank(:), [F.clear]']);  F = F(k);
  end
  if o.print
    fprintf('--- CLASH CHECK: %d pieces, %d findings ---\n', n, numel(F));
    for k = 1:numel(F)
      fprintf('  %-8s %-24s %-24s clear %6.1f', F(k).cls, F(k).a, F(k).b, F(k).clear);
      if F(k).need > 0, fprintf(' < %4.1f', F(k).need); else, fprintf('       '); end
      fprintf('  at (%5.0f,%5.0f,%5.0f)\n', F(k).at);
    end
  end
end

% ---------------------------------------------------------------------------
function [c, at, par] = pair_clear(A, B, cpar)
  par = false;
  if strcmp(A.type, 'box') && strcmp(B.type, 'box')
    g = max(B.pts(1,:) - A.pts(2,:), A.pts(1,:) - B.pts(2,:));
    if any(g > 0), c = norm(max(g, 0)); else, c = max(g); end
    at = (max(A.pts(1,:), B.pts(1,:)) + min(A.pts(2,:), B.pts(2,:)))/2;
    return
  end
  if strcmp(A.type, 'box'), [A, B] = deal(B, A); end
  if strcmp(B.type, 'box')                       % bar A against box B
    c = Inf;  at = [0 0 0];
    for k = 1:size(A.pts, 1) - 1
      [ck, ak] = seg_box(A, k, B.pts);
      if ck < c, c = ck;  at = ak; end
    end
    return
  end
  c = Inf;  at = [0 0 0];                        % bar against bar
  for k = 1:size(A.pts, 1) - 1
    p1 = A.pts(k,:);  q1 = A.pts(k+1,:);
    for m = 1:size(B.pts, 1) - 1
      p2 = B.pts(m,:);  q2 = B.pts(m+1,:);
      [s, t, c1, c2] = seg_seg(p1, q1, p2, q2);
      ck = norm(c1 - c2) - (A.d + B.d)/2;
      [ea, ua, ca] = bar_end(A, k, s);
      if ea, ck = max(ck, disk_dist(c2, ca, ua, A.d/2) - B.d/2); end
      [eb, ub, cb] = bar_end(B, m, t);
      if eb, ck = max(ck, disk_dist(c1, cb, ub, B.d/2) - A.d/2); end
      if ck < c
        c = ck;  at = (c1 + c2)/2;
        u1 = (q1 - p1)/norm(q1 - p1);  u2 = (q2 - p2)/norm(q2 - p2);
        par = abs(u1*u2') > cpar && overlap(p1, q1, p2, q2) > 0;
      end
    end
  end
end

function [c, at] = seg_box(A, k, bx)
  p = A.pts(k,:);  q = A.pts(k+1,:);  r = A.d/2;
  f = @(t) sd_box(p + t*(q - p), bx);
  a = 0;  b = 1;  g = (sqrt(5) - 1)/2;           % golden section: f is convex along the segment
  x1 = b - g*(b - a);  x2 = a + g*(b - a);  f1 = f(x1);  f2 = f(x2);
  for it = 1:40
    if f1 < f2, b = x2;  x2 = x1;  f2 = f1;  x1 = b - g*(b - a);  f1 = f(x1);
    else,       a = x1;  x1 = x2;  f1 = f2;  x2 = a + g*(b - a);  f2 = f(x2); end
  end
  t = (a + b)/2;
  if f(0) <= f(t), t = 0; elseif f(1) <= f(t), t = 1; end
  at = p + t*(q - p);  c = f(t) - r;
  [e, u, ce] = bar_end(A, k, t);
  if e                                           % flat end: nearest point of the end disk
    [v, w] = perp(u);  ang = (0:15)'*pi/8;
    D = [ce; ce + r*(cos(ang)*v + sin(ang)*w)];
    c = min(arrayfun(@(i) sd_box(D(i,:), bx), 1:rows(D)));
  end
end

function d = sd_box(p, bx)
  dv = max(bx(1,:) - p, p - bx(2,:));
  d = norm(max(dv, 0)) + min(max(dv), 0);
end

function [e, u, c] = bar_end(A, k, s)
  % is parameter s of segment k a free end of the bar? u = outward axis there
  N = size(A.pts, 1);  e = false;  u = [0 0 0];  c = [0 0 0];
  if norm(A.pts(1,:) - A.pts(N,:)) < 1e-9, return; end   % closed (a hoop)
  if k == 1 && s < 1e-6
    e = true;  c = A.pts(1,:);  u = A.pts(1,:) - A.pts(2,:);
  elseif k == N - 1 && s > 1 - 1e-6
    e = true;  c = A.pts(N,:);  u = A.pts(N,:) - A.pts(N-1,:);
  end
  if e, u = u/norm(u); end
end

function d = disk_dist(q, c, u, r)
  % distance from point q to the solid end of a bar (end centre c, outward axis u, radius r)
  v = q - c;  a = v*u';  p = norm(v - a*u);
  if a > 0, d = hypot(max(p - r, 0), a);
  elseif p > r, d = p - r;
  else, d = -min(r - p, -a); end
end

function L = overlap(p1, q1, p2, q2)
  u = (q1 - p1)/norm(q1 - p1);
  t = sort([(p2 - p1)*u', (q2 - p1)*u']);
  L = min(norm(q1 - p1), t(2)) - max(0, t(1));
end

function [v, w] = perp(u)
  [~, i] = min(abs(u));  e = zeros(1, 3);  e(i) = 1;
  v = cross(u, e);  v = v/norm(v);  w = cross(u, v);
end

function [s, t, c1, c2] = seg_seg(p1, q1, p2, q2)
  % closest points of two segments (Ericson, Real-Time Collision Detection, 5.1.9)
  d1 = q1 - p1;  d2 = q2 - p2;  r = p1 - p2;
  a = d1*d1';  e = d2*d2';  f = d2*r';
  cl = @(x) min(max(x, 0), 1);
  if a <= eps && e <= eps, s = 0;  t = 0;
  elseif a <= eps, s = 0;  t = cl(f/e);
  else
    c = d1*r';
    if e <= eps, t = 0;  s = cl(-c/a);
    else
      b = d1*d2';  den = a*e - b*b;
      if den > 1e-12*a*e, s = cl((b*f - c*e)/den); else, s = 0; end
      t = (b*s + f)/e;
      if t < 0, t = 0;  s = cl(-c/a);
      elseif t > 1, t = 1;  s = cl((b - c)/a); end
    end
  end
  c1 = p1 + d1*s;  c2 = p2 + d2*t;
end
