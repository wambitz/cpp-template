#include <gtest/gtest.h>
#include "example_shared.hpp"
#include "test_helpers.hpp"

class ExampleSharedTest : public ::testing::Test
{
   protected:
    void SetUp() override
    {
        // Setup code if needed
    }

    void TearDown() override
    {
        // Cleanup code if needed
    }
};

TEST_F(ExampleSharedTest, FunctionExecutes)
{
    OutputCapture capture;
    EXPECT_NO_THROW(example_shared_function());
    std::string output = capture.getOutput();
    EXPECT_FALSE(output.empty());
    EXPECT_NE(output.find("Shared library"), std::string::npos);
}

TEST_F(ExampleSharedTest, OutputContainsExpectedString)
{
    OutputCapture capture;
    example_shared_function();
    std::string output = capture.getOutput();

    // Verify specific expected string
    EXPECT_NE(output.find("Shared library example!"), std::string::npos);
}

TEST_F(ExampleSharedTest, FunctionProducesConsistentOutput)
{
    OutputCapture capture1;
    example_shared_function();
    std::string output1 = capture1.getOutput();

    OutputCapture capture2;
    example_shared_function();
    std::string output2 = capture2.getOutput();

    // Both calls should produce the same output
    EXPECT_EQ(output1, output2);
    EXPECT_FALSE(output1.empty());
}
