function R = joint_residual(M, jt, skip)
% JOINT_RESIDUAL  Break down the equilibrium/mapping residual of a joint.
%
%   R = joint_residual(M, DB.joints(k), 'RSA')
%
% The residual printed by dmj_lib / dwj_lib is, for each direction,
%     column moment + bending of the beams mapped to that direction
% about that column axis.  At a real joint the full moment balance about
% the joint centre also contains three terms that the residual leaves out:
%
%   torsion  torque (T) of the beams mapped to the OTHER direction: a beam
%            twisting into the column
%   skew     bending (M2, M3) of the beams mapped to the OTHER direction:
%            beams not exactly along a column axis
%   (a mapped beam's contribution to its own direction, torque included,
%   is in "mapped", exactly as the libraries sum it)
%   arm      force x lever arm: member forces are reported at the member
%            end station (column face, end offsets), not at the joint
%            centre.  A shear at the face of the column makes a moment
%            about its axis.
%
% Per case, for [strong weak], all in kN*m about the column axes:
%   R(n).col, .mapped, .torsion, .skew, .arm
%   R(n).residual = col + mapped                     (what the libraries print)
%   R(n).closure  = residual + torsion + skew + arm  (should be ~0)
%   R(n).ratio    = max|residual| / max(largest beam moment, 1 kN*m)
% Same sign conventions as joint_forces.

  if nargin < 3, skip = 'RSA'; end
  map = jt.map;  res = jt.res;
  if strcmp(map.colM, 'M3'), ax = [3 2]; else, ax = [2 3]; end   % [strong weak] column axis
  kc = find(strcmp(M.fr.name, num2str(map.col)), 1);
  Rc = M.fr.R(:,:,kc);

  names = unique({res.ocase}, 'stable');
  if ~isempty(skip), names = names(cellfun(@isempty, strfind(names, skip))); end

  R = struct('name', {}, 'col', {}, 'mapped', {}, 'torsion', {}, 'skew', {}, ...
             'arm', {}, 'residual', {}, 'closure', {}, 'ratio', {});
  for n = 1:numel(names)
    sel = find(strcmp({res.ocase}, names{n}));
    t = zeros(5, 2);          % rows: col, mapped, torsion, skew, arm
    Mb = 0;
    for r = sel
      k = find(strcmp(M.fr.name, res(r).frame), 1);
      Rm = M.fr.R(:,:,k);
      if res(r).endIJ == 'I', s = 1; else, s = -1; end
      v  = res(r).loc .* [1 1 1 1 -1 1];                  % as in joint_forces
      mT = Rc * (Rm.' * (s * [v(4); 0; 0]));             % torque
      mB = Rc * (Rm.' * (s * [0; v(5); v(6)]));          % bending
      F  = Rm.' * (s * v(1:3).');
      mA = Rc * cross(res(r).arm(:), F);                  % force x arm
      t(5, :) = t(5, :) + mA(ax).';
      if strcmp(res(r).type, 'Column')
        t(1, :) = t(1, :) + (mT(ax) + mB(ax)).';
        continue
      end
      Mb = max(Mb, abs(res(r).loc(6)));
      b = str2double(res(r).frame);
      d = 1 + any(b == map.weak);                         % direction it is mapped to
      t(2, d)   = t(2, d)   + mT(ax(d)) + mB(ax(d));     % as the libraries sum it
      t(3, 3-d) = t(3, 3-d) + mT(ax(3-d));
      t(4, 3-d) = t(4, 3-d) + mB(ax(3-d));
    end
    resid = t(1, :) + t(2, :);
    R(end+1) = struct('name', names{n}, 'col', t(1,:), 'mapped', t(2,:), ...
                      'torsion', t(3,:), 'skew', t(4,:), 'arm', t(5,:), ...
                      'residual', resid, 'closure', resid + sum(t(3:5, :), 1), ...
                      'ratio', max(abs(resid)) / max(Mb, 1));
  end
end
