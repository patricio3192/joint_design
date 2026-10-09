function Q = rotp(Q, deg, c)
% ROTP  rotate the points Q by deg degrees about c
  a = deg*pi/180;  Rm = [cos(a) -sin(a); sin(a) cos(a)];
  Q = (Q - c)*Rm' + c;
end
