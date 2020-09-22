#pragma once

#include "list.h"

typedef struct {
	int product_id;
	int vendor_id;
	wchar_t serial[128];
	wchar_t path[];
} HidDevice;

HidDevice *HidDevice_create(int vid, int pid, wchar_t *path);
void HidDevice_delete(HidDevice *h);

DEFINE_LIST_TYPE(HidDevice)

HidDeviceList *HidDevice_enumerate();
