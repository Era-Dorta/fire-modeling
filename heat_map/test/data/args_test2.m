function [args_path] = args_test2()
%ARGS_TEST2 Arguments for heatMapReconstruction
%   ARGS_PATH = ARGS_TEST2() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here. Main args are:
%   solver = 'ga'
%   use_approx_fitness = true;
%   dist_foo = @histogram_sum_abs;
%   error_foo = {@histogramDErrorOpti};
%   PopulationSize = 200;
%   CreationFcn = @gacreationheuristic1;
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
args_path = [mfilename('fullpath') '.mat'];
args_test_template(args_path);

use_approx_fitness = true; % Using the approximate fitness

% Update the variables that do not match the template
save(args_path, '*', '-append');

%% Change solver parameters
solver_path = [mfilename('fullpath') 'solver.mat'];

L = load(solver_path);

options = L.options;

time_limit = 30; % In seconds
options.TimeLimit = time_limit;

% Update the variables that do not match the template
save(solver_path, 'time_limit', 'options', '-append');

end
