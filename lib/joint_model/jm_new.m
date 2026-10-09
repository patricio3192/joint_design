function M = jm_new()
% JM_NEW  empty 3D joint model: M.pc is the list of pieces (jm_bar, jm_box).
% Coordinates and units are the caller's (mm); see lib/joint_model/README.md.
  M.pc = struct('name', {}, 'type', {}, 'pts', {}, 'd', {}, 'mark', {}, 'grp', {}, 'kind', {}, ...
                'style', {}, 'phase', {}, 'new', {}, 'qty', {}, 'touch', {}, 'desc', {}, 'kgm', {});
end
