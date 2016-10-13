function [args_path] = args_test72()
%ARGS_TEST72 ICM_RE_DENSITY synthetic goal
%   ARGS_PATH = ARGS_TEST72() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
load('~/maya/projects/fire/images/test111_no_background/icm-re-search13-size128-two-goal-xyz-ordered-exp-density-cluster-each-ite-with-neigh-20-hours/args_test64.mat');

solver = 'icm';

data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
