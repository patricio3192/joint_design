function [WI, gap, slip] = yl_work(W, L)
% YL_WORK  Internal work of a yield line mechanism, from the planes of its rigid regions.
%   [WI, gap, slip] = yl_work(W, L)
%   W     n x 3, deflection plane of region k: w = W(k,1) + W(k,2) x + W(k,3) y
%   L     one row per yield line: [x1 y1 x2 y2 kA kB m]
%         kA, kB  regions on the two sides (0 = plate that does not move)
%         m       plastic moment per unit length of that line (1 = m_p)
%   WI    sum over the lines of m * length * (jump of the slope normal to the line)
%   gap   largest jump of w at the ends of a line (must be 0: the plate does not tear)
%   slip  largest jump of the slope along a line (must be 0 for the same reason)
%
%   No projection rule and no assumed rotations are used: the slope jumps come
%   straight from the planes, so this is an independent check of the hand work.

WI = 0;  gap = 0;  slip = 0;
for i = 1:size(L,1)
    p1 = L(i,1:2);  p2 = L(i,3:4);
    d = p2 - p1;  len = norm(d);
    t = d/len;  n = [-t(2) t(1)];
    dw = plane(W, L(i,5)) - plane(W, L(i,6));
    gap  = max([gap, abs(dw*[1 p1]'), abs(dw*[1 p2]')]);
    slip = max(slip, abs(dw(2:3)*t'));
    WI = WI + L(i,7)*len*abs(dw(2:3)*n');
end
end

function c = plane(W, k)
% plane of region k, zero for the plate that does not move
if k == 0
    c = [0 0 0];
else
    c = W(k,:);
end
end
