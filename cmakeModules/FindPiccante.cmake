#  Find Piccante
#
#  PICCANTE_INCLUDE_DIRS - where to find Piccante includes.
#  PICCANTE_FOUND        - True if Piccante found.
#  As Piccante is a collection of headers there is no lib variable 

IF(PICCANTE_INCLUDE_DIRS)

	# in cache already
	SET(PICCANTE_FOUND TRUE)
	
ELSE(PICCANTE_INCLUDE_DIRS)

	# Look for the header file.
	FIND_PATH( PICCANTE_INCLUDE_DIRS NAMES piccante.hpp 
		PATHS ${INCLUDE_INSTALL_DIR}
     	${KDE4_INCLUDE_DIR}
     	PATH_SUFFIXES piccante)

	# handle the QUIETLY and REQUIRED arguments and set PICCANTE_FOUND to TRUE if
	# all listed variables are TRUE
	INCLUDE( FindPackageHandleStandardArgs)	
	FIND_PACKAGE_HANDLE_STANDARD_ARGS( Picccante DEFAULT_MSG PICCANTE_INCLUDE_DIRS)

	MARK_AS_ADVANCED(PICCANTE_INCLUDE_DIRS)
ENDIF(PICCANTE_INCLUDE_DIRS)
