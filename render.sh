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

fullName=$1
fileName=$(basename "$fullName")
SceneName="${fileName%.*}"
projectPath=~/maya/projects/fire/images
extension="tif"

if [ ! -d "$projectPath/$SceneName" ]; then
	mkdir "$projectPath/$SceneName"
fi

# Delete the log file if it exits
if [ -f "$projectPath/$SceneName/$SceneName.log" ]; then
	rm "$projectPath/$SceneName/$SceneName.log"
fi

touch "$projectPath/$SceneName/$SceneName.log"

Render -r mr -v 5 -cam camera1 -perframe -autoRenderThreads -s 1 -e 1  -fnc 3 -pad 3 -rd "$projectPath/$SceneName" -im "$SceneName" -of $extension -log "$projectPath/$SceneName/$SceneName.log" "$fullName"

avconv -framerate 2 -i "$projectPath/$SceneName/$SceneName.%03d.$extension" -c:v h264 -crf 1 "$SceneName.mp4"

