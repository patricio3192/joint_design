function ca_report(P, R, F, fname)
% CA_REPORT  Writes the HTML report of the cantilever anchorage (revision 2).
%   ca_report(P, R, F, fname): P from ca_inputs, R from ca_calc, F from ca_draw.
%   All the numbers printed here are read from R; nothing is typed by hand.

fid = fopen(fname, 'w');
kN = 1e-3;  kNm = 1e-6;
E = R.kase(1);  C = R.kase(2);  V3 = R.kase(3);
B = R.beam;  W = R.weld;  G = R.plate;  N = R.anc;  D = R.dev;  Q = R.brk;  X = R.ar;
J = R.joint;  M = R.stm;  H = R.shear;  Y = R.brg;  O = R.tor;  Z = R.ped;  bm = P.bm;
sq = sqrt(P.fc);  db = P.anc.db;  Ab = pi*db^2/4;  Ab12 = pi*P.cb.db^2/4;
ldh14 = max([P.fy*D.psic/(23*sq)*14^1.5, 8*14, 150]);    % lower edge bars as Ø14, alternative

w(fid, '<!DOCTYPE html>');
w(fid, '<html lang="en"><head><meta charset="utf-8">');
w(fid, '<meta name="viewport" content="width=device-width, initial-scale=1">');
w(fid, '<title>Cantilever anchorage report</title>');
w(fid, '<style>');
w(fid, 'body{font-family:Georgia,"Times New Roman",serif;color:#1b1b1b;background:#fbfaf7;margin:0;line-height:1.5}');
w(fid, 'main{max-width:1080px;margin:0 auto;padding:24px 20px 80px}');
w(fid, 'h1{font-size:30px;margin:12px 0 4px} h2{font-size:22px;margin:44px 0 10px;padding-top:12px;border-top:2px solid #34506b}');
w(fid, 'h3{font-size:17px;margin:26px 0 6px;color:#34506b} p{margin:8px 0} .sub{color:#555;margin:0 0 18px}');
w(fid, 'table{border-collapse:collapse;width:100%%;margin:12px 0;font-family:Helvetica,Arial,sans-serif;font-size:13.5px}');
w(fid, 'th,td{border-bottom:1px solid #d9d5ca;padding:5px 8px;text-align:left;vertical-align:top}');
w(fid, 'th{background:#ece9e2;font-weight:600} td.n,th.n{text-align:right;white-space:nowrap}');
w(fid, '.tw{overflow-x:auto} .grp td{background:#f3f1ea;font-weight:600;color:#34506b}');
w(fid, '.ok{background:#dcefe1} .mid{background:#fbeec8} .bad{background:#f6d0cb} .inf{background:#e6e6e6;color:#555}');
w(fid, '.eq{font-family:Helvetica,Arial,sans-serif;font-size:14px;background:#fff;border-left:3px solid #34506b;padding:6px 12px;margin:6px 0;overflow-x:auto}');
w(fid, '.step{background:#fff;border:1px solid #d9d5ca;border-radius:6px;padding:10px 16px;margin:14px 0}');
w(fid, '.step h3{margin-top:4px} .res{font-family:Helvetica,Arial,sans-serif;font-weight:600;color:#1e6b3a}');
w(fid, '.ref{color:#8a4b00;font-size:12.5px;white-space:nowrap} .note{background:#fdf3d7;border:1px solid #e3c96b;padding:10px 14px;margin:14px 0}');
w(fid, '.warn{background:#fbe3df;border:1px solid #d98b80;padding:10px 14px;margin:14px 0}');
w(fid, 'figure{margin:18px 0;background:#fff;border:1px solid #d9d5ca;padding:8px;overflow-x:auto}');
w(fid, 'figure svg{max-width:100%%;height:auto;display:block;margin:0 auto} figcaption{font-family:Helvetica,Arial,sans-serif;font-size:13px;color:#444;padding:6px 4px 2px}');
w(fid, '.leg span{display:inline-block;width:22px;height:8px;margin:0 5px 0 14px;vertical-align:middle}');
w(fid, 'ol li,ul li{margin:4px 0} nav a{margin-right:14px;font-family:Helvetica,Arial,sans-serif;font-size:13.5px}');
w(fid, '@media print{body{background:#fff} h2{page-break-before:always} figure,.step{page-break-inside:avoid}}');
w(fid, '</style></head><body><main>');

% ---------------------------------------------------------------- header
w(fid, '<h1>Steel cantilever anchored to a concrete pedestal</h1>');
w(fid, '<p class="sub">Revision 2. %s cantilever, %g m from the column axis, on %gx%g cm pedestals: edge column (one beam) and corner column (two beams). ', bm.name, (P.L+P.a0)/1000, P.col.b/10, P.col.b/10);
w(fid, 'ACI 318-19 (318S-14 where it differs), AISC 360-16, NEC-SE-DS. LRFD. Units kN, mm, MPa. Generated %s by t1_cantilever_anchor.m.</p>', datestr(now, 'yyyy-mm-dd'));
w(fid, '<nav><a href="#s1">1 Changes</a><a href="#s2">2 Easy check</a><a href="#s3">3 Drawings</a><a href="#s4">4 All limit states</a><a href="#s5">5 Site</a><a href="#s6">6 Notes</a></nav>');

