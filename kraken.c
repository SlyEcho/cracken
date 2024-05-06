#include <windows.h>

#include "curve.h"
#include "kraken.h"
#include "xalloc.h"

struct s_Kraken {
	HidDevice *device;
	HANDLE reader;
	HANDLE writer;
	wchar_t ident[128];
	DeviceInfo info;
};

#define self Kraken *this
#define private (*this)
#define lengthof(T) (sizeof(T)/sizeof((T)[0]))

Kraken *Kraken_create(HidDevice *device) {
	self = xmalloc(sizeof(Kraken));

	swprintf(private.ident, lengthof(private.ident), L"X52 (%s)", device->serial);

	private.device = device;
	private.reader = CreateFile(device->path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, NULL);
	private.writer = NULL;

	return this;
}

void Kraken_delete(self) {
	CloseHandle(private.reader);
	if (private.writer) {
		CloseHandle(private.writer);
	}
	HidDevice_delete(private.device);
	xfree(this, sizeof(Kraken));
}

void Kraken_update(self) {
	BYTE packet[65];
	DWORD num;
	DeviceInfo *info = &private.info;
	if (ReadFile(private.reader, packet, 65, &num, NULL)) {
		//info->device_nr = (int) packet[10];
		info->temp_c = (double) packet[1] + (double) packet[2] * 0.1;
		info->fan_rpm = (int) packet[3] << 8 | (int) packet[4];
		info->pump_rpm = (int) packet[5] << 8 | (int) packet[6];
	}
}

wchar_t *Kraken_get_ident(const self) {
	return private.ident;
}

DeviceInfo *Kraken_get_info(const self) {
	return &private.info;
}

enum FanOrPump {
	FAN = 0,
	PUMP = 1,
};

static void Kraken_control(self, int isSave, enum FanOrPump fanOrpump, int size, const BYTE *levels, int interval) {

	if (private.writer == NULL) {
		private.writer = CreateFile(private.device->path, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, NULL);
	}

	if (private.writer == NULL) {
		return;
	}

	for (int i = 0; i < size; i++) {
		BYTE packet[65] = {
			2, 77,
			(BYTE) (isSave * 128 + fanOrpump * 64 + i),
			(BYTE) (i * interval),
			levels[i],
		};
		DWORD num;

		WriteFile(private.writer, packet, sizeof(packet), &num, NULL);
	}
}

void Kraken_set_pump_curve(self, const Curve *curve) {
	int interval = (curve->length - 1 == 0) ? (curve->length - 1) : (100 / (curve->length - 1));
	Kraken_control(this, curve->length > 1, PUMP, curve->length, curve->items, interval);
}

void Kraken_set_fan_curve(self, const Curve *curve) {
	int interval = (curve->length - 1 == 0) ? (curve->length - 1) : (100 / (curve->length - 1));
	Kraken_control(this, curve->length > 1, FAN, curve->length, curve->items, interval);
}

KrakenList *Kraken_get_krakens() {
	HidDeviceList *hids = HidDevice_enumerate();
	KrakenList *krakens = KrakenList_create(1);

	for (int i = 0; i < HidDeviceList_length(hids); i++) {
		HidDevice *hid = HidDeviceList_get(hids, i);
		if (hid->vendor_id == 0x1e71 && hid->product_id == 0x170e) {
			self = Kraken_create(hid);
			KrakenList_append(krakens, this);
            HidDeviceList_set(hids, i, NULL);
		}
	}

	HidDeviceList_delete(hids);
    
	return krakens;
}
