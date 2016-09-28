function [args_path] = args_test30()
%ARGS_TEST30 Permute solver
%   ARGS_PATH = ARGS_TEST30() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path, false);

solver = 'permute';

% Update solver parameters
args_test_solver_template(args_path, solver);

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
