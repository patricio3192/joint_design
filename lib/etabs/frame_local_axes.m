function R = frame_local_axes(pI, pJ, angleDeg)
% FRAME_LOCAL_AXES  ETABS/CSI default frame local axes + rotation angle.
%   R = [e1; e2; e3]  (rows = local axes as unit vectors in global X,Y,Z)
%   Global -> local:  v_loc = R * v_glob      Local -> global: v_glob = R' * v_loc
%
%   CSI default rules:
%   - axis 1 from I to J
%   - vertical member: axis 2 = +X global
%   - otherwise: axis 2 in the vertical plane containing axis 1, pointing up
%   - axis 3 = 1 x 2
%   - Angle rotates 2 and 3 about +1 (counter-clockwise when +1 points at you)
%   NOT handled: advanced local axes, mirroring.
  e1 = (pJ(:) - pI(:)).';
  e1 = e1 / norm(e1);
  Z = [0 0 1];
  if norm(cross(e1, Z)) < 1e-3        % vertical (within ~0.06 deg)
    e2 = [1 0 0];
  else
    e2 = Z - dot(Z, e1) * e1;
    e2 = e2 / norm(e2);
  end
  e3 = cross(e1, e2);
  a  = angleDeg * pi / 180;
  e2r =  cos(a) * e2 + sin(a) * e3;
  e3r = -sin(a) * e2 + cos(a) * e3;
  R = [e1; e2r; e3r];
end
