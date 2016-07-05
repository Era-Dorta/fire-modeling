function [args_path] = args_test39()
%ARGS_TEST0 QMC Histo RGB
%   ARGS_PATH = ARGS_TEST39() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Save with default parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);

args_test_template(args_path);

L = load(args_path);

sample_divisions = 4;
num_samples = L.max_ite;

save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end