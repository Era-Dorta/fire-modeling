function histoV = histogramEstimate( xyz, v, volumeSize, goal_img, goal_mask)
%UPHEATESTIMATE estimate heatMap upwards heat
%   UP_HEAT_V = UPHEATESTIMATE( XYZ, V, VOLUME_SIZE ) returns large values
%   in UP_HEAT_V if the heat in the flame goes "up" and lower values
%   otherwise. The estimate is in arbitrary units for the heatmaps defined
%   by the common coordinates matrix 3xM XYZ, the value matrix NxM V, where
%   the coordinates are in a volume given by VOLUME_SIZE 1X3.

persistent CTtable GoalHisto

if(isempty(CTtable))
    code_dir = fileparts(fileparts(mfilename('fullpath')));
    CTtable = load([code_dir '/data/CT-BlackBody.mat'], '-ascii');
    
    % Create 256 bins, image can be 0..255
    edges = linspace(0, 255, 256);
    GoalHisto = zeros(3, 255);
    
    sub_img = goal_img(:, :, 1);
    GoalHisto(1, :) = histcounts( sub_img(goal_mask), edges);
    sub_img = goal_img(:, :, 2);
    GoalHisto(2, :) = histcounts( sub_img(goal_mask), edges);
    sub_img = goal_img(:, :, 3);
    GoalHisto(3, :) = histcounts( sub_img(goal_mask), edges);
    
    % Normalize by the number of pixels
    GoalHisto = GoalHisto ./ sum(goal_mask(:) == 1);
end

% interp_method = 'nearest'; % C0
interp_method = 'linear'; % C0
% interp_method = 'cubic'; % C1
% interp_method = 'spline'; % C2

num_vol = size(v, 1);
histoV = zeros(1, num_vol);
num_temp_inv = 1.0 / numel(v(1, :));

histo_est = zeros(3, 255);

for i=1:num_vol
    % Get the estimated color for each voxel using the table, as the
    % temperatures in the table are discrete samples, use an interpolation
    % method to get the colors for the current temperatures
    colors_est = interp1(CTtable(:, 1), CTtable(:, 2:4), v(i,:), interp_method);

    % Compute the histograms of the color estimates    
    % Normalize by the number of voxels, which should be equivalent to
    % normalize by the number of pixels, in the end just getting a normalized
    % histogram
    histo_est(1, :) = histcounts( colors_est(:,1), edges) * num_temp_inv;
    histo_est(2, :) = histcounts( colors_est(:,2), edges) * num_temp_inv;
    histo_est(3, :) = histcounts( colors_est(:,3), edges) * num_temp_inv;

    histoV(i) = (sum(abs(histo_est(1, :) - GoalHisto(1, :))) +  ...
        sum(abs(histo_est(2, :) - GoalHisto(2, :))) + ...
        sum(abs(histo_est(3, :) - GoalHisto(3, :)))) / 3;
end

end
