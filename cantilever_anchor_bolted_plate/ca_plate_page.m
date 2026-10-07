function ca_plate_page(P, R, fname)
% CA_PLATE_PAGE  Review page for the end plate: each check next to a dimensioned diagram.
%   Numbers from P and R only; figures reports/figures/pc_*.png from ca_draw.
fid = fopen(fname, 'w');
w = @(varargin) fprintf(fid, [varargin{1} '\n'], varargin{2:end});
Y = R.typ(1);  D = Y.dg;  S = R.strip(1);  bm = P.bm;  an = P.an;
st = P.ep.grade;  Fy = P.st.Fy(st);  Fu = P.st.Fu(st);  tp = P.ep.t;  td = P.dbl.t;
mn = 0.9*Fy*tp^2/4;  mn2 = 0.9*P.st.Fy(P.dbl.grade)*td^2/4;
kN = 1e-3;
w('<!doctype html><html><head><meta charset="utf-8"><title>End plate check</title>');
w(['<style>body{background:#fff;font-family:Helvetica,Arial,sans-serif;max-width:1250px;margin:24px auto;padding:0 16px;color:#111;line-height:1.45}' ...
   'h1{font-size:23px}h2{font-size:18px;margin-top:30px;border-bottom:1px solid #ccc}' ...
   '.row{display:grid;grid-template-columns:minmax(0,1.1fr) minmax(0,1fr);gap:18px;align-items:start;margin:12px 0}' ...
   '@media (max-width:900px){.row{grid-template-columns:1fr}}' ...
   '.row img{width:100%%;border:1px solid #ddd}.calc{font-size:14px}.calc ol{padding-left:20px;margin:0}.calc li{margin:5px 0}' ...
   '.res{font-weight:bold}.ok{color:#1e6b32}.note{font-size:13px;color:#444}' ...
   '.tw{overflow-x:auto}table{border-collapse:collapse;font-size:13px;margin:10px 0}td,th{border:1px solid #ccc;padding:3px 6px;text-align:right}th:first-child,td:first-child{text-align:left}</style></head><body>']);
w('<h1>End plate check: PL %gx%gx%g %s + extra plate PL %g %s, rib PL %g</h1>', tp, P.ep.w, Y.H, P.st.name{st}, td, P.st.name{P.dbl.grade}, P.rib.t);
w('<p>2026-10-02, review page. Type E (edge) is written out step by step; the table at the end gives the same steps for the four types. Every length in the steps is drawn with a dimension line in the diagram next to it. Units: mm, kN, MPa; plate moments in kN m per m of width (= N mm/mm &divide; 1000).</p>');
w('<p><b>Method.</b> Strips, a lower bound: each strip is a cantilever carrying a share of an anchor force to a <i>welded</i> support, and its width counts only where it lands on that support. If every strip stays below &phi;m<sub>p</sub>, the plate is safe whatever the real distribution. Yield lines are not used.</p>');

% ---- 1. forces
w('<h2>1. Forces on the plate</h2><div class="row"><div><img src="figures/pc_forces.png" alt="forces"></div><div class="calc"><ol>');
w('<li>Design moment at the column face, from your ETABS cases: M<sub>u</sub> = (1.2 + E<sub>v</sub>) M<sub>D</sub> + M<sub>L</sub> = (1.2 + %.3f)(%.2f) + %.2f = <b>%.2f kN m</b>.</li>', R.Ev, P.etabs.MD, P.etabs.ML, Y.Mu/1e6);
w('<li>Bearing stress, AISC DG1 3.1.1 with &radic;(A<sub>2</sub>/A<sub>1</sub>) = 1: f<sub>p</sub> = 0.65 &times; 0.85 &times; f''<sub>c</sub> = 0.65 &times; 0.85 &times; %.2f = <b>%.2f MPa</b>; per mm of height q = f<sub>p</sub> B = %.2f &times; %g = %.0f N/mm.</li>', P.fc, D.fp, D.fp, P.ep.w, D.fp*P.ep.w);
w('<li>Anchors to the bottom edge: f + N/2 = pf + d + %g = %g + %g + %g = <b>%g mm</b>.</li>', P.ep.under, Y.zT, bm.h, P.ep.under, D.ft);
w('<li>Bearing length (DG1 Eq. 3.4.3, P = 0): Y = (f + N/2) &minus; &radic;[(f + N/2)&sup2; &minus; 2 M<sub>u</sub>/q] = %g &minus; &radic;[%g&sup2; &minus; 2 &times; %.2f&times;10<sup>6</sup>/%.0f] = <b>%.1f mm</b>.</li>', D.ft, D.ft, Y.Mu/1e6, D.fp*P.ep.w, D.Y);
w('<li>Pull on the two top anchors: T = q Y = %.0f &times; %.1f = <b>%.1f kN</b>; per anchor T<sub>a</sub> = <b>%.1f kN</b>. Lever arm = %g &minus; Y/2 = %.1f mm.</li>', D.fp*P.ep.w, D.Y, D.T*kN, Y.Ta*kN, D.ft, D.lev);
w('<li>Plate capacity per unit width: &phi;m<sub>p</sub> = 0.9 F<sub>y</sub> t&sup2;/4 = 0.9 &times; %g &times; %g&sup2;/4 = <b>%.2f kN m/m</b> (end plate and extra plate alike).</li>', Fy, tp, mn*kN);
w('</ol><p class="note">The bearing block at full f<sub>p</sub> at the bottom edge assumes a stiff plate. Check 4 shows the plate can deliver it.</p></div></div>');

