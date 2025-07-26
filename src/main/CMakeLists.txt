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