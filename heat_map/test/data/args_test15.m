function [args_path] = args_test15()
%ARGS_TEST15 Gradient, approx
%   ARGS_PATH = ARGS_TEST15() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
args_path = [mfilename('fullpath') '.mat'];
args_test_template(args_path);

L = load(args_path);

solver = 'grad';
use_approx_fitness = true;

% Save all but L
save(args_path, '-regexp','^(?!(L)$).', '-append');

%% Change solver parameters
solver_path = [mfilename('fullpath') 'solver.mat'];
args_test_solver_template(solver_path, solver);

end