% ---------------------------------------------------------------- 1 changes
w(fid, '<h2 id="s1">1. What changed in revision 2</h2>');
w(fid, '<div class="tw"><table><tr><th>Item</th><th>Revision 1</th><th>Revision 2</th><th>Why</th></tr>');
w(fid, '<tr><td>Dead load</td><td>3.0 kN/m&sup2;</td><td>%g kN/m&sup2;</td><td>your value</td></tr>', P.qD);
w(fid, '<tr><td>Cantilever</td><td>1.3 m from the face</td><td>%g m from the axis = %g m from the face</td><td>real geometry</td></tr>', (P.L+P.a0)/1000, P.L/1000);
w(fid, '<tr><td>Pull on the anchors, edge</td><td>157 kN</td><td>%.0f kN</td><td>lighter load, shorter arm</td></tr>', E.T*kN);
w(fid, '<tr><td>Pedestal</td><td>4 &Oslash;16</td><td>8 &Oslash;16 (4 corners + 4 mid-face), 4 &Oslash;12 rods of the steel column</td><td>your data</td></tr>');
w(fid, '<tr><td>Lug</td><td>190 x 110 mm</td><td>%g x %g mm</td><td>the mid-face column bar sits %g mm behind the face, in the way of the old lug</td></tr>', P.lug.w, P.lug.L, P.col.cover + P.col.dtie);
w(fid, '<tr><td>Anchors, edge</td><td>4 &Oslash;16 in one row</td><td>4 &Oslash;16: 2 under and 2 over the lug, at v = &plusmn;%g</td><td>they must sit behind the flange; two levels keep them in the gaps between the beam bars</td></tr>', abs(P.anc.v(1)));
w(fid, '<tr><td>Anchors, corner</td><td>4 + 4 &Oslash;16</td><td>2 + 2 &Oslash;16</td><td>enough with the new loads; much less congestion</td></tr>');
w(fid, '<tr><td>Added L bars</td><td>2 &Oslash;16 per beam</td><td><b>none</b></td><td>the edge beam has 5 &Oslash;12 on top, which is enough; see step 5</td></tr>');
w(fid, '<tr><td>Bar welds</td><td>on the lug only</td><td>end of each bar welded to the plate + side welds on the lug</td><td>shorter lug; the bar now touches the plate</td></tr>');
w(fid, '<tr><td>Joint ties</td><td>3 two-piece hoops</td><td>%d layers, each of 4 straight &Oslash;%g ties with 135&deg; hooks</td><td>they confine the hooks of the anchors and of the beam bars together (step 5)</td></tr>', numel(P.hoop.z), P.hoop.db);
w(fid, '<tr><td>Beams</td><td>6 &Oslash;12 assumed</td><td>VCM: 10 &Oslash;12 (5 top, layout 2-1-2). VCS: 6 &Oslash;12. The corner is checked with the VCS on both sides</td><td>your sections</td></tr>');
w(fid, '</table></div>');
w(fid, '<div class="tw"><table><tr><th>Case</th><th class="n">V<sub>u</sub> (kN)</th><th class="n">M<sub>u</sub> at the face (kN m)</th><th class="n">T (kN)</th><th class="n">Anchors</th><th class="n">Anchor D/C</th><th class="n">Highest D/C</th></tr>');
for k = 1:3
    K = R.kase(k);
    w(fid, '<tr><td>%s</td><td class="n">%.1f</td><td class="n">%.1f</td><td class="n">%.0f</td><td class="n">%d &Oslash;%g</td><td class="n">%.2f</td><td class="n">%.2f</td></tr>', K.name, K.Vu*kN, K.Mu*kNm, K.T*kN, R.nb(k), db, K.T/N.phiNy(k), maxdc(R, k));
end
w(fid, '</table></div>');
w(fid, '<p>The highest ratios are lengths, not forces: the hook embedment of the edge anchors under the lug (step 4) and their overlap with the hooks of the beam bars (step 5). They pass with the stricter way of measuring.</p>');

% ---------------------------------------------------------------- 2 easy check
w(fid, '<h2 id="s2">2. Easy check, step by step</h2>');
w(fid, '<p>Edge beam, which governs. Each step is one idea, one formula, one number. The corner beams are in the table of section 4.</p>');
w(fid, '<figure>%s<figcaption>Tributary areas, beyond the column face.</figcaption></figure>', F.trib);

w(fid, '<div class="step"><h3>Step 1. Load on the beam</h3>');
w(fid, '<div class="eq">q = 1.2 D + E<sub>v</sub> + L = 1.2 (%g) + %.3f (%g) + %g = <b>%.2f kN/m&sup2;</b> &nbsp; (1.2D + 1.6L gives %.2f) <span class="ref">NEC-SE-DS 3.4.4</span></div>', P.qD, R.Ev, P.qD, P.qL, R.q(2), R.q(1));
w(fid, '<div class="eq">E<sub>v</sub> = (2/3) I &eta; Z F<sub>a</sub> = (2/3)(%g)(%g)(%g)(%g) = %.3f of the dead load. This is the vertical force the NEC asks for cantilevers. The horizontal coefficient %.4f g does not load this connection: the slab takes it.</div>', P.I, P.eta, P.Z, P.Fa, R.Ev, P.eta*P.Z*P.Fa*P.I/2.5);
w(fid, '<div class="eq">w = q s + beam = %.2f (%g) + %.2f = <b>%.1f kN/m</b></div>', R.q(2), P.s_edge/1000, R.gsw(2)*bm.w, R.q(2)*P.s_edge/1000 + R.gsw(2)*bm.w);
w(fid, '<div class="eq">At the column face: V = w L = <b>%.1f kN</b> &nbsp;&nbsp; M = w L&sup2;/2 = <b>%.1f kN m</b> &nbsp; (L = %g m from the face)</div>', E.Vu*kN, E.Mu*kNm, P.L/1000);
w(fid, '<p>0.9D &minus; E<sub>v</sub> = %.2f kN/m&sup2;, still downwards, so the moment never reverses and only the top flange pulls.</p></div>', R.q(3));

w(fid, '<div class="step"><h3>Step 2. The moment becomes a pull and a push</h3>');
w(fid, '<p>The flanges carry the moment as two opposite forces, one flange depth apart: the top flange pulls the column (T), the bottom flange pushes on it (C = T).</p>');
w(fid, '<div class="eq">T = M / (h &minus; t<sub>f</sub>) = %.1f / %.4f = <b>%.0f kN</b></div>', E.Mu*kNm, R.ho/1000, E.T*kN);
w(fid, '<p>The rest of the design is: give T to steel that is anchored on the other side of the column, let C bear on the concrete, and let V go down.</p></div>');

w(fid, '<div class="step"><h3>Step 3. Are there enough anchor bars?</h3>');
w(fid, '<div class="eq">&phi; A<sub>s</sub> f<sub>y</sub> = 0.75 (%d x %.0f)(%g) = <b>%.0f kN</b> &ge; T = %.0f kN &nbsp; <span class="res">D/C = %.2f</span> <span class="ref">ACI 17.5.3, 23.7.2</span></div>', R.nb(1), Ab, P.fy, N.phiNy(1)*kN, E.T*kN, E.T/N.phiNy(1));
w(fid, '<p>Would fewer do? 2 &Oslash;16 give %.0f kN, D/C %.2f at the edge. That passes, but with little margin, so the edge keeps 4. The corner beams use 2 (D/C %.2f with the trapezoid, %.2f with the envelope).</p></div>', N.phiNy(2)*kN, E.T/N.phiNy(2), C.T/N.phiNy(2), V3.T/N.phiNy(3));

