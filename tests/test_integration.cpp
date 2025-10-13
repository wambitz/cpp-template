#include <gtest/gtest.h>
#include "test_helpers.hpp"

// Include all library headers for integration testing
#include "example_interface.hpp"
#include "example_public_private.hpp"
#include "example_shared.hpp"
#include "example_static.hpp"

class IntegrationTest : public ::testing::Test
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

TEST_F(IntegrationTest, AllFunctionsTogether)
{
    OutputCapture capture;

    EXPECT_NO_THROW({
        example_static_function();
        example_shared_function();
        example_public();
        example_interface();
    });

    std::string output = capture.getOutput();
    EXPECT_FALSE(output.empty());

    // Check that all expected outputs are present
    EXPECT_NE(output.find("Static library"), std::string::npos);
    EXPECT_NE(output.find("Shared library"), std::string::npos);
    EXPECT_NE(output.find("Public function"), std::string::npos);
}

TEST_F(IntegrationTest, LibrariesWorkIndependently)
{
    // Test that each library works independently without interference

    // Test static library
    {
        OutputCapture capture;
        example_static_function();
        std::string output = capture.getOutput();
        EXPECT_NE(output.find("Static library example!"), std::string::npos);
    }

    // Test shared library
    {
        OutputCapture capture;
        example_shared_function();
        std::string output = capture.getOutput();
        EXPECT_NE(output.find("Shared library example!"), std::string::npos);
    }

    // Test public/private library
    {
        OutputCapture capture;
        example_public();
        std::string output = capture.getOutput();
        EXPECT_NE(output.find("Public function example!"), std::string::npos);
    }

    // Test interface (no output expected)
    EXPECT_NO_THROW(example_interface());
}

TEST_F(IntegrationTest, CrossLibraryDependencies)
{
    // Test that example_public_private correctly uses its private dependency
    OutputCapture capture;

    // example_public depends on private_example
    example_public();
    std::string output = capture.getOutput();

    // Should see output from both public and private functions
    EXPECT_NE(output.find("Public function example!"), std::string::npos);
    EXPECT_NE(output.find("Private function example!"), std::string::npos);
}

TEST_F(IntegrationTest, FullApplicationWorkflow)
{
    // Simulate the main application workflow
    OutputCapture capture;

    EXPECT_NO_THROW({
        // This mirrors what main.cpp does
        example_static_function();
        example_shared_function();
        example_public();
        example_interface();
    });

    std::string output = capture.getOutput();

    // Verify all expected components are present
    std::vector<std::string> expected_outputs = {
        "Static library example!", 
        "Shared library example!", 
        "Public function example!",
        "Private function example!"
    };

    for (const auto& expected : expected_outputs)
    {
        EXPECT_NE(output.find(expected), std::string::npos)
            << "Missing expected output: " << expected;
    }

    // Verify output has reasonable length (not empty, not too short)
    EXPECT_GT(output.length(), 50);
}
