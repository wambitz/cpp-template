# ── CMakeLists.txt (top level) ────────────────────────────────────────────────
cmake_minimum_required(VERSION 3.20)                 # 3.20+ for gtest_discover_tests niceties

project(cpp_project_template
        VERSION 0.1.0
        LANGUAGES CXX)

# ── Global compiler defaults (but avoid leaking flags) ───────────────────────
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)                # helps clang-tools; optional

# Set RPATH settings for installed binaries
set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)  # Use different RPATH for build vs install

# -----------------------------------------------------------------------------
# Coverage option
# -----------------------------------------------------------------------------
option(ENABLE_COVERAGE "Enable code coverage" OFF)

if(ENABLE_COVERAGE)
    message(STATUS "Code coverage enabled")
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} --coverage")
    else()
        message(WARNING "Code coverage only supported with GCC")
    endif()
endif()

# -----------------------------------------------------------------------------
# 1. Primary code
# -----------------------------------------------------------------------------

add_subdirectory(src/example_public_private)
add_subdirectory(src/example_interface)
add_subdirectory(src/example_usage)
add_subdirectory(src/example_static)
add_subdirectory(src/example_shared)
add_subdirectory(src/example_plugin_loader)
add_subdirectory(src/example_plugin_impl)
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
        
        # Prevent GoogleTest from being installed
        set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
        set(INSTALL_GMOCK OFF CACHE BOOL "" FORCE)
        
        FetchContent_Declare(
            googletest
            URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE     # <- fixes CMP0135 warning
        )
        FetchContent_MakeAvailable(googletest)  # exports GTest::gtest / gtest_main
    endif()

    add_subdirectory(tests)
endif()

# Install rules - only install shippable/runtime components
install(TARGETS main_exec
    RUNTIME DESTINATION bin)

# Install shared libraries (needed at runtime)
install(TARGETS example_shared example_plugin_impl
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin)

# Note: Static libraries and headers are typically not installed unless
# this project is meant to be a library package for other developers.
# Uncomment the lines below if you want to ship a development package:
#
# install(TARGETS example_static example_plugin_loader
#     ARCHIVE DESTINATION lib)
# install(DIRECTORY src/example_public_private/include/
#     DESTINATION include/example_public_private)
# install(DIRECTORY src/example_interface/include/
#     DESTINATION include/example_interface)
# install(DIRECTORY src/example_usage/include/
#     DESTINATION include/example_usage)
# install(DIRECTORY src/example_static/
#     DESTINATION include/example_static
#     FILES_MATCHING PATTERN "*.hpp")
# install(DIRECTORY src/example_shared/
#     DESTINATION include/example_shared
#     FILES_MATCHING PATTERN "*.hpp")
# install(DIRECTORY src/example_plugin_loader/
#     DESTINATION include/example_plugin_loader
#     FILES_MATCHING PATTERN "*.hpp")
# install(DIRECTORY src/example_plugin_impl/
#     DESTINATION include/example_plugin_impl
#     FILES_MATCHING PATTERN "*.hpp")
