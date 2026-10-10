function S = end_plate_welds(Mu, Vu, b, W, ext, pfi, num)
% END_PLATE_WELDS  Welds of a flush end plate to an I beam (AISC 360-16 J2, J4;
% DG 39 Sec. 3.7.5): top flange CJP (or PJP), bottom flange fillets, web
% fillets split into a tension region near the tension rods and a shear region.
% Prints the lines (module 10 of check_sandwich_beam) and returns {name, ratio}.
%   Mu (N*mm), Vu (N); b: beam fields h, bf, tf, tw, r_fil, Fy, Fu;
%   W: weld fields FEXX, top_cjp, S_pjp, pjp_flat, w_fl, w_web; ext (mm) plate
%   below the bottom flange; pfi (mm) inner flange to the tension row; num:
%   module number in the printed heading (default 10).
  h = b.h;  bf = b.bf;  tf = b.tf;  tw = b.tw;  r_fil = b.r_fil;  Fy = b.Fy;  Fu = b.Fu;
  FEXX = W.FEXX;  top_cjp = W.top_cjp;  S_pjp = W.S_pjp;  pjp_flat = W.pjp_flat;
  w_fl = W.w_fl;  w_web = W.w_web;
  if nargin < 7, num = 10; end
  in = 25.4;
  S = cell(0, 2);
  fprintf('--- %d. WELDS (E70XX, FEXX = %.0f MPa) ---\n', num, FEXX);
  Ru_fl = max(Mu/(h - tf), 0.60*Fy*bf*tf);          % DG39 (3-38a), no axial force
  fprintf('  Flange weld demand Ru = max(Mu/(d-tf), 0.60Fy bf tf) = max(%.1f, %.1f) = %.1f kN\n', ...
          Mu/(h-tf)/1e3, 0.60*Fy*bf*tf/1e3, Ru_fl/1e3);
  % Top flange: plate flush on top -> groove weld, flange beveled
  if top_cjp
      % CJP, matching filler (E70XX): joint strength controlled by the base metal
      fprintf('  Top flange CJP groove weld, E70XX matching filler\n');
      S(end+1,:) = print_check('CJP top flange, base metal (flange yielding)', Ru_fl/1e3, 0.90*Fy*bf*tf/1e3, 'kN', 'Table J2.5, J4-1');
  else
      E_pjp = iif(pjp_flat, S_pjp, S_pjp - 3);   % Table J2.1, 45 deg bevel
      if S_pjp > tf, error('PJP bevel depth larger than tf'); end
      fprintf('  Top flange PJP: S = %.1f mm, E = %.1f mm (%s)\n', S_pjp, E_pjp, iif(pjp_flat, 'GMAW/FCAW F,H: E = S', 'SMAW or V/OH: E = S - 3'));
      S(end+1,:) = print_check('PJP min effective throat', 5, E_pjp, 'mm', 'AISC Table J2.3');
      S(end+1,:) = print_check('PJP top flange, weld metal', Ru_fl/1e3, 0.80*0.60*FEXX*E_pjp*bf/1e3, 'kN', 'AISC Table J2.5');
      S(end+1,:) = print_check('PJP top flange, base metal (rupture)', Ru_fl/1e3, 0.75*Fu*E_pjp*bf/1e3, 'kN', 'Table J2.5, J4-2');
  end
  % Bottom flange: fillet both faces (outer full width, inner faces between root radii)
  L_fl = bf + (bf - tw - 2*r_fil);
  kds  = 1 + 0.5*sind(90)^1.5;                       % (J2-5), theta = 90 deg
  S(end+1,:) = print_check('Bottom flange fillet min size', 5, w_fl, 'mm', 'AISC Table J2.4');
  S(end+1,:) = print_check('Bottom flange fillet max size (t-2)', w_fl, tf - 2, 'mm', 'AISC J2.2b');
  S(end+1,:) = print_check('Bottom flange fillet (designed for Ru)', Ru_fl/1e3, 0.75*0.60*FEXX*kds*0.707*w_fl*L_fl/1e3, 'kN', 'AISC J2-4, J2-5');
  fprintf('  (bottom flange is in compression; Ru used in case of moment reversal; ext = %.0f mm >= w)\n', ext);
  % Web: tension region near the tension rods, rest in shear (DG 39 Sec. 3.7.5, Example 5.2-1)
  Tuw = (2/2) * Mu/(h - tf);                         % (3-39), (3-40): ntrib/n = 2/2
  lwt_DG = pfi + 6*in;
  lwt = min(lwt_DG, h - 2*tf);
  Tyw = Fy * tw * lwt;
  Tuwd = max(Tuw, 0.60*Fy*tw*lwt);                   % (3-41a)
  S(end+1,:) = print_check('Web tension yielding near tension rods', Tuw/1e3, 0.90*Tyw/1e3, 'kN', 'DG39 3-40; J4-1');
  S(end+1,:) = print_check('Web weld, tension region', Tuwd/1e3, 0.75*2*0.60*FEXX*0.707*w_web*lwt*kds/1e3, 'kN', 'DG39 3-41a; J2-4, J2-5');
  lt   = h - 2*tf - lwt;
  l05  = h/2 - tf;
  lwv  = min(lt, l05);
  if lwv > 0
      S(end+1,:) = print_check('Web weld, shear region', Vu/1e3, 0.75*2*0.60*FEXX*0.707*w_web*lwv/1e3, 'kN', 'J2-4 (theta = 0)');
      S(end+1,:) = print_check('Web shear rupture at weld', Vu/1e3, 0.75*0.60*Fu*lwv*tw/1e3, 'kN', 'AISC J4-4');
  else
      fprintf('  FLAG: DG 39 tension length pfi + 6 in. = %.0f mm covers the whole web of this\n', lwt_DG);
      fprintf('        shallow beam; no weld is left for shear. Lower half of the web (%.1f mm)\n', l05);
      fprintf('        checked for tension + shear together (resultant at angle theta, J2-5).\n');
      ft = Tuwd / (2*lwt);  fv = Vu / (2*l05);       % N/mm per weld
      th = atand(ft / fv);
      S(end+1,:) = print_check('Web weld, tension + shear (lower half)', sqrt(ft^2 + fv^2), ...
          0.75*0.60*FEXX*0.707*w_web*(1 + 0.5*sind(th)^1.5), 'N/mm', 'J2-4, J2-5 (deviation)');
      S(end+1,:) = print_check('Web shear rupture at weld (lower half)', Vu/1e3, 0.75*0.60*Fu*l05*tw/1e3, 'kN', 'AISC J4-4');
  end
  fprintf('\n');
end
