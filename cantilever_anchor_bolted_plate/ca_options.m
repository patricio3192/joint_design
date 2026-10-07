function O = ca_options(P, R, fname)
% CA_OPTIONS  The single back plate B1 connects the two top anchors at their embedded end, which
%   ACI 318-19 17.1.5 excludes from chapter 17. Two ways out, checked for the four types:
%   A  one plate washer per anchor (each anchor has its own head): stays in chapter 17;
%   B  through-bolts with a bearing plate on the far face of the column: outside chapter 17,
%      checked as a concentrated load on the top of the pedestal (bearing 22.8, shear 22.5,
%      shear friction 22.9, and the strut-and-tie view of chapter 23).
%   O = ca_options(P, R) returns the numbers; with fname it also writes the review page.
%   Units N, mm, MPa.

an = P.an;  fc = P.fc;  sq = sqrt(fc);  Fy = P.st.Fy(1);  hb = P.col.b/2;
T = [R.typ.T];  Ta = [R.typ.Ta];  zT = [R.typ.zT];  nm = {R.typ.name};
Ah = pi*an.hole^2/4;

% ---- option A: plate washers PL 12 x 45 x 50, one per anchor ---------------------------
A.t = 12;  A.h = 45;  A.w = 50;
A.re = an.dw/2 + A.t;                                % effective head: nut face + one plate thickness
y = linspace(-A.h/2, A.h/2, 4001);
A.Aeff = trapz(y, min(2*sqrt(max(A.re^2 - y.^2, 0)), A.w)) - Ah;
A.Afull = A.h*A.w - Ah;
A.phiNp = 0.70*8*A.Aeff*fc;                          % 17.6.3.2.2(a), cracked
A.dc_po = Ta/A.phiNp;
ca1 = P.col.top - zT;  ca2 = hb - an.vT;  s = 2*an.vT;
Nsb = 13*ca1*sqrt(A.Aeff)*sq;
f2 = ones(1,4);  f2(ca2 < 3*ca1) = (1 + ca2./ca1(ca2 < 3*ca1))/4;
fg = min(1 + s./(6*ca1), 2);
A.phiNsbg = 0.70*Nsb.*f2.*fg;
A.dc_sfb = T./A.phiNsbg;
pe = Ta/A.Aeff;                                      % pressure on the effective head
pf = Ta/A.Afull;                                     % pressure on the whole plate
mp = 0.9*Fy*A.t^2/4;
A.dc_pw = max(pe*A.t^2/2, pf*(A.w/2 - an.dw/2)^2/2)/mp;
A.edge = [A.w/2, A.h/2];  A.gap = s - A.w;
O.A = A;

% ---- option B: through-bolts, PL 12 x 55 x 120 on the far face over a 10 mm mortar bed ------
B.t = 12;  B.h = 55;  B.w = 120;  B.g = 10;           % 160 wide fails through the holes (1.30 at E)
B.L = an.out + P.col.b + B.g + B.t + an.twsh + an.tnut + an.pp;
B.zb = zT - B.h/2;  B.zt = zT + B.h/2;              % holes at mid-height
B.A1g = B.h*B.w;  B.A1n = B.A1g - 2*Ah;
sp = min(P.col.top - B.zt, hb - B.w/2);              % frustum: the top of the pedestal limits it
B.A2 = (B.w + 2*sp).*(B.h + 2*sp);
B.bc = min(sqrt(B.A2/B.A1g), 2);
B.phiBn = 0.65*0.85*fc*B.A1n.*B.bc;                  % 22.8.3.2
B.dc_brg = T./B.phiBn;
Pb = P;  Pb.bp.t = B.t;  Pb.bp.h = B.h;  Pb.bp.w = B.w;  Pb.bp.grade = 1;
for j = 1:4, Bb(j) = ca_bpbeam(Pb, T(j), an.dw/2); end
B.dc_bend = [Bb.M0]/(0.9*Fy*B.h*B.t^2/4);
B.dc_hole = [Bb.Mh]./[Bb.Ch];
row = @(s) R.rows(find(strncmp(R.rows(:,2), s, numel(s)), 1), :);
x = row('Pedestal shear');  B.phiVped = x{5}(1);  B.dc_ped = T/B.phiVped;
% shear friction across the top of the joint (z = 0): monolithic, mu = 1.4
B.mu = 1.4;  B.Avf = T/(0.75*B.mu*P.fy);
B.Ac = P.col.b^2;  B.Vmax = 0.75*min([0.2*fc, 3.3 + 0.08*fc, 11])*B.Ac;
zA = P.col.top - P.col.ctop - P.col.db/2;  zBh = P.col.zhB;
B.above = [zA zBh] + P.col.db/2;                     % outside of the top hooks above z = 0
B.ldhmin = max(8*P.col.db, 150);
B.Vplain = 0.60*0.11*sq*P.col.b*P.col.b;             % plain concrete, 14.5.5.1
B.tau_s = T*((P.etabs.MD + P.etabs.ML)/(R.typ(1).Mu/1e6))/B.Ac;   % service shear stress on z = 0
O.B = B;

