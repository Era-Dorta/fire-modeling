Automatic heat map reconstruction
-----------

#### Dependencies
* [Matlab](http://mathworks.com/products/matlab) 2015
* [Ruby](http://www.ruby-lang.org/) 1.9.3
* Fire shader [dependencies](/README.md)

#### Compile and install
* Compile the files in [mex_fnc](heat_map/mex_fnc/) folder, it can be done with the provided [CmakeLists.txt](heat_map/mex_fnc/CmakeLists.txt) file or running the Matlab script [compileAll.m](heat_map/mex_fnc/compileAll.m).
Note that each Matlab version requires a specific compiler version, which might be solved by creating a ```mexopts.sh``` file in ```~/.matlab/<version>/```, see the following [link](https://gist.github.com/Garoe/890787ae6ec845a62db7) for an example for Matlab 2015.

#### Usage
Matlab code that estimates a heat map given a goal image.
Execute [runHeatMapReconstruction.sh <method>](heat_map/runHeatMapReconstruction.sh) to start the computation.
The goal image and other parameters can be set in the [heatMapReconstruction.m](heat_map/heatMapReconstruction.m) function.
For solver specific parameters see the files in the [solvers](heat_map/solvers) folder.
Execute [runExploreErrorFun.sh](heat_map/runExploreErrorFun.sh) to generate visualizations of the parameter space in a PCA reduced 2 dimensional representation.  
