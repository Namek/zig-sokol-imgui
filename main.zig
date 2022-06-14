const std = @import("std");

const c = @import("c.zig");
const serialize = @import("serialize.zig");

fn zero_struct(comptime T: type) T {
    var variable: T = undefined;
    @memset(@ptrCast([*]u8, &variable), 0, @sizeOf(T));
    return variable;
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

const State = struct {
    pass_action: c.sg_pass_action,
    main_pipeline: c.sg_pipeline,
    main_bindings: c.sg_bindings,
};

var state: State = undefined;
var font: *c.ImFont = undefined;

export fn init() void {
    var desc = zero_struct(c.sg_desc);
    desc.context = c.sapp_sgcontext();
    c.sg_setup(&desc);

    c.stm_setup();

    var imgui_desc = zero_struct(c.simgui_desc_t);
    imgui_desc.no_default_font = true;
    c.simgui_setup(&imgui_desc);

    var io = c.igGetIO().*;
    var style = c.igGetStyle();
    c.igStyleColorsLight(style);

    var fontCfg = c.ImFontConfig_ImFontConfig().*;
    // fontCfg.OversampleH = 2;
    // fontCfg.OversampleV = 2;
    // fontCfg.RasterizerMultiply = 1.25;
    fontCfg.SizePixels = 18;
    const font_path = thisDir() ++ "/deps/cimgui/imgui/misc/fonts/DroidSans.ttf";

    font = c.ImFontAtlas_AddFontFromFileTTF(io.Fonts, font_path, 0, &fontCfg, c.ImFontAtlas_GetGlyphRangesDefault(io.Fonts));
    _ = c.ImFontAtlas_Build(io.Fonts);

    var font_pixels: [*c]u8 = undefined;
    var font_width: i32 = undefined;
    var font_height: i32 = undefined;
    c.ImFontAtlas_GetTexDataAsRGBA32(io.Fonts, &font_pixels, &font_width, &font_height, null);
    var img_desc = zero_struct(c.sg_image_desc);
    img_desc.width = font_width;
    img_desc.height = font_height;
    img_desc.pixel_format = c.SG_PIXELFORMAT_RGBA8;
    img_desc.wrap_u = c.SG_WRAP_CLAMP_TO_EDGE;
    img_desc.wrap_v = c.SG_WRAP_CLAMP_TO_EDGE;
    img_desc.min_filter = c.SG_FILTER_NEAREST;
    img_desc.mag_filter = c.SG_FILTER_NEAREST;
    img_desc.data.subimage[0][0].ptr = font_pixels;
    img_desc.data.subimage[0][0].size = @intCast(usize, font_width * font_height * 4);
    img_desc.label = "custom-font";
    const img = c.sg_make_image(&img_desc);
    io.Fonts.*.TexID = @intToPtr(*anyopaque, img.id);

    state.pass_action.colors[0].action = c.SG_ACTION_CLEAR;
    state.pass_action.colors[0].value = c.sg_color{ .r = 0.2, .g = 0.2, .b = 0.2, .a = 1.0 };

    const vertices = [_]f32{
        // positions     // colors
        0.0,  0.5,  0.5, 1.0, 0.0, 0.0, 1.0,
        0.5,  -0.5, 0.5, 0.0, 1.0, 0.0, 1.0,
        -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0,
    };

    var buffer_desc = zero_struct(c.sg_buffer_desc);
    buffer_desc.size = vertices.len * @sizeOf(f32);
    buffer_desc.data.ptr = &vertices[0];
    buffer_desc.data.size = @sizeOf(@TypeOf(vertices));
    buffer_desc.type = c.SG_BUFFERTYPE_VERTEXBUFFER;
    buffer_desc.label = "triangle_vertices";
    state.main_bindings.vertex_buffers[0] = c.sg_make_buffer(&buffer_desc);

    var shader_desc = zero_struct(c.sg_shader_desc);
    shader_desc.vs.source = switch (c.sg_query_backend()) {
        // .D3D11       => @embedFile("shaders/offscreen_vs.hlsl"),
        c.SG_BACKEND_GLCORE33 => @embedFile("shaders/vs.v330.glsl"),
        c.SG_BACKEND_GLES2 => @embedFile("shaders/vs.v100.glsl"),
        c.SG_BACKEND_METAL_MACOS, c.SG_BACKEND_METAL_SIMULATOR => @embedFile("shaders/vs.metal"),
        else => unreachable,
    };
    shader_desc.fs.source = switch (c.sg_query_backend()) {
        // .D3D11       => @embedFile("shaders/offscreen_fs.hlsl"),
        c.SG_BACKEND_GLCORE33 => @embedFile("shaders/fs.v330.glsl"),
        c.SG_BACKEND_GLES2 => @embedFile("shaders/fs.v100.glsl"),
        c.SG_BACKEND_METAL_MACOS, c.SG_BACKEND_METAL_SIMULATOR => @embedFile("shaders/fs.metal"),
        else => unreachable,
    };

    const shader = c.sg_make_shader(&shader_desc);

    var pipeline_desc = zero_struct(c.sg_pipeline_desc);
    pipeline_desc.layout.attrs[0].format = c.SG_VERTEXFORMAT_FLOAT3;
    pipeline_desc.layout.attrs[1].format = c.SG_VERTEXFORMAT_FLOAT4;
    pipeline_desc.shader = shader;
    pipeline_desc.label = "main_pipeline";
    state.main_pipeline = c.sg_make_pipeline(&pipeline_desc);
}

var last_time: u64 = 0;
var show_test_window: bool = false;
var show_another_window: bool = false;
var display_menu: bool = false;

var f: f32 = 0.0;
var inputTextBuf: [1024]u8 = undefined;

export fn update() void {
    const width = c.sapp_width();
    const height = c.sapp_height();
    var frame = c.simgui_frame_desc_t{
        .dpi_scale = 1,
        .width = width,
        .height = height,
        .delta_time = c.sapp_frame_duration(),
    };
    c.simgui_new_frame(&frame);
    c.igPushFont(font);
    if (display_menu) {
        c.igSetNextWindowPos(zero_struct(c.ImVec2), 0, zero_struct(c.ImVec2));
        c.igSetNextWindowSize(c.ImVec2{ .x = @intToFloat(f32, width), .y = @intToFloat(f32, height) }, 0);

        _ = c.igBegin("Window", null, (c.ImGuiWindowFlags_NoTitleBar) | (c.ImGuiWindowFlags_NoBringToFrontOnFocus) | (c.ImGuiWindowFlags_NoResize) | (c.ImGuiWindowFlags_NoMove) | (c.ImGuiWindowFlags_AlwaysAutoResize));
        _ = serialize.serialize_imgui(state, "state");

        c.igEnd();
    } else {
        c.igText("Hello, world!");
        _ = c.igInputText("Input text", &inputTextBuf, inputTextBuf.len, 0, null, null);
        _ = c.igSliderFloat("float", &f, 0.0, 1.0, "%.3f", 1.0);
        _ = c.igColorEdit3("clear color", @ptrCast(*f32, &state.pass_action.colors[0].value), 0);
        if (c.igButton("Test Window", c.ImVec2{ .x = 0.0, .y = 0.0 })) show_test_window = !show_test_window;
        if (c.igButton("Another Window", c.ImVec2{ .x = 0.0, .y = 0.0 })) show_another_window = !show_another_window;
        c.igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / c.igGetIO().*.Framerate, c.igGetIO().*.Framerate);

        if (show_another_window) {
            c.igSetNextWindowSize(c.ImVec2{ .x = 200, .y = 100 }, @intCast(c_int, c.ImGuiCond_FirstUseEver));
            _ = c.igBegin("Another Window", &show_another_window, 0);
            c.igText("Hello");
            c.igEnd();
        }

        if (show_test_window) {
            c.igSetNextWindowPos(c.ImVec2{ .x = 460, .y = 20 }, @intCast(c_int, c.ImGuiCond_FirstUseEver), c.ImVec2{ .x = 0, .y = 0 });
            c.igShowDemoWindow(0);
        }
    }

    c.sg_begin_default_pass(&state.pass_action, width, height);
    c.sg_apply_pipeline(state.main_pipeline);
    c.sg_apply_bindings(&state.main_bindings);
    c.sg_draw(0, 3, 1);
    c.igPopFont();
    c.simgui_render();
    c.sg_end_pass();
    c.sg_commit();
}

export fn cleanup() void {
    c.simgui_shutdown();
    c.sg_shutdown();
}

export fn event(e: [*c]const c.sapp_event) void {
    const evt = e[0];
    _ = c.simgui_handle_event(e);
    // std.debug.print("{any} {any} {any}\n", .{evt, evt.type, evt.key_code});

    if (evt.type == c.SAPP_EVENTTYPE_KEY_DOWN) {
        switch (evt.key_code) {
            c.SAPP_KEYCODE_TAB => display_menu = !display_menu,
            c.SAPP_KEYCODE_ESCAPE => c.sapp_quit(),
            else => {},
        }
    }
}

pub fn main() void {
    var app_desc = zero_struct(c.sapp_desc);
    app_desc.width = 800;
    app_desc.height = 600;
    app_desc.init_cb = init;
    app_desc.frame_cb = update;
    app_desc.cleanup_cb = cleanup;
    app_desc.event_cb = event;
    app_desc.high_dpi = true;

    _ = c.sapp_run(&app_desc);
}
