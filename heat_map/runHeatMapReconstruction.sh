#!/bin/bash
if [ "$#" -lt 2 ]; then
	if [ "$#" -eq 1 ]; then
		# If no arguments are given set number of Maya instances to number of 
		# cores divided by three
		NUM_MAYA=$(grep -c ^processor /proc/cpuinfo)
		
		# Add 1 to do rounding
		NUM_MAYA=$(((${NUM_MAYA} + 1) / 3))
	else
		echo ""
		echo "Not enough input arguments"
		echo ""
		echo "Usage: runHeatMapReconstruction.sh <solver> <maya_threads>"
		echo ""
		echo "	Where <solver> can be any of [\"ga\", \"sa\", \"ga-re\", \"grad\" ]"
		echo "	\"ga\"    -> Genetic Algorithm"
		echo "	\"sa\"    -> Simulated Annealing"
		echo "	\"ga-re\" -> Genetic Algorithm with heat map resampling"
		echo "	\"grad\"  -> Gradient Descent"
		echo ""
		echo "	<maya_threads> must be an positive integer which indicates how many"
		echo "	Maya instances will be rendering"
		echo "	Default value is: round(number of cores / 3)"
		echo ""
		exit 0 
	fi
else
	NUM_MAYA=$2
fi

# Each Maya will listen to this port + (current Maya number - 1)
INIT_PORT="2222"

# Create random name for the log file to avoid clashes with other matlab logs
LOGFILE=`mktemp matlabXXXXXXXXXXXXXXXXXXXXX.log`
LOGFILE=`pwd`"/"$LOGFILE

# Get this script path
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Launch the first Maya instance
nice -n20 "$CDIR/runMayaBatch.sh" "$INIT_PORT" > /dev/null

if [ "$?" -ne 0 ]; then
	echo "Could not launch Maya:${INIT_PORT}"
	exit 2
fi

echo "Launched Maya:${INIT_PORT}"
# Add the port to the list of ports
PORTS=${INIT_PORT}

# Launch the rest of the Maya instances
for i in `seq 2 $NUM_MAYA`;
do
	nice -n20 "$CDIR/runMayaBatch.sh" $((${INIT_PORT} + $i - 1)) > /dev/null

	if [ "$?" -ne 0 ]; then
		# Close all the previous Maya instances
		for j in `seq 1 $(($i - 1))`;
		do
			"$CDIR/maya_comm/sendMaya.rb" $((${INIT_PORT} + $j - 1)) "quit -f"
			if [ "$?" -ne 0 ]; then
				echo "Could not close Maya:$((${INIT_PORT} + $j - 1))"
			else
				echo "Closed Maya:$((${INIT_PORT} + $j - 1))"
			fi
		done
	
		echo "Could not launch Maya:$((${INIT_PORT} + $i - 1))"
		exit 2
	fi
	
	echo "Launched Maya:$((${INIT_PORT} + $i - 1))"
	PORTS="$PORTS, $((${INIT_PORT} + $i - 1))"
done

PORTS="[${PORTS}]"

# Runs matlab in batch mode with low priority
nice -n20 matlab -nodesktop -nosplash -r "heatMapReconstruction('$1', $PORTS, '$LOGFILE')" -logfile $LOGFILE

# Close all the Maya instances
for i in `seq 1 $NUM_MAYA`;
do
	"$CDIR/maya_comm/sendMaya.rb" $((${INIT_PORT} + $i - 1)) "quit -f"
	if [ "$?" -ne 0 ]; then
		echo "Could not close Maya:$((${INIT_PORT} + $i - 1))"
	else
		echo "Closed Maya:$((${INIT_PORT} + $i - 1))"
	fi
done

