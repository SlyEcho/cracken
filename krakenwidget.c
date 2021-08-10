#include <Windows.h>
#include <windowsx.h>
#include <CommCtrl.h>
#include <wchar.h>

#include "app.h"
#include "curve.h"
#include "krakenwidget.h"
#include "layout.h"
#include "xalloc.h"

typedef struct {
	KrakenWidget public;
	HFONT font;
	HFONT bold_font;
	HFONT big_font;
	HWND pump;
	HWND fan;

	struct {
		HWND device;
		HWND fan;
		HWND temp;
		HWND pump;
	} labels;

	struct {
		HWND device;
		HWND fan;
		HWND temp;
		HWND pump;
	} values;
} private_KrakenWidget;

#define self KrakenWidget *this
#define wnd ((Window*)this)
#define base (this->base)
#define public (*this)
#define private (*((private_KrakenWidget*)this))

#define ID_PUMP 0x1001
#define ID_FAN 0x1002


void KrakenWidget_update(self) {
	Kraken *k = public.kraken;
	wchar_t buffer[20];

	swprintf(buffer, 20, L"%.1f \u00b0C", k->temp_c);
	SetWindowText(private.values.temp, buffer);

	swprintf(buffer, 20, L"%.0f rpm", k->fan_rpm);
	SetWindowText(private.values.fan, buffer);

	swprintf(buffer, 20, L"%.0f rpm", k->pump_rpm);
	SetWindowText(private.values.pump, buffer);
}

static void position(self) {

	int m = Window_scale(wnd, 5);
	int h = Window_scale(wnd, 20);

	LayoutCell c_lab_Device = { .control = private.labels.device };
	LayoutCell c_lab_Temp =   { .control = private.labels.temp };
	LayoutCell c_lab_Fan =    { .control = private.labels.fan };
	LayoutCell c_lab_Pump =   { .control = private.labels.pump };

	LayoutCell c_val_Device = { .control = private.values.device };
	LayoutCell c_val_Temp =   { .control = private.values.temp, .text = L"99.9 \u00b0C" };
	LayoutCell c_val_Fan =    { .control = private.values.fan,  .text = L"9999 rpm", };
	LayoutCell c_val_Pump =   { .control = private.values.pump, .text = L"9999 rpm", };

	LayoutCell *cells[8] = {
		&c_lab_Device, &c_val_Device,
		&c_lab_Temp,   &c_val_Temp,
		&c_lab_Fan,    &c_val_Fan,
		&c_lab_Pump,   &c_val_Pump,
	};
	
	HDC hdc = GetDC(base.hwnd);
	Layout(hdc, 0, 0, 4, 2, cells, Window_scale(wnd, 5));

	int pump_y = c_val_Pump.y + c_val_Pump.ascender;
	int fan_y = c_val_Fan.y + c_val_Fan.ascender;
	int val_w = max(max(c_val_Pump.x + c_val_Pump.width, c_val_Fan.x + c_val_Fan.width), c_val_Temp.x + c_val_Temp.width);

	MoveWindow(private.pump, val_w + m, pump_y - h, base.width - val_w - m, h, TRUE);
	MoveWindow(private.fan, val_w + m, fan_y - h, base.width - val_w - m, h, TRUE);
}

static void load_assets(self) {
	if (private.font) DeleteObject(private.font);
	if (private.bold_font) DeleteObject(private.bold_font);
	if (private.big_font) DeleteObject(private.big_font);

	private.font = CreateFont(
		Window_scale(wnd, 16), 0, 0, 0, 0, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 0, 0, L"Segoe UI");

	private.bold_font = CreateFont(
		Window_scale(wnd, 16), 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 0, 0, L"Segoe UI");

	private.big_font = CreateFont(
		Window_scale(wnd, 36), 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 0, 0, L"Arial");

	SetWindowFont(private.pump, private.font, FALSE);
	SetWindowFont(private.fan, private.font, FALSE);

	SetWindowFont(private.labels.device, private.font, FALSE);
	SetWindowFont(private.labels.fan, private.font, FALSE);
	SetWindowFont(private.labels.pump, private.font, FALSE);
	SetWindowFont(private.labels.temp, private.font, FALSE);

	SetWindowFont(private.values.device, private.bold_font, FALSE);
	SetWindowFont(private.values.fan, private.big_font, FALSE);
	SetWindowFont(private.values.pump, private.big_font, FALSE);
	SetWindowFont(private.values.temp, private.big_font, FALSE);

	InvalidateRect(base.hwnd, NULL, TRUE);
}

