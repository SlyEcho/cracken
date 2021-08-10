#include <stdlib.h>

#include "xalloc.h"

void *xmalloc(size_t size) {
    void *mem = malloc(size);
    if (!mem) {
        exit(1);
    }
    return mem;
}

void *xrealloc(void *ptr, size_t size) {
    void *mem = realloc(ptr, size);
    if (!mem) {
        exit(1);
    }
    return mem;
}

void xfree(void *ptr) {
    if (ptr) free(ptr);
}