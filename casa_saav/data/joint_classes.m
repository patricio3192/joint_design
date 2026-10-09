function C = joint_classes()
% JOINT_CLASSES  What arrives on each side of every joint, for detailing.
%
% Sides in GLOBAL axes, as seen on plan:
%   W = left (-X)   N = north (+Y)   E = right (+X)   S = south (-Y)
%
% Codes
%   M    moment beam: both flanges lapped and welded to the cap and shelf
%   S    shear only: the beam sits on the shelf, bottom flange welded to
%        the shelf only.  Two small plates welded to the cap, one each
%        side of the top flange, keep it from turning (not welded to it)
%   NL   the beam arrives lower, below the collar: single plate (shear
%        tab) welded to the column wall, bolted to the beam web
%   N    no beam.  The collar strip on that side is free, sized to keep
%        the number of plate types down
%   E    no beam and no room (building edge): strip limited to J.pl.w_back
%
% joint_config reads this table, finds the beam on each side in the model,
% and warns when the model disagrees (a beam missing, or a moment where
% the detail is a pin).
C = {
% joint   W     N     E     S
  '3',   'M',  'S',  'M',  'M'
  '4',   'M',  'M',  'M',  'M'
  '5',   'M',  'M',  'M',  'M'
  '6',   'M',  'S',  'M',  'M'
  '7',   'M',  'S',  'M',  'S'
  '8',   'M',  'S',  'M',  'NL'
  '9',   'M',  'M',  'M',  'NL'
  '10',  'M',  'M',  'M',  'M'
  '11',  'M',  'M',  'M',  'S'
  '12',  'M',  'M',  'M',  'M'
  '13',  'M',  'M',  'M',  'NL'
  '14',  'M',  'S',  'M',  'M'
  '69',  'E',  'M',  'M',  'M'
  '71',  'E',  'M',  'M',  'NL'
  '72',  'E',  'S',  'M',  'M'
  '73',  'E',  'M',  'M',  'N'
};
end
