function P = plan_layout(M, DB, G)
% PLAN_LAYOUT  What the floor plan shows: grid names, IPE beams, correas
% and the IPE to IPE shear connections.
%
%   P = plan_layout(M, DB, G)        G: the project's grid (see README.md)
%
% P.name       containers.Map, ETABS joint -> grid name ('10' -> 'C1')
% P.ipe        frame indices (into M.fr) of the IPE beams
% P.correa     frame indices of the correas: north-south members that are
%              not on a lettered grid line (more than 50 mm off it)
% P.vv(k)      IPE to IPE connections, away from the columns:
%   .pt, .xy   ETABS point and its plan position (m)
%   .kind      'T' one beam frames into a continuous one, 'X' two beams
%              from opposite sides, 'L' corner (two beams end, none goes on)
%   .coped     frames cut and welded (the supported beams)
%   .support   frame(s) of the beam they weld to
%   .V         largest shear (N) at each coped end in the model, all
%              combinations except RSA
%   .nsup      coped beams on the same supporting web (for its web shear)
% Corner rule: the beam whose far end is not on a column is the one cut;
% if neither (or both) are, the north-south one.

  if nargin < 3 || ~isstruct(G)
    error('plan_layout: give the grid G (the project''s grid_lines()).');
  end
  xy  = M.pt.xyz(:, 1:2);
  idx = containers.Map(M.pt.name, num2cell(1:numel(M.pt.name)));
  P.grid = G;

  % ---- joint names from the grid
  P.name = containers.Map();
  for k = 1:numel(DB.joints)
    p = DB.joints(k).xyz(1:2);
    dv = cellfun(@(a, b) dist_line(p, a, b), G.v(:,2), G.v(:,3));
    dh = abs(p(2) - cell2mat(G.h(:,2)));
    [~, iv] = min(dv);  [~, ih] = min(dh);
    P.name(DB.joints(k).joint) = [G.v{iv,1} G.h{ih,1}];
  end

  % ---- IPE or correa
  kb = find(strcmp(M.fr.type, 'Beam')).';
  P.ipe = [];  P.correa = [];
  for i = kb
    a = xy(idx(M.fr.ptI{i}), :);  b = xy(idx(M.fr.ptJ{i}), :);
    ns = abs(b(2) - a(2)) > abs(b(1) - a(1));
    ongrid = false;
    for g = 1:size(G.v, 1)
      if dist_line(a, G.v{g,2}, G.v{g,3}) < 0.05 && dist_line(b, G.v{g,2}, G.v{g,3}) < 0.05
        ongrid = true;
      end
    end
    if ns && ~ongrid, P.correa(end+1) = i; else, P.ipe(end+1) = i; end
  end

  % ---- IPE to IPE connections
  cols = {DB.joints.joint};
  ends = unique([M.fr.ptI(P.ipe); M.fr.ptJ(P.ipe)]);
  isColEnd = @(i, pt) any(strcmp(cols, other_end(M, i, pt)));
  P.vv = struct('pt', {}, 'xy', {}, 'kind', {}, 'coped', {}, 'support', {}, 'V', {}, 'nsup', {});
  for e = 1:numel(ends)
    pt = ends{e};
    if any(strcmp(cols, pt)), continue; end
    p  = xy(idx(pt), :);
    fin = P.ipe(strcmp(M.fr.ptI(P.ipe), pt) | strcmp(M.fr.ptJ(P.ipe), pt));
    % unit direction of each ending beam, pointing away from the point
    u = zeros(numel(fin), 2);
    for j = 1:numel(fin)
      q = xy(idx(other_end(M, fin(j), pt)), :);  u(j, :) = (q - p)/norm(q - p);
    end
    % IPEs passing through the point (not split there in the model)
    pass = [];
    for i = setdiff(P.ipe, fin)
      a = xy(idx(M.fr.ptI{i}), :);  b = xy(idx(M.fr.ptJ{i}), :);
      if dist_seg(p, a, b) < 0.005, pass(end+1) = i; end
    end
    % collinear pair among the ending beams
    pair = [];
    for j1 = 1:numel(fin)
      for j2 = j1+1:numel(fin)
        if dot(u(j1,:), u(j2,:)) < -cosd(5), pair = [j1 j2]; end
      end
    end
    if ~isempty(pass)
      coped = 1:numel(fin);  sup = M.fr.name(pass);
    elseif ~isempty(pair)
      coped = setdiff(1:numel(fin), pair);  sup = M.fr.name(fin(pair));
    elseif numel(fin) == 2 && abs(dot(u(1,:), u(2,:))) < sind(10)
      c1 = isColEnd(fin(1), pt);  c2 = isColEnd(fin(2), pt);
      if c1 && ~c2, coped = 2; elseif c2 && ~c1, coped = 1;
      else, [~, coped] = max(abs(u(:,2))); end
      sup = M.fr.name(fin(3 - coped));
    else
      continue
    end
    if isempty(coped), continue; end                  % a splice, not a connection
    V = zeros(1, numel(coped));
    for j = 1:numel(coped), V(j) = end_shear(M, fin(coped(j)), pt); end
    if ~isempty(pass), kind = 'T'; if numel(coped) == 2, kind = 'X'; end
    elseif ~isempty(pair), kind = 'T';
    else, kind = 'L'; end
    P.vv(end+1) = struct('pt', pt, 'xy', p, 'kind', kind, 'coped', {M.fr.name(fin(coped)).'}, ...
                         'support', {sup(:).'}, 'V', V, 'nsup', numel(coped));
  end
end

function q = other_end(M, i, pt)
  if strcmp(M.fr.ptI{i}, pt), q = M.fr.ptJ{i}; else, q = M.fr.ptI{i}; end
end

% largest |V2| (N) at the end of frame i that sits at point pt
function V = end_shear(M, i, pt)
  r = find(strcmp(M.F.name, M.fr.name{i}) & strcmp(M.F.ctype, 'Combination') & ...
           cellfun(@isempty, strfind(M.F.case, 'RSA')));
  if isempty(r), V = 0; return; end
  sta = M.F.sta(r);
  if strcmp(M.fr.ptI{i}, pt), t = min(sta); else, t = max(sta); end
  r = r(abs(sta - t) < 1e-6);
  V = 1e3*max(abs(M.F.f(r, 2)));
end

function d = dist_line(p, a, b)
  t = (b - a)/norm(b - a);
  v = p - a;
  d = abs(v(1)*t(2) - v(2)*t(1));
end

function d = dist_seg(p, a, b)
  t = dot(p - a, b - a)/dot(b - a, b - a);
  if t <= 1e-6 || t >= 1 - 1e-6, d = Inf; return; end    % interior only
  d = norm(p - (a + t*(b - a)));
end
