const std = @import("std");
const builtin = @import("builtin");

const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;

const freetype = @import("deps/mach-freetype/build.zig");

const is_windows = builtin.os.tag == .windows;

pub fn build(b: *Builder) void {
    b.release_mode = .Debug;

    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const cross_compiling_to_darwin = target.isDarwin() and (target.getOsTag() != builtin.os.tag);

    var exe = b.addExecutable("app", "main.zig");
    exe.setTarget(target);
    exe.addIncludeDir("");
    exe.setBuildMode(mode);
        
    exe.defineCMacro("IMGUI_ENABLE_FREETYPE", "1");
    exe.defineCMacro("CIMGUI_FREETYPE", "1");
    exe.defineCMacro("IMGUI_FREETYPE", "1");
    exe.addSystemIncludeDir("deps/mach-freetype/upstream/freetype/include");
    exe.linkLibrary(libSokol(b, target, mode, cross_compiling_to_darwin, ""));
    freetype.link(b, exe, .{});

    exe.addIncludeDir("deps/cimgui/imgui");
    exe.addSystemIncludeDir("deps/cimgui/imgui");
    exe.addIncludeDir("deps/cimgui");
    exe.addSystemIncludeDir("deps/cimgui");
    exe.addCSourceFiles(&[_][]const u8{
        "deps/cimgui/cimgui.cpp",
        "deps/cimgui/imgui/imgui.cpp",
        "deps/cimgui/imgui/imgui_demo.cpp",
        "deps/cimgui/imgui/imgui_draw.cpp",
        "deps/cimgui/imgui/imgui_widgets.cpp",
        "deps/cimgui/imgui/imgui_tables.cpp",
        "deps/cimgui/imgui/misc/freetype/imgui_freetype.cpp",
    }, &[_][]const u8{});
    exe.addPackage(freetype.pkg);
    exe.linkLibCpp();
    if (cross_compiling_to_darwin) {
        addDarwinCrossCompilePaths(b, exe);
    }
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
