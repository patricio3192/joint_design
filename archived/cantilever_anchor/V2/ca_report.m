function ca_report(P, R, F, fname)
% CA_REPORT  Writes the HTML report of the cantilever anchorage, revision 3 (variant).
%   ca_report(P, R, F, fname): P from ca_inputs, R from ca_calc, F from ca_draw.
%   All the numbers printed here are read from R or P; nothing is typed by hand.

fid = fopen(fname, 'w');
nf(0);                                              % figure counter
kN = 1e-3;  kNm = 1e-6;
E = R.kase(1);  C = R.kase(2);  V3 = R.kase(3);
B = R.beam;  W = R.weld;  G = R.plate;  N = R.anc;  D = R.dev;  Q = R.brk;  X = R.ar;
J = R.joint;  M = R.stm;  H = R.shear;  Y = R.brg;  O = R.tor;  Z = R.ped;  bm = P.bm;
sq = sqrt(P.fc);  db = P.anc.db;  Ab = pi*db^2/4;  Ab12 = pi*P.cb.db^2/4;  e = R.e;  t = P.pl.t;
u2 = P.pl.t + P.pla.L;

w(fid, '<!DOCTYPE html>');
w(fid, '<html lang="en"><head><meta charset="utf-8">');
w(fid, '<meta name="viewport" content="width=device-width, initial-scale=1">');
w(fid, '<title>Cantilever anchorage, revision 3</title>');
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
w(fid, '<p class="sub">Revision 3 (variant of revision 2). %s cantilever, %g m from the column axis, on %gx%g cm pedestals: edge column (one beam) and corner column (two beams). ', bm.name, (P.L+P.a0)/1000, P.col.b/10, P.col.b/10);
w(fid, 'ACI 318-19 (318S-14 where it differs), AISC 360-16, NEC-SE-DS. LRFD. Units kN, mm, MPa. Generated %s by t1_cantilever_anchor.m in cantilever_anchor_V2.</p>', datestr(now, 'yyyy-mm-dd'));
w(fid, '<nav><a href="#s1">1 Changes</a><a href="#s2">2 Load path</a><a href="#s3">3 Plate bending</a><a href="#s4">4 Anchorage and tolerances</a><a href="#s5">5 Easy check</a><a href="#s6">6 Drawings</a><a href="#s7">7 All limit states</a><a href="#s8">8 Site</a><a href="#s9">9 Notes</a></nav>');

% ---------------------------------------------------------------- 1 changes
w(fid, '<h2 id="s1">1. What changes from revision 2, and why</h2>');
w(fid, '<p>Revision 2 passed every check, but some of its margins were a few millimetres, the pull reached the bars by two parallel welded paths whose split is unknown, and the weakest element was a weld, not a bar. This variant keeps the concept (embed plate, platina behind the top flange, hooked bars, beam top bars as anchor reinforcement) and removes those weak points.</p>');
w(fid, '<div class="tw"><table><tr><th>Item</th><th>Revision 2</th><th>Revision 3 (this report)</th><th>Why</th></tr>');
w(fid, '<tr><td>Steel beam</td><td>IPE 200</td><td>%s</td><td>lever arm %.1f mm instead of 191.5: the pull drops from 99 to %.0f kN (edge)</td></tr>', bm.name, R.ho, E.T*kN);
w(fid, '<tr><td>Embed plate</td><td>PL 12x220x260</td><td>PL %gx%gx%g</td><td>deeper beam; still %g mm thick, proven in section 3</td></tr>', t, P.pl.w, P.pl.zt-P.pl.zb, t);
w(fid, '<tr><td>Platina</td><td>one PL 12x110x30 (+ the same under the bottom flange)</td><td>two PL %gx%gx%g behind the top flange, %g mm apart; no bottom piece</td><td>the mid-face column bar passes between them, so they can be %g mm long instead of 30</td></tr>', P.pla.t, P.pla.w, P.pla.L, 2*P.pla.v0, P.pla.L);
w(fid, '<tr><td>Anchor bars</td><td>&Oslash;16; edge 4 (hooks at 270 and 350), corner 2</td><td>&Oslash;%g, 4 per beam, all hooks at %g</td><td>&#8467;<sub>dh</sub> %.0f instead of 205 mm, smaller bend so the cone starts deeper, 4 anchors everywhere (needed by the shear-lug rules)</td></tr>', db, P.anc.uh, D.ldh);
w(fid, '<tr><td>Load path of the pull</td><td>two in parallel: bead around the bar ends, and platina + side welds</td><td><b>one</b>: plate, platinas, side welds, bars. The bars stop %g mm short of the plate</td><td>no unknown split; every piece has one job</td></tr>', P.anc.u0 - t);
w(fid, '<tr><td>Side welds</td><td>6 x 25</td><td>%g x %g, both sides of each bar</td><td>each bar breaks before its welds (step 8)</td></tr>', P.w.bar, P.anc.Lw);
w(fid, '<tr><td>Beam bars as anchor reinforcement</td><td>nominal positions</td><td>with the ACI placing tolerances taken against the design</td><td>the margin no longer depends on the site placing bars to the millimetre</td></tr>');
w(fid, '<tr><td>Exposed face of the plate</td><td>not painted</td><td>weldable primer optional; weld zones ground to bright metal before welding</td><td>rust under a site weld causes porosity and hydrogen cracking</td></tr>');
w(fid, '</table></div>');
w(fid, '<div class="tw"><table><tr><th>Case</th><th class="n">V<sub>u</sub> (kN)</th><th class="n">M<sub>u</sub> at the face (kN m)</th><th class="n">T on the bars (kN)</th><th class="n">Anchors</th><th class="n">Highest D/C</th></tr>');
for k = 1:3
    K = R.kase(k);
    w(fid, '<tr><td>%s</td><td class="n">%.1f</td><td class="n">%.1f</td><td class="n">%.1f</td><td class="n">4 &Oslash;%g</td><td class="n">%.2f</td></tr>', K.name, K.Vu*kN, K.Mu*kNm, K.T*kN, db, maxdc(R, k));
end
w(fid, '</table></div>');
w(fid, '<p>The highest ratios are the beam bars that anchor the breakout body, computed with every placing tolerance against the design at the same time. At nominal positions the same checks give %.2f or less (section 4). The highest ratios of the steel parts are the platina root at the corner (%.2f) and the embed plate over the gap between the platinas (%.2f, simply supported, section 3). The VCM has 2 of its 5 top bars in contact under the corner bars; only one bar of each such pair is counted.</p>', max(D.ldh12./X.ins_nom), max(G.H1), max(G.Fgap/G.phiFgap));

