function ca_scheme_report(P, R, fname)
% CA_SCHEME_REPORT  HTML page of the double plate scheme: figures, site
%   requirements, materials, clearances and first sizing. Every number comes from P or R.
fid = fopen(fname, 'w');
w = @(varargin) fprintf(fid, [varargin{1} '\n'], varargin{2:end});
E = R.typ(1);  X = R.typ(2);  Y = R.typ(3);
cl = @(name) R.clr{strcmp(R.clr(:,1), name), 2};    % a clearance by its name
pr = @(t, name) R.pre{strcmp(R.pre(:,1), t) & strcmp(R.pre(:,2), name), 3}/R.pre{strcmp(R.pre(:,1), t) & strcmp(R.pre(:,2), name), 4};
w('<!doctype html><html><head><meta charset="utf-8"><title>Double plate scheme</title>');
w(['<style>body{font-family:Helvetica,Arial,sans-serif;max-width:1150px;margin:24px auto;padding:0 16px;color:#111;line-height:1.45}' ...
   'h1{font-size:24px}h2{font-size:19px;margin-top:34px;border-bottom:1px solid #ccc}h3{font-size:16px}' ...
   'figure{margin:18px 0}figure img{width:100%%;border:1px solid #ddd}figcaption{font-size:13px;color:#333}' ...
   'table{border-collapse:collapse;font-size:13px;margin:10px 0}td,th{border:1px solid #ccc;padding:3px 7px;text-align:left}' ...
   'td.n{text-align:right}.bad{background:#f9d6d5}.warn{background:#fdf0c9}.ok{background:#e3f1e3}' ...
   '.grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}.grid img{width:100%%;border:1px solid #ddd}</style></head><body>']);
w('<h1>Cantilever anchorage, double plate concept: scheme</h1>');
w('<p>Status: <b>scheme, revision 2</b>, 2026-10-01. Layout accepted by the user; corner changed and rods chosen after the user''s decisions (below). Strength numbers are a first sizing only; the full limit-state table comes next.</p>');
w('<p><b>Changes from revision 1.</b> (1) Unknown beam-bar layers are taken as the least favourable for every check (user decision). The corner type CY with rods <i>under</i> the flange then clashes with the crossing bars, so both corner beams now have their rods <i>over</i> the flange, at two levels: CX at z = %+.0f, CY at z = %+.0f. No part of the scheme depends on which beam bars are on top. (2) Rods 5/8" ASTM A193 B7: F1554 is not stocked in Ecuador, B7 is (section 7). (3) Two closed ties %s%g at the top of every pedestal, required by ACI 10.7.6.1.5 for the steel column anchor rods; the earlier designs had one tie there.</p>', X.rowT(1), Y.rowT(1), '&#216;', P.top.db);

w('<h2>1. What it is</h2>');
w('<ul><li><b>Embedded assembly</b> (shop-made, no welds): a <b>front plate</b> PL %gx%g cast flush with the outer face, straight rods %s B7, and a <b>back plate</b> PL %gx%gx%g at the far side of the joint, behind the far column bars and ties. Nuts on both faces of both plates make it a rigid frame.</li>', P.fp.t, P.fp.w, P.tr.lab, P.bp.t, P.bp.h, P.bp.w);
w('<li><b>Steel beam</b> %s with a shop-welded extended end plate PL %gx%g, bolted on site to the rods against the front plate. <b>No site welding.</b></li>', P.bm.name, P.ep.t, P.ep.w);
w('<li>2 <b>tension rods</b> over the top flange carry the pull. 2 <b>shear rods</b> over the bottom flange carry the shear; they sit in the compression zone and never see tension.</li>');
w('<li>The beam top bars cross the whole breakout body and are hooked at the front: they are the anchor reinforcement, %.0f mm or more inside the body with every tolerance against (ldh = 150).</li></ul>', min(cell2mat(R.pre(strcmp(R.pre(:,2), 'Beam bars inside the breakout body vs ldh (mm, tolerances on)'), 4)))/1e3);
w('<table><tr><th>Type</th><th>Where</th><th>Tension rods</th><th>Shear rods</th><th>Rod lengths</th><th>End plate top</th></tr>');
wh = {'edge columns', 'corner, beam X', 'corner, beam Y'};
for j = 1:3
    T = R.typ(j);
    w('<tr><td>%s</td><td>%s</td><td>z = %+.1f, |v| = %g</td><td>z = %+.1f, |v| = %g</td><td>%g / %g</td><td>%+.0f</td></tr>', T.name, wh{j}, T.rowT(1), T.rowT(2), T.rowS(1), T.rowS(2), T.L(1), T.L(2), T.ep_top);
