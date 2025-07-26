#include "example_interface.hpp"
#include "example_public_private.hpp"
#include "example_shared.hpp"
#include "example_static.hpp"
#include "example_usage.hpp"
#include "plugin_api.hpp"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <vector>

int main(int argc, char** argv)
{
    std::cout << "Starting main application...\n";
    example_static_function();
    example_shared_function();
    example_public();
    example_interface();
    example_usage();

    // Determine executable directory
    std::filesystem::path exe_path = std::filesystem::absolute(argv[0]);
    std::filesystem::path exe_dir = exe_path.parent_path();

    // List of plugin paths to try (relative to executable location)
    std::vector<std::filesystem::path> plugin_paths = {
        exe_dir / "../lib/libexample_plugin_impl.so",  // Installed layout
        exe_dir / "libexample_plugin_impl.so",         // Same dir as exe (rare, but possible)
        exe_dir / "../../src/example_plugin_impl/libexample_plugin_impl.so",       // Dev layout
        exe_dir / "../../build/src/example_plugin_impl/libexample_plugin_impl.so"  // Alt dev
    };

    bool plugin_loaded = false;
    for (const auto& path : plugin_paths)
    {
        if (std::filesystem::exists(path))
        {
            std::cout << "Loading plugin from: " << path << std::endl;
            load_plugin(path.c_str());
            plugin_loaded = true;
            break;
        }
    }

    if (!plugin_loaded)
    {
        std::cerr << "ERROR: Plugin could not be loaded from any expected location!" << std::endl;
        return 1;
    }

    std::cout << "Main application finished.\n";
    return 0;
}