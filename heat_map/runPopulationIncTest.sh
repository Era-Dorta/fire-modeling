#!/bin/bash

# Get this script path
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Tests 8 is GA, using heat_map_fitness, 200 in Population, 25 Generations
# single goal image, and using chi_square_statistics_fast

# Create the data files
nice -n20 matlab -nodesktop -nosplash -r "args_test8(); exit();"

POP_SIZES=(100 200 400 800 1600 3200)

for i in ${POP_SIZES[@]}; do
	nice -n20 matlab -nodesktop -nosplash -r "solver_path = '~/bath-fire-shader/heat_map/test/data/args_test8solver.mat'; L = load(solver_path); options = L.options; options.PopulationSize = ${i}; save(solver_path, 'options', '-append'); exit();"
	#Optimize using the parameters defined in the previous data files
	"$CDIR/runHeatMapReconstruction.sh" ~/bath-fire-shader/heat_map/test/data/args_test8.mat
done

