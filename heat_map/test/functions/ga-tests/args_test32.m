function [args_path] = args_test32()
%ARGS_TEST32 Ga, histoNoEdge, mutationpermute
%   ARGS_PATH = ARGS_TEST31() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

L = load(args_path);

error_foo = {@histogramErrorOpti};

options = L.options;
options.MutationFcn = @gamutationpermute;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
