function Q = arcp(c, r, a1, a2, n)
% ARCP  points on an arc, centre c, radius r, from a1 to a2 degrees
  if nargin < 5, n = 10; end
  a = (a1 + (a2 - a1)*(0:n)'/n)*pi/180;  Q = [c(1) + r*cos(a), c(2) + r*sin(a)];
end