end
w('</table><p>E and CX are the same piece. CY differs only in the level of the tension rods and the plates. At a corner either beam can be X; the column hooks are bent along Y.</p>');

w('<h2>2. Edge column</h2>');
fig(fid, 'edge_elev', 'Figure 1. Edge, type E: section along the steel beam.');
fig(fid, 'edge_plan', 'Figure 2. Edge: plan, all rods projected. Solid red = tension rods; light red = shear rods (lower).');
fig(fid, 'edge_front', 'Figure 3. Edge: seen from outside. Circles = nut corners against the flange and web fillets.');
w('<h2>3. Corner column</h2>');
fig(fid, 'cor_plan', 'Figure 4. Corner: plan. Beam X with type CX (rods low), beam Y with type CY (rods high, crossing over those of X).');
fig(fid, 'cor_elevX', sprintf('Figure 5. Corner, beam X, type CX. The rods of Y cross this section %.0f mm over the rods of X.', cl('Corner: rods of X - rods of Y, where they cross')));
fig(fid, 'cor_elevY', 'Figure 6. Corner, beam Y, type CY.');
w('<h2>4. The embedded pieces</h2>');
fig(fid, 'assy_E', 'Figure 7. Assembly E = CX.');
fig(fid, 'assy_Y', 'Figure 8. Assembly CY.');

w('<h2>5. Placing sequence (edge; the corner is the same per beam)</h2><div class="grid">');
for s = 1:5, w('<img src="figures/seq%d.png">', s); end
w('</div><p>Figure 9. The two top ties go first, dropped over the column bars (the hooks are not bent yet). The shear rods go in from the front, between the joint tie layers. The back plate goes in from above, behind the far ties. The tension rods go in from the front over the top ties; their nuts are reached from above. At the corner, CX first, then CY over it.</p>');

w('<h2>6. What the site must do</h2><ol>');
w('<li><b>Top ties:</b> 2 closed ties %s%g at %+g and %+g, before the rods (ACI 10.7.6.1.5: two No. 4 within 127 mm of the top of a pedestal with anchor bolts).</li>', '&#216;', P.top.db, P.top.z);
w('<li><b>Column top hooks</b> (not bent yet): along the steel beam at the edge, along beam Y at the corner. The two mid-face hooks on the same line go side by side. <b>Hold point at the corner:</b> the hooks pass %.0f mm over the rods of X.</li>', cl('Corner: rods of X - column hooks bent along Y, where they cross'));
w('<li><b>Edge:</b> closed tie %s%g at +%g instead of +45, after the rods (%.0f mm over them).</li>', '&#216;', P.hoop.db, P.hoop.ztop, cl('Edge: rods - closed tie 10 at +50'));
w('<li><b>Joint ties</b> as planned (-90, -135, -180, -225). The shear rods pass between them with 8 to 9 mm. Nothing changes if they are already tied.</li>');
w('<li><b>Outer face of the joint open</b> (no form yet) for step 1, or opened locally.</li>');
w('<li><b>Deck</b> notched around the end plates (top at %+.0f for E/CX, %+.0f for CY; slab top +%g). The nuts end up inside the slab.</li>', E.ep_top, Y.ep_top, P.slab.t);
w('<li><b>Steel beams</b> after the pour; end-plate holes drilled from the front plate template, so placing errors of the assembly do not reach the bolting.</li></ol>');

