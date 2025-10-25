#pragma once

#include <gtest/gtest.h>

#include <iostream>
#include <sstream>

// Helper class to capture stdout
class OutputCapture {
public:
    OutputCapture() {
        old_cout = std::cout.rdbuf();
        std::cout.rdbuf(captured_output.rdbuf());
    }

    ~OutputCapture() { std::cout.rdbuf(old_cout); }

    std::string getOutput() { return captured_output.str(); }

private:
    std::stringstream captured_output;
    std::streambuf* old_cout;
};
