Automatic rendering parameter estimation
-----------

#### Dependencies
* [Matlab](http://mathworks.com/products/matlab) 2015
* Fire shader [dependencies](README.md)

#### Usage
Matlab code that estimates density scale and offset, temperature scale and offset, intensity and opacity parameters given a goal image.
Place the Maya [script](image_differences/maya/setAllFireAttributes.mel) in your  script folder for Maya and execute [run_matlab.sh](image_differences/run_matlab.sh). 
The goal image, scene file and other parameters can be set in the script [fire_attr_search](image_differences/matlab/fire_attr_search.m)
The result will be saved in a file ```best_attr.mat``` and a summary with relevant information will be written in a ```summary_file.txt```.
