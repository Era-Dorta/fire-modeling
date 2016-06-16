function [args_path] = args_test35()
%ARGS_TEST35 Maya-Render/Data
%   ARGS_PATH = ARGS_TEST35() Returns in ARGS_PATH the file path of a .mat
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
mask_img_path = {'~/maya/projects/fire/images/test104_maya_render/mask-synthetic1.png'};
raw_file_path = 'data/heat_maps/maya-flame-preset/temperature30-reduced.raw';

scene_name = 'test104_maya_render';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

% N.B. in Maya software renderer, lower temperatures mean brighter values
is_mr = false; % Using Maya renderer

LB = 0; % Maya temperatures use a arbitrary scale from 0 to 2
UB = 2;

options = L.options;

% Heuristic creation is based on "real" temperatures in Kelvin, as Maya
% uses an arbitrary scale, we cannot use the prior creation functions
options.CreationFcn = @gacreationrandom;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
