% T0_SCHEME  Scheme of the double plate concept: layout, clearances, first sizing, drawings.
%   octave-cli t0_scheme.m   (from inside cantilever_anchor_double_plate)
P = ca_inputs();
R = ca_layout(P);
F = ca_draw(P, R);
fd = fullfile('reports', 'figures');
if ~exist(fd, 'dir'), mkdir(fd); end
fn = fieldnames(F);
for i = 1:numel(fn)
    f = fullfile(fd, [fn{i} '.svg']);
    fid = fopen(f, 'w');  fprintf(fid, '%s', F.(fn{i}));  fclose(fid);
    system(sprintf('mutool draw -q -r 96 -o %s %s', strrep(f, '.svg', '.png'), f));
end
fprintf('\nClearances (nominal, mm)\n');
for i = 1:size(R.clr,1), fprintf('%7.1f  %-72s %s\n', R.clr{i,2}, R.clr{i,1}, R.clr{i,3}); end
fprintf('\nFirst sizing\n');
for i = 1:size(R.pre,1)
    fprintf('%-26s %-62s %9.1f %9.1f  %5.2f\n', R.pre{i,1}, R.pre{i,2}, R.pre{i,3}/1e3, R.pre{i,4}/1e3, R.pre{i,3}/R.pre{i,4});
end
ca_scheme_report(P, R, fullfile('reports', 'scheme.html'));
fprintf('\nScheme written to reports/scheme.html\n');
