function [args_path] = args_test8()
%ARGS_TEST8  GA, single goal, chi^2, 200 Pop
%   ARGS_PATH = ARGS_TEST8() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here. Main args are:
%   solver = 'sa'
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
args_path = [mfilename('fullpath') '.mat'];
args_test_template(args_path);

dist_foo = @chi_square_statistics_fast;

% Save all but L
save(args_path, '-regexp','^(?!(L)$).', '-append');

end