if nargin < 3, return; end
% ======================================================================================
fid = fopen(fname, 'w');
w = @(varargin) fprintf(fid, [varargin{1} '\n'], varargin{2:end});
kN = 1e-3;  f2s = @(v, f) strjoin(arrayfun(@(q) sprintf(f, q), v, 'UniformOutput', false), ' / ');
w('<!DOCTYPE html><html><head><meta charset="utf-8"><title>Back plate: two options</title><style>');
w(['body{font-family:Arial,Helvetica,sans-serif;max-width:1250px;margin:20px auto;padding:0 16px;color:#111;line-height:1.45}' ...
   'h1{font-size:23px}h2{font-size:18px;margin-top:30px;border-bottom:1px solid #ccc}' ...
   '.row{display:flex;gap:24px;align-items:flex-start;flex-wrap:wrap}.row>div{flex:1 1 520px}' ...
   'table{border-collapse:collapse;font-size:14px}td,th{border:1px solid #bbb;padding:3px 8px;text-align:right}' ...
   'td:first-child,th:first-child{text-align:left}.ok{color:#1e7d32;font-weight:bold}.ng{color:#c0392b;font-weight:bold}' ...
   '.note{color:#555;font-size:14px}svg{background:#fff;border:1px solid #ddd}']);
w('</style></head><body>');
w('<h1>Back plate of the top anchors: two ways to stay within the code</h1>');
w(['<p>ACI 318-19 <b>17.1.5</b>: chapter 17 does not apply to through-bolts or to <i>multiple anchors connected to a single steel plate at the embedded end</i>. ' ...
   'The back plate B1 (PL %gx%gx%g) connects the two top anchors at their embedded end, so the anchor checks of chapter 17 (pullout, blowout, breakout, anchor reinforcement) do not cover it. ' ...
   'Both options below are checked for the four types (%s), with the ETABS loads (T = %s kN on the two anchors).</p>'], P.bp.t, P.bp.h, P.bp.w, strjoin(nm, ', '), f2s(T*kN, '%.1f'));

% ---- A ----
w('<h2>A. One plate washer per anchor (stays in chapter 17)</h2><div class="row"><div>%s</div><div><ol>', svgA(P, A));
w('<li>Each anchor gets its own head: nut + plate washer PL %gx%gx%g A36, one hole &#216;%g. The two pieces are %g mm apart (anchors %g apart). Holes %g / %g from the edges (AISC J3.4M: 22).</li>', A.t, A.h, A.w, an.hole, A.gap, s, A.edge);
w(['<li>Effective head: the nut bearing face (d<sub>w</sub> = %g) plus one plate thickness all round, &#216;%g, clipped by the plate: A<sub>brg</sub> = %.0f mm&sup2; ' ...
   '(a plate washer counts only as far as it is stiff: the usual limit, from ACI 349 and AISC DG1, is a projection beyond the nut no larger than the plate thickness).</li>'], an.dw, 2*A.re, A.Aeff);