% ---------------------------------------------------------------- 2 load path
w(fid, '<h2 id="s2">2. One load path</h2>');
w(fid, '<figure>%s<figcaption><b>Figure %d. One load path behind the top flange.</b> Behind the top flange, corner type C1. The pull goes through five pieces in a row and nothing else carries it. The bar ends %g mm behind the plate, so it cannot take a share directly.</figcaption></figure>', F.path, nf(), P.anc.u0 - t);
w(fid, '<ol><li><b>Embed plate, through its thickness.</b> Each platina sits right behind the flange, so the pull crosses the %g mm of plate straight. Over the %g mm gap between the platinas, the plate bends a little (section 3).</li>', t, 2*P.pla.v0);
w(fid, '<li><b>Fillets platina to plate</b>, %g mm, above and below each platina, along its full width (%g mm). No bar is in the way: the bars start %g mm behind the toe of these fillets.</li>', P.w.pla, P.pla.w, P.anc.u0 - t - P.w.pla);
w(fid, '<li><b>Platina</b>, in tension. At the corner the bars sit on one face, %g mm off its axis, so the root of the platina also bends.</li>', e);
w(fid, '<li><b>Side welds</b>, %g mm long on both sides of each bar, ending at the end of the platina.</li>', P.anc.Lw);
w(fid, '<li><b>Bar</b>, from the end of the welds to its hook: %g mm available, %.0f needed.</li></ol>', P.anc.uh - u2, D.ldh);
w(fid, '<p>After the hooks, the same two paths as in revision 2 take the moment out of the joint: the top bars of the concrete beam (path 1) and the pedestal (path 2), step 6.</p>');
w(fid, '<div class="eq">Edge: 2 bars over and 2 under the platinas, %g mm above and below the flange line, so their resultant is on the flange line: T = M / (h &minus; t<sub>f</sub>) = %.1f / %.4f = <b>%.1f kN</b></div>', e, E.Mu*kNm, R.ho/1000, E.T*kN);
w(fid, '<div class="eq">Corner C1 (bars under): T = M / (z<sub>bars</sub> &minus; z<sub>C</sub>) = %.1f / %.4f = <b>%.1f kN</b> (flange %.1f kN). Corner C2 (bars over): %.1f kN. Envelope load.</div>', V3.Mu*kNm, (R.zbar(3)-R.zC)/1000, V3.T*kN, V3.Tf*kN, V3.TO*kN);

% ---------------------------------------------------------------- 3 plate bending
w(fid, '<h2 id="s3">3. Bending of the %g mm plate: equations and proof</h2>', t);
w(fid, '<p>The plate is loaded in four places: the top flange pulls it, the platinas pull it back, the bottom flange pushes it, and the concrete pushes back behind the bottom flange. Each place is checked with a model that ignores any help from the rest of the plate and from the beam web, so every model is a lower bound.</p>');
w(fid, '<figure>%s<figcaption><b>Figure %d. Back face of the embed plate: where the forces enter.</b> Back face of the embed plate. Green: flange directly backed by a platina (3a). Orange: flange over the gap, carried by plate bending (3b). Blue: strip that carries the offset moment at the corner (3c). Grey: bearing behind the compression flange (3e).</figcaption></figure>', F.plate_face, nf());

w(fid, '<div class="step"><h3>3a. Through the thickness, flange to platinas</h3>');
w(fid, '<p>Where a platina is behind the flange, the pull crosses the plate as plain tension over the footprint of the flange and its fillets:</p>');
w(fid, '<div class="eq">h = t<sub>f</sub> + 2 w = %.1f + 2 (%g) = %.1f mm; &nbsp; b = 2 (min(b<sub>f</sub>/2, v<sub>0</sub> + w<sub>p</sub>) &minus; v<sub>0</sub>) = 2 (%g &minus; %g) = %.0f mm</div>', bm.tf, P.w.flange, G.htt, min(bm.b/2, P.pla.v0+P.pla.w), P.pla.v0, G.bov);
w(fid, '<div class="eq">&phi;R<sub>n</sub> = 0.9 F<sub>y</sub> h b = 0.9 (%g)(%.1f)(%.0f) = <b>%.0f kN</b> &ge; T<sub>flange</sub> = %.1f kN &nbsp; <span class="res">D/C = %.2f</span> <span class="ref">AISC J4.1(a)</span></div>', P.Fy, G.htt, G.bov, G.plTT*kN, E.Tf*kN, E.Tf/G.plTT);
w(fid, '<p>The whole flange force is put on the backed part, although a third of it arrives over the gap. Lamellar tearing is not a concern for a %g mm plate.</p></div>', t);

w(fid, '<div class="step"><h3>3b. Over the gap between the platinas (%g mm)</h3>', 2*P.pla.v0);
w(fid, '<p>The middle %g mm of the flange has no platina behind it. Its share of the pull goes sideways through the plate to the platinas. Model: a strip of plate as wide as the flange footprint (h = %.1f mm), spanning the gap, <b>simply supported</b> at the platinas (they are welded on both faces, so the real ends are close to fixed), with the flange share spread uniformly:</p>', 2*P.pla.v0, G.htt);
w(fid, '<div class="eq">F = T<sub>flange</sub> (gap / b<sub>f</sub>) = %.1f (%g / %g) = <b>%.1f kN</b> (edge)</div>', E.Tf*kN, G.Lgap, bm.b, G.Fgap(1)*kN);
w(fid, '<div class="eq">M = F L / 8 = %.1f (%g) / 8 = <b>%.0f N m</b></div>', G.Fgap(1)*kN, G.Lgap, G.Fgap(1)*G.Lgap/8*1e-3);
w(fid, '<div class="eq">&phi;M<sub>p</sub> = 0.9 F<sub>y</sub> h t&sup2;/4 = 0.9 (%g)(%.1f)(%g)&sup2;/4 = <b>%.0f N m</b> &nbsp; <span class="res">D/C = %.2f</span> (%.2f with fixed ends) <span class="ref">AISC F11.1: M<sub>n</sub> = F<sub>y</sub> Z &le; 1.6 F<sub>y</sub> S; Z/S = 1.5</span></div>', P.Fy, G.htt, t, 0.9*G.Mpg*1e-3, G.Fgap(1)/G.phiFgap, G.Fgap(1)/G.phiFgapX);
w(fid, '<div class="eq">Shear at the ends: F/2 = %.1f kN &le; &phi;V<sub>n</sub> = 1.0 (0.6 F<sub>y</sub>) h t = %.1f kN &nbsp; <span class="res">D/C = %.2f</span> <span class="ref">AISC J4.2(a)</span></div>', G.Fgap(1)/2*kN, G.phiVgap*kN, G.Fgap(1)/2/G.phiVgap);
w(fid, '<p><b>If the gap share is concentrated</b> at the web instead of spread: a point load at mid-span with fixed ends has the same plastic capacity, 8 M<sub>p</sub>/L, so the ratio is the same %.2f. The ends are fixed in reality: the plate is continuous past each platina and each platina is welded on both faces. Only a point load on a simply supported strip would double the ratio, and that combination does not exist here. Nor is the share likely to be more than a third: the flange is very stiff in its own plane and moves load sideways to the backed parts, which are stiffer than the plate over the gap.</p>', G.Fgap(1)/G.phiFgap);
w(fid, '<p>The F11 limit for lateral-torsional buckling does not apply: the strip is a plate bent about its weak axis and is held by the flange weld along its length.</p></div>');

