#pragma once

#include <stddef.h>

typedef void (*fn_delete)(void *);

typedef struct {
    void **data;
    size_t length;
    size_t capacity;
} List;

List *List_create(size_t capacity);
void List_delete(List *b, fn_delete deleter);
void List_append(List *b, void *data);

#define DEFINE_LIST_TYPE(type) \
    typedef struct { \
        type **data; \
        size_t length; \
        size_t capacity; \
    } type##List; \
    static inline type##List *type##List_create(size_t capacity) { \
        return (type##List *)List_create(capacity); \
    } \
    static inline void type##List_delete(type##List *this) { \
        List_delete((List *)this, (fn_delete)type##_delete); \
    } \
    static inline void type##List_append(type##List *this, type *item) { \
        List_append((List *)this, item); \
    } 
