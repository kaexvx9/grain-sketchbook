const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .linux,
            .abi = .gnu,
        },
    });

    const optimize = b.standardOptimizeOption(.{});

    // DAG Core module (from main src/)
    const dag_core_mod = b.addModule("dag_core", .{
        .root_source_file = b.path("../../src/dag_core.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Zigimg module (for image format support)
    const zigimg_mod = b.addModule("zigimg", .{
        .root_source_file = b.path("../../grainstore/github/zigimg/zigimg/zigimg.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Media engine module
    const media_engine_mod = b.addModule("grainflow_media", .{
        .root_source_file = b.path("src/lib/media/engine.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zigimg", .module = zigimg_mod },
        },
    });

    // DAG synthesis module
    const dag_synthesis_mod = b.addModule("grainflow_dag", .{
        .root_source_file = b.path("src/lib/dag/synthesis.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "dag_core", .module = dag_core_mod },
            .{ .name = "grainflow_media", .module = media_engine_mod },
        },
    });

    // Grainscript media workflow module
    const grainscript_media_mod = b.addModule("grainflow_grainscript", .{
        .root_source_file = b.path("src/lib/grainscript/parser.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "grainflow_media", .module = media_engine_mod },
            .{ .name = "grainflow_dag", .module = dag_synthesis_mod },
        },
    });

    // Main Grainflow CLI executable
    const grainflow_cli_mod = b.addModule("grainflow_cli", .{
        .root_source_file = b.path("src/cli/grainflow.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "grainflow_media", .module = media_engine_mod },
            .{ .name = "grainflow_dag", .module = dag_synthesis_mod },
            .{ .name = "grainflow_grainscript", .module = grainscript_media_mod },
        },
    });

    const grainflow_exe = b.addExecutable(.{
        .name = "grainflow",
        .root_module = grainflow_cli_mod,
    });

    grainflow_exe.linkLibC();
    b.installArtifact(grainflow_exe);

    // Run step
    const run_step = b.step("run", "Run Grainflow CLI");
    const run_cmd = b.addRunArtifact(grainflow_exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Test step
    const test_step = b.step("test", "Run Grainflow tests");
    const media_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib/media/engine.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zigimg", .module = zigimg_mod },
            },
        }),
    });
    const run_media_tests = b.addRunArtifact(media_tests);
    test_step.dependOn(&run_media_tests.step);
}

