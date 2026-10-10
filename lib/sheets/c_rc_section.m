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
%   S.inner           interior closed stirrups, one row each: [xa ya xb yb db]
%                     = centres of two opposite corner bars it wraps and their
%                     diameter; 135 deg hooks at its top-left bar, like the outer one
%   S.xties           crossties (grapas), one row each: [xA yA xB yB db]: a straight
%                     bar from bar A to bar B (diameter db) on the left of A->B,
%                     hooked around both; S.xhooks = [hook at A, hook at B] in deg
%                     (default [90 135]; [135 135] for seismic detailing)
% Interior stirrups and crossties use S.dst and S.st. Extension of every hook
% max(6 dst, 75) (ACI 25.3.2), drawn, not checked.
% Returns the outline, the two stirrup pieces, the interior stirrups, the
% crossties and the bars, in that order; add c_rc_dims(S) and c_rc_labels(S).
  if ~isfield(S, 'rb'), S.rb = 8; end
  if ~isfield(S, 'hook'), S.hook = [22 60]; end
  if ~isfield(S, 's'), S.s = 'r_conc'; end
  if ~isfield(S, 'st'), S.st = 'r_tieS'; end
  if ~isfield(S, 'bars'), S.bars = zeros(0, 3); end
  if ~isfield(S, 'bar_s'), S.bar_s = 'r_bm1'; end
  if ~isfield(S, 'inner'), S.inner = zeros(0, 5); end
  if ~isfield(S, 'xties'), S.xties = zeros(0, 5); end
  if ~isfield(S, 'xhooks'), S.xhooks = [90 135]; end
  b = S.b;  h = S.h;  ct = S.ct;
  it = {d_rectxy(-b/2, 0, b/2, h, S.s)};
  it = [it, stirrup(-b/2 + ct, ct, b/2 - ct, h - ct, S.rb, S.hook, S.dst, S.st)];
  for k = 1:size(S.inner, 1)
    q = S.inner(k,:);  r = q(5)/2 + S.dst/2;           % centreline wraps the corner bars
    hk = [2.5*r, max(6*S.dst, 75)];
    it = [it, stirrup(min(q(1), q(3)) - r, min(q(2), q(4)) - r, max(q(1), q(3)) + r, max(q(2), q(4)) + r, r, hk, S.dst, S.st)];
  end
  for k = 1:size(S.xties, 1)
    it{end+1} = d_path(crosstie(S.xties(k,1:2), S.xties(k,3:4), S.xties(k,5)/2 + S.dst/2, S.xhooks, ...
                                max(6*S.dst, 75)), S.dst, S.st);
  end
  for k = 1:size(S.bars, 1)
    if iscell(S.bar_s), st = S.bar_s{k}; else, st = S.bar_s; end
    it{end+1} = d_circle(S.bars(k,1), S.bars(k,2), S.bars(k,3)/2, st);
  end
end

function it = stirrup(XL, YB, XR, YT, rb, hook, dst, st)
  % closed stirrup on the axis rectangle XL..XR x YB..YT, 135 deg hooks at the top-left corner
  TL = [XL, YT];  w = hook(2)*[1 -1]/sqrt(2);  m = [(XL + XR)/2, YT];
  e1 = TL + [hook(1) 0];  e2 = TL + [0 -hook(1)];      % both hooks wrap the corner bar, pointing inward
  it = {d_path(fillet([e1 + w; e1; TL; XL, YB; XR, YB; XR, YT; m], rb), dst, st), ...
        d_path(fillet([m; TL; e2; e2 + w], rb), dst, st)};
end

function Q = crosstie(A, B, r, hooks, e)
  % straight leg on the left of A->B at distance r from the bar centres, hooked around A and B
  u = (B - A)/norm(B - A);  n = [-u(2) u(1)];  th = atan2d(n(2), n(1));
  QB = hook_pts(B, r, th, -1, hooks(2), e);              % around B: clockwise
  QA = hook_pts(A, r, th, 1, hooks(1), e);               % around A: counter-clockwise
  Q = [flipud(QA); QB];
end

function Q = hook_pts(C, r, th, sg, deg, e)
  % from the leg's end at angle th around the bar centre C, sweep deg, then the extension
  Q = arcp(C, r, th, th + sg*deg, max(4, round(deg/15)));
  f = th + sg*deg;
  Q = [Q; Q(end,:) + e*sg*[-sind(f) cosd(f)]];
end

