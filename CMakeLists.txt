cmake_minimum_required(VERSION 3.16)

# ---------------------------------------------------------------
# Project meta
project(cpp_project_template LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


# Your regular libraries / executables
add_subdirectory(src/libstatic)
add_subdirectory(src/libshared)
add_subdirectory(src/plugin_loader)
add_subdirectory(src/plugin_impl)
add_subdirectory(src/main)

# ---------------------------------------------------------------
# =====  UNIT-TEST OPTION  =====
include(CTest)
option(ENABLE_UNIT_TESTS "Build unit tests with GoogleTest" ${BUILD_TESTING})

if(ENABLE_UNIT_TESTS)
    find_package(GTest CONFIG QUIET)
    if(NOT GTest_FOUND)
        include(FetchContent)
        FetchContent_Declare(
            googletest
            URL https://github.com/google/googletest/archive/v1.14.0.zip
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE   # <- fixes CMP0135 warning
        )
        FetchContent_MakeAvailable(googletest)
    endif()

    add_subdirectory(tests)
endif()

# ---------------------------------------------------------------
