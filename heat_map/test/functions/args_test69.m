function [args_path] = args_test69()
%ARGS_TEST69 ICM_RE Test113, two goal
%   ARGS_PATH = ARGS_TEST69() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path, false);

solver = 'icm-re';

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

% Update solver parameters
args_test_solver_template(args_path, solver);

L = load(args_path);
options = L.options;

goal_img_path = {'~/maya/projects/fire/images/test113_no_background_maya_data/goal1-camera1.png', ...
    '~/maya/projects/fire/images/test113_no_background_maya_data/goal1-camera2.png'};
goal_mask_img_path = {'~/maya/projects/fire/images/test113_no_background_maya_data/trimap1-camera1.png', ...
    '~/maya/projects/fire/images/test113_no_background_maya_data/trimap1-camera2.png'};
in_img_path = {'~/maya/projects/fire/images/test113_no_background_maya_data/goal1-camera1-maya-render.png', ...
    '~/maya/projects/fire/images/test113_no_background_maya_data/goal1-camera2-maya-render.png'};
mask_img_path = {'~/maya/projects/fire/images/test113_no_background_maya_data/mask1-camera1.png', ...
    '~/maya/projects/fire/images/test113_no_background_maya_data/mask1-camera2.png'};
raw_file_path = 'data/heat_maps/maya-flame-preset/temperature30-reduced2.raw';
density_file_path = '~/maya/projects/fire/data/heat_maps/maya-flame-preset/temperature30-reduced2.raw';
in_img_bg_path = {L.in_img_bg_path{1}, L.in_img_bg_path{1}};

scene_name = 'test113_no_background_maya_data';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

error_foo = {@MSEPerceptual};
prior_fncs = {};
prior_weights = 1;

exposure_scales_range = [0.01 1000];
density_scales_range = [0.01 300];

use_cache = false;

color_space = 'Lab';

options.CreateSamplesFcn = @generate_gaussian_temperatures_icm;
options.UpdateSampleRangeFcn = @update_range_none_icm;
options.DataTermApproxFcn = {@eval_render_function_always_icm};
options.DataTermFcn = {@eval_render_function_always_icm};
options.PairWiseTermFcn = {@neighbour_distance_term_icm};
options.PairWiseTermFactors = [10];

initGuessFnc = @random_guess_icm;

options.NeighbourhoodSize = 1;

%%
options.TemperatureNSamples = 1;
max_ite = 1;
options.MaxIterations = max_ite;
exposure_scales_range = [10 200];
density_scales_range = [1 100];
n_exposure_scale = 1;
n_density_scale = 1;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
