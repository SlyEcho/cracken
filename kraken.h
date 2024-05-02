#pragma once

#include "curve.h"
#include "list.h"
#include "hiddevice.h"

typedef struct {
	wchar_t ident[128];
	int device_nr;
	double temp_c;
	double fan_rpm;
	double pump_rpm;
} Kraken;

void Kraken_update(Kraken *k);
void Kraken_set_pump_curve(Kraken *k, const Curve *curve);
void Kraken_set_fan_curve(Kraken *k, const Curve *curve);
void Kraken_delete(Kraken *k);

DEFINE_LIST_TYPE(Kraken)

KrakenList *Kraken_get_krakens();
