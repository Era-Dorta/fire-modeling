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


%% Get the color from the goal image
max_rgb = getImgModeColor(goal_img, goal_mask, n_bins);
getImgMeanColor( goal_img, goal_mask);
%% Find the closer RGB value for the goal image in fuel_type temperature data

norm_bb_rgb = zeros(size(bbdata, 1), 1);
for i=1:size(bbdata, 1)
    norm_bb_rgb(i) = norm(bbdata(i, 2:4) - max_rgb);
end
[~, Tidx] = min(norm_bb_rgb);

T = bbdata(Tidx, 1);

%% Generate initial population around that temperature

% Initialize the guess as having uniformly the computed temperature
c_heat_map.v(:) = T;

% Generate an initial population by randomly perturbing the guess with the
% given mean and sigma
InitialPopulation = gacreationfrominitguess( GenomeLength, FitnessFcn, options,  ...
    c_heat_map, mean_noise, sigma_noise, savePath );
end

