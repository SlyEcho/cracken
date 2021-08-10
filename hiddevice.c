#include <string.h>
#include <wchar.h>

#include "deviceenumerator.h"
#include "hiddevice.h"
#include "xalloc.h"

HidDevice *HidDevice_create(int vid, int pid, wchar_t *path) {
	size_t len = wcslen(path) + 1;
	HidDevice *d = xmalloc(sizeof(HidDevice) + len * sizeof(wchar_t));
	memcpy(d->path, path, sizeof(wchar_t) * (len + 1));
	d->path[len - 1] = 0;
	d->vendor_id = vid;
	d->product_id = pid;
	d->serial[0] = 0;
	return d;
}

void HidDevice_delete(HidDevice *h) {
	xfree(h);
}

HidDeviceList *HidDevice_enumerate() {
	HidDeviceList *list = HidDeviceList_create(10);
	DeviceEnumerator *de = DeviceEnumerator_create();

	while (DeviceEnumerator_move_next(de)) {
		HidDevice *device = DeviceEnumerator_get_device(de);
		if (device) {
			HidDeviceList_append(list, device);
		}
	}

	DeviceEnumerator_delete(de);

	return list;
}