% ---- 2. tension side
w('<h2>2. Tension side: the plate around each top anchor</h2>');
w('<div class="row"><div><img src="figures/pc_geo.png" alt="supports"></div><div class="calc">');
w('<p>The end plate is held in two places only, both on the beam side: the fillet of the top flange (support 1) and the fillet of the rib (support 2). A strip can only end on one of them. Lengths are measured to the <b>toe</b> of each fillet:</p><ul>');
w('<li>support 1 at z = w = %g, over |v| &le; b<sub>f</sub>/2 + w = %g;</li>', P.w.flange, bm.b/2 + P.w.flange);
w('<li>support 2 at |v| = t<sub>rib</sub>/2 + w<sub>rib</sub> = %g + %g = %g, from z = %g to the plate top %g.</li></ul>', P.rib.t/2, P.rib.w, P.rib.t/2 + P.rib.w, P.w.flange, Y.ep_top);
w('<p>Anchor: v<sub>T</sub> = %g, pf = %g.</p></div></div>', an.vT, Y.zT);
w('<div class="row"><div><img src="figures/pc_ten1.png" alt="end plate strips"></div><div class="calc"><p><b>End plate (plate 1)</b></p><ol>');
w('<li>Strip 1, to the flange: span x<sub>1</sub> = pf &minus; w = %g &minus; %g = <b>%g</b>; width 2x<sub>1</sub> = %g centred on the anchor (v = %g to %g), all on support 1 (%g to %g): b<sub>1</sub> = <b>%g</b>.</li>', Y.zT, P.w.flange, S.x1, 2*S.x1, an.vT - S.x1, an.vT + S.x1, P.rib.t/2 + P.rib.w, bm.b/2 + P.w.flange, S.w1);
w('<li>Strip 2, to the rib: span x<sub>2</sub> = v<sub>T</sub> &minus; %g = %g &minus; %g = <b>%g</b>; width 2x<sub>2</sub> = %g (z = %g to %g), cut to the rib between z = %g and %g: b<sub>2</sub> = <b>%g</b>.</li>', P.rib.t/2 + P.rib.w, an.vT, P.rib.t/2 + P.rib.w, S.x2, 2*S.x2, Y.zT - S.x2, Y.zT + S.x2, P.w.flange, Y.ep_top, S.w2);
w('<li>A force F in a strip gives at its support m = F x/b per unit width: strip 1, x<sub>1</sub>/b<sub>1</sub> = %.4f; strip 2, x<sub>2</sub>/b<sub>2</sub> = %.4f (per kN, in kN m/m).</li>', S.x1/S.w1, S.x2/S.w2);
w('<li>Share &alpha; to strip 1 so both strips have the same moment: &alpha; = (x<sub>2</sub>/b<sub>2</sub>)/(x<sub>1</sub>/b<sub>1</sub> + x<sub>2</sub>/b<sub>2</sub>) = <b>%.3f</b>; then m = %.4f per kN carried by plate 1.</li>', S.al, S.c1);
w('</ol></div></div>');
w('<div class="row"><div><img src="figures/pc_ten2.png" alt="extra plate strips"></div><div class="calc"><p><b>Extra plate (plate 2)</b>, %g mm, two pieces with a %g mm gap over the rib, fillets %g on the bottom and inner edges only (the outer and top edges are flush with the end plate)</p><ol>', td, P.dbl.gap, P.dbl.w);
w('<li>It gets its share by contact: the nut pushes plate 1 onto it around the anchor (compression, so no weld is needed there).</li>');
w('<li>Its supports are its own edge welds, which sit right over support 1 (bottom edge, z = 0) and support 2 (inner edge, over the rib).</li>');
w('<li>Strip A, to the bottom edge: y<sub>1</sub> = pf &minus; 0 = <b>%g</b>; width 2y<sub>1</sub> = %g (v = %g to %g), cut to the piece (%g to %g): <b>%g</b>.</li>', S.y1, 2*S.y1, an.vT - S.y1, an.vT + S.y1, P.dbl.gap/2, P.ep.w/2, S.u1);
w('<li>Strip B, to the inner edge: y<sub>2</sub> = v<sub>T</sub> &minus; gap/2 = %g &minus; %g = <b>%g</b>; width 2y<sub>2</sub> = %g (z = %g to %g), cut to the piece (0 to %g): <b>%g</b>.</li>', an.vT, P.dbl.gap/2, S.y2, 2*S.y2, Y.zT - S.y2, Y.zT + S.y2, Y.ep_top, S.u2);
w('<li>Same split: m = %.4f per kN carried by plate 2.</li>', S.c2);
w('</ol></div></div>');
m1 = S.be*S.c1*Y.Ta;
w('<div class="calc" style="border:1px solid #bbb;padding:8px 14px"><p><b>Result, type E</b></p><ol>');
w('<li>Share between the plates so that both reach the same ratio: plate 1 takes &beta; = <b>%.2f</b> of T<sub>a</sub>, plate 2 the rest (%.1f kN).</li>', S.be, (1 - S.be)*Y.Ta*kN);
w('<li>Moment in each plate: m = &beta; &times; %.4f &times; T<sub>a</sub> = %.2f &times; %.4f &times; %.1f = <b>%.2f kN m/m</b>.</li>', S.c1, S.be, S.c1, Y.Ta*kN, m1*kN);
w('<li class="res ok">D/C = %.2f / %.2f = %.2f</li>', m1*kN, mn*kN, m1/mn);
w('<li class="res ok">Extra strict, plate stays elastic (DG16 thick-plate idea applied to the strips): 1.11 m / &phi;m<sub>p</sub> = %.2f</li>', 1.11*m1/mn);
w('<li>Where strip 1 and strip 2 cross (near the corner of the two supports) both moments are equal and of the same sign; that is within the yield criterion of the plate (square or von Mises).</li>');
w('<li>Without the extra plate (&beta; = 1): %.2f &times; %.1f = %.2f kN m/m, D/C %.2f; it is needed.</li>', S.c1, Y.Ta*kN, S.c1*Y.Ta*kN, S.c1*Y.Ta/mn);
w('</ol></div>');

