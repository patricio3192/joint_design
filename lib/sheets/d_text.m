function it = d_text(x, y, txt, s, a)
% D_TEXT  text at (x, y), size in points from style s; a = 'start' | 'middle' | 'end';
% several lines separated by newlines
  it = struct('t', 'text', 'p', [x y], 'txt', txt, 's', s, 'a', a);
end
