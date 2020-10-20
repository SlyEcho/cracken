#pragma once

#include "window.h"
#include "kraken.h"

typedef struct {
	Window base;
	Kraken *kraken;
} KrakenWidget;

KrakenWidget *KrakenWidget_create(Window *parent, Kraken *kraken);
void KrakenWidget_update(KrakenWidget *kw);

