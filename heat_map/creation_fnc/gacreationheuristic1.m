function [ InitialPopulation ] = gacreationheuristic1( GenomeLength, FitnessFcn, ...
    options, c_heat_map, goal_img,  goal_mask, savePath )
%GACREATIONHEURISTIC1 Create a population for ga

code_dir = fileparts(fileparts(mfilename('fullpath')));
bbdata = read_bbdata([code_dir '/data/bbr_precomputed.txt']);

mean_noise = 0;
sigma_noise = 500;

%% Compute histogram of the goal image

% Create 256 bins, image can be 0..255
edges = linspace(0, 255, 256);

if(size(goal_mask, 3) == 3)
    goal_mask = goal_mask(:,:,1);
end

sub_img = goal_img(:, :, 1);
hc_goal(1, :) = histcounts( sub_img(goal_mask), edges);

sub_img = goal_img(:, :, 2);
hc_goal(2, :) = histcounts( sub_img(goal_mask), edges);

sub_img = goal_img(:, :, 3);
hc_goal(3, :) = histcounts( sub_img(goal_mask), edges);

%% Find the closer RGB value for the goal image in black body temperature data

% Get the most common RGB value
[~, max_rgb] = max(hc_goal, [], 2);

norm_bb_rgb = zeros(size(bbdata, 1), 1);
for i=1:size(bbdata, 1)
    norm_bb_rgb(i) = norm(bbdata(i, 2:4) - max_rgb');
end
[~, Tidx] = min(norm_bb_rgb);

T = bbdata(Tidx, 1);

% The black body table lower value is 1000K, lowe than that there is no 
% radiation, so move the temperature up to generate good guesses. Since is 
% going to be randomly perturb we are going to get heat maps with 
% temperatures close to the original one
if(T < 1000 + mean_noise + sigma_noise)
    T = 1000 + mean_noise + sigma_noise;
end

%% Generate initial population around that temperature

% Initialize the guess as having uniformly the computed temperature
c_heat_map.v(:) = T;

% Generate an initial population by randomly perturbing the guess with the
% given mean and sigma
InitialPopulation = gacreationfrominitguess( GenomeLength, FitnessFcn, options,  ...
    c_heat_map, mean_noise, sigma_noise, savePath );
end
