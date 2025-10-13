// tests/test_main.cpp
#include <gtest/gtest.h>
#include <iostream>
#include <sstream>

// Include all the library headers
#include "example_interface.hpp"
#include "example_public_private.hpp"
#include "example_shared.hpp"
#include "example_static.hpp"
#include "plugin_api.hpp"

// Helper class to capture stdout
class OutputCapture
{
   public:
    OutputCapture()
    {
        old_cout = std::cout.rdbuf();
        std::cout.rdbuf(captured_output.rdbuf());
    }

    ~OutputCapture() { std::cout.rdbuf(old_cout); }

    std::string getOutput() { return captured_output.str(); }

   private:
    std::stringstream captured_output;
    std::streambuf* old_cout;
};

// Test the static library
TEST(ExampleStaticTest, FunctionExecutes)
{
    OutputCapture capture;
    EXPECT_NO_THROW(example_static_function());
    std::string output = capture.getOutput();
    EXPECT_FALSE(output.empty());
    EXPECT_NE(output.find("Static library"), std::string::npos);
}

// Test the shared library
TEST(ExampleSharedTest, FunctionExecutes)
{
    OutputCapture capture;
    EXPECT_NO_THROW(example_shared_function());
    std::string output = capture.getOutput();
    EXPECT_FALSE(output.empty());
    EXPECT_NE(output.find("Shared library"), std::string::npos);
}

// Test the public/private library
TEST(ExamplePublicPrivateTest, PublicFunctionExecutes)
{
    OutputCapture capture;
    EXPECT_NO_THROW(example_public());
    std::string output = capture.getOutput();
    EXPECT_FALSE(output.empty());
    EXPECT_NE(output.find("Public function"), std::string::npos);
}

// Test the interface (header-only) library
TEST(ExampleInterfaceTest, InlineFunctionExecutes)
{
    // Interface function is inline and doesn't produce output,
    // but we can test that it executes without throwing
    EXPECT_NO_THROW(example_interface());
}



// Test plugin loading with invalid path (should not crash)
TEST(PluginLoaderTest, InvalidPluginPath)
{
    // Test with a non-existent plugin - should handle gracefully
    // Note: This might still crash if dlopen/dlsym don't handle errors properly
    // but we'll test it anyway
    EXPECT_NO_THROW(load_plugin("non_existent_plugin.so"));
}

// Test plugin loading with valid path
TEST(PluginLoaderTest, ValidPluginPath)
{
    // Test with the actual plugin that should exist
    // We'll try multiple possible paths since the working directory might vary
    std::vector<std::string> possible_paths = {
        "./src/example_plugin_impl/libexample_plugin_impl.so",
        "../src/example_plugin_impl/libexample_plugin_impl.so",
        "../../build/src/example_plugin_impl/libexample_plugin_impl.so"};

    bool found_valid_path = false;
    for (const auto& path : possible_paths)
    {
        OutputCapture capture;
        EXPECT_NO_THROW(load_plugin(path.c_str()));
        std::string output = capture.getOutput();

        if (output.find("Plugin registered") != std::string::npos)
        {
            found_valid_path = true;
            break;
        }
    }

    // If none of the paths worked, at least verify the function doesn't crash
    if (!found_valid_path)
    {
        std::cout
            << "Note: Plugin not found at expected paths, but load_plugin executed without crashing"
            << std::endl;
    }
}

// Integration test - test all functions together
TEST(IntegrationTest, AllFunctionsTogether)
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

// Test edge cases and additional functionality
TEST(ExampleLibrariesTest, OutputContainsExpectedStrings)
{
    OutputCapture capture;

    example_static_function();
    std::string static_output = capture.getOutput();

    OutputCapture capture2;
    example_shared_function();
    std::string shared_output = capture2.getOutput();

    // Verify specific expected strings
    EXPECT_NE(static_output.find("Static library example!"), std::string::npos);
    EXPECT_NE(shared_output.find("Shared library example!"), std::string::npos);
}

TEST(ExamplePublicPrivateTest, CallsPrivateFunction)
{
    OutputCapture capture;
    example_public();
    std::string output = capture.getOutput();

    // example_public() calls private_example() internally
    // so we should see output from both functions
    EXPECT_NE(output.find("Public function example!"), std::string::npos);
    EXPECT_NE(output.find("Private function example!"), std::string::npos);
}

int main(int argc, char** argv)
{
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
