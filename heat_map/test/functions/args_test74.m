function [args_path] = args_test74()
%ARGS_TEST74 ICM like args_test61
%   ARGS_PATH = ARGS_TEST74() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
load('~/maya/projects/fire/images/test111_no_background/icm-re-search12-size64-xyz-ordered-exp-density-cluster-each-ite-with-neigh/args_test61.mat');

solver = 'icm-re';

data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);

options.PairWiseTermFactors = [0.01];

maxFunEvals = 9187; % Maximum number of allowed function evaluations
time_limit = 8 * 60 * 60; % Two hours
options.MaxFunctionEvaluations = maxFunEvals;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).');

end