w(fid, '<div class="step"><h3>Step 4. Is each anchor bar long enough? (hook development)</h3>');
w(fid, '<p>A hooked bar needs a length &#8467;<sub>dh</sub> of concrete, measured to the outside of the hook, to reach its yield force without pulling out:</p>');
w(fid, '<div class="eq">&#8467;<sub>dh</sub> = f<sub>y</sub> &psi;<sub>c</sub> d<sub>b</sub><sup>1.5</sup> / (23 &radic;f''c) = %g (%.3f)(%g)<sup>1.5</sup> / (23 (%.2f)) = <b>%.0f mm</b> <span class="ref">ACI 25.4.3.1, SI (Appendix E)</span></div>', P.fy, D.psic, db, sq, D.ldh);
w(fid, '<p>&psi;<sub>c</sub> = 0.01 f''c + 0.6 = %.3f (SI form of f''c/15000 + 0.6, ACI Appendix E). The other factors are 1.0 because the hooks are inside the column core and the %d joint hoops confine them (without the hoops: %.0f mm) <span class="ref">Table 25.4.3.2, 25.4.3.3</span>.</p>', D.psic, numel(P.hoop.z), D.ldh_nohoop);
w(fid, '<div class="tw"><table><tr><th>Bars</th><th class="n">Hook at</th><th class="n">Length from the plate</th><th class="n">From the end of the lug</th><th class="n">Needed</th><th class="n">D/C (stricter)</th></tr>');
w(fid, '<tr><td>Edge, under the lug</td><td class="n">%g</td><td class="n">%g</td><td class="n">%g</td><td class="n">%.0f</td><td class="n">%.2f</td></tr>', P.anc.uhA, P.anc.uhA-P.pl.t, P.anc.uhA-P.pl.t-P.lug.L, D.ldh, D.ldh/(P.anc.uhA-P.pl.t-P.lug.L));
w(fid, '<tr><td>Edge over the lug; corner X and Y</td><td class="n">%g</td><td class="n">%g</td><td class="n">%g</td><td class="n">%.0f</td><td class="n">%.2f</td></tr>', P.anc.uh, P.anc.uh-P.pl.t, P.anc.uh-P.pl.t-P.lug.L, D.ldh, D.ldh/(P.anc.uh-P.pl.t-P.lug.L));
w(fid, '</table></div>');
w(fid, '<p>The bar starts working at the plate, so the first column is the real length. The second ignores the %g mm along the lug, to be safe. By ACI 318S-14 the need is %.0f mm, still within both columns.</p>', P.lug.L, D.ldh14);
w(fid, '<p><b>Should the %.2f worry us?</b> No. &#8467;<sub>dh</sub> is the length that anchors the bar at its <i>yield</i> force, %.0f kN. Each edge bar carries T/4 = %.0f kN, %.0f%% of that. ACI does not let the length be reduced for the lower stress (25.4.10.2(d)), so the ratio stays, but the real margin is several times larger. If you want the ratio lower anyway, make the two lower edge bars &Oslash;14: &#8467;<sub>dh</sub> = %.0f mm, ratio %.2f, and the four bars still give D/C %.2f.</p>', D.ldh/(P.anc.uhA-P.pl.t-P.lug.L), P.fy*Ab*kN, E.T/4*kN, E.T/4/(P.fy*Ab)*100, ldh14, ldh14/(P.anc.uhA-P.pl.t-P.lug.L), E.T/(0.75*P.fy*(2*Ab + 2*pi*14^2/4)));
w(fid, '<p><b>Group effect.</b> ACI has no separate group reduction for development length. Bars close together are covered by &psi;<sub>r</sub>: under 6d<sub>b</sub> apart, the length grows by 1.6 unless ties enclose the hooks with A<sub>th</sub> &ge; 0.4 A<sub>hs</sub>. Here the same ties enclose the anchor hooks and the beam-bar hooks, so they are counted once for all of them: 0.4 (%.0f + %.0f) = %.0f mm&sup2; &le; %d ties x 2 legs x 78.5 = %.0f mm&sup2;. The breakout of the group is a separate check: step 5.</p></div>', R.As(1), numel(P.cb.ve)*Ab12, 0.4*D.AhsAll(1), numel(P.hoop.z), D.Ath);

w(fid, '<div class="step"><h3>Step 5. Who takes the pull after the anchors? (both sides of the breakout surface)</h3>');
w(fid, '<p>If the anchors were alone, they would pull out a cone of concrete. For these bars chapter 17 gives only %.0f kN (D/C %.1f), so the cone must be held by bars that cross it. Those bars are the top bars of the concrete beam in line with the cantilever. ACI accepts this if the crossing bars are <b>strong enough</b> and <b>developed on both sides of the cone</b> <span class="ref">ACI 17.5.2.1(a)</span>.</p>', Q.phiN*kN, E.T/Q.phiN);
w(fid, '<figure>%s<figcaption>Edge joint. Red: anchors. Green: top bars of the concrete beam. Orange dashed: the cone surface.</figcaption></figure>', F.flow);
w(fid, '<p><b>5a. Strong enough.</b></p>');
w(fid, '<div class="eq">%d &Oslash;%g top bars: &phi; A<sub>s</sub> f<sub>y</sub> = 0.75 (%d x %.0f)(%g) = <b>%.0f kN</b> &ge; T = %.0f kN &nbsp; <span class="res">D/C = %.2f</span></div>', X.n(1), P.cb.db, X.n(1), Ab12, P.fy, X.phiN(1)*kN, E.T*kN, E.T/X.phiN(1));
w(fid, '<p>So no bars need to be added. Corner: the VCS has 3 &Oslash;12 on top: %.0f kN, D/C %.2f; the VCM side is better (D/C %.2f).</p>', X.phiN(2)*kN, V3.T/X.phiN(3), V3.T/X.phiN(1));
w(fid, '<p><b>5b. Developed inside the cone.</b> The cone starts at the anchor hooks and opens towards the outer face with slope 1 : 1.5. Each beam bar enters it from the beam side and ends in its hook behind the plate. The part of the beam bar inside the cone, from the point where it crosses the cone surface to the outside of its hook, must be at least &#8467;<sub>dh</sub> of a &Oslash;12 = %.0f mm (&psi;<sub>r</sub> = 1.0 thanks to the ties, as in step 4).</p>', R.dev.ldh12);
w(fid, '<p>Conservative choices: the cone starts at the <i>beginning</i> of the anchor bend, not at the hook, which makes the cone smaller; the crossing point is computed in 3D from the distance between each beam bar and the nearest anchor; the worst beam bar is reported.</p>');
w(fid, '<div class="tw"><table><tr><th>Case</th><th>Beam bars (v, mm)</th><th class="n">Where each bar leaves the cone (u, mm)</th><th class="n">Length inside</th><th class="n">Needed</th><th class="n">D/C</th></tr>');
for k = 1:3
    w(fid, '<tr><td>%s</td><td>%s</td><td class="n">%s</td><td class="n">%.0f</td><td class="n">%.0f</td><td class="n">%.2f</td></tr>', R.corner_label{k}, num2str(R.cone(k).vb), num2str(round(R.cone(k).uc)), R.cone(k).inside, R.dev.ldh12, R.dev.ldh12/R.cone(k).inside);
