# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
./scripts/build.sh                              # Debug build with tests enabled
./scripts/test.sh                                # Run all tests
./scripts/package.sh                             # Release build + CPack packaging
./scripts/format.sh                              # Apply clang-format
./scripts/format.sh --check                      # Verify formatting (CI mode)
./scripts/lint.sh                                # Run clang-tidy (build first — needs compile_commands.json)
./scripts/coverage.sh                            # Generate lcov coverage report
./scripts/docs.sh                                # Generate Doxygen documentation
```

Pre-commit hooks run on **pre-push** (not pre-commit): `pre-commit install --hook-type pre-push`

All scripts auto-delegate to Docker when run outside the container (`docker run --rm`). The delegation logic lives in `scripts/docker/exec.sh`, sourced by each script via `scripts/env.sh`. Inside the container or CI (`CI=true`), scripts run directly with no overhead. See `docs/ci-container-delegation.md` for details on the CI strategy and a GHCR upgrade path.

## Architecture

This is a C++ project template using **CMake >= 3.20** and **C++17**. Each build target lives in its own `src/<name>/` subdirectory with its own `CMakeLists.txt`, registered via `add_subdirectory()` in the root CMakeLists.txt.

The template demonstrates four library patterns that build on each other:

- **Static library** (`example_static`) — simplest case, compiled and linked at build time
- **Shared library** (`example_shared`) — uses RPATH (`$ORIGIN/../lib`) so the binary finds `.so` files relative to itself at runtime, making the install relocatable
- **Interface library** (`example_interface`) — header-only, no compiled output; uses `INTERFACE` visibility so dependents get the include paths automatically
- **Public/Private visibility** (`example_public_private`) — demonstrates how `PUBLIC` includes propagate to dependents while `PRIVATE` includes stay internal

The **plugin system** (`example_plugin_loader` + `example_plugin_impl`) shows runtime loading via `dlopen()`. Plugins implement a C-compatible API defined in `plugin_api.hpp` and must export `create_plugin()` as `extern "C"`. The loader discovers plugin `.so` files via RPATH.

The main executable (`src/main/`) links against all libraries and demonstrates their usage together.

Tests use **GoogleTest v1.14.0** (fetched via `FetchContent`). Test files follow the pattern `tests/test_<target_name>.cpp` and are discovered via `gtest_discover_tests()`. The `tests/test_helpers.hpp` provides an `OutputCapture` utility for testing stdout.

## Code Style

Enforced by `.clang-format` and `.clang-tidy` — CI rejects non-conforming code.

- Google C++ style base, **4-space indent**, **100-char column limit**, K&R braces
- Pointer alignment: left (`int* ptr`)
- Naming: `lower_case` for variables/members, `CamelCase` for classes/structs
- Headers use `#pragma once` (not traditional include guards)
- Includes: sorted and grouped (main header, then system, then project)
- Use `target_include_directories` and `target_link_libraries` with correct CMake visibility (PUBLIC/PRIVATE/INTERFACE) — never raw compiler/linker flags
- Shared libraries must configure RPATH — never hardcode absolute paths
