function [ InitialPopulation ] = gacreationheuristic2( GenomeLength, FitnessFcn, ...
    options, c_heat_map, goal_img,  goal_mask, fuel_type, color_space, ...
    savePath )
%GACREATIONHEURISTIC2 Create a population for ga
code_dir = fileparts(fileparts(mfilename('fullpath')));
bbdata = load([code_dir '/data/CT-' get_fuel_name(fuel_type) '.mat'], ...
    '-ascii');

mean_noise = 0;

% Conver the RGB values in the Color-Temperature table to a new color
% space
colorsCT = reshape(bbdata(:,2:4), size(bbdata, 1), 1, 3);
colorsCT = colorspace_transform_imgs({colorsCT}, 'RGB', color_space);
bbdata(:,2:4) = reshape(colorsCT{1}, size(bbdata, 1), 3);

%% Get the mean color and standard deviation from the goal image/s
goal_mean_rgb = getImgMeanColor( goal_img, goal_mask);
goal_std_rgb = getImgStdColor( goal_img, goal_mask);

%% Find the closer RGB value for the goal image in fuel_type temperature data

norm_bb_rgb = zeros(size(bbdata, 1), 1);
for i=1:size(bbdata, 1)
    norm_bb_rgb(i) = norm(bbdata(i, 2:4) - goal_mean_rgb);
end
[~, Tidx] = min(norm_bb_rgb);

T = bbdata(Tidx, 1);

%% Find the min and max temperature using the standard deviation
max_color = min([255,255,255], goal_mean_rgb + goal_std_rgb);
min_color = max([0,0,0], goal_mean_rgb - goal_std_rgb);

norm_bb_rgb = zeros(size(bbdata, 1), 2);
for i=1:size(bbdata, 1)
    norm_bb_rgb(i, 1) = norm(bbdata(i, 2:4) - max_color);
    norm_bb_rgb(i, 2) = norm(bbdata(i, 2:4) - min_color);
end

[~, Tidx] = min(norm_bb_rgb(:,1));
Tmax = abs(T - bbdata(Tidx, 1));

[~, Tidx] = min(norm_bb_rgb(:,2));
Tmin = abs(T - bbdata(Tidx, 1));

% As we are using a normal distribution for perturbations, 68% of the
% perturbations will fall within this sigma, with a 30% room for higher
% perturbations in the temperature
sigma_noise = max(Tmax, Tmin);

%% Generate initial population around that temperature

% Initialize the guess as having uniformly the computed temperature
c_heat_map.v(:) = T;

% Generate an initial population by randomly perturbing the guess with the
% given mean and sigma
InitialPopulation = gacreationfrominitguess( GenomeLength, FitnessFcn, options,  ...
    c_heat_map, mean_noise, sigma_noise, savePath );
end

