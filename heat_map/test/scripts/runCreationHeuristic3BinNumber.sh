#!/bin/bash

# Get this script path
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Go up two folders, scripts and test
CDIR="$(dirname $(dirname "$CDIR"))"

# Create the data files
nice -n20 matlab -nodesktop -nosplash -r "args_test21(); exit();"

BIN_SIZES=(10 50 100 256)

for i in ${BIN_SIZES[@]}; do
	"args_path = '~/bath-fire-shader/heat_map/test/data/args_test21.mat'; creation_fnc_n_bins = ${i}; save(args_path, 'creation_fnc_n_bins', '-append'); exit();"
	
	#Optimize using the parameters defined in the previous data files
	"$CDIR/runHeatMapReconstruction.sh" ~/bath-fire-shader/heat_map/test/data/args_test21.mat
done

