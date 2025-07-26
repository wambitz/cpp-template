add_executable(main_exec main.cpp)

target_link_libraries(main_exec
    PRIVATE
    example_public_private
    example_usage
    example_static
    example_shared
    example_plugin_loader 
    example_plugin_impl
)

# Set development RPATH for plugin discovery during builds
# $ORIGIN (same dir) + $ORIGIN/../lib (standard layout)
# See docs/rpath-guide.md for details
set_target_properties(main_exec PROPERTIES 
    BUILD_RPATH "$ORIGIN:$ORIGIN/../lib"
)