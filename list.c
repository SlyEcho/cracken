#include <string.h>

#include "list.h"
#include "xalloc.h"

struct s_List {
    void **data;
    size_t length;
    size_t capacity;
};

List *List_create(size_t capacity) {
	List *b = xmalloc(sizeof(List));
	b->data = xmalloc(sizeof(void *) * capacity);
	b->length = 0;
	b->capacity = capacity;
	return b;
}

void List_delete(List *b, fn_delete deleter) {
	if (b) {
		if (deleter) {
			for (size_t i = 0; i < b->length; i++) {
				if (b->data[i])
					deleter(b->data[i]);
			}
		}
		xfree(b->data);
		xfree(b);
	}
}

static void List_ensure(List *b, size_t cap) {
	if (b->capacity < cap) {
		cap = cap * 3 / 2;
		b->data = xrealloc(b->data, sizeof(void *) * cap);
		b->capacity = cap;
	}
}

void List_append(List *b, void *data) {
	List_ensure(b, b->length + 1);
	b->data[b->length++] = data;
}

size_t List_length(const List *b) {
	return b->length;
}

void *List_get(const List *b, size_t i) {
	return b->data[i];
}

void List_set(List *b, size_t i, void *data) {
	b->data[i] = data;
}