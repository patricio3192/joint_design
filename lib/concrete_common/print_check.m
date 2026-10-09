function row = print_check(name, D, C, units, ref)
% PRINT_CHECK  Print one demand/capacity line and return {name, ratio}.
%   D, C  : demand and capacity in the same units (check is D <= C)
%   units : text printed after the numbers, e.g. 'kN', 'mm'
%   ref   : code / guide reference printed at the end of the line
ratio = D / C;
if ratio <= 1.0
    verdict = 'OK';
else
    verdict = 'NOT OK';
end
fprintf('  %-46s D = %8.2f  C = %8.2f %-4s ratio = %5.2f  %-6s [%s]\n', ...
        name, D, C, units, ratio, verdict, ref);
row = {name, ratio};
end
