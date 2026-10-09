function C = ca_capacity(P)
C = cap(P, {});
C2 = cap(P, {'No prying'});
C.Mu2 = C2.Mu;  C.gov2 = C2.gov;
end

function C = cap(P, skip)
% CA_CAPACITY  Largest factored moment at the column face that each connection type takes.
%   All forces (M, V, torsion) are scaled together by one factor until the largest D/C of
%   the limit states that depend on the load reaches 1.0. Rows marked 'info' and the frame
%   item (concrete beam behind) are left out. C.Mu(j) in kN m, C.gov{j} the governing check.
lo = 0.5;  hi = 4;
R0 = ca_calc(P);
ks = lo:0.01:hi;
for j = 1:4
    % the D/C is not monotonic in the load (the number of beam bars counted grows with T):
    % first load step where a check exceeds 1, then bisection inside that step
    a = lo;  b = hi;
    for k = ks
        if worst(P, k, j, skip) > 1, b = k;  a = max(lo, k - 0.01);  break; end
    end
    for it = 1:20
        k = (a + b)/2;
        [dc, g] = worst(P, k, j, skip);
        if dc > 1, b = k; else, a = k; end
    end
    [dc, g] = worst(P, a, j, skip);
    C.k(j) = a;  C.Mu(j) = a*R0.kase(R0.typ(j).k).Mc;  C.gov{j} = g;  C.dc(j) = dc;
end
end

function [dc, g] = worst(P, k, j, skip)
P.kMforce = k;
R = ca_calc(P);
dc = 0;  g = '';
for i = 1:size(R.rows, 1)
    r = R.rows(i,:);
    if strcmp(r{8}, 'info') || strncmp(r{2}, 'Concrete beam behind', 20), continue; end
    if any(cellfun(@(x) strncmp(r{2}, x, numel(x)), skip)), continue; end
    d = r{4}(j)/r{5}(j);
    if d > dc, dc = d;  g = r{2}; end
end
end
