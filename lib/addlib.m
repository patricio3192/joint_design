function addlib()
% ADDLIB  put every library of lib/ on the Octave path (not examples/ or tests/).
%   addpath('/path/to/joint_design/lib');  addlib();
% Libraries can also be added one by one; each README lists what it needs.
  here = fileparts(mfilename('fullpath'));
  d = dir(here);
  for k = 1:numel(d)
    if d(k).isdir && d(k).name(1) ~= '.' && exist(fullfile(here, d(k).name), 'dir')
      if any(strcmp(d(k).name, {'printing'})), continue; end     % Python only
      addpath(fullfile(here, d(k).name));
    end
  end
end
