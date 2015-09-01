#!/bin/sh
#Render -rd ~/maya/projects/fire/images -im outputim -of jpg ~/maya/projects/fire/scenes/test5_mental_ray_volumetric.ma
# Flag to show mental ray info messages -mr:v 4 
# -r renderer, -v verbosity, -s start_frame, -e end_frame, -fnc output_name_format, -pad padding_of_frame_num, -im output_name, -of output_extension
# The -perframe options needs to be added or mental ray will not update the filenames on each frame in batch render
Render -r mr -v 4 -cam camera1 -perframe -s 1 -e 1  -fnc 7 -pad 3 -rd ~/maya/projects/fire/images -im outputim -of tga ~/maya/projects/fire/scenes/test34*.ma
