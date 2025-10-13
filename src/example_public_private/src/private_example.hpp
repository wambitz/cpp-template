#pragma once

// This is a PRIVATE header (in src/ directory)
// Only code INSIDE example_public_private can include this file
// External targets (like main.cpp) CANNOT include this - it will fail to compile!

void example_private();
