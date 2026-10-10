function r = top_band_bearing(p, depth)
% TOP_BAND_BEARING  Bearing area of a flush end plate in a band from its top
% edge down to `depth`, counted with the same strict strips as bearing_strips
% (sandwich_concrete): top flange band min(bp, bf + 2c), strip below the flange
% min(bp, max(bf, tw + 2c)) over c, then the web zone min(bp, tw + 2c); holes
% deducted. Own model (see EQUATIONS.txt, module 6).
%   p: bp, bf, tf, tw, tp, Fyp, phi_b, fp, holes_y (from the top edge), holes_x, dh
%   r.c, r.A (mm2), r.C = fp A (N), r.ybar (centroid from the top edge)
  c  = p.tp * sqrt(p.phi_b * p.Fyp / (2 * p.fp));
  dy = 0.01;
  y  = (dy/2 : dy : depth)';
  w  = zeros(size(y));
  k = y <= p.tf;                         w(k) = min(p.bp, p.bf + 2*c);
  k = y > p.tf & y <= p.tf + c;          w(k) = min(p.bp, max(p.bf, p.tw + 2*c));
  k = y > p.tf + c;                      w(k) = min(p.bp, p.tw + 2*c);
  rh = p.dh/2;
  for i = 1:numel(p.holes_y)
    for j = 1:numel(p.holes_x)
      dyh = y - p.holes_y(i);  k = abs(dyh) < rh;
      half = sqrt(rh^2 - dyh(k).^2);
      lo = max(p.holes_x(j) - half, -w(k)/2);  hi = min(p.holes_x(j) + half, w(k)/2);
      w(k) = w(k) - max(0, hi - lo);
    end
  end
  r.c = c;  r.A = sum(w)*dy;  r.C = p.fp*r.A;  r.ybar = sum(w.*y)*dy/max(r.A, eps);
end
