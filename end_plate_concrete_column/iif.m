% Copied unchanged from sandwiched_concrete_beam/iif.m (trusted baseline), 2026-10-07.
function out = iif(c, a, b)
% IIF  Inline if: returns a when c is true, b otherwise.
if c
    out = a;
else
    out = b;
end
end
