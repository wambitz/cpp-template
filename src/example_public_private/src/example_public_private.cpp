#include "example_public_private.hpp"

#include <iostream>

#include "private_example.hpp"

void example_public() {
    std::cout << "Public function example!\n";
    example_private();
}
