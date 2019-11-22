# The MIT License (MIT)
#
# Copyright (c) 2016-2017 Simon Ninon <simon.ninon@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

###
# config
###
cmake_minimum_required(VERSION 3.13)
set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_CXX_STANDARD 11)
include(ExternalProject)


###
# verbose make
###
# set(CMAKE_VERBOSE_MAKEFILE TRUE)


###
# project
###
project(tacopie LANGUAGES CXX VERSION 3.2.0)


###
# compilation options
###
if (MSVC)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W3 /O2 /bigobj")

  # was causing conflics with gtest build
  string(REPLACE "/RTC1" "" CMAKE_CXX_FLAGS_DEBUG ${CMAKE_CXX_FLAGS_DEBUG})

  if ("${MSVC_RUNTIME_LIBRARY_CONFIG}" STREQUAL "")
    set(MSVC_RUNTIME_LIBRARY_CONFIG "/MT")
  endif ()

  foreach (flag_var CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE)
    if ("${MSVC_RUNTIME_LIBRARY_CONFIG}" STREQUAL "/MT")
      string(REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
    elseif ("${MSVC_RUNTIME_LIBRARY_CONFIG}" STREQUAL "/MD")
      string(REPLACE "/MT" "/MD" ${flag_var} "${${flag_var}}")
    else ()
      string(REPLACE "/MD" "${MSVC_RUNTIME_LIBRARY_CONFIG}" ${flag_var} "${${flag_var}}")
      string(REPLACE "/MT" "${MSVC_RUNTIME_LIBRARY_CONFIG}" ${flag_var} "${${flag_var}}")
    endif()
  endforeach()

  add_definitions(-D_UNICODE)
  add_definitions(-DUNICODE)
  add_definitions(-DWIN32_LEAN_AND_MEAN)
else ()
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -W -Wall -Wextra -O3")
endif (MSVC)


###
# variables
###
set(DEPS_INCLUDES ${PROJECT_SOURCE_DIR}/deps/include)
set(DEPS_LIBRARIES ${PROJECT_SOURCE_DIR}/deps/lib)
set(TACOPIE_INCLUDES ${PROJECT_SOURCE_DIR}/includes)


###
# includes
###
include_directories(${TACOPIE_INCLUDES})

###
# sources
###
set(SRC_DIRS "sources" "sources/network" "sources/network/common" "sources/utils" "includes/tacopie" "includes/tacopie/network" "includes/tacopie/utils")

if (WIN32)
  set(SRC_DIRS ${SRC_DIRS} "sources/network/windows")
else ()
  set(SRC_DIRS ${SRC_DIRS} "sources/network/unix")
endif (WIN32)

foreach(dir ${SRC_DIRS})
  # get directory sources and headers
  file(GLOB s_${dir} "${dir}/*.cpp")
  file(GLOB h_${dir} "${dir}/*.hpp")
  file(GLOB i_${dir} "${dir}/*.ipp")

  # set sources
  set(SOURCES ${SOURCES} ${s_${dir}} ${h_${dir}} ${i_${dir}})
endforeach()


###
# outputs
###
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_PKGCONFIG_OUTPUT_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/pkgconfig)


###
# pkg-config
###
configure_file("tacopie.pc.in" "${CMAKE_PKGCONFIG_OUTPUT_DIRECTORY}/tacopie.pc" @ONLY)


###
# executable
###
add_library(${PROJECT_NAME} ${SOURCES})
set_property(TARGET ${PROJECT_NAME} PROPERTY POSITION_INDEPENDENT_CODE ON)

if (WIN32)
  set_target_properties(${PROJECT_NAME} PROPERTIES
    COMPILE_PDB_NAME ${PROJECT_NAME}
    COMPILE_PDB_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
endif (WIN32)

if (WIN32)
  target_link_libraries(${PROJECT_NAME} ws2_32)
else ()
  target_link_libraries(${PROJECT_NAME} pthread)
endif (WIN32)

# __TACOPIE_LOGGING_ENABLED
if (LOGGING_ENABLED)
  set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY COMPILE_DEFINITIONS " __TACOPIE_LOGGING_ENABLED=${LOGGING_ENABLED}")
endif (LOGGING_ENABLED)

# __TACOPIE_CONNECTION_QUEUE_SIZE
if (CONNECTION_QUEUE_SIZE)
  set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY COMPILE_DEFINITIONS " __TACOPIE_CONNECTION_QUEUE_SIZE=${CONNECTION_QUEUE_SIZE}")
endif (CONNECTION_QUEUE_SIZE)

#__TACOPIE_IO_SERVICE_NB_WORKERS
if (IO_SERVICE_NB_WORKERS)
  set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY COMPILE_DEFINITIONS " __TACOPIE_IO_SERVICE_NB_WORKERS=${IO_SERVICE_NB_WORKERS}")
endif (IO_SERVICE_NB_WORKERS)

#__TACOPIE_TIMEOUT
if (SELECT_TIMEOUT)
  set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY COMPILE_DEFINITIONS " __TACOPIE_TIMEOUT=${SELECT_TIMEOUT}")
endif (SELECT_TIMEOUT)


###
# install
###
# ensure lib and bin directories exist
install(CODE "FILE(MAKE_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})")
install(CODE "FILE(MAKE_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})")
# install tacopie
install(DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/ DESTINATION lib USE_SOURCE_PERMISSIONS)
install(DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/ DESTINATION bin USE_SOURCE_PERMISSIONS)
install(DIRECTORY ${TACOPIE_INCLUDES}/ DESTINATION include USE_SOURCE_PERMISSIONS)


###
# examples
###
if (BUILD_EXAMPLES)
  add_subdirectory(examples)
endif (BUILD_EXAMPLES)


###
# tests
###
if (BUILD_TESTS)
  add_subdirectory(tests)
  ExternalProject_Add("googletest"
    GIT_REPOSITORY "https://github.com/google/googletest.git"
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${PROJECT_SOURCE_DIR}/deps")
endif (BUILD_TESTS)
