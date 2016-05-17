function [args_path] = args_test2()
%ARGS_TEST2 Approx, 30 seconds
%   ARGS_PATH = ARGS_TEST2() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here. Main args are:
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);

args_test_template(args_path);

L = load(args_path);

use_approx_fitness = true; % Using the approximate fitness

options = L.options;

time_limit = 30; % In seconds
options.TimeLimit = time_limit;

% Update the variables that do not match the template
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
