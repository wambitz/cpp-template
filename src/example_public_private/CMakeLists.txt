add_library(example_public_private
    src/example_public_private.cpp
    src/private_example.cpp
)

target_include_directories(example_public_private
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
)
