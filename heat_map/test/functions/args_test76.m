function [args_path] = args_test76(frame_num, prev_frame_folder)
%ARGS_TEST76
%   ARGS_PATH = ARGS_TEST76() Returns in ARGS_PATH the file path of a .mat
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

frame_num_str = num2str(frame_num,'%05d');

goal_img_path = {'~/maya/projects/fire/images/test112_like_111_volume0/goal1.png'};
goal_mask_img_path = {'~/maya/projects/fire/images/test112_like_111_volume0/trimap1-ext.png'};
in_img_path = {'~/maya/projects/fire/images/test112_like_111_volume0/synthetic1.tif'};
mask_img_path = {'~/maya/projects/fire/images/test112_like_111_volume0/trimap1-ext.png'};
raw_file_path = ['data/from_dmitry/volumes/frame' frame_num_str 'vox_clean_128.raw2'];
density_file_path = ['~/maya/projects/fire/data/from_dmitry/volumes/frame' frame_num_str 'vox_clean_128.raw2'];

% Previous frame temperature, exposure and density
if nargin == 1
    use_prev_frame = false;
else
    use_prev_frame = true;
end

if use_prev_frame
    PL = load(fullfile(prev_frame_folder, 'summary_file.mat'));
    prev_frame_dir_from_img = strrep(prev_frame_folder, L.project_path, '');

    prev_frame_raw_file_path = fullfile(prev_frame_dir_from_img , 'heat-map.raw');
    init_exposure = PL.summary_data.output.exposure;
    maya_new_density_scale = PL.summary_data.output.density;
end

scene_name = 'test112_like_111_volume0';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

error_foo = {@MSEPerceptual};
prior_fncs = {};
prior_weights = 1;

if use_prev_frame
    exposure_scales_range = [];
else
    exposure_scales_range = [0.01 1000];
end
density_scales_range = [0.01 300];

use_cache = false;

options.CreateSamplesFcn = @generate_gaussian_temperatures_icm;
options.UpdateSampleRangeFcn = @update_range_none_icm;
options.DataTermApproxFcn = {@eval_render_function_always_icm};
options.DataTermFcn = {@eval_render_function_always_icm};
options.PairWiseTermFcn = {@neighbour_distance_term_icm};
options.PairWiseTermFactors = [10];
options.ClusterFnc = @k_means_cluster;

if use_prev_frame
    options.ExposureFnc = @icm_estimate_exposure_none;
    options.ClusterUpdateFnc = @cluster_reduce_none;
    hm = read_raw_file(density_file_path);
    options.initial_num_clusters = hm.count;
    initGuessFnc = @getInitHeatMap_icm;
    max_ite = 1;
else
    options.ClusterUpdateFnc = @cluster_update_array;
    max_ite = 5;
end

maxFunEvals = inf;
time_limit = inf;

% Save all but L
save(args_path, '-regexp','^(?!(L|PL|hm|data_dir)$).', '-append');

end

