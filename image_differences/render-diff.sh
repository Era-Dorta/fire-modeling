#!/bin/sh
# Based on render.sh script
if [ "$#" -le 7 ]; then
	echo ""
	echo "Missing file to render"
	echo ""
	echo "Usage: render <path_to_file.ma> <ouputnumber> <densityScale> <densityOffset> <temperatureScale> <temperatureOffset> <intensity> <transparency>"
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

if [ ! -d "$outputImPath/$SceneName" ]; then
	mkdir "$outputImPath/$SceneName"
fi

# Delete the log file if it exits
if [ -f "$outputImPath/$SceneName/$SceneName.log" ]; then
	rm "$outputImPath/$SceneName/$SceneName.log"
fi

touch "$outputImPath/$SceneName/$SceneName.log"

Render -r mr -v 5 -preRender "setAllFireAttributes(\"fire_volume_shader\", $3, $4, $5, $6, $7, $8);" -proj "$projectPath" -cam camera1 -perframe -autoRenderThreads -rd "$outputImPath/$SceneName" -im "$SceneName""$2" -of $extension -log "$outputImPath/$SceneName/$SceneName""$2"".log" "$fullName"

