#include <gtest/gtest.h>
#include "example_usage.hpp"
#include "test_helpers.hpp"

class ExampleUsageTest : public ::testing::Test
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

TEST_F(ExampleUsageTest, FunctionExecutes)
{
    OutputCapture capture;
    EXPECT_NO_THROW(example_usage());
    std::string output = capture.getOutput();
    EXPECT_FALSE(output.empty());
    EXPECT_NE(output.find("Usage example"), std::string::npos);
}

TEST_F(ExampleUsageTest, CallsOtherFunctions)
{
    OutputCapture capture;
    example_usage();
    std::string output = capture.getOutput();

    // example_usage calls example_public() and example_interface()
    // so we should see those outputs too
    EXPECT_NE(output.find("Usage example!"), std::string::npos);
    EXPECT_NE(output.find("Public function example!"), std::string::npos);
}

TEST_F(ExampleUsageTest, OutputContainsAllExpectedElements)
{
    OutputCapture capture;
    example_usage();
    std::string output = capture.getOutput();

    // Check for all expected output elements from the usage function
    EXPECT_NE(output.find("Usage example!"), std::string::npos);
    EXPECT_NE(output.find("Public function example!"), std::string::npos);
    EXPECT_NE(output.find("Private function example!"), std::string::npos);

    // Verify the output is not empty and contains meaningful content
    EXPECT_FALSE(output.empty());
    EXPECT_GT(output.length(), 10);  // Should have substantial output
}

TEST_F(ExampleUsageTest, DemonstratesLibraryIntegration)
{
    // This test verifies that example_usage properly demonstrates
    // integration with other libraries in the project
    OutputCapture capture;

    EXPECT_NO_THROW(example_usage());

    std::string output = capture.getOutput();

    // Should contain evidence of calling multiple libraries
    int library_call_count = 0;
    if (output.find("Usage example") != std::string::npos)
        library_call_count++;
    if (output.find("Public function") != std::string::npos)
        library_call_count++;
    if (output.find("Private function") != std::string::npos)
        library_call_count++;

    EXPECT_GE(library_call_count, 2);  // Should call at least 2 other functions
}