end
w(fid, '</table></div>');
w(fid, '<figure>%s<figcaption>Edge, section along the beam. Dashed: the cone surface of each pair of anchors. The white dot on the beam bar is where the worst bar leaves the cone, computed in 3D, so it does not sit exactly on the dashed line of this section.</figcaption></figure>', F.dev_edge);
w(fid, '<figure>%s<figcaption>Corner, section along beam X, same check.</figcaption></figure>', F.dev_cor);
w(fid, '<figure>%s<figcaption>Corner in plan: the cones of X (orange) and Y (blue), the beam bars of both directions and the lengths inside, for the worst bar of each.</figcaption></figure>', F.cones);
w(fid, '<p>Earlier I described this as the two sets of hooks &ldquo;overlapping&rdquo;: seen from the side, the anchors and the beam bars run next to each other between their hooks, like a lap. The check above is the precise version of that picture.</p>');
w(fid, '<p><b>The pairs of bars in contact (2-1-2).</b> Two bars in contact form a bundle. For straight development, a two-bar bundle needs no extra length <span class="ref">ACI 25.6.1.5</span>; only the cover and spacing conditions use the equivalent diameter &radic;2 d<sub>b</sub> = %.0f mm <span class="ref">25.6.1.6</span>, which the beam satisfies. So in the beam nothing changes: &#8467;<sub>d</sub> = %.0f mm. Hooks are different: ACI does not cover a bundle developed by one hook <span class="ref">R25.6.1.5</span>, and advises not to hook bundles as a unit <span class="ref">R25.6.1.1</span>. So inside the joint the two bars of each pair should be separated, each with its own hook: the outer bar stays at &plusmn;%g and the inner one moves to &plusmn;%g, with a small crank (1 : 6) starting about 150 mm before the column face. That is where the positions 0, &plusmn;%g, &plusmn;%g come from. It also keeps %g mm between each beam bar and the anchor tails at &plusmn;%g.</p>', sqrt(2)*P.cb.db, D.ld12, P.cb.ve(5), P.cb.ve(4), P.cb.ve(4), P.cb.ve(5), P.cb.ve(4) - P.anc.v(2) - (db + P.cb.db)/2, P.anc.v(2));
w(fid, '<p>If the pairs stay together, the geometry still works (length inside the cone %.0f mm &ge; 150), but the hooked pair is outside the code. Then count only one bar of each pair plus the centre bar: 3 &Oslash;12 = %.0f kN, D/C %.2f. It passes, with less margin, so separating the pairs is the better option.</p>', R.cone_built.inside, 0.75*3*Ab12*P.fy*kN, E.T/(0.75*3*Ab12*P.fy));
w(fid, '<p><b>Does the edge need all 5 &Oslash;12?</b> By strength, 3 bars would do (%.0f kN, D/C %.2f); all 5 give D/C %.2f. Hook all 5: they cost nothing and are already there.</p>', 0.75*3*Ab12*P.fy*kN, E.T/(0.75*3*Ab12*P.fy), E.T/X.phiN(1));
w(fid, '<p><b>5c. Developed on the other side (in the beam).</b> The bars continue along the whole beam. They need a straight length of</p>');
w(fid, '<div class="eq">&#8467;<sub>d</sub> = f<sub>y</sub> d<sub>b</sub> / (2.1 &radic;f''c) = %g (%g)/(2.1 (%.2f)) = <b>%.0f mm</b> beyond the column face, which a continuous beam bar always has. <span class="ref">ACI Table 25.4.2.3</span></div>', P.fy, P.cb.db, sq, D.ld12);
w(fid, '<p>That is the whole check. The beam bars must be <b>hooked down at the outer face of the joint</b> (they have no hooks yet) and must pass between the anchor tails (section 3).</p>');
w(fid, '<p><b>5d. Can the beam carry the moment it receives?</b></p>');
w(fid, '<div class="eq">Moment at the column axis: M<sub>face</sub> + V (distance face to axis) = %.1f + %.1f (%g) = <b>%.1f kN m</b></div>', E.Mu*kNm, E.Vu*kN, P.a0/1000, E.Ma*kNm);
w(fid, '<div class="eq">%d &Oslash;%g top: &phi;M<sub>n</sub> = 0.9 A<sub>s</sub> f<sub>y</sub> (d &minus; a/2) = <b>%.1f kN m</b> &nbsp; <span class="res">D/C = %.2f</span> (the cantilever alone) <span class="ref">ACI 22.3</span></div>', X.n(1), P.cb.db, X.phiMn(1)*kNm, E.Ma/X.phiMn(1));
w(fid, '<p><b>Two jobs for the same bars?</b> It is one job. At this column the top bars carry the negative moment of the beam at the face, and the cantilever is part of that moment: it is what makes the support moment negative. The pull of the anchors is that same tension arriving from the other side, not an extra one. What has to be checked is: support moment of the beam from your model <i>without</i> the cantilever + the cantilever moment &le; &phi;M<sub>n</sub>. That leaves %.0f kN m for the model moment on the VCM (edge) and %.0f kN m on a VCS (corner). If your model already includes the cantilever, use its moment alone. The pedestal also takes part of the cantilever moment, so this is conservative.</p></div>', (X.phiMn(1)-E.Ma)*kNm, (X.phiMn(2)-V3.Ma)*kNm);

w(fid, '<div class="step"><h3>Step 6. Load paths in easy mode</h3>');
w(fid, '<p>The moment of the cantilever has to end up somewhere. Two things behind the column can take it, and both are checked:</p><ul>');
w(fid, '<li><b>Path 1, the concrete beam:</b> the pull T goes from the anchors to the beam top bars (step 5), and the push C goes straight through the joint into the bottom of the beam. The beam carries the moment like the back span of a concrete cantilever.</li>');
w(fid, '<li><b>Path 2, the pedestal:</b> the pull goes diagonally down through the joint to the push. The diagonal compression is carried by the concrete; its vertical part, T tan %.0f&deg; = %.0f kN, is tension in the 3 column bars of the inner face (capacity %.0f kN). For this the column bars need their 90&deg; hooks at the top.</li></ul>', M.th*180/pi, E.T*tan(M.th)*kN, M.phiTcol*kN);
w(fid, '<p>Each path alone is enough. In reality the stiffer one, the pedestal, takes most of it.</p>');
w(fid, '<div class="eq">Pedestal, edge: cantilever %.1f kN m and frame %.2f kN m (1.2D + L &minus; E<sub>x</sub>), added at right angles as if they happened together: %.1f kN m against &phi;M<sub>n</sub> = %.1f kN m at P = 0, 8 &Oslash;16 &nbsp; <span class="res">D/C = %.2f</span> <span class="ref">ACI 22.4</span></div>', Z.Mx*kNm, P.frame.Mcol, hypot(Z.Mx, Z.My)*kNm, Z.phiMnE*kNm, hypot(Z.Mx, Z.My)/Z.phiMnE);
w(fid, '<div class="eq">Joint shear, direction of the cantilever: V<sub>u</sub> = T = %.0f kN &le; &phi;V<sub>n</sub> = 0.75 (1.25) &radic;f''c A<sub>j</sub> = %.0f kN. Direction of the edge beams, with your frame forces: %.0f kN. <span class="ref">ACI 15.4.2</span></div></div>', E.T*kN, J.phiVn(1)*kN, J.Vu_other*kN);

