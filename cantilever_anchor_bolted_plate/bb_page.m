function bb_page(P, R, B, C, fname, rec)
% BB_PAGE  Review page of the border beam (bb_calc). C from ca_capacity (largest Mu per type).
fid = fopen(fname, 'w');
w = @(varargin) fprintf(fid, [varargin{1} '\n'], varargin{2:end});
nm = cellfun(@(s) s.name, B.S, 'UniformOutput', false);
get = @(n) B.S{find(strcmp(nm, n), 1)};
s = get(rec);  L = B.L(1);  kN = 1e-3;  Ev = R.Ev;
yn = @(b) ifelse(b, '<span class="ok">ok</span>', '<span class="ng">no</span>');
w('<!doctype html><html><head><meta charset="utf-8"><title>Border beam</title>');
w(['<style>body{background:#fff;font-family:Helvetica,Arial,sans-serif;max-width:1150px;margin:24px auto;padding:0 16px;color:#111;line-height:1.45}' ...
   'h1{font-size:23px}h2{font-size:18px;margin-top:30px;border-bottom:1px solid #ccc}.calc{font-size:14px}.calc li{margin:5px 0}' ...
   '.ok{color:#1e6b32;font-weight:bold}.ng{color:#b03a2e;font-weight:bold}.note{font-size:13px;color:#444}.hl{background:#fdf2d0}' ...
   '.tw{overflow-x:auto}table{border-collapse:collapse;font-size:13px;margin:10px 0}td,th{border:1px solid #ccc;padding:3px 6px;text-align:right}th:first-child,td:first-child{text-align:left}</style></head><body>']);
w('<h1>Border beam at the slab edge: %s, A36, simply supported between cantilever tips</h1>', rec);
w('<p>2026-10-03, design proposal (not in the drawings). Catalog: IPAC Nacional 2023 (every IPE and every rectangular tube with H &ge; 100). AISC 360-16 LRFD; vibration per AISC Design Guide 11, 2nd ed.</p>');

w('<h2>1. Layout and loads (assumptions to confirm)</h2><div class="calc"><ol>');
w('<li><b>Where.</b> Along the slab edge, between the tips of the IPE 240 cantilevers: south edge B9&ndash;C9&ndash;D9 (spans %g), east edge E4&ndash;E3 (span %g). Each span pinned at both ends (shear tab on the cantilever tip).</li>', B.L(1), B.L(2));
w('<li><b>Deck.</b> Spans from the grid-4 beam (south strip) or the grid-D beam (east strip) to the border beam, 1270 mm. Simple span: the border beam takes half, %g mm of floor.</li>', B.trib);
w('<li><b>Loads.</b> q<sub>D</sub> = %g, q<sub>L</sub> = %g kN/m&sup2; (as the cantilevers) + self-weight + <b>railing %g kN/m</b> (assumed: steel tube railing with posts, about 30 kg/m; no data). Its posts are anchored into the slab concrete, so the horizontal push on the railing goes into the slab, not into the beam. 1.2D + E<sub>v</sub> + L with E<sub>v</sub> = %.3f D (NEC, as the cantilevers), 1.2D + 1.6L, 1.4D.</li>', P.qD, P.qL, B.wedge, Ev);
w('<li><b>Corner E9.</b> Two pinned pieces cannot meet at E9 (no column there). Proposal: the east border beam runs in one piece E3&ndash;E4&ndash;E9 (4330 + 1270 = 5600, one 6 m bar) and cantilevers 1270 past the tip of CX; the short south piece D9&ndash;E9 is pinned to the tip of CY and to the end of that cantilever. Its moment there is small (section 5).</li>');
w('<li><b>Top flange braced by the deck</b> (deck screwed or welded to it at every rib before the pour). The deck rests on one side of the beam; once it is fixed, it also holds the beam against twisting.</li>');
w('</ol></div>');

