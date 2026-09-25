function map = joint_map(M, joint, colM, tol)
% JOINT_MAP  Frame map of a beam-column joint for dmj_lib, from geometry.
%
%   map = joint_map(M, '10')          strong direction = column M3
%   map = joint_map(M, '10', 'M2')    strong direction = column M2
%
% map fields (the ones dmj_lib uses are strong, weak, col, colM):
%   col       column BELOW the joint (by Z, not by I/J), [] if none
%   colAbove  column above the joint, [] if none
%   strong    beams whose moment goes into the column's colM moment
%   weak      the other beams
%   colM      'M3' or 'M2'
%   skew      beams more than tol degrees (default 10) off both column axes,
%             still assigned to the closer direction
% Frames are numbers, as dmj_lib expects.
%
% A beam along column local axis 2 bends the column about local 3 (M3),
% a beam along local axis 3 bends it about local 2 (M2).

  if nargin < 3 || isempty(colM), colM = 'M3'; end
  if nargin < 4, tol = 10; end

  pj    = M.pt.xyz(strcmp(M.pt.name, joint), :);
  isCol = strcmp(M.fr.type, 'Column');
  isBm  = strcmp(M.fr.type, 'Beam');
  atJ   = strcmp(M.fr.ptI, joint) | strcmp(M.fr.ptJ, joint);

  map = struct('joint', joint, 'strong', [], 'weak', [], 'col', [], ...
               'colAbove', [], 'colM', colM, 'skew', []);

  % columns above / below, from the Z of the far end
  kc = find(isCol & atJ);
  ic = [];
  for k = kc.'
    if strcmp(M.fr.ptI{k}, joint), far = M.fr.ptJ{k}; else, far = M.fr.ptI{k}; end
    zf = M.pt.xyz(strcmp(M.pt.name, far), 3);
    if zf < pj(3)
      ic(end+1) = k;
    else
      map.colAbove(end+1) = frame_num(M, k);
    end
  end
  if numel(ic) > 1
    error('Joint %s has %d columns below it.', joint, numel(ic));
  end
  if isempty(ic), return; end
  map.col = frame_num(M, ic);

  % beams, sorted by the column local axis they run along
  Rc = M.fr.R(:,:,ic);
  if strcmp(colM, 'M3'), axStrong = 2; else, axStrong = 3; end
  for k = find(isBm & atJ).'
    e1 = M.fr.R(1,:,k);
    c  = abs([dot(e1, Rc(2,:)) dot(e1, Rc(3,:))]);
    [cmax, a] = max(c);
    if acosd(min(cmax / max(norm(c), eps), 1)) > tol
      map.skew(end+1) = frame_num(M, k);
    end
    if a + 1 == axStrong
      map.strong(end+1) = frame_num(M, k);
    else
      map.weak(end+1) = frame_num(M, k);
    end
  end
end

function n = frame_num(M, k)
  n = str2double(M.fr.name{k});
  if isnan(n)
    error('Frame name "%s" is not a number; dmj_lib needs numeric names.', M.fr.name{k});
  end
end
