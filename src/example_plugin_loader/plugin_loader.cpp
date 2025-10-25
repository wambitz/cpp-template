#include <dlfcn.h>

#include <iostream>

#include "plugin_api.hpp"

void load_plugin(const char* lib) {
    void* handle = dlopen(lib, RTLD_LAZY);
    if (!handle) {
        std::cerr << "Cannot load plugin: " << dlerror() << std::endl;
        return;
    }

    auto func = (void (*)()) dlsym(handle, "register_plugin");
    if (!func) {
        std::cerr << "Cannot find register_plugin function: " << dlerror() << std::endl;
        dlclose(handle);
        return;
    }

    func();
    dlclose(handle);
}