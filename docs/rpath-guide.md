# RPATH Guide: Runtime Library Discovery

This guide explains RPATH implementation in this C++ project template, including configuration, usage patterns, and troubleshooting.

## RPATH Overview

RPATH (Runtime Path) specifies library search paths embedded directly in executable files. This mechanism enables the dynamic linker to locate shared libraries at runtime without relying on system-wide configuration or environment variables.

## Problem Statement

### Default Library Search Order

When executing a binary, the dynamic linker searches for shared libraries in the following order:

1. Directories in LD_LIBRARY_PATH environment variable
2. System directories (/lib, /usr/lib, /usr/local/lib)
3. Paths specified in /etc/ld.so.conf

### Challenge

Project-specific shared libraries located outside standard system directories (e.g., ../lib relative to the executable) are not automatically discovered.

### Traditional Approaches and Limitations

```bash
# Approach 1: Environment variable configuration
export LD_LIBRARY_PATH=/path/to/lib:$LD_LIBRARY_PATH
./main_exec

# Approach 2: System directory installation
sudo cp lib*.so /usr/local/lib/

# Approach 3: Absolute path specification
dlopen("/absolute/path/to/plugin.so", RTLD_LAZY);
```

Limitations:
- Approach 1: Fragile, requires per-session configuration
- Approach 2: Pollutes system directories, requires administrative privileges
- Approach 3: Non-portable, breaks when installation paths change

### RPATH Solution

RPATH embeds library search paths directly in the executable, creating self-contained, portable binaries that function independently of environment configuration.

## RPATH Syntax

### Special Variables

- `$ORIGIN`: Directory containing the executable (resolved at runtime)
- `$LIB`: Platform-specific library directory (e.g., lib64 on some systems)

### Common Patterns

```cmake
# Libraries in same directory as executable
set(CMAKE_INSTALL_RPATH "$ORIGIN")

# Libraries in ../lib relative to executable
set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")

# Multiple search paths
set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib:$ORIGIN")
```

## Project Implementation

### Directory Structure

```
package/
├── bin/
│   └── main_exec          (RPATH: $ORIGIN/../lib)
└── lib/
    ├── libexample_shared.so       (Linked at compile time)
    └── libexample_plugin_impl.so  (Loaded at runtime via dlopen)
```

### CMake Configuration

```cmake
# In src/main/CMakeLists.txt
set_target_properties(main_exec PROPERTIES
    # Development builds (relative to build directory)
    BUILD_RPATH "${CMAKE_BINARY_DIR}/lib"
    
    # Installed builds (relative to installation directory)
    INSTALL_RPATH "$ORIGIN/../lib"
    
    # Use BUILD_RPATH during development
    BUILD_WITH_INSTALL_RPATH OFF
)
```

### Runtime Behavior

#### Compile-Time Linked Libraries

```cpp
// In main.cpp
#include "example_shared.hpp"
int main() {
    example_shared::greet();
}
```

Execution sequence:
1. Dynamic linker reads RPATH from executable: `$ORIGIN/../lib`
2. Resolves `$ORIGIN` to `/path/to/package/bin`
3. Searches for `libexample_shared.so` in `/path/to/package/lib`
4. Loads library

#### Runtime Plugin Loading

```cpp
// In plugin_loader.cpp
void* handle = dlopen("libexample_plugin_impl.so", RTLD_LAZY);
```

Execution sequence:
1. dlopen respects RPATH from calling executable
2. Searches in `$ORIGIN/../lib` = `/path/to/package/lib`
3. Loads `libexample_plugin_impl.so`

## Build Environments

### Development Build

```
build/
├── main_exec              (BUILD_RPATH: ./lib)
├── lib/
│   ├── libexample_shared.so
│   └── libexample_plugin_impl.so  (Copied by CMake)
└── src/example_plugin_impl/
    └── libexample_plugin_impl.so   (Original location)
```

### Installation

```
install/
├── bin/
│   └── main_exec          (INSTALL_RPATH: $ORIGIN/../lib)
└── lib/
    ├── libexample_shared.so
    └── libexample_plugin_impl.so
```

## Verification

### RPATH Inspection

```bash
readelf -d build/main_exec | grep -E "(RPATH|RUNPATH)"
```

or

```bash
objdump -x build/main_exec | grep -E "(RPATH|RUNPATH)"
```

Expected output:
```
0x000000000000000f (RPATH) Library rpath: [$ORIGIN/../lib]
```

### Library Resolution

```bash
ldd build/main_exec
```

### Runtime Trace

```bash
LD_DEBUG=libs ./build/main_exec 2>&1 | grep -E "(search|trying)"
```

## Configuration Patterns

### Pattern 1: Collocated Libraries

```cmake
set(CMAKE_INSTALL_RPATH "$ORIGIN")
```

```
package/
├── app_exec
├── libfoo.so
└── libbar.so
```

### Pattern 2: Standard Unix Layout

```cmake
set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")
```

```
package/
├── bin/app_exec
└── lib/
    ├── libfoo.so
    └── libbar.so
```

### Pattern 3: Multiple Search Paths

```cmake
set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib:$ORIGIN/../plugins:$ORIGIN")
```

```
package/
├── bin/app_exec
├── lib/libcore.so
├── plugins/libplugin.so
└── bin/libutils.so
```

## Best Practices

### Recommended

- Use `$ORIGIN` for portable, relocatable packages
- Configure both `BUILD_RPATH` and `INSTALL_RPATH`
- Test packages across different systems
- Prefer relative paths in RPATH

### Not Recommended

- Hardcoding absolute paths in RPATH
- Relying on `LD_LIBRARY_PATH` for production deployments
- Installing libraries to system directories
- Using RPATH for system libraries (already in standard locations)

## Troubleshooting

### Library Not Found

```
error while loading shared libraries: libexample_shared.so: cannot open shared object file
```

Diagnostic steps:
1. Verify RPATH: `readelf -d main_exec | grep RPATH`
2. Confirm library exists: `ls -la lib/libexample_shared.so`
3. Check permissions: `file lib/libexample_shared.so`
4. Trace loading: `LD_DEBUG=libs ./main_exec`

### Plugin Loading Failure

```cpp
void* handle = dlopen("libplugin.so", RTLD_LAZY);
if (!handle) {
    std::cerr << "dlopen error: " << dlerror() << std::endl;
}
```

Diagnostic steps:
1. Verify plugin presence in RPATH directories
2. Check plugin dependencies: `ldd lib/libplugin.so`
3. Verify exported symbols: `nm -D lib/libplugin.so`

## References

- [Linux Manual: ld.so(8)](https://man7.org/linux/man-pages/man8/ld.so.8.html)
- [CMake RPATH Handling](https://cmake.org/Wiki/CMake_RPATH_handling)
- [Shared Libraries Guide](https://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html)
