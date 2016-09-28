function [args_path] = args_test36()
%ARGS_TEST36 Maya-Data1, Real-Fire1 Goal
%   ARGS_PATH = ARGS_TEST36() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

L = load(args_path);

goal_img_path = {'~/maya/projects/fire/data/fire-test-pics/real-fire1.jpg'};
goal_mask_img_path = {'~/maya/projects/fire/data/fire-test-pics/trimap/real-fire1-mask.png'};
mask_img_path = {'~/maya/projects/fire/images/test102_maya_data/flame-30-mask1.png'};
raw_file_path = 'data/heat_maps/maya-flame-preset/temperature30-reduced.raw';

scene_name = 'test102_maya_data';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

raw_temp_scale = 600;
raw_temp_offset = 1200;

error_foo = {@histogramErrorOpti};
prior_fncs = {};

prior_weights = 1;

options = L.options;

options.CrossoverFcn = @gacrossovercombine;
options.MutationFcn = @mutationadaptfeasible;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
