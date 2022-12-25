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
# project
###
# see cmake --help-policy CMP<NNNN>
cmake_policy(SET CMP0048 NEW)
cmake_policy(SET CMP0077 NEW)
project(tacopie
  LANGUAGES CXX
  VERSION 3.2.0
  DESCRIPTION "C++ TCP Library"
  HOMEPAGE_URL "")

###
# config
###
cmake_minimum_required(VERSION 3.13)
option(VERBOSE_MAKEFILE "Generate verbose output from Makefile builds" OFF)
set(CMAKE_VERBOSE_MAKEFILE ${VERBOSE_MAKEFILE})
set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_CXX_STANDARD 11)

set(EXPORT_TARGET_NAME ${PROJECT_NAME} CACHE STRING "Name of the exported CMake target used in install(EXPORT)")

###
# compilation options
###
if (MSVC)
  add_compile_options(/W3 /O2 /bigobj)

  # was causing conflics with gtest build
  string(REPLACE "/RTC1" "" CMAKE_CXX_FLAGS_DEBUG ${CMAKE_CXX_FLAGS_DEBUG})
  # CMake 3.15 has support for automatically configuring MSVC runtime
  # through target property MSVC_RUNTIME_LIBRARY. Since I'm not
  # planning on supporting old CMake versions I will most likely bump
  # cmake_minimum_required to 3.15 at some point.
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
  add_compile_options(-W -Wall -Wextra -O3)
endif ()

include(sources.cmake)

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
add_library(${PROJECT_NAME} SHARED ${tacopie_sources})
target_include_directories(${PROJECT_NAME} PUBLIC
  $<BUILD_INTERFACE:${tacopie_includes}>
  $<INSTALL_INTERFACE:includes>)

if (WIN32)
  set_target_properties(${PROJECT_NAME} PROPERTIES
    COMPILE_PDB_NAME ${PROJECT_NAME}
    COMPILE_PDB_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
endif ()

set_target_properties(${PROJECT_NAME} PROPERTIES
  SOVERSION ${PROJECT_VERSION}
  RESOURCE ${CMAKE_PKGCONFIG_OUTPUT_DIRECTORY}/tacopie.pc)

find_package(Threads REQUIRED)
target_link_libraries(${PROJECT_NAME} PRIVATE Threads::Threads)

# __TACOPIE_LOGGING_ENABLED
option(LOGGING_ENABLED "Enable logging" OFF)
if (LOGGING_ENABLED)
  target_compile_definitions(${PROJECT_NAME} PRIVATE __TACOPIE_LOGGING_ENABLED=${LOGGING_ENABLED})
endif ()

# __TACOPIE_CONNECTION_QUEUE_SIZE
set(CONNECTION_QUEUE_SIZE "" CACHE STRING "Custom connection queue size")
if (CONNECTION_QUEUE_SIZE MATCHES "^[0-9]+")
  target_compile_definitions(${PROJECT_NAME} PRIVATE __TACOPIE_CONNECTION_QUEUE_SIZE=${CONNECTION_QUEUE_SIZE})
endif ()

#__TACOPIE_IO_SERVICE_NB_WORKERS
set(IO_SERVICE_NB_WORKERS "" CACHE STRING "Number of service workers")
if (IO_SERVICE_NB_WORKERS MATCHES "^[1-9]+")
  target_compile_definitions(${PROJECT_NAME} PRIVATE __TACOPIE_IO_SERVICE_NB_WORKERS=${IO_SERVICE_NB_WORKERS})
endif ()

#__TACOPIE_TIMEOUT
set(SELECT_TIMEOUT "" CACHE STRING "Select timeout")
if (SELECT_TIMEOUT MATCHES "^[0-9]+")
  target_compile_definitions(${PROJECT_NAME} PRIVATE __TACOPIE_TIMEOUT=${SELECT_TIMEOUT})
endif ()

###
# install
###
# NOTE: this fails if more directories are added to ${tacopie_includes}
include(GNUInstallDirs)
install(DIRECTORY ${tacopie_includes}/ DESTINATION include USE_SOURCE_PERMISSIONS)
install(TARGETS ${PROJECT_NAME} EXPORT ${EXPORT_TARGET_NAME}
  LIBRARY
  RESOURCE DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)

###
# examples
###
option(BUILD_EXAMPLES "Build examples" OFF)
if (BUILD_EXAMPLES)
  add_subdirectory(examples)
endif ()


###
# tests
###
option(BUILD_TESTS "Build tests" OFF)
if (BUILD_TESTS)
  if (NOT TARGET gtest)
    set(INSTALL_GTEST OFF)
    add_subdirectory(googletest)
  endif ()
  add_subdirectory(tests)
endif ()
