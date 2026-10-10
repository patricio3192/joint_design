function it = c_column_tie(T)
% C_COLUMN_TIE  Square column section with one closed tie (two 135 deg hooks at a
% corner bar, legs 6db >= 75) and its 8 bars: {outline, bars, tie (2 pieces), dims}.
% Origin at the column centre.
%
%   T.b       column side                 T.xc   bar centre to the column axis
%             (= b/2 - cover - db - db_col/2, the same as the 3D models use)
%   T.db_col  column bar diameter         T.db   tie diameter
%   T.s       tie style (default 'r_tieS'), T.bs bar style ('r_col'), T.br bar dot radius (8)
%   T.dim_off offset of the two dimensions (default -90)
  if ~isfield(T, 's'), T.s = 'r_tieS'; end
  if ~isfield(T, 'bs'), T.bs = 'r_col'; end
  if ~isfield(T, 'br'), T.br = 8; end
  if ~isfield(T, 'dim_off'), T.dim_off = -90; end
  c = T.xc;  db = T.db;  r = T.db_col/2 + db/2;  e = max(6*db, 75);  w = [1 1]/sqrt(2);
  BL = [-c -c];  BR = [c -c];  TR = [c c];  TL = [-c c];
  a0 = arcp(BL, r, 135, 270);  a5 = arcp(BL, r, 180, 315);
  Q1 = [a0(1,:) + e*w; a0; arcp(BR, r, -90, 0); arcp(TR, r, 0, 90); arcp(TL, r, 90, 180)];
  Q2 = [Q1(end,:); a5; a5(end,:) + e*w];
  it = {d_rectxy(-T.b/2, -T.b/2, T.b/2, T.b/2, 'r_conc')};
  for sx = [-1 0 1], for sy = [-1 0 1]
    if sx ~= 0 || sy ~= 0, it{end+1} = d_circle(sx*c, sy*c, T.br, T.bs); end
  end, end
  it{end+1} = d_path(Q1, db, T.s);  it{end+1} = d_path(Q2, db, T.s);
  o = c + r + db/2;
  it{end+1} = d_dim(-o, -o, o, -o, T.dim_off, sprintf('%.0f', 2*o));
  it{end+1} = d_dim(o, -o, o, o, T.dim_off, sprintf('%.0f', 2*o));
end
