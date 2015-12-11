cmake_minimum_required(VERSION 2.8)
PROJECT(MEX)

# Install dir is this folder
SET(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR} CACHE STRING "Installation directory" FORCE )

# Add custom .cmake files located in cmakeModules
SET(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmakeModules)

#Set build to Release is none is given
IF (NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE Release CACHE STRING "type of build" FORCE )
ENDIF(NOT CMAKE_BUILD_TYPE)

ADD_DEFINITIONS(/DMATLAB_MEX_FILE) #define matlab macros
ADD_DEFINITIONS(/DMX_COMPAT_32)

# Current Matlab version needs this compiler version on linux
IF(UNIX)
	SET(CMAKE_CXX_COMPILER g++-4.7 CACHE STRING "C++ compiler")
	SET(CMAKE_CC_COMPILER gcc-4.7 CACHE STRING "C compiler")
ENDIF(UNIX)

FIND_PACKAGE(Matlab REQUIRED)

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

# Include Matlab headers
INCLUDE_DIRECTORIES(${MATLAB_INCLUDE_DIR})

# Include the headers for Boost and Openvdb
IF(WIN32)
	INCLUDE_DIRECTORIES( ${Boost_INCLUDE_DIR} )
ENDIF(WIN32)

INCLUDE_DIRECTORIES( ${OpenVdb_INCLUDE_DIRS} )

IF(MATLAB_FOUND)
    MESSAGE(STATUS "MATLAB Found, MATLAB MEX will be compiled.")

    # Auxiliary code needed to compile the mex files
    SET(COMMON_SRC
    	createVoxelDataSet.cpp
    	createVoxelDataSet.h
    )

    # Array with the name of each function to be compiled
	SET(FUNCTIONS
		mixHeatMaps
	)

	# Compiled code extension changes depending of the platform and processor
	EXECUTE_PROCESS(COMMAND "$ENV{MATLAB_ROOT}/bin/mexext" OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_VARIABLE EXTENSION)
	
	# Compile each function separately
	FOREACH(FUNCTION ${FUNCTIONS})
		ADD_LIBRARY(${FUNCTION}	SHARED "${FUNCTION}.cpp" ${COMMON_SRC} ${CMAKE_SOURCE_DIR}/Matlabdef.def)

		IF(WIN32)
			# Boost linking, in linux systems the it will be automatically found
			TARGET_LINK_LIBRARIES( ${FUNCTION} ${Boost_LIBRARIES})
		ENDIF(WIN32)

		# Matlab libraries linking
		TARGET_LINK_LIBRARIES(${FUNCTION} ${MATLAB_LIBRARIES})

		# OpenVDB linking
		TARGET_LINK_LIBRARIES(${FUNCTION} ${OpenVdb_LIBRARIES})

		# Library name should not have lib as name prefix
		SET_TARGET_PROPERTIES(${FUNCTION} PROPERTIES PREFIX "")

		# Library should end in mexa64 or mexw32
		SET_TARGET_PROPERTIES(${FUNCTION} PROPERTIES SUFFIX ".${EXTENSION}")

		# Install all compiled files in CMAKE_INSTALL_PREFIX 
		IF(WIN32)
			INSTALL(TARGETS ${FUNCTION} RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX})
		ELSE(WIN32)
			INSTALL(TARGETS ${FUNCTION} LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}
			PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ
  			GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
		ENDIF(WIN32)

	ENDFOREACH()

ELSE(MATLAB_FOUND)
    MESSAGE("MATLAB not found...nothing will be built.")
ENDIF(MATLAB_FOUND)
