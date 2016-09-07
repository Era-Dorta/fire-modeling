function [args_path] = args_test48()
%ARGS_TEST48 Vox_bin_00841 64, Vox_bin_00841 Goal
%   ARGS_PATH = ARGS_TEST48() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

L = load(args_path);

goal_img_path = {'~/maya/projects/fire/data/from_dmitry/cam1/goal1.png'};
goal_mask_img_path = {'~/maya/projects/fire/data/from_dmitry/cam1/tri-map.png'};
in_img_path = {'~/maya/projects/fire/images/test109_same_input/test109_same_input.tif'};
in_img_bg_path = {'~/maya/projects/fire/images/test109_same_input/background-new.png'};
mask_img_path = {'~/maya/projects/fire/images/test109_same_input/mask.png'};
raw_file_path = 'data/from_dmitry/vox_bin_00841_clean_64.raw2';
density_file_path = '~/maya/projects/fire/data/from_dmitry/vox_bin_00841_clean_64.raw2';

scene_name = 'test109_same_input';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

error_foo = {@histogramErrorOpti};
prior_fncs = {};

prior_weights = 1;

options = L.options;

options.CreationFcn = @gacreationrandom;
options.CrossoverFcn = @gacrossovercombine2;
options.MutationFcn = @mutationuniform;
density_scales_range = [0.01 1000];

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
