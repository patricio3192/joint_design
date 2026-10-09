function r = aci_dev_lengths(db, fy, fc, lambda, psi_t, good, psi_r, psi_o)
% ACI_DEV_LENGTHS  Tension development lengths of a deformed bar, ACI 318-19,
% SI forms (Appendix C). Units: N, mm, MPa. Uncoated bars (psi_e = 1),
% Grade 420 or lower (psi_g = 1.0), bars of 19 mm and smaller.
%   psi_t : casting position, 1.3 if more than 300 mm of fresh concrete is
%           placed below the bar (Table 25.4.2.5), else 1.0
%   good  : true if clear spacing >= db, clear cover >= db and stirrups/ties
%           not less than the code minimum along ld (Table 25.4.2.3, first row)
%   psi_r : confining reinforcement for hooks (Table 25.4.3.2), 1.0 or 1.6
%   psi_o : hook location (Table 25.4.3.2), 1.0 inside the column core with
%           side cover >= 65 mm, else 1.25
% Straight bar, Table 25.4.2.3 (No. 6 and smaller): ld = fy*psi_t*psi_e*psi_g
%   / (k*lambda*sqrt(fc)) * db, k = 2.1 (good) or 1.4 (other), ld >= 300 mm
%   (25.4.2.1). psi_t*psi_e <= 1.7.
k = 1.4;  if good, k = 2.1; end
r.ld = max(300, fy * psi_t / (k * lambda * sqrt(fc)) * db);
% Standard hook, 25.4.3.1: ldh = max(fy*psi_e*psi_r*psi_o*psi_c/(23*lambda*sqrt(fc))
%   * db^1.5, 8db, 150 mm); psi_c = fc/105 + 0.6 for fc < 40 MPa (Table 25.4.3.2,
%   SI conversion of fc/15000 + 0.6).
psi_c = min(1.0, fc/105 + 0.6);
r.psi_c = psi_c;
r.ldh = max([fy * psi_r * psi_o * psi_c / (23 * lambda * sqrt(fc)) * db^1.5, 8*db, 150]);
end
