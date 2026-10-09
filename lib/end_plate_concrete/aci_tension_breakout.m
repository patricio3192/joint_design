function r = aci_tension_breakout(hef, sx, sy, n, ca, fc, lambda_a, psi_c)
% ACI_TENSION_BREAKOUT  Concrete breakout strength in tension of a cast-in
% headed anchor group on a rectangular grid, ACI 318-19 17.6.2 (SI forms,
% Appendix C). Units: N, mm, MPa.
%   hef      : effective embedment depth
%   sx, sy   : outer-to-outer spacing of the group in x and y (0 for one row)
%   n        : number of anchors (cap ANc <= n*ANco)
%   ca       : edge distances [left right top bottom]; Inf = no edge
%   psi_c    : cracking factor 17.6.2.5.1 (1.0 cracked, 1.25 uncracked cast-in)
% Eccentricity psi_ec,N = 1 and psi_cp,N = 1 (cast-in) are taken as 1.
near = ca(ca < 1.5*hef);
r.hef_used = hef;
if numel(near) >= 3                                      % 17.6.2.1.2
    r.hef_used = max(max(near)/1.5, max(sx, sy)/3);
end
h  = r.hef_used;
cx = min(ca(1), 1.5*h) + sx + min(ca(2), 1.5*h);
cy = min(ca(3), 1.5*h) + sy + min(ca(4), 1.5*h);
r.ANco = 9 * h^2;                                        % (17.6.2.1.4)
r.ANc  = min(cx * cy, n * r.ANco);                       % 17.6.2.1.1
camin  = min(ca);
r.psi_ed = min(1, 0.7 + 0.3*camin/(1.5*h));              % (17.6.2.4.1a,b)
if h >= 280 && h <= 635
    r.Nb = 3.9 * lambda_a * sqrt(fc) * h^(5/3);          % (17.6.2.2.3)
else
    r.Nb = 10 * lambda_a * sqrt(fc) * h^1.5;             % (17.6.2.2.1), kc = 10
end
r.Ncbg = r.ANc / r.ANco * r.psi_ed * psi_c * r.Nb;       % (17.6.2.1b)
end
