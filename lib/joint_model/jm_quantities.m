function T = jm_quantities(M, o)
% JM_QUANTITIES  pieces with qty = true grouped by mark: count, unit length or
% size, total length and steel mass (7850 kg/m3, or the piece kgm).
%   T = jm_quantities(M)  ->  struct array mark, desc, n, L (mm, bars: centreline
%   length per piece), mass (kg, all pieces of the mark), vol (litres, grout)
% Pieces without a mark are skipped. The description is the first piece's desc.
  if nargin < 2, o = struct(); end
  rho = 7850e-9;                                     % kg/mm3
  pc = M.pc([M.pc.qty] & ~cellfun(@isempty, {M.pc.mark}));
  marks = unique({pc.mark}, 'stable');
  T = struct('mark', {}, 'desc', {}, 'n', {}, 'L', {}, 'mass', {}, 'vol', {});
  for k = 1:numel(marks)
    G = pc(strcmp({pc.mark}, marks{k}));
    L = 0;  mass = 0;  vol = 0;
    for p = G
      if strcmp(p.type, 'bar')
        Lp = sum(sqrt(sum(diff(p.pts).^2, 2)));  L = Lp;  V = pi*p.d^2/4*Lp;
        if ~isnan(p.kgm), m = p.kgm*Lp/1000; else, m = rho*V; end
      else
        V = prod(diff(p.pts));
        if ~isnan(p.kgm), m = p.kgm*max(diff(p.pts))/1000; else, m = rho*V; end
      end
      if strcmp(p.kind, 'grout'), vol = vol + V/1e6;  m = 0; end
      mass = mass + m;
    end
    T(end+1) = struct('mark', marks{k}, 'desc', G(1).desc, 'n', numel(G), 'L', L, 'mass', mass, 'vol', vol);
  end
end
