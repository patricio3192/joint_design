function it = d_lines(x, y, lines, s, a, dy)
% D_LINES  several lines of text as one item (cell array of strings); dy is not used
% (the printer spaces lines by the text size)
  it = {d_text(x, y, strjoin(lines, sprintf('\n')), s, a)};
end
