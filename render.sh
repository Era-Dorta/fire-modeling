#!/bin/sh
#Render -rd ~/maya/projects/fire/images -im outputim -of jpg ~/maya/projects/fire/scenes/test5_mental_ray_volumetric.ma
# Flag to show mental ray info messages -mr:v 4 
# -r renderer, -v verbosity, -s start_frame, -e end_frame, -fnc output_name_format, -pad padding_of_frame_num, -im output_name, -of output_extension
# autoRenderThreads automatically get optimal number of threads
# The -perframe options needs to be added or mental ray will not update the filenames on each frame in batch render
if [ "$#" -le 0 ]; then
	echo ""
	echo "Missing file to render"
	echo ""
	echo "Usage: render <path_to_file.ma>"
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

Render -r mr -v 5 -proj "$projectPath" -cam camera1 -perframe -autoRenderThreads -s 1 -e 1  -fnc 3 -pad 3 -rd "$outputImPath/$SceneName" -im "$SceneName" -of $extension -log "$outputImPath/$SceneName/$SceneName.log" "$fullName"

# -r is the frame rate
ffmpeg -r 4 -i "$outputImPath/$SceneName/$SceneName.%03d.$extension" "$outputMoviePath/$SceneName.avi"


