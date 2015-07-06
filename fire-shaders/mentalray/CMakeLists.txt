#g++ -I/usr/autodesk/mentalrayForMaya2015/devkit/include -O3 -pedantic -Wall 
#-Wextra -c -fmessage-length=0 -D_REENTRANT -pthread -ansi -std=c++11 -fPIC -MMD -MP -MF
#g++ -export-dynamic -static-libgcc -Wl,-Bsymbolic -pthread -shared -Wl,
#-soname=-BSymbolyc -o "/home/gdp24/maya/shaders/mentalRayFireShader.so"     
#******************************************************************************
CMAKE_MINIMUM_REQUIRED(VERSION 2.8) 

PROJECT(mentalRayFireShader)

SET(LIBRARY_OUTPUT_PATH /home/gdp24/maya/shaders/)

SET(CMAKE_CXX_COMPILER g++)

#Set build to Release is none is given
if (NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE Release)
endif()

#All warnings and thread compiling on linux
IF(UNIX)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pthread")
ENDIF()

#Add custom .cmake files located in this folder
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmakeModules")

SET(MAYA_VERSION "2015")
FIND_PACKAGE (Maya REQUIRED)

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_REENTRANT -fPIC -pthread -ansi -std=c++11 -shared -export-dynamic -static-libgcc -Wl,-Bsymbolic")

FILE(GLOB mentalRayFireShader_SRC
    "*.h"
    "*.cpp"
    "*.impl"
)

ADD_LIBRARY(mentalRayFireShader
	SHARED
   ${mentalRayFireShader_SRC}
)

SET_TARGET_PROPERTIES(mentalRayFireShader PROPERTIES PREFIX "")