% ---- 3. prying
bpr = Y.zT - an.db/2;  pp = (bm.b + 25)/2;  tmin = sqrt(4*Y.Ta*bpr/(0.9*pp*Fu));  teff = sqrt(tp^2 + td^2);
w('<h2>3. Prying</h2><div class="row"><div><img src="figures/pc_pry.png" alt="prying"></div><div class="calc"><ol>');
w('<li>AISC Manual Part 9: b'' = b &minus; d<sub>b</sub>/2 = %g &minus; %g = %g; p = %.1f.</li>', Y.zT, an.db/2, bpr, pp);
w('<li>Thickness with no prying: t<sub>min</sub> = &radic;[4 T<sub>a</sub> b''/(&phi; p F<sub>u</sub>)] = &radic;[4 &times; %.0f &times; %g/(0.9 &times; %.1f &times; %g)] = <b>%.1f mm</b>.</li>', Y.Ta, bpr, pp, Fu, tmin);
w('<li>Two plates, not composite: t<sub>eff</sub> = &radic;(%g&sup2; + %g&sup2;) = %.1f mm (same plastic capacity).</li>', tp, td, teff);
w('<li class="res ok">D/C = %.1f / %.1f = %.2f. The strict check of step 2 gives %.2f.</li>', tmin, teff, tmin/teff, 1.11*m1/mn);
w('</ol></div></div>');

% ---- 4. bearing side
w('<h2>4. Bearing side, below the bottom flange</h2><div class="row"><div><img src="figures/pc_brg.png" alt="bearing"></div><div class="calc"><ol>');
w('<li>Strip below the flange (DG1 3.1.2): m = %g + 0.025 d = %g + %g = <b>%g</b> (from the plate bottom to the 0.95 d line).</li>', P.ep.under, P.ep.under, 0.025*bm.h, D.m);
w('<li>Strips beyond the flange tips: n = (B &minus; 0.8 b<sub>f</sub>)/2 = (%g &minus; %g)/2 = <b>%g</b>.</li>', P.ep.w, 0.8*bm.b, D.n);
w('<li>Y = %.1f &ge; m and &ge; n: the whole strip is loaded at f<sub>p</sub> (DG1 Eq. 3.3.14 form): M = f<sub>p</sub> &times; length&sup2;/2.</li>', D.Y);
w('<li>m strip: %.2f &times; %g&sup2;/2 = %.2f kN m/m; <span class="res ok">D/C %.2f</span>.</li>', D.fp, D.m, D.Mb*kN, D.Mb/mn);
w('<li>n strips: %.2f &times; %g&sup2;/2 = %.2f kN m/m; <span class="res ok">D/C %.2f</span> (governs).</li>', D.fp, D.n, D.Mbn*kN, D.Mbn/mn);
Ds = R.dgs(1);
w('<li>Strict: DG1 itself would use the full allowed pressure on this face, f<sub>p</sub> = 0.65 &times; 0.85 f''<sub>c</sub> &radic;(A<sub>2</sub>/A<sub>1</sub>) = %.2f MPa (&radic;(A<sub>2</sub>/A<sub>1</sub>) = %.2f). Then Y = %.1f and the strips: m %.2f kN m/m, n %.2f kN m/m; <span class="ok">D/C %.2f / %.2f</span>.</li>', Ds.fp, Ds.fp/D.fp, Ds.Y, Ds.Mb*kN, Ds.Mbn*kN, Ds.Mb/mn, Ds.Mbn/mn);
w('<li>Only plate 1 here: the extra plate is at the top.</li>');
w('</ol></div></div>');

