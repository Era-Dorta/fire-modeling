function [ InitialPopulation ] = gacreationheuristic3( GenomeLength, ~, ...
    options, goal_img,  goal_mask, fuel_type,  n_bins,  color_space, ...
    savePath )
%GACREATIONHEURISTIC3 Create a population for ga
%   [ INITIALPOPULATION ] = GACREATIONHEURISTIC3( GENOMELENGTH, FITNESSFCN,
%   OPTIONS, GOAL_IMG,  GOAL_MASK, FUEL_TYPE,  N_BINS,  COLOR_SPACE)
%
%   [ INITIALPOPULATION ] = GACREATIONHEURISTIC3( GENOMELENGTH, FITNESSFCN,
%   OPTIONS, GOAL_IMG,  GOAL_MASK, FUEL_TYPE,  N_BINS,  COLOR_SPACE,
%   SAVEPATH )
%

if nargin < 8
    error('Not enough input arguments.');
end

totalPopulation = sum(options.PopulationSize);
initPopProvided = size(options.InitialPopulation, 1);
individualsToCreate = totalPopulation - initPopProvided;

% The lb and ub parameters are mapped here if the option is not overriden
% by the user
range = options.PopInitRange;

% Initialize Population to be created
InitialPopulation = zeros(totalPopulation,GenomeLength);

% Use initial population provided already
if initPopProvided > 0
    % If not population is given, the algorithm initialization sets the
    % initial population as one individual, whose values are the the lower
    % bounds. If that is the case, ignore such individual
    if initPopProvided == 1 && isequal(options.InitialPopulation, range(1, :))
        individualsToCreate = totalPopulation;
        initPopProvided = 0;
    else
        InitialPopulation(1:initPopProvided,:) = options.InitialPopulation;
    end
end

% Fill the rest with the temperatures inferred from the goal image/s
if(individualsToCreate > 0)
    %% Load precomputed data
    code_dir = fileparts(fileparts(mfilename('fullpath')));
    bbdata = load([code_dir '/data/CT-' get_fuel_name(fuel_type) '.mat'], ...
        '-ascii');
    
    % Convert the RGB values in the Color-Temperature table to a new color
    % space
    colorsCT = reshape(bbdata(:,2:4), size(bbdata, 1), 1, 3);
    colorsCT = colorspace_transform_imgs({colorsCT}, 'RGB', color_space);
    bbdata(:,2:4) = reshape(colorsCT{1}, size(bbdata, 1), 3);
    
    %% Get the mean histogram from the goal image/s
    % Create n_bins bins
    edges = linspace(0, 255, n_bins+1);
    hc_goal = zeros(1, n_bins^3);
    num_goal = numel(goal_img);
    for i=1:num_goal
        hc_goal = hc_goal + getImgCombinedHistogram( goal_img{i}, ...
            goal_mask{i}, n_bins, edges, true);
    end
    hc_goal = hc_goal / num_goal;
    
    %% Find the closer RGB value for the goal image in fuel_type temperature data
    bin_width = 255 / n_bins;
    
    % Create a population by sampling the distribution extracted from the
    % goal image/s "combined" histogram
    InitPopHeuristic = randsample(1:numel(hc_goal), ...
        individualsToCreate * GenomeLength, true, hc_goal);
    
    InitPopHeuristic = reshape(InitPopHeuristic, individualsToCreate, ...
        GenomeLength);
    
    %% Transform from single histogram index to 3 separate ones, this is
    % just a numeric base conversion from base n_bins^3 - 1 to base n_bins
    InitPopColors = getColorFromHistoIndex( InitPopHeuristic, n_bins, ...
        bin_width);
    
    %% Add some noise to the colors, the noise moves the color randomly
    % inside the bin width, assuming that normal noise models well the
    % inner distribution, with more bins the noise model is less important
    max_deviation = bin_width / 2;
    
    noise = random('norm', 0, max_deviation / 3, size(InitPopColors));
    noise = min(max(noise, -max_deviation), max_deviation); % Check bounds
    InitPopColors = InitPopColors + noise;
    
    assert(all(InitPopColors(:) >= 0 & InitPopColors(:) <= 255), ...
        'Invalid color range');
    
    %% Get the corresponding temperature for each color
    size_pop_2 = size(InitPopColors, 2);
    parfor i=1:size(InitPopColors, 1)
        for j=1:size_pop_2
            colorDist = pdist2(reshape(InitPopColors(i,j,:), 1, 3), ...
                bbdata(:, 2:4));
            [~, tempIdx] = min(colorDist);
            InitPopHeuristic(i,j) = bbdata(tempIdx, 1);
        end
    end
    
    InitialPopulation(initPopProvided + 1:end, :) = InitPopHeuristic;
end

% Clamp to lower and upper bounds
InitialPopulation = bsxfun(@max, InitialPopulation, options.LinearConstr.lb');
InitialPopulation = bsxfun(@min, InitialPopulation, options.LinearConstr.ub');

if nargin == 9
    save(savePath, 'InitialPopulation');
end

end

