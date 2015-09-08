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

Render -r mr -v 5 -cam camera1 -perframe -autoRenderThreads -s 1 -e 1  -fnc 3 -pad 3 -rd ~/maya/projects/fire/images -im $SceneName -of tif $fullName
