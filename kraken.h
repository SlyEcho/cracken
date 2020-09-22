#pragma once

#include "list.h"
#include "hiddevice.h"

enum FanOrPump {
	FAN = 0,
	PUMP = 1,
};

typedef struct {
	HidDevice *device;
	int device_nr;
	double temp_c;
	double fan_rpm;
	double pump_rpm;
} Kraken;

void Kraken_update(Kraken *k);
void Kraken_control(Kraken *k, int isSave, enum FanOrPump fanOrpump, int size, BYTE *levels, int interval);
void Kraken_fanspeed(Kraken *k, int pct);
void Kraken_pumpspeed(Kraken *k, int pct); 
void Kraken_delete(Kraken *k);

DEFINE_LIST_TYPE(Kraken)

KrakenList *Kraken_get_krakens();
