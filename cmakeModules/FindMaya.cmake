#
# (c) 2010-Present Peregrine Labs a division of Peregrine Visual Storytelling Ltd.
# All rights reserved.
#
# The coded instructions, statements, computer programs, and/or related
# material (collectively the "Data") in these files contain unpublished
# information proprietary to Peregrine Visual Storytelling Ltd. ("Peregrine") 
# and/or its licensors, which is protected by U.S. and Canadian federal 
# copyright law and by international treaties.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND. PEREGRINE
# DOES NOT MAKE AND HEREBY DISCLAIMS ANY EXPRESS OR IMPLIED WARRANTIES
# INCLUDING, BUT NOT LIMITED TO, THE WARRANTIES OF NON-INFRINGEMENT,
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, OR ARISING FROM A COURSE 
# OF DEALING, USAGE, OR TRADE PRACTICE. IN NO EVENT WILL PEREGRINE AND/OR ITS
# LICENSORS BE LIABLE FOR ANY LOST REVENUES, DATA, OR PROFITS, OR SPECIAL,
# DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES, EVEN IF PEREGRINE AND/OR ITS
# LICENSORS HAS BEEN ADVISED OF THE POSSIBILITY OR PROBABILITY OF SUCH DAMAGES.
#
#

#
# MAYA_FOUND            set if maya is found.
# MAYA_LOCATION         install location of maya.
# MAYA_INCLUDE_DIRS      maya's include directory
# MAYA_LIBRARY_DIR      maya's library directory
# MAYA_LIBRARIES        all maya libraries (sans MAYA_IMAGE_LIBRARIES)

# MENTALRAY_FOUND            set if mentalray is found.
# MENTALRAY_LOCATION         install location of mentalray.
# MENTALRAY_INCLUDE_DIRS      mentalray's include directory

SET( MAYA_FOUND "NO" )
SET( MENTALRAY_FOUND "NO" )

# TODO This should be automatically detected when Maya is found
SET( MAYA_VERSION "${MAYA_VERSION}" )
IF ( NOT MAYA_VERSION )
	MESSAGE ( FATAL_ERROR "Maya version not defined!")
ELSE( NOT MAYA_VERSION )
	MESSAGE(STATUS "Using Maya Version: ${MAYA_VERSION}")
ENDIF( NOT MAYA_VERSION )

##
## Obtain Maya install location
##

FIND_PATH( MAYA_LOCATION include/maya/MLibrary.h
  "${MAYA_LOCATION}"
  "${MAYA_LOCATION}/../../devkit/"
  "/usr/autodesk/maya/"
  DOC "Root directory of Maya headers"
  )
  
FIND_PATH( MENTALRAY_LOCATION include/mi_version.h
  "${MAYA_LOCATION}/mentalray/"
  "${MAYA_LOCATION}/../mentalray/devkit/"
  "${MAYA_LOCATION}/devkit/mentalray/"
  "${MAYA_LOCATION}/mentalray/devkit/"
  "${MAYA_LOCATION}/../../devkit/mentalray/"
  "${MAYA_LOCATION}/mentalrayForMaya${MAYA_VERSION}/"
  "${MAYA_LOCATION}/../mentalrayForMaya${MAYA_VERSION}/devkit/"
  "${MAYA_LOCATION}/devkit/mentalrayForMaya${MAYA_VERSION}/"
  "${MAYA_LOCATION}/mentalrayForMaya${MAYA_VERSION}/devkit/"
  "${MAYA_LOCATION}/../../devkit/mentalrayForMaya${MAYA_VERSION}/"
  DOC "Root directory of Mental Ray headers"
  )
  
