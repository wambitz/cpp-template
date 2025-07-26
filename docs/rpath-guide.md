# RPATH Guide: Understanding Runtime Library Discovery

This guide explains how RPATH works in this C++ project template, with practical examples and beginner-friendly explanations.

## What is RPATH?

**RPATH** (Runtime Path) is a mechanism that tells your executable where to find shared libraries at runtime. Think of it as "GPS coordinates" embedded directly in your executable that point to library locations.

## The Problem RPATH Solves

### Without RPATH
When you run `./main_exec`, the system looks for shared libraries like `libexample_shared.so` in these locations (in order):

1. System directories (`/lib/`, `/usr/lib/`, `/usr/local/lib/`)
2. Directories listed in `LD_LIBRARY_PATH` environment variable
3. Current working directory (sometimes)

**Problem**: Your custom libraries are in `../lib/` relative to your executable, not in these standard locations!

### Traditional "Solutions" and Their Problems
```bash
# Option 1: Set LD_LIBRARY_PATH (fragile)
export LD_LIBRARY_PATH=/path/to/your/lib:$LD_LIBRARY_PATH
./main_exec

# Option 2: Copy libraries to system dirs (pollutes system)
sudo cp lib*.so /usr/local/lib/

# Option 3: Hardcode absolute paths (not portable)
dlopen("/absolute/path/to/plugin.so", RTLD_LAZY);
```

### RPATH Solution
RPATH embeds the library search path directly in the executable, making it self-contained and portable.

## RPATH Syntax

### Special Variables
- **`$ORIGIN`**: The directory containing the executable (resolved at runtime)
- **`$LIB`**: Platform-specific lib directory (lib64 on some systems)

### Common Patterns
```cmake
# Libraries in same directory as executable
set(CMAKE_INSTALL_RPATH "$ORIGIN")

# Libraries in ../lib relative to executable
set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")

# Multiple search paths
set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib:$ORIGIN")
```

## How This Project Uses RPATH

### Project Structure
```
package/
├── bin/
│   └── main_exec          ← Executable with RPATH: $ORIGIN/../lib
└── lib/
    ├── libexample_shared.so       ← Linked at compile time
    └── libexample_plugin_impl.so  ← Loaded at runtime via dlopen()
```

### CMake Configuration
```cmake
# In src/main/CMakeLists.txt
set_target_properties(main_exec PROPERTIES
    # For development builds (relative to build directory)
    BUILD_RPATH "${CMAKE_BINARY_DIR}/lib"
    
    # For installed builds (relative to installation)
    INSTALL_RPATH "$ORIGIN/../lib"
    
    # Use RPATH for both build and install
    BUILD_WITH_INSTALL_RPATH OFF
)
```

### Runtime Behavior

#### 1. Compile-time Linked Libraries
```cpp
// In main.cpp - automatically found via RPATH
#include "example_shared.hpp"
int main() {
    example_shared::greet();  // Library found automatically
}
```

When you run `./bin/main_exec`:
1. System reads RPATH from executable: `$ORIGIN/../lib`
2. Resolves `$ORIGIN` to `/path/to/package/bin`
3. Searches for `libexample_shared.so` in `/path/to/package/lib`
4. Loads library automatically

#### 2. Runtime Plugin Loading
```cpp
// In plugin_loader.cpp - dlopen() respects RPATH
void* handle = dlopen("libexample_plugin_impl.so", RTLD_LAZY);
```

When `dlopen()` is called:
1. System checks RPATH from the calling executable
2. Searches in `$ORIGIN/../lib` = `/path/to/package/lib`
3. Finds and loads `libexample_plugin_impl.so`

## Development vs Installation

### Development Build (build/)
```
build/
├── main_exec              ← BUILD_RPATH: ./lib
├── lib/
│   ├── libexample_shared.so
│   └── libexample_plugin_impl.so  ← Copied here by CMake
└── src/example_plugin_impl/
    └── libexample_plugin_impl.so   ← Original location
```

### Installed Package
```
install/
├── bin/
│   └── main_exec          ← INSTALL_RPATH: $ORIGIN/../lib
└── lib/
    ├── libexample_shared.so
    └── libexample_plugin_impl.so
```

## Verifying RPATH

### Check RPATH in Executable
```bash
# View RPATH
readelf -d build/main_exec | grep -E "(RPATH|RUNPATH)"
# or
objdump -x build/main_exec | grep -E "(RPATH|RUNPATH)"

# Expected output:
# 0x000000000000000f (RPATH) Library rpath: [$ORIGIN/../lib]
```

### Test Library Loading
```bash
# See which libraries are loaded
ldd build/main_exec

# Trace library loading at runtime
LD_DEBUG=libs ./build/main_exec 2>&1 | grep -E "(search|trying)"
```

## Common RPATH Patterns

### Pattern 1: Libraries in Same Directory
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

### ✅ Do
- Use `$ORIGIN` for portable, relocatable packages
- Set both `BUILD_RPATH` and `INSTALL_RPATH` appropriately
- Test your packages on different systems
- Use relative paths in RPATH when possible

### ❌ Don't
- Hardcode absolute paths in RPATH
- Rely on `LD_LIBRARY_PATH` for production deployments
- Copy libraries to system directories
- Use RPATH for system libraries (they're already in standard locations)

## Troubleshooting

### Library Not Found
```
./main_exec: error while loading shared libraries: libexample_shared.so: cannot open shared object file
```

**Debug steps:**
1. Check RPATH: `readelf -d main_exec | grep RPATH`
2. Verify library exists: `ls -la lib/libexample_shared.so`
3. Check permissions: `file lib/libexample_shared.so`
4. Trace loading: `LD_DEBUG=libs ./main_exec`

### Plugin Loading Fails
```cpp
// dlopen() returns NULL
void* handle = dlopen("libplugin.so", RTLD_LAZY);
if (!handle) {
    std::cerr << "dlopen error: " << dlerror() << std::endl;
}
```

**Debug steps:**
1. Verify plugin exists in RPATH directories
2. Check plugin dependencies: `ldd lib/libplugin.so`
3. Ensure plugin exports expected symbols: `nm -D lib/libplugin.so`

## Further Reading

- [Linux man page: ld.so(8)](https://man7.org/linux/man-pages/man8/ld.so.8.html)
- [CMake RPATH Documentation](https://cmake.org/Wiki/CMake_RPATH_handling)
- [Shared Libraries Best Practices](https://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html)
