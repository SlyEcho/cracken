#include "curve.h"

#define SC(x) static const Curve static_##x = { \
	.name = L"Fixed " L#x L"%", \
	.length = 1, \
	.items = { (x) } \
}
#define pSC(x) &static_##x

SC(25);
SC(50);
SC(75);
SC(100);

static const Curve preset_fan_silent = {
	.name = L"Silent",
	.length = 21,
	.items = { 25, 25, 25, 25, 25, 25, 25, 25, 35, 45, 55, 75, 100, 100, 100, 100, 100, 100, 100, 100, 100 },
};

static const Curve preset_fan_performance = {
	.name = L"Performance",
	.length = 21,
	.items = { 50, 50, 50, 50, 50, 50, 50, 50, 60, 70, 80, 90, 100, 100, 100, 100, 100, 100, 100, 100, 100 },
};

static const Curve preset_pump_silent = {
	.name = L"Silent",
	.length = 21,
	.items = { 60, 60, 60, 60, 60, 60, 60, 60, 70, 80, 90, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100 },
};

static const Curve preset_pump_performance = {
	.name = L"Performance",
	.length = 21,
	.items = { 70, 70, 70, 70, 70, 70, 70, 70, 80, 85, 90, 95, 100, 100, 100, 100, 100, 100, 100, 100, 100 },
};

const Curve *Curve_fan_presets[] = {
	&preset_fan_silent,
	&preset_fan_performance,
	pSC(25),
	pSC(50),
	pSC(75),
	pSC(100),
	NULL,
};

const Curve *Curve_pump_presets[] = {
	&preset_pump_silent,
	&preset_pump_performance,
	pSC(25),
	pSC(50),
	pSC(75),
	pSC(100),
	NULL,
};