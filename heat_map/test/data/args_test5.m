function [args_path] = args_test5()
%ARGS_TEST5 Cmaes, approx
%   ARGS_PATH = ARGS_TEST5() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here. Main args are:
%   solver = 'cmaes'
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
args_path = [mfilename('fullpath') '.mat'];
args_test_template(args_path);

L = load(args_path);

solver = 'cmaes';
use_approx_fitness = true;

% Save all but L
save(args_path, '-regexp','^(?!(L)$).', '-append');

%% Change solver parameters
solver_path = [mfilename('fullpath') 'solver.mat'];
args_test_solver_template(solver_path, solver);

end
