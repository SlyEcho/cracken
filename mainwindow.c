#include <Windows.h>
#include <stdbool.h>
#include <stdlib.h>

#include "app.h"
#include "kraken.h"
#include "krakenwidget.h"
#include "mainwindow.h"
#include "window.h"
#include "xalloc.h"

typedef struct {
	MainWindow public;
	HFONT font;
	HWND button;
	KrakenList *krakens;
	KrakenWidget **widgets;
	size_t widget_count;
} private_MainWindow;

#define base (this->base)
#define self MainWindow *this
#define wnd ((Window*)this)
#define private (*((private_MainWindow*)(this)))

#define ID_UPDATE 0x100

static void destroy(self) {
	PostQuitMessage(0);
}

static void update(self) {
	for (int i = 0; i < private.krakens->length; i++) {
		Kraken *k = private.krakens->data[i];
		Kraken_update(k);
	}

	for (int i = 0; i < private.widget_count; i++) {
		KrakenWidget *kw = private.widgets[i];
		KrakenWidget_update(kw);
	}

	InvalidateRect(base.hwnd, NULL, TRUE);
	UpdateWindow(base.hwnd);
}

static void resize(self) {
	for (size_t i = 0; i < private.widget_count; i++) {
		Window *wgt = (Window*)private.widgets[i];
		Window_rescale(wgt, 10, 10 + i * 150, Window_unscale(wnd, base.width) - 20, 140);
	}
	base.content_height = Window_scale(wnd, 90 * private.widget_count);
}

static void created(self) {

	private.krakens = Kraken_get_krakens();
	update(this);

	SetTimer(base.hwnd, ID_UPDATE, 2000, NULL);
	private.widget_count = private.krakens->length;
	if (private.widget_count > 0) {
		private.widgets = xmalloc(sizeof(KrakenWidget *) * private.widget_count);
		for (size_t i = 0; i < private.widget_count; i++) {
			private.widgets[i] = KrakenWidget_create(wnd, private.krakens->data[i]);
			KrakenWidget_update(private.widgets[i]);
		}
	}
	resize(this);
	Window_update_scroll(wnd);
}

static void command(self, int id) {
	if (id == ID_UPDATE) {
		update(this);
	}
}

static WindowClass crackenClass = {
	.name = L"MainWindowClass",
	.style = WS_OVERLAPPEDWINDOW | WS_VSCROLL,
	.resize = (fn_window) resize,
	.destroyed = (fn_window) destroy,
	.created = (fn_window) created,
	.clicked = (fn_window_command) command,
	.timer = (fn_window_command) command,
};

MainWindow *MainWindow_create() {
	if (!crackenClass.registered) {
		crackenClass.background = GetSysColorBrush(COLOR_WINDOW);
	}
	self = xmalloc(sizeof(private_MainWindow));
	base.class = &crackenClass;
	private.widgets = NULL;
	private.widget_count = 0;
	Window_init(wnd, NULL, L"Cracken");
	Window_rescale(wnd, -1, -1, 300, 200);
	return this;
}
