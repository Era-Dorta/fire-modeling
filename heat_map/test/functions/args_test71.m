function [args_path] = args_test71()
%ARGS_TEST71 GA, test111 128size
%   ARGS_PATH = ARGS_TEST71() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path, false);

solver = 'ga';

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

% Update solver parameters
args_test_solver_template(args_path, solver);

L = load(args_path);
options = L.options;

goal_img_path = {'~/maya/projects/fire/data/from_dmitry/cam1/goal1-aligned.png'};
goal_mask_img_path = {'~/maya/projects/fire/data/from_dmitry/cam1/tri-map-aligned.png'};
in_img_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/test110_like_109_close_camera.tif'};
in_img_bg_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/background-new.png'};
mask_img_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/mask.png'};
raw_file_path = 'data/from_dmitry/vox_bin_00841_clean_128.raw2';
density_file_path = '~/maya/projects/fire/data/from_dmitry/vox_bin_00841_clean_128.raw2';

scene_name = 'test111_no_background';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

error_foo = {@MSEPerceptual};
prior_fncs = {@smoothnessEstimateGrad};
prior_weights = [0.5, 0.5];

% Data from icm-re-search8-size128-xyz-ordered-exp-density-cluster-each-ite-6-hours
init_exposure = 57.3888741892001;
maya_new_density_scale = 151.771899639965;

use_cache = false;

color_space = 'Lab';

options = L.options;

options.CreationFcn = @gacreationrandom;
options.CrossoverFcn = @gacrossovercombine2;
options.MutationFcn = @mutationadaptfeasible;
options.OutputFcns = [options.OutputFcns, {@ga_user_interrupt}];

max_ite = 30;
maxFunEvals = 1e8;
time_limit = 5 * 60 * 60;
options.Generations = max_ite;
options.TimeLimit = time_limit;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
