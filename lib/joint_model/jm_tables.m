function [tc, tq] = jm_tables(F, Q)
% JM_TABLES  sheet blocks (lib/sheets, Spanish) for a clash list F (jm_clash)
% and quantities Q (jm_quantities): tc = {heading, table} of clashes with
% CHOQUE / separación rows in red, tq = {heading, table} of quantities.
% Both are cell arrays of blocks: use them as columns, blk_row([0.56 0.44], {tc, tq}),
% or stacked in one column, {tc{:}, tq{:}}.
  es = struct('CLASH', 'CHOQUE', 'spacing', 'separación', 'contact', 'contacto', 'tight', 'justo');
  rows = {};  red = zeros(0, 2);
  for k = 1:numel(F)
    need = '';  if F(k).need > 0, need = sprintf('%.0f', F(k).need); end
    rows{end+1} = {es.(F(k).cls), F(k).a, F(k).b, sprintf('%.1f', F(k).clear), need, sprintf('%.0f, %.0f, %.0f', F(k).at)};
    if any(strcmp(F(k).cls, {'CLASH', 'spacing'})), red(end+1,:) = [k 1]; end
  end
  qrows = {};
  for q = Q
    if strcmp(q.mark, 'G'), tot = sprintf('%.1f L', q.vol); else, tot = sprintf('%.2f kg', q.mass); end
    Ls = '';  if q.L > 0, Ls = sprintf('%.0f', q.L); end
    qrows{end+1} = {q.mark, q.desc, sprintf('%d', q.n), Ls, tot};
  end
  tc = {blk_h(3, sprintf('**Choques y holguras (%d)**', numel(F))), ...
        blk_table({'Tipo', 'Pieza', 'Contra', 'Holgura', 'Mín.', 'Dónde (x, y, z)'}, rows, [0.13 0.24 0.24 0.1 0.08 0.21], [4 5], red)};
  tq = {blk_h(3, '**Cantidades por unión**'), ...
        blk_table({'Marca', 'Descripción', 'N', 'L', 'Total'}, qrows, [0.09 0.53 0.08 0.12 0.18], [3 4 5], [])};
end
