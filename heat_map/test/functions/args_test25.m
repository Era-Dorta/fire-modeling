function [args_path] = args_test25()
%ARGS_TEST25 gaussian_weighted_intersection_opti intersection
%   ARGS_PATH = ARGS_TEST25() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

dist_foo = @gaussian_weighted_intersection_opti;
is_histo_independent = false;
n_bins = 20;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
