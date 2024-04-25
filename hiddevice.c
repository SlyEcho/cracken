#include <string.h>
#include <wchar.h>

#include "deviceenumerator.h"
#include "hiddevice.h"
#include "xalloc.h"

/*
HidDevice *HidDevice_create(unsigned short vid, unsigned short pid, const wchar_t *path) {
	size_t len = wcslen(path);
	HidDevice *d = xcalloc(1, sizeof(HidDevice));
	d->path = xmalloc((len + 1) * sizeof(wchar_t));
	memcpy(d->path, path, (len + 1) * sizeof(wchar_t));
	d->vendor_id = vid;
	d->product_id = pid;
	d->serial[0] = 0;
	return d;
}

void HidDevice_delete(HidDevice *h) {
	xfree(h->path);
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
*/