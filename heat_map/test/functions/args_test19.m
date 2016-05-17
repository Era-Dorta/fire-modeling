function [args_path] = args_test19()
%ARGS_TEST19 Seed 2
%   ARGS_PATH = ARGS_TEST19() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);

args_test_template(args_path);

rand_seed = 2;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end