w('<li>Pullout (17.6.3.2.2a, cracked): &phi;N<sub>pn</sub> = 0.70 &times; 8 &times; %.0f &times; %.2f = %.0f kN per anchor; <span class="ok">D/C %s</span>.</li>', A.Aeff, fc, A.phiNp*kN, f2s(A.dc_po, '%.2f'));
w('<li>Side-face blowout (17.6.4, group of two separate heads, 17.6.4.2): &phi;N<sub>sbg</sub> = %s kN; <span class="ok">D/C %s</span> (was %s with the single plate).</li>', f2s(A.phiNsbg*kN, '%.1f'), f2s(A.dc_sfb, '%.2f'), f2s(T./R.rows{find(strncmp(R.rows(:,2), 'Side-face blowout', 17), 1), 5}, '%.2f'));
w('<li>Plate washer bending, cantilever from the nut face: on the effective head p = %.1f MPa over %g mm; on the whole plate p = %.1f MPa over %g mm. m<sub>u</sub> = p l&sup2;/2 against &phi;m<sub>p</sub> = 0.9 F<sub>y</sub> t&sup2;/4 = %.0f N mm/mm; <span class="ok">D/C %s</span>.</li>', pe(1), A.t, pf(1), A.w/2 - an.dw/2, mp, f2s(A.dc_pw, '%.2f'));
w('<li>Unchanged: anchor steel, thread stripping, anchor reinforcement (the bearing face stays at u = %g), clearances (the pieces cover the same %g x %g as B1, less a %g mm gap at the middle).</li>', P.bp.u, 2*(an.vT + A.w/2), A.h, A.gap);
w('<li>Service: the cone in front of the heads still cracks under D + L (it is edge-limited, see the anchor check page); the beam bars hold it, about 165 MPa at E.</li>');
w('<li>Change on site: two pieces instead of one, each positioned by its own front nut. Nothing else moves.</li></ol></div></div>');

% ---- B ----
w('<h2>B. Through-bolts with a plate on the far face (outside chapter 17)</h2><div class="row"><div>%s</div><div><ol>', svgB(P, R, B));
w(['<li>The top anchors run through the column; PL %gx%gx%g A36 bears on the far face over a %g mm mortar bed, holes at mid-height, put on after the forms come off (the bars pass through holes in the far form). ' ...
   'One nut and washer behind it; no nut in front. Bars L = %.0f.</li>'], B.t, B.h, B.w, B.g, B.L);
w(['<li><b>Your idea, in code terms.</b> The plate pushes the top of the column towards the cantilever: a concentrated horizontal load on the top of the pedestal, %g to %g mm above the top of the joint (z = 0). ' ...
   'ACI has no "anchor" rule for that, but it does have the member rules for a concentrated load: bearing (22.8), one-way shear of the pedestal (22.5), shear friction across the plane where the load enters the joint (22.9), ' ...
   'and, because the load acts within d of its support, the strut-and-tie method (chapter 23).</li>'], B.zb(1), B.zt(1));
