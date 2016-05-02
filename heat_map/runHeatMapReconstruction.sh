#!/bin/bash
if [ "$#" -lt 3 ]; then
        
    # If no arguments are given set number of Maya instances to number of 
    # cores divided by three
    NUM_MAYA=$(grep -c ^processor /proc/cpuinfo)

    # Add 1 to do rounding
    NUM_MAYA=$(((${NUM_MAYA} + 1) / 3))
		    
    if [ "$#" -lt 2 ]; then
    
        INIT_PORT="2222"
        
	    if [ "$#" -lt 1 ]; then
		    echo ""
		    echo "Not enough input arguments"
		    echo ""
		    echo "Usage: runHeatMapReconstruction.sh <input_data> <init_port> <maya_threads>"
		    echo ""
		    echo "	Where <input_data> is a .mat file generated with any of the"
		    echo "	heat_map/test/data/arg_test*.m functions"
		    echo ""
		    echo "	<init_port> is the port of the first maya instance, default is"
		    echo "	2222."
		    echo ""
		    echo "	<maya_threads> must be an positive integer which indicates how"
		    echo "	many Maya instances will launched for rendering"
		    echo "	Default value is: round(number of cores / 3)"
		    echo ""
		    exit 0 
	    fi
	else
		INIT_PORT=$2
	fi
else
	# Each Maya will listen to this port + (current Maya number - 1)
	INIT_PORT=$2
	NUM_MAYA=$3
fi

# Get the full path of the .mat file, also add '' for matlab syntax
DATA_FILE="'$(readlink -e "$1")'"

# Create random name for the log file to avoid clashes with other matlab logs
LOGFILE=`mktemp matlabXXXXXXXXXXXXXXXXXXXXX.log`
LOGFILE=`pwd`"/"$LOGFILE

# Get this script path
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Launch the Maya instances
"$CDIR/runMayaBatch.sh" "$INIT_PORT" "$NUM_MAYA"

if [ "$?" -ne 0 ]; then
	exit 2
fi

# Create a list of ports
PORTS=${INIT_PORT}

for i in `seq 2 $NUM_MAYA`;
do
	PORTS="$PORTS, $((${INIT_PORT} + $i - 1))"
done

PORTS="[${PORTS}]"

# Runs matlab in batch mode with low priority
nice -n20 matlab -nodesktop -nosplash -r "heatMapReconstruction($DATA_FILE, $PORTS, '$LOGFILE')" -logfile $LOGFILE

# Close all the Maya instances
"$CDIR/closeMayaBatch.sh" "$INIT_PORT" "$NUM_MAYA"

