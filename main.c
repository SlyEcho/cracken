#include <windows.h>
#include <CommCtrl.h>

#include "app.h"
#include "mainwindow.h"
#include "window.h"

int WINAPI wWinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPWSTR lpCmdLine, _In_ int nShowCmd) {

	App_instance = hInstance;
	InitCommonControls();

	MainWindow *mw = MainWindow_create();
	Window_show(mw, nShowCmd);

	MSG msg;
	while (GetMessage(&msg, NULL, 0, 0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	return 0;
}
