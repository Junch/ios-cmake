# Standard setup
cmake_minimum_required (VERSION 2.8)
project (hello-lib CXX C)

# Includes
include_directories (${hello-lib_SOURCE_DIR})

# Source files
set (SRC
	HelloWorld.cpp
	HelloIOS.mm
)

# Headers
set (HDR
	HelloWorld.h
	HelloIOS.h
)


IF (${SIMULATOR})
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mios-simulator-version-min=6.0")
ENDIF()

# Library
add_library (hello-lib STATIC ${SRC} ${HDR})
set_xcode_property (hello-lib GCC_GENERATE_DEBUGGING_SYMBOLS YES ALL)

# Installation
set (CMAKE_INSTALL_PREFIX "${hello-lib_SOURCE_DIR}/../hello-app/hello-app")
install (TARGETS hello-lib DESTINATION .)
install (FILES HelloIOS.h DESTINATION .)
