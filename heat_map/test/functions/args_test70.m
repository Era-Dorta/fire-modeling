function [args_path] = args_test70()
%ARGS_TEST70 ICM_RE_DENSITY synthetic goal
%   ARGS_PATH = ARGS_TEST70() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path, false);

solver = 'icm-re-density';

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

% Update solver parameters
args_test_solver_template(args_path, solver);

L = load(args_path);
options = L.options;

goal_img_path = {'~/maya/projects/fire/images/test111_no_background/goal-cam1-synthetic.png'};
goal_mask_img_path = {'~/maya/projects/fire/data/from_dmitry/cam1/tri-map-aligned.png'};
in_img_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/test110_like_109_close_camera.tif'};
in_img_bg_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/background-new.png'};
mask_img_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/mask.png'};
raw_file_path = 'data/from_dmitry/vox_bin_00841_clean_32.raw2';
density_file_path = '~/maya/projects/fire/data/from_dmitry/vox_bin_00841_clean_32.raw2';

scene_name = 'test111_no_background';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

error_foo = {@MSEPerceptual};
prior_fncs = {};
prior_weights = 1;

exposure_scales_range = [0.01 1000];

n_exposure_scale = 2;

use_cache = false;

color_space = 'Lab';

options.CreateSamplesFcn = @generate_gaussian_temperatures_icm;
options.UpdateSampleRangeFcn = @update_range_none_icm;
options.DataTermApproxFcn = {@eval_render_function_always_icm_density};
options.DataTermFcn = {@eval_render_function_always_icm_density};
options.PairWiseTermFcn = {@neighbour_distance_term_icm};
options.PairWiseTermFactors = [10];
options.TemperatureNSamples = 30;

max_ite = 30;
options.MaxIterations = max_ite;

initGuessFnc = @getMeanTemp_icm;

options.NeighbourhoodSize = 1;

maxFunEvals = 6500; % Maximum number of allowed function evaluations
time_limit = 4 * 60 * 60; % Two hours
options.MaxFunctionEvaluations = maxFunEvals;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
