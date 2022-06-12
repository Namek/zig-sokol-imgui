const std = @import("std");
const builtin = @import("builtin");

const build_root = "../build/";
const cache_root = "../build/cache/";

const is_windows = builtin.os.tag == .windows;

pub fn build(b: *std.build.Builder) void {
    b.build_root = build_root;
    b.cache_root = cache_root;
    b.release_mode = .Debug;

    const mode = b.standardReleaseOptions();
const target = b.standardTargetOptions(.{});
    var exe = b.addExecutable("carbon", "../code/carbon.zig");
     exe.setTarget(target);
    exe.setOutputDir(build_root);
    exe.addIncludeDir("../code/");
    exe.setBuildMode(mode);
    exe.addCSourceFile("../code/sokol_compile.c", &[_][]const u8{});

    exe.addIncludeDir("cimgui");
    exe.addIncludeDir("cimgui/imgui");
    exe.addCSourceFiles(&[_][]const u8{
        "../code/cimgui/cimgui.cpp",
        "../code/cimgui/imgui/imgui.cpp",
        "../code/cimgui/imgui/imgui_demo.cpp",
        "../code/cimgui/imgui/imgui_draw.cpp",
        "../code/cimgui/imgui/imgui_widgets.cpp",
        "../code/cimgui/imgui/imgui_tables.cpp",
    }, &[_][]const u8 {});

    exe.linkLibCpp();
    if (is_windows) {
        // exe.addObjectFile("cimgui.obj");
        // exe.addObjectFile("imgui.obj");
        // exe.addObjectFile("imgui_demo.obj");
        // exe.addObjectFile("imgui_draw.obj");
        // exe.addObjectFile("imgui_widgets.obj");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
    } else {
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("GLEW");
    }

    var run_step = exe.run();
    run_step.step.dependOn(&exe.step);

    b.default_step.dependOn(&run_step.step);
}
