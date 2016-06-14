function [args_path] = args_test34()
%ARGS_TEST34 Ga, creationheuristic4
%   ARGS_PATH = ARGS_TEST34() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

L = load(args_path);

options = L.options;
options.CreationFcn = @gacreationheuristic4;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
