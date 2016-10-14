function [args_path] = args_test67()
%ARGS_TEST67 ICM_RE Test112, frame3, two goal
%   ARGS_PATH = ARGS_TEST67() Returns in ARGS_PATH the file path of a .mat
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

goal_img_path = {'~/maya/projects/fire/data/from_dmitry/volumes/RequestedFrames/goal3-aligned.png', ...
    '~/maya/projects/fire/data/from_dmitry/volumes/RequestedFrames/cam2/goal3-aligned.png'};
goal_mask_img_path = {'~/maya/projects/fire/images/test112_like_111_volume0/trimap-cam1-frame3.png', ...
    '~/maya/projects/fire/images/test112_like_111_volume0/trimap-cam2-frame3.png', };
in_img_path = {'~/maya/projects/fire/images/test112_like_111_volume0/synthetic-cam1-frame3.tif', ...
    '~/maya/projects/fire/images/test112_like_111_volume0/synthetic-cam2-frame3.tif'};
mask_img_path = {'~/maya/projects/fire/images/test112_like_111_volume0/mask-cam1-frame3.png', ...
    '~/maya/projects/fire/images/test112_like_111_volume0/mask-cam2-frame3.png'};
raw_file_path = 'data/from_dmitry/volumes/frame00003vox_clean_128.raw2';
density_file_path = '~/maya/projects/fire/data/from_dmitry/volumes/frame00003vox_clean_128.raw2';
in_img_bg_path = {L.in_img_bg_path{1}, L.in_img_bg_path{1}};

scene_name = 'test112_like_111_volume0';
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

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end