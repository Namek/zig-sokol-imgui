pub usingnamespace @cImport({
    @cDefine("SOKOL_GLCORE33", "");
    @cDefine("SOKOL_NO_ENTRY", "");
    @cInclude("deps/sokol/sokol_app.h");
    @cInclude("deps/sokol/sokol_gfx.h");
    @cInclude("deps/sokol/sokol_time.h");
    @cInclude("deps/sokol/sokol_glue.h");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cInclude("deps/cimgui/cimgui.h");
    @cInclude("deps/sokol/util/sokol_imgui.h");
});
