#!/bin/sh
#Render -rd ~/maya/projects/fire/images -im outputim -of jpg ~/maya/projects/fire/scenes/test5_mental_ray_volumetric.ma
# Flag to show mental ray info messages -mr:v 4 
Render -mr:v 4 -cam camera1 -rd ~/maya/projects/fire/images -im outputim -of jpg ~/maya/projects/fire/scenes/test35*.ma
