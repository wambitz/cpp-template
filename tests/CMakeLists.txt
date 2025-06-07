add_executable(unit_tests
    test_main.cpp
)

target_link_libraries(unit_tests PRIVATE
    math_utils
    string_utils
    plugin_loader
    my_plugin
    GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(unit_tests)
