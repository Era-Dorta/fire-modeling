function [args_path] = args_test3()
%ARGS_TEST3 4 Population, 20 seconds, 2 genereation
%   ARGS_PATH = ARGS_TEST3() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);

args_test_template(args_path);

solver_path = fullfile(data_dir, [mfilename('clas') 'solver.mat']);

L = load(solver_path);

options = L.options;

options.PopulationSize = 4;
options.Generations = 2;
time_limit = 20; % In seconds
options.TimeLimit = time_limit;

% Update the variables that do not match the template
save(solver_path, 'time_limit', 'options', '-append');

end
