function [args_path] = args_test9()
%ARGS_TEST9  Jensen Shannon
%   ARGS_PATH = ARGS_TEST9() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

dist_foo = @jensen_shannon_divergence;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
