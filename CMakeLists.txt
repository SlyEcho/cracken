cmake_minimum_required (VERSION 3.8)

add_definitions(-DUNICODE -D_UNICODE)

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
)
set_property(TARGET cracken PROPERTY C_STANDARD 11)

target_link_libraries(cracken setupapi hid comctl32 gdi32)

add_custom_command(
    TARGET cracken
    POST_BUILD
    COMMAND "mt.exe" -manifest \"${CMAKE_SOURCE_DIR}\\cracken.manifest\" -outputresource:"${CMAKE_BINARY_DIR}\\cracken.exe"\;\#1
    COMMENT "Adding manifest..."
)
