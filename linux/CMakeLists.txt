cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "flutter_js")
project(${PROJECT_NAME} LANGUAGES CXX C)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_js_plugin")

set(CMAKE_C_COMPILER "gcc")
set(CMAKE_CXX_COMPILER "g++")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -DANDROID_STL=c++_static -DDEBUGGER_SERVER_PORT=${DEBUGGER_SERVER_PORT}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DQUICKJS")
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-error=incompatible-pointer-types-discards-qualifiers")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-int-conversion")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-variable")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-but-set-variable")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-maybe-uninitialized")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DCONFIG_VERSION=\\\"2020-11-08\\\" ")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)


include_directories(
    ../android/src/main/c/quickjs
)
add_library(${PLUGIN_NAME} SHARED
  "flutter_js_plugin.cc"
  ../android/src/main/c/libfastdev_quickjs_runtime.cpp
  ../android/src/main/c/quickjs/cutils.c
  ../android/src/main/c/quickjs/libregexp.c
  ../android/src/main/c/quickjs/libunicode.c
  ../android/src/main/c/quickjs/quickjs.c
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# List of absolute paths to libraries that should be bundled with the plugin
set(flutter_js_bundled_libraries
  ""
  PARENT_SCOPE
)

# cmake_minimum_required(VERSION 3.10)
# set(PROJECT_NAME "flutter_js")
# project(${PROJECT_NAME} LANGUAGES CXX)

# # This value is used when generating builds using this plugin, so it must
# # not be changed
# set(PLUGIN_NAME "flutter_js_plugin")

# set(CMAKE_C_COMPILER "gcc")
# set(CMAKE_CXX_COMPILER "g++")
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -DDEBUGGER_SERVER_PORT=${DEBUGGER_SERVER_PORT}")
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DQUICKJS")
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DCONFIG_VERSION=\\\"2020-11-08\\\" ")
# include_directories(
#     ../android/src/main/c/quickjs
# )


# add_library(${PLUGIN_NAME} SHARED
#   "flutter_js_plugin.cc"
#   ../android/src/main/c/libfastdev_quickjs_runtime.cpp
#   ../android/src/main/c/quickjs/cutils.c
#   ../android/src/main/c/quickjs/libregexp.c
#   ../android/src/main/c/quickjs/libunicode.c
#   ../android/src/main/c/quickjs/quickjs.c

# )
# apply_standard_settings(${PLUGIN_NAME})
# set_target_properties(${PLUGIN_NAME} PROPERTIES
#   CXX_VISIBILITY_PRESET hidden)
# target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
# target_include_directories(${PLUGIN_NAME} INTERFACE
#   "${CMAKE_CURRENT_SOURCE_DIR}/include")
# target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
# target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# # List of absolute paths to libraries that should be bundled with the plugin
# set(flutter_js_bundled_libraries
#   ""
#   PARENT_SCOPE
# )
