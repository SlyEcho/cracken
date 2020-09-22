#pragma once

typedef void *win_HFONT, *win_HDC;

typedef struct {
	wchar_t *text;
	win_HFONT font;
	int height;
	int width;
	int ascender;
	int x;
	int y;
} LayoutCell;

void Layout(win_HDC hdc, int left, int top, int nrow, int ncol, LayoutCell **cells, int margin);
