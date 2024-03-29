function [args_path] = args_test41()
%ARGS_TEST41 Uniform Sampler Maya Render
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
in_img_path = {'~/maya/projects/fire/images/test104_maya_render/synthetic1.tif'};
mask_img_path = {'~/maya/projects/fire/images/test104_maya_render/mask-synthetic1.png'};
raw_file_path = 'data/heat_maps/maya-flame-preset/temperature30-reduced2.raw';

scene_name = 'test104_maya_render';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

color_space = {'RGB', 'HSL', 'Luv'};

is_custom_shader = false;

% Maya temperatures use an normalised scale of [0,1]
LB = 0; 
UB = 1;

max_ite = 3000;
maxFunEvals = max_ite;
samples_n_bins = 100; % Number of bins
num_samples = 100 * samples_n_bins; % 100 samples for each bin
sample_method = 'mirror';

save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end