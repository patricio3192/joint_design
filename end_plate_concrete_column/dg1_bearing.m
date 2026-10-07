function r = dg1_bearing(p)
% DG1_BEARING  Compression side of an end plate bearing on concrete (through
% grout), AISC Design Guide 1 2nd ed. Sec. 3.4 (large moment) with Pr = 0,
% and the plate thickness from the DG 1 cantilever strips.
%   Uniform pressure fp over bp x Y at the plate bottom edge:
%     Y = D - sqrt(D^2 - 2*Mu/(fp*bp))         (Eq. 3.4.3, Pr = 0)
%     solution exists if D^2 >= 2*Mu/(fp*bp)   (Eq. 3.4.4, Pr = 0)
%   Cantilevers (one-sided version of DG 1 Sec. 3.1.2):
%     m = ext + 0.025*d   (the (N - 0.95d)/2 line, 0.025d inside the flange face)
%     n = (bp - 0.8*bf)/2
%   Required thickness:
%     Y >= m : tp = 1.49*m*sqrt(fp/Fy)                    (Eq. 3.3.14a-1)
%     Y <  m : tp = 2.11*sqrt(fp*Y*(m - Y/2)/Fy)          (Eq. 3.3.15a-1)
%     n      : tp = 1.49*n*sqrt(fp/Fy)                    (Eq. 3.3.14a-1 with n)
% Input struct p (N, mm, MPa): Mu, D (tension row to plate bottom edge),
%   bp, fp, ext, d, bf, Fyp.
r.ok = p.D^2 >= 2*p.Mu/(p.fp*p.bp);
r.m  = p.ext + 0.025*p.d;
r.n  = (p.bp - 0.8*p.bf)/2;
if ~r.ok
    r.Y = NaN; r.arm = NaN; r.C = NaN; r.t_m = NaN; r.t_n = NaN; r.t_req = NaN;
    return
end
r.Y   = p.D - sqrt(p.D^2 - 2*p.Mu/(p.fp*p.bp));
r.arm = p.D - r.Y/2;
r.C   = p.fp * p.bp * r.Y;
if r.Y >= r.m
    r.t_m = 1.49 * r.m * sqrt(p.fp/p.Fyp);
else
    r.t_m = 2.11 * sqrt(p.fp * r.Y * (r.m - r.Y/2) / p.Fyp);
end
r.t_n   = 1.49 * r.n * sqrt(p.fp/p.Fyp);
r.t_req = max(r.t_m, r.t_n);
end
