function r = aci_shear_breakout(ca1, s_perp, n, ha, da, le, fc, lambda_a, psi_c, depth_AVc)
% ACI_SHEAR_BREAKOUT  Nominal concrete breakout strength in shear of an
% anchor group, shear perpendicular to the edge, ACI 318-19 17.7.2.
% Units: N, mm, MPa (SI forms, ACI 318-19 Appendix C).
%   ca1      : edge distance in the direction of the shear (to the critical row)
%   s_perp   : spacing of the outer anchors, perpendicular to the shear
%   n        : number of anchors (cap AVc <= n*AVco, 17.7.2.1.1)
%   ha       : member thickness used for psi_h,V (17.7.2.6.1)
%   da, le   : anchor diameter and load-bearing length (le <= 8*da)
%   psi_c    : cracking factor, Table 17.7.2.5.1
%   depth_AVc: depth of the projected area AVc. Pass [] for the ACI value
%              min(1.5*ca1, ha); pass a number to override (two-face model).
% Edges parallel to the shear (ca2) are taken as infinite (continuous beam):
% psi_ed,V = 1 (17.7.2.4.1) and the narrow-member rule 17.7.2.1.2 does not apply.
le  = min(le, 8 * da);                                   % 17.7.2.2.1
Vb1 = 0.6 * (le / da)^0.2 * sqrt(da) * lambda_a * sqrt(fc) * ca1^1.5;   % (17.7.2.2.1a)
Vb2 = 3.7 * lambda_a * sqrt(fc) * ca1^1.5;                              % (17.7.2.2.1b)
Vb  = min(Vb1, Vb2);

AVco = 4.5 * ca1^2;                                      % (17.7.2.1.3)
if isempty(depth_AVc)
    depth_AVc = min(1.5 * ca1, ha);                      % 17.7.2.1.1
end
width = 1.5 * ca1 + s_perp + 1.5 * ca1;                  % ca2 = inf on both sides
AVc   = min(width * depth_AVc, n * AVco);                % 17.7.2.1.1

psi_ec = 1.0;                                            % 17.7.2.3, no eccentricity
psi_ed = 1.0;                                            % 17.7.2.4.1, ca2 >= 1.5ca1
psi_h  = max(1.0, sqrt(1.5 * ca1 / ha));                 % (17.7.2.6.1)

Vcbg = AVc / AVco * psi_ec * psi_ed * psi_c * psi_h * Vb;   % (17.7.2.1b)

r.le = le; r.Vb = Vb; r.Vb1 = Vb1; r.Vb2 = Vb2;
r.AVc = AVc; r.AVco = AVco; r.width = width; r.depth = depth_AVc;
r.psi_h = psi_h; r.Vcbg = Vcbg;
end
