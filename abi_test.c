#include <windows.h>
#include <setupapi.h>
#include <hidsdi.h>
#include <stddef.h>

#define GENERATE \
    X(HIDD_ATTRIBUTES) \
    X(SCROLLINFO) \
    X(SP_DEVICE_INTERFACE_DETAIL_DATA_W)

#define X(N) const size_t SIZEOF_ ## N = sizeof(N);
GENERATE
#undef X

#ifndef ZIGTEST
#include <stdio.h>

int main() {
    #define X(N) printf("sizeof(%s) = %zu\n", #N, sizeof(N));
    GENERATE
    #undef X
}
#endif
