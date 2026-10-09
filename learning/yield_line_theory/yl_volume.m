function V = yl_volume(W, C)
% YL_VOLUME  Volume under the deflected plate: external work of a unit uniform load.
%   V = yl_volume(W, C)
%   W   n x 3 planes of the regions (as in yl_work)
%   C   cell array, C{k} = [x y] vertices of region k, in order
%   For a plane the integral is the area times w at the centroid: exact.

V = 0;
for k = 1:numel(C)
    x = C{k}(:,1);  y = C{k}(:,2);
    xn = x([2:end 1]);  yn = y([2:end 1]);
    cr = x.*yn - xn.*y;
    A  = sum(cr)/2;
    xc = sum((x + xn).*cr)/(6*A);
    yc = sum((y + yn).*cr)/(6*A);
    V  = V + abs(A)*(W(k,:)*[1 xc yc]');
end
end
