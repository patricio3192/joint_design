function T = collar_types(DB, J, C)
% COLLAR_TYPES  Group the collar plates of all classified joints by outline.
%
%   T = collar_types(DB, default_joint())
%
% Two joints share a plate type when their strips beyond the column are
% the same up to turning or flipping the plate: the two strips on the D
% sides and the two on the B sides are compared as unordered pairs.  The
% cap and the shelf of a joint have the same outline.
%
% T(k): name ('A', 'B', ... most used first), oD and oB (strips, largest
% first), LD x LB (plate size along D and along B), t (thickness), and
% per joint: joints, over ([W N E S] strips) and axis (strong axis, 'X'/'Y').

  if nargin < 3, C = joint_classes(); end
  keys = {};
  T = struct('name', {}, 'oD', {}, 'oB', {}, 'LD', {}, 'LB', {}, 't', {}, ...
             'joints', {}, 'over', {}, 'axis', {});
  for k = 1:numel(DB.joints)
    jt = DB.joints(k);
    if ~any(strcmp(C(:,1), jt.joint)), continue; end
    [map, Jj] = joint_config(jt, J, C);
    oD = sort(Jj.pl.oD, 'descend');  oB = sort(Jj.pl.oB, 'descend');
    key = sprintf('%g ', [oD oB Jj.pl.t_cap Jj.pl.t_shf]);
    t = find(strcmp(keys, key), 1);
    if isempty(t)
      keys{end+1} = key;  t = numel(keys);
      T(t).oD = oD;  T(t).oB = oB;
      T(t).LD = Jj.cl.D + sum(oD);  T(t).LB = Jj.cl.B + sum(oB);
      T(t).t  = [Jj.pl.t_cap Jj.pl.t_shf];
      T(t).joints = {};  T(t).over = {};  T(t).axis = {};
    end
    T(t).joints{end+1} = jt.joint;
    T(t).over{end+1}   = Jj.pl.over;
    T(t).axis{end+1}   = map.strongAxis;
  end
  [~, o] = sort(-cellfun(@numel, {T.joints}));
  T = T(o);
  for t = 1:numel(T), T(t).name = char('A' + t - 1); end
end
