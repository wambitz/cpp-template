// tests/test_main.cpp
#include <gtest/gtest.h>

TEST(StringUtilTest, BasicCheck)
{
    EXPECT_EQ(1 + 1, 2);
}

int main(int argc, char** argv)
{
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