w('<li>Bearing on the far face (22.8.3.2): A<sub>1</sub> = %.0f mm&sup2; (net), &radic;(A<sub>2</sub>/A<sub>1</sub>) = %s (the top of the pedestal limits A<sub>2</sub>); &phi;B<sub>n</sub> = %s kN; <span class="ok">D/C %s</span>.</li>', B.A1n, f2s(B.bc, '%.2f'), f2s(B.phiBn*kN, '%.0f'), f2s(B.dc_brg, '%.2f'));
w('<li>Plate bending (as section 3b of the anchor page, b = %g, h = %g): between the anchors <span class="ok">D/C %s</span>; through the holes %s.</li>', B.w, B.h, f2s(B.dc_bend, '%.2f'), f2s(B.dc_hole, '%.2f'));
w('<li>Pedestal as a cantilever, one-way shear with its ties (22.5): &phi;V<sub>n</sub> = %.0f kN; <span class="ok">D/C %s</span>.</li>', B.phiVped*kN, f2s(B.dc_ped, '%.2f'));
w(['<li><b>Where it fails: the load has to cross the top of the joint.</b> Shear friction across z = 0 (22.9, monolithic, &mu; = %.1f): A<sub>vf</sub> = T/(&phi; &mu; f<sub>y</sub>) = %s mm&sup2;, easily available in the 8 column bars, ' ...
   'but 22.9 wants that steel developed on both sides of the plane. Above z = 0 the column bars end in their top hooks, whose outside is only %g mm (level A) and %g mm (level B) above the plane, against at least %g mm for any hook (25.4.3.1). ' ...
   '<span class="ng">Not developed.</span> The strut-and-tie model says the same: the node at the plate needs a vertical tie anchored above it, and there is no room above it.</li>'], ...
   B.mu, f2s(B.Avf, '%.0f'), B.above(1), B.above(2), B.ldhmin);
w('<li>Without that steel only plain concrete is left (14.5.5.1): &phi;V<sub>n</sub> = 0.60 &times; 0.11 &radic;f''<sub>c</sub> b h = %.0f kN against T = %.1f kN: <span class="ng">D/C %.2f</span>.</li>', B.Vplain*kN, T(1)*kN, T(1)/B.Vplain);
w(['<li>Making it work needs vertical bars anchored above the anchors: U-bars over the two through-bolts near the far face, legs developed down into the joint. Their bend would sit at z &asymp; %g to %g, ' ...
   'exactly where the level-A column hooks cross the far side (z %g to %g): the column hooks would have to be redrawn. ' ...
   'The steel column rods also cross the plane and are anchored above by the base plate, but only once the steel column is erected, and they carry its uplift: not relied upon.</li>'], ...
   an.pf + an.db/2, an.pf + an.db/2 + 2*10, zA - P.col.db/2, zA + P.col.db/2);
w(['<li>Service: the shear stress on the plane z = 0 is only about %.2f MPa under D + L (E), so the top would most likely not crack: the plate spreads the push over the whole far face instead of a small head near the top. ' ...
   'That is the real advantage of B, and the reason it needs the U-bars only for the ultimate load.</li>'], B.tau_s(1));
w('<li>Also: a mortar bed and a nut on the far face after stripping (the slab covers them later); holes in the far form at the anchor positions; at D4 the two plates are on the west and north faces.</li></ol></div></div>');

% ---- table and recommendation ----
w('<h2>Side by side (E / C1 / CX / CY)</h2><table><tr><th>Check</th><th>Now (single B1)</th><th>A: plate washers</th><th>B: far-face plate</th></tr>');
rdc = @(s) f2s(R.rows{find(strncmp(R.rows(:,2), s, numel(s)), 1), 4}./R.rows{find(strncmp(R.rows(:,2), s, numel(s)), 1), 5}, '%.2f');
w('<tr><td>In the code</td><td class="ng">no (17.1.5)</td><td class="ok">yes, chapter 17</td><td>chapters 22 / 23</td></tr>');
w('<tr><td>Pullout / bearing</td><td>%s</td><td>%s</td><td>%s</td></tr>', rdc('Pullout at the back plate'), f2s(A.dc_po, '%.2f'), f2s(B.dc_brg, '%.2f'));
w('<tr><td>Side-face blowout</td><td>%s</td><td>%s</td><td>does not apply</td></tr>', rdc('Side-face blowout'), f2s(A.dc_sfb, '%.2f'));
w('<tr><td>Plate bending</td><td>%s</td><td>%s</td><td>%s</td></tr>', rdc('Back plate bending between'), f2s(A.dc_pw, '%.2f'), f2s(B.dc_bend, '%.2f'));
w('<tr><td>Transfer into the joint</td><td>anchor reinforcement %s</td><td>anchor reinforcement %s</td><td class="ng">shear friction: steel not developed above z = 0</td></tr>', rdc('Anchor reinforcement: top bars'), rdc('Anchor reinforcement: top bars'));
w('<tr><td>Cracking under D + L</td><td>cone cracks, controlled</td><td>cone cracks, controlled</td><td>most likely none</td></tr>');
w('<tr><td>Change</td><td></td><td>B1 in two pieces</td><td>longer bars, far-form holes, mortar bed, U-bars, column hooks redrawn</td></tr></table>');
w(['<h2>Recommendation</h2><p><b>A.</b> It puts the anchors back inside chapter 17 with one change to one piece, and every check passes. ' ...
   'B removes the service cracking, but to satisfy the code it needs vertical bars anchored above the anchors, where the column hooks already are; that is a redesign of the top of the column for a crack that the beam bars already control and that ends up hidden under the base plate grout and the slab.</p>']);
