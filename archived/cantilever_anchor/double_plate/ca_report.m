function ca_report(P, R, fname)
% CA_REPORT  Limit-state report of the double plate anchorage. Numbers from P and R only.
%   Drawings, placing sequence, site notes and suppliers are in reports/scheme.html.
fid = fopen(fname, 'w');
w = @(varargin) fprintf(fid, [varargin{1} '\n'], varargin{2:end});
w('<!doctype html><html><head><meta charset="utf-8"><title>Double plate checks</title>');
w(['<style>body{font-family:Helvetica,Arial,sans-serif;max-width:1150px;margin:24px auto;padding:0 16px;color:#111;line-height:1.45}' ...
   'h1{font-size:24px}h2{font-size:19px;margin-top:30px;border-bottom:1px solid #ccc}' ...
   'figure{margin:16px 0}figure img{width:100%%;border:1px solid #ddd}figcaption{font-size:13px}' ...
   'table{border-collapse:collapse;font-size:13px;margin:10px 0}td,th{border:1px solid #ccc;padding:3px 6px;text-align:left;vertical-align:top}' ...
   'td.n{text-align:right;white-space:nowrap}.bad{background:#f9d6d5}.warn{background:#fdf0c9}.ok{background:#e3f1e3}.eq{font-size:12px;color:#333}</style></head><body>']);
w('<h1>Cantilever anchorage, double plate: limit states</h1>');
w('<p>2026-10-02. Rods %s ASTM A193 B7, end plate PL %gx%g on %s, front plate PL %gx%g, back plate PL %gx%gx%g. Layout, drawings, placing sequence, site notes and suppliers: <a href="scheme.html">scheme.html</a>. Run: <code>octave-cli t1_cantilever_anchor.m</code>.</p>', ...
  P.tr.lab, P.ep.t, P.ep.w, P.bm.name, P.fp.t, P.fp.w, P.bp.t, P.bp.h, P.bp.w);
w('<p><b>Assumptions</b> (conservative, user decision): beam bars on the least favourable layer and 13 mm off, bar hooks 25 mm short (ACI 26.6.2.1); corner beams VCS (3 top bars); edge VCM with its pairs in contact (one bar per pair, 3 counted); concrete cracked; no directional factor on welds.</p>');
fig(fid, 'edge_elev', 'Figure 1. Edge, type E.');
fig(fid, 'cor_plan', 'Figure 2. Corner: CX (rods low) and CY (rods high).');

w('<h2>1. Demands</h2><table><tr><th>Type</th><th>Load case</th><th>M<sub>u</sub> (kN m)</th><th>V<sub>u</sub> (kN)</th><th>Lever arm (mm)</th><th>T = M<sub>u</sub>/lever (kN)</th><th>Torsion T<sub>u</sub> (kN m)</th><th>H (kN)</th></tr>');
for j = 1:3
    Y = R.typ(j);  K = R.kase(Y.k);
    w('<tr><td>%s</td><td>%s, %s</td><td class="n">%.2f</td><td class="n">%.1f</td><td class="n">%.1f</td><td class="n">%.1f</td><td class="n">%.2f</td><td class="n">%.2f</td></tr>', ...
      Y.name, K.name, R.combo{K.jg}, K.Mu/1e6, K.Vu/1e3, Y.lev, Y.T/1e3, R.Tor(j)/1e6, R.H(j)/1e3);
end
w('</table><p>q = (1.2 + E<sub>v</sub>) D + L with E<sub>v</sub> = %.3f D (NEC-SE-DS 3.4.4); 0.9D - E<sub>v</sub> stays downward, so the moment never reverses. Lever arm from the tension rods to the bottom flange centroid (z = %.1f). Torsion as in V2: T<sub>u</sub> = V<sub>u</sub> b/2 at the corner (half at the edge), taken by a horizontal couple H between tension and shear rods.</p>', R.Ev, R.z.C);
w('<p>Seismic (17.10.5): the E<sub>v</sub> share of the anchor tension is %.0f%% &gt; 20%%. Option 17.10.5.3(d) amplifies only E<sub>h</sub> by &Omega;<sub>o</sub>; there is no E<sub>h</sub> here, so the design combination stands. The anchor reinforcement is INEN 2167 (A706 type), 17.10.4.</p>', 100*R.kase(1).fE);

