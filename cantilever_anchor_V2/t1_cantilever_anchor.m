% T1_CANTILEVER_ANCHOR  Main script: checks the anchorage and writes the report.
%   Revision 3 (variant): run from inside cantilever_anchor_V2, so that its ca_*.m are used.
%   octave-cli t1_cantilever_anchor.m
P = ca_inputs();
R = ca_calc(P);

fprintf('\nDemands at the column face\n');
for k = 1:numel(R.kase)
    K = R.kase(k);
    fprintf('  %-20s Vu = %5.1f kN   Mu = %5.1f kN m   T = %5.1f kN   (%s)\n', ...
        K.name, K.Vu/1e3, K.Mu/1e6, K.T/1e3, R.combo{K.jg});
end
fprintf('\n%-9s %-50s %-22s %9s %9s %9s %9s  %5s %5s %5s\n', 'Group', 'Limit state', 'Reference', ...
    'edge', 'corner', 'corn.env', 'capacity', 'D/C', 'D/C', 'D/C');
for i = 1:size(R.rows,1)
    r = R.rows(i,:);  d = r{4};  c = r{5};
    if numel(d) == 1, d = d*[1 1 1]; end
    if numel(c) == 1, c = c*[1 1 1]; end
    fprintf('%-9s %-50s %-22s %9.1f %9.1f %9.1f %9.1f  %5.2f %5.2f %5.2f  %s %s\n', r{1}, r{2}, r{3}, d, c(1), d./c, r{6}, r{7});
end

F = ca_draw(P, R);
ca_report(P, R, F, fullfile('reports', 'cantilever_anchor_report.html'));
fprintf('\nReport written to reports/cantilever_anchor_report.html\n');