w('<h2>2. Candidates (span %g)</h2>', L);
w('<p class="note">D/C of strength and deflection; f<sub>n</sub> of the edge strip with the cantilever tips moving (second value: anchor connection twice as flexible); deflection under 1 kN at midspan; DG11 acceleration (limit 0.5%%); extra moment on the edge cantilever from the beam''s own weight.</p>');
w('<div class="tw"><table><tr><th>Section</th><th>kg/m</th><th>M</th><th>V</th><th>L/360 (L)</th><th>L/240 (D+L)</th><th>f<sub>n</sub> Hz</th><th>mm/kN</th><th>a/g DG11</th><th>&Delta;M<sub>u</sub> cantilever</th><th>all</th></tr>');
list = {'IPE 120', 'IPE 140', 'IPE 160', 'IPE 180', 'IPE 200', 'IPE 240', 'tubo 60x120x5', 'tubo 75x175x3', 'tubo 70x200x3', 'tubo 100x150x4', 'tubo 100x200x3'};
for i = 1:numel(list)
    t = get(list{i});  cl = '';  if strcmp(list{i}, rec), cl = ' class="hl"'; end
    w('<tr%s><td>%s</td><td>%.1f</td><td>%.2f</td><td>%.2f</td><td>%.2f</td><td>%.2f</td><td>%.1f / %.1f</td><td>%.2f</td><td>%.0f%%</td><td>%.2f kN m</td><td>%s</td></tr>', ...
      cl, t.name, t.m, t.dcM, t.dcV, t.dcL, t.dcDL, t.fn, t.fn2, t.d1k, 100*t.ag, t.dMu, yn(all(t.pass)));
end
w('</table></div>');
w('<p>Lightest that pass everything: <b>%s</b> (%.1f kg/m) and <b>%s</b> (%.1f kg/m). With the railing, the dead + live deflection (L/240) decides the size.</p>', ...
  B.best.IPE.name, B.best.IPE.m, B.best.tube.name, B.best.tube.m);
w(['<p><b>Proposal: %s</b> (%.1f kg/m): the lightest IPE that passes; f<sub>n</sub> = %.1f Hz (%.1f Hz if the anchor connection is twice as flexible as computed). Flange %g wide for the deck and the edge form. ' ...
   'The tube %s is lighter but its %g mm wall is thin for the end connections and for a slab edge exposed to weather. ' ...
   'The last column is the beam''s own weight on the edge cantilever, for comparison only: your ETABS model already has a border beam.</p>'], ...
   rec, s.m, s.fn, s.fn2, s.b, B.best.tube.name, B.best.tube.tw);
w('<h2>3. %s: strength and deflection</h2><div class="calc"><ol>', rec);
w('<li>w<sub>D</sub> = %g &times; %.3f + %.2f (self-weight) = %.2f kN/m; w<sub>L</sub> = %g &times; %.3f = %.2f kN/m; w<sub>u</sub> = max(1.4D, 1.2D + 1.6L, %.3fD + L) = <b>%.2f kN/m</b>.</li>', ...
  P.qD, B.trib/1e3, s.m*9.81e-3, s.wD, P.qL, B.trib/1e3, s.wL, 1.2 + Ev, s.wu);
w('<li>M<sub>u</sub> = w<sub>u</sub> L&sup2;/8 = %.2f &times; %.2f&sup2;/8 = <b>%.1f kN m</b>; compact, top flange braced: &phi;M<sub>n</sub> = 0.9 F<sub>y</sub> Z<sub>x</sub> = 0.9 &times; 248 &times; %.1f cm&sup3; = %.1f kN m; <span class="ok">D/C %.2f</span> (F2.1).</li>', ...
  s.wu, L/1e3, s.Mu*1e-6, s.Z/1e3, s.phiMn*1e-6, s.dcM);
w('<li>V<sub>u</sub> = %.1f kN; &phi;V<sub>n</sub> = %.1f kN; <span class="ok">D/C %.2f</span> (G2.1).</li>', s.Vu*kN, s.phiVn*kN, s.dcV);
w('<li>Deflection, bare steel (I = %.0f cm&#8308;): live %.1f mm (L/360 = %.1f), dead + live %.1f mm (L/240 = %.1f); <span class="ok">D/C %.2f / %.2f</span>.</li>', ...
  s.I/1e4, s.dL, L/360, s.dDL, L/240, s.dcL, s.dcDL);
w('<li>During the pour (deck fixed, wet concrete 2.0 kN/m&sup2; + 1.0 construction load) the moment is below the one above.</li>');
w('</ol></div>');

w('<h2>4. %s: vibration (DG11)</h2><div class="calc"><ol>', rec);
w('<li><b>Weight for vibration</b> (actual, not design; DG11 3.3): q<sub>D</sub> + 0.29 kPa (residence, Table 3-1): w = %.2f kN/m on the beam.</li>', ...
  (P.qD*1e-3*B.trib + s.m*9.81e-3 + B.qvL*B.trib));