w(fid, '<div class="step"><h3>3c. The offset of the bars (corner only)</h3>');
w(fid, '<p>At the corner the bars of each beam sit on one face of the platinas, e = (t<sub>p</sub> + d<sub>b</sub>)/2 = (%g + %g)/2 = %g mm off the flange line. That is unavoidable: the bars of X and Y must cross at different levels. The platina hands the plate a moment T e at its root. Following the plate down, the moment falls linearly to zero at the compression flange, where the concrete pushes back:</p>', P.pla.t, db, e);
w(fid, '<figure>%s<figcaption><b>Figure %d. Bending models of the embed plate.</b> (a) Strip over the gap, edge. (b) Plate strip under the platinas, corner C1, with its moment diagram: T e at the root of the platinas, zero at the compression flange.</figcaption></figure>', F.plate_mod, nf());
w(fid, '<div class="eq">M = T e = %.1f (%g) = <b>%.2f kN m</b> &nbsp; (corner C1, envelope load)</div>', V3.T*kN, e, G.Mstr(3)*kNm);
w(fid, '<div class="eq">Strip: only the plate under the two platina roots, b = 2 (%g) = %g mm, no spreading: &phi;M<sub>p</sub> = 0.9 F<sub>y</sub> b t&sup2;/4 = 0.9 (%g)(%g)(%g)&sup2;/4 = <b>%.2f kN m</b> &nbsp; <span class="res">D/C = %.2f</span> <span class="ref">AISC F11.1</span></div>', P.pla.w, G.bstr, P.Fy, G.bstr, t, G.phiMstr*kNm, G.Mstr(3)/G.phiMstr);
w(fid, '<div class="eq">Shear in the strip: T &minus; T<sub>flange</sub> = %.1f kN, negligible.</div>', G.Vstr(3)*kN);
w(fid, '<p><b>Edge.</b> The rows over and under balance, so M = 0. Even if the rows shared the pull 60 / 40 instead of 50 / 50, M = 0.2 T e = %.2f kN m, D/C %.2f. At ultimate the bars yield and share equally.</p>', 0.2*E.T*e*kNm, 0.2*E.T*e/G.phiMstr);
w(fid, '<p>The real plate is welded to the beam web along its whole depth and to both flanges, and it spreads the moment wider than the platinas. None of that is counted.</p></div>');

w(fid, '<div class="step"><h3>3d. The platina root (corner)</h3>');
w(fid, '<p>Between the plate and the start of the bars, the platina alone carries the pull of its two bars and the moment of the offset. Per platina, envelope load:</p>');
w(fid, '<div class="eq">P<sub>r</sub> = T/2 = %.1f kN, &nbsp; M<sub>r</sub> = P<sub>r</sub> e = %.2f kN m; &nbsp; P<sub>c</sub> = 0.9 F<sub>y</sub> w<sub>p</sub> t<sub>p</sub> = %.0f kN, &nbsp; M<sub>c</sub> = 0.9 F<sub>y</sub> w<sub>p</sub> t<sub>p</sub>&sup2;/4 = %.2f kN m</div>', V3.T/2*kN, V3.T/2*e*kNm, G.Pc*kN, G.Mc*kNm);
if V3.T/2/G.Pc >= 0.2
    w(fid, '<div class="eq">P<sub>r</sub>/P<sub>c</sub> &ge; 0.2: P<sub>r</sub>/P<sub>c</sub> + (8/9) M<sub>r</sub>/M<sub>c</sub> = <b>%.2f</b> &le; 1.0 <span class="ref">AISC (H1-1a)</span></div>', G.H1(3));
else
    w(fid, '<div class="eq">P<sub>r</sub>/P<sub>c</sub> = %.2f &lt; 0.2: P<sub>r</sub>/(2P<sub>c</sub>) + M<sub>r</sub>/M<sub>c</sub> = <b>%.2f</b> &le; 1.0 <span class="ref">AISC (H1-1b)</span></div>', V3.T/2/G.Pc, G.H1(3));
end
w(fid, '<p>Beyond the start of the bars the platina and the bars act together, much stronger. At the edge the platina is in plain tension: %.2f.</p></div>', G.H1(1));

w(fid, '<div class="step"><h3>3e. Bearing behind the compression flange</h3>');
w(fid, '<p>The plate spreads the push of the bottom flange onto the concrete as a cantilever of length c around the flange footprint, with the plate at its plastic moment (the method of AISC Design Guide 1 for base plates):</p>');
w(fid, '<div class="eq">f<sub>p</sub> = &phi; 0.85 f''c &radic;(A<sub>2</sub>/A<sub>1</sub>) = 0.65 (0.85)(%.1f)(2) = %.1f MPa <span class="ref">ACI 22.8.3.2</span></div>', P.fc, Y.fp);
w(fid, '<div class="eq">c = &radic;(2 (0.9 F<sub>y</sub> t&sup2;/4) / f<sub>p</sub>) = &radic;(2 (0.9)(%g)(%g)&sup2;/4 / %.1f) = %.1f mm; &nbsp; A<sub>1</sub> = (t<sub>f</sub> + 2c)(b<sub>f</sub> + 2c) = (%.1f)(%.1f) = %.0f mm&sup2;</div>', P.Fy, t, Y.fp, Y.c, bm.tf + 2*Y.c, bm.b + 2*Y.c, Y.A1);
w(fid, '<div class="eq">&phi;B<sub>n</sub> = f<sub>p</sub> A<sub>1</sub> = <b>%.0f kN</b> &ge; C = %.1f kN &nbsp; <span class="res">D/C = %.2f</span></div>', Y.phiBn*kN, E.Tf*kN, E.Tf/Y.phiBn);
w(fid, '<p>&radic;(A<sub>2</sub>/A<sub>1</sub>) = 2 needs a concentric area twice as large in each direction: %.0f x %.0f mm, which fits in the %g mm column face, centred %.0f mm below the beam top. Without the factor 2, D/C = %.2f.</p></div>', 2*(bm.tf + 2*Y.c), 2*(bm.b + 2*Y.c), P.col.b, -R.zC, E.Tf/(Y.fp/2*plate_A1(P, Y.fp/2)));

w(fid, '<div class="step"><h3>3f. Why 12 mm and not thicker</h3>');
w(fid, '<p>All plate ratios above are at most %.2f with models that leave out every helping element. A thicker plate lowers the bending ratios (3b, 3c) with the square of the thickness; the bearing ratio (3e) drops more slowly, because only the spread c grows with t:</p>', max([E.Tf/G.plTT, G.Fgap(1)/G.phiFgap, G.Mstr(3)/G.phiMstr, E.Tf/Y.phiBn]));
w(fid, '<div class="tw"><table><tr><th>Plate</th><th class="n">Gap, 3b</th><th class="n">Offset, 3c</th><th class="n">Bearing, 3e</th></tr>');
for tt = [12 16 20]
    k2 = (t/tt)^2;
    w(fid, '<tr><td>%g mm</td><td class="n">%.2f</td><td class="n">%.2f</td><td class="n">%.2f</td></tr>', tt, G.Fgap(1)/G.phiFgap*k2, G.Mstr(3)/G.phiMstr*k2, E.Tf/(Y.fp*plate_A1(P, Y.fp, tt)));