w('<h2>7. Rods: material and suppliers</h2>');
w('<p><b>Specified:</b> threaded rod <b>ASTM A193 B7, 5/8"-11 UNC</b> (fy 105 ksi = %g MPa, fu 125 ksi; futa = %g MPa in ACI 17.6.1.2), heavy hex nuts ASTM A194 2H on the tension rods, regular hex nuts on the shear rods (end-plate side), hardened washers F436. Black finish, threads greased and taped for the pour. Ask for the mill certificate (heat number on the bars).</p>', P.tr.fya, P.tr.futa);
w('<p><b>Why B7.</b> ASTM F1554 (the anchor-rod standard) did not show up in any Ecuadorian catalogue found. B7 is stocked in Ecuador as "varilla roscada negra estructural". It qualifies as a ductile steel element in ACI 318 (elongation 16 %%, reduction of area 50 %%; ACI asks 14 %% and 30 %%). The common galvanized "grado 2" rod (A307) has no specified reduction of area, so it would have to be treated as brittle (&phi; = 0.65): it would still pass the edge (D/C about %.2f), but there is no certificate behind it. Grade 5 rod is an acceptable second choice.</p>', E.T/2/(0.65*P.tr.Ase*414));
w('<table><tr><th>Supplier</th><th>Where</th><th>What the web page shows</th><th>Contact</th></tr>');
w('<tr><td>BP Ecuador</td><td><b>Cuenca</b>: Panamericana Sur km 3 (Narancay) and Av. Gil Ram&iacute;rez D&aacute;valos 5-140 (Terminal Terrestre)</td><td>inch threaded rod, coarse thread, grade 5, 90 cm and 3.66 m; grade 8 bolts. B7 not listed: ask.</td><td>+593 99 515 4029, servicioalcliente@bpecuador.com</td></tr>');
w('<tr><td>Importadora Banco del Perno</td><td><b>Cuenca</b>: Av. Huayna C&aacute;pac 5-57 y Gran Colombia</td><td>bolt importer (directory listing only; stock not checked)</td><td>by phone / visit</td></tr>');
w('<tr><td>Castillo Hermanos</td><td>Quito (ships nationwide)</td><td>threaded bars in mm and inch, grade 2 / 5 / <b>structural ASTM B7</b>, natural, black or galvanized</td><td>(02) 2475785, ventas@castillohermanos.com</td></tr>');
w('<tr><td>Casa del Perno</td><td>Sangolqu&iacute; (Quito)</td><td>"varilla roscada negra estructural pulgadas UNC, ASTM A193-B7"</td><td>WhatsApp +593 99 851 9040</td></tr>');
w('</table><p>Per assembly: 2 rods %g mm + 2 rods %g mm, 16 nuts (10 heavy hex for the tension rods, 6 regular for the shear rods), 8 washers. One 3.66 m bar (12 ft) is enough for two assemblies (2 x %g mm). Confirm stock of 5/8" B7 and the heavy nuts by phone before the pour date.</p>', E.L(1), E.L(2), 2*(E.L(1) + E.L(2)));

w('<h2>8. Clearances (nominal, mm)</h2><table><tr><th>Between</th><th>mm</th><th>Note</th></tr>');
for i = 1:size(R.clr,1)
    v = R.clr{i,2};  c = 'ok';  if v < 10, c = 'warn'; end;  if v < 0, c = 'bad'; end
    w('<tr class="%s"><td>%s</td><td class="n">%.1f</td><td>%s</td></tr>', c, R.clr{i,1}, v, R.clr{i,3});
end
w('</table><p>Yellow: under 10 mm. None of them depends on a beam bar position any more: the tension rods are all above the beams, the shear rods between the top and bottom bars.</p>');

