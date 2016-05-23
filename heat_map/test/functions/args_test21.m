function [args_path] = args_test21()
%ARGS_TEST21 CreationHeuristic3
%   ARGS_PATH = ARGS_TEST21() Returns in ARGS_PATH the file path of a .mat
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

options.CreationFcn = @gacreationheuristic3;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
