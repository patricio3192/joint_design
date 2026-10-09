function G = grid_lines()
% GRID_LINES  Construction grid, in the ETABS global coordinates (m).
%
% Lettered lines run north-south, numbered lines east-west.  Each lettered
% line is given by two points (it may be inclined, like A); each numbered
% line by its Y.  Joints are named after the nearest pair: C1, A4, ...
G.v = { ...
% name  point 1           point 2
  'A',  [-1.830  0.000],  [-2.413  9.737]
  'B',  [ 0.000  0.000],  [ 0.000  9.750]
  'C',  [ 4.780  0.000],  [ 4.780  9.750]
  'D',  [ 9.560  0.000],  [ 9.560  9.750]
  'F',  [10.830  0.000],  [10.830  9.750]
};
G.h = { ...
% name  Y
  '5',  11.50
  '1',   9.75
  '6',   7.74
  '2',   5.73
  '3',   4.33
  '7',   2.23
  '4',   0.00
  '8',  -1.50
};
end
