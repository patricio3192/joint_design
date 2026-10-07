function Q = f_deeper()
% F_DEEPER  Axis F with a deeper section (IPE 160 / 180 / 200) and the connection across VCS made with
%   through rods Ø20 only (no strap), user question 2026-10-05. Rods under the top flange at x = +-35,
%   one row (z = -40, on the VCS top bars) or two rows (z = -40 and -75, between the VCS top bars and
%   the stirrups); compression at the bottom flange; rod forces in proportion to the distance from it.
%   End plate PL 12 A36 by strips to the flange and the web (as ca_calc), alone or with a 12 mm extra plate.
%   Moment: 18.3 kN m (factored, IPE 160 north, run 1) and +20 % (a stiffer F attracts more; ETABS to confirm).
here = fileparts(mfilename('fullpath'));
C = f_capacities(fullfile(here, 'capacities.txt'));
mp = 0.9*248*12^2/4;  phiRt = 0.75*0.75*550*pi*20^2/4;  wf = 6;  ww = 5;  xr = 35;
rows = {[-40], [-40 -75]};  Mus = [18.3 22.0]*1e6;  out = {};
for nm = {'IPE160', 'IPE180', 'IPE200'}
    S = C.(nm{1});  zc = -(S.h - S.tf/2);
    zft = -S.tf - wf;  xwt = S.tw/2 + ww;  xft = S.b/2 + wf;  zfb = zc + S.tf/2 + wf;
    for k = 1:2
        zr = rows{k};  d = zr - zc;                              % lever of each row
        for Mu = Mus
            T1 = Mu/(2*sum(d.^2)/d(1));                          % top row, per rod
            % strips of the top rod: to the flange (above) and the web; with two rows the lower rod limits
            % the web strip of the upper one at the midpoint
            x1 = zft - zr(1);  w1 = min(xr + x1, xft) - max(xr - x1, xwt);
            x2 = xr - xwt;  lo = zfb;  if k == 2, lo = (zr(1) + zr(2))/2; end
            w2 = min(zr(1) + x2, zft) - max(zr(1) - x2, lo);
            c1 = (x1/w1)*(x2/w2)/((x1/w1) + (x2/w2));
            out(end+1,:) = {S.name, numel(zr)*2, Mu/1e6, T1/1e3, T1/phiRt, c1*T1/mp, c1*T1/2/mp, S.phiMn(1450, 1)/1e6};
        end
    end
end
f = fopen(fullfile(here, 'deeper_results.txt'), 'w');
fprintf(f, 'AXIS F with a deeper section, rods Ø20 only (no strap). f_deeper.m, %s\n', datestr(now, 'yyyy-mm-dd'));
fprintf(f, 'D/C of: rod in tension; end plate PL 12 alone; with a 12 mm extra plate; beam flexure (Lb 1.45).\n\n');
fprintf(f, '%-8s %5s %8s %10s %8s %10s %12s %8s\n', 'Section', 'rods', 'Mu', 'rod T (kN)', 'rod', 'plate 12', 'plate 12+12', 'beam');
for i = 1:size(out, 1)
    fprintf(f, '%-8s %5d %8.1f %10.1f %8.2f %10.2f %12.2f %8.2f\n', out{i,1}, out{i,2}, out{i,3}, out{i,4}, out{i,5}, out{i,6}, out{i,7}, out{i,3}/out{i,8});
end
fclose(f);  type(fullfile(here, 'deeper_results.txt'));  Q = out;
end
