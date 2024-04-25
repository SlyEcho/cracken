#include <windows.h>
#include <windowsx.h>
#include <commctrl.h>
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
	HWND no_devices;
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
	for (int i = 0; i < KrakenList_length(private.krakens); i++) {
		Kraken *k = KrakenList_get(private.krakens, i);
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
	base.content_height = 0;
	for (size_t i = 0; i < private.widget_count; i++) {
		Window *wgt = (Window*)private.widgets[i];
		Window_rescale(wgt, 10, 10 + i * 150, Window_unscale(wnd, base.width) - 20, 140);
		base.content_height += Window_scale(wnd, 150);
	}

	if (private.no_devices) {
		MoveWindow(private.no_devices, 0, 0, base.width, base.height, true);
		if (private.font) DeleteObject(private.font);
		private.font = CreateFont(
			Window_scale(wnd, 16), 0, 0, 0, 0, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 0, 0, L"Segoe UI");
		SetWindowFont(private.no_devices, private.font, true);
	}
}

static void created(self) {

	private.krakens = Kraken_get_krakens();
	update(this);

	SetTimer(base.hwnd, ID_UPDATE, 2000, NULL);
	private.widget_count = KrakenList_length(private.krakens);
	if (private.widget_count > 0) {
		private.widgets = xmalloc(sizeof(KrakenWidget *) * private.widget_count);
		for (size_t i = 0; i < private.widget_count; i++) {
			private.widgets[i] = KrakenWidget_create(wnd, KrakenList_get(private.krakens, i));
			KrakenWidget_update(private.widgets[i]);
		}
	}

	if (private.widget_count == 0) {
		private.no_devices = CreateWindowEx(
			0, WC_STATIC, L"No devices found", SS_CENTER | SS_CENTERIMAGE | WS_CHILD | WS_VISIBLE,
			0, 0, 0, 0, base.hwnd, (HMENU) NULL, App_instance, NULL);
	}
	
	resize(this);
	Window_update_scroll(wnd);
}

static void command(self, int id) {
	if (id == ID_UPDATE) {
		update(this);
	}
}

static HBRUSH static_color(self, HDC hdc, HWND ctrl) {
	SetBkMode(hdc, TRANSPARENT);
	return GetSysColorBrush(COLOR_WINDOW);
}

static WindowClass crackenClass = {
	.name = L"MainWindowClass",
	.style = WS_OVERLAPPEDWINDOW | WS_VSCROLL,
	.resize = (fn_window) resize,
	.destroyed = (fn_window) destroy,
	.created = (fn_window) created,
	.clicked = (fn_window_command) command,
	.timer = (fn_window_command) command,
	.static_color = (fn_window_static_color) static_color,
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
