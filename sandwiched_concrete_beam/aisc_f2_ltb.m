function r = aisc_f2_ltb(E, Fy, Zx, Sx, Iy, J, ho, ry, Lb, Cb)
% AISC_F2_LTB  Nominal flexural strength of a doubly symmetric compact
% I-shape bent about its major axis, AISC 360-16 Section F2.
%   Units: N, mm, MPa. Returns struct with Mp, Lp, Lr, rts, Mn [N*mm]
%   and the equation that governs.
c   = 1.0;                                   % (F2-8a) doubly symmetric
Cw  = Iy * ho^2 / 4;                         % F2.2 User Note, doubly symmetric I
rts = sqrt(sqrt(Iy * Cw) / Sx);              % (F2-7)
Mp  = Fy * Zx;                               % (F2-1)
Lp  = 1.76 * ry * sqrt(E / Fy);              % (F2-5)
Jc  = J * c / (Sx * ho);
Lr  = 1.95 * rts * (E / (0.7 * Fy)) * ...
      sqrt(Jc + sqrt(Jc^2 + 6.76 * (0.7 * Fy / E)^2));   % (F2-6)

if Lb <= Lp
    Mn = Mp;                                 % F2.1, yielding
    eq = 'F2-1 (Lb <= Lp)';
elseif Lb <= Lr
    Mn = Cb * (Mp - (Mp - 0.7 * Fy * Sx) * (Lb - Lp) / (Lr - Lp));   % (F2-2)
    Mn = min(Mn, Mp);
    eq = 'F2-2 (Lp < Lb <= Lr)';
else
    Fcr = Cb * pi^2 * E / (Lb / rts)^2 * sqrt(1 + 0.078 * Jc * (Lb / rts)^2);  % (F2-4)
    Mn  = min(Fcr * Sx, Mp);                 % (F2-3)
    eq  = 'F2-3/F2-4 (Lb > Lr)';
end

r.Mp = Mp; r.Lp = Lp; r.Lr = Lr; r.rts = rts; r.Cw = Cw;
r.Mn = Mn; r.eq = eq;
end
