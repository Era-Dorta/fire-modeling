function [args_path] = args_test22()
%ARGS_TEST22 Candle synthetic, Pegoraro1 Goal
%   ARGS_PATH = ARGS_TEST22() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

L = load(args_path);

goal_img_path = {'~/maya/projects/fire/data/fire-test-pics/pegoraro1.png'};
goal_mask_img_path = {'~/maya/projects/fire/data/fire-test-pics/trimap/pegoraro1-mask.png'};
mask_img_path = {'~/maya/projects/fire/images/test99_synthetic32x32x32/mask-synth1.png'};
raw_file_path = 'data/from_dmitry/NewData/oneFlame/synthetic32x32x32.raw';

scene_name = 'test99_synthetic32x32x32';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
