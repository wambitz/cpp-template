# PUBLIC vs PRIVATE Include Directories

This guide explains CMake's `PUBLIC` and `PRIVATE` visibility for include directories, demonstrated by the `example_public_private` module.

## Directory Structure

```
example_public_private/
├── include/                          # PUBLIC headers (API)
│   └── example_public_private.hpp   # ✅ Can be included by consumers
└── src/                              # PRIVATE headers (implementation)
    ├── private_example.hpp           # ❌ Cannot be included by consumers
    ├── private_example.cpp
    └── example_public_private.cpp
```

## The Concept

### PUBLIC Include Directories
Headers in `include/` are **part of your library's public API**:
```cpp
// main.cpp (consumer code)
#include "example_public_private.hpp"  // ✅ Works! PUBLIC header
```

### PRIVATE Include Directories  
Headers in `src/` are **internal implementation details**:
```cpp
// main.cpp (consumer code)
#include "private_example.hpp"  // ❌ Compile error! PRIVATE header
```

## CMakeLists.txt Configuration

```cmake
target_include_directories(example_public_private
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include   # API headers
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src      # Internal headers
)
```

## Why This Matters

1. **Encapsulation**: Enforces separation between interface and implementation
2. **Dependency Management**: Consumers only get access to what they need
3. **Faster Recompilation**: Changes to PRIVATE headers don't trigger rebuilds of dependent targets
4. **Clear API Boundaries**: Makes it obvious what's part of your public API

## How It Works

When you use `target_link_libraries` to link against a library:

```cmake
# In main/CMakeLists.txt
target_link_libraries(main_exec
    PRIVATE example_public_private
)
```

The compiler automatically gets access to:
- ✅ **PUBLIC** include directories from `example_public_private`
- ❌ **PRIVATE** include directories are NOT passed through

## Example Usage

### Inside the Library
```cpp
// In src/example_public_private.cpp
#include "example_public_private.hpp"  // ✅ Works (PUBLIC)
#include "private_example.hpp"         // ✅ Works (PRIVATE - same target)
```

### In Consumer Code
```cpp
// In src/main/main.cpp
#include "example_public_private.hpp"  // ✅ Works (PUBLIC)
#include "private_example.hpp"         // ❌ Compiler cannot find this!
```

## Visibility Scopes Explained

CMake has three visibility levels:

### PRIVATE
- Only visible to the target itself
- Not propagated to consumers
- Use for: Implementation details, internal headers

### PUBLIC
- Visible to the target AND all consumers
- Fully propagated through the dependency chain
- Use for: Public API headers, required dependencies

### INTERFACE
- NOT visible to the target itself
- Only visible to consumers
- Use for: Header-only libraries, transitive dependencies

## Visual Example

```
Target A (library)          Target B (executable)
├─ PUBLIC includes     →    ✅ B can see these
├─ PRIVATE includes    →    ❌ B cannot see these
└─ INTERFACE includes  →    ✅ B can see these (but A cannot!)
```

## Try It Yourself

To see the difference in action, try adding this to `src/main/main.cpp`:

```cpp
#include "private_example.hpp"  // This will fail to compile!
```

You'll get an error like:
```
fatal error: private_example.hpp: No such file or directory
```

This is **intentional** - it proves that PRIVATE headers are truly private!

## Best Practices

### ✅ Do
- Put your public API in `include/` with PUBLIC visibility
- Put implementation details in `src/` with PRIVATE visibility
- Use PUBLIC for dependencies that appear in your public headers
- Use PRIVATE for dependencies only used in .cpp files

### ❌ Don't
- Make everything PUBLIC "just to be safe"
- Put private headers in the same directory as public ones
- Use PUBLIC for implementation-only dependencies
- Expose internal implementation details in public headers

## Common Patterns

### Pattern 1: Library with Public API
```cmake
add_library(mylib
    src/mylib.cpp
    src/internal.cpp
)

target_include_directories(mylib
    PUBLIC  ${CMAKE_CURRENT_SOURCE_DIR}/include  # Public API
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src      # Implementation
)
```

### Pattern 2: Header-Only Library
```cmake
add_library(mylib INTERFACE)

target_include_directories(mylib
    INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include
)
```

### Pattern 3: Library with Public Dependencies
```cmake
target_link_libraries(mylib
    PUBLIC  nlohmann_json    # Appears in public headers
    PRIVATE sqlite3          # Only used in .cpp files
)
```

## Debugging Visibility Issues

### Check what includes are propagated:
```bash
# Show the include directories for a target
cmake --build build --target help
cmake --build build --target mylib -- VERBOSE=1
```

### Common error messages:
```cpp
// If you see this:
fatal error: some_header.hpp: No such file or directory

// Possible causes:
// 1. Header is PRIVATE but you're trying to use it from another target
// 2. Missing target_include_directories
// 3. Wrong visibility level (should be PUBLIC)
```

## Real-World Example

A typical library structure:

```
mylib/
├── include/mylib/           # PUBLIC API
│   ├── mylib.hpp           # Main public header
│   └── types.hpp           # Public type definitions
├── src/                     # PRIVATE implementation
│   ├── mylib.cpp           # Implementation
│   ├── internal.hpp        # Private helpers
│   └── internal.cpp        # Private implementation
└── CMakeLists.txt

CMakeLists.txt:
target_include_directories(mylib
    PUBLIC  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:include>
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
)
```

This ensures:
- Consumers can `#include <mylib/mylib.hpp>`
- Consumers cannot see `internal.hpp`
- Works both in-tree and after installation

## Further Reading

- [CMake target_include_directories documentation](https://cmake.org/cmake/help/latest/command/target_include_directories.html)
- [CMake target_link_libraries documentation](https://cmake.org/cmake/help/latest/command/target_link_libraries.html)
- [Effective Modern CMake](https://gist.github.com/mbinna/c61dbb39bca0e4fb7d1f73b0d66a4fd1)
