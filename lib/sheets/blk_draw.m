function b = blk_draw(items, h, cap, note)
% BLK_DRAW  drawing block: items in model mm, h = height on paper (mm), bold caption,
% optional note below it
  if nargin < 4
    b = struct('k', 'drawing', 'items', {items}, 'h', h, 'cap', cap);
  else
    b = struct('k', 'drawing', 'items', {items}, 'h', h, 'cap', cap, 'note', note);
  end
end
