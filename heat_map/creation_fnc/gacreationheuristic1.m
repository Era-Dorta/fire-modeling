function [ InitialPopulation ] = gacreationheuristic1( GenomeLength, FitnessFcn, ...
    options, c_heat_map, goal_img,  goal_mask, fuel_type, n_bins, ...
    color_space, savePath )
%GACREATIONHEURISTIC1 Create a population for ga
code_dir = fileparts(fileparts(mfilename('fullpath')));
bbdata = load([code_dir '/data/CT-' get_fuel_name(fuel_type) '.mat'], ...
    '-ascii');

mean_noise = 0;
sigma_noise = 250;

% Conver the RGB values in the Color-Temperature table to a new color
% space
colorsCT = reshape(bbdata(:,2:4), size(bbdata, 1), 1, 3);
colorsCT = colorspace_transform_imgs({colorsCT}, 'RGB', color_space);
bbdata(:,2:4) = reshape(colorsCT{1}, size(bbdata, 1), 3);


%% Compute histogram of the goal image

% Create n_bins bins for the histogram
edges = linspace(0, 255, n_bins+1);

% Multi goal optimization, compute the mean histogram of all the goal
% images
hc_goal = zeros(3, n_bins);
num_goal = numel(goal_img);
for i=1:num_goal
    if(size(goal_mask{i}, 3) == 3)
        goal_mask{i}= goal_mask{i}(:,:,1);
    end
    
    sub_img = goal_img{i}(:, :, 1);
    hc_goal(1, :) = hc_goal(1, :) + histcounts( sub_img(goal_mask{i}), edges);
    
    sub_img = goal_img{i}(:, :, 2);
    hc_goal(2, :) = hc_goal(2, :) + histcounts( sub_img(goal_mask{i}), edges);
    
    sub_img = goal_img{i}(:, :, 3);
    hc_goal(3, :) = hc_goal(3, :) + histcounts( sub_img(goal_mask{i}), edges);
end
hc_goal = hc_goal ./ num_goal;


%% Find the closer RGB value for the goal image in fuel_type temperature data

% Get the most common RGB value
[~, max_rgb] = max(hc_goal, [], 2);

norm_bb_rgb = zeros(size(bbdata, 1), 1);
for i=1:size(bbdata, 1)
    norm_bb_rgb(i) = norm(bbdata(i, 2:4) - max_rgb');
end
[~, Tidx] = min(norm_bb_rgb);

T = bbdata(Tidx, 1);

% If the guess is a either limit of the precomputed temperature range, then
% move the guess a bit inside the range, for better exploration, as we are
% perturbing we are likely to generate an individual close to the the
% original temperature guess anyway
if(T < options.LinearConstr.lb(1) + mean_noise + sigma_noise)
    T = options.LinearConstr.lb(1) + mean_noise + sigma_noise;
end

if(T + mean_noise + sigma_noise > options.LinearConstr.ub(1) )
    T = options.LinearConstr.ub(1) - mean_noise - sigma_noise;
end

%% Generate initial population around that temperature

% Initialize the guess as having uniformly the computed temperature
c_heat_map.v(:) = T;

% Generate an initial population by randomly perturbing the guess with the
% given mean and sigma
InitialPopulation = gacreationfrominitguess( GenomeLength, FitnessFcn, options,  ...
    c_heat_map, mean_noise, sigma_noise, savePath );
end