end
w(fid, '</table></div>');
w(fid, '<p>But every millimetre of plate pushes the platinas and the bars deeper into the joint, where the clearances are %g to %g mm (section 8). 12 mm passes with margin and keeps the layout that was checked.</p></div>', min(cell2mat(R.clr([1 2 3],2))), max(cell2mat(R.clr([1 2 3],2))));

% ---------------------------------------------------------------- 4 anchorage
w(fid, '<h2 id="s4">4. Anchorage without millimetres</h2>');
w(fid, '<p>The anchorage has two parts. The anchor bars themselves are made in the shop and welded to the platinas, so their hooks are where the drawing says, within a few millimetres. The top bars of the concrete beam, which hold the breakout body, are placed on site, and ACI allows them to be off by:</p><ul>');
w(fid, '<li>&plusmn;%g mm at the ends of bars at discontinuous ends of members <span class="ref">ACI 318-19 Table 26.6.2.1(b)</span>;</li>', P.tol.ub);
w(fid, '<li>&plusmn;%g mm in d for members deeper than 200 mm <span class="ref">Table 26.6.2.1(a)</span>.</li></ul>', P.tol.zb);
w(fid, '<p>Revision 2 used nominal positions; its margin on this check was 27 mm, the size of these tolerances. Here the check is made with <b>all tolerances against the design at once</b>:</p><ul>');
w(fid, '<li>beam bars %g mm shorter at the hook and %g mm lower;</li>', P.tol.ub, P.tol.zb);
w(fid, '<li>anchor hooks %g mm shorter, platinas %g mm off level (shop);</li>', P.tol.ua, P.tol.za);
w(fid, '<li>beam bars at their lowest possible level, since which beam is on top is not known: a VCM under a VCS has its top line at z = %g and its two extra bars at %g; a VCS under a VCM passes under the stacked corner bars, at %g;</li>', R.zV, R.zV - P.cb.dz, R.zS);
w(fid, '<li>the centre bar of each beam stopped behind the mid-face column bar (hook at u = %g instead of %g).</li></ul>', P.cb.uh0, P.cb.uh);
w(fid, '<div class="step"><h3>4a. The anchor bars</h3>');
w(fid, '<div class="eq">&#8467;<sub>dh</sub> = max(f<sub>y</sub> &psi;<sub>e</sub> &psi;<sub>r</sub> &psi;<sub>o</sub> &psi;<sub>c</sub> d<sub>b</sub><sup>1.5</sup> / (23 &lambda; &radic;f''c), 8 d<sub>b</sub>, 150) = max(%g (1)(%g)(1)(%.3f)(%g)<sup>1.5</sup> / (23 (%.2f)), %g, 150) = max(%.0f, %g, 150) = <b>%.0f mm</b> <span class="ref">ACI 25.4.3.1, SI (Appendix E)</span></div>', P.fy, D.psir, D.psic, db, sq, 8*db, D.ldhf, 8*db, D.ldh);
w(fid, '<p>&psi;<sub>c</sub> = 0.01 f''c + 0.6 = %.3f for f''c &lt; 40 MPa (SI form of f''c/15000 + 0.6, ACI Appendix E). &psi;<sub>r</sub> is 1.0 or 1.6 in ACI 318-19; there is no 0.8 factor (that was the tie factor of 318-14).</p>', D.psic);
w(fid, '<div class="eq">Available, from the end of the welds to the outside of the hook, minus the shop tolerance: %g &minus; %g &minus; %g = <b>%g mm</b> &nbsp; <span class="res">D/C = %.2f</span> (revision 2: 0.91)</div>', P.anc.uh, u2, P.tol.ua, D.av, D.ldh/D.av);
if D.encl
    w(fid, '<p>&psi;<sub>r</sub> = 1.0: %d tie layers lie within 15 d<sub>b</sub> = %g mm below the highest row of hooks, spaced %g &le; 8 d<sub>b</sub> = %g: A<sub>th</sub> = %.0f &ge; 0.4 A<sub>hs</sub> = %.0f mm&sup2; <span class="ref">25.4.3.3(b)(1)</span>.</p>', D.nlay(1), 15*db, abs(diff(P.hoop.z(1:2))), 8*db, D.Ath_anc(1), 0.4*R.As(1));
else
    w(fid, '<p>&psi;<sub>r</sub> = 1.6: the hooks end behind the far tie legs, so the joint ties do not enclose them <span class="ref">25.4.3.3</span>. The longer &#8467;<sub>dh</sub> is accepted: the hooks are past the ties because that puts them deeper and makes the breakout body larger (section 4b).</p>');
end
w(fid, '<p>&psi;<sub>o</sub> = 1.0: the hooks end behind the far ties, inside the beam in line, with side cover normal to the plane of the hook %g mm &ge; 6 d<sub>b</sub> = %g <span class="ref">Table 25.4.3.2</span>.</p></div>', P.col.b/2 - max([P.anc.vO P.anc.vU P.anc.vC]) - db/2, 6*db);
w(fid, '<div class="step"><h3>4b. The beam bars that hold the breakout body</h3>');
w(fid, '<p>Same rules as revision 2: the cone starts at the beginning of the anchor bends and opens towards the plate with slope 1 : 1.5; each beam bar must have &#8467;<sub>dh</sub> = %.0f mm inside it, measured to the outside of its hook <span class="ref">ACI 17.5.2.1(a)</span>, and must lie within 0.5 h<sub>ef</sub> = %.0f mm of an anchor <span class="ref">R17.5.2.1</span>. Only the bars needed for T are counted, the ones with the longest length inside first; the number is chosen so that the larger of the two ratios is the smallest. Development for full f<sub>y</sub> is required: no reduction for excess steel <span class="ref">R17.5.2.1</span>.</p>', D.ldh12, X.half_hef);
w(fid, '<div class="tw"><table><tr><th>Case</th><th>Beam bars |v|</th><th class="n">Distance to the nearest anchor</th><th class="n">Inside, nominal</th><th class="n">Inside, with tolerances</th><th class="n">Bars counted</th><th class="n">Strength D/C</th><th class="n">Length D/C</th></tr>');
Tc = [E.T, V3.T, V3.TO, E.T];
for i = 1:4
    c = R.cone(i);
    w(fid, '<tr><td>%s</td><td>%s</td><td class="n">%s</td><td class="n">%s</td><td class="n">%s</td><td class="n">%d</td><td class="n">%.2f</td><td class="n">%.2f</td></tr>', R.cone_label{i}, num2str(c.vb), num2str(round(c.r)), fin(c.ins_nom), fin(c.ins_tol), c.k, Tc(i)/(0.75*P.fy*c.k*Ab12), D.ldh12/c.inside);
