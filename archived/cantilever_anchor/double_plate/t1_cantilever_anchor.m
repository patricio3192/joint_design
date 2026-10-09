% T1_CANTILEVER_ANCHOR  Double plate anchorage: layout, limit states, drawings, scheme page and report.
%   octave-cli t1_cantilever_anchor.m   (from inside cantilever_anchor_double_plate)
t0_scheme;                       % layout, clearances, drawings, reports/scheme.html
R = ca_calc(P, R);
ca_report(P, R, fullfile('reports', 'cantilever_anchor_report.html'));
fprintf('\nReport written to reports/cantilever_anchor_report.html\n');
