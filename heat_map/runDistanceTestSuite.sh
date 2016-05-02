#!/bin/bash

# Get this script path
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Tests 6,67,8 are GA, using heat_map_fitness, 200 in Population, 25 Generations
# single goal image, and using histogram_sum_abs, histogram_intersection,
# chi_square_statistics_fast, respectively
"$CDIR/runHeatMapReconstruction.sh" ~/bath-fire-shader/heat_map/test/data/args_test6.mat
"$CDIR/runHeatMapReconstruction.sh" ~/bath-fire-shader/heat_map/test/data/args_test7.mat
"$CDIR/runHeatMapReconstruction.sh" ~/bath-fire-shader/heat_map/test/data/args_test8.mat
