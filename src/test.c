#include <stdio.h>
#include <stdint.h>

void c_test() {
    printf("Hello from C\n");
}

typedef struct TestStruct {
    uint64_t data;
} TestStruct;

extern void use_test(TestStruct *ts);

void c_use_test(TestStruct *const ts) {
    printf("From c calling use test:\n");
    use_test(ts);
}