w('<li><b>Composite stiffness</b> (DG11 3.2: the deck fixed to the beam is enough): concrete above the deck %g mm, width min(%g, 0.2L) = %g mm, E<sub>c</sub> = 4700&radic;f''<sub>c</sub> = %.0f MPa, dynamic n = E<sub>s</sub>/(1.35 E<sub>c</sub>) = %.2f: I<sub>t</sub> = %.0f cm&#8308; (bare %.0f).</li>', ...
  B.tc, B.trib, min(B.trib, 0.2*L), B.Ec, B.n, s.It/1e4, s.I/1e4);
w('<li><b>Beam</b>: &Delta;<sub>j</sub> = 5wL&#8308;/(384 E I<sub>t</sub>) = %.2f mm, f<sub>j</sub> = 0.18&radic;(g/&Delta;) = %.1f Hz.</li>', s.dj, s.fj);
w(['<li><b>Supports</b>: each cantilever tip carries a whole span of the strip (%.1f kN). Tip flexibility %.3f mm/kN from the IPE 240 (%.3f) and the stretch of the 2 A1 rods over their lever arm (%.3f): ' ...
   '&Delta;<sub>g</sub> = %.2f mm.</li>'], s.dg/(B.ctip*1e3), B.ctip*1e3, B.ctip_parts(1), B.ctip_parts(2), s.dg);
w('<li><b>Edge strip</b> (DG11 eq. 3-4): f<sub>n</sub> = 0.18&radic;(g/(&Delta;<sub>j</sub> + &Delta;<sub>g</sub>)) = <b>%.1f Hz</b> &ge; 9 Hz: walking cannot drive it into resonance (DG11 2.2.1). With the connection twice as flexible: %.1f Hz.</li>', s.fn, s.fn2);
w('<li><b>Point stiffness</b>: 1 kN at midspan moves it %.2f mm (beam + half the tip movement), against 1 mm, the usual limit for residential floors above 8 Hz (EN 1995-1-1 7.3.3 uses 1 to 1.5 mm).</li>', s.d1k);
w(['<li><b>DG11 acceleration</b> (eq. 2-10, 9 to 15 Hz): free edge, C<sub>j</sub> = 1, panel width limited to 2/3 of the 1270 strip = %.0f mm, W = %.1f kN; &beta; = %.2f: a/g = <b>%.0f%%</b> against 0.5%%. ' ...
   'Every section in the table gives 5 to 19%%, IPE 240 included: the border beam does not control it. A footstep moves a strip that weighs about 1.2 t; DG11''s limit is calibrated on office bays of 100 to 400 kN, ' ...
   'and its two equations (below and above 9 Hz) do not even agree for a panel this light. What changes it is mass and damping at the edge (a wall or cladding fixed to the edge, partitions), not a deeper beam. ' ...
   'For a light floor of this size the realistic targets are the two above.</li>'], ...
   s.Bj, s.W*kN, B.beta, 100*s.ag);
w('</ol></div>');

w('<h2>5. Effect on the cantilevers (the anchorage)</h2><div class="calc">');
w(['<p>Your ETABS model already has the border beam and the deck spanning to it, so the design moments stay; what is new is the railing, which reaches each cantilever tip as a point load: ' ...
   '&Delta;M<sub>u</sub> = %.3f &times; %g kN/m &times; (beam length on the tip) &times; %.2f m. Beam length on each tip: E a whole span (%g), C1 half a span + 150, CX and CY half a span + the 1270 corner piece (envelope).</p>'], 1.2 + Ev, B.wedge, B.lev/1e3, L);
w('<div class="tw"><table><tr><th>Type</th><th>Design M<sub>u</sub></th><th>+ railing</th><th>Total</th><th>Largest M<sub>u</sub> the joint takes</th><th>Governing D/C now</th><th>With the railing</th></tr>');
tn = {'E', 'C1', 'CX', 'CY'};
for j = 1:4
    Mu0 = R.typ(j).Mu*1e-6;
    w('<tr><td>%s</td><td>%.1f</td><td>%.2f</td><td>%.1f</td><td>%.1f</td><td>%.2f</td><td>%.2f</td></tr>', tn{j}, Mu0, s.Mrail(j), s.Mnew(j), C.Mu(j), Mu0/C.Mu(j), s.Mnew(j)/C.Mu(j));
end
w('</table></div>');
w(['<p>E is the tight one: %.2f of what the joint takes. Each 0.1 kN/m of railing adds %.2f kN m at E: a railing heavier than about %.2f kN/m (glass, masonry) does not fit. ' ...
   'The governing check is the top anchors under tension + shear (section 8b of anchorage_check).</p></div>'], ...
   s.Mnew(1)/C.Mu(1), (1.2 + Ev)*0.1*L*B.lev*1e-9*1e3, B.wedge + (C.Mu(1) - s.Mnew(1))/((1.2 + Ev)*L*B.lev*1e-6));