% ---- 5. welds that carry the strips
rr = R.rows;  f = @(s) find(strncmp(rr(:,2), s, numel(s)), 1);
w('<h2>5. Welds that act as supports</h2><div class="tw"><table><tr><th>Weld</th><th>E</th><th>C1</th><th>CX</th><th>CY</th><th>Type E</th></tr>');
for s = {'Rib-to-end-plate', 'Rib-to-flange', 'Extra plate: edge welds', 'Fillet, tension flange'}
    i = f(s{1});
    w('<tr><td>%s</td><td>%.2f</td><td>%.2f</td><td>%.2f</td><td>%.2f</td><td style="text-align:left">%s</td></tr>', regexprep(rr{i,2}, '^Shop f', 'F'), rr{i,4}./rr{i,5}, rr{i,7});
end
w('</table></div><p class="note">All welds are taken as site welds; the strength is the same (AISC J2.4, E70, no directional factor).</p>');

% ---- 6. all types
w('<h2>6. The four types</h2><div class="tw"><table><tr><th></th>');
for j = 1:4, w('<th>%s</th>', R.typ(j).name); end
w('</tr>');
T = R.typ;  SS = R.strip;
lines = {'M<sub>u</sub> (kN m)', arrayfun(@(y) y.Mu/1e6, T), '%.2f';
         'pf = anchor over the flange', [T.zT], '%g';
         'plate top over the flange', [T.ep_top], '%g';
         'Y (mm)', arrayfun(@(y) y.dg.Y, T), '%.1f';
         'T<sub>a</sub> (kN)', [T.Ta]*kN, '%.1f';
         'x<sub>1</sub> / b<sub>1</sub>', [], '';
         'x<sub>2</sub> / b<sub>2</sub>', [], '';
         'y<sub>1</sub> / b (extra plate)', [], '';
         'y<sub>2</sub> / b (extra plate)', [], '';
         '&beta; (share of plate 1)', [SS.be], '%.2f';
         'm (kN m/m)', [SS.be].*[SS.c1].*[T.Ta]*kN, '%.2f';
         'D/C tension side', [SS.be].*[SS.c1].*[T.Ta]/mn, '%.2f';
         'D/C strict (1.11 m)', 1.11*[SS.be].*[SS.c1].*[T.Ta]/mn, '%.2f';
         'D/C bearing, m strip', arrayfun(@(y) y.dg.Mb, T)/mn, '%.2f';
         'D/C bearing, n strips', arrayfun(@(y) y.dg.Mbn, T)/mn, '%.2f';
         'D/C bearing, strict (f<sub>p,max</sub>)', max([R.dgs.Mb], [R.dgs.Mbn])/mn, '%.2f'};
pairs = {[SS.x1; SS.w1], [SS.x2; SS.w2], [SS.y1; SS.u1], [SS.y2; SS.u2]};
for k = 1:size(lines,1)
    w('<tr><td>%s</td>', lines{k,1});
    if isempty(lines{k,2})
        pr = pairs{k-5};
        for j = 1:4, w('<td>%g / %g</td>', pr(1,j), pr(2,j)); end
    else
        for j = 1:4, w(['<td>' lines{k,3} '</td>'], lines{k,2}(j)); end
    end
    w('</tr>');
end
w('</table></div><p class="note">CY: its anchors sit at %g, so x<sub>1</sub> = %g and strip 1 would be %g wide; it is cut to the flange and the rib (%g to %g): b<sub>1</sub> = %g. Its extra plate pieces are %gx%g.</p>', ...
  T(4).zT, SS(4).x1, 2*SS(4).x1, P.rib.t/2 + P.rib.w, bm.b/2 + P.w.flange, SS(4).w1, P.ep.w/2 - P.dbl.gap/2, T(4).ep_top);
w('</body></html>');
fclose(fid);
end