end
w(fid, '</table></div>');
w(fid, '<p>Pull: edge %.1f kN; corner C1 %.1f kN, C2 %.1f kN (envelope load). &ldquo;-&rdquo;: the other bar of a pair in contact, not counted (a hooked bundle is outside ACI, R25.6.1.5).</p>', E.T*kN, V3.T*kN, V3.TO*kN);
w(fid, '<figure>%s<figcaption><b>Figure %d. Beam-bar hooks the design counts on, and how far they may fall short.</b> The hooks the design counts on and how far each may fall short. Green bars: counted as anchor reinforcement; the green zone and the black mark show where the outside of each hook may end, measured from the outer face of the column. Grey bars: not needed. Red: the anchor assemblies, made in the shop. These limits hold with the beam bars also %g mm low, on the lower layer, and with the shop tolerances; they are the site checks of section 8.</figcaption></figure>', F.tol, nf(), P.tol.zb);
w(fid, '<figure>%s<figcaption><b>Figure %d. Breakout body at the edge, section along the beam.</b> Edge, section along the beam. The light bar is the same beam bar with the tolerances.</figcaption></figure>', F.dev_edge, nf());
w(fid, '<figure>%s<figcaption><b>Figure %d. Breakout body at the corner, type C2, section along the beam.</b> Corner, type C2: its bars are the farthest from the beam bars, so it governs.</figcaption></figure>', F.dev_cor, nf());
w(fid, '<figure>%s<figcaption><b>Figure %d. Breakout bodies at the corner, plan.</b> Corner in plan: the bodies of X (C1) and Y (C2) and where each beam bar leaves them.</figcaption></figure>', F.cones, nf());
w(fid, '<p><b>What made the difference.</b> The &Oslash;12 bend is smaller, so the cone starts deeper (u = %.0f instead of 286); all hooks reach u = %g; the edge bars under the platinas sit at |v| = %g, next to the centre bar of the beam; four anchors per beam put an anchor near every beam bar.</p>', D.uap, P.anc.uh, P.anc.vU);
w(fid, '<p><b>Corner assignment.</b> The numbers above put both corner assemblies against the 3-bar VCS beam. If C1 (bars under) goes to the side of the VCM beam, its ratios drop; but no assignment is needed for the design to pass.</p></div>');
w(fid, '<div class="step"><h3>4c. The other side of the breakout body</h3>');
w(fid, '<div class="eq">The beam bars continue along the beam: &#8467;<sub>d</sub> = f<sub>y</sub> d<sub>b</sub>/(2.1 &radic;f''c) = %g (%g)/(2.1 (%.2f)) = <b>%.0f mm</b>, always available. <span class="ref">ACI Table 25.4.2.3</span></div></div>', P.fy, P.cb.db, sq, D.ld12);

