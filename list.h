#pragma once

#include <stddef.h>

typedef void (*fn_delete)(void *);

struct s_List;
typedef struct s_List List;

List *List_create(size_t capacity);
void List_delete(List *b, fn_delete deleter);
void List_append(List *b, void *data);
size_t List_length(const List *b);
void *List_get(const List *b, size_t i);
void List_set(List *b, size_t i, void *data);

#define DEFINE_LIST_TYPE(type) \
    struct s_##type##List; \
    typedef struct s_##type##List type##List; \
    static inline type##List *type##List_create(size_t capacity) { \
        return (type##List *)List_create(capacity); \
    } \
    static inline void type##List_delete(type##List *this) { \
        List_delete((List *)this, (fn_delete)type##_delete); \
    } \
    static inline void type##List_append(type##List *this, type *item) { \
        List_append((List *)this, item); \
    } \
    static inline size_t type##List_length(const type##List *this) { \
        return List_length((const List *)this); \
    } \
    static inline type *type##List_get(const type##List *this, size_t i) { \
        return (type *)List_get((const List *)this, i); \
    } \
    static inline type *type##List_set(type##List *this, size_t i, type *item) { \
        List_set((List *)this, i, item); \
    }
