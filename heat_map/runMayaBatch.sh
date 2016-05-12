#!/bin/bash
# Runs Maya in batch mode, Maya waits for command to be send on the given port
# Optional one argument with port number, if not given port 2222 will be used
function isPortOpen()
{
	return $( nc -z localhost "$1" )
}

function runSingleMaya()
{
    local PORT=$1

    isPortOpen "$PORT"

    # If it fails, tell the user to use a different port
    if [ "$?" -eq 0 ] ; then
	    return 0
    fi

    nice -n20 maya -batch -command "commandPort -n \":$PORT\";" &> /dev/null &
    
    # sendToMaya command will wait for Maya to open and be ready, but weird
    # errors sometime happen, so give Maya some extra time before even
    # trying to open the port
    sleep 1
    
    return 1
}

PORT=2222
NUM_MAYA=1

# Get this script path
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$#" -ge 1 ]; then
	PORT=$1
	if [ "$#" -ge 2 ]; then
	    NUM_MAYA=$2
    fi
fi

for i in `seq 1 $NUM_MAYA`;
do
    NEW_PORT=$((${PORT} + $i - 1))
    runSingleMaya $NEW_PORT

    if [ "$?" -eq 1 ]; then
        echo "Launched Maya:${NEW_PORT}"
	else
	     # Close all the previous Maya instances
		for j in `seq 1 $(($i - 1))`;
		do
		    CLOSE_PORT=$((${PORT} + $j - 1))
			"$CDIR/maya_comm/sendMaya.rb" $CLOSE_PORT "quit -f"
			if [ "$?" -ne 0 ]; then
				echo "Could not close Maya:${CLOSE_PORT}"
			else
				echo "Closed Maya:${CLOSE_PORT}"
			fi
		done
	
		echo "Could not launch Maya:${NEW_PORT}"
		exit 2
    fi
done

