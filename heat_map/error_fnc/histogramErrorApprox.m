function histoE = histogramErrorApprox( v, goal_img, goal_mask)
%HISTOGRAMERRORAPPROX computes an error measure between v and goal image
%   HISTOE = HISTOGRAMERRORAPPROX( V, GOAL_IMG, GOAL_MASK ) V is a value
%   matrix NxM, with N heat maps with M values per heat map. GOAL_IMG is
%   and PxQ RGB of image and GOAL_MASK is a PxQ logical matrix used as a
%   mask for GOAL_IMG, HISTOE is the error value

persistent CTtable GoalHisto NumGoal

% Create 256 bins, image can be 0..255
edges = linspace(0, 255, 256);

if(isempty(CTtable))
    code_dir = fileparts(fileparts(mfilename('fullpath')));
    CTtable = load([code_dir '/data/CT-BlackBody.mat'], '-ascii');
    
    NumGoal = numel(goal_img);
    GoalHisto = cell(NumGoal, 1);
    
    for i=1:NumGoal
        GoalHisto{i} = zeros(3, 255);
        
        sub_img = goal_img{i}(:, :, 1);
        GoalHisto{i}(1, :) = histcounts( sub_img(goal_mask{i}), edges);
        sub_img = goal_img{i}(:, :, 2);
        GoalHisto{i}(2, :) = histcounts( sub_img(goal_mask{i}), edges);
        sub_img = goal_img{i}(:, :, 3);
        GoalHisto{i}(3, :) = histcounts( sub_img(goal_mask{i}), edges);
        
        % Normalize by the number of pixels
        GoalHisto{i} = GoalHisto{i} ./ sum(goal_mask{i}(:) == 1);
    end
end

% interp_method = 'nearest'; % C0
interp_method = 'linear'; % C0
% interp_method = 'cubic'; % C1
% interp_method = 'spline'; % C2

num_vol = size(v, 1);
histoE = zeros(1, num_vol);
num_temp_inv = 1.0 / numel(v(1, :));

histo_est = zeros(3, 255);

for i=1:num_vol
    % Get the estimated color for each voxel using the table, as the
    % temperatures in the table are discrete samples, use an interpolation
    % method to get the colors for the current temperatures, assume that
    % anything outside the table is black [0, 0, 0]
    colors_est = interp1(CTtable(:, 1), CTtable(:, 2:4), v(i,:), ...
        interp_method, 0);
    
    % Compute the histograms of the color estimates
    % Normalize by the number of voxels, which should be equivalent to
    % normalize by the number of pixels, in the end just getting a normalized
    % histogram
    histo_est(1, :) = histcounts( colors_est(:,1), edges) * num_temp_inv;
    histo_est(2, :) = histcounts( colors_est(:,2), edges) * num_temp_inv;
    histo_est(3, :) = histcounts( colors_est(:,3), edges) * num_temp_inv;
    
    for j=1:NumGoal
        histoE(i) = histoE(i) + ...
            (sum(abs(histo_est(1, :) - GoalHisto{j}(1, :))) +  ...
            sum(abs(histo_est(2, :) - GoalHisto{j}(2, :))) + ...
            sum(abs(histo_est(3, :) - GoalHisto{j}(3, :))));
    end
end

histoE = histoE ./ (NumGoal * 6);

end
