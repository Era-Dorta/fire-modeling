function [args_path] = args_test8()
%ARGS_TEST8  Chi square
%   ARGS_PATH = ARGS_TEST8() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

dist_foo = @chi_square_statistics_fast;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
