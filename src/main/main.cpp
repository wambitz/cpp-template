#include <iostream>

#include "example_interface.hpp"
#include "example_public_private.hpp"
#include "example_shared.hpp"
#include "example_static.hpp"
#include "plugin_api.hpp"

int main(int argc, char** argv) {
    std::cout << "Starting main application...\n";
    example_static_function();
    example_shared_function();
    example_public();
    example_interface();

    // Plugin loading with RPATH-based discovery
    // dlopen() uses RPATH to find plugin automatically - no hardcoded paths!
    const std::string plugin_name = "libexample_plugin_impl.so";

    std::cout << "Loading plugin: " << plugin_name << std::endl;
    load_plugin(plugin_name.c_str());

    std::cout << "Main application finished.\n";
    return 0;
}