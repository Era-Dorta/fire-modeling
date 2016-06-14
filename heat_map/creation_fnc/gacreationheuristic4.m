function [ InitialPopulation ] = gacreationheuristic4( GenomeLength, ~, ...
    options, goal_img,  goal_mask, fuel_type,  n_bins,  color_space, ...
    heat_map, savePath )
%GACREATIONHEURISTIC4 Create a population for ga
%   [ INITIALPOPULATION ] = GACREATIONHEURISTIC4( GENOMELENGTH, FITNESSFCN,
%   OPTIONS, GOAL_IMG,  GOAL_MASK, FUEL_TYPE,  N_BINS, COLOR_SPACE,
%   HEAT_MAP)
%
%   [ INITIALPOPULATION ] = GACREATIONHEURISTIC4( GENOMELENGTH, FITNESSFCN,
%   OPTIONS, GOAL_IMG,  GOAL_MASK, FUEL_TYPE,  N_BINS,  COLOR_SPACE,
%   HEAT_MAP, SAVEPATH )
%

if nargin < 9
    error('Not enough input arguments.');
end

%% Generate the initial population with heuristic3
if nargin == 10
    InitialPopulation = gacreationheuristic3( GenomeLength, [], ...
        options, goal_img,  goal_mask, fuel_type,  n_bins,  color_space, ...
        savePath );
else
    InitialPopulation = gacreationheuristic3( GenomeLength, [], ...
        options, goal_img,  goal_mask, fuel_type,  n_bins,  color_space);
end

%% Check how many individuals heuristic3 created
totalPopulation = sum(options.PopulationSize);
initPopProvided = size(options.InitialPopulation, 1);
individualsToCreate = totalPopulation - initPopProvided;

% The lb and ub parameters are mapped here if the option is not overriden
% by the user
range = options.PopInitRange;

% At least one individual provided
if initPopProvided > 0
    % If not population is given, the ga initialization sets the
    % initial population as one individual, whose values are the the lower
    % bounds. If that is the case, ignore such individual
    if initPopProvided == 1 && isequal(options.InitialPopulation, range(1, :))
        individualsToCreate = totalPopulation;
        initPopProvided = 0;
    end
end

%% Sort the individuals that heuristic3 created
if(individualsToCreate > 0)
    % Sort the generated initial population and the initial temperature
    initPopOrd = sort(InitialPopulation(initPopProvided + 1:end, :),2);
    [~, initHmIdx] = sort(heat_map);
    
    % Make the generated initial population follow the same order as the
    % initial heat values
    InitialPopulation(initPopProvided + 1:end, :) = initPopOrd(:,initHmIdx);
    
    if nargin == 10
        save(savePath, 'InitialPopulation');
    end
    
end

end

