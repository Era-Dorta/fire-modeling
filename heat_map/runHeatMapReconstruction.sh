#!/bin/bash
if [ "$#" -le 0 ]; then
	echo ""
	echo "Missing solver type"
	echo ""
	echo "Usage: runHeatMapReconstruction.sh <solver>"
	echo ""
	echo "	Where <solver> can be any of [\"ga\", \"sa\"]"
	echo "	\"ga\" -> Genetic Algorithm"
	echo "	\"sa\" -> Simulated Annealing"
	echo ""
	exit 0 
fi
# Runs matlab in batch mode
matlab -nodesktop -nosplash -r "heatMapSearch('$1')" -logfile matlab.log
