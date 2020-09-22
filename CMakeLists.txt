cmake_minimum_required (VERSION 3.8)

add_definitions(-DUNICODE -D_UNICODE)

project ("cracken" C)

add_executable (cracken WIN32 "main.c" "cracken.manifest"
	"mainwindow.c" "mainwindow.h"
	"app.c" "app.h"
	"window.c" "window.h"
	"hiddevice.c" "hiddevice.h"
	"list.c" "list.h"
	"deviceenumerator.c" "deviceenumerator.h"
	"kraken.c" "kraken.h"
	"xalloc.c" "xalloc.h"
	"krakenwidget.c" "krakenwidget.h"
	"layout.c" "layout.h"
)
set_property(TARGET cracken PROPERTY C_STANDARD 11)

target_link_libraries(cracken setupapi.lib hid.lib comctl32.lib)

