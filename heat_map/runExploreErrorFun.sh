#!/bin/bash
# Create random name for the log file to avoid clashes with other matlab logs
LOGFILE=`mktemp matlabXXXXXXXXXXXXXXXXXXXXX.log`
LOGFILE=`pwd`"/"$LOGFILE

# Runs matlab in batch mode with low priority
nice -n10 matlab -nodesktop -nosplash -r "exploreErrorFun('$LOGFILE')" -logfile $LOGFILE
