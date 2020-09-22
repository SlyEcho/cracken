#pragma once
#include <stdbool.h>

#include "hiddevice.h"
#include "deviceenumerator.h"

struct s_DeviceEnumerator;
typedef struct s_DeviceEnumerator DeviceEnumerator;

DeviceEnumerator *DeviceEnumerator_create();
void DeviceEnumerator_delete(DeviceEnumerator *de);
bool DeviceEnumerator_move_next(DeviceEnumerator *de);
HidDevice *DeviceEnumerator_get_device(DeviceEnumerator *de);
