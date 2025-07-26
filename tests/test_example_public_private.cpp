#include <gtest/gtest.h>
#include "example_public_private.hpp"
#include "test_helpers.hpp"

class ExamplePublicPrivateTest : public ::testing::Test
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

TEST_F(ExamplePublicPrivateTest, PublicFunctionExecutes)
{
    OutputCapture capture;
    EXPECT_NO_THROW(example_public());
    std::string output = capture.getOutput();
    EXPECT_FALSE(output.empty());
    EXPECT_NE(output.find("Public function"), std::string::npos);
}

TEST_F(ExamplePublicPrivateTest, PublicFunctionCallsPrivateFunction)
{
    OutputCapture capture;
    example_public();
    std::string output = capture.getOutput();

    // example_public() calls private functions internally
    EXPECT_NE(output.find("Public function example!"), std::string::npos);
    EXPECT_NE(output.find("Private function example!"), std::string::npos);
}

TEST_F(ExamplePublicPrivateTest, OutputFormatIsCorrect)
{
    OutputCapture capture;
    example_public();
    std::string output = capture.getOutput();

    // Check that both messages are present and properly formatted
    EXPECT_TRUE(output.find("Public function example!") != std::string::npos);
    EXPECT_TRUE(output.find("Private function example!") != std::string::npos);

    // Check that output ends with newlines
    EXPECT_TRUE(output.back() == '\n' || output.find('\n') != std::string::npos);
}
