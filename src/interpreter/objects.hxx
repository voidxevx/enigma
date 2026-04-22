#ifndef INTERPRETER_OBJECTS_BRIDGE
#define INTERPRETER_OBJECTS_BRIDGE

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

union Object {
    int32_t _int;
    uint32_t _uint;
    int64_t _long;
    uint64_t _ulong;
    float _float;
    double _double;
};

#ifdef __cplusplus
}
#endif
#endif