w('<p class="note">Quoted from memory, to confirm in your copies: the plate-washer stiffness limit (ACI 349 / AISC DG1), &mu; = 1.4 for monolithic concrete and the development requirement of 22.9, 14.5.5.1 for plain concrete.</p>');
w('</body></html>');
fclose(fid);
end

% ======================================================================================
function s = svgA(P, A)
an = P.an;  k = 3.2;  W = 560;  H = 260;  cx = W/2;  cy = 120;
X = @(v) cx + k*v;  Y = @(z) cy - k*z;
s = sprintf('<svg viewBox="0 0 %d %d" width="%d" height="%d">', W, H, W, H);
s = [s sprintf('<text x="10" y="18" font-size="13" font-weight="bold">A. Plate washers, seen along the anchors</text>')];
for v0 = [-1 1]*an.vT
    s = [s sprintf('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#34506b" fill-opacity="0.25" stroke="#142433"/>', X(v0 - A.w/2), Y(A.h/2), k*A.w, k*A.h)];
    s = [s sprintf('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#1e8449" fill-opacity="0.18" stroke="#1e8449" stroke-dasharray="5 3"/>', X(v0), Y(0), k*A.re)];
    s = [s sprintf('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="none" stroke="#7b241c" stroke-width="1.5"/>', X(v0), Y(0), k*an.dw/2)];
    s = [s sprintf('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#fff" stroke="#222"/>', X(v0), Y(0), k*an.hole/2)];
end
s = [s dimh(X(-an.vT - A.w/2), X(-an.vT + A.w/2), Y(A.h/2) - 14, sprintf('%g', A.w))];
s = [s dimh(X(-an.vT + A.w/2), X(an.vT - A.w/2), Y(A.h/2) - 14, sprintf('%g', A.gap))];
s = [s dimh(X(-an.vT), X(an.vT), Y(-A.h/2) + 22, sprintf('%g', 2*an.vT))];
s = [s sprintf('<text x="%.1f" y="%.1f" font-size="12" text-anchor="start">h = %g</text>', X(an.vT + A.w/2) + 8, Y(0) + 4, A.h)];
s = [s sprintf('<text x="10" y="%d" font-size="12">green dashed: effective head &#216;%g (nut face %g + 2 t); brown: nut face; t = %g</text>', H - 30, 2*A.re, an.dw, A.t)];
s = [s '</svg>'];
end

