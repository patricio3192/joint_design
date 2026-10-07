function [WI, gap, slip] = flushmech(bp, g, pf, s, h1)
% FLUSHMECH  Flush end plate, two bolts per row: the mechanism of DG 16 Table 3-2.
%   [WI, gap, slip] = flushmech(bp, g, pf, s, h1)
%   x across the plate from the web, y up from the centre of the compression flange.
%   The beam end turns theta = 1 about the compression flange (w = y), the bolts
%   stay put (w = 0). Lines: inner face of the tension flange, bolt line (bolt to
%   edge), s below the bolts, both faces of the web, and the diagonals from the bolt.
%   WI in units of m_p: M = WI m_p, so M/(Fy t^2) = WI/4 is the Y of the mechanism.

yf = h1 + pf;  ys = h1 - s;
R1 = [-yf*h1/pf, 0, yf/pf];           % between flange and bolt line: 0 on the bolt line, yf at the flange
R2 = [(h1 - s)*h1/s, 0, -(h1 - s)/s]; % between bolt line and s-line
W = [R1;  R2;  0 -2*h1/g 1;           % 1-3 right of the web (3 = the triangle at the web)
     R1;  R2;  0  2*h1/g 1;           % 4-6 left
     0 0 1];                          % 7 the beam end: flange, web and the plate below the s-line
L = [0 yf bp/2 yf 1 7 1;      -bp/2 yf 0 yf 4 7 1;        % inner face of the tension flange
     g/2 h1 bp/2 h1 1 2 1;    -g/2 h1 -bp/2 h1 4 5 1;     % bolt line
     0 ys bp/2 ys 2 7 1;      -bp/2 ys 0 ys 5 7 1;        % s below the bolts
     0 yf g/2 h1 3 1 1;       g/2 h1 0 ys 3 2 1;          % diagonals, right
     0 yf -g/2 h1 6 4 1;      -g/2 h1 0 ys 6 5 1;         % diagonals, left
     0 ys 0 yf 3 7 1;         0 ys 0 yf 6 7 1];           % faces of the web
[WI, gap, slip] = yl_work(W, L);
end
