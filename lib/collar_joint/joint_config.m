function [map, J, msg] = joint_config(jt, J, C)
% JOINT_CONFIG  Frame map and collar geometry of one joint, from its class.
%
%   [map, J, msg] = joint_config(DB.joints(k), default_joint())
%   [map, J, msg] = joint_config(DB.joints(k), J, joint_classes())
%
% Reads the joint's codes from joint_classes (W N E S) and the beam on
% each side from the database (map.at), then returns
%   map.strong, map.weak   MOMENT beams only (code M), by column axis
%   map.shear              beams on the shelf, shear only (code S)
%   map.nl                 beams below the collar, shear tab (code NL)
%   map.sides              the four codes
%   J.pl.over              collar strip beyond the column, [W N E S], mm:
%                          M, S, NL, N -> L_lap + gap (NL and N are free
%                          sides: J.pl.o_free overrides), E -> w_back
%   J.pl.oD, J.pl.oB       the same, on the two D sides and the two B
%                          sides of the column (used by plate_geometry)
%   J.pl.nwing             short (w_back) strips across the [strong weak]
%                          force, for T13
%   J.nl.face              width of the column face a shear tab lands on
% msg: disagreements between the class and the model, one line each.
% A joint missing from the table keeps the automatic map (all beams as
% moment beams) and J unchanged, with a message.
% J without a collar (dwj_lib) only gets the map.

  if nargin < 3, C = joint_classes(); end
  map = jt.map;  msg = {};
  k = find(strcmp(C(:,1), jt.joint), 1);
  if isempty(k)
    msg{end+1} = sprintf('joint %s is not in joint_classes: all beams taken as moment beams', jt.joint);
    return
  end
  codes = C(k, 2:5);
  side  = {'W', 'N', 'E', 'S'};
  if strcmp(map.strongAxis, 'Y'), onD = [2 4]; else, onD = [1 3]; end   % sides on the column's D faces

  hasPl = isfield(J, 'pl');
  if hasPl
    ov = J.pl.L_lap + J.st.gap;
    if isfield(J.pl, 'o_free') && ~isempty(J.pl.o_free), ofree = J.pl.o_free; else, ofree = ov; end
  end
  over = zeros(1, 4);
  map.strong = [];  map.weak = [];  map.shear = [];  map.nl = [];  map.sides = codes;
  ok = cellfun(@isempty, regexp({jt.res.ocase}, 'RSA'));
  for s = 1:4
    f = map.at(s);  c = codes{s};
    if any(strcmp(c, {'M', 'S', 'NL'}))
      if isnan(f)
        msg{end+1} = sprintf('joint %s, side %s: class %s but the model has no beam there', jt.joint, side{s}, c);
        continue
      end
      r = jt.res(ok & strcmp({jt.res.frame}, num2str(f)));
      Mm = max(abs(arrayfun(@(x) x.loc(6), r)));
      if strcmp(c, 'M') && Mm < 0.01
        msg{end+1} = sprintf('joint %s, side %s: beam %d is class M but the model releases it (M = 0)', ...
                             jt.joint, side{s}, f);
      elseif ~strcmp(c, 'M') && Mm >= 0.01
        msg{end+1} = sprintf(['joint %s, side %s: beam %d is class %s (pinned) but the model gives it ' ...
                              '%.2f kNm; that moment is not checked'], jt.joint, side{s}, f, c, Mm);
      end
      switch c
        case 'M'
          if any(s == onD), map.strong(end+1) = f; else, map.weak(end+1) = f; end
          if hasPl, over(s) = ov; end
        case 'S'
          map.shear(end+1) = f;
          if hasPl, over(s) = ov; end
        case 'NL'
          map.nl(end+1) = f;
          if hasPl, over(s) = ofree; end
          if isfield(J, 'cl')
            if any(s == onD), J.nl.face = J.cl.B; else, J.nl.face = J.cl.D; end
          end
      end
    elseif any(strcmp(c, {'N', 'E'}))
      if ~isnan(f)
        msg{end+1} = sprintf('joint %s, side %s: class %s (no beam) but the model has beam %d there', ...
                             jt.joint, side{s}, c, f);
      end
      if hasPl
        if strcmp(c, 'E'), over(s) = J.pl.w_back; else, over(s) = ofree; end
      end
    else
      error('joint %s, side %s: unknown code %s', jt.joint, side{s}, c);
    end
  end

  if hasPl
    onB = setdiff(1:4, onD);
    J.pl.over  = over;
    J.pl.oD    = over(onD);
    J.pl.oB    = over(onB);
    J.pl.nwing = [sum(J.pl.oB < ov) sum(J.pl.oD < ov)];
  end
end
