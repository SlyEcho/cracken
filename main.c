#include <windows.h>
#include <commctrl.h>

#include "app.h"
#include "mainwindow.h"
#include "window.h"

int WINAPI WinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPSTR lpCmdLine, _In_ int nShowCmd) {

	App_instance = hInstance;
	InitCommonControls();

	Window *mw = (Window*)MainWindow_create();
	Window_show(mw, nShowCmd);

	MSG msg;
	while (GetMessage(&msg, NULL, 0, 0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	return 0;
}
