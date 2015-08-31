Fire Shader for Mental Ray in Maya
-----------
#### Dependencies
* [CMake](http://www.cmake.org/)
* [Boost](www.boost.org)
* [libz](zlib.net)
* [OpenEXR](www.openexr.com)
* [Intel Threading Building Blocks](threadingbuildingblocks.org)
* [OpenVDB](http://www.openvdb.org/)
* [Maya DevKit](https://apps.exchange.autodesk.com/en) Search for "Maya Developer Kit"
* [MentalRay DevKit](http://knowledge.autodesk.com/support/maya/downloads/caas/downloads/content/mental-ray-plugin-for-maya-2016.html)
* For Ubuntu, all the dependencies but Maya and MentalRay can be installed with <br /> `sudo apt-get install cmake libboost-all-dev zlib1g-dev libopenexr-dev libtbb-dev libopenvdb-dev`

#### Compile and install
* Create build folder and the run the following commands in it
* ```cmake ../```
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
  * The only exception are the number of samples per ray, which are located under the mental ray section in the area light shape, ```High Samples, High Sample Limit, Low Samples```; on each execution the shader will output the upper limit for ```High Samples``` for the current data in the mental ray console.
* New instances can be created with the command ```instance -smartTransform;```
