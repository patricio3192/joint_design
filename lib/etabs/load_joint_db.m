function DB = load_joint_db(dbfile)
% LOAD_JOINT_DB  Load the database written by build_joint_db.
%   Warns when the ETABS export has changed since the database was built.

  if nargin < 1 || isempty(dbfile)
    error('load_joint_db: give the database file (.../joint_db/joint_db.mat).');
  end
  if ~exist(dbfile, 'file')
    error('%s not found. Run build_joint_db first.', dbfile);
  end
  S  = load(dbfile);
  DB = S.DB;

  d = dir(DB.source);
  if isempty(d)
    warning('Source %s not found; cannot tell whether the database is current.', DB.source);
  elseif d.datenum ~= DB.srcdate || d.bytes ~= DB.srcbytes
    warning('%s changed after the database was built (%s). Run build_joint_db again.', ...
            DB.source, DB.built);
  end
  fprintf('Joint database: %d joints, built %s from %s\n', ...
          numel(DB.joints), DB.built, DB.source);
end