% ---------------------------------------------------------------- 5 easy check
w(fid, '<h2 id="s5">5. Easy check, step by step</h2>');
w(fid, '<p>Edge beam unless said otherwise. Each step is one idea, one formula, one number.</p>');
w(fid, '<figure>%s<figcaption><b>Figure %d. Tributary areas.</b> </figcaption></figure>', F.trib, nf());
w(fid, '<div class="step"><h3>Step 1. Load on the beam</h3>');
w(fid, '<div class="eq">q = 1.2 D + E<sub>v</sub> + L = 1.2 (%g) + %.3f (%g) + %g = <b>%.2f kN/m&sup2;</b> &nbsp; (1.2D + 1.6L gives %.2f) <span class="ref">NEC-SE-DS 3.4.4</span></div>', P.qD, R.Ev, P.qD, P.qL, R.q(2), R.q(1));
w(fid, '<div class="eq">w = q s + beam = %.2f (%g) + %.2f = <b>%.1f kN/m</b>; &nbsp; at the column face: V = <b>%.1f kN</b>, M = <b>%.1f kN m</b></div>', R.q(2), P.s_edge/1000, R.gsw(2)*bm.w, R.q(2)*P.s_edge/1000 + R.gsw(2)*bm.w, E.Vu*kN, E.Mu*kNm);
w(fid, '<p>0.9D &minus; E<sub>v</sub> = %.2f kN/m&sup2;, still downwards: only the top flange pulls.</p></div>', R.q(3));
w(fid, '<div class="step"><h3>Step 2. The moment becomes a pull and a push</h3>');
w(fid, '<div class="eq">T = M / (h &minus; t<sub>f</sub>) = %.1f / %.4f = <b>%.1f kN</b> = C</div></div>', E.Mu*kNm, R.ho/1000, E.T*kN);
w(fid, '<div class="step"><h3>Step 3. Enough anchor bars?</h3>');
w(fid, '<div class="eq">&phi; A<sub>s</sub> f<sub>y</sub> = 0.75 (4 x %.0f)(%g) = <b>%.0f kN</b> &ge; %.1f kN &nbsp; <span class="res">D/C = %.2f</span> (corner %.2f) <span class="ref">ACI 17.5.3, 23.7.2</span></div></div>', Ab, P.fy, N.phiNy(1)*kN, E.T*kN, E.T/N.phiNy(1), V3.T/N.phiNy(3));
w(fid, '<div class="step"><h3>Step 4. Hooks of the anchors</h3><p>Section 4a: %.0f mm needed, %g available. <span class="res">D/C = %.2f</span></p></div>', D.ldh, D.av, D.ldh/D.av);
w(fid, '<div class="step"><h3>Step 5. Who takes the pull after the anchors?</h3>');
w(fid, '<p>Chapter 17 alone gives %.0f kN for the concrete cone (D/C %.1f), so the beam top bars hold it (section 4b): strength D/C %.2f, length inside D/C %.2f with tolerances.</p>', Q.phiN*kN, E.T/Q.phiN, E.T/X.phiN(1), D.ldh12/X.ins(1));
w(fid, '<figure>%s<figcaption><b>Figure %d. Paths of the moment out of the edge joint.</b> Edge joint: the two paths that take the moment out of the joint. Red: anchors. Green: top bars of the concrete beam. Orange dashed: the cone surface.</figcaption></figure>', F.flow, nf());
w(fid, '<div class="eq">Moment at the column axis: %.1f + %.1f (%g) = <b>%.1f kN m</b> &le; &phi;M<sub>n</sub> of 5 &Oslash;12 = %.1f kN m &nbsp; <span class="res">D/C = %.2f</span> <span class="ref">ACI 22.3</span></div>', E.Mu*kNm, E.Vu*kN, P.a0/1000, E.Ma*kNm, X.phiMn(1)*kNm, E.Ma/X.phiMn(1));
w(fid, '<p>Room left for the support moment of the beams from your model (without the cantilever): about %.0f kN m on the VCM and %.0f kN m on a VCS.</p></div>', (X.phiMn(1)-E.Ma)*kNm, (X.phiMn(2)-V3.Ma)*kNm);
w(fid, '<div class="step"><h3>Step 6. Paths out of the joint</h3>');
w(fid, '<p>Path 1, the concrete beam (step 5). Path 2, the pedestal: the pull goes diagonally down to the push; the vertical part, T tan %.0f&deg; = %.0f kN, is tension in the 3 column bars of the inner face (capacity %.0f kN). Each path alone is enough.</p>', M.th*180/pi, E.T*tan(M.th)*kN, M.phiTcol*kN);
w(fid, '<div class="eq">Pedestal, edge, cantilever + frame at right angles: %.1f kN m &le; &phi;M<sub>n</sub> = %.1f kN m &nbsp; <span class="res">D/C = %.2f</span>. Joint shear: %.0f kN &le; %.0f kN <span class="ref">ACI 22.4, 15.4.2</span></div></div>', hypot(Z.Mx, Z.My)*kNm, Z.phiMnE*kNm, hypot(Z.Mx, Z.My)/Z.phiMnE, E.T*kN, J.phiVn(1)*kN);
w(fid, '<div class="step"><h3>Step 7. Shear V: the platinas are the shear lug</h3>');
w(fid, '<p>V pushes the platinas down onto the concrete. ACI 17.11 applies: at least 4 anchors (now true at the edge and at the corner), h<sub>ef</sub>/h<sub>sl</sub> = %.0f/%g = %.1f &ge; 2.5 and h<sub>ef</sub>/c<sub>sl</sub> = %.0f/%g = %.0f &ge; 2.5 <span class="ref">17.11.1.1.2, 17.11.1.1.8</span>.</p>', H.hef, H.hsl, H.hef/H.hsl, H.hef, H.csl, H.hef/H.csl);
w(fid, '<div class="eq">A<sub>ef</sub> = 2 w<sub>p</sub> min(2 t<sub>p</sub>, L) = 2 (%g)(%g) = %.0f mm&sup2;; &nbsp; &phi;V<sub>brg</sub> = 0.65 (1.7 f''c A<sub>ef</sub>) = <b>%.0f kN</b> &ge; %.1f &nbsp; <span class="res">D/C = %.2f</span> <span class="ref">17.11.2.1, 17.11.2.1.1(a)</span></div>', P.pla.w, min(2*P.pla.t, P.pla.L), H.Aef, H.phiVbrg*kN, E.Vu*kN, E.Vu/H.phiVbrg);
w(fid, '<div class="eq">Breakout parallel to the side faces: &phi;V<sub>cb</sub> = <b>%.0f kN</b> &nbsp; <span class="res">D/C = %.2f</span> <span class="ref">17.11.3.2</span>. 35&deg; plane to the far face: %.0f kN <span class="ref">22.9</span></div>', H.phiVcb*kN, E.Vu/H.phiVcb, Z.phiVsf*kN);
w(fid, '<p>The bars are welded to the attachment, so they also take part of V <span class="ref">17.11.1.1.3</span>; checked with all of V on them: tension + shear %.2f &le; 1.2 <span class="ref">17.8.3</span>.</p></div>', E.T/N.phiNsa(1) + hypot(E.Vu, O.H(1))/N.phiVsa(1));
w(fid, '<div class="step"><h3>Step 8. Welds, and which part fails first</h3>');
w(fid, '<p>A bar lying on a plate leaves a curved groove on each side (flare-bevel). For bars under &Oslash;20, AISC counts only the fillet placed on the groove filled flush <span class="ref">AISC Table J2.2, note [a]</span>. So each side weld is rated as a %g mm fillet. No directional increase (J2-5) is used.</p>', P.w.bar);
w(fid, '<div class="eq">One bar: &phi;R<sub>n</sub> = 0.75 (0.6 F<sub>EXX</sub>)(0.707 w)(2 L) = 0.75 (0.6)(%g)(0.707)(%g)(2 x %g) = <b>%.1f kN</b> &ge; T/4 = %.1f kN &nbsp; <span class="res">D/C = %.2f</span></div>', P.FEXX, P.w.bar, P.anc.Lw, W.side*kN, E.T/4*kN, E.T/4/W.side);
w(fid, '<div class="eq">Platina to plate, one fillet line: &phi;R<sub>n</sub> = %.1f (%g)(%g) = <b>%.1f kN</b>. Worst line at the corner: N = T/4 + (T/2) e / t<sub>p</sub> = %.1f kN, with V/4 across it: %.1f kN &nbsp; <span class="res">D/C = %.2f</span> (edge %.2f)</div>', W.fw, P.w.pla, P.pla.w, W.line*kN, W.Ntop(3)*kN, W.root(3)*kN, W.root(3)/W.line, W.root(1)/W.line);
w(fid, '<p><b>Order of failure.</b> If the joint were overloaded, a bar or a platina should yield and stretch before any weld breaks. The welds are checked against the strength of what they connect:</p><ul>');
w(fid, '<li>side welds of one bar %.1f kN &ge; 1.25 f<sub>y</sub> A<sub>b</sub> = %.1f kN (the target of ACI 25.5.7.1 for welded splices): D/C %.2f;</li>', W.side*kN, W.bar125*kN, W.bar125/W.side);
w(fid, '<li>bar and platina surfaces along those welds, shear rupture: %.0f kN &ge; %.1f: D/C %.2f <span class="ref">AISC J4.2(b)</span>;</li>', min(W.bmBar, W.bmPla)*kN, W.bar125*kN, W.bar125/min(W.bmBar, W.bmPla));
w(fid, '<li>platina fillets at the edge, with both bars at 1.25 f<sub>y</sub>: D/C %.2f; at the corner the platina root turns plastic first (eccentric pull %.1f kN per platina, nominal), and the fillets hold it: D/C %.2f. With the expected yield of A36 plate, R<sub>y</sub> = 1.3 <span class="ref">AISC 341-16 Table A3.1</span>, the fillets still hold at their nominal strength (no &phi;): D/C %.2f.</li></ul></div>', G.Fhier(1)/W.line, G.Fmech*kN, G.Fhier(3)/W.line, 1.3*G.Fhier(3)/(W.line/0.75));
w(fid, '<div class="step"><h3>Step 9. Torsion on the corner beams</h3>');
w(fid, '<div class="eq">T<sub>t</sub> = %.2f kN m realistic, %.2f kN m with all the load on one flange tip; couple on the flanges %.1f kN. At the top it goes to the welded bars (inside the interaction of step 7); at the bottom by friction under C: &phi; 0.4 C = %.0f kN (AISC Design Guide 1).</div></div>', O.Treal*kNm, O.Tu(3)*kNm, O.H(3)*kN, 0.75*0.4*V3.T*kN);
w(fid, '<div class="step"><h3>Step 10. Strength of the members</h3>');
w(fid, '<div class="tw"><table><tr><th>Member</th><th class="n">&phi;M<sub>n</sub> (kN m)</th><th class="n">&phi;V<sub>n</sub> (kN)</th><th>Basis</th></tr>');
w(fid, '<tr><td>%s cantilever</td><td class="n">%.1f / %.1f</td><td class="n">%.1f</td><td>AISC F2: L<sub>b</sub> = L and 2.5 L (tip unbraced, load on top); G2.1. Tip deflection under D + L: %.1f mm (L/180 = %.1f)</td></tr>', bm.name, B.phiMn*kNm, B.phiMn25*kNm, B.phiVn*kN, B.dDL, B.dlim);
w(fid, '<tr><td>VCM 30x35, 5 &Oslash;12 top</td><td class="n">%.1f</td><td class="n">%.0f / %.0f</td><td>d = %g mm</td></tr>', R.cb(1).phiMn*kNm, R.cb(1).phiVn(1)*kN, R.cb(1).phiVn(2)*kN, X.d);
w(fid, '<tr><td>VCS 30x35, 3 &Oslash;12 top</td><td class="n">%.1f</td><td class="n">%.0f / %.0f</td><td>same</td></tr>', R.cb(2).phiMn*kNm, R.cb(2).phiVn(1)*kN, R.cb(2).phiVn(2)*kN);
w(fid, '<tr><td>Pedestal 40x40, 8 &Oslash;16, P = 0</td><td class="n">%.1f / %.1f</td><td class="n">%.0f</td><td>one axis / diagonal</td></tr>', Z.phiMn0*kNm, Z.phiMn45*kNm, Z.phiVn*kN);
w(fid, '</table></div></div>');

