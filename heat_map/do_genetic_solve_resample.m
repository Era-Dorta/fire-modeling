function [ heat_map_v, best_error, exitflag] = do_genetic_solve_resample( ...
    max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, paths_str)
% Genetics Algorithm solver for heat map reconstruction with heat map
% resampling scheme for faster convergence

[summarydir, summaryname, summaryext] = fileparts(paths_str.summary);

paths_str.summary = [summarydir summaryname];

%% Options for the ga
% Get default values
options = gaoptimset(@ga);
options.PopulationSize = 50;
options.Generations = max(fix(max_ite / options.PopulationSize), 1);
options.TimeLimit = time_limit;
options.EliteCount = 1;
options.Display = 'iter'; % Give some output on each iteration
options.MutationFcn = @mutationadaptfeasible;

A = [];
b = [];
Aeq = [];
beq = [];
nonlcon = [];

%% Down sample the heat map
d_heat_map{1} = init_heat_map;
num_ite = 1;
while max(d_heat_map{end}.size) > 32
    d_heat_map{end + 1} = resampleHeatMap(d_heat_map{end}, 'down');
    num_ite = num_ite + 1;
end

%% Main optimization loop
for i=1:num_ite
    %% Iteration dependant GA parameters
    % Upper and lower bounds
    LB1 = ones(d_heat_map{i}.count, 1) * LB;
    UB1 = ones(d_heat_map{i}.count, 1) * UB;
    
    % Function executed on each iteration, there is a PlotFcns too, but it
    % creates a figure outside of our control and it makes the plotting and
    % saving too dificult
    plotf = @(options,state,flag)gaplotbestcustom(options, state, flag, ...
        [paths_str.errorfig num2str(i)]);
    options.OutputFcns = plotf;
    
    %% Generate initial population
    if i == 1
        % Rows are number of individuals, and columns are the dimensions
        options.InitialPopulation = getRandomInitPopulation( LB1', UB1', options.PopulationSize );
    else
        % Create from upsampling the result of the previous iteration
        options.InitialPopulation = [];
        for j=1:size(population, 2)
            % Construct a temporary heat map with the individual
            temp_heat_map = struct('xyz', d_heat_map{i - 1}.xyz, 'v', population(:, j)', ...
                'count', d_heat_map{i - 1}.count, 'size', d_heat_map{i - 1}.size);
            
            % Up sample the data taking only the values indicated by d_heat_map{i}.xyz
            temp_heat_map = resampleHeatMap(temp_heat_map, 'up', d_heat_map{i}.xyz);
            
            % Set the new individual for the next iteration
            options.InitialPopulation(j, :) = temp_heat_map.v;
        end
    end
    
    %% Call the genetic algorithm optimization for the first
    startTime = tic;
    
    [heat_map_v, best_error, exitflag, ~, population] = ga(fitness_foo, ...
        d_heat_map{i}.count, A, b, Aeq, beq, LB1, UB1, nonlcon, options);
    
    totalTime = toc(startTime);
    disp(['Optimization total time ' num2str(totalTime)]);
    
    %% Save summary file
    save_summary_file([paths_str.summary num2str(i) summaryext],  ...
        'Genetic Algorithms Resample', best_error, heat_map_size, options, ...
        LB1(1), UB1(1), totalTime);
end

end