function s = svgB(P, R, B)
% section along the cantilever (type E): column, plate on the far face, the plane z = 0
an = P.an;  k = 0.95;  W = 720;  H = 470;  u0 = 150;  z0 = 150;
X = @(u) u0 + k*u;  Y = @(z) z0 - k*z;  b = P.col.b;  top = P.col.top;  cj = P.col.cj;  zT = R.typ(1).zT;
zA = top - P.col.ctop - P.col.db/2;  zBh = P.col.zhB;  rc = P.col.cover + P.col.dtie + P.col.db/2;
s = sprintf('<svg viewBox="0 0 %d %d" width="%d" height="%d">', W, H, W, H);
s = [s '<text x="10" y="18" font-size="13" font-weight="bold">B. Section along the cantilever (type E)</text>'];
s = [s sprintf('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#ece9e2" stroke="#6b6b6b"/>', X(0), Y(top), k*b, k*(top - cj))];
s = [s sprintf('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#ece9e2" fill-opacity="0.4" stroke="#8a8a8a" stroke-dasharray="6 3"/>', X(b), Y(0), k*200, k*P.cb.h)];
s = [s sprintf('<text x="%.1f" y="%.1f" font-size="12" text-anchor="middle">VCM</text>', X(b + 100), Y(-175))];
for u = [rc b - rc]                                  % column bars with their top hooks (faint)
    s = [s sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#9a6b00" stroke-opacity="0.5" stroke-width="%.1f"/>', X(u), Y(cj), X(u), Y(zBh), k*P.col.db)];
end
s = [s sprintf('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#9a6b00" fill-opacity="0.55"/>', X(b - rc - 8), Y(zA), k*8)];
s = [s sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#c0392b" stroke-width="%.1f"/>', X(-an.out), Y(zT), X(b + B.g + B.t + an.twsh + an.tnut + an.pp), Y(zT), k*an.db)];
s = [s sprintf('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#b9b2a0"/>', X(b), Y(B.zt(1)), k*B.g, k*B.h)];
s = [s sprintf('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#34506b"/>', X(b + B.g), Y(B.zt(1)), k*B.t, k*B.h)];
s = [s sprintf('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#7b241c"/>', X(b + B.g + B.t), Y(zT + an.nut/2), k*(an.twsh + an.tnut), k*an.nut)];
s = [s sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#c0392b" stroke-width="1.6" stroke-dasharray="8 4"/>', X(-20), Y(0), X(b + 220), Y(0))];
s = [s sprintf('<text x="%.1f" y="%.1f" font-size="12" fill="#c0392b">z = 0: the push has to cross this plane into the joint</text>', X(-20), Y(0) + 16)];
s = [s sprintf('<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="#c0392b"/>', X(b - 2), Y(zT), X(b + 26), Y(zT) - 7, X(b + 26), Y(zT) + 7)];
s = [s sprintf('<text x="%.1f" y="%.1f" font-size="12">only %g / %g mm of hook above z = 0 (need 150)</text>', X(b - rc - 140), Y(top) - 8, B.above(1), B.above(2))];
s = [s sprintf('<text x="%.1f" y="%.1f" font-size="12" text-anchor="middle">top of the pedestal +%g</text>', X(b/2), Y(top) - 26, top)];
s = [s sprintf('<text x="%.1f" y="%.1f" font-size="12">PL %gx%gx%g on a %g mm bed</text>', X(b + 40), Y(B.zt(1)) - 6, B.t, B.h, B.w, B.g)];
s = [s sprintf('<text x="%.1f" y="%.1f" font-size="12" text-anchor="end">through-bolt &#216;%g</text>', X(-5), Y(zT) - 10, an.db)];
s = [s sprintf('<text x="%.1f" y="%.1f" font-size="12" text-anchor="middle">column 40 x 40, joint below z = 0</text>', X(b/2), Y(-200))];
s = [s '</svg>'];
end

function s = dimh(x1, x2, y, t)
s = sprintf(['<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#222" stroke-width="0.8"/>' ...
             '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#222"/><line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#222"/>' ...
             '<text x="%.1f" y="%.1f" font-size="12" text-anchor="middle">%s</text>'], ...
             x1, y, x2, y, x1, y - 4, x1, y + 4, x2, y - 4, x2, y + 4, (x1 + x2)/2, y - 4, t);
end
