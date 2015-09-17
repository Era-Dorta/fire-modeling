#g++ -I/usr/autodesk/mentalrayForMaya2015/devkit/include -O3 -pedantic -Wall 
#-Wextra -c -fmessage-length=0 -D_REENTRANT -pthread -ansi -std=c++11 -fPIC -MMD -MP -MF
#g++ -export-dynamic -static-libgcc -Wl,-Bsymbolic -pthread -shared -Wl,
#-soname=-BSymbolyc -o "/home/gdp24/maya/shaders/mentalRayFireShader.so"     
#******************************************************************************
CMAKE_MINIMUM_REQUIRED(VERSION 2.8) 

PROJECT(fire_shader)

#Set build to Release is none is given
IF (NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE Release CACHE STRING "type of build" FORCE )
ENDIF(NOT CMAKE_BUILD_TYPE)

# Cannot relay on CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT as it changes to
# false after running a second time, so use our on variable. 
# $ cmake ../ # Will fail because no maya version was given
# $ cmake -DMAYA_VERSION ../ # This time INITIALIZED_TO_DEFAULT will be false
IF(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
	SET(IS_DEFAULT_PREFIX TRUE CACHE BOOLEAN "using defaul prefix" FORCE)
ENDIF(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
MARK_AS_ADVANCED(IS_DEFAULT_PREFIX)

# Get current maya version
IF (MAYA_VERSION)
	SET(MAYA_VERSION "${MAYA_VERSION}" CACHE STRING "maya version" FORCE)
ELSE(MAYA_VERSION)
	SET(MAYA_VERSION "" CACHE STRING "maya version" FORCE)
    MESSAGE(FATAL_ERROR "Maya version required, e.g. cmake -DMAYA_VERSION=2015 ../")
ENDIF(MAYA_VERSION)

#Add custom .cmake files located in this folder
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmakeModules")

# Boost is explicitely required for OpenVDB in Windows
# The components were extracted from their Makefile
# https://github.com/dreamworksanimation/openvdb/blob/master/openvdb/Makefile
# And the version from their INSTALL file
# https://github.com/dreamworksanimation/openvdb/blob/master/openvdb/INSTALL
IF(WIN32)
	FIND_PACKAGE (Boost 1.42 REQUIRED COMPONENTS iostreams system thread)
ENDIF(WIN32)

# OpenVDB for sparse voxel data
FIND_PACKAGE (OpenVDB REQUIRED)

# Maya and Mental Ray development files
FIND_PACKAGE (Maya REQUIRED)

# Include the headers for Boost, Openvdb, Maya and Mental Ray
IF(WIN32)
	INCLUDE_DIRECTORIES( ${Boost_INCLUDE_DIR} )
ENDIF(WIN32)
INCLUDE_DIRECTORIES( ${OpenVdb_INCLUDE_DIRS} )
INCLUDE_DIRECTORIES( ${MAYA_INCLUDE_DIRS} )
INCLUDE_DIRECTORIES( ${MENTALRAY_INCLUDE_DIRS} )

MARK_AS_ADVANCED(MAYA_LOCATION MENTALRAY_LOCATION)

#All warnings and thread compiling on linux
IF(UNIX)
	SET(CMAKE_CXX_COMPILER g++)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pthread -D_REENTRANT -fPIC -ansi -std=c++11 -shared -export-dynamic -static-libgcc -Wl,-Bsymbolic")
ENDIF(UNIX)

IF(IS_DEFAULT_PREFIX)
	# MENTALRAY_LOCATION points to mentalray/devkit, get the parent directory 
	GET_FILENAME_COMPONENT(MENTALRAY_LOCATION_DIR ${MENTALRAY_LOCATION} DIRECTORY)
		
    SET(CMAKE_INSTALL_PREFIX "${MENTALRAY_LOCATION_DIR}" CACHE PATH "default install path" FORCE)

	IF(NOT SHADERS_INSTALL_PREFIX)		
		SET(SHADERS_INSTALL_PREFIX "${MENTALRAY_LOCATION_DIR}/shaders" CACHE PATH "shaders install path" FORCE)
	ELSE(NOT SHADERS_INSTALL_PREFIX)
		SET(SHADERS_INSTALL_PREFIX "${SHADERS_INSTALL_PREFIX}" CACHE PATH "shaders install path" FORCE)
	ENDIF(NOT SHADERS_INSTALL_PREFIX)       


	IF(NOT SCRIPTS_INSTALL_PREFIX)	
		SET(SCRIPTS_INSTALL_PREFIX "${MENTALRAY_LOCATION_DIR}/scripts" CACHE PATH "scripts install path" FORCE)	
	ELSE(NOT SCRIPTS_INSTALL_PREFIX)
		SET(SCRIPTS_INSTALL_PREFIX "${SCRIPTS_INSTALL_PREFIX}" CACHE PATH "scripts install path" FORCE)
	ENDIF(NOT SCRIPTS_INSTALL_PREFIX)    	
    
ELSE(IS_DEFAULT_PREFIX)

	# Set shader and script paths, if a new cmake_install_prefix is given, rewrite the old paths
	IF(NOT SHADERS_INSTALL_PREFIX OR NOT(CMAKE_INSTALL_PREFIX STREQUAL PREV_CMAKE_INSTALL_PREFIX) )		
		SET(SHADERS_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/shaders" CACHE PATH "shaders install path" FORCE)
	ELSE(NOT SHADERS_INSTALL_PREFIX OR NOT(CMAKE_INSTALL_PREFIX STREQUAL PREV_CMAKE_INSTALL_PREFIX))
		SET(SHADERS_INSTALL_PREFIX "${SHADERS_INSTALL_PREFIX}" CACHE PATH "shaders install path" FORCE)
	ENDIF(NOT SHADERS_INSTALL_PREFIX OR NOT(CMAKE_INSTALL_PREFIX STREQUAL PREV_CMAKE_INSTALL_PREFIX))    

	IF(NOT SCRIPTS_INSTALL_PREFIX OR NOT(CMAKE_INSTALL_PREFIX STREQUAL PREV_CMAKE_INSTALL_PREFIX))	
		SET(SCRIPTS_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/scripts" CACHE PATH "scripts install path" FORCE)
	ELSE(NOT SCRIPTS_INSTALL_PREFIX OR NOT(CMAKE_INSTALL_PREFIX STREQUAL PREV_CMAKE_INSTALL_PREFIX))
		SET(SCRIPTS_INSTALL_PREFIX "${SCRIPTS_INSTALL_PREFIX}" CACHE PATH "scripts install path" FORCE)	
	ENDIF(NOT SCRIPTS_INSTALL_PREFIX OR NOT(CMAKE_INSTALL_PREFIX STREQUAL PREV_CMAKE_INSTALL_PREFIX))
	
ENDIF(IS_DEFAULT_PREFIX)

SET(PREV_CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}" CACHE PATH "previous install prefix" FORCE)
MARK_AS_ADVANCED(PREV_CMAKE_INSTALL_PREFIX)

# Already used the prefix variable, set to false
SET(IS_DEFAULT_PREFIX FALSE CACHE BOOLEAN "using defaul prefix" FORCE)

SET(PROJECT_DATA_INSTALL_PREFIX "${SHADERS_INSTALL_PREFIX}/${PROJECT_NAME}_data")
# Pass to the source code were it will be installed, so it can access the data files
ADD_DEFINITIONS(-DLIBRARY_DATA_PATH="${PROJECT_DATA_INSTALL_PREFIX}")

FILE(GLOB PROJECT_SRC
    "mentalray/src/*.h"
    "mentalray/src/*.cpp"
    "mentalray/src/*.impl"
)

FILE(GLOB PROJECT_DATA
    "${PROJECT_NAME}_data/*.specline"
    "${PROJECT_NAME}_data/*.optconst"
)

FILE(GLOB PROJECT_SCRIPTS
    "mentalray/scripts/*.mel"
)

FILE(GLOB PROJECT_SCRIPTS_AETEMPLATES
    "mentalray/scripts/AETemplates/*.mel"
)

ADD_LIBRARY(${PROJECT_NAME}
	SHARED
   ${PROJECT_SRC}
)


IF(WIN32)
	# Boost linking
	TARGET_LINK_LIBRARIES( ${PROJECT_NAME} ${Boost_LIBRARIES} )
ENDIF(WIN32)

# OpenVDB linking
TARGET_LINK_LIBRARIES(${PROJECT_NAME} ${OpenVdb_LIBRARIES})

# Maya Linking, actually this is doing nothing, the MAYA_LIBRARIES is empty
TARGET_LINK_LIBRARIES(${PROJECT_NAME} ${MAYA_LIBRARIES})

# Library name should not have lib as name prefix
SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES PREFIX "")

# MentalRay library
IF(WIN32)
	INSTALL(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION ${SHADERS_INSTALL_PREFIX})
ELSE(WIN32)
	INSTALL(TARGETS ${PROJECT_NAME} LIBRARY DESTINATION ${SHADERS_INSTALL_PREFIX})
ENDIF(WIN32)

# MentalRay library definition
INSTALL( FILES "mentalray/${PROJECT_NAME}.mi" DESTINATION "${SHADERS_INSTALL_PREFIX}/include" )

# MentalRay library data files
INSTALL( FILES ${PROJECT_DATA} DESTINATION "${SHADERS_INSTALL_PREFIX}/${PROJECT_NAME}_data" )

# Utility scripts
INSTALL( FILES ${PROJECT_SCRIPTS} DESTINATION "${SCRIPTS_INSTALL_PREFIX}" )

# Shader UI templates
INSTALL( FILES ${PROJECT_SCRIPTS_AETEMPLATES} DESTINATION "${SCRIPTS_INSTALL_PREFIX}/AETemplates" )

