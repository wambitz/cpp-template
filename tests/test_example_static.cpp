#include <gtest/gtest.h>

#include "example_static.hpp"
#include "test_helpers.hpp"

class ExampleStaticTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Setup code if needed
    }

    void TearDown() override {
        // Cleanup code if needed
    }
};

TEST_F(ExampleStaticTest, FunctionExecutes) {
    OutputCapture capture;
    EXPECT_NO_THROW(example_static_function());
    std::string output = capture.getOutput();
    EXPECT_FALSE(output.empty());
    EXPECT_NE(output.find("Static library"), std::string::npos);
}

TEST_F(ExampleStaticTest, OutputContainsExpectedString) {
    OutputCapture capture;
    example_static_function();
    std::string output = capture.getOutput();

    // Verify specific expected string
    EXPECT_NE(output.find("Static library example!"), std::string::npos);
}

TEST_F(ExampleStaticTest, FunctionCanBeCalledMultipleTimes) {
    OutputCapture capture;

    // Call the function multiple times
    EXPECT_NO_THROW(example_static_function());
    EXPECT_NO_THROW(example_static_function());
    EXPECT_NO_THROW(example_static_function());

    std::string output = capture.getOutput();

    // Should have output from all three calls
    size_t first_pos = output.find("Static library example!");
    EXPECT_NE(first_pos, std::string::npos);

    size_t second_pos = output.find("Static library example!", first_pos + 1);
    EXPECT_NE(second_pos, std::string::npos);
}
