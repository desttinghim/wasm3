const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create static library - this allows depending on wasm3 from the zig package manager
    const libwasm3 = b.addStaticLibrary(.{
        .name = "wasm3",
        .target = target,
        .optimize = optimize,
    });
    libwasm3.install();
    libwasm3.linkLibC();
    libwasm3.addIncludePath("source");

    libwasm3.addCSourceFiles(&.{
        "source/m3_api_libc.c",
        "source/m3_api_meta_wasi.c",
        "source/m3_api_tracer.c",
        "source/m3_api_uvwasi.c",
        "source/m3_api_wasi.c",
        "source/m3_bind.c",
        "source/m3_code.c",
        "source/m3_compile.c",
        "source/m3_core.c",
        "source/m3_env.c",
        "source/m3_exec.c",
        "source/m3_function.c",
        "source/m3_info.c",
        "source/m3_module.c",
        "source/m3_parse.c",
    }, &.{
        "-Dd_m3HasWASI",
        "-fno-sanitize=undefined", // TODO investigate UB sites in the codebase, then delete this line.
    });

    // Install header files
    libwasm3.installHeader("source/m3_api_libc.h", "m3_api_libc.h");
    libwasm3.installHeader("source/m3_api_wasi.h", "m3_api_wasi.h");
    libwasm3.installHeader("source/m3_bind.h", "m3_bind.h");
    libwasm3.installHeader("source/m3_config.h", "m3_config.h");
    libwasm3.installHeader("source/m3_config_platforms.h", "m3_config_platforms.h");
    libwasm3.installHeader("source/m3_code.h", "m3_code.h");
    libwasm3.installHeader("source/m3_compile.h", "m3_compile.h");
    libwasm3.installHeader("source/m3_core.h", "m3_core.h");
    libwasm3.installHeader("source/m3_env.h", "m3_env.h");
    libwasm3.installHeader("source/m3_exec.h", "m3_exec.h");
    libwasm3.installHeader("source/m3_exec_defs.h", "m3_exec_defs.h");
    libwasm3.installHeader("source/m3_function.h", "m3_function.h");
    libwasm3.installHeader("source/m3_info.h", "m3_info.h");
    libwasm3.installHeader("source/wasm3.h", "wasm3.h");
    libwasm3.installHeader("source/wasm3_defs.h", "wasm3_defs.h");

    // Create wasm3 cli
    const wasm3 = b.addExecutable(.{
        .name = "wasm3-cli",
        .target = target,
        .optimize = optimize,
    });
    wasm3.addCSourceFile("platforms/app/main.c", &.{
        "-Dd_m3HasWASI",
        "-fno-sanitize=undefined",
    });
    wasm3.linkLibrary(libwasm3);
    wasm3.installLibraryHeaders(libwasm3); // let zig know we want to use the libwasm3 installed headers
    wasm3.install();
    wasm3.linkLibC();

    if (target.getCpuArch() == .wasm32 and target.getOsTag() == .wasi) {
        wasm3.linkSystemLibrary("wasi-emulated-process-clocks");
    }
}
