#include "example_public_private.hpp"
#include "private_example.hpp"
#include <iostream>

void example_public() {
    std::cout << "Public function example!\n";
    example_private();
}
