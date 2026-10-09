% T1_BOLTED_PLATE  Bolted plate anchorage: loads, layout, limit states, drawings and report.
%   octave-cli t1_bolted_plate.m   (from inside cantilever_anchor_bolted_plate)
P = ca_inputs();
R = ca_calc(P);
F = ca_draw(P, R);
fd = fullfile('reports', 'figures');
if ~exist(fd, 'dir'), mkdir(fd); end
fn = fieldnames(F);
for i = 1:numel(fn)
    f = fullfile(fd, [fn{i} '.svg']);
    fid = fopen(f, 'w');  fprintf(fid, '%s', F.(fn{i}));  fclose(fid);
    rr = 96;  if any(strcmp(fn{i}, {'ta_brk', 'ta_z0'})), rr = 192; end    % figure G: shown full width, sharper
    system(sprintf('mutool draw -q -r %d -o %s %s 2>/dev/null', rr, strrep(f, '.svg', '.png'), f));
end
ca_plate_page(P, R, fullfile('reports', 'plate_check.html'));
ca_anchor_page(P, R, fullfile('reports', 'anchorage_check.html'));
ca_options(P, R, fullfile('reports', 'back_plate_options.html'));   % ACI 17.1.5: the single back plate, two options
fprintf('\nLimit states (D/C per type E, C1, CX, CY)\n');
for i = 1:size(R.rows,1)
    r = R.rows(i,:);
    fprintf('%-10s %-80s %5.2f %5.2f %5.2f %5.2f %s\n', r{1}, r{2}(1:min(80,end)), r{4}./r{5}, r{8});
end
fprintf('\nClearances (nominal, mm)\n');
for i = 1:size(R.clr,1), fprintf('%7.1f  %-72s %s\n', R.clr{i,2}, R.clr{i,1}, R.clr{i,3}); end
C = ca_capacity(P);
fprintf('\nLargest Mu at the column face (kN m), all forces scaled together\n');
for j = 1:4, fprintf('%-3s %6.1f  (x %.2f of the design moment)  limited by: %s\n', R.typ(j).name, C.Mu(j), C.Mu(j)/(R.typ(j).Mu/1e6), C.gov{j}); end
ca_report(P, R, C, fullfile('reports', 'bolted_plate_report.html'));
fprintf('\nReport written to reports/bolted_plate_report.html\n');
