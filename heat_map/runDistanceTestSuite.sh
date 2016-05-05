#!/bin/bash

# Get this script path
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Tests 6,67,8 are GA, using heat_map_fitness, 200 in Population, 25 Generations
# single goal image, and using histogram_l1_norm, histogram_intersection,
# chi_square_statistics_fast, jensen_shannon_divergence, respectively

# Create the data files
nice -n20 matlab -nodesktop -nosplash -r "args_test6(); args_test7(); args_test8(); args_test9(); exit();"

# Optimize using the parameters defined in the previous data files
"$CDIR/runHeatMapReconstruction.sh" ~/bath-fire-shader/heat_map/test/data/args_test6.mat
"$CDIR/runHeatMapReconstruction.sh" ~/bath-fire-shader/heat_map/test/data/args_test7.mat
"$CDIR/runHeatMapReconstruction.sh" ~/bath-fire-shader/heat_map/test/data/args_test8.mat
"$CDIR/runHeatMapReconstruction.sh" ~/bath-fire-shader/heat_map/test/data/args_test9.mat
