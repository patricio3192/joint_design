% T5_BORDER_BEAM  Border beam at the slab edge, between the cantilever tips: catalog search,
%   strength, deflection, vibration, effect on the anchorage. Writes reports/border_beam.html.
%   octave-cli t5_border_beam.m   (from inside cantilever_anchor_bolted_plate)
P = ca_inputs();
R = ca_calc(P);
B = bb_calc(P, R);
C = ca_capacity(P);
rec = 'IPE 160';                    % proposal (2026-10-03), waiting for the user's review
bb_page(P, R, B, C, fullfile('reports', 'border_beam.html'), rec);
fprintf('Lightest IPE %s, lightest tube %s; proposal %s\n', B.best.IPE.name, B.best.tube.name, rec);
fprintf('Report written to reports/border_beam.html\n');
