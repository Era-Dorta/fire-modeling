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
mask_img_path = {'~/maya/projects/fire/images/test104_maya_render/mask-synthetic1.png'};
raw_file_path = 'data/heat_maps/maya-flame-preset/temperature30-reduced.raw';

scene_name = 'test104_maya_render';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

color_space = {'RGB', 'HSV', 'Luv', 'XYZ'};

% N.B. in Maya software renderer, lower temperatures mean brighter values
is_mr = false; % Using Maya renderer

LB = 0; % Maya temperatures use a arbitrary scale from 0 to 2
UB = 2;

max_ite = 3000;
maxFunEvals = max_ite;
samples_n_bins = 100; % Number of bins
num_samples = 100 * samples_n_bins; % 100 samples for each bin
sample_method = 'mirror';

save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end