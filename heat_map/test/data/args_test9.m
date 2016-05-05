function [args_path] = args_test9()
%ARGS_TEST9  GA, single goal, Jensen, 200 Pop
%   ARGS_PATH = ARGS_TEST9() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here. Main args are:
%   solver = 'ga'
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
args_path = [mfilename('fullpath') '.mat'];
args_test_template(args_path);

dist_foo = @jensen_shannon_divergence;

% Save all but L
save(args_path, '-regexp','^(?!(L)$).', '-append');

end
