function b = blk_row(w, cols)
% BLK_ROW  blocks side by side: w = width fractions, cols = {{blocks}, {blocks}, ...}
  b = struct('k', 'row', 'w', w, 'cols', {cols});
end
