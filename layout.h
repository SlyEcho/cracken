#pragma once

typedef struct {
	wchar_t *text;
	HFONT font;
	int height;
	int width;
	int ascender;
	int x;
	int y;
	HWND control;
} LayoutCell;

void Layout(HDC hdc, int left, int top, unsigned nrow, unsigned ncol, LayoutCell **cells, int margin);
