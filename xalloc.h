#pragma once

void *xmalloc(size_t size);
void *xrealloc(void * ptr, size_t size);
void xfree(void *ptr);
void *alloca(size_t);
