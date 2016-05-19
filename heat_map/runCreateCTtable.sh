#!/bin/bash
if [ "$#" -gt 0 ]; then
	echo ""
	echo "Too many input arguments"
	echo ""
	echo "Usage: runCreateCTtable.sh"
	echo ""
	exit 2
fi

# Maya will listen to this port
PORT="2222"

# Create random name for the log file to avoid clashes with other matlab logs
LOGFILE=`mktemp matlabXXXXXXXXXXXXXXXXXXXXX.log`
LOGFILE=`pwd`"/"$LOGFILE

# Get this script path
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Launch the Maya instance
"$CDIR/runMayaBatch.sh" "$PORT" "1" "1"

if [ "$?" -ne 0 ]; then
	exit 2
fi

# Runs matlab in batch mode with low priority
nice -n20 matlab -nodesktop -nosplash -r "createCTtable($PORT, '$LOGFILE')" -logfile $LOGFILE

# Close all the Maya instances
"$CDIR/closeMayaBatch.sh" "$PORT" "$NUM_MAYA"

