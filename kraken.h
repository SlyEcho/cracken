#pragma once

#include <stdbool.h>

#include "curve.h"
#include "list.h"
#include "hiddevice.h"

struct s_Kraken;
typedef struct s_Kraken Kraken;

typedef struct {
	double temp_c;
	double fan_rpm;
	double pump_rpm;
} DeviceInfo;

void Kraken_update(Kraken *k);
wchar_t *Kraken_get_ident(const Kraken *k);
DeviceInfo *Kraken_get_info(const Kraken *k);
void Kraken_set_pump_curve(Kraken *k, const Curve *curve);
void Kraken_set_fan_curve(Kraken *k, const Curve *curve);
void Kraken_delete(Kraken *k);

DEFINE_LIST_TYPE(Kraken)

KrakenList *Kraken_get_krakens();
