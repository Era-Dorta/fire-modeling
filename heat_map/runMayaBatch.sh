#!/bin/bash
# Runs Maya in batch mode, Maya waits for command to be send on the given port
function isPortOpen()
{
	lofret=$( lsof -i:"$1" )
	if [ "$lofret" = "" ] ; then
		return 1
	else
		return 0
	fi
}

PORT=2222

if [ "$#" -eq 1 ]; then
	PORT=$1
fi

isPortOpen "$PORT"
isOpen=$?

# If it fails, tell the user to use a different port
while [ "$isOpen" -eq 0 ] ; do
	echo "Port $PORT already in use, try runMayaBath <newPort>"
	exit -1
done

oriMaya -batch -command "commandPort -n \":$PORT\";" &
