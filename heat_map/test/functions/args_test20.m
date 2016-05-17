function [args_path] = args_test20()
%ARGS_TEST20 PriorW [0.8, 0.15, 0.05]
%   ARGS_PATH = ARGS_TEST20() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

L = load(args_path);

% 80% Color matching, 15% smoothness, 5% heat up
prior_weights = [0.8, 0.15, 0.05];

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

% Update solver parameters
args_test_solver_template(args_path, solver);

end
