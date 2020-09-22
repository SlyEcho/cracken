#pragma once

#include "window.h"

typedef struct {
	Window base;
} MainWindow;

MainWindow *MainWindow_create();
