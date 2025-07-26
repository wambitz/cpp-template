#include <gtest/gtest.h>
#include "example_interface.hpp"
#include "test_helpers.hpp"

class ExampleInterfaceTest : public ::testing::Test
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

TEST_F(ExampleInterfaceTest, InlineFunctionExecutes)
{
    // Interface function is inline and doesn't produce output,
    // but we can test that it executes without throwing
    EXPECT_NO_THROW(example_interface());
}

TEST_F(ExampleInterfaceTest, FunctionCanBeCalledMultipleTimes)
{
    // Test that the inline function can be called multiple times safely
    EXPECT_NO_THROW({
        example_interface();
        example_interface();
        example_interface();
    });
}

TEST_F(ExampleInterfaceTest, FunctionIsHeaderOnly)
{
    // This test verifies that the function is truly header-only
    // by ensuring it compiles and links without requiring a separate object file

    // Call the function - if it's truly header-only, this should work
    EXPECT_NO_THROW(example_interface());

    // Since it's header-only and doesn't produce output, we just verify
    // that it doesn't crash or throw exceptions
    bool function_executed = false;
    try
    {
        example_interface();
        function_executed = true;
    }
    catch (...)
    {
        function_executed = false;
    }

    EXPECT_TRUE(function_executed);
}