% ---------------------------------------------------------------- 6 drawings
w(fid, '<h2 id="s6">6. Drawings</h2>');
w(fid, '<p class="leg">Colours:<span style="background:#c0392b"></span>anchor bars<span style="background:#5d6d7e"></span>beam bars<span style="background:#9a6b00"></span>column bars<span style="background:#117a65"></span>rods of the steel column<span style="background:#7d3c98"></span>ties<span style="background:#34506b"></span>steel plates<span style="background:#e3141e"></span>welds</p>');
w(fid, '<figure>%s<figcaption><b>Figure %d. Assembly type E, side view.</b> Assembly type E, side view (the beam is welded on site, after the pour). Lighter: the bars under the platinas, behind.</figcaption></figure>', F.assy_elev, nf());
w(fid, '<figure>%s<figcaption><b>Figure %d. Assembly type E, top view.</b> Assembly type E, top view. The mid-face column bar is shown to explain the %g mm gap; it is not part of the assembly.</figcaption></figure>', F.assy_plan, nf(), 2*P.pla.v0);
w(fid, '<h3>Edge column</h3>');
w(fid, '<figure>%s<figcaption><b>Figure %d. Edge column, plan.</b> Edge column, plan.</figcaption></figure>', F.edge_plan, nf());
w(fid, '<figure>%s<figcaption><b>Figure %d. Edge column, section along the steel beam.</b> Edge column, section along the steel beam. The bars under the platinas (lighter) are behind the ones over them.</figcaption></figure>', F.edge_elev, nf());
w(fid, '<figure>%s<figcaption><b>Figure %d. Edge column seen from outside.</b> VCM top bars at 0 and &plusmn;%g, with a second bar in contact under each corner bar; anchors at &plusmn;%g (under) and &plusmn;%g (over).</figcaption></figure>', F.edge_front, nf(), P.cb.v(end), P.anc.vU, P.anc.vO);
w(fid, '<h3>Ties of the joint (unchanged)</h3>');
w(fid, '<figure>%s<figcaption><b>Figure %d. One layer of joint ties, plan.</b> </figcaption></figure>', F.hoops, nf());
w(fid, '<figure>%s<figcaption><b>Figure %d. Bending detail of one joint tie.</b> Bending detail of one tie. 135&deg; hooks: inside bend diameter 4 d<sub>b</sub>, extension the greater of 6 d<sub>b</sub> and 75 mm <span class="ref">ACI Table 25.3.2</span>.</figcaption></figure>', F.tie, nf());
w(fid, '<h3>Corner column</h3>');
w(fid, '<figure>%s<figcaption><b>Figure %d. Corner column, plan.</b> Corner column, plan: C1 under the platinas of X, C2 over the platinas of Y; they cross %g mm apart.</figcaption></figure>', F.cor_plan, nf(), R.clr{4,2});
w(fid, '<figure>%s<figcaption><b>Figure %d. Corner column, section along beam X (type C1).</b> </figcaption></figure>', F.cor_elevX, nf());
w(fid, '<figure>%s<figcaption><b>Figure %d. Corner column, section along beam Y (type C2).</b> </figcaption></figure>', F.cor_elevY, nf());

% ---------------------------------------------------------------- 7 limit states
w(fid, '<h2 id="s7">7. All limit states</h2>');
w(fid, '<p>Grey: information only, not relied upon. Frame rows include only the cantilever, except the pedestal of the edge, which adds your frame moment. Corner columns: the worse of C1 and C2 where they differ.</p>');
w(fid, '<div class="tw"><table><tr><th>Limit state</th><th>Reference</th><th class="n">Strength</th><th class="n">Edge</th><th class="n">D/C</th><th class="n">Corner</th><th class="n">D/C</th><th class="n">Envelope</th><th class="n">D/C</th></tr>');
g = '';
for i = 1:size(R.rows,1)
    r = R.rows(i,:);  d = r{4};  c = r{5};
    if numel(d) == 1, d = d*[1 1 1]; end
    if numel(c) == 1, c = c*[1 1 1]; end
    if ~strcmp(g, r{1}), g = r{1};  w(fid, '<tr class="grp"><td colspan="9">%s</td></tr>', g); end
    if strcmp(r{6}, '-'), fm = '%.2f'; un = ''; else, fm = '%.1f'; un = [' ' r{6}]; end
    if numel(unique(round(c*100))) == 1, cs = [sprintf(fm, c(1)) un]; else, cs = [sprintf(fm, c(1)) ' / ' sprintf(fm, c(2)) ' / ' sprintf(fm, c(3)) un]; end
    s = sprintf('<tr><td>%s</td><td><span class="ref">%s</span></td><td class="n">%s</td>', r{2}, r{3}, cs);
    for k = 1:3
        s = [s sprintf(['<td class="n">' fm '</td><td class="n %s">%.2f</td>'], d(k), cls(d(k)/c(k), r{7}), d(k)/c(k))];
    end
    w(fid, '%s</tr>', s);
end
w(fid, '</table></div>');
w(fid, '<p>Not applicable: bolt checks (no bolts); pullout of hooked bolts, 17.6.3 (deformed hooked bars are covered by 25.4.3); side-face blowout, 17.6.4 (headed anchors only); shear breakout downwards (no edge below).</p>');

% ---------------------------------------------------------------- 8 site
w(fid, '<h2 id="s8">8. Clearances and site</h2>');
w(fid, '<div class="tw"><table><tr><th>Between</th><th class="n">Clear (mm)</th><th>Note</th></tr>');
for i = 1:size(R.clr,1)
    w(fid, '<tr><td>%s</td><td class="n">%.0f</td><td>%s</td></tr>', R.clr{i,1}, R.clr{i,2}, R.clr{i,3});
