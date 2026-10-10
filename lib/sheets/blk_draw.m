function b = blk_draw(items, h, cap, note, scale)
% BLK_DRAW  drawing block: items in model mm, h = height on paper (mm), bold caption,
% optional note below it (keep it to one line: details go on the drawing as labels),
% optional scale: 'std' = the next standard scale that fits (1:10, 1:20, 1:25,
% 1:50 ...) or a number N for 1:N (used if it fits); printed as "ESC 1:N" after
% the caption. Without scale the drawing just fills the block.
  b = struct('k', 'drawing', 'items', {items}, 'h', h, 'cap', cap);
  if nargin >= 4, b.note = note; end
  if nargin >= 5 && ~isempty(scale), b.scale = scale; end
end