w('<h2>9. First sizing (not the final check)</h2>');
w('<p>Demands at the column face: edge Mu = %.2f kN m, Vu = %.1f kN; corner envelope Mu = %.2f kN m, Vu = %.1f kN. Compression at the bottom flange centroid (z = %.1f). Rods %s B7: Ase = %g mm&sup2;, futa = %g MPa. Conservative assumptions: beam bars on the lower layer and 13 mm lower still, 25 mm short at the hooks; corner beams VCS (3 bars); edge VCM pairs in contact (one bar per pair counted).</p>', R.kase(1).Mu/1e6, R.kase(1).Vu/1e3, R.kase(3).Mu/1e6, R.kase(3).Vu/1e3, R.z.C, P.tr.lab, P.tr.Ase, P.tr.futa);
w('<table><tr><th>Type</th><th>Check</th><th>Demand</th><th>Capacity</th><th>D/C</th></tr>');
for i = 1:size(R.pre,1)
    r = R.pre{i,3}/R.pre{i,4};  c = 'ok';  if r > 0.85, c = 'warn'; end;  if r > 1, c = 'bad'; end
    un = 'kN';  sc = 1e3;
    if ~isempty(strfind(R.pre{i,2}, 'End plate')), un = 'kN m'; sc = 1e6; end
    if ~isempty(strfind(R.pre{i,2}, '(mm')), un = 'mm'; sc = 1e3; end
    w('<tr class="%s"><td>%s</td><td>%s</td><td class="n">%.1f %s</td><td class="n">%.1f %s</td><td class="n">%.2f</td></tr>', c, R.pre{i,1}, R.pre{i,2}, R.pre{i,3}/sc, un, R.pre{i,4}/sc, un, r);
end
w('</table>');
w('<p>Unreinforced concrete breakout of type E (17.6.2, three edges, hef limited to %.0f): &phi;N<sub>cbg</sub> = %.1f kN, far below T = %.1f kN, so the beam top bars are needed as anchor reinforcement. Governing items now: anchor reinforcement of the edge (%.2f, 3 bars counted) and the end plate strip of CY (%.2f, lower bound). The rods are no longer critical (%.2f).</p>', R.brk.hefp, R.brk.phiN/1e3, E.T/1e3, pr(E.name, 'Anchor reinforcement, 3 top bars of the beam (17.5.2.1)'), pr(Y.name, 'End plate, cantilever strip fixed at the weld toe'), pr(E.name, 'Rod steel in tension (17.6.1)'));
w('<p>Seismic: the share of E<sub>v</sub> in the anchor tension is %.0f%% (more than 20%%, 17.10.5.2). Option 17.10.5.3(d) amplifies only E<sub>h</sub> by &Omega;<sub>o</sub>; this cantilever has E<sub>v</sub> only, so the design combination stands. The anchor reinforcement is INEN 2167 (A706 type), as 17.10.4 requires.</p>', 100*R.kase(1).fE);

w('<h2>10. Still to check (full calculation)</h2><ul>');
w('<li>Rods: tension, shear, interaction (17.8); pryout of the shear rods (17.7.3); shear breakout; pullout of the back plate; side-face blowout with the exact plate geometry.</li>');
w('<li>Anchor reinforcement with the cone of each type, development on both sides (25.4), placing tolerances, as in V2.</li>');
w('<li>End plate: extended two-bolt case with prying (DG4 / DG16 yield lines), shop welds, beam web and flanges at the end.</li>');
w('<li>Front plate: bearing on the concrete under the bottom flange (DG1), plate bending, vent holes. Back plate: bending between the rods, bearing.</li>');
w('<li>Joint shear (15.4.2), negative moment of the concrete beams (VCS room about 16 kN m against Mu = %.2f at the corner; needs the frame moments), pedestal strut path, torsion at the corner, cantilever deflection, connection stiffness.</li>', R.kase(3).Mu/1e6);
w('</ul>');

w('<h2>11. Verdict on the geometry</h2>');
w('<p><b>It can be placed with the site as it is, and with the least favourable bar layout.</b> No bar has to be cut or moved. The site only bends the hooks (after the rods), places two extra ties at the top before the rods, and moves the edge closed tie to +50. Nothing waits for the site''s answers about the bars.</p>');
w('<p>Main risks: (1) the corner hooks %.0f mm over the rods of X (hold point); (2) concrete compaction behind the front plate (vent holes, vibrate from above); (3) protruding threads damaged before bolting; (4) supply of B7 in time.</p>', cl('Corner: rods of X - column hooks bent along Y, where they cross'));
w('</body></html>');
fclose(fid);
end

function fig(fid, name, cap)
fprintf(fid, '<figure><img src="figures/%s.png"><figcaption>%s</figcaption></figure>\n', name, cap);
end
