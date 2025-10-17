# CMake Include Directory Visibility

This guide explains CMake's PUBLIC and PRIVATE visibility modifiers for include directories, as demonstrated in the `example_public_private` module.

## Directory Structure

```
example_public_private/
├── include/
│   └── example_public_private.hpp   # Public API header
└── src/
    ├── private_example.hpp           # Internal implementation header
    ├── private_example.cpp
    └── example_public_private.cpp
```

## Visibility Concepts

### PUBLIC Include Directories

Headers in `include/` constitute the library's public API and are accessible to consuming targets:

```cpp
// main.cpp (consumer code)
#include "example_public_private.hpp"  // Accessible
```

### PRIVATE Include Directories

Headers in `src/` are implementation details and not accessible to consuming targets:

```cpp
// main.cpp (consumer code)
#include "private_example.hpp"  // Compilation error
```

## CMake Configuration

```cmake
target_include_directories(example_public_private
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include   # Public API headers
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src      # Implementation headers
)
```

## Design Rationale

1. **Encapsulation**: Enforces separation between interface and implementation
2. **Dependency Management**: Consumers access only required components
3. **Build Optimization**: Modifications to PRIVATE headers do not trigger dependent target rebuilds
4. **API Clarity**: Explicitly defines public interface boundaries

## Dependency Propagation

When linking against a library using `target_link_libraries`:

```cmake
# In main/CMakeLists.txt
target_link_libraries(main_exec
    PRIVATE example_public_private
)
```

The compiler receives:
- PUBLIC include directories from `example_public_private`
- PRIVATE include directories are not propagated

## Usage Examples

### Within the Library

```cpp
// In src/example_public_private.cpp
#include "example_public_private.hpp"  // Accessible (PUBLIC)
#include "private_example.hpp"         // Accessible (PRIVATE - same target)
```

### In Consumer Code

```cpp
// In src/main/main.cpp
#include "example_public_private.hpp"  // Accessible (PUBLIC)
#include "private_example.hpp"         // Not accessible - compilation error
```

## Visibility Scope Reference

CMake supports three visibility levels:

### PRIVATE

- Visible only to the defining target
- Not propagated to dependent targets
- Use case: Implementation details, internal headers

### PUBLIC

- Visible to the defining target and all dependent targets
- Fully propagated through dependency chain
- Use case: Public API headers, required dependencies

### INTERFACE

- Not visible to the defining target
- Visible only to dependent targets
- Use case: Header-only libraries, transitive dependencies

## Propagation Model

```
Target A (library)          Target B (executable)
├─ PUBLIC includes     →    Visible to B
├─ PRIVATE includes    →    Not visible to B
└─ INTERFACE includes  →    Visible to B (not visible to A)
```

## Verification

To demonstrate visibility enforcement, attempt to include a private header in `src/main/main.cpp`:

```cpp
#include "private_example.hpp"
```

Expected compilation error:
```
fatal error: private_example.hpp: No such file or directory
```

This confirms that PRIVATE headers are correctly isolated from consuming targets.

## Best Practices

### Recommended Practices

- Place public API in `include/` with PUBLIC visibility
- Place implementation details in `src/` with PRIVATE visibility
- Use PUBLIC for dependencies referenced in public headers
- Use PRIVATE for dependencies used exclusively in implementation files

### Practices to Avoid

- Marking all include directories as PUBLIC without justification
- Mixing private and public headers in the same directory
- Using PUBLIC for implementation-only dependencies
- Exposing internal implementation details through public headers

## Implementation Patterns

### Pattern 1: Standard Library with Public API

```cmake
add_library(mylib
    src/mylib.cpp
    src/internal.cpp
)

target_include_directories(mylib
    PUBLIC  ${CMAKE_CURRENT_SOURCE_DIR}/include
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
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
    PUBLIC  nlohmann_json    # Required by public headers
    PRIVATE sqlite3          # Used only in implementation
)
```

## Diagnostics

### Inspecting Include Directories

```bash
cmake --build build --target help
cmake --build build --target mylib -- VERBOSE=1
```

### Common Error Messages

```
fatal error: some_header.hpp: No such file or directory
```

Potential causes:
- Header is PRIVATE but referenced from dependent target
- Missing `target_include_directories` directive
- Incorrect visibility level specification

## Installation Configuration

Standard library structure with install support:

```
mylib/
├── include/mylib/
│   ├── mylib.hpp
│   └── types.hpp
├── src/
│   ├── mylib.cpp
│   ├── internal.hpp
│   └── internal.cpp
└── CMakeLists.txt
```

CMakeLists.txt:
```cmake
target_include_directories(mylib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)
```

This configuration ensures:
- Consumers can include `<mylib/mylib.hpp>`
- `internal.hpp` remains inaccessible to consumers
- Correct behavior in both build tree and post-installation

## References

- [CMake target_include_directories](https://cmake.org/cmake/help/latest/command/target_include_directories.html)
- [CMake target_link_libraries](https://cmake.org/cmake/help/latest/command/target_link_libraries.html)
- [Effective Modern CMake](https://gist.github.com/mbinna/c61dbb39bca0e4fb7d1f73b0d66a4fd1)
