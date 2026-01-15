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

    // Create library modules
    const supervision_mod = b.addModule("supervision", .{
        .root_source_file = b.path("src/lib/supervision.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    const config_loader_mod = b.addModule("config_loader", .{
        .root_source_file = b.path("src/lib/config/loader.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "supervision", .module = supervision_mod },
        },
    });
    
    const dependency_mod = b.addModule("dependency", .{
        .root_source_file = b.path("src/lib/dependency.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "supervision", .module = supervision_mod },
        },
    });
    
    // Main init system executable
    const init_mod = b.addModule("init", .{
        .root_source_file = b.path("src/init/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "supervision", .module = supervision_mod },
            .{ .name = "config_loader", .module = config_loader_mod },
            .{ .name = "dependency", .module = dependency_mod },
        },
    });
    
    const init_exe = b.addExecutable(.{
        .name = "sevenos-init",
        .root_module = init_mod,
    });

    // Link against libc for system calls (initially)
    // TODO: Consider libc-free approach for full Grain Style compliance
    init_exe.linkLibC();

    b.installArtifact(init_exe);

    // Grainscript Language module (for .gr file execution)
    // Use root.zig which re-exports all components
    const grainscript_mod = b.addModule("grainscript", .{
        .root_source_file = b.path("../../src/grainscript/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Grainscript Shell executable
    const shell_mod = b.addModule("shell", .{
        .root_source_file = b.path("src/shell/grainscript.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "supervision", .module = supervision_mod },
            .{ .name = "grainscript", .module = grainscript_mod },
        },
    });
    
    const shell_exe = b.addExecutable(.{
        .name = "grainscript-shell",
        .root_module = shell_mod,
    });

    // Link against libc for system calls
    shell_exe.linkLibC();

    b.installArtifact(shell_exe);

    // Service supervision library (TODO: implement supervision.zig)
    // const supervision_lib = b.addStaticLibrary(.{
    //     .name = "sevenos-supervision",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/lib/supervision.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     }),
    // });

    // supervision_lib.linkLibC();
    // b.installLibrary(supervision_lib);

    // Run init system tests
    const init_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/init/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_init_tests = b.addRunArtifact(init_tests);
    const init_test_step = b.step("test-init", "Run init system unit tests");
    init_test_step.dependOn(&run_init_tests.step);

    // Run shell tests
    const shell_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/shell/test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_shell_tests = b.addRunArtifact(shell_tests);
    const shell_test_step = b.step("test-shell", "Run shell unit tests");
    shell_test_step.dependOn(&run_shell_tests.step);

    // Integration test helpers module
    const integration_test_mod = b.addModule("integration_test", .{
        .root_source_file = b.path("src/test/integration_test.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "supervision", .module = supervision_mod },
        },
    });

    // Run shell integration tests
    const shell_integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/shell/integration_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "supervision", .module = supervision_mod },
                .{ .name = "integration_test", .module = integration_test_mod },
            },
        }),
    });
    
    shell_integration_tests.linkLibC();

    const run_shell_integration_tests = b.addRunArtifact(shell_integration_tests);
    const shell_integration_test_step = b.step("test-shell-integration", "Run shell integration tests");
    shell_integration_test_step.dependOn(&run_shell_integration_tests.step);

    // Run integration tests (init system integration test helpers)
    const integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test/integration_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "supervision", .module = supervision_mod },
            },
        }),
    });

    const run_integration_tests = b.addRunArtifact(integration_tests);
    const integration_test_step = b.step("test-integration", "Run integration test helpers");
    integration_test_step.dependOn(&run_integration_tests.step);

    // Service lifecycle integration tests module
    const lifecycle_test_mod = b.addModule("integration_test", .{
        .root_source_file = b.path("src/test/integration_test.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "supervision", .module = supervision_mod },
        },
    });

    // Run service lifecycle integration tests
    const lifecycle_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test/service_lifecycle_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "supervision", .module = supervision_mod },
                .{ .name = "integration_test", .module = lifecycle_test_mod },
            },
        }),
    });
    
    lifecycle_tests.linkLibC();

    const run_lifecycle_tests = b.addRunArtifact(lifecycle_tests);
    const lifecycle_test_step = b.step("test-lifecycle", "Run service lifecycle integration tests");
    lifecycle_test_step.dependOn(&run_lifecycle_tests.step);

    // Run configuration loading integration tests
    const config_loading_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test/config_loading_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "supervision", .module = supervision_mod },
                .{ .name = "config_loader", .module = config_loader_mod },
                .{ .name = "dependency", .module = dependency_mod },
            },
        }),
    });
    
    config_loading_tests.linkLibC();

    const run_config_loading_tests = b.addRunArtifact(config_loading_tests);
    const config_loading_test_step = b.step("test-config-loading", "Run configuration loading integration tests");
    config_loading_test_step.dependOn(&run_config_loading_tests.step);

    // Run all tests
    const test_step = b.step("test", "Run all unit tests");
    test_step.dependOn(init_test_step);
    test_step.dependOn(shell_test_step);
    test_step.dependOn(shell_integration_test_step);
    test_step.dependOn(integration_test_step);
    test_step.dependOn(lifecycle_test_step);
    test_step.dependOn(config_loading_test_step);
}

