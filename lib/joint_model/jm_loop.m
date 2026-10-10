function Q = jm_loop(x0, x1, z0, z1, y)
% JM_LOOP  closed rectangular tie at height y (centreline x0..x1, z0..z1), as a
% polyline for jm_bar; it starts mid-side so jm_bar rounds all four corners.
  xm = (x0 + x1)/2;
  Q = [xm y z0; x1 y z0; x1 y z1; x0 y z1; x0 y z0; xm y z0];
end
