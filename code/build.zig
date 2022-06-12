const std = @import("std");
const builtin = @import("builtin");

const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;

const build_root = "../build/";
const cache_root = "../build/cache/";

const is_windows = builtin.os.tag == .windows;

pub fn build(b: *Builder) void {
    b.build_root = build_root;
    b.cache_root = cache_root;
    b.release_mode = .Debug;

    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const cross_compiling_to_darwin = target.isDarwin() and (target.getOsTag() != builtin.os.tag);

    var exe = b.addExecutable("app", "../code/main.zig");
    exe.setTarget(target);
    exe.setOutputDir(build_root);
    exe.addIncludeDir("../code/");
    exe.setBuildMode(mode);
    // exe.addCSourceFile("../code/sokol_compile.c", &[_][]const u8{});

    exe.addIncludeDir("cimgui");
    exe.addIncludeDir("cimgui/imgui");
    exe.addCSourceFiles(&[_][]const u8{
        "../code/cimgui/cimgui.cpp",
        "../code/cimgui/imgui/imgui.cpp",
        "../code/cimgui/imgui/imgui_demo.cpp",
        "../code/cimgui/imgui/imgui_draw.cpp",
        "../code/cimgui/imgui/imgui_widgets.cpp",
        "../code/cimgui/imgui/imgui_tables.cpp",
    }, &[_][]const u8{});

    exe.linkLibCpp();
    exe.linkLibrary(libSokol(b, target, mode, cross_compiling_to_darwin, "../code/"));
    if (cross_compiling_to_darwin) {
        addDarwinCrossCompilePaths(b, exe);
    }

    // if (is_windows) {
    //     // exe.addObjectFile("cimgui.obj");
    //     // exe.addObjectFile("imgui.obj");
    //     // exe.addObjectFile("imgui_demo.obj");
    //     // exe.addObjectFile("imgui_draw.obj");
    //     // exe.addObjectFile("imgui_widgets.obj");
    //     exe.linkSystemLibrary("user32");
    //     exe.linkSystemLibrary("gdi32");
    // } else {
    //     // exe.linkSystemLibrary("GL");
    //     // exe.linkSystemLibrary("GLEW");
    // }

    exe.install();
    b.step("run", "Run the program").dependOn(&exe.run().step);
}

fn libSokol(b: *Builder, target: CrossTarget, mode: Mode, cross_compiling_to_darwin: bool, comptime prefix_path: []const u8) *LibExeObjStep {
    const lib = b.addStaticLibrary("sokol", null);
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.linkLibC();
    const sokol_path = prefix_path ++ "sokol_compile.c";
    if (lib.target.isDarwin()) {
        lib.addCSourceFile(sokol_path, &.{"-ObjC"});
        lib.linkFramework("MetalKit");
        lib.linkFramework("Metal");
        lib.linkFramework("AudioToolbox");
        if (target.getOsTag() == .ios) {
            lib.linkFramework("UIKit");
            lib.linkFramework("AVFoundation");
            lib.linkFramework("Foundation");
        } else {
            lib.linkFramework("Cocoa");
            lib.linkFramework("QuartzCore");
        }
    } else {
        lib.addCSourceFile(sokol_path, &.{});
        if (lib.target.isLinux()) {
            lib.linkSystemLibrary("X11");
            lib.linkSystemLibrary("Xi");
            lib.linkSystemLibrary("Xcursor");
            lib.linkSystemLibrary("GL");
            lib.linkSystemLibrary("asound");
        } else if (lib.target.isWindows()) {
            lib.linkSystemLibrary("kernel32");
            lib.linkSystemLibrary("user32");
            lib.linkSystemLibrary("gdi32");
            lib.linkSystemLibrary("ole32");
            lib.linkSystemLibrary("d3d11");
            lib.linkSystemLibrary("dxgi");
        }
    }
    // setup cross-compilation search paths
    if (cross_compiling_to_darwin) {
        addDarwinCrossCompilePaths(b, lib);
    }
    return lib;
}

fn addDarwinCrossCompilePaths(b: *Builder, step: *LibExeObjStep) void {
    checkDarwinSysRoot(b);
    step.addLibPath("/usr/lib");
    step.addSystemIncludeDir("/usr/include");
    step.addFrameworkDir("/System/Library/Frameworks");
}

fn checkDarwinSysRoot(b: *Builder) void {
    if (b.sysroot == null) {
        std.log.warn("===================================================================================", .{});
        std.log.warn("You haven't set the path to Apple SDK which may lead to build errors.", .{});
        std.log.warn("Hint: you can the path to Apple SDK with --sysroot <path> flag like so:", .{});
        std.log.warn("  zig build --sysroot $(xcrun --sdk iphoneos --show-sdk-path) -Dtarget=aarch64-ios", .{});
        std.log.warn("or:", .{});
        std.log.warn("  zig build --sysroot $(xcrun --sdk iphonesimulator --show-sdk-path) -Dtarget=aarch64-ios-simulator", .{});
        std.log.warn("===================================================================================", .{});
    }
}
