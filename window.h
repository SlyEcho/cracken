#pragma once

#include <windows.h>
#include <stdbool.h>

struct s_Window;

typedef void (*fn_window)(struct s_Window *);
typedef int (*fn_window_command)(struct s_Window *, int id);
typedef HBRUSH (*fn_window_static_color)(struct s_Window *, HDC hdc, HWND ctrl);

typedef struct s_WindowClass {
	wchar_t *name;
	bool registered;
	int style;
	HBRUSH background;
	fn_window created;
	fn_window paint;
	fn_window_static_color static_color;
	fn_window destroyed;
	fn_window resize;
	fn_window dpi;
	fn_window_command command;
	fn_window_command clicked;
	fn_window_command select;
	fn_window_command timer;
} WindowClass;

typedef struct s_Window {
	WindowClass *class;
	HWND hwnd;
	int width;
	int height;
	int dpi;
	int content_height;
} Window;

void Window_init(Window *w, Window *parent, wchar_t *title);
void Window_show(Window *w);
void Window_update_scroll(Window *w);
int Window_scale(Window *w, int dimension);
int Window_unscale(Window *w, int dimension);
void Window_rescale(Window *w, int x, int y, int width, int height);