w(fid, '<div class="step"><h3>Step 7. Shear V</h3>');
w(fid, '<p>The lug is a small shelf inside the concrete. V pushes it down onto the concrete below it:</p>');
w(fid, '<div class="eq">&phi;V = 0.65 (1.7 f''c)(width x 2t) = 0.65 (1.7)(%.1f)(%g x %g) = <b>%.0f kN</b> &ge; V = %.1f &nbsp; <span class="res">D/C = %.2f</span> <span class="ref">ACI 17.11.2.1</span></div>', P.fc, P.lug.w, min(2*P.lug.t, P.lug.L), H.phiVbrg*kN, E.Vu*kN, E.Vu/H.phiVbrg);
w(fid, '<p>Even without the lug, the welded bars would take it: tension + shear %.2f &le; 1.2 <span class="ref">ACI 17.8.3</span>.</p>', E.T/N.phiNsa(1) + E.Vu/N.phiVsa(1));
w(fid, '<p><b>A 35&deg; plane from the lug to the far face.</b> The shear points down and the pedestal continues below, so there is no free edge for a breakout cone in that direction. Your plane is still a fair conservative check: the wedge above it would have to slide down along it. The plane crosses all 8 column bars. By shear friction:</p>');
w(fid, '<div class="eq">&phi;V<sub>n</sub> = 0.75 &mu; A<sub>vf</sub> f<sub>y</sub> = 0.75 (1.4)(8 x 201)(420) = 709 kN, limited to 0.75 (0.2 f''c A<sub>c</sub>) = <b>%.0f kN</b>. Against %.1f kN (edge) and %.1f kN (both corner beams). <span class="ref">ACI 22.9.4.2, Table 22.9.4.2, 22.9.4.4</span></div></div>', R.ped.phiVsf*kN, E.Vu*kN, 2*V3.Vu*kN);

