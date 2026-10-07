function [k, A1, A2] = conf_factor(w, H, d_bot, d_top, depth)
% CONF_FACTOR  sqrt(A2/A1) <= 2 for a w x H loaded area on the side face of
% the concrete beam (ACI 318-19 22.8.3.2). The frustum (1 vertical : 2
% horizontal) spreads x on every side, limited by the distance to the bottom
% face, to the top face, and by the beam width (a spread x needs a depth x/2;
% both faces are loaded at the same place, so each frustum may use half the
% width: x/2 <= depth/2). Along the beam the concrete is continuous.
x  = max(0, min([d_bot, d_top, depth]));
A1 = w * H;
A2 = (w + 2*x) * (H + 2*x);
k  = min(2, sqrt(A2 / A1));
end
