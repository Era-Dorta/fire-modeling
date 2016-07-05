function [args_path] = args_test39()
%ARGS_TEST39 QMC Histo RGB
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

goal_img_path = {'~/maya/projects/fire/data/fire-test-pics/real-fire1.jpg'};
goal_mask_img_path = {'~/maya/projects/fire/data/fire-test-pics/trimap/real-fire1-mask.png'};
mask_img_path = {'~/maya/projects/fire/images/test102_maya_data/flame-30-mask1.png'};
raw_file_path = 'data/heat_maps/maya-flame-preset/temperature30-reduced.raw';

scene_name = 'test102_maya_data';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

raw_temp_scale = 600;
raw_temp_offset = 1200;

max_ite = 3000;
maxFunEvals = max_ite;
sample_divisions = 4;
num_samples = max_ite;

save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end