function [args_path] = args_test15()
%ARGS_TEST15 Gradient, approx
%   ARGS_PATH = ARGS_TEST15() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

L = load(args_path);

solver = 'grad';
use_approx_fitness = true;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

%% Change solver parameters
solver_path = fullfile(data_dir, [mfilename('clas') 'solver.mat']);
args_test_solver_template(solver_path, solver);

end
