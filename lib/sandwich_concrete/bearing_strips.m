function r = bearing_strips(p)
% BEARING_STRIPS  Compression side of an end plate bearing on concrete,
% lower-bound ("strict strips") model.
%
% The bearing pressure is fp (uniform, ACI 318-19 22.8.3.2) but it is only
% placed where the end plate can carry it as a cantilever strip of length
% <= c that lands on a support (beam flange or web). c comes from the DG 1
% strip equation (Eq. 3.3.14a-1) solved for the length:
%     tp = c*sqrt(2*fp/(phi_b*Fy))   ->   c = tp*sqrt(phi_b*Fy/(2*fp))
% Any pressure field that is in equilibrium, never exceeds fp and is carried
% by the plate within its plastic moment is safe (lower-bound theorem).
% The same idea (effective bearing width c around the section) is
% EN 1993-1-8 Sec. 6.2.5, Eq. (6.5); not an AISC provision.
%
% Coordinates: y measured up from the bottom edge of the plate, x from the
% web centreline. Zones that are counted:
%   below the flange : |x| <= bf/2, ext-c <= y < ext        (strip down from flange)
%   flange band      : |x| <= min(bp, bf+2c)/2, ext <= y <= ext+tf (overhang strip)
%   above the flange : |x| <= bf/2, ext+tf < y <= ext+tf+c  (strip up from flange)
%   web zone         : |x| <= tw/2 + c, above that          (strips from the web)
% Plate corners outside these zones have no supported strip and get no pressure.
% Pressure is filled from the bottom edge up (largest lever arm) until
% C*(D - ybar) = Mu. Bolt holes inside the zones are deducted.
%
% Input struct p (N, mm, MPa): bp, bf, tf, tw, h, ext, tp, Fyp, phi_b, fp,
%   D (tension bolt line to plate bottom edge), Mu, holes_y, holes_x, dh.
c  = p.tp * sqrt(p.phi_b * p.Fyp / (2 * p.fp));
dy = 0.01;
y  = (dy/2 : dy : p.ext + p.h - p.tf)';      % up to the inner face of the top flange
w  = zeros(size(y));

y_fl0 = p.ext;  y_fl1 = p.ext + p.tf;
k = (y >= p.ext - c) & (y < y_fl0);            w(k) = p.bf;
k = (y >= y_fl0) & (y <= y_fl1);               w(k) = min(p.bp, p.bf + 2*c);
k = (y > y_fl1) & (y <= y_fl1 + c);            w(k) = min(p.bp, max(p.bf, p.tw + 2*c));
k = (y > y_fl1 + c);                           w(k) = min(p.bp, p.tw + 2*c);

% deduct holes: chord of each hole that falls inside [-w/2, w/2]
rh = p.dh / 2;
for i = 1:numel(p.holes_y)
    for j = 1:numel(p.holes_x)
        dyh = y - p.holes_y(i);
        k = abs(dyh) < rh;
        half = sqrt(rh^2 - dyh(k).^2);
        x0 = p.holes_x(j) - half;  x1 = p.holes_x(j) + half;
        lo = max(x0, -w(k)/2);     hi = min(x1, w(k)/2);
        w(k) = w(k) - max(0, hi - lo);
    end
end

A  = cumsum(w) * dy;                  % bearing area below each y
Sy = cumsum(w .* y) * dy;             % first moment about the plate bottom
ybar = Sy ./ max(A, eps);
M  = p.fp * A .* (p.D - ybar);        % moment about the tension bolt line

i = find(M >= p.Mu, 1, 'first');
r.c = c;
r.Mmax = max(M);
if isempty(i)
    r.ok = false; r.yt = NaN; r.C = NaN; r.ybar = NaN; r.arm = NaN; r.A = NaN;
else
    r.ok   = true;
    r.yt   = y(i) + dy/2;             % top of the pressure field
    r.A    = A(i);
    r.C    = p.fp * A(i);
    r.ybar = ybar(i);
    r.arm  = p.D - ybar(i);
end
r.web_zone_width = min(p.bp, p.tw + 2*c);
end
