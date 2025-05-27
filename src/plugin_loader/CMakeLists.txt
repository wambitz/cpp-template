add_library(plugin_loader STATIC plugin_loader.cpp)
target_include_directories(plugin_loader PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(plugin_loader dl)