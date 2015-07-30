Installation
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
* For Ubuntu, all the dependencies but Maya and MentalRay can be installed with `sudo apt-get install cmake libboost-all-dev zlib1g-dev libopenexr-dev libtbb-dev libopenvdb-dev`

#### Mental Ray Shaders
* Create build folder
* cmake -DCMAKE_INSTALL_PREFIX="/path-to-shaders-installation-folder" ../
* make
* make install

#### Maya commands
* Copy createFireVolume.mel file into the scripts folder in your maya project

Running
-----------
* Select Render Settings -> Render Using -> Mental Ray
* Run createFireVolume("/path-to-temperature-file.raw", "/path-to-density-file.raw");
* Additionally create new instances with ```instance -smartTransform;```

Running (Deprecated)
-----------
* Create -> Volume primitive -> Cube
* Open Hypershader 
* Select Mental ray -> Volumetric Materials
* Create Fire Volume Shader
* Select Mental ray -> MentalRAy Lights
* Create Fire Volume Light
* Select Mental ray -> Miscellaneous
* Create two Voxel Density nodes 
* Select cubeFog material
* Show input/output conections
* Select cubeFogSG
* With middle mouse hold, drag and drop the Fire Volume Shader Node into Volume material
* Select the Fire Volume Shader node
* Select the Utilities tab
* With middle mouse hold, drag and drop one of the voxel density nodes into density shader
* Select the voxel density node, choose a input filename and a read mode
* Create -> lights -> area light
* In areaLightShape -> mental ray
* Tick Use Light Shape or setAttr "areaLightShape1.areaLight" 1;
* On type select Custom or setAttr "areaLightShape1.areaType" 4;
* Scroll down to Custom Shaders
* Add this shader as Light Shader or connectAttr -f fire_volume_light1.message pointLightShape1.miLightShader;
* Select the fire volume light
* With middle mouse hold, drag and drop one of the other voxel density nodes into temperature shader
* Select the voxel density node, choose a input filename and a read mode

### Extra (Deprecated)

* An easy way to move everything together is to set the cube as parent of the light, 
select the cube, then sift select the light then execute "parent -s -r;", which is 
equivalent to "select -r areaLight1 box1 ;" "parent -s -r;"

* Additionally, lock all transformations in the light shape
 setAttr -l true { "areaLight1.t" };
 setAttr -l true { "areaLight1.r" };
 setAttr -l true { "areaLight1.s" };
 setAttr -l true { "areaLight1.sh" };
