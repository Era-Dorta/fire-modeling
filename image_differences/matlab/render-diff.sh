#!/bin/bash
# Based on render.sh script
if [ "$#" -le 8 ]; then
	echo ""
	echo "Missing file to render"
	echo ""
	echo "Usage: render <path_to_file.ma> <folderNumber> <fileNumber> <densityScale> <densityOffset> <temperatureScale> <temperatureOffset> <intensity> <transparency>"
	echo ""
	exit 0 
fi

fullName=$(readlink -f "$1") # Get the absolute path, relative ones would save the images in the default project
fileName=$(basename "$fullName") # Get the name of the file
SceneName="${fileName%.*}"  # Take the extension out
projectPath=$(dirname $(dirname "${fullName}")) # Get the project folder path
outputImPath="$projectPath/images"
outputMoviePath="$projectPath/movies"
extension="tif"
logfile="$outputImPath/$SceneName/$2/$SceneName$3.log"

if [ ! -d "$outputImPath/$SceneName" ]; then
	mkdir "$outputImPath/$SceneName"
fi

# Delete the log file if it exits
if [ -f "$logfile" ]; then
	rm "$logfile"
fi

touch "$logfile"

Render -r mr -v 5 -preRender "setAllFireAttributes(\"fire_volume_shader\", $4, $5, $6, $7, $8, $9);" -proj "$projectPath" -cam camera1 -perframe -autoRenderThreads -rd "$outputImPath/$SceneName/$2" -im "$SceneName$3" -of $extension -log "$logfile" "$fullName"
