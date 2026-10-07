function [P, gap, slip] = patchmech(L, c, bp, e)
% PATCHMECH  Patch load c (along the edges) x bp (across) between two clamped edges.
%   [P, gap, slip] = patchmech(L, c, bp, e)
%   Mechanism of AISC 360-16 Commentary Fig. C-J10.10: the patch moves out by d = 1,
%   two trapezoids turn about the clamped edges x = 0 and x = L, two triangles
%   (trapezoids if bp > 0) turn about transverse lines y = +-(c/2 + e).
%   P is the collapse load in units of m_p (= Fy t^2/4).

d  = 1;
x1 = (L - bp)/2;  x2 = (L + bp)/2;  yt = c/2 + e;  yc = c/2;
W = [0,      d/x1,  0;        % 1 left, about x = 0
     d*L/x1, -d/x1, 0;        % 2 right, about x = L
     d*yt/e, 0,    -d/e;      % 3 top, about y = yt
     d*yt/e, 0,     d/e;      % 4 bottom, about y = -yt
     d,      0,     0];       % 5 patch, moves out d
Ln = [0 -yt 0 yt 1 0 1;  L -yt L yt 2 0 1;  0 yt L yt 3 0 1;  0 -yt L -yt 4 0 1];
Lp = [x1 -yc x1 yc 1 5 1;  x2 -yc x2 yc 2 5 1;  x1 yc x2 yc 3 5 1;  x1 -yc x2 -yc 4 5 1;
      0 yt x1 yc 1 3 1;  L yt x2 yc 2 3 1;  0 -yt x1 -yc 1 4 1;  L -yt x2 -yc 2 4 1];
if bp == 0, Lp([3 4],:) = []; end
[WI, gap, slip] = yl_work(W, [Ln; Lp]);
P = WI/d;
end
