pub usingnamespace @cImport({
    @cDefine("SOKOL_GLCORE33", "");
    @cDefine("SOKOL_NO_ENTRY", "");
    @cInclude("sokol/sokol_app.h");
    @cInclude("sokol/sokol_gfx.h");
    @cInclude("sokol/sokol_time.h");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cInclude("deps/cimgui/cimgui.h");
    @cInclude("sokol/util/sokol_imgui.h");
});
