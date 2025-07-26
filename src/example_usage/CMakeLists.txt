add_library(example_usage
    src/example_usage.cpp
)

target_include_directories(example_usage PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

target_link_libraries(example_usage
    PUBLIC example_public_private
    PUBLIC example_interface
)
