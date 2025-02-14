#pragma once

#include <stddef.h>

void *xmalloc(size_t size);
void xfree(void *ptr, size_t size);
