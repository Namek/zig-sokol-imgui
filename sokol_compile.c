#define SOKOL_IMPL
#if defined(_WIN32)
    #define SOKOL_GLCORE33
#elif defined(__APPLE__)
    #define SOKOL_METAL
#endif
#define SOKOL_NO_ENTRY
#include "sokol/sokol_app.h"
#include "sokol/sokol_gfx.h"
#include "sokol/sokol_time.h"
#include "sokol/sokol_glue.h"
#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS
// #define IMGUI_ENABLE_FREETYPE
// #define CIMGUI_FREETYPE
// #define IMGUI_FREETYPE
#include "deps/cimgui/cimgui.h"
#define SOKOL_IMGUI_IMPL
#include "sokol/util/sokol_imgui.h"
