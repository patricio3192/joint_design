function lbcheck(name, f, Lx, Ly, w)
% LBCHECK  Checks a lower bound moment field of a simply supported rectangle.
%   lbcheck(name, f, Lx, Ly, w)
%   f(x,y) = [mx my mxy] in units of m_p, plate x in [-Lx/2, Lx/2], y in [-Ly/2, Ly/2]
%   w      the uniform load the field claims to carry (units m_p per mm2)
%   Prints: equilibrium error, edge moments, and the largest yield ratio for the
%   square (Johansen), Tresca and von Mises criteria (<= 1 means admissible).

hd = 1e-2;
xs = linspace(-Lx/2, Lx/2, 41);  ys = linspace(-Ly/2, Ly/2, 41);
eq = 0;  J = 0;  T = 0;  M = 0;  ed = 0;
for x = xs
    for y = ys
        mxx = (comp(f, x+hd, y, 1) - 2*comp(f, x, y, 1) + comp(f, x-hd, y, 1))/hd^2;
        myy = (comp(f, x, y+hd, 2) - 2*comp(f, x, y, 2) + comp(f, x, y-hd, 2))/hd^2;
        mxy = (comp(f, x+hd, y+hd, 3) - comp(f, x+hd, y-hd, 3) - comp(f, x-hd, y+hd, 3) + comp(f, x-hd, y-hd, 3))/(4*hd^2);
        eq = max(eq, abs(mxx + 2*mxy + myy + w)/w);          % d2mx/dx2 + 2 d2mxy/dxdy + d2my/dy2 = -w
        m = f(x, y);
        k = eig([m(1) m(3); m(3) m(2)]);
        J = max(J, max(abs(k)));
        T = max(T, max([abs(k); abs(k(1) - k(2))]));
        M = max(M, k(1)^2 - k(1)*k(2) + k(2)^2);
    end
end
for y = ys, ed = max([ed, abs(comp(f, Lx/2, y, 1)), abs(comp(f, -Lx/2, y, 1))]); end
for x = xs, ed = max([ed, abs(comp(f, x, Ly/2, 2)), abs(comp(f, x, -Ly/2, 2))]); end
fprintf('     %s: equilibrium err %.0e, edge moment %.0e, yield ratio  Johansen %.2f  Tresca %.2f  von Mises %.2f\n', ...
    name, eq, ed, J, T, sqrt(M));
end

function v = comp(f, x, y, i)
m = f(x, y);
v = m(i);
end
