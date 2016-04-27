function [project_path, scene_name, raw_file_path, scene_img_folder, ...
    goal_img_path, goal_mask_img_path, mask_img_path] = get_test_paths( ...
    multi_goal, symmetric )
%GET_TEST_PATHS Returns path for heatMapReconstruction
%   [...] = GET_TEST_PATHS(MULTI_GOAL, SYMMETRIC) MULTI_GOAL and SYMMETRIC
%   are two logical parameters indicating where the test includes multigoal
%   images optimization and symmetric or asymmetric goal image/s.
%
%   See also heatMapReconstruction

% For single goal image the Maya scene must have only one renderable
% camera, for multiple goal images, it is assumed that there are as many
% cameras in the scene as goal images. If there are more cameras they must
% have the rendererable attribute set to false. Each camera must be named
% as "cameraNShape". The first goal image belongs to camera1Shape, the
% second to camera2Shape and so on.
project_path = '~/maya/projects/fire/';
scene_name = 'test95_gaussian_new';
scene_img_folder = [project_path 'images/' scene_name '/'];

goal_mask_img_path{1} = [scene_img_folder 'maskcam1.png'];
mask_img_path{1} = [scene_img_folder 'maskcam1.png'];

if multi_goal
    goal_mask_img_path{2} = [scene_img_folder 'maskcam2.png'];
    mask_img_path{2} = [scene_img_folder 'maskcam2.png'];
end

if symmetric
    raw_file_path = 'data/heat_maps/gaussian4x4x4new.raw';
    
    goal_img_path{1} = [scene_img_folder 'goalimage1.tif'];
    
    if multi_goal
        goal_img_path{2} = {[scene_img_folder 'goalimage2.tif']};
    end
else
    raw_file_path = 'data/heat_maps/asymmetric4x4x4new.raw';
    
    goal_img_path{1} = [scene_img_folder 'goalimage1-asym.tif'];
    
    if multi_goal
        goal_img_path{2} = {[scene_img_folder 'goalimage2-asym.tif']};
    end
end

end

