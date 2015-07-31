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
* Additionally create new instances with ```instance -smartTransform;```
