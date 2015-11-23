function [ InitialPopulation ] = gacreationupsample( GenomeLength, FitnessFcn, ...
    options, scores, prev_population, prev_heat_map, c_heat_map, savePath )
% Create a population from upsampling the result of the previous iteration

% Get a sorted index of the scores, ascending order as this are the
% result of the fitness function
[~, bestInd] = sort(scores);

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
    % If not population is given the algorithm initialization sets the
    % initial population as one individual whose values are the the lower
    % bounds, if that is the case just ignore it as we are going to
    % recreate it later
    if initPopProvided == 1 && isequal(options.InitialPopulation, range(1, :))
        individualsToCreate = totalPopulation;
        initPopProvided = 0;
    else
        InitialPopulation(1:initPopProvided,:) = options.InitialPopulation;
    end
end

% TODO Assuming that the previous population is always equal or
% bigger than the current needed population

for j=1:individualsToCreate
    % Construct a temporary heat map with the individual
    temp_heat_map = struct('xyz', prev_heat_map.xyz, 'v',  ...
        prev_population(bestInd(j),:)', 'count', prev_heat_map.count, ...
        'size', prev_heat_map.size);
    
    % Up sample the data taking only the values indicated by d_heat_map{i}.xyz
    temp_heat_map = resampleHeatMap(temp_heat_map, 'up', c_heat_map.xyz);
    
    % Set the new individual for the next iteration
    InitialPopulation(initPopProvided + j, :) = temp_heat_map.v';
end

if nargin == 4
    save(savePath, 'InitialPopulation');
end

end