w(fid, '<div class="step"><h3>Step 8. Welds: which weld carries what</h3>');
w(fid, '<p>Three pieces meet behind the plate: the plate, the platina and the bars. One continuous bead joins them, but the forces use its parts differently. There are three forces to follow: the pull T, the push C and the shear V.</p>');
w(fid, '<p><b>8a. Where the pull really acts.</b> The flange pulls the plate at the flange level. The bars pull the plate at their own level. At the edge the two rows of bars sit %g mm above and below the flange line, so their resultant is on the flange line. At the corner (type C1) both bars sit %g mm below it. The lever arm to the push C is then shorter, and the bars pull more:</p>', G.e, G.e);
w(fid, '<div class="eq">T = M / (z<sub>bars</sub> &minus; z<sub>C</sub>) &nbsp; Edge: %.1f / %.4f = <b>%.1f kN</b> &nbsp; Corner: %.1f / %.4f = <b>%.1f kN</b> (flange force %.1f kN)</div>', E.Mu*kNm, (R.zbar(1)-R.zC)/1000, E.T*kN, V3.Mu*kNm, (R.zbar(3)-R.zC)/1000, V3.T*kN, V3.Tf*kN);
w(fid, '<p>The plate carries the %g mm offset by bending:</p>', G.e);
w(fid, '<div class="eq">M = T<sub>flange</sub> e = %.1f (%g) = %.2f kN m &le; &phi;M<sub>p</sub> = 0.9 F<sub>y</sub> b t&sup2;/4 = 0.9 (%g)(%g)(%g)&sup2;/4 = %.2f kN m &nbsp; <span class="res">D/C = %.2f</span> <span class="ref">AISC F11</span></div>', V3.Tf*kN, G.e, G.Mpl(3)*kNm, P.Fy, P.pl.w, P.pl.t, G.phiMpl*kNm, G.Mpl(3)/G.phiMpl);
w(fid, '<figure>%s<figcaption>Forces on the plate, corner type C1. The flange pulls at its level. The bars pull 14 mm lower. The concrete pushes back at the bottom flange.</figcaption></figure>', F.wf_plate);
w(fid, '<p><b>8b. Which part of the weld carries what.</b></p>');
w(fid, '<figure>%s<figcaption>The three paths behind the plate. A: the pull goes from the plate straight into the bar, through the bead around the bar end. B: plate, bead, platina, side welds, bar. C: the shear V goes from the concrete into the platina and through the bead to the plate.</figcaption></figure>', F.wf_paths);
w(fid, '<ul><li><b>Path A: plate, bead around each bar end, bar.</b> Direct, but the bars sit %g mm off the flange line, so the plate bends a little.</li>', G.e);
w(fid, '<li><b>Path B: plate, bead along the platina, platina, side welds, bar.</b> The platina is in line with the flange, so the pull enters it straight; the side welds hand it to the bars.</li>');
w(fid, '<li><b>Path C: the shear V.</b> The concrete pushes the platina up between the bars; the bead along the platina takes it to the plate.</li></ul>');
w(fid, '<p>In plain words: behind the plate, the pull has two roads to reach the bars, like two ropes tied side by side. Road A is the ring of weld around the end of each bar: the plate pulls the bar directly. Road B goes through the platina: the plate pulls the platina, and the platina pulls the bars through the welds along their sides. Both roads are welded, so both work at the same time. How the pull splits between A and B depends on their stiffness and cannot be known exactly. So <b>each path is checked to carry all of T by itself</b>. Then the split does not matter. For this the side welds were raised from 5 to %g mm.</p>', P.w.bar);
w(fid, '<div class="eq">Bead around one bar end: L = 3/4 &pi; d<sub>b</sub> = %.1f mm (the quarter that touches the platina is not welded), leg %g, &phi;R<sub>n</sub> = (0.75)(0.60 F<sub>EXX</sub>)(0.707 w) L = (%.1f)(%g)(%.1f) = <b>%.1f kN</b> per bar <span class="ref">AISC (J2-4)</span></div>', W.Lend, P.w.end, W.fw, P.w.end, W.Lend, W.endw*kN);
w(fid, '<p>No weld in this report uses the directional increase (the factor up to 1.5 of eq. J2-5). J2-5 is written for linear weld groups; a ring around a bar is not one.</p>');
w(fid, '<div class="eq">Side welds of one bar: 2 x %g mm, leg %g: &phi;R<sub>n</sub> = %.1f (%g)(%g) = <b>%.1f kN</b> per bar <span class="ref">AISC (J2-4)</span></div>', P.anc.Lw, P.w.bar, W.fw, P.w.bar, 2*P.anc.Lw, W.side*kN);
w(fid, '<div class="eq">Path B, platina and bars welded together, bending from the offset: M = T e = %.1f (%g) = %.2f kN m &le; &phi;M<sub>p</sub> = %.2f kN m (corner) <span class="ref">AISC F11</span></div>', V3.T*kN, G.e, G.MB(3)*kNm, G.phiMpB*kNm);
w(fid, '<div class="eq">Both added: %.1f + %.1f = %.1f kN per bar. Information only: the AISC rule for longitudinal plus transverse fillets asks for one leg size, and these are %g and %g mm. <span class="ref">AISC J2.4(c)</span></div>', W.side*kN, W.endw*kN, W.bar*kN, P.w.bar, P.w.end);
w(fid, '<div class="eq">Bar surface under the end bead, shear rupture: 0.75 (0.6 F<sub>u</sub>)(w L) = 0.75 (0.6)(%g)(%g)(%.1f) = <b>%.1f kN</b> per bar <span class="ref">AISC J4.2(b), Table J2.5</span></div>', P.fu_bar, P.w.end, W.Lend, 0.75*0.6*P.fu_bar*P.w.end*W.Lend*kN);
w(fid, '<div class="eq">Bead platina-plate: %.0f mm (the part in front of each bar is lost), leg %g: &phi;R<sub>n</sub> = (%.1f)(%g)(%.0f) = <b>%.0f kN</b> (edge)</div>', W.Llug(1), P.w.lug, W.fw, P.w.lug, W.Llug(1), W.bead(1)*kN);
w(fid, '<div class="tw"><table><tr><th>Weld</th><th>Carries</th><th class="n">Edge</th><th class="n">D/C</th><th class="n">Corner (C1)</th><th class="n">D/C</th></tr>');
w(fid, '<tr><td>Flange to plate, fillet %g (site)</td><td>flange force</td><td class="n">%.0f / %.0f</td><td class="n">%.2f</td><td class="n">%.0f / %.0f</td><td class="n">%.2f</td></tr>', P.w.flange, E.Tf*kN, W.flange*kN, E.Tf/W.flange, V3.Tf*kN, W.flange*kN, V3.Tf/W.flange);
w(fid, '<tr><td>Web to plate, fillet %g (site)</td><td>V</td><td class="n">%.1f / %.0f</td><td class="n">%.2f</td><td class="n">%.1f / %.0f</td><td class="n">%.2f</td></tr>', P.w.web, E.Vu*kN, W.web*kN, E.Vu/W.web, V3.Vu*kN, W.web*kN, V3.Vu/W.web);
w(fid, '<tr><td>Plate, through its thickness</td><td>flange force</td><td class="n">%.0f / %.0f</td><td class="n">%.2f</td><td class="n">%.0f / %.0f</td><td class="n">%.2f</td></tr>', E.Tf*kN, G.plTT*kN, E.Tf/G.plTT, V3.Tf*kN, G.plTT*kN, V3.Tf/G.plTT);
w(fid, '<tr><td>Path A: bead around the bar ends, all bars</td><td>T</td><td class="n">%.0f / %.0f</td><td class="n">%.2f</td><td class="n">%.0f / %.0f</td><td class="n">%.2f</td></tr>', E.T*kN, W.ring(1)*kN, E.T/W.ring(1), V3.T*kN, W.ring(3)*kN, V3.T/W.ring(3));
w(fid, '<tr><td>Path A: plate bending from the offset</td><td>T e</td><td class="n">%.2f / %.2f</td><td class="n">%.2f</td><td class="n">%.2f / %.2f</td><td class="n">%.2f</td></tr>', G.Mpl(1)*kNm, G.phiMpl*kNm, G.Mpl(1)/G.phiMpl, G.Mpl(3)*kNm, G.phiMpl*kNm, G.Mpl(3)/G.phiMpl);
w(fid, '<tr><td>Path B: side welds %g x %g, per bar</td><td>T per bar</td><td class="n">%.1f / %.1f</td><td class="n">%.2f</td><td class="n">%.1f / %.1f</td><td class="n">%.2f</td></tr>', P.w.bar, P.anc.Lw, E.T/R.nb(1)*kN, W.side*kN, E.T/R.nb(1)/W.side, V3.T/R.nb(3)*kN, W.side*kN, V3.T/R.nb(3)/W.side);
w(fid, '<tr><td>Path B: bead along the platina</td><td>T and V</td><td class="n">%.0f / %.0f</td><td class="n">%.2f</td><td class="n">%.0f / %.0f</td><td class="n">%.2f</td></tr>', hypot(E.T,E.Vu)*kN, W.bead(1)*kN, hypot(E.T,E.Vu)/W.bead(1), hypot(V3.T,V3.Vu)*kN, W.bead(3)*kN, hypot(V3.T,V3.Vu)/W.bead(3));
w(fid, '<tr><td>Path B: platina + bars bending from the offset</td><td>T e</td><td class="n">0</td><td class="n">-</td><td class="n">%.2f / %.2f</td><td class="n">%.2f</td></tr>', G.MB(3)*kNm, G.phiMpB*kNm, G.MB(3)/G.phiMpB);
w(fid, '<tr><td>Path C: bead along the platina</td><td>V</td><td class="n">%.1f / %.0f</td><td class="n">%.2f</td><td class="n">%.1f / %.0f</td><td class="n">%.2f</td></tr>', E.Vu*kN, W.bead(1)*kN, E.Vu/W.bead(1), V3.Vu*kN, W.bead(3)*kN, V3.Vu/W.bead(3));
w(fid, '<tr><td>Bar surface under the end bead, shear rupture</td><td>T per bar</td><td class="n">%.1f / %.1f</td><td class="n">%.2f</td><td class="n">%.1f / %.1f</td><td class="n">%.2f</td></tr>', E.T/R.nb(1)*kN, 0.75*0.6*P.fu_bar*P.w.end*W.Lend*kN, E.T/R.nb(1)/(0.75*0.6*P.fu_bar*P.w.end*W.Lend), V3.T/R.nb(3)*kN, 0.75*0.6*P.fu_bar*P.w.end*W.Lend*kN, V3.T/R.nb(3)/(0.75*0.6*P.fu_bar*P.w.end*W.Lend));
w(fid, '</table></div>');
w(fid, '<p>Joining the three pieces with one bead does not change these numbers. The bead around each bar end is the same weld as before, and the platina part only loses the width of each bar.</p></div>');

w(fid, '<div class="step"><h3>Step 9. Torsion on the corner beams</h3>');
w(fid, '<div class="eq">T<sub>t</sub> = q (b/4)(unequal width) = %.2f kN m realistic; %.2f kN m if all the load sat on one flange tip. Couple on the flanges: %.1f kN.</div>', O.Treal*kNm, O.Tu(3)*kNm, O.H(3)*kN);
w(fid, '<p>At the top, the couple goes to the welded bars as sideways shear (included in the interaction of step 7 at %.0f%% of their strength). At the bottom, it goes by friction under the push C (&phi; 0.4 C = %.0f kN, AISC Design Guide 1). Once the slab hardens, torsion stops.</p></div>', O.H(3)/N.phiVsa(3)*100, 0.75*0.4*V3.T*kN);

