function [ InitialPopulation ] = gacreationfrominitguess( GenomeLength, ~, ...
    options, c_heat_map, mean, sigma, savePath )
%GACREATIONFROMINITGUESS Create a population for ga
%

if nargin < 6
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

% Randomly perturb the initial guess with normal noise
if(individualsToCreate > 0)
    InitialPopulation(initPopProvided + 1:end, :) = ...
        bsxfun(@plus, c_heat_map.v', random('norm', mean, sigma, ...
        [individualsToCreate, GenomeLength]));
end

% Clamp to lower and upper bounds
InitialPopulation = bsxfun(@max, InitialPopulation, options.LinearConstr.lb');
InitialPopulation = bsxfun(@min, InitialPopulation, options.LinearConstr.ub');

if nargin == 7
    save(savePath, 'InitialPopulation');
end

end

