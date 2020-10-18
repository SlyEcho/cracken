#include <Windows.h>

#include "app.h"
#include "window.h"

#define self Window *this
#define public (*this)

int Window_scale(self, int s) {
	return s * public.dpi / 96;
}

int Window_unscale(self, int s) {
	return s * 96 / public.dpi;
}

void Window_update_scroll(self) {
	SCROLLINFO si = {
		.cbSize = sizeof(si),
		.fMask = SIF_POS,
	};
	GetScrollInfo(public.hwnd, SB_VERT, &si);
	si.fMask = SIF_RANGE | SIF_PAGE;
	si.nMin = 0;
	si.nMax = public.content_height;
	si.nPage = public.height;
	SetScrollInfo(public.hwnd, SB_VERT, &si, TRUE);

	if (si.nPos > 0 && si.nPos > public.content_height - public.height) {
		ScrollWindow(public.hwnd, 0, si.nPos - (public.content_height - public.height), NULL, NULL);
		si.nPos = public.content_height - public.height;
	}
}

static int handle_vscroll(self, UINT msg, WPARAM wParam, LPARAM lParam) {
	switch (msg) {
		case WM_DPICHANGED:
		case WM_SIZE: {
			Window_update_scroll(this);
			return 0;
		}
		case WM_MOUSEWHEEL: {
			int zDelta = GET_WHEEL_DELTA_WPARAM(wParam);
			int turn = zDelta / WHEEL_DELTA;
			SendMessage(public.hwnd, WM_VSCROLL, MAKELONG(turn > 0 ? SB_LINEUP : SB_LINEDOWN, 0), 0);
			return 0;
		}
		case WM_VSCROLL: {
			SCROLLINFO si = {
				.cbSize = sizeof(si),
				.fMask = SIF_POS | SIF_TRACKPOS,
			};
			GetScrollInfo(public.hwnd, SB_VERT, &si);

			int oldpos = si.nPos;
			switch (LOWORD(wParam)) {
				case SB_TOP: si.nPos = 0;
					break;
				case SB_BOTTOM: si.nPos = public.content_height;
					break;
				case SB_LINEUP: si.nPos -= Window_scale(this, 25);
					break;
				case SB_LINEDOWN: si.nPos += Window_scale(this, 25);
					break;
				case SB_PAGEUP: si.nPos -= public.height;
					break;
				case SB_PAGEDOWN: si.nPos += public.height;
					break;
				case SB_THUMBTRACK: si.nPos = si.nTrackPos;
					break;
			}

			si.fMask = SIF_POS;
			SetScrollInfo(public.hwnd, SB_VERT, &si, TRUE);
			GetScrollInfo(public.hwnd, SB_VERT, &si);

			if (si.nPos != oldpos) {
				ScrollWindow(public.hwnd, 0, oldpos - si.nPos, NULL, NULL);
			}

			return 0;
		}
	}

	return 1;
}

static int handle_virtual(self, UINT msg, WPARAM wParam, LPARAM lParam) {
	switch (msg) {
		case WM_CREATE: {
			if (public.class->created) {
				public.class->created(this);
				return 0;
			}
			break;
		}
		case WM_DESTROY: {
			if (public.class->destroyed) {
				public.class->destroyed(this);
				return 0;
			}
			break;
		}
		case WM_PAINT: {
			if (public.class->paint) {
				public.class->paint(this);
				return 0;
			}
			break;
		}
		case WM_DPICHANGED_BEFOREPARENT:
		case WM_DPICHANGED:
		case WM_SIZE: {
			if (public.class->resize) {
				public.class->resize(this);
				return 0;
			}
			break;
		}
		case WM_COMMAND: {
			if (HIWORD(wParam) == BN_CLICKED &&
				public.class->clicked &&
				public.class->clicked(this, LOWORD(wParam)) == 0) {
				return 0;
			}
			if (HIWORD(wParam) == CBN_SELCHANGE &&
				public.class->select &&
				public.class->select(this, LOWORD(wParam)) == 0) {
				return 0;
			}
			if (public.class->command &&
				public.class->command(this, LOWORD(wParam)) == 0) {
				return 0;
			}
			break;
		}
		case WM_TIMER: {
			if (public.class->timer &&
				public.class->timer(this, (int) wParam) == 0) {
				return 0;
			}
			break;
		}
	}

	return 1;
}

static LRESULT CALLBACK Window_proc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
	self;
	if (msg == WM_CREATE) {
		CREATESTRUCT *pCreate = (CREATESTRUCT *) lParam;
		this = (Window *) pCreate->lpCreateParams;
		public.hwnd = hWnd;
		SetWindowLongPtr(hWnd, GWLP_USERDATA, (LONG_PTR) this);
	} else {
		this = (Window *) GetWindowLongPtr(hWnd, GWLP_USERDATA);
	}

	if (this != NULL) {
		bool handled = false;

		switch (msg) {
			case WM_SIZE: {
				public.width = LOWORD(lParam);
				public.height = HIWORD(lParam);
				handled |= true;
				break;
			}
			case WM_DPICHANGED_BEFOREPARENT: {
				public.dpi = GetDpiForWindow(public.hwnd);
				handled |= true;
				break;

			}
			case WM_DPICHANGED: {
				public.dpi = HIWORD(wParam);
				RECT *r = (RECT *) lParam;
				SetWindowPos(hWnd, NULL,
					r->left, r->top,
					r->right - r->left, r->bottom - r->top,
					SWP_NOZORDER | SWP_NOACTIVATE
				);
				handled |= true;
				break;
			}
		}

		if ((public.class->style & WS_VSCROLL) && handle_vscroll(this, msg, wParam, lParam) == 0) {
			handled |= true;
		}

		if (handle_virtual(this, msg, wParam, lParam) == 0) {
			handled |= true;
		}

		if (handled) {
			return 0;
		}

	}

	return DefWindowProc(hWnd, msg, wParam, lParam);
}

void Window_init(self, Window *parent, wchar_t *title) {
	if (!public.class->registered) {
		WNDCLASS wc = {
			.lpfnWndProc = Window_proc,
			.hInstance = App_instance,
			.lpszClassName = public.class->name,
			.style = CS_HREDRAW | CS_VREDRAW,
			.hCursor = LoadCursor(NULL, IDC_ARROW),
		};

		RegisterClass(&wc);
		public.class->registered = true;
	}

	public.content_height = 0;
	public.dpi = GetDpiForSystem();
	public.width = 0;
	public.height = 0;

	HWND hwnd = CreateWindowEx(
		0, public.class->name, title, public.class->style,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		0, 0,
		parent != NULL ? parent->hwnd : NULL,
		NULL, App_instance, this);

	RECT r;
	GetClientRect(hwnd, &r);
	public.width = r.right;
	public.height = r.bottom;
	public.dpi = GetDpiForWindow(hwnd);
}

void Window_show(self, int show) {
	ShowWindow(public.hwnd, show);
}

void Window_rescale(self, int x, int y, int width, int height) {
	RECT size;
	GetWindowRect(public.hwnd, &size);
	if (x != -1) size.left = Window_scale(this, x);
	if (y != -1) size.top = Window_scale(this, y);

	SetWindowPos(public.hwnd, NULL,
		size.left, size.top,
		Window_scale(this, width), Window_scale(this, height),
		SWP_NOZORDER | SWP_NOACTIVATE);
}