#!/bin/bash
if [ "$#" -le 0 ]; then
	echo ""
	echo "Missing solver type"
	echo ""
	echo "Usage: runHeatMapReconstruction.sh <solver>"
	echo ""
	echo "	Where <solver> can be any of [\"ga\", \"sa\", \"ga-re\", \"grad\" ]"
	echo "	\"ga\"    -> Genetic Algorithm"
	echo "	\"sa\"    -> Simulated Annealing"
	echo "	\"ga-re\" -> Genetic Algorithm with heat map resampling"
	echo "	\"grad\"  -> Gradient Descent"
	echo ""
	exit 0 
fi

# Create random name for the log file to avoid clashes with other matlab logs
LOGFILE=`mktemp matlabXXXXXXXXXXXXXXXXXXXXX.log`
LOGFILE=`pwd`"/"$LOGFILE

# Runs matlab in batch mode with low priority
nice -n20 matlab -nodesktop -nosplash -r "heatMapReconstruction('$1', '$LOGFILE')" -logfile $LOGFILE
