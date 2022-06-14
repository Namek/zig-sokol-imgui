#define SOKOL_IMPL
#if defined(__APPLE__)
    #define SOKOL_METAL
#else
    #define SOKOL_GLCORE33
#endif
#define SOKOL_NO_ENTRY
#include "deps/sokol/sokol_app.h"
#include "deps/sokol/sokol_gfx.h"
#include "deps/sokol/sokol_time.h"
#include "deps/sokol/sokol_glue.h"
#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS
// #define IMGUI_ENABLE_FREETYPE
// #define CIMGUI_FREETYPE
// #define IMGUI_FREETYPE
#include "deps/cimgui/cimgui.h"
#define SOKOL_IMGUI_IMPL
#include "deps/sokol/util/sokol_imgui.h"
