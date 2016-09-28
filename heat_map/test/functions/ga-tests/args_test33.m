function [args_path] = args_test33()
%ARGS_TEST33 Ga, histoNoEdge, imageSideDistribution
%   ARGS_PATH = ARGS_TEST33() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

L = load(args_path);

error_foo = {@histogramErrorOpti, @imageSideDistribution};

prior_weights = [0.2, 0.2, 0.2, 0.4];

options = L.options;
options.MutationFcn = @gamutationpermute;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
