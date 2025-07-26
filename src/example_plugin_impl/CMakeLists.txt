add_library(example_plugin_impl SHARED plugin_impl.cpp)
target_include_directories(example_plugin_impl PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

# Development convenience: Copy plugin to main executable's directory
# Copy plugin to main_exec directory for development testing
# Enables RPATH-based discovery during development builds
add_custom_command(TARGET example_plugin_impl POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:example_plugin_impl> 
            ${CMAKE_BINARY_DIR}/src/main/$<TARGET_FILE_NAME:example_plugin_impl>
    COMMENT "Copying plugin for development testing"
)