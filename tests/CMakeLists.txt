add_executable(unit_tests
    test_example_static.cpp
    test_example_shared.cpp
    test_example_public_private.cpp
    test_example_interface.cpp
    test_example_usage.cpp
    test_plugin_loader.cpp
    test_integration.cpp
)

target_include_directories(unit_tests PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(unit_tests PRIVATE
    example_public_private
    example_usage
    example_static
    example_shared
    example_plugin_loader
    example_plugin_impl
    GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(unit_tests)
