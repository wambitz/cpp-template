add_library(example_public_private
    src/example_public_private.cpp
    src/private_example.cpp
)

# Demonstrates PUBLIC vs PRIVATE include directories:
#
# PUBLIC  = ${CMAKE_CURRENT_SOURCE_DIR}/include
#   - Headers here CAN be included by targets linking to this library
#   - Example: main.cpp can do #include "example_public_private.hpp"
#   - Used for the library's API/interface
#
# PRIVATE = ${CMAKE_CURRENT_SOURCE_DIR}/src  
#   - Headers here are INTERNAL ONLY - cannot be accessed by consumers
#   - Example: main.cpp CANNOT do #include "private_example.hpp" (compile error!)
#   - Used for implementation details
#
# This separation enforces encapsulation at build time!
# For detailed explanation, see: docs/public-private-guide.md
target_include_directories(example_public_private
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
)