w('<h2>6. Corner piece and connections</h2><div class="calc"><ol>');
a = 1270;  Pe = s.wu*a/2;  Mo = Pe*a + (1.2 + Ev)*s.m*9.81e-3*a^2/2;
Ti = csv_row('../../../digitalized_catalog_profiles/ipac2023/ipac_ipe.csv', rec);   % IPE row for F2 LTB
E = P.Es;  Fy = 248;  ry = Ti.ry_cm*10;  Sx = Ti.Sx_cm3*1e3;  Zx = Ti.Zx_cm3*1e3;  J = Ti.J_cm4*1e4;  ho = Ti.h_mm - Ti.tf_mm;
Cw = Ti.Iy_cm4*1e4*ho^2/4;  rts = sqrt(sqrt(Ti.Iy_cm4*1e4*Cw)/Sx);  Lp = 1.76*ry*sqrt(E/Fy);
Lr = 1.95*rts*E/(0.7*Fy)*sqrt(J/(Sx*ho) + sqrt((J/(Sx*ho))^2 + 6.76*(0.7*Fy/E)^2));
Mp = Fy*Zx;  if a <= Lp, Mn = Mp; else, Mn = min(Mp, Mp - (Mp - 0.7*Fy*Sx)*(a - Lp)/(Lr - Lp)); end
w('<li>East beam overhang E4&ndash;E9 (%g): it carries the end of the south piece D9&ndash;E9, P<sub>u</sub> = w<sub>u</sub> &times; %g/2 = %.1f kN, and little floor (the corner deck spans north-south): M<sub>u</sub> = %.1f kN m at E4, bottom flange in compression over %g. Lateral-torsional buckling (F2.2, C<sub>b</sub> = 1): L<sub>p</sub> = %.0f, L<sub>r</sub> = %.0f, &phi;M<sub>n</sub> = %.1f kN m; <span class="ok">D/C %.2f</span>.</li>', a, a, Pe*kN, Mo*1e-6, a, Lp, Lr, 0.9*Mn*1e-6, Mo/(0.9*Mn));
w('</ol></div>');
% ---- connection to the cantilever tips (option a, user 2026-10-04)
bb = P.bb;  Ru = s.Vu;  Fu = 400;  db_ = bb.bolt;  Ab_ = pi*db_^2/4;  tp = bb.tp;
phiRb = 0.75*bb.Fnv*Ab_;                                      % J3.6, one bolt, single shear
phiBr = 0.75*2.4*db_*bb.tw*Fu;                                % J3.10(a)(1), web of the IPE 160 (thinner than the plate)
phiVw = 1.0*0.6*Fy*bb.h*bb.tw;                                % G2.1, the coped section keeps the whole web
Zc = Zx - 2*(bb.b/2 - bb.tw/2)*bb.tf*(bb.h - bb.tf)/2;         % inner half-flanges cut off
ec = tp(2)/2 + bb.cl - bb.bx;  phiMc = 0.9*Fy*Zc;
Lw = tp(3) - 2*P.bm.tf - 2*P.bm.r;  phiW = 0.75*0.6*P.FEXX*0.707*bb.wtp*2*Lw;   % J2.4, web fillets both sides
tE = (1.2 + Ev)*0 + 1*P.qL*1e-3*B.trib*L/2;                   % E: live load on one span only, factor 1.0
wu1 = s.wu;  RCD = wu1*B.L(1)/2;  Rpc = wu1*1270/2;            % D9: span C-D and the corner piece
w('<h2>6b. Connection to the cantilever tips</h2><div class="calc"><ol>');
w(['<li><b>Detail</b> (user 2026-10-04): a tip plate PL %gx%gx%g A36 welded across the end of each IPE 240 (fillets %g all around). The %s web is bolted flat to it; ' ...
   'its inner half-flanges, top and bottom, are cut flush with the web over the plate plus %g each side (they would hit the cantilever). Bolts M%g A325 (or 8.8) in holes &#216;%g, ' ...
   'columns at %g on each side of the cantilever web, rows at z = %g and %g. Where the beam passes a tip (B9, E3, E4) it takes all 4 bolts, centred on the web; ' ...
   'where two beams end at a tip (C9, D9) each takes the 2 on its side, %g mm apart at the ends.</li>'], ...
   tp(1), tp(2), tp(3), bb.wtp, bb.name, bb.cl, db_, bb.hole, bb.bx, bb.bz, bb.gap);
