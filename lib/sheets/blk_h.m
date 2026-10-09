function b = blk_h(level, text)
% BLK_H  heading, level 1-3
  b = struct('k', sprintf('h%d', level), 't', text);
end