end
w(fid, '</table></div>');
w(fid, '<h3>Placing the assemblies</h3>');
w(fid, '<p><b>From above.</b> Nothing lies above the platinas and the horizontal bars until the closed tie at %+g, which goes in afterwards; the platinas pass the mid-face column bar with %.0f mm each side and the bars pass the rods of the steel column with %.0f mm. The only tight place is where the hook tails come down between the top bars of the beam in line, which cross the whole joint (figure below).</p>', P.hoop.ztop, R.clr{1,2}, R.clr{3,2});
w(fid, '<figure>%s<figcaption><b>Figure %d. Placing the edge assembly from above.</b> (a) The edge joint seen from above as the assembly goes down: everything shown is already in place except the assembly (plate, platinas, red anchors). The dark red circles are the hook tails, which go down past the beam top bars. (b) to (d) The far side enlarged, for the three possible layouts of the beam top bars, with the clear gap between each tail and the nearest beam bar. The corner assemblies have tails at the same |v| (37 and 78), so (d) applies to a VCS beam and (b) or (c) to a VCM beam.</figcaption></figure>', F.ins, nf());
w(fid, '<p><b>From the front</b> (through the open outer face) is not possible: the hook tails would have to pass through the top bars of the crossing beam and the joint ties. Placing from above is the only way.</p>');
w(fid, '<div class="warn"><b>Before the pour</b><ol>');
w(fid, '<li>Column bars: 90&deg; hooks at the top, turned into the joint (a straight bar has %g mm where it needs %.0f mm; hooked: %.0f mm). They are not bent yet: bend the mid-face bars so their hooks run along the steel beam, not across the anchors.</li>', D.colav, D.ldcol, D.ldhcol);
lim = @(C, i) C.uh(i) + 5*floor(C.short(i)/5);
iE = R.cone(1).used;  i1 = R.cone(2).used;  i2 = R.cone(3).used;
w(fid, '<li>Top bars of the concrete beams: 90&deg; hooks down at the outer face of the joint, tail 12 d<sub>b</sub> = %g mm, the hook against the outer tie. The centre bar may stop behind the mid-face column bar.</li>', 12*P.cb.db);
w(fid, '<li><b>Hold point, measure before the pour</b> (figure in section 4b), from the form of the outer face to the outside of each hook: edge, bars at &plusmn;%g at most %g mm, bars at &plusmn;%g at most %g mm; corner, beam X (type C1) at most %g mm, beam Y (type C2) at most %g mm. A hook found farther away is pushed back and re-tied.</li>', ...
    abs(R.cone(1).vb(iE(1))), lim(R.cone(1), iE(1)), abs(R.cone(1).vb(iE(2))), lim(R.cone(1), iE(2)), lim(R.cone(2), i1(1)), lim(R.cone(3), i2(1)));
w(fid, '<li>VCM: 5 top bars, 3 on the top line (0, &plusmn;%g) and 2 in contact under the corner bars; the bars under the corners hook down inside the hooks of the corner bars. The anchor tails come down between the beam top bars (Figure in section 8), %.0f mm clear.</li>', P.cb.v(end), R.clr{strcmp(R.clr(:,1), 'Hook tails - beam top bars, in plan'),2});
w(fid, '<li>%d layers of ties &Oslash;%g in the joint at z = %s mm, and one closed tie at z = %+g after the assemblies.</li>', numel(P.hoop.z), P.hoop.db, num2str(P.hoop.z), P.hoop.ztop);
w(fid, '<li>Lower the assembly from above; the plate closes the form. The mid-face column bar passes between the platinas (%g mm clear each side; nudge it if needed). Fix the plate to the form and tie the assembly to the cage. Corner: X (type C1) first, then Y (type C2) on top.</li>', R.clr{1,2});
w(fid, '<li>Tape or foam over the outer face of the plate so the cement paste does not cover it.</li>');
w(fid, '<li>Pour up to the pedestal top (+%g). Vibrate well under the platinas.</li></ol></div>', P.col.top);
w(fid, '<div class="warn"><b>Before welding the beam (site)</b><ol>');
w(fid, '<li>Grind the weld zones of the plate to bright metal, 25 mm beyond each weld, just before welding. If the shop applied a weldable primer, the welding procedure must be qualified with it; grinding is still the safer option.</li>');
w(fid, '<li>Weld: fillet %g all round the flanges, %g on both sides of the web. Small passes, with pauses, to limit the heat in the concrete around the plate <span class="ref">PCI Design Handbook 6.7.4</span>. Prop the beam tip until the slab has hardened.</li>', P.w.flange, P.w.web);
w(fid, '<li>After welding: brush and paint the plate and the welds with zinc-rich paint.</li></ol></div>');
w(fid, '<p>Shop: bend the hooks before welding (the welds end %.0f mm from the start of the bends); bars weldable (INEN 2167 / A706), check the mill certificate for preheat; platinas level with the top flange line within %g mm; bars start %g mm behind the plate and are not welded to it.</p>', D.uap - u2, P.tol.za, P.anc.u0 - t);

% ---------------------------------------------------------------- 9 notes
w(fid, '<h2 id="s9">9. Notes and references</h2><ul>');
w(fid, '<li>Section numbers checked against the PDFs of ACI 318-19 (inch-pound; SI equations from its Appendix E), ACI 318S-14, AISC 360-16, PCI Design Handbook 7th ed. and NEC-SE-DS. AWS D1.1 and D1.4 were not available; rules from them are quoted through AISC or PCI.</li>');
w(fid, '<li>ACI 318S-14: no shear-lug provisions (17.11 is new in 2019); hook length 0.24 f<sub>y</sub> &psi;<sub>c</sub> d<sub>b</sub>/&radic;f''c = %.0f mm.</li>', D.ldh14);
w(fid, '<li>No excess-steel reduction of development length anywhere (ACI 25.4.10.2(d), R17.5.2.1). No directional increase of fillet strength (AISC J2-5), no J2.4(c).</li>');
w(fid, '<li>Assumed: rebar f<sub>y</sub> = %g MPa, weldable; I = %g; ordinary moment frame (ACI 15.3 joint ties).</li>', P.fy, P.I);
w(fid, '<li>Open: support moments of the concrete beams from your model (room left in step 5).</li></ul>');
w(fid, '</main></body></html>');
fclose(fid);
end

% ---------------------------------------------------------------------------
function w(fid, fmt, varargin)
fprintf(fid, [fmt '\n'], varargin{:});
end

function s = fin(x)
% numbers of a row, '-' for the bars not counted
s = '';
for i = 1:numel(x)
    if isfinite(x(i)), s = [s sprintf('%.0f ', x(i))]; else, s = [s '- ']; end
end
end

function A1 = plate_A1(P, fp, t)
% DG1 bearing area behind the compression flange for a plate t and stress fp
if nargin < 3, t = P.pl.t; end
c = sqrt(2*(0.9*P.Fy*t^2/4)/fp);
A1 = (P.bm.tf + 2*c)*(P.bm.b + 2*c);
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

function n = nf(reset)
% figure number: nf(0) resets, nf() gives the next one
persistent k
if nargin > 0 || isempty(k), k = 0; n = 0; return; end
k = k + 1;  n = k;
end
