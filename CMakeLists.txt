# ── CMakeLists.txt (top level) ────────────────────────────────────────────────
cmake_minimum_required(VERSION 3.20)                 # 3.20+ for gtest_discover_tests niceties

project(cpp_project_template
        VERSION 0.1.0
        LANGUAGES CXX)

# ── Global compiler defaults (but avoid leaking flags) ───────────────────────
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)                # helps clang-tools; optional

# -----------------------------------------------------------------------------
# 1. Primary code
# -----------------------------------------------------------------------------
add_subdirectory(src/libstatic)
add_subdirectory(src/libshared)
add_subdirectory(src/plugin_loader)
add_subdirectory(src/plugin_impl)
add_subdirectory(src/main)                           # -> target "main_exec" etc.

# -----------------------------------------------------------------------------
# 2. Unit-test toggle
# -----------------------------------------------------------------------------
option(ENABLE_UNIT_TESTS "Build GoogleTest unit tests" ON)

if(ENABLE_UNIT_TESTS)
    enable_testing()  # Makes ctest happy to find the tests

    include(FetchContent)
    # First try system / package-manager copy; fall back to FetchContent
    find_package(GTest CONFIG QUIET)
    if(NOT GTest_FOUND)
        message(STATUS "GTest not found, fetching google test v1.14.0")
        FetchContent_Declare(
            googletest
            URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE     # <- fixes CMP0135 warning
        )
        FetchContent_MakeAvailable(googletest)  # exports GTest::gtest / gtest_main
    endif()

    add_subdirectory(tests)
endif()
