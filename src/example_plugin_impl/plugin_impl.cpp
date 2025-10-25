#include <iostream>

extern "C" void register_plugin() {
    std::cout << "Plugin registered!\n";
}