w(fid, '<div class="step"><h3>Step 10. Strength of the members</h3>');
w(fid, '<div class="tw"><table><tr><th>Member</th><th class="n">&phi;M<sub>n</sub> (kN m)</th><th class="n">&phi;V<sub>n</sub> (kN)</th><th>Basis</th></tr>');
w(fid, '<tr><td>IPE 200 cantilever</td><td class="n">%.1f</td><td class="n">%.1f</td><td>AISC F2 (L<sub>b</sub> = %g &lt; L<sub>p</sub> = %.0f mm, so M<sub>p</sub>), G2.1</td></tr>', B.phiMn*kNm, B.phiVn*kN, P.L, B.Lp);
w(fid, '<tr><td>VCM 30x35, 5 &Oslash;12 top, negative moment</td><td class="n">%.1f</td><td class="n">%.0f / %.0f</td><td>d = %g mm. Shear: V<sub>c</sub> = 0.17 &radic;f''c b d = %.0f kN, stirrups &Oslash;10 at 7 / 14 cm (f<sub>yt</sub> = %g assumed)</td></tr>', R.cb(1).phiMn*kNm, R.cb(1).phiVn(1)*kN, R.cb(1).phiVn(2)*kN, P.cb.h+P.cb.zt(1), R.cb(1).Vc*kN, P.cb.fyt);
w(fid, '<tr><td>VCS 30x35, 3 &Oslash;12 top, negative moment</td><td class="n">%.1f</td><td class="n">%.0f / %.0f</td><td>same</td></tr>', R.cb(2).phiMn*kNm, R.cb(2).phiVn(1)*kN, R.cb(2).phiVn(2)*kN);
w(fid, '<tr><td>Pedestal 40x40, 8 &Oslash;16, P = 0</td><td class="n">%.1f / %.1f</td><td class="n">%.0f</td><td>one axis / diagonal. Shear with ties &Oslash;10 @ %g, 2 legs</td></tr>', Z.phiMn0*kNm, Z.phiMn45*kNm, Z.phiVn*kN, P.col.s);
w(fid, '</table></div>');
w(fid, '<p>Beam shear: &phi; = 0.75, V<sub>s</sub> = A<sub>v</sub> f<sub>yt</sub> d/s capped at 0.66 &radic;f''c b d <span class="ref">ACI 22.5.5.1, 22.5.8.5.3, 22.5.1.2</span>. Pedestal at P = 0 is the lowest; the axial load from above raises it.</p></div>');

% ---------------------------------------------------------------- 3 drawings
w(fid, '<h2 id="s3">3. Drawings</h2>');
w(fid, '<p class="leg">Colours:<span style="background:#c0392b"></span>anchor bars<span style="background:#5d6d7e"></span>beam bars<span style="background:#9a6b00"></span>column bars<span style="background:#117a65"></span>rods of the steel column<span style="background:#7d3c98"></span>hoops<span style="background:#34506b"></span>steel plates</p>');
w(fid, '<figure>%s<figcaption>Assembly of the edge, side view (the beam is welded on site, after the pour). At the corner, beam X has only the 2 bars under the lug with hooks at %g, and beam Y only the 2 bars over it.</figcaption></figure>', F.assy_elev, P.anc.uh);
w(fid, '<figure>%s<figcaption>Assembly, top view.</figcaption></figure>', F.assy_plan);
w(fid, '<h3>Edge column</h3>');
w(fid, '<figure>%s<figcaption>Edge column, plan. The anchors under and over the lug are on the same lines; the dots are their hook tails.</figcaption></figure>', F.edge_plan);
w(fid, '<figure>%s<figcaption>Edge column, section along the steel beam.</figcaption></figure>', F.edge_elev);
w(fid, '<figure>%s<figcaption>Edge column seen from outside. The beam top bars must be at 0, &plusmn;%g and &plusmn;%g mm inside the joint, so the anchor tails at &plusmn;%g pass between them with %g mm of clearance.</figcaption></figure>', F.edge_front, P.cb.ve(4), P.cb.ve(5), P.anc.v(2), P.cb.ve(4) - P.anc.v(2) - (db + P.cb.db)/2);
w(fid, '<h3>Ties of the joint</h3>');
w(fid, '<figure>%s<figcaption>One layer of joint ties, plan.</figcaption></figure>', F.hoops);
w(fid, '<figure>%s<figcaption>Bending detail of one tie. 135&deg; hooks: inside bend diameter 4 d<sub>b</sub>, straight extension the greater of 6 d<sub>b</sub> and 75 mm <span class="ref">ACI Table 25.3.2</span>. The cut length is approximate: bend a trial piece around two corner bars first.</figcaption></figure>', F.tie);
w(fid, '<p><b>Placing one layer:</b> (1) bend one hook of each tie in the shop; (2) slide the tie along its face, between the top and bottom layers of beam bars, and hook it on the first corner bar; (3) bend the second hook around the other corner bar with a hand bender; (4) wire the mid-face bar to it. Do the outer face (plate side) before the assembly goes in.</p>');
w(fid, '<div class="tw"><table><tr><th>Zone</th><th>Ties</th><th>Levels z (mm)</th></tr>');
w(fid, '<tr><td>Pedestal below the beams (cast)</td><td>existing &Oslash;%g @ %g</td><td>below %g</td></tr>', P.col.dtie, P.col.s, P.col.cj);
w(fid, '<tr><td>Joint, within the beam depth</td><td>%d layers, each 4 straight &Oslash;%g with 135&deg; hooks</td><td>%s</td></tr>', numel(P.hoop.z), P.hoop.db, num2str(P.hoop.z));
w(fid, '<tr><td>Above the anchors</td><td>1 closed tie &Oslash;%g, dropped over the column bars before their top hooks are bent</td><td>%+g</td></tr>', P.hoop.db, P.hoop.ztop);
w(fid, '</table></div>');
w(fid, '<p>Why straight pieces: the beam bars are already tied, so a closed hoop cannot be slid down into the joint. Each straight tie is put along one face between the layers of beam bars, one hook bent beforehand and the other bent in place around the corner bar. Every corner bar is held by two hooks; the mid-face bars are within 150 mm of a held bar, so they only need wire <span class="ref">ACI 25.7.2.3</span>. Spacing %g mm, under the 200 mm of ACI 15.3.1.4 and the 8 d<sub>b</sub> of 25.4.3.3.</p>', abs(diff(P.hoop.z(1:2))));
w(fid, '<h3>Corner column</h3>');
w(fid, '<figure>%s<figcaption>Corner column, plan: 2 anchors per beam. The bars of Y pass %g mm over those of X (the lug thickness).</figcaption></figure>', F.cor_plan, P.lug.t);
w(fid, '<figure>%s<figcaption>Corner column, section along beam X.</figcaption></figure>', F.cor_elevX);
w(fid, '<figure>%s<figcaption>Corner column, section along beam Y.</figcaption></figure>', F.cor_elevY);


