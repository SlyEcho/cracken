#pragma once

#include <stdint.h>
#include <wchar.h>

typedef struct {
	wchar_t name[16];
	uint8_t length;
	uint8_t items[31];
} Curve;

extern const Curve * const Curve_fan_presets[];
extern const Curve * const Curve_pump_presets[];
