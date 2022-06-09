#include <windows.h>
#include <sdkddkver.h>
#include <setupapi.h>
#include <hidsdi.h>

#include "deviceenumerator.h"
#include "xalloc.h"

struct s_DeviceEnumerator {
	GUID guid;
	HDEVINFO handle;
	int currentDeviceNr;
	SP_DEVICE_INTERFACE_DATA *interfaceData;
};

#define self DeviceEnumerator *this
#define private (*this)

DeviceEnumerator *DeviceEnumerator_create() {
	self = xmalloc(sizeof(DeviceEnumerator));

	HidD_GetHidGuid(&private.guid);

	private.handle = SetupDiGetClassDevs(&private.guid, NULL, NULL, DIGCF_DEVICEINTERFACE | DIGCF_PRESENT);
	private.currentDeviceNr = 0;
	private.interfaceData = xmalloc(sizeof(SP_DEVICE_INTERFACE_DATA));
	memset(private.interfaceData, 0, sizeof(SP_DEVICE_INTERFACE_DATA));
	private.interfaceData->cbSize = sizeof(SP_DEVICE_INTERFACE_DATA);

	return this;
}

void DeviceEnumerator_delete(self) {
	SetupDiDestroyDeviceInfoList(private.handle);
	xfree(private.interfaceData);
}

bool DeviceEnumerator_move_next(self) {
	return SetupDiEnumDeviceInterfaces(private.handle, NULL, &private.guid, ++(private.currentDeviceNr), private.interfaceData);
}

HidDevice *DeviceEnumerator_get_device(self) {
	HidDevice *d = NULL;
	HANDLE file = NULL;
	SP_DEVICE_INTERFACE_DETAIL_DATA *detailData;

	DWORD detailDataSize = 0;
	SetupDiGetDeviceInterfaceDetail(private.handle, private.interfaceData, NULL, 0, &detailDataSize, NULL);

	detailData = xcalloc(1, detailDataSize);
	detailData->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA);

	if (!SetupDiGetDeviceInterfaceDetail(private.handle, private.interfaceData, detailData, detailDataSize, &detailDataSize, NULL)) {
		goto exit;
	}

	file = CreateFile(detailData->DevicePath, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, 0);
	if (!file) {
		goto exit;
	}

	HIDD_ATTRIBUTES attributes = { .Size = sizeof(HIDD_ATTRIBUTES) };
	if (!HidD_GetAttributes(file, &attributes)) {
		goto exit;
	}

	d = HidDevice_create(attributes.VendorID, attributes.ProductID, detailData->DevicePath);
	if (!HidD_GetSerialNumberString(file, d->serial, sizeof(d->serial)))
		d->serial[0] = 0;

exit:
	if (file)
		CloseHandle(file);
	free(detailData);

	return d;
}
