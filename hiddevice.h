#pragma once

#include "list.h"

typedef struct {
	unsigned short product_id;
	unsigned short vendor_id;
	wchar_t serial[128];
	wchar_t *path;
} HidDevice;

HidDevice *HidDevice_create(unsigned short vid, unsigned short pid, const wchar_t *path);
void HidDevice_delete(HidDevice *h);

DEFINE_LIST_TYPE(HidDevice)

HidDeviceList *HidDevice_enumerate();
