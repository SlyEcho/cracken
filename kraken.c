#include <Windows.h>

#include "curve.h"
#include "kraken.h"

typedef struct {
	Kraken public;
	HANDLE reader;
	HANDLE writer;
} private_Kraken;

#define self Kraken *this
#define public (*this)
#define private (*((private_Kraken*)this))

Kraken *Kraken_create(HidDevice *device) {
	self = malloc(sizeof(private_Kraken));
	if (!this) return NULL;

	public.device = device;
	private.reader = CreateFile(device->path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, NULL);
	private.writer = NULL;

	return this;
}
void Kraken_delete(self) {
	CloseHandle(private.reader);
	if (private.writer) {
		CloseHandle(private.writer);
	}
	HidDevice_delete(public.device);
	free(this);
}

void Kraken_update(self) {
	BYTE packet[256];
	DWORD num;
	if (ReadFile(private.reader, packet, 64, &num, NULL)) {
		public.device_nr = (int) packet[10];
		public.temp_c = (double) packet[1] + (double) packet[2] * 0.1;
		public.fan_rpm = (int) packet[3] << 8 | (int) packet[4];
		public.pump_rpm = (int) packet[5] << 8 | (int) packet[6];
	}
}

static void Kraken_control(self, int isSave, enum FanOrPump fanOrpump, int size, BYTE *levels, int interval) {

	if (private.writer == NULL) {
		private.writer = CreateFile(public.device->path, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, NULL);
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
	FlushFileBuffers(private.writer);
}

void Kraken_set_pump_curve(self, Curve *curve) {
	int interval = (curve->length - 1 == 0) ? (curve->length - 1) : (100 / (curve->length - 1));
	Kraken_control(this, FALSE, PUMP, curve->length, curve->items, interval);
}
void Kraken_set_fan_curve(self, Curve *curve) {
	int interval = (curve->length - 1 == 0) ? (curve->length - 1) : (100 / (curve->length - 1));
	Kraken_control(this, FALSE, FAN, curve->length, curve->items, interval);
}


KrakenList *Kraken_get_krakens() {
	HidDeviceList *hids = HidDevice_enumerate();
	KrakenList *krakens = KrakenList_create(1);

	for (int i = 0; i < hids->length; i++) {
		HidDevice *hid = hids->data[i];
		if (hid->vendor_id == 0x1e71 && hid->product_id == 0x170e) {
			self = Kraken_create(hid);
			KrakenList_append(krakens, this);
			hids->data[i] = NULL;
		}
	}

	HidDeviceList_delete(hids);

	return krakens;
}
