#g++ -I/usr/autodesk/mentalrayForMaya2015/devkit/include -O3 -pedantic -Wall 
#-Wextra -c -fmessage-length=0 -D_REENTRANT -pthread -ansi -std=c++11 -fPIC -MMD -MP -MF
#g++ -export-dynamic -static-libgcc -Wl,-Bsymbolic -pthread -shared -Wl,
#-soname=-BSymbolyc -o "/home/gdp24/maya/shaders/mentalRayFireShader.so"     
#******************************************************************************
CMAKE_MINIMUM_REQUIRED(VERSION 2.8) 

PROJECT(mentalRayFireShader)

SET(CMAKE_CXX_COMPILER g++)

#Set build to Release is none is given
if (NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE Release CACHE STRING "type of build" FORCE )
endif()

#All warnings and thread compiling on linux
IF(UNIX)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pthread")
ENDIF()

#Add custom .cmake files located in this folder
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmakeModules")

FIND_PACKAGE (OpenVDB REQUIRED)

SET(MAYA_VERSION "2015")
FIND_PACKAGE (Maya REQUIRED)

INCLUDE_DIRECTORIES( ${OpenVdb_INCLUDE_DIRS} )

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_REENTRANT -fPIC -ansi -std=c++11 -shared -export-dynamic -static-libgcc -Wl,-Bsymbolic")

MARK_AS_ADVANCED(MAYA_LOCATION MENTALRAY_LOCATION)

IF(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
	# MENTALRAY_LOCATION points to mentalray/devkit, get the parent directory 
	GET_FILENAME_COMPONENT(MENTALRAY_LOCATION_DIR ${MENTALRAY_LOCATION} DIRECTORY)
		
    SET(CMAKE_INSTALL_PREFIX "${MENTALRAY_LOCATION_DIR}" CACHE PATH "default install path" FORCE )

	IF(NOT SHADERS_INSTALL_PREFIX)		
		SET(SHADERS_INSTALL_PREFIX "${MENTALRAY_LOCATION_DIR}/shaders" CACHE PATH "maya scripts install path" FORCE )	
	ENDIF(NOT SHADERS_INSTALL_PREFIX)       


	IF(NOT SCRIPTS_INSTALL_PREFIX)	
		SET(SCRIPTS_INSTALL_PREFIX "${MAYA_LOCATION}/scripts" CACHE PATH "maya scripts install path" FORCE )	
	ENDIF(NOT SCRIPTS_INSTALL_PREFIX)    	
    
ELSE(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

	IF(NOT SHADERS_INSTALL_PREFIX)		
		SET(SHADERS_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/shaders" CACHE PATH "maya scripts install path" FORCE )	
	ENDIF(NOT SHADERS_INSTALL_PREFIX)    

	IF(NOT SCRIPTS_INSTALL_PREFIX)	
		SET(SCRIPTS_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/scripts" CACHE PATH "maya scripts install path" FORCE )
	ENDIF(NOT SCRIPTS_INSTALL_PREFIX)
	
ENDIF(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

SET(PROJECT_DATA_INSTALL_PREFIX "${SHADERS_INSTALL_PREFIX}/${PROJECT_NAME}Data")
# Pass to the source code were it will be installed, so it can access the data files
ADD_DEFINITIONS(-DLIBRARY_DATA_PATH="${PROJECT_DATA_INSTALL_PREFIX}")

FILE(GLOB PROJECT_SRC
    "mentalray/src/*.h"
    "mentalray/src/*.cpp"
    "mentalray/src/*.impl"
)

FILE(GLOB PROJECT_DATA
    "nist/data/*.specline"
    "nist/data/*.optconst"
)

FILE(GLOB PROJECT_SCRIPTS
    "maya/*.mel"
)

ADD_LIBRARY(${PROJECT_NAME}
	SHARED
   ${PROJECT_SRC}
)

# OpenVDB linking
TARGET_LINK_LIBRARIES(${PROJECT_NAME} ${OpenVdb_LIBRARIES})

SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES PREFIX "")

MESSAGE(STATUS "Set the installation root directory adding -DCMAKE_INSTALL_PREFIX=\"/path\"")
MESSAGE(STATUS "\tCMAKE_INSTALL_PREFIX=\"${CMAKE_INSTALL_PREFIX}\"")
MESSAGE(STATUS "Override shaders path with -DSHADERS_INSTALL_PREFIX=\"/path\"")
MESSAGE(STATUS "\tSHADERS_INSTALL_PREFIX=\"${SHADERS_INSTALL_PREFIX}\"")
MESSAGE(STATUS "Override scripts path with -DSCRIPTS_INSTALL_PREFIX=\"/path\"")
MESSAGE(STATUS "\tSCRIPTS_INSTALL_PREFIX=\"${SCRIPTS_INSTALL_PREFIX}\"")

# MentalRay library
INSTALL(TARGETS ${PROJECT_NAME} LIBRARY DESTINATION ${SHADERS_INSTALL_PREFIX})

# MentalRay library definition
INSTALL( FILES "mentalray/${PROJECT_NAME}.mi" DESTINATION "${SHADERS_INSTALL_PREFIX}/include" )

# MentalRay library data files
INSTALL( FILES ${PROJECT_DATA} DESTINATION "${SHADERS_INSTALL_PREFIX}/${PROJECT_NAME}_data" )

# Maya command
INSTALL( FILES ${PROJECT_SCRIPTS} DESTINATION "${SCRIPTS_INSTALL_PREFIX}" )