IF( MAYA_LOCATION )
	SET( MAYA_FOUND "YES" )
	
	MESSAGE(STATUS "Found Maya: ${MAYA_LOCATION}")

	SET( MAYA_INCLUDE_DIRS       "${MAYA_LOCATION}/include" )
	
	IF ( APPLE )
		SET( MAYA_LIBRARY_DIR       "${MAYA_LOCATION}/../Maya.app/Contents/MacOS" )
	ELSE ( APPLE )
		SET( MAYA_LIBRARY_DIR       "${MAYA_LOCATION}/lib" )
	ENDIF ( APPLE )
	
	SET( MAYA_DEFINITIONS 
	  "-DREQUIRE_IOSTREAM -DBits64_ -DPG_MAYA_PLUGIN -D_BOOL"
	)
	
	SET( MAYA_LIB_NAMES Foundation OpenMaya OpenMayaUI OpenMayaAnim OpenMayaFX OpenMayaRender Image )
		
	IF( WIN32 )
		SET( MAYA_DEFINITIONS "${MAYA_DEFINITIONS} -nologo -D_WIN32 -DWIN32 -DNT_PLUGIN -D_WINDOWS -D_WINDLL -DVC80_UPGRADE=0x0710" )
		SET( MAYA_DEFINITIONS "${MAYA_DEFINITIONS} -Zi -EHsc -GR -GS" )
		SET( MAYA_DEFINITIONS "${MAYA_DEFINITIONS} /fp:precise" )
		SET( MAYA_LINK_FLAGS "-DLL -nologo -MACHINE:X64 /export:initializePlugin /export:uninitializePlugin /MANIFEST /SUBSYSTEM:WINDOWS /NXCOMPAT /TLBID:1 /DYNAMICBASE" )
		SET( MAYA_EXTENSION ".mll" )
		
		SET( MAYA_LIBRARY_STYLE MODULE )
		SET( MAYA_TBB_LIBRARIES ${MAYA_LIBRARY_DIR}/tbb.lib ${MAYA_LIBRARY_DIR}/tbbmalloc.lib )
		SET( MAYA_TBB_RUNTIME_LIBRARIES ${MAYA_LIBRARY_DIR}/../bin/tbb.dll ${MAYA_LIBRARY_DIR}/../bin/tbbmalloc.dll )
		
		FOREACH(LIB_NAME ${MAYA_LIB_NAMES}) 
				SET( MAYA_LIBRARIES  ${MAYA_LIBRARIES} ${MAYA_LIBRARY_DIR}/${LIB_NAME}.dll )
		ENDFOREACH()
	ELSE( WIN32 )
		SET( MAYA_DEFINITIONS "${MAYA_DEFINITIONS} -D_GNU_SOURCE -DCC_GNU_ -D_LANGUAGE_C_PLUS_PLUS -Wall -Wextra -Wno-unused-parameter -fno-strict-aliasing -funsigned-char" )
		
		SET( CMAKE_CXX_FLAGS 
		  "-fno-gnu-keywords"
		  )
		
		SET( OS_LIBRARIES "" )
		SET( MAYA_EXTENSION ".so" )
		
		IF ( APPLE )
			SET( MAYA_DEFINITIONS "${MAYA_DEFINITIONS} -fno-common -DOSMac_ -DOSMacOSX_ -DOSMac_MachO_" )
			SET( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fpascal-strings -arch x86_64" )
			SET( MAYA_EXTENSION ".bundle" )
			SET( MAYA_LIBRARY_STYLE MODULE )
			SET( MAYA_TBB_LIBRARIES ${MAYA_LIBRARY_DIR}/libtbb.dylib ${MAYA_LIBRARY_DIR}/libtbbmalloc.dylib )
			SET( MAYA_TBB_RUNTIME_LIBRARIES ${MAYA_TBB_LIBRARIES} )
			FOREACH(LIB_NAME ${MAYA_LIB_NAMES}) 
				SET( MAYA_LIBRARIES  ${MAYA_LIBRARIES} ${MAYA_LIBRARY_DIR}/lib${LIB_NAME}.dylib )
			ENDFOREACH()
		ELSE( APPLE )
			SET( MAYA_DEFINITIONS "${MAYA_DEFINITIONS} -pthread -m64 -DUNIX -D_BOOL -DLINUX -DFUNCPROTO -D_GNU_SOURCE -DLINUX_64 -fPIC -fno-strict-aliasing -Wno-deprecated -Wall -Wno-multichar -Wno-comment -Wno-sign-compare -funsigned-char -Wno-reorder -fno-gnu-keywords -ftemplate-depth-25" )
			SET( MAYA_LIBRARY_STYLE SHARED )
			SET( MAYA_TBB_LIBRARIES ${MAYA_LIBRARY_DIR}/libtbb.so ${MAYA_LIBRARY_DIR}/libtbbmalloc.so )
			SET( MAYA_TBB_RUNTIME_LIBRARIES ${MAYA_TBB_LIBRARIES} )
			FOREACH(LIB_NAME ${MAYA_LIB_NAMES}) 
				SET( MAYA_LIBRARIES  ${MAYA_LIBRARIES} ${MAYA_LIBRARY_DIR}/lib${LIB_NAME}.so )
			ENDFOREACH()
		ENDIF( APPLE )
	ENDIF( WIN32 )
		
	SET( MAYA_DEFINITIONS "${MAYA_DEFINITIONS} -D_MAYA_VERSION_${MAYA_VERSION} -D_MAYA_VERSION=${MAYA_VERSION}" )
	
	IF(NOT UNIX)
		# Maya on linux includes tbb, malloc and other libraries that are
		# already included as system libraries
		LINK_DIRECTORIES( ${MAYA_LIBRARY_DIR} )
	ENDIF(NOT UNIX)
	
	IF(MENTALRAY_LOCATION)
		SET( MENTALRAY_FOUND "YES" )
		MESSAGE(STATUS "Found Mental Ray: ${MENTALRAY_LOCATION}")
		IF( WIN32 )
			SET(MENTALRAY_INCLUDE_DIRS ${MENTALRAY_LOCATION}/devkit/include)
			LINK_DIRECTORIES( ${MENTALRAY_LOCATION}/lib/nt )
		ELSE( WIN32 )
			SET(MENTALRAY_INCLUDE_DIRS ${MENTALRAY_LOCATION}/include)
		ENDIF( WIN32 )		
	ELSE(MENTALRAY_LOCATION)
		MESSAGE ( FATAL_ERROR "Mental Ray not found!")
	ENDIF(MENTALRAY_LOCATION )
ELSE ( MAYA_LOCATION )
	MESSAGE ( FATAL_ERROR "Maya not found!")
ENDIF( MAYA_LOCATION )


