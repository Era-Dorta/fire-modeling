#!/bin/bash
# Close Maya in batch mode on the given port
# Optional one argument with port number, if not given port 2222 will be used
# Optional second argument number of Maya instances to close
function isPortOpen()
{
	nc -z localhost "$1"
	return $?
}

function waitClose()
{
	isPortOpen "$1"
	isOpen=$?
	while [ "$isOpen" -eq 0 ]; do
		sleep 0.1
		isPortOpen "$1"
		isOpen=$?
	done
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
    CLOSE_PORT=$((${PORT} + $i - 1))
    
    "$CDIR/maya_comm/sendMaya.rb" $CLOSE_PORT "quit -f" &>/dev/null
    
    if [ "$?" -ne 0 ]; then
	    echo "Could not close Maya:${CLOSE_PORT}"
    else
    	# Wait for the port to be closed
    	waitClose $CLOSE_PORT
    	
	    echo "Closed Maya:${CLOSE_PORT}"
    fi
done