static HBRUSH static_color(self, HDC hdc, HWND ctrl) {

	if (ctrl == private.labels.device || ctrl == private.labels.fan ||
		ctrl == private.labels.pump || ctrl == private.labels.temp) {
		SetTextColor(hdc, RGB(110, 110, 110));
	} else {
		SetTextColor(hdc, RGB(30, 30, 30));
	}

	SetBkMode(hdc, TRANSPARENT);
	return GetSysColorBrush(COLOR_WINDOW);
}


static void resize(self) {
	load_assets(this);
	position(this);
}

static void created(self) {
	load_assets(this);
}

static int selected(self, int command) {

	if (command == ID_PUMP) {
		int i = ComboBox_GetCurSel(private.pump);
		if (i != CB_ERR) {
			SetCursor(LoadCursor(NULL, IDC_APPSTARTING));
			const Curve *c = Curve_pump_presets[i];
			Kraken_set_pump_curve(public.kraken, c);
		}
		return 0;
	}

	if (command == ID_FAN) {
		int i = ComboBox_GetCurSel(private.fan);
		if (i != CB_ERR) {
			SetCursor(LoadCursor(NULL, IDC_APPSTARTING));
			const Curve *c = Curve_fan_presets[i];
			Kraken_set_fan_curve(public.kraken, c);
		}
		return 0;
	}

	return 1;
}

static WindowClass class = {
	.name = L"KrakenWidget",
	.style = WS_CHILD | WS_VISIBLE,
	.created = (fn_window) created,
	.resize = (fn_window) resize,
	.select = (fn_window_command) selected,
	.static_color = (fn_window_static_color) static_color,
};

KrakenWidget *KrakenWidget_create(Window *parent, Kraken *kraken) {
	self = xmalloc(sizeof(private_KrakenWidget));
	base.class = &class;
	private.font = NULL;
	private.bold_font = NULL;
	private.big_font = NULL;
	public.kraken = kraken;

	Window_init(wnd, parent, L"");

	#define MAKE_DROPDOWN(id) CreateWindowEx( \
		0, WC_COMBOBOX, L"", CBS_DROPDOWNLIST | CBS_HASSTRINGS | WS_CHILD | WS_OVERLAPPED | WS_VISIBLE, \
		0, 0, 0, 1000, base.hwnd, (HMENU) id, App_instance, NULL)

	private.pump = MAKE_DROPDOWN(ID_PUMP);
	private.fan = MAKE_DROPDOWN(ID_FAN);
    
    wchar_t buf[128] = {0};
	for (int i = 0; Curve_pump_presets[i]; i++) {
        wcscpy_s(buf, 128, Curve_pump_presets[i]->name);
		ComboBox_AddString(private.pump, buf);
    }
    
	for (int i = 0; Curve_fan_presets[i]; i++) {
        wcscpy_s(buf, 128, Curve_fan_presets[i]->name);
		ComboBox_AddString(private.fan, buf);
    }

	#define MAKE_STATIC(text, s) CreateWindowEx( \
		0, WC_STATIC, text, s | WS_CHILD | WS_VISIBLE /*| SS_SUNKEN*/, \
		0, 0, 0, 0, base.hwnd, (HMENU) NULL, App_instance, NULL)

	private.labels.fan = MAKE_STATIC(L"Fan", SS_RIGHT);
	private.labels.pump = MAKE_STATIC(L"Pump", SS_RIGHT);
	private.labels.device = MAKE_STATIC(L"Device", SS_RIGHT);
	private.labels.temp = MAKE_STATIC(L"Temp", SS_RIGHT);

	private.values.fan = MAKE_STATIC(L"", SS_LEFT);
	private.values.pump = MAKE_STATIC(L"", SS_LEFT);
	private.values.device = MAKE_STATIC(kraken->device->serial, SS_LEFT);
	private.values.temp = MAKE_STATIC(L"", SS_LEFT);

	return this;
}

