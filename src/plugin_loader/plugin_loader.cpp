#include <dlfcn.h>

#include <iostream>

#include "plugin_api.hpp"

void load_plugin(const char* lib)
{
    void* handle = dlopen(lib, RTLD_LAZY);
    auto func = (void (*)()) dlsym(handle, "register_plugin");
    func();
    dlclose(handle);
}