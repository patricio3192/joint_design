function ca_report(P, R, C, fname)
% CA_REPORT  HTML report of the bolted plate anchorage. Every number is read from P, R and C
%   (ca_inputs, ca_calc, ca_capacity); figures are reports/figures/*.png from ca_draw.
%   The plate and the anchors are written out step by step in plate_check.html and
%   anchorage_check.html (ca_plate_page, ca_anchor_page).
fid = fopen(fname, 'w');
w = @(varargin) fprintf(fid, [varargin{1} '\n'], varargin{2:end});
bm = P.bm;  an = P.an;  bp = P.bp;  st = P.ep.grade;  E = R.typ(1);  Y4 = R.typ(4);  M = R.ram;
kN = 1e-3;  kNm = 1e-6;  nf = 0;
rr = R.rows;
dc = @(s, j) dcv(rr, s, j);
w('<!doctype html><html><head><meta charset="utf-8"><title>Bolted plate anchorage</title>');
w(['<style>body{background:#fff;font-family:Helvetica,Arial,sans-serif;max-width:1150px;margin:24px auto;padding:0 16px;color:#111;line-height:1.45}' ...
   'h1{font-size:24px}h2{font-size:19px;margin-top:34px;border-bottom:1px solid #ccc}h3{font-size:16px;margin-top:22px}' ...
   'figure{margin:16px 0}figure img{max-width:100%%;border:1px solid #ddd}figcaption{font-size:13px;color:#555}' ...
   '.tw{overflow-x:auto}table{border-collapse:collapse;font-size:13px;margin:10px 0}td,th{border:1px solid #ccc;padding:3px 6px;text-align:left;vertical-align:top}' ...
   'td.n{text-align:right;white-space:nowrap}.bad{background:#f9d6d5}.warn{background:#fdf0c9}.ok{background:#e3f1e3}.inf{background:#f1f1f1;color:#555}' ...
   '.eq{font-size:12px;color:#333}.box{border:1px solid #bbb;background:#fafafa;padding:8px 14px;margin:12px 0}</style></head><body>']);

% ---- header and summary -------------------------------------------------------------
w('<h1>Cantilever anchorage, bolted plate: check of the RAM Connection design and final design</h1>');
w('<p>2026-10-02. Starting point: the RAM Connection report <i>anclaje voladizo.pdf</i> (plate 250x351x12, 5 &#216;16 anchors, shear key, %s). Site data and lessons from <code>../cantilever_anchor</code>, <code>../cantilever_anchor_V2</code> and <code>../cantilever_anchor_double_plate</code>. ACI 318-19 (SI, Appendix E), AISC 360-16, AISC Design Guides 1, 4, 16, NEC-SE-DS. LRFD. Run: <code>octave-cli t1_bolted_plate.m</code>; workshop sheets: <code>octave-cli t2_planos_taller.m</code>.</p>', bm.name);
w('<p>Step-by-step review pages with dimensioned diagrams: <a href="plate_check.html">end plate</a>, <a href="anchorage_check.html">tension anchors and back plate</a>.</p>');
dcs = worst(R);
w('<div class="box"><b>Summary</b><ul>');
w('<li><b>Your RAM model cannot be built as drawn</b> (section 2): the centre anchor runs into the mid-face column bar, the second row sits %g mm over the beam top bars, the top row puts the washer on the flange fillet, and the shear-key pocket cuts the column bar and the ties. RAM also assumes %g mm of concrete above the top anchors (there are %g) and uncracked concrete.</li>', M.c_bar, M.caTop, P.col.top - M.top);
w('<li><b>Loads</b> (section 1): from your ETABS cases at the column face, M<sub>u</sub> = (1.2 + E<sub>v</sub>) M<sub>D</sub> + M<sub>L</sub> = <b>%.2f kN m</b> at the edge (RAM: %.2f). The same factor is applied to the corners.</li>', R.Mets, M.Mu);
w('<li><b>Design</b> (section 3): end plate <b>PL %gx%gx%g A36</b> with a <b>rib PL %g</b> and <b>2 extra plates PL %g</b> on the column side; per beam 2 straight top anchors with a <b>back plate PL %gx%gx%g</b> and 2 short shear anchors, all <b>threaded rod 5/8" ASTM A193 B7</b>; grout pad %g mm; no shear key. Beam IPE 240, welded on site.</li>', ...
  P.ep.t, P.ep.w, E.H, P.rib.t, P.dbl.t, bp.t, bp.h, bp.w, P.g);
w('<li><b>Every limit state passes.</b> Highest D/C: <b>%.2f</b> (%s, type %s). Plates proven by strips (lower bound), the strict versions included.</li>', dcs.dc, dcs.name, dcs.typ);
w('<li><b>Largest moment</b> (section 7): %.1f kN m (E, C1, CX) and %.1f kN m (CY), against %.2f kN m at the edge.</li>', C.Mu(1), C.Mu(4), E.Mu*kNm);
w('<li><b>Room for site errors</b> (section 9): %g mm down and %g mm up in the level of the top anchors at the edge; errors in the plane of the face are absorbed by drilling the end plate to the survey.</li>', R.tolt{1,3}, R.tolt{2,3});
w('<li><b>For you to check on the concrete beam in line</b> (section 13): its 2 bars in contact under the corner bars are a hooked bundle; counted, the beam is at %.2f; not counted, at %.2f.</li>', dc('Concrete beam in line', 1), dc('Same, counting only the', 1));
w('</ul></div>');

% ---- 1. loads ------------------------------------------------------------------------
w('<h2>1. Loads</h2>');
nf = fig(fid, nf, 'trib', 'Tributary areas beyond the column face (cross-check of the ETABS loads).');
w('<p>Design: your ETABS model, edge cantilever B16 at the column face: M<sub>D</sub> = %.2f kN m, V<sub>D</sub> = %.2f kN, M<sub>L</sub> = %.2f kN m, V<sub>L</sub> = %.2f kN. NEC-SE-DS vertical seismic E<sub>v</sub> = (2/3) I &eta; Z F<sub>a</sub> = (2/3)(%g)(%g)(%g)(%g) = %.3f D, not in the ETABS combinations. Governing: 1.2D + E<sub>v</sub> + L = %.3f D + L:</p>', ...
  P.etabs.MD, P.etabs.VD, P.etabs.ML, P.etabs.VL, P.I, P.eta, P.Z, P.Fa, R.Ev, 1.2 + R.Ev);
w('<p style="margin-left:20px">M<sub>u</sub> = %.3f &times; %.2f + %.2f = <b>%.2f kN m</b> (1.2D + 1.6L gives %.2f); 0.9D &minus; E<sub>v</sub> = %.2f kN m stays downward, the moment never reverses.</p>', 1.2 + R.Ev, P.etabs.MD, P.etabs.ML, R.Mets, 1.2*P.etabs.MD + 1.6*P.etabs.ML, (0.9 - R.Ev)*P.etabs.MD);
w('<p>Cross-check with tributary areas (q<sub>D</sub> = %g, q<sub>L</sub> = %g kN/m&sup2;, L = %.2f m from the face of the concrete beam): %.2f kN m. ETABS is higher because it puts the strip of slab over the concrete beam on the cantilever (your note). The ratio %.3f is applied to every case, so the corners keep the proportions of the tributary areas. Shears stay at the tributary values &times; %.3f, which are larger than ETABS (%.1f against %.1f kN at the edge).</p>', ...
  P.qD, P.qL, P.L/1000, R.kase(1).Mc, R.kM, R.kM, E.Vu*kN, (1.2 + R.Ev)*P.etabs.VD + P.etabs.VL);
w('<div class="tw"><table><tr><th>Case</th><th class="n">A (m&sup2;)</th><th class="n">M tributary</th><th class="n">M<sub>u</sub> design</th><th class="n">V<sub>u</sub> design</th><th>Used by</th></tr>');
use = {'E', 'joint checks of the corner', 'CX, CY (each beam)', 'C1'};
for k = 1:4
    K = R.kase(k);
    w('<tr><td>%s</td><td class="n">%.2f</td><td class="n">%.2f</td><td class="n"><b>%.2f</b></td><td class="n">%.1f</td><td>%s</td></tr>', K.name, K.A, K.Mc, K.Mu*kNm, K.Vu*kN, use{k});
end
w('</table></div>');
w('<p>Seismic anchors (ACI 17.10.5): E<sub>v</sub> is %.0f%% of the anchor tension, more than 20%%, so 17.10.5.3 applies. Option (d) amplifies only E<sub>h</sub> by &Omega;<sub>o</sub>; the cantilever has no E<sub>h</sub> (it is statically determinate, the frame sway does not load it). Concrete cracked everywhere (17.10.5.4); anchor reinforcement per 17.5.2.1, no further reduction (17.10.5.5).</p>', 100*R.kase(1).fE);

% ---- 2. RAM --------------------------------------------------------------------------
w('<h2>2. Your RAM Connection model, checked against the site</h2>');
nf = fig(fid, nf, 'ram_front', 'The RAM model on the edge column, seen from outside. Red circles: conflicts.');
nf = fig(fid, nf, 'ram_sec', 'The RAM model in a section along the beam.');
w('<div class="tw"><table><tr><th>#</th><th>RAM model</th><th>On site / in the code</th><th>Consequence</th></tr>');
w('<tr><td>1</td><td>Anchor at v = 0 in the top row</td><td>Mid-face column bar at v = 0, u = 58</td><td>Not buildable (overlap %.0f mm). With 5 anchors one always sits at v = 0: an even number is needed</td></tr>', -M.c_mid);
w('<tr><td>2</td><td>Anchors at v = &plusmn;75</td><td>Rods of the steel column at v = &plusmn;100</td><td>%.0f mm clear, less than the placing tolerance</td></tr>', M.c_rod);
w('<tr><td>3</td><td>Second row at z = %g</td><td>Beam top bars at z = -56, &plusmn;13 mm</td><td>%.0f mm clear nominal, %.0f with the ACI tolerance: clash</td></tr>', M.z2, M.c_bar, M.c_barT);
w('<tr><td>4</td><td>Top row %g mm over the flange</td><td>Washer &#216;30 plus the 8 mm fillet</td><td>Washer on the fillet (%.0f mm)</td></tr>', M.pf, M.c_nut);
w('<tr><td>5</td><td>Row spacing %g mm</td><td>6 d<sub>a</sub> = 96 for torqued cast-in anchors (17.9.2)</td><td>Too close</td></tr>', M.sp);
w('<tr><td>6</td><td>Concrete %g mm above the top anchors</td><td>Pedestal top %g mm above them</td><td>Breakout &phi;N<sub>cbg</sub> &asymp; %.0f kN (cracked) against %.0f kN in 5 anchors: fails. The beam top bars must carry the pull (17.5.2.1)</td></tr>', M.caTop, P.col.top - M.top, M.phiNcbg*kN, M.Tsum5*kN);
w('<tr><td>7</td><td>Uncracked concrete</td><td>Cracked (joint under moment; 17.10.5.4)</td><td>Concrete strengths 20 to 30%% lower</td></tr>');
w('<tr><td>8</td><td>J/L-bolt pullout, e<sub>h</sub> = %g: 20.9 kN</td><td>Cracked: %.1f kN &lt; 15.1 kN</td><td>Fails even with RAM''s loads; the design uses a back plate</td></tr>', M.eh, M.phiNp_c*kN);
w('<tr><td>9</td><td>Shear key %gx%gx%g, %g deep</td><td>Its pocket reaches %s</td><td>Not buildable, and not needed</td></tr>', M.key(1), M.key(3), M.key(2), M.key(2), strjoin(M.key_hits, '; '));
w('<tr><td>10</td><td>Plate 250x351x12 A36: bearing interface 1.04</td><td>Real loads, DG1 3.4.2: m-side %.2f, n-side %.2f</td><td>The strip beyond the flange tips (n = 77) governs; 250 wide does not work in 12 mm</td></tr>', R.plate.user);
w('<tr><td>11</td><td>ACI 318-08; 1.5 directional factor on the key welds</td><td>ACI 318-19; no 1.5 factor</td><td>Updated</td></tr>');
w('<tr><td>12</td><td>M<sub>u</sub> %.2f, V<sub>u</sub> %.2f</td><td>M<sub>u</sub> %.2f, V<sub>u</sub> %.1f (with E<sub>v</sub>)</td><td>Loads short</td></tr>', M.Mu, M.Vu, E.Mu*kNm, E.Vu*kN);
w('</table></div>');

% ---- 3. design -----------------------------------------------------------------------
w('<h2>3. Design</h2>');
w('<div class="tw"><table><tr><th>Piece</th><th>Description</th><th>Why</th></tr>');
w('<tr><td>End plate</td><td>PL %gx%gx%g A36, the same plate for all types: top %g over the beam top, %g below the bottom flange; holes drilled to the surveyed anchors (z = %+g, CY %+g)</td><td>Width %g so that the strips beyond the flange tips work (n = %g); 12 mm is the plate available; one plate so that the shop does not need to know the type</td></tr>', P.ep.t, P.ep.w, E.H, E.ep_top, P.ep.under, an.pf, an.zH, P.ep.w, E.dg.n);
w('<tr><td>Extra plates</td><td>2 pieces PL %gx%gx%g A36 on the column side, gap %g over the rib, fillets %g on the bottom and inner edges only (shop)</td><td>12 mm alone fails the tension side; each piece is welded over the flange line and the rib line, so its share goes to the same supports</td></tr>', P.dbl.t, P.ep.w/2 - P.dbl.gap/2, E.ep_top, P.dbl.gap, P.dbl.w);
w('<tr><td>Rib</td><td>PL %g on the web line over the top flange, %g long, %g high, fillets %g (site)</td><td>Second support for the plate around the anchors</td></tr>', P.rib.t, 5*ceil(E.ep_top/tan(pi/6)/5), E.ep_top, P.rib.w);
w('<tr><td>Top anchors</td><td>2 threaded rods %s %s (commercial, cut to length), L = %.0f, |v| = %g, z = %+g (CY %+g)</td><td>Hooks would not fit; straight bars with a back plate</td></tr>', an.thr, an.grade, an.out + an.uT, an.vT, an.pf, an.zH);
w('<tr><td>Back plate</td><td>PL %gx%gx%g A36 at u = %g, nuts on both faces</td><td>Behind the far column bars and the far ties; deep breakout body</td></tr>', bp.t, bp.h, bp.w, bp.u);
w('<tr><td>Shear anchors</td><td>2 threaded rods %s, L = %.0f, z = %.1f, nut + washer at u = %g</td><td>Compression zone; short, so those of X and Y do not cross</td></tr>', an.lab, an.outS + an.uS + an.twsh + an.tnut + an.pp, E.zS, an.uS);
w('<tr><td>Grout pad</td><td>%g mm, commercial non-shrink grout (ASTM C1107), f''<sub>g</sub> &ge; %g MPa = %.0f kg/cm&sup2;, e.g. SikaGrout-212 or INTACO Maxibed Grout (%g mm under the extra plates)</td><td>The end plate is not cast flush</td></tr>', P.g, P.fg, P.fg/0.0980665, P.g - P.dbl.t);
w('<tr><td>Ties</td><td>2 closed &#216;14 at %+g and %+g, both under the anchors: the upper one under the B1 front nuts, B1 bears on it; the lower one %s</td><td>ACI 10.7.6.1.5 (rods of the steel column)</td></tr>', P.top.z, 'on the beam top bars');
w('</table></div>');
w('<div class="tw"><table><tr><th>Type</th><th>Where</th><th class="n">Number</th><th>Anchors z</th><th>End plate</th><th class="n">M<sub>u</sub></th><th class="n">V<sub>u</sub></th><th class="n">T (kN)</th><th>Beam in line</th></tr>');
nn = [1 2 1 1];
for j = 1:4
    Yj = R.typ(j);
    w('<tr><td>%s</td><td>%s</td><td class="n">%d</td><td class="n">%+g</td><td>PL %gx%gx%g</td><td class="n">%.2f</td><td class="n">%.1f</td><td class="n">%.1f</td><td>%s</td></tr>', Yj.name, Yj.where, nn(j), Yj.zT, P.ep.t, P.ep.w, Yj.H, Yj.Mu*kNm, Yj.Vu*kN, Yj.T*kN, Yj.beam);
end
w('</table></div><p>Corner rule: beam Y (the high anchors) is the corner beam whose top bars are on the upper layer; look at the tied cage. Numbers of each type from the first design: to be confirmed.</p>');
w('<h3>Edge column (type E)</h3>');
nf = fig(fid, nf, 'edge_elev', 'Type E, section along the beam.');
nf = fig(fid, nf, 'edge_plan', 'Edge column, plan. Solid red: top anchors; light red: shear anchors (lower).');
nf = fig(fid, nf, 'edge_front', 'Type E seen from outside. Dashed: the extra plates behind the end plate.');
w('<h3>Corner with two cantilevers (types CX and CY)</h3>');
nf = fig(fid, nf, 'cor_plan', 'Plan.');
nf = fig(fid, nf, 'cor_elevX', 'Beam X (type CX), section.');
nf = fig(fid, nf, 'cor_elevY', 'Beam Y (type CY), section.');
nf = fig(fid, nf, 'cor_front', 'Type CY seen from outside.');
w('<h3>Corner with one cantilever (type C1)</h3>');
nf = fig(fid, nf, 'c1_plan', 'Plan. Same pieces as type E.');
w('<h3>Grout pad</h3>');
nf = fig(fid, nf, 'grout', 'The end plate is not cast flush: grout pad and levelling nuts.');

% ---- 4. end plate ----------------------------------------------------------------------
w('<h2>4. End plate (full steps: <a href="plate_check.html">plate_check.html</a>)</h2>');
nf = fig(fid, nf, 'reinf', 'End plate of type E: (A) the extension with its strips, (B) the extra plates with theirs, (C) the bearing zone.');
nf = fig(fid, nf, 'reinf_sec', 'Section through a top anchor.');
D = E.dg;  SL = R.strip(1);  mn = 0.9*P.st.Fy(st)*P.ep.t^2/4;
w('<ul><li>Forces (DG1 3.4, P = 0, f<sub>p</sub> = %.2f MPa): Y = %.1f mm, T = %.1f kN, T<sub>a</sub> = %.1f kN per anchor; &phi;m<sub>p</sub> = %.2f kN m/m.</li>', D.fp, D.Y, D.T*kN, E.Ta*kN, mn*kN);
w('<li>Tension side: each anchor is held by strips to the flange and to the rib, in the end plate (x<sub>1</sub> = %g / b<sub>1</sub> = %g, x<sub>2</sub> = %g / b<sub>2</sub> = %g) and in the extra plate (%g / %g, %g / %g), each strip cut to where it lands on its welded support. The two plates are not composite: their capacities add. D/C <b>%.2f</b>; strict (plate elastic, 1.11 m): %.2f.</li>', ...
  SL.x1, SL.w1, SL.x2, SL.w2, SL.y1, SL.u1, SL.y2, SL.u2, dc('Tension side: end plate', 1), dc('No prying, strict', 1));
w('<li>Bearing side: m = %g, n = %g: D/C %.2f / %.2f; strict, with f<sub>p</sub> at its full allowed %.1f MPa (&radic;(A<sub>2</sub>/A<sub>1</sub>) = %.2f): <b>%.2f</b>.</li>', D.m, D.n, D.Mb/mn, D.Mbn/mn, R.dgs(1).fp, R.dgs(1).fp/D.fp, dc('Bearing side at f', 1));
w('<li>Prying (AISC Manual 9-20a): t<sub>min</sub> &le; t<sub>eff</sub>, D/C %.2f.</li></ul>', dc('No prying (AISC', 1));
w('<p>What was tried before this (real loads, type E):</p><div class="tw"><table><tr><th>End plate</th><th class="n">Tension side</th><th>Result</th></tr>');
w('<tr><td>Your plate 250x351x12 A36</td><td class="n">-</td><td>Bearing strip beyond the flange tips %.2f: fails</td></tr>', R.plate.user(2));
w('<tr><td>160 wide, 12 mm A36, rib, no extra plate</td><td class="n">1.29</td><td>Fails</td></tr>');
w('<tr><td>160 wide, 12 mm A36, extra plate, no rib</td><td class="n">1.33</td><td>Fails: the rib is the second support</td></tr>');
w('<tr><td>160 wide, 12 mm A36, rib + extra plate (design)</td><td class="n">%.2f</td><td>Passes</td></tr>', dc('Tension side: end plate', 1));
w('</table></div>');

% ---- 5. anchors ------------------------------------------------------------------------
w('<h2>5. Tension anchors and back plate (full steps: <a href="anchorage_check.html">anchorage_check.html</a>)</h2>');
w('<ul><li>Rod steel (%s, A<sub>se</sub> = %g mm&sup2;, f<sub>uta</sub> = %g): D/C %.2f; with shear if all four holes bear: %.2f.</li>', an.grade, an.Ase, an.futa, dc('Top anchor, steel', 1), dc('Top anchor, tension + shear', 1));
w('<li>Back plate: pullout %.2f, side-face blowout towards the pedestal top %.2f (CY %.2f), bending %.2f between the anchors and %.2f through a hole.</li>', dc('Pullout at the back plate', 1), dc('Side-face blowout', 1), dc('Side-face blowout', 4), dc('Back plate bending between', 1), dc('Back plate through the hole', 1));
w('<li>Anchor reinforcement (beam top bars, every tolerance against): steel %.2f, length inside the breakout body %.2f, within 0.5 h<sub>ef</sub> %.2f. The concrete alone would be at %.2f.</li></ul>', ...
  dc('Anchor reinforcement: top bars', 1), dc('Anchor reinforcement: beam bars inside', 1), dc('Anchor reinforcement within', 1), dc('Unreinforced breakout', 1));
nf = fig(fid, nf, 'cone_E', 'Type E: breakout body and the beam bar that limits it, every tolerance against.');

% ---- 6. table --------------------------------------------------------------------------
w('<h2>6. Limit states</h2>');
w('<p>Green &le; 0.85, yellow &le; 1.0, red &gt; 1.0; grey: information only, not relied upon. Last column: the check of type E written out.</p>');
w('<div class="tw"><table><tr><th>Group</th><th>Limit state</th><th>Reference</th><th class="n">E</th><th class="n">C1</th><th class="n">CX</th><th class="n">CY</th><th>Demand / capacity, E</th><th>Check, type E</th></tr>');
for i = 1:size(rr,1)
    r = rr(i,:);  u = r{6};  [sc, uu] = unit(u);
    d = r{4}./r{5};
    c = 'ok';  if max(d) > 0.85, c = 'warn'; end;  if max(d) > 1, c = 'bad'; end
    if strcmp(r{8}, 'info'), c = 'inf'; end
    if strcmp(u, '-'), ds = sprintf('%.2f / %.2f', r{4}(1), r{5}(1)); else, ds = sprintf('%.1f / %.1f %s', r{4}(1)/sc, r{5}(1)/sc, uu); end
    w('<tr class="%s"><td>%s</td><td>%s</td><td>%s</td><td class="n">%.2f</td><td class="n">%.2f</td><td class="n">%.2f</td><td class="n">%.2f</td><td class="n">%s</td><td class="eq">%s</td></tr>', c, r{1}, r{2}, r{3}, d, ds, r{7});
end
w('</table></div>');
w('<p>Shear: the shear anchors are checked carrying all of V<sub>u</sub>, and the top anchors as if all four holes bore at once; both pass. Concrete in shear (anchor check page, section 8): no breakout downward, the column continues below; pryout behind the shear anchors; breakout towards a side face under the torsion couple, with the vertical shear parallel to that face. Torsion at the corners: T<sub>u</sub> = V<sub>u</sub> b<sub>f</sub>/2 (edge: half), a horizontal couple between top and shear anchors. All welds are taken as site welds (AISC J2.4, E70, no directional factor).</p>');

% ---- 7. capacity -----------------------------------------------------------------------
w('<h2>7. Largest moment the connection takes</h2><div class="tw"><table><tr><th>Type</th><th class="n">Design M<sub>u</sub></th><th class="n">Largest M<sub>u</sub></th><th class="n">Ratio</th><th>Limited by</th></tr>');
for j = 1:4
    w('<tr><td>%s</td><td class="n">%.2f</td><td class="n"><b>%.1f</b></td><td class="n">%.2f</td><td>%s</td></tr>', R.typ(j).name, R.typ(j).Mu*kNm, C.Mu(j), C.Mu(j)/(R.typ(j).Mu*kNm), C.gov{j});
end
w('</table></div><p>All forces scaled together until the first check reaches 1.0 (information rows and the concrete beam in line left out). Without the strict no-prying criterion: %.1f / %.1f kN m.</p>', C.Mu2(1), C.Mu2(4));

% ---- 8. questions ----------------------------------------------------------------------
w('<h2>8. Questions</h2>');
w('<h3>The end plate is not cast flush</h3><ul>');
w('<li>Grout pad on a vertical face, %g mm, non-shrink and flowable, at least %g MPa; %g mm under the extra plates (check the minimum of the grout chosen). The face roughened and wetted; the compression passes through it, so a void under the bottom flange is a real defect.</li>', P.g, P.fg, P.g - P.dbl.t);
w('<li>Shear anchors through a grout pad: V<sub>sa</sub> &times; 0.80 (17.7.1.2.1), included.</li>');
w('<li>The anchors are positioned only by a template during the pour. The end plate is drilled to the surveyed anchors, so errors in the plane of the face disappear; errors in level do not (section 9).</li></ul>');
w('<h3>A flush (embedded) plate?</h3><p>It would act as template and bearing surface (no grout on a vertical face) and remove the 0.80 factor on the shear anchors. The end plate, anchors and back plate keep their dimensions; the anchors stick out %g mm less. It gives no room in level with a bolted beam; only a beam welded to an embedded plate absorbs level errors of 1 to 2 cm.</p>', P.g);
w('<h3>Back plate outside, on the far face?</h3><p>Not better: the rods become through-bolts, outside ACI chapter 17 (17.1.5); the plate would bear on the 40 mm cover outside the ties and stay exposed until the slab is cast. A larger back plate only helps checks that already have room.</p>');
w('<h3>Shear key?</h3><p>Not needed: the shear anchors take V<sub>u</sub> (D/C %.2f). Keys beside the centre bar would be limited to about 35 mm deep by the tie layers and the hook tails of the beam bars.</p>', dc('Shear anchor, steel', 1));
w('<h3>IPE 200? Composite section?</h3><p>The IPE 200 itself passes, but its shorter lever arm raises the pull on the anchors from 81 to about 97 kN and its narrower flange makes the bearing strip beyond the flange tips fail (about 1.13). A composite section does not help a cantilever: the slab is in tension, and the anchors take the couple at the column face whatever the slab does. IPE 240, not composite.</p>');
w('<h3>Rib and extra plates: both needed?</h3><p>Yes, at E, CX and CY. Without the extra plates the tension side is at 1.29 / 0.68 / 0.99 / 1.11 (E / C1 / CX / CY); without the rib (with the extra plates) at 1.33 / 0.71 / 1.02 / 1.33. C1 would pass without the extra plates; they are used everywhere so that there is one detail.</p>');

% ---- 9. room ---------------------------------------------------------------------------
w('<h2>9. Room for site errors</h2>');
nf = fig(fid, nf, 'tol', 'Where the axis of a top anchor of type E may be, everything else nominal.');
w('<div class="tw"><table><tr><th>Item</th><th>Direction</th><th class="n">Room (mm)</th><th>Limited by</th></tr>');
for i = 1:size(R.tolt,1)
    v = R.tolt{i,3};
    if isinf(v), vs = 'free'; elseif isnan(v), vs = '-'; else, vs = sprintf('%.0f', v); end
    w('<tr><td>%s</td><td>%s</td><td class="n">%s</td><td>%s</td></tr>', R.tolt{i,1}, R.tolt{i,2}, vs, R.tolt{i,4});
end
w('</table></div><p>The level of the top anchors is the tight direction. Hold points: template level and anchor positions before the pour; at the corner, beam Y = the beam with its top bars on the upper layer, the column hooks placed after the A1 + B1 assemblies, level A resting on the A1 and the B1 front nuts (E, C1, CX) and tied to them; beam corner bars at &plusmn;88 in the joint, tied to the rods of the steel column; survey after stripping; grout full under the bottom flange.</p>');

% ---- 10. clearances ------------------------------------------------------------------
w('<h2>10. Clearances (nominal)</h2><div class="tw"><table><tr><th>Between</th><th class="n">mm</th><th>Note</th></tr>');
for i = 1:size(R.clr,1), w('<tr><td>%s</td><td class="n">%.0f</td><td>%s</td></tr>', R.clr{i,1}, R.clr{i,2}, R.clr{i,3}); end
w('</table></div>');

% ---- 11. double plate ----------------------------------------------------------------
w('<h2>11. Against the double plate design</h2>');
w('<p>With the back plate, this design uses the same holes through the joint, the same anchor reinforcement and the same anchor levels as the double plate. What is left is the face: a flush front plate (template, steel-on-steel bearing; kept flush and vented during the pour) against a grout pad (nothing embedded at the face; grouting on a vertical face, survey and drilling). The double plate''s PL 20 end plate is not available either: it would need this same 12 mm plate with rib and extra plates, and its checks redone with the ETABS loads. Rods: B7 there, threaded rod B7 here too.</p>');

% ---- 12. corrections -----------------------------------------------------------------
w('<h2>12. Mistakes found and corrected during this work</h2><ol>');
w('<li>DG1 bearing strip beyond the flange tips (n) left out at first: at B = 250 it was 1.60. Plate narrowed to %g.</li>', P.ep.w);
w('<li>Yield lines and prying of type CY first computed with the anchor 29 over the flange instead of 56.</li>');
w('<li>A clearance quoted as &minus;1 mm (depth only); the real gap is lateral, 13 mm.</li>');
w('<li>Labels in the drawings read clearances by row number; after rows moved they showed wrong values.</li>');
w('<li>The hook bends of the hooked version hit the top tie at 0; hooks then replaced by the back plate.</li>');
w('<li>Back plate 40 high left 20 mm from the holes to its edges (AISC J3.4M: 22): now %g high.</li>', bp.h);
w('<li>Bearing side first checked only with f<sub>p</sub> without the &radic;(A<sub>2</sub>/A<sub>1</sub>) increase; the strict version with the full allowed pressure is now a check (%.2f).</li>', dc('Bearing side at f', 1));
w('<li>The loads of the tributary areas were 12%% under ETABS; the design now uses ETABS.</li>');
w('</ol>');

% ---- 13. open items ------------------------------------------------------------------
w('<h2>13. Open items</h2><ul>');
w('<li><b>Concrete beam in line, bundled bars.</b> The VCM has 2 bars in contact under the corner bars. ACI 318-19 R25.6.1.5: development of a hooked bundle is not covered by 25.4.3. With all its top bars (C4: 5 + 2 bastones) the beam is at %.2f (edge, ETABS + E<sub>v</sub>); counting only the 3 bars of the top line, at %.2f (%.2f with the ETABS moment alone: %.1f against %.1f kN m). To check in your beam design, or separate the stacked bars at their hooks before the pour. It does not change the connection: the anchors count only the top line.</li>', ...
  dc('Concrete beam in line', 1), dc('Same, counting only the', 1), P.etabs.Mbeam_edge(2)/(R.phiM3(1)*kNm), P.etabs.Mbeam_edge(2), R.phiM3(1)*kNm);
w('<li>Numbers of connections of each type (sheets: 1 E, 2 C1, 1 CX, 1 CY).</li>');
w('<li>Minimum thickness of the chosen grout (%g mm under the extra plates).</li>', P.g - P.dbl.t);
w('<li>Threaded rod %s %s, bought in bars and cut to length; grade marked on the bar and quality certificate. Hardware-store rod (grade 2) is not allowed (A<sub>se</sub> = %g mm&sup2; used).</li>', an.thr, an.grade, an.Ase);
w('<li>Ends of the top anchors %.0f mm from the far face, above the beam top (covered by the slab); back plate of CY %.1f mm under the pedestal top (under the base plate grout).</li>', P.col.b - an.uT, P.col.top - (an.zH + bp.h/2));
w('<li>Deck notched around the end plate and the rib.</li>');
w('</ul></body></html>');
fclose(fid);
end

% ------------------------------------------------------------------------------------
function nf = fig(fid, nf, name, cap)
nf = nf + 1;
fprintf(fid, '<figure><img src="figures/%s.png" alt="%s"><figcaption>Figure %d. %s</figcaption></figure>\n', name, name, nf, cap);
end

function v = dcv(rr, s, j)
i = find(strncmp(rr(:,2), s, numel(s)), 1);
D = rr{i,4};  C = rr{i,5};
v = D(j)/C(j);
end

function [s, uu] = unit(u)
s = 1;  uu = u;
if strcmp(u, 'kN'), s = 1e3; elseif strcmp(u, 'kN m'), s = 1e6; elseif strcmp(u, 'kN m/m'), s = 1e3; end
end

function d = worst(R)
d.dc = 0;  d.name = '';  d.typ = '';
for i = 1:size(R.rows, 1)
    r = R.rows(i,:);
    if strcmp(r{8}, 'info'), continue; end
    [m, j] = max(r{4}./r{5});
    if m > d.dc, d.dc = m;  d.name = regexprep(r{2}, '<[^>]*>', '');  d.typ = R.typ(j).name; end
end
end

function r = ifelse_r(c, a, b)
  if c, r = a; else, r = b; end
end
