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
	int pump_y;
	int fan_y;
	int val_w;
} private_KrakenWidget;

#define self KrakenWidget *this
#define base (this->base)
#define public (*this)
#define private (*((private_KrakenWidget*)this))

#define ID_PUMP 0x1001
#define ID_FAN 0x1002


static void position(self) {
	int m = Window_scale(this, 5);
	int h = Window_scale(this, 20);
	MoveWindow(private.pump, private.val_w + m, private.pump_y - h, base.width - private.val_w - m, h, TRUE);
	MoveWindow(private.fan, private.val_w + m, private.fan_y - h, base.width - private.val_w - m, h, TRUE);
}

static void paint(self) {
	Kraken *k = public.kraken;
	PAINTSTRUCT ps;
	HDC hdc = BeginPaint(base.hwnd, &ps);
	HBRUSH hBrush = CreateSolidBrush(RGB(255, 255, 255));
	FillRect(hdc, &ps.rcPaint, hBrush);
	DeleteObject(hBrush);
	SetBkMode(hdc, TRANSPARENT);

	LayoutCell c_lab_Device = { .text = L"Device", .font = private.font };
	LayoutCell c_lab_Temp =   { .text = L"Temp",   .font = private.font };
	LayoutCell c_lab_Fan =    { .text = L"Fan",    .font = private.font };
	LayoutCell c_lab_Pump =   { .text = L"Pump",   .font = private.font };

	wchar_t temp_text[20];
	swprintf(temp_text, 20, L"%.1f \u00b0C", k->temp_c);

	wchar_t fan_text[20];
	swprintf(fan_text, 20, L"%.0f rpm", k->fan_rpm);

	wchar_t pump_text[20];
	swprintf(pump_text, 20, L"%.0f rpm", k->pump_rpm);

	LayoutCell c_val_Device = { .text = k->device->serial, .font = private.bold_font };
	LayoutCell c_val_Temp =   { .text = temp_text,         .font = private.big_font };
	LayoutCell c_val_Fan =    { .text = fan_text,          .font = private.big_font };
	LayoutCell c_val_Pump =   { .text = pump_text,         .font = private.big_font };

	LayoutCell *cells[8] = {
		&c_lab_Device, &c_val_Device,
		&c_lab_Temp,   &c_val_Temp,
		&c_lab_Fan,    &c_val_Fan,
		&c_lab_Pump,   &c_val_Pump,
	};

	Layout(hdc, 0, 0, 4, 2, cells, Window_scale(this, 5));

	bool reposition = private.pump_y == 0;
	private.pump_y = c_val_Pump.y + c_val_Pump.ascender;
	private.fan_y = c_val_Fan.y + c_val_Fan.ascender;
	private.val_w = max(max(c_val_Pump.x + c_val_Pump.width, c_val_Fan.x + c_val_Fan.width), c_val_Temp.x + c_val_Temp.width);
	
	if (reposition) {
		position(this);
	}

	EndPaint(base.hwnd, &ps);
}

static void load_assets(self) {
	if (private.font) DeleteObject(private.font);
	if (private.bold_font) DeleteObject(private.bold_font);
	if (private.big_font) DeleteObject(private.big_font);

	private.font = CreateFont(
		Window_scale(this, 16), 0, 0, 0, 0, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 0, 0, L"Segoe UI");

	private.bold_font = CreateFont(
		Window_scale(this, 16), 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 0, 0, L"Segoe UI");

	private.big_font = CreateFont(
		Window_scale(this, 36), 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 0, 0, L"Arial");

	SetWindowFont(private.pump, private.font, FALSE);
	SetWindowFont(private.fan, private.font, FALSE);

	InvalidateRect(base.hwnd, NULL, TRUE);
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
			Curve *c = Curve_pump_presets[i];
			Kraken_set_pump_curve(public.kraken, c);
		}
		return 0;
	}

	if (command == ID_FAN) {
		int i = ComboBox_GetCurSel(private.fan);
		if (i != CB_ERR) {
			Curve *c = Curve_fan_presets[i];
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
	.paint = (fn_window) paint,
	.resize = (fn_window) resize,
	.select = (fn_window_command) selected,
};

KrakenWidget *KrakenWidget_create(Window *parent, Kraken *kraken) {
	self = xmalloc(sizeof(private_KrakenWidget));
	base.class = &class;
	private.font = NULL;
	private.bold_font = NULL;
	private.big_font = NULL;
	private.pump_y = 0;
	private.fan_y = 0;
	private.val_w = 0;
	public.kraken = kraken;

	Window_init(this, parent, L"");
	private.pump = CreateWindowEx(
		0, WC_COMBOBOX, L"asdf", CBS_DROPDOWNLIST | CBS_HASSTRINGS | WS_CHILD | WS_OVERLAPPED | WS_VISIBLE,
		0, 0, 0, 0, base.hwnd, (HMENU) ID_PUMP, App_instance, NULL);
	
	private.fan = CreateWindowEx(
		0, WC_COMBOBOX, L"asdf", CBS_DROPDOWNLIST | CBS_HASSTRINGS | WS_CHILD | WS_OVERLAPPED | WS_VISIBLE,
		0, 0, 0, 0, base.hwnd, (HMENU) ID_FAN, App_instance, NULL);

	for (int i = 0; Curve_pump_presets[i]; i++)
		ComboBox_AddString(private.pump, Curve_pump_presets[i]->name);
	
	for (int i = 0; Curve_fan_presets[i]; i++)
		ComboBox_AddString(private.fan, Curve_fan_presets[i]->name);

	return this;
}