# Copilot Instructions

This is a modern C++ project template using CMake >= 3.20 and C++17.

## Code Style

- Follow Google C++ style with 4-space indentation and 100-character column limit
- Variables, locals, and members use `lower_case` naming
- Classes and structs use `CamelCase` naming
- Pointer alignment is left: `int* ptr` not `int *ptr`
- Brace style: K&R (attach opening brace to statement)
- Include sorting: main header first, then system headers, then project headers, separated by blank lines

## Project Architecture

- Each build target has its own subdirectory under `src/` with its own `CMakeLists.txt`
- Tests go in `tests/test_<target_name>.cpp` using GoogleTest (GTest)
- Use `target_include_directories` and `target_link_libraries` with correct CMake visibility keywords (PUBLIC, PRIVATE, INTERFACE)
- Shared libraries use RPATH (`$ORIGIN/../lib`) for portable deployment
- Plugins use a C-compatible API with `extern "C"` exported factory functions

## Build & Test

- Build: `./scripts/build.sh` or `mkdir -p build && cd build && cmake .. && make`
- Test: `cd build && ctest --output-on-failure`
- Format: `./scripts/format.sh`
- Lint: `./scripts/lint.sh` (requires build first for compile_commands.json)

## Conventions

- Always use CMake target properties instead of raw compiler/linker flags
- Use `#pragma once` for header guards
- New libraries: create `src/<name>/CMakeLists.txt`, add via `add_subdirectory()` in root CMakeLists.txt
- New tests: create `tests/test_<name>.cpp`, register in `tests/CMakeLists.txt` with `gtest_discover_tests()`
- Plugin implementations must export `register_plugin()` as `extern "C"`
