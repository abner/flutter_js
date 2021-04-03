cmake_minimum_required(VERSION 3.15)
include("${CMAKE_CURRENT_SOURCE_DIR}/../cxx/quickjs.cmake")

set(PROJECT_NAME "flutter_js")
project(${PROJECT_NAME} LANGUAGES CXX)
add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_js_plugin")

add_library(${PLUGIN_NAME} SHARED
  "flutter_js_plugin.cpp"
  "${CXX_LIB_DIR}/libfastdev_quickjs_runtime.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin quickjs)

# List of absolute paths to libraries that should be bundled with the plugin
set(flutter_js_bundled_libraries
  ""
  PARENT_SCOPE
)
