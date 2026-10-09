function b = blk_table(head, rows, widths, right, red)
% BLK_TABLE  table: head {..}, rows {{..}, ..}, widths (fractions), right = right-aligned
% columns (1-based), red = [row col; ...] cells in red (1-based, body rows)
  b = struct('k', 'table', 'head', {head}, 'rows', {rows}, 'w', widths, ...
             'right', {right}, 'red', {red});
end
