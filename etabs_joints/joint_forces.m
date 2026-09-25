function [res, chk] = joint_forces(M, joint, ref)
% JOINT_FORCES  Forces of all frames connected to a joint, all output cases.
%
%   [res, chk] = joint_forces(M, 'J123')            ref axes = the column
%   [res, chk] = joint_forces(M, 'J123', 'global')  ref axes = global XYZ
%   [res, chk] = joint_forces(M, 'J123', 'C45')     ref axes = frame C45
%
% res(k) fields (one row per frame per output case):
%   frame, type, endIJ, ocase (case + step type/number), ctype, station
%   loc  = [P V2 V3 T M2 M3]  as ETABS reports it at that end
%          (member local axes, ETABS sign convention - unchanged)
%   glob = [Fx Fy Fz Mx My Mz] force/moment the MEMBER EXERTS ON THE JOINT,
%          global axes, at the member end station (column face etc.)
%   ref  = same vector as glob, expressed in the reference axes (1,2,3)
%
% chk: per case, sum of member forces on joint (moments taken about the
%      joint centre). Moments should close to ~0. Forces will NOT fully
%      close, for two known reasons:
%       - vertical: load acting on the rigid end-offset zones goes straight
%         into the joint (~0.1 kN in your model)
%       - horizontal: with a rigid diaphragm, in-plane forces are carried by
%         the diaphragm constraint, and Ex/Ey story forces are applied at
%         the joints; neither appears in frame forces
%
% Sign logic (CSI convention: internal forces act on the positive-1 face):
%   I-end: member acts on joint with +f      J-end: with -f
%   CSI M2 has the opposite rotational sense to a right-hand vector about
%   axis 2 (dM2/dx = -V3, like dM3/dx = -V2), so M2 is negated before
%   rotating to global. Verified on the full model: with this, moment
%   equilibrium closes to < 0.01 kNm at every column top.
%   glob = R' * (s * [P V2 V3 T -M2 M3])

  if nargin < 3, ref = ''; end
  pj = M.pt.xyz(strcmp(M.pt.name, joint), :);
  if isempty(pj), error('Joint %s not found.', joint); end

  atI = find(strcmp(M.fr.ptI, joint));
  atJ = find(strcmp(M.fr.ptJ, joint));
  frames = [atI; atJ];
  ends   = [repmat('I', numel(atI), 1); repmat('J', numel(atJ), 1)];
  if isempty(frames), error('No frames connected to %s.', joint); end

  % reference axes
  if isempty(ref)
    kc = frames(strcmp(M.fr.type(frames), 'Column'));
    if numel(kc) == 1
      Rref = M.fr.R(:,:,kc); refName = M.fr.name{kc};
    else
      Rref = eye(3); refName = 'global';
    end
  elseif strcmpi(ref, 'global')
    Rref = eye(3); refName = 'global';
  else
    kr = find(strcmp(M.fr.name, ref), 1);
    if isempty(kr), error('Reference frame %s not found.', ref); end
    Rref = M.fr.R(:,:,kr); refName = ref;
  end

  res = struct('frame',{},'type',{},'endIJ',{},'ocase',{},'ctype',{},'station',{}, ...
               'loc',{},'glob',{},'ref',{},'arm',{});
  for m = 1:numel(frames)
    i  = frames(m);
    R  = M.fr.R(:,:,i);
    rows = find(strcmp(M.F.name, M.fr.name{i}));
    if isempty(rows)
      warning('No forces found for frame %s.', M.fr.name{i}); continue
    end
    sta = M.F.sta(rows);
    if ends(m) == 'I', target = min(sta); s = +1; else, target = max(sta); s = -1; end
    rows = rows(abs(sta - target) < 1e-6 * max(1, M.fr.L(i)));

    % position of the station point relative to the joint (lever arm)
    pI = M.pt.xyz(strcmp(M.pt.name, M.fr.ptI{i}), :);
    arm = pI + target * R(1,:) - pj;

    key = strcat(M.F.case(rows), '|', M.F.step(rows));
    [~, first] = unique(key, 'first');
    for r = rows(sort(first)).'
      f  = M.F.f(r, :);
      v  = f .* [1 1 1 1 -1 1];     % CSI: M2 has opposite sense (see header)
      g  = [R.' * (s * v(1:3)).'; R.' * (s * v(4:6)).'].';
      k  = numel(res) + 1;
      res(k).frame   = M.fr.name{i};
      res(k).type    = M.fr.type{i};
      res(k).endIJ   = ends(m);
      res(k).ocase   = strtrim([M.F.case{r} ' ' M.F.step{r}]);
      res(k).ctype   = M.F.ctype{r};
      res(k).station = target;
      res(k).loc     = f;
      res(k).glob    = g;
      res(k).ref     = [(Rref * g(1:3).').' (Rref * g(4:6).').'];
      res(k).arm     = arm;
    end
  end

  % equilibrium check per case (moments transferred to joint centre)
  cases = unique({res.ocase}, 'stable');
  chk = struct('ocase', cases, 'sumF', [], 'sumM', []);
  for c = 1:numel(cases)
    sel = res(strcmp({res.ocase}, cases{c}));
    SF = zeros(1,3); SM = zeros(1,3);
    for k = 1:numel(sel)
      SF += sel(k).glob(1:3);
      SM += sel(k).glob(4:6) + cross(sel(k).arm, sel(k).glob(1:3));
    end
    chk(c).sumF = SF; chk(c).sumM = SM;
  end
  [res.refAxes] = deal(refName);
end