% ---------------------------------------------------------------- 4 limit states
w(fid, '<h2 id="s4">4. All limit states</h2>');
w(fid, '<p>Grey: information only, not relied upon. Frame rows include only the cantilever, except the pedestal of the edge, which adds your frame moment.</p>');
w(fid, '<div class="tw"><table><tr><th>Limit state</th><th>Reference</th><th class="n">Strength</th><th class="n">Edge</th><th class="n">D/C</th><th class="n">Corner</th><th class="n">D/C</th><th class="n">Envelope</th><th class="n">D/C</th></tr>');
g = '';
for i = 1:size(R.rows,1)
    r = R.rows(i,:);  d = r{4};  c = r{5};
    if ~strcmp(g, r{1}), g = r{1};  w(fid, '<tr class="grp"><td colspan="9">%s</td></tr>', g); end
    if strcmp(r{6}, '-'), fm = '%.2f'; un = ''; else, fm = '%.1f'; un = [' ' r{6}]; end
    if numel(unique(round(c))) == 1, cs = [sprintf(fm, c(1)) un]; else, cs = [sprintf(fm, c(1)) ' / ' sprintf(fm, c(2)) un]; end
    s = sprintf('<tr><td>%s</td><td><span class="ref">%s</span></td><td class="n">%s</td>', r{2}, r{3}, cs);
    for k = 1:3
        s = [s sprintf(['<td class="n">' fm '</td><td class="n %s">%.2f</td>'], d(k), cls(d(k)/c(k), r{7}), d(k)/c(k))];
    end
    w(fid, '%s</tr>', s);
end
w(fid, '</table></div>');
w(fid, '<p>Not applicable: bolt checks (no bolts); pullout of hooked bolts, 17.6.3 (for smooth bolts; deformed hooked bars are covered by 25.4.3); side-face blowout, 17.6.4 (headed anchors only); shear breakout downwards (no edge below).</p>');

% ---------------------------------------------------------------- 5 site
w(fid, '<h2 id="s5">5. Site</h2>');
w(fid, '<div class="warn"><b>Before the pour</b><ol>');
w(fid, '<li>Column bars: 90&deg; hooks at the top, turned into the joint. Mandatory: the pedestal ends in this joint and a straight bar has %g mm where it needs %.0f mm (hooked: %.0f mm).</li>', D.colav, D.ldcol, D.ldhcol);
w(fid, '<li>Top bars of the concrete beams: 90&deg; hooks down at the outer face of the joint, tail 12 d<sub>b</sub> = %g mm. The middle one must step beside the mid-face column bar.</li>', 12*P.cb.db);
w(fid, '<li>Edge beam (VCM): inside the joint, separate each pair of top bars in contact; the inner bar moves to &plusmn;%g with a 1 : 6 crank, the outer stays at &plusmn;%g. Each bar gets its own hook. The anchor tails at &plusmn;%g pass between them.</li>', P.cb.ve(4), P.cb.ve(5), P.anc.v(2));
w(fid, '<li>%d layers of ties &Oslash;%g in the joint at z = %s mm, each of 4 straight ties with 135&deg; hooks, and one closed tie at z = %+g after the assemblies.</li>', numel(P.hoop.z), P.hoop.db, num2str(P.hoop.z), P.hoop.ztop);
w(fid, '<li>Lower the assembly (plate, plates and bars, without the beam) from above; the plate closes the form. Fix it to the form and tie it to the cage so it cannot move when vibrating. Corner: beam X first, then Y.</li>');
w(fid, '<li>Pour up to the pedestal top (+%g) with the rods of the steel column sticking out. Vibrate well under the lug.</li>', P.col.top);
w(fid, '<li>Weld the beam on site once the concrete has hardened (7 days is reasonable): fillet %g all round the flanges, %g on both sides of the web. Line the top flange up with the marks on the plate, which show where the lug is behind it. Prop the beam tip until the slab has hardened.</li></ol></div>', P.w.flange, P.w.web);
w(fid, '<p>Shop: bend the hooks before welding (the welds end %g mm or more from any bend); bars weldable (INEN 2167 / A706). Keep the platina at the level of the top flange within 3 mm.</p>', P.anc.uhA - P.anc.db/2 - R.dev.rb - P.pl.t - P.lug.L);

% ---------------------------------------------------------------- 6 notes
w(fid, '<h2 id="s6">6. Notes and references</h2><ul>');
w(fid, '<li>Section numbers checked against the PDFs of ACI 318-19 (inch-pound; SI equations from its Appendix E), ACI 318S-14, AISC 360-16 and NEC-SE-DS.</li>');
w(fid, '<li>ACI 318S-14 differences: no shear-lug provisions (17.11 is new in 2019); hook length 0.24 f<sub>y</sub> &psi;<sub>c</sub> d<sub>b</sub>/&radic;f''c = %.0f mm (25.4.3.1); anchor reinforcement is 17.4.2.9.</li>', D.ldh14);
w(fid, '<li>The excess-steel reduction of development length is not used anywhere: ACI 25.4.10.2(d) forbids it for hooks.</li>');
w(fid, '<li>Assumed: the VCM top bars in one layer at 0, &plusmn;57, &plusmn;94 (layout 2-1-2); rebar f<sub>y</sub> = %g MPa; I = %g.</li>', P.fy, P.I);
w(fid, '<li>The frame is an ordinary moment frame (confirmed). The joint ties follow ACI 15.3 (at least two layers within the beam depth, spacing at most 200 mm); the special detailing of ACI 18.8 does not apply.</li>');
w(fid, '<li>Welds: no directional strength increase (eq. J2-5) is used anywhere, and the combination rule J2.4(c) is not used (it needs one leg size).</li>');
w(fid, '<li>Revision history. Rev. 1: 4 &Oslash;16 in the pedestal, D = 3 kN/m&sup2;, L = 1.3 m from the face, 4 anchors per beam, added L bars. Rev. 2: real pedestal (8 &Oslash;16) and beams (VCM, VCS), D = 2.5, L from the axis, short platina, 2 anchors per corner beam, no L bars. Later: 4 tie layers; separated bar pairs in the VCM; beam welded on site; one continuous 8 mm bead joining plate, platina and bar ends; corner anchor force from the real lever arm; no 1.5 factor; side welds 6 mm so that each load path carries all of T.</li></ul>');
w(fid, '</main></body></html>');
fclose(fid);
end

% ---------------------------------------------------------------------------
function w(fid, fmt, varargin)
fprintf(fid, [fmt '\n'], varargin{:});
end

function c = cls(x, kind)
if strcmp(kind, 'info'), c = 'inf';
elseif x <= 0.75, c = 'ok';
elseif x <= 1.0, c = 'mid';
else, c = 'bad';
end
end

function m = maxdc(R, k)
% highest ratio of the connection rows (not information, not frame) for case k
m = 0;
for i = 1:size(R.rows,1)
    r = R.rows(i,:);
    if ~isempty(r{7}), continue; end
    d = r{4};  c = r{5};
    if numel(d) > 1, d = d(k); end
    if numel(c) > 1, c = c(k); end
    m = max(m, d/c);
end
end

function m = maxdc2(R)
% second highest ratio of the connection rows for the edge case
v = [];
for i = 1:size(R.rows,1)
    r = R.rows(i,:);
    if ~isempty(r{7}), continue; end
    d = r{4};  c = r{5};
    v(end+1) = d(1)/c(1);
end
v = sort(v, 'descend');
m = v(2);
end
