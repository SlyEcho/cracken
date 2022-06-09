cmake_minimum_required (VERSION 3.8)

add_definitions(-DUNICODE -D_UNICODE -DWIN32_LEAN_AND_MEAN)

project ("cracken" C)

add_compile_options(-Wno-unused-parameter)

add_executable (cracken WIN32
	"app.c"
	"curve.c"
	"deviceenumerator.c"
	"hiddevice.c"
	"kraken.c"
	"krakenwidget.c"
	"layout.c"
	"list.c"
	"main.c"
	"mainwindow.c"
	"window.c"
	"xalloc.c"
	"cracken.manifest"
)
set_property(TARGET cracken PROPERTY C_STANDARD 11)

target_link_libraries(cracken setupapi hid comctl32 gdi32)
