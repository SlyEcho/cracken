cmake_minimum_required (VERSION 3.8)

add_definitions(-DUNICODE -D_UNICODE)

project ("cracken" C)

add_executable (cracken WIN32 "main.c" "cracken.manifest"
	"app.c" "app.h"
	"curve.c" "curve.h"
	"deviceenumerator.c" "deviceenumerator.h"
	"hiddevice.c" "hiddevice.h"
	"kraken.c" "kraken.h"
	"krakenwidget.c" "krakenwidget.h"
	"layout.c" "layout.h"
	"list.c" "list.h"
	"mainwindow.c" "mainwindow.h"
	"window.c" "window.h"
	"xalloc.c" "xalloc.h"
)
set_property(TARGET cracken PROPERTY C_STANDARD 11)

target_link_libraries(cracken setupapi.lib hid.lib comctl32.lib)

