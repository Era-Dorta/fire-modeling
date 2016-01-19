#!/bin/bash
if [ "$#" -le 1 ]; then
	echo ""
	echo "Not enough input arguments"
	echo ""
	echo "Usage: runCreateHeatMapTrainTestSet.sh <size> <save_mat_file>"
	echo ""
	echo "	Where <size> is an integer that indicates the number of train"
	echo "	samples to generate, and <save_mat_files> is a boolean that when"
	echo "	active causes the function to also save a data.mat file with the"
	echo "	image and the heat map values for each sample."
	echo ""
	exit 0 
fi

# Create random name for the log file to avoid clashes with other matlab logs
LOGFILE=`mktemp matlabXXXXXXXXXXXXXXXXXXXXX.log`
LOGFILE=`pwd`"/"$LOGFILE

# Runs matlab in batch mode with low priority
nice -n20 matlab -nodesktop -nosplash -r "createHeatMapTrainTestSet($1, $2, '$LOGFILE')" -logfile $LOGFILE
