// Version: 1.1.0

#include <stdio.h>
#include "vendor/unity.h"

extern int identity(int x);

void setUp(void) {
    /* Emit 30 lines * 21 chars = 630 chars of output before the test runs,
       so the parser's truncate() path is exercised. */
    for (int i = 0; i < 30; ++i) {
        printf("0123456789abcdef0123\n");
    }
}

void tearDown(void) {
}

void test_identity(void) {
    TEST_ASSERT_EQUAL_INT(42, identity(42));
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_identity);
    return UNITY_END();
}
