#!/bin/bash
# Runs Maya in batch mode, Maya waits for command to be send on the given port
# Optional one argument with port number, if not given port 2222 will be used
function isPortOpen()
{
	nc -z localhost "$1"
	return $?
}

function runSingleMaya()
{
	local PORT=$1

	isPortOpen "$PORT"

	# If it fails, tell the user to use a different port
	if [ "$?" -eq 0 ] ; then
		return 0
	fi

	# Run with setsid to protect Maya from the parent ctrl-c, allows Maya to be 
	# closed gracefully
	setsid nice -n20 maya -batch -command "commandPort -n \":$PORT\";" &> /dev/null &

	# sendToMaya command will wait for Maya to open and be ready, but weird
	# errors sometime happen, so give Maya some extra time before even
	# trying to open the port
	sleep 1

	return 1
}

function runSingleMayaLog()
{
	local PORT=$1

	isPortOpen "$PORT"

	# If it fails, tell the user to use a different port
	if [ "$?" -eq 0 ] ; then
		return 0
	fi

	local LOGNAME="mayaLog-${PORT}.log"	
	> "${LOGNAME}" # Create/Truncate the file

	# Redirect with >> so the file can be truncated by each Matlab run
	setsid nice -n20 maya -batch -command "commandPort -n \":$PORT\";" &>> "${LOGNAME}" &

	# sendToMaya command will wait for Maya to open and be ready, but weird
	# errors sometime happen, so give Maya some extra time before even
	# trying to open the port
	sleep 1

	return 1
}

PORT=2222
NUM_MAYA=1
USE_LOG=0

# Get this script path
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$#" -ge 1 ]; then
	PORT=$1
	if [ "$#" -ge 2 ]; then
		NUM_MAYA=$2
		if [ "$#" -ge 3 ]; then
			USE_LOG=$3
		fi
	fi
fi

for i in `seq 1 $NUM_MAYA`;
do
	NEW_PORT=$((${PORT} + $i - 1))

	if [ ${USE_LOG} -eq 0 ]; then
		runSingleMaya $NEW_PORT
	else
		runSingleMayaLog $NEW_PORT
	fi

	if [ "$?" -eq 1 ]; then
		echo "Launched Maya:${NEW_PORT}"
	else
		echo "Could not launch Maya:${NEW_PORT}"

		# Close all the previous Maya instances	
		if [ "$i" -gt 1 ]; then
			"$CDIR/closeMayaBatch.sh" "$PORT" "$(($i - 1))"
		fi

		exit 2
	fi
done

