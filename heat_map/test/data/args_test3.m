function [args_path] = args_test3()
%ARGS_TEST3 Ga, single goal, 4 Population
%   ARGS_PATH = ARGS_TEST3() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here. Main args are:
%   solver = 'ga'
%   use_approx_fitness = false;
%   dist_foo = @histogram_sum_abs;
%   error_foo = {@histogramDErrorOpti};
%   PopulationSize = 4;
%   CreationFcn = @gacreationheuristic1;
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

args_path = [mfilename('fullpath') '.mat'];
args_test_template(args_path);

solver_path = [mfilename('fullpath') 'solver.mat'];
L = load(solver_path);

options = L.options;

options.PopulationSize = 4;
options.Generations = 2;
time_limit = 20; % In seconds
options.TimeLimit = time_limit;

% Update the variables that do not match the template
save(solver_path, 'time_limit', 'options', '-append');

end
