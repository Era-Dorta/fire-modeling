#!/bin/sh
#Render -rd /home/gdp24/maya/projects/fire/images -im outputim -of jpg /home/gdp24/maya/projects/fire/scenes/test5_mental_ray_volumetric.ma
# Flag to show mental ray info messages -mr:v 4 
Render -mr:v 4 -rd /home/gdp24/maya/projects/fire/images -im outputim -of jpg /home/gdp24/maya/projects/fire/scenes/test28*.ma