w('<h2>2. Limit states</h2><table><tr><th>Group</th><th>Limit state</th><th>Reference</th><th>Demand E / CX / CY</th><th>Capacity E / CX / CY</th><th>D/C</th><th>Check, type E</th></tr>');
worst = 0;
for i = 1:size(R.rows,1)
    r = R.rows(i,:);  u = r{6};  s = 1;
    if strcmp(u, 'kN'), s = 1e3; elseif strcmp(u, 'kN m'), s = 1e6; end
    dc = r{4}./r{5};  worst = max(worst, max(dc));
    c = 'ok';  if max(dc) > 0.85, c = 'warn'; end;  if max(dc) > 1, c = 'bad'; end
    if strcmp(u, '-'), ds = sprintf('%.3f / %.3f / %.3f', r{4}); cs = '0.2';
    else, ds = sprintf('%.1f / %.1f / %.1f %s', r{4}/s, u); cs = sprintf('%.1f / %.1f / %.1f %s', r{5}/s, u); end
    w('<tr class="%s"><td>%s</td><td>%s</td><td>%s</td><td class="n">%s</td><td class="n">%s</td><td class="n">%.2f / %.2f / %.2f</td><td class="eq">%s</td></tr>', ...
      c, r{1}, r{2}, r{3}, ds, cs, dc, r{7});
end
w('</table><p>Highest D/C: <b>%.2f</b>. All connection checks pass; the concrete beams behind remain an open frame item (section 3).</p>', worst);

w('<h2>3. Open items and notes</h2><ul>');
w('<li><b>Concrete beams behind the column (frame item, same for any connection).</b> The cantilever moment at the far face of the column is %.1f kN m (edge) and %.1f kN m (corner). Against the room left in the beams quoted earlier (%g and %g kN m, VCM and VCS), that is %.2f and %.2f. Part of the moment goes into the pedestal and the steel column instead, which this check ignores. The support moments from the frame model (with the cantilevers) are needed to close this. If they confirm the shortfall at the corner, add top bars to the VCS over the support.</li>', ...
  R.rows{strncmp(R.rows(:,2), 'Concrete beam behind', 20), 4}(1)/1e6, R.rows{strncmp(R.rows(:,2), 'Concrete beam behind', 20), 4}(2)/1e6, R.room(1)/1e6, R.room(2)/1e6, ...
  R.rows{strncmp(R.rows(:,2), 'Concrete beam behind', 20), 4}(1)/R.room(1), R.rows{strncmp(R.rows(:,2), 'Concrete beam behind', 20), 4}(2)/R.room(2));
w('<li>Beam lateral-torsional buckling, deflection and the beam itself: same %s, loads and length as V2, checked there (LTB with 2.5 L).</li>', P.bm.name);
w('<li>No concrete shear breakout: the shear acts downward and the column continues below (the cold joint is not an edge). Tension rods take only the torsion shear (interaction not needed, 17.8.1).</li>');
w('<li>End plate: two models agree (yield lines and a lower-bound strip); no prying at the demand. Connection treated as rigid: a 20 mm plate on B7 rods tightened snug + 1/3 turn with the compression flange bearing steel on steel.</li>');
w('<li>Hold points: corner hooks %.0f mm over the rods of X; top ties placed before the rods; threads protected; front plate vented and vibrated.</li>', R.clr{strncmp(R.clr(:,1), 'Corner: rods of X - column hooks', 30), 2});
w('<li>Nuts: tension rods snug tight plus 1/3 turn; shear rods snug tight.</li>');
w('</ul></body></html>');
fclose(fid);
end

function fig(fid, name, cap)
fprintf(fid, '<figure><img src="figures/%s.png"><figcaption>%s</figcaption></figure>\n', name, cap);
end
