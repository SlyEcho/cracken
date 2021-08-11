#include <Windows.h>
#include <stdlib.h>

#include "xalloc.h"

void *xmalloc(size_t size) {
    void *mem = malloc(size);
    if (!mem) {
        MessageBox(0, L"xmalloc out of memory", L"error", MB_ICONERROR | MB_OK);
        exit(1);
    }
    return mem;
}

void *xrealloc(void *ptr, size_t size) {
    void *mem = realloc(ptr, size);
    if (!mem) {
        MessageBox(0, L"xrealloc out of memory", L"error", MB_ICONERROR | MB_OK);
        exit(1);
    }
    return mem;
}

void xfree(void *ptr) {
    if (ptr) free(ptr);
}
