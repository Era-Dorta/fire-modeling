Fire Shader for Mental Ray in Maya
-----------
#### Dependencies
* [CMake](http://www.cmake.org/) 2.8.12
* [Boost](http://www.boost.org/) 1.54
* [zlib](http://www.zlib.net/) 1.2.8
* [OpenEXR](http://www.openexr.com/) 1.6
* [Intel Threading Building Blocks](https://www.threadingbuildingblocks.org/) 4.2
* [OpenVDB](http://www.openvdb.org/) 2.1
* [Maya DevKit](https://apps.exchange.autodesk.com/en) needed for Maya 2016 and above, download "Maya Developer Kit"
* [MentalRay DevKit](http://knowledge.autodesk.com/support/maya/downloads/caas/downloads/content/mental-ray-plugin-for-maya-2016.html) 2015
* For Ubuntu, all the dependencies can be installed with 
  * `sudo apt-get install cmake libboost-all-dev zlib1g-dev libopenexr-dev libtbb-dev libopenvdb-dev`
  * [This script](https://gist.github.com/Garoe/859324436d1273aa56ff) can be used to install Maya 2015 with Mental Ray . 

#### Compile and install
* Create build folder and the run the following commands in it
* ```cmake -DMAYA_VERSION=<Year version, e.g. 2015> ../```
* ```make```
* ```make install```

#### Using the shaders
* Select Render Settings -> Render Using -> Mental Ray
* Run ```createFireVolume("/path-to-temperature-file.raw", "/path-to-density-file.raw");```
  * Both paths should be for the first file in a data sequence
  * The file name format requires the frame number to be located in the end of the name, e.g. ```my-file-001.raw```
  * Batch rendering is not supported with the GUI, the input files will not update; instead render from the command line with the ```Render``` command with the ```-perframe``` flag.
* The shader will automatically advance to new data files when the playback frame changes in Maya
* All the parameters that affect the result of the shading network can be modified from the ```fire_volume_shader``` attribute editor
  * On each execution the shader will output the upper limit for ```High Samples``` for the current data in the Mental Ray log.
* New instances can be created with the command ```instance -smartTransform;```

#### Known issues
* **Wrong data file paths**: data file paths are automatically set only when the file dialog is used. If the attributes are set via mel commands or copying and pasting, the hidden attributes `density_file_first` and `temperature_file_first` must be set to the data relative paths. Then `density_file` and `temperature_file` can be updated by either calling the mel script `fireFrameUpdate(<fire_volume_shader>)`, going manually to a new frame or with the `setAttr` command where the new path is the full path to the data file.
* **Flame does not appear on saved images**: go the cameraShape, Environment section, Image Plane -> Create, on the image plane change the Type to Texture and in Texture attach a lambert node with your preferred background colour.
* **Tooltip clarification**: the help values indicated in scale attributes of the shader refer to the mean of the data after they are applied, e.g. if the mean of your temperature voxel data is 10 units then the scale should be around 200 so that the final temperatures are around 2000K. Note that the mean, max and other values are outputted in the Mental Ray log when the verbosity is set to 5 (info messages).
* **Maya .mb scenes**: the scenes which use the shader must be saved in the `.ma` ascii format
* **Sequence does not update on batch rendering**: due to internal animation optimizations Mental Ray does not call the update script during batch rendering, the workaround is to batch render in the console with `Render -r mr -perframe -s <start_frame_number> -e <end_frame_number> <path_to_scene_file>`

#### Extra information
For a detailed description of the models and equations used in the fire shader, as well as engineering decisions and preliminary results please consult the pdfs in the report and presentation folders.