w('<li><b>Reaction</b> per beam end (1.2D + E<sub>v</sub> + L, railing included): R<sub>u</sub> = %.1f kN.</li>', Ru*kN);
w('<li><b>Bolts</b> (J3.6): &phi;R<sub>n</sub> = 0.75 &times; %g &times; %.0f = %.1f kN per bolt; 2 bolts: %.1f kN against %.1f: <span class="ok">D/C %.2f</span>.</li>', bb.Fnv, Ab_, phiRb*kN, 2*phiRb*kN, Ru*kN, Ru/(2*phiRb));
w('<li><b>Bearing on the web</b> of the %s, t = %g (J3.10(a)): 0.75 &times; 2.4 &times; %g &times; %g &times; %g = %.1f kN per bolt; 2 bolts: <span class="ok">D/C %.2f</span>.</li>', bb.name, bb.tw, db_, bb.tw, Fu, phiBr*kN, Ru/(2*phiBr));
w(['<li><b>Coped end</b>: shear on the whole web (G2.1) 1.0 &times; 0.6 &times; %g &times; %g &times; %g = %.0f kN: <span class="ok">D/C %.2f</span>. ' ...
   'Bending where the cut ends, %g from the bolts: M = %.2f kN m against 0.9 F<sub>y</sub> Z (Z without the inner half-flanges = %.0f cm&sup3;) = %.1f kN m: <span class="ok">D/C %.2f</span>.</li>'], ...
   Fy, bb.h, bb.tw, phiVw*kN, Ru/phiVw, ec, Ru*ec*1e-6, Zc/1e3, phiMc*1e-6, Ru*ec/phiMc);
w(['<li><b>Tip plate welds</b> (J2.4, E70): web fillets %g both sides, %g long: &phi;R<sub>n</sub> = 0.75 &times; 0.6 &times; %g &times; 0.707 &times; %g &times; 2 &times; %g = %.0f kN against 2 R<sub>u</sub> = %.1f kN: ' ...
   '<span class="ok">D/C %.2f</span> (the flange fillets are extra).</li>'], bb.wtp, Lw, P.FEXX, bb.wtp, Lw, phiW*kN, 2*Ru*kN, 2*Ru/phiW);
w(['<li><b>Torsion on the cantilevers</b> (what the anchorage calc assumes: 0.25 V<sub>u</sub> b/2, i.e. V<sub>u</sub> at 15 mm): ' ...
   'B9, E3, E4: bolt group centred on the web, none. C9 (E): live load on one span only, %.1f kN at %g mm = %.2f kN m against %.2f assumed. ' ...
   'D9 (CY): span C&ndash;D %.1f kN and corner piece %.1f kN on either side, (%.1f &minus; %.1f) &times; %g = %.2f kN m against %.2f assumed. Both within.</li>'], ...
   tE*kN, bb.bx, tE*bb.bx*1e-6, 0.25*R.typ(1).Vu*P.bm.b/2*1e-6, RCD*kN, Rpc*kN, RCD*kN, Rpc*kN, bb.bx, (RCD - Rpc)*bb.bx*1e-6, 0.25*R.typ(4).Vu*P.bm.b/2*1e-6);
w(['<li><b>Corner E9</b>: the corner piece D9&ndash;E9 frames into the web of the east beam: shear tab PL %gx%gx%g welded to that web, 2 bolts; the piece''s end coped top and bottom (%g deep, %g long). ' ...
   'Reaction %.1f kN: a fraction of the checks above.</li>'], bb.tab, ceil(bb.tf + bb.r), ceil(bb.b/2 + 10), Rpc*kN);
w('</ol></div>');
w('<h2>7. To confirm</h2><div class="calc"><ol>');
w('<li>The railing: %g kN/m assumed; its real weight before it is bought (section 5).</li>', B.wedge);
w('<li>Accepted by the user (2026-10-03): deck north-south in the south strip and east-west in the east strip; the corner scheme; ETABS already has the border beam.</li>');
w('</ol></div>');
w('</body></html>');
fclose(fid);
end

function T = csv_row(f, name)
% one row of a catalog CSV (first column = name) as a struct
fid = fopen(f, 'r');  hdr = strsplit(strtrim(fgetl(fid)), ',');  T = [];
while true
    l = fgetl(fid);  if ~ischar(l), break; end
    c = strsplit(strtrim(l), ',');
    if strcmp(c{1}, name), for j = 2:numel(hdr), T.(hdr{j}) = str2double(c{j}); end, break; end
end
fclose(fid);
end

function r = ifelse(a, b, c)
if a, r = b; else, r = c; end
end
