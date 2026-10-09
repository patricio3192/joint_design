function r = aci_beam_shear_torsion(sec, Vu, Mu, Tu)
% ACI_BEAM_SHEAR_TORSION  Shear, torsion and the longitudinal steel they
% need, for a rectangular nonprestressed beam with closed stirrups and
% bars only in the top and bottom layers. ACI 318-19, SI forms (Appendix C).
% Units: N, mm, MPa.  Nu = 0 (no axial force).
%
% sec fields: bw, h, fc, fy, fyt, lambda, cover_long (clear cover to the
%   longitudinal bars), db_long, n_top, n_bot, db_st, s, compat (true if the
%   torsion is compatibility torsion, 22.7.3.2).
% Returns struct r with all intermediate values.
phi  = 0.75;                                   % Table 21.2.1, shear and torsion
lam  = sec.lambda;  fc = sec.fc;  bw = sec.bw;  h = sec.h;
d    = h - sec.cover_long - sec.db_long/2;     % effective depth
Ab_st   = pi * sec.db_st^2 / 4;
Ab_long = pi * sec.db_long^2 / 4;

% torsion section properties (22.7.6.1.1, Fig. R22.7.6.1.1)
c_st = sec.cover_long - sec.db_st/2;           % surface to stirrup centreline
x1 = bw - 2*c_st;   y1 = h - 2*c_st;
Aoh = x1 * y1;   ph = 2*(x1 + y1);   Ao = 0.85 * Aoh;    % 22.7.6.1.1
Acp = bw * h;    pcp = 2*(bw + h);
theta = 45;                                    % 22.7.6.1.2, nonprestressed

Tth = 0.083 * lam * sqrt(fc) * Acp^2 / pcp;    % Table 22.7.4.1(a)(a), Nu = 0
Tcr = 0.33  * lam * sqrt(fc) * Acp^2 / pcp;    % (22.7.5.1(a)), Nu = 0
Tu_d = abs(Tu);
if sec.compat
    Tu_d = min(Tu_d, phi * Tcr);               % 22.7.3.2
end
tors = Tu_d > phi * Tth;                       % 22.7.1.1

% shear (Av >= Av,min is checked below; Vc per Table 22.5.5.1(a))
Vc = 0.17 * lam * sqrt(fc) * bw * d;           % Table 22.5.5.1(a), Nu = 0
Vs_req = max(0, abs(Vu)/phi - Vc);
Av_s_req = Vs_req / (sec.fyt * d);             % from (22.5.8.5.3)

if tors
    At_s_req = Tu_d / (phi * 2 * Ao * sec.fyt * cotd(theta));       % (22.7.6.1a)
    Al_req   = At_s_req * ph * (sec.fyt / sec.fy) * cotd(theta)^2;  % from (22.7.6.1b)
    % 9.6.4.3(a) uses the PROVIDED At/s (one leg of the closed stirrup);
    % ACI does not say required or provided - decision agreed with the user.
    At_s_prov = Ab_st / sec.s;
    Al_min   = max(0, min(0.42*sqrt(fc)*Acp/sec.fy - At_s_prov*ph*sec.fyt/sec.fy, ...
                   0.42*sqrt(fc)*Acp/sec.fy - (0.175*bw/sec.fyt)*ph*sec.fyt/sec.fy));  % 9.6.4.3
    Al_des   = max(Al_req, Al_min);
    trans_min = max(0.062*sqrt(fc)*bw/sec.fyt, 0.35*bw/sec.fyt);    % 9.6.4.2, (Av+2At)/s
    s_max = min([ph/8, 300, d/2, 600]);        % 9.7.6.3.3 and Table 9.7.6.2.2
    lhs = sqrt((abs(Vu)/(bw*d))^2 + (Tu_d*ph/(1.7*Aoh^2))^2);      % (22.7.7.1a)
else
    At_s_req = 0; Al_req = 0; Al_min = 0; Al_des = 0;
    trans_min = max(0.062*sqrt(fc)*bw/sec.fyt, 0.35*bw/sec.fyt);    % Table 9.6.3.4
    s_max = min(d/2, 600);                     % Table 9.7.6.2.2
    lhs = abs(Vu)/(bw*d);                      % 22.5.1.2 written as a stress
end
rhs = phi * (Vc/(bw*d) + 0.66*sqrt(fc));       % 22.7.7.1(a) / 22.5.1.2

% transverse steel: 2-leg closed stirrup, Av = 2*Ab, At = Ab
trans_req  = Av_s_req + 2*At_s_req;            % (Av + 2At)/s, 9.5.4.3 (added)
trans_prov = 2 * Ab_st / sec.s;
if Vs_req > 0.33*sqrt(fc)*bw*d                 % Table 9.7.6.2.2, closer spacing
    s_max = min(s_max, min(d/4, 300));
end

% flexure (rectangular stress block 22.2.2.4.1, beta1 Table 22.2.2.4.3)
phi_f = 0.90;
As_req = (0.85*fc*bw/sec.fy) * (d - sqrt(d^2 - 2*abs(Mu)/(phi_f*0.85*fc*bw)));
a  = As_req * sec.fy / (0.85*fc*bw);
b1 = min(0.85, max(0.65, 0.85 - 0.05*(fc - 28)/7));
cna = a / b1;
eps_t = 0.003 * (d - cna) / cna;               % >= 0.005 -> phi = 0.90 (Table 21.2.2)

% longitudinal: bars only top and bottom -> Al split half per face
% (assumption; Al reduction in the flexural compression zone not used)
As_face_prov = min(sec.n_top, sec.n_bot) * Ab_long;
As_tens_req  = As_req + Al_des/2;
As_comp_req  = Al_des/2;

r = struct('d', d, 'x1', x1, 'y1', y1, 'Aoh', Aoh, 'ph', ph, 'Ao', Ao, ...
    'Acp', Acp, 'pcp', pcp, 'phi', phi, 'Tth', Tth, 'Tcr', Tcr, 'Tu_d', Tu_d, ...
    'tors', tors, 'Vc', Vc, 'Vs_req', Vs_req, 'Av_s_req', Av_s_req, ...
    'At_s_req', At_s_req, 'Al_req', Al_req, 'Al_min', Al_min, 'Al_des', Al_des, ...
    'trans_req', trans_req, 'trans_prov', trans_prov, 'trans_min', trans_min, ...
    's_max', s_max, 'lhs', lhs, 'rhs', rhs, 'As_req', As_req, 'eps_t', eps_t, ...
    'As_face_prov', As_face_prov, 'As_tens_req', As_tens_req, ...
    'As_comp_req', As_comp_req, 'row_gap', h - 2*(sec.cover_long + sec.db_long/2));
end
