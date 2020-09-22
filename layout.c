#include <Windows.h>

#include "layout.h"
#include "xalloc.h"

void Layout(win_HDC hdc, int left, int top, int nrow, int ncol, LayoutCell **cells, int margin) {

	SIZE size;
	TEXTMETRIC metrics;

	int *rowsizes = xmalloc(sizeof(int) * nrow);
	int *baselines = xmalloc(sizeof(int) * nrow);
	int *colsizes = xmalloc(sizeof(int) * ncol);

	for (int i = 0; i < nrow; i++) {
		rowsizes[i] = 0;
		baselines[i] = 0;
		for (int j = 0; j < ncol; j++) {
			LayoutCell *cell = cells[i * ncol + j];
			SelectObject(hdc, cell->font);
			wchar_t *text = cell->text;
			int len = (int)wcslen(text);
			GetTextExtentPoint32(hdc, text, len, &size);
			GetTextMetrics(hdc, &metrics);
			cell->width = size.cx;
			cell->height = metrics.tmHeight;
			cell->ascender = metrics.tmAscent;
			if (cell->height > rowsizes[i]) {
				rowsizes[i] = cell->height;
			}
			if (cell->ascender > baselines[i]) {
				baselines[i] = cell->ascender;
			}
		}
	}

	for (int j = 0; j < ncol; j++) {
		colsizes[j] = 0;
		for (int i = 0; i < nrow; i++) {
			LayoutCell *cell = cells[i * ncol + j];
			if (cell->width > colsizes[j]) {
				colsizes[j] = cell->width;
			}
		}
	}

	int y = top;
	for (int i = 0; i < nrow; i++) {
		int x = left;
		int h = rowsizes[i];
		int b = baselines[i];
		for (int j = 0; j < ncol; j++) {
			int w = colsizes[j];
			LayoutCell *cell = cells[i * ncol + j];

			SelectObject(hdc, cell->font);
			RECT r = { .left = x, .right = x + w, .top = y + b - cell->ascender, .bottom = y + h };
			//FillRect(hdc, &r, CreateSolidBrush(RGB(255, 0, 255)));
			DrawText(hdc, cell->text, -1, &r, DT_LEFT | DT_SINGLELINE | DT_TOP);

			cell->x = x;
			cell->y = y;

			x += w + margin;
		}
		y += h + margin;
	}

	xfree(rowsizes);
	xfree(baselines);
	xfree(colsizes);
}