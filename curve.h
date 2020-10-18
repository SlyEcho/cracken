#pragma once

#include <stdint.h>

typedef struct {
	wchar_t *name;
	uint8_t length;
	uint8_t items[];
} Curve;

extern const Curve *Curve_fan_presets[];
extern const Curve *Curve_pump_presets[];
