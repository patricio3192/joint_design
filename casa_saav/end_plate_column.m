% =========================================================================
% casa_saav / end_plate_column.m
% IPE 240 CANTILEVER - FLUSH END PLATE ON THE CONCRETE COLUMN C4 (same detail
% at B4, D4X, D4Y, D3). The end plate is set on 4 cast-in threaded rods
% (A193 B7) after the joint is cast, over a 30 mm grout layer. The rods end
% in square head plates inside the column hoop cage. All rod tension is taken
% by 2 L-shaped bars ("bastones") lapping into the VCM.
% Checks: lib/end_plate_concrete/check_end_plate_column.m (limits: CLAUDE.md there).
% Open items: notes/end_plate_PENDIENTE.txt. Output: reports/end_plate_column_output.txt
%   octave-cli casa_saav/end_plate_column.m > casa_saav/reports/end_plate_column_output.txt
% Units: N, mm, MPa. Coordinates: x along the column face (0 = cantilever
% axis = column axis), y down from the top of the beams, z into the column.
% =========================================================================
clc; clear;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'lib', 'end_plate_concrete'), fullfile(here, '..', 'lib', 'concrete_common'));
addpath(fullfile(here, 'data'));

P = end_plate_C4();                % every input: data/end_plate_C4.m
R = check_end_plate_column(P);
