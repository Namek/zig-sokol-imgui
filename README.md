# What?

UI App template based on:
1. [Zig](https://ziglang.org/) programming language
2. Immediate UI library called [ImGUI](https://github.com/ocornut/imgui), platform   independent. The [sokol](https://github.com/floooh/sokol/) library provides per-OS implementation.
3. [FreeType](https://github.com/freetype/freetype) for better font rendering than ImGUI's default

## Points of care

1. **platforms**: Windows and MacOS. Linux support would be nice but I don't use it outside of terminal.
2. **High DPI**. In my case it's 125% scaling on Windows and 200% on Mac's Retina screen. This involves window/control scaling and nice font rendering.
3. **dependencies** as submodules linking to source repos, not copies of the repos. That might be easier to update.

# Build

`zig build run`
