function [ InitialPopulation ] = gacreationlinspace( GenomeLength, ~, ...
    options, savePath )
% Generates a new population of linearly spaced individuals where each of
% them has the same value for all dimensions

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

myfoo = @(lb, ub)linspace(lb, ub, individualsToCreate)';

% Fill the population matrix with linearly spaced individuals
InitialPopulation(initPopProvided + 1:end, :) = cell2mat(arrayfun(myfoo, ...
    range(1, :), range(2,:), 'Uniform', false));

if nargin == 4
    save(savePath, 'InitialPopulation');
end
end

