const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ray_module = b.addModule("ray", .{
        .root_source_file = b.path("src/ray.zig"),
        .target = target,
        .optimize = optimize,
    });

    const grainwrap_module = b.addModule("grainwrap", .{
        .root_source_file = b.path("vendor/grainwrap/src/grainwrap.zig"),
        .target = target,
        .optimize = optimize,
    });

    const grainvalidate_module = b.addModule("grainvalidate", .{
        .root_source_file = b.path("vendor/grainvalidate/src/grainvalidate.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zigimg_module = b.addModule("zigimg", .{
        .root_source_file = b.path("grainstore/github/zigimg/zigimg/zigimg.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ARCHIVED 2026-01-13 03:54:03 PST: TLS modules archived - not used by essential tests
    // Grain TLS implementation from grainstore (forked from ianic/tls.zig)
    // const grain_tls_impl_module = b.addModule("grain_tls_impl", .{
    //     .root_source_file = b.path("grainstore/github/kae3g/grain-tls/src/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13 03:54:03 PST: TLS module archived - not used by essential tests
    // TLS module (Grain TLS) - Simplified wrapper around grain_tls_impl
    // const tls_module = b.addModule("tls", .{
    //     .root_source_file = b.path("src/grain_tls/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "grain_tls_impl", .module = grain_tls_impl_module },
    //     },
    // });

    const graincard_exe = b.addExecutable(.{
        .name = "graincard",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/graincard.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zigimg", .module = zigimg_module },
            },
        }),
    });
    b.installArtifact(graincard_exe);

    const graincard_run = b.addRunArtifact(graincard_exe);
    const graincard_step = b.step("graincard", "Run the Graincard Generator");
    graincard_step.dependOn(&graincard_run.step);
    if (b.args) |args| {
        graincard_run.addArgs(args);
    }

    const exe = b.addExecutable(.{
        .name = "ray",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/ray_app.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "ray", .module = ray_module },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the Ray envelope printer");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const slicer = b.addExecutable(.{
        .name = "thread_slicer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/thread_slicer.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "ray", .module = ray_module },
            },
        }),
    });

    const thread_step = b.step("thread", "Regenerate docs/ray_160.md using the Zig slicer");
    const run_slicer = b.addRunArtifact(slicer);
    thread_step.dependOn(&run_slicer.step);
    run_slicer.step.dependOn(b.getInstallStep());

    const wrap_docs_exe = b.addExecutable(.{
        .name = "wrap_docs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/wrap_docs.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "grainwrap", .module = grainwrap_module },
            },
        }),
    });
    const wrap_docs_step = b.step("wrap-docs", "Wrap documentation to 73 columns");
    const run_wrap_docs = b.addRunArtifact(wrap_docs_exe);
    wrap_docs_step.dependOn(&run_wrap_docs.step);

    // ELF Parser module (for tests that need direct access).
    // ELF Parser module (for kernel and tests) - kept for kernel tests
    const elf_parser_module = b.addModule("elf_parser", .{
        .root_source_file = b.path("src/kernel/elf_parser.zig"),
        .target = target,
        .optimize = optimize,
    });
    _ = elf_parser_module; // Used by kernel tests

    // Basin Kernel module (syscall interface and kernel structures).
    // Note: basin_kernel.zig imports elf_parser.zig as a file (same directory).
    // Tests can import elf_parser as a module separately.
    const basin_kernel_module = b.addModule("basin_kernel", .{
        .root_source_file = b.path("src/kernel/basin_kernel.zig"),
        .target = target,
        .optimize = optimize,
    });

    // RISC-V SBI module (platform runtime services).
    // Why: Our own Grain Style SBI wrapper (inspired by CascadeOS/zig-sbi, MIT licensed).
    const sbi_module = b.addModule("sbi", .{
        .root_source_file = b.path("src/kernel_vm/sbi.zig"),
        .target = target,
        .optimize = optimize,
    });

    // RISC-V64 kernel target
    const kernel_target = std.Target.Query{
        .cpu_arch = .riscv64,
        .os_tag = .freestanding,
        .abi = .none,
    };
    const kernel_resolved = b.resolveTargetQuery(kernel_target);

    // Grainscript module for kernel (RISC-V64 target)
    const grainscript_kernel_module = b.addModule("grainscript", .{
        .root_source_file = b.path("src/grainscript/root.zig"),
        .target = kernel_resolved,
        .optimize = optimize,
    });

    const kernel_exe = b.addExecutable(.{
        .name = "grain-rv64",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kernel/main.zig"),
            .target = kernel_resolved,
            .optimize = optimize,
            .code_model = .medium,
            .imports = &.{
                .{ .name = "sbi", .module = sbi_module },
                .{ .name = "grainscript", .module = grainscript_kernel_module },
            },
        }),
    });
    kernel_exe.setLinkerScript(b.path("src/kernel/linker.ld"));
    kernel_exe.addAssemblyFile(b.path("src/kernel/entry.S"));
    const kernel_install = b.addInstallArtifact(kernel_exe, .{});
    const kernel_step = b.step("kernel-rv64", "Build Grain RISC-V kernel image");
    kernel_step.dependOn(&kernel_install.step);

    // Kernel platform module (for testing platform abstraction) - kept for kernel tests
    const kernel_platform_module = b.addModule("kernel_platform", .{
        .root_source_file = b.path("src/kernel/kernel_platform.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "sbi", .module = sbi_module },
            .{ .name = "basin_kernel", .module = basin_kernel_module },
        },
    });
    _ = kernel_platform_module; // Used by kernel tests

    // RISC-V VM module for kernel virtualization.
    const kernel_vm_module = b.addModule("kernel_vm", .{
        .root_source_file = b.path("src/kernel_vm/kernel_vm.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "sbi", .module = sbi_module },
            .{ .name = "basin_kernel", .module = basin_kernel_module },
        },
    });

    // Note: process_execution.zig is now in kernel_vm directory
    // Why: Avoids circular dependency - kernel_vm/integration.zig imports it as a file

    // Multi-architecture testing framework module.
    const test_framework_module = b.addModule("test_framework", .{
        .root_source_file = b.path("src/test_framework/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const grain_buffer_module = b.addModule("grain_buffer_terminal", .{
    //     .root_source_file = b.path("src/grain_buffer.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13 03:54:03 PST: Events module archived - not used by essential kernel tests
    // const events_module = b.addModule("events", .{
    //     .root_source_file = b.path("src/platform/events.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13 03:22:03 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Window module (macos_tahoe, for grain_terminal) - use different name to avoid conflict
    // const window_module_for_terminal = b.addModule("macos_window_terminal", .{
    //     .root_source_file = b.path("src/platform/macos_tahoe/window.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "events", .module = events_module },
    //     },
    // });

    // ARCHIVED 2026-01-13 03:22:03 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Grain Terminal module
    // const grain_terminal_module = b.addModule("grain_terminal", .{
    //     .root_source_file = b.path("src/grain_terminal/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "grain_buffer", .module = grain_buffer_module },
    //         .{ .name = "macos_window", .module = window_module_for_terminal },
    //         .{ .name = "grainscript", .module = grainscript_module },
    //     },
    // });

    // ARCHIVED 2026-01-13 03:22:03 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Grain Skate module
    // const grain_skate_module = b.addModule("grain_skate", .{
    //     .root_source_file = b.path("src/grain_skate/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "macos_window", .module = window_module_for_terminal },
    //         .{ .name = "events", .module = events_module },
    //     },
    // });

    // ARCHIVED 2026-01-13 03:54:03 PST: Grain Core module archived - not used by essential kernel tests
    // const grain_core_module = b.addModule("grain_core", .{
    //     .root_source_file = b.path("src/grain_core/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "basin_kernel", .module = basin_kernel_module },
    //     },
    // });

    // Grain Court module (formerly Grain Field)
    // TEMPORARILY DISABLED: const grain_court_module = b.addModule("grain_court", .{
    // TEMPORARILY DISABLED:     .root_source_file = b.path("src/grain_court/root.zig"),
    // TEMPORARILY DISABLED:     .target = target,
    // TEMPORARILY DISABLED:     .optimize = optimize,
    // TEMPORARILY DISABLED:     .imports = &.{
    // TEMPORARILY DISABLED:         .{ .name = "grain_core", .module = grain_core_module },
    // TEMPORARILY DISABLED:     },
    // TEMPORARILY DISABLED: });

    // ARCHIVED 2026-01-13 03:54:03 PST: Grain Silo module archived - not used by essential kernel tests
    // const grain_silo_module = b.addModule("grain_silo", .{
    //     .root_source_file = b.path("src/grain_silo/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const shared_module = b.addModule("shared", .{
    //     .root_source_file = b.path("src/shared/font_renderer.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const grain_carry_core_module = b.addModule("grain_carry_core", .{
    //     .root_source_file = b.path("src/grain_carry_core/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13 03:45:41 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Grain Workspace module
    // const grain_workspace_module = b.addModule("grain_workspace", .{
    //     .root_source_file = b.path("src/grain_workspace/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "grain_silo", .module = grain_silo_module },
    //         .{ .name = "grain_skate", .module = grain_skate_module },
    //         .{ .name = "grain_core", .module = grain_core_module },
    //     },
    // });

    // ARCHIVED 2026-01-13 03:54:03 PST: Grain Database module archived - not used by essential kernel tests
    // const grain_database_module = b.addModule("grain_database", .{
    //     .root_source_file = b.path("src/grain_database/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "grain_silo", .module = grain_silo_module },
    //         .{ .name = "grain_core", .module = grain_core_module },
    //     },
    // });

    // Dream Browser Components module (needed by Grain Bubble)
    // TEMPORARILY DISABLED: const dream_browser_components_module = b.addModule("dream_browser_components", .{
    // TEMPORARILY DISABLED:     .root_source_file = b.path("src/dream_browser_components.zig"),
    // TEMPORARILY DISABLED:     .target = target,
    // TEMPORARILY DISABLED:     .optimize = optimize,
    // TEMPORARILY DISABLED:     .imports = &.{
    // TEMPORARILY DISABLED:         .{ .name = "grain_workspace", .module = grain_workspace_module },
    // TEMPORARILY DISABLED:     },
    // TEMPORARILY DISABLED: });

    // Grain Bubble module
    // TEMPORARILY DISABLED: const _grain_bubble_module = b.addModule("grain_bubble", .{
    // TEMPORARILY DISABLED:     .root_source_file = b.path("src/grain_bubble/root.zig"),
    // TEMPORARILY DISABLED:     .target = target,
    // TEMPORARILY DISABLED:     .optimize = optimize,
    // TEMPORARILY DISABLED:     .imports = &.{
    // TEMPORARILY DISABLED:         .{ .name = "grain_core", .module = grain_core_module },
    // TEMPORARILY DISABLED:         .{ .name = "grain_workspace", .module = grain_workspace_module },
    // TEMPORARILY DISABLED:         .{ .name = "dream_browser_components", .module = dream_browser_components_module },
    // TEMPORARILY DISABLED:     },
    // TEMPORARILY DISABLED: });

    // Grain Flow module
    // TEMPORARILY DISABLED: const grain_flow_module = b.addModule("grain_flow", .{
    // TEMPORARILY DISABLED:     .root_source_file = b.path("src/grain_flow/root.zig"),
    // TEMPORARILY DISABLED:     .target = target,
    // TEMPORARILY DISABLED:     .optimize = optimize,
    // TEMPORARILY DISABLED:     .imports = &.{
    // TEMPORARILY DISABLED:         .{ .name = "grain_core", .module = grain_core_module },
    // TEMPORARILY DISABLED:         .{ .name = "grain_court", .module = grain_court_module },
    // TEMPORARILY DISABLED:     },
    // TEMPORARILY DISABLED: });

    // Grain Research module
    // TEMPORARILY DISABLED: const grain_research_module = b.addModule("grain_research", .{
    // TEMPORARILY DISABLED:     .root_source_file = b.path("src/grain_research/root.zig"),
    // TEMPORARILY DISABLED:     .target = target,
    // TEMPORARILY DISABLED:     .optimize = optimize,
    // TEMPORARILY DISABLED:     .imports = &.{
    // TEMPORARILY DISABLED:         .{ .name = "grain_court", .module = grain_court_module },
    // TEMPORARILY DISABLED:         .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED:     },
    // TEMPORARILY DISABLED: });

    // Kernel VM test executable (for testing VM functionality).
    const kernel_vm_test_exe = b.addExecutable(.{
        .name = "kernel_vm_test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kernel_vm/test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "kernel_vm", .module = kernel_vm_module },
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const kernel_vm_test_install = b.addInstallArtifact(kernel_vm_test_exe, .{});
    const kernel_vm_test_step = b.step("kernel-vm-test", "Test RISC-V VM functionality");
    kernel_vm_test_step.dependOn(&kernel_vm_test_install.step);
    const kernel_vm_test_run = b.addRunArtifact(kernel_vm_test_exe);
    kernel_vm_test_step.dependOn(&kernel_vm_test_run.step);

    // JIT Benchmark executable
    const benchmark_jit_exe = b.addExecutable(.{
        .name = "benchmark_jit",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kernel_vm/benchmark_jit.zig"),
            .target = target,
            .optimize = .ReleaseFast, // Benchmark should be optimized
            .imports = &.{
                .{ .name = "sbi", .module = sbi_module },
            },
        }),
    });
    const benchmark_jit_run = b.addRunArtifact(benchmark_jit_exe);
    const benchmark_jit_step = b.step("benchmark-jit", "Run JIT vs Interpreter benchmark");
    benchmark_jit_step.dependOn(&benchmark_jit_run.step);

    const validate_src_exe = b.addExecutable(.{
        .name = "validate_src",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/validate_src.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "grainvalidate", .module = grainvalidate_module },
            },
        }),
    });
    const validate_step = b.step("validate", "Validate source files against Grain style");
    const run_validate = b.addRunArtifact(validate_src_exe);
    validate_step.dependOn(&run_validate.step);

    const validate_kernel_exe = b.addExecutable(.{
        .name = "validate_kernel",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/validate_kernel.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "grainvalidate", .module = grainvalidate_module },
            },
        }),
    });
    const validate_kernel_step = b.step("validate-kernel", "Validate kernel files against Grain style (64 lines, 128 chars)");
    const run_validate_kernel = b.addRunArtifact(validate_kernel_exe);
    validate_kernel_step.dependOn(&run_validate_kernel.step);

    const conductor_exe = b.addExecutable(.{
        .name = "grain_conductor",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/grain_conductor.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const conduct_step = b.step("conduct", "Run Grain Conductor command suite");
    const run_conductor = b.addRunArtifact(conductor_exe);
    conduct_step.dependOn(&run_conductor.step);

    // Grain OS CLI tool
    const grainos_cli_exe = b.addExecutable(.{
        .name = "grainos",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/grainos_cli.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(grainos_cli_exe);

    const run_zon_phase4_validation_exe = b.addExecutable(.{
        .name = "run_zon_phase4_validation",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/run_zon_phase4_validation.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
            },
        }),
    });
    const run_zon_phase4_validation_step = b.step("run_zon_phase4_validation", "Run ZON Format Phase 4 Validation");
    const run_zon_phase4_validation_run = b.addRunArtifact(run_zon_phase4_validation_exe);
    run_zon_phase4_validation_step.dependOn(&run_zon_phase4_validation_run.step);

    // Framework x86_64 test runner (for multi-architecture testing).
    const framework_x86_64_test_runner = b.addExecutable(.{
        .name = "test_runner_framework_x86_64",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/test_runner_framework_x86_64.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "test_framework", .module = test_framework_module },
            },
        }),
    });
    b.installArtifact(framework_x86_64_test_runner);
    const framework_test_runner_step = b.step("test_runner_framework_x86_64", "Build Framework x86_64 test runner");
    framework_test_runner_step.dependOn(&b.addInstallArtifact(framework_x86_64_test_runner, .{}).step);

    const ray_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/ray.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const nostr_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/nostr.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const contracts_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/contracts.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const mmt_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/nostr_mmt.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const cdn_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tigerbank_cdn.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const lattice_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/grain_lattice.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // ARCHIVED 2026-01-13: Test references archived file
    // const prompts_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/unit/prompts_desc_order.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     }),
    // });

    const dm_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/dm.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const loop_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/grain_loop.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const daemon_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/graindaemon.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const buffer_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/grain_buffer.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const loom_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/grain_loom.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // TEMPORARILY DISABLED: const aurora_tests = b.addTest(.{
    // TEMPORARILY DISABLED:     .root_module = b.createModule(.{
    // TEMPORARILY DISABLED:         .root_source_file = b.path("src/grain_aurora.zig"),
    // TEMPORARILY DISABLED:         .target = target,
    // TEMPORARILY DISABLED:         .optimize = optimize,
    // TEMPORARILY DISABLED:     }),
    // TEMPORARILY DISABLED: });

    // ARCHIVED 2026-01-13: Tests reference archived aurora modules
    // const text_renderer_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/aurora_text_renderer.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "shared", .module = shared_module },
    //         },
    //     }),
    // });

    // const lsp_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/aurora_lsp.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     }),
    // });

    // const editor_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/aurora_editor.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     }),
    // });

    // const ai_provider_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/aurora_ai_provider.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     }),
    // });

    // const glm46_provider_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/aurora_glm46_provider.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     }),
    // });

    // const ai_transforms_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/aurora_ai_transforms.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     }),
    // });

    // Aurora Layout module
    // Aurora Errors module (foundational error types)

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_layout_module = b.addModule("aurora_layout", .{
    //     .root_source_file = b.path("src/aurora_layout.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Test references archived aurora_layout module
    // const layout_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/112_aurora_layout_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_layout", .module = aurora_layout_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_lsp_module = b.addModule("aurora_lsp", .{
    //     .root_source_file = b.path("src/aurora_lsp.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Modules archived - not used by essential tests
    // const aurora_ai_provider_module = b.addModule("aurora_ai_provider", .{
    //     .root_source_file = b.path("src/aurora_ai_provider.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const aurora_ai_transforms_module = b.addModule("aurora_ai_transforms", .{
    //     .root_source_file = b.path("src/aurora_ai_transforms.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_dag_integration_module = b.addModule("aurora_dag_integration", .{
    //     .root_source_file = b.path("src/aurora_dag_integration.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_folding_module = b.addModule("aurora_folding", .{
    //     .root_source_file = b.path("src/aurora_folding.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_tree_sitter_module = b.addModule("aurora_tree_sitter", .{
    //     .root_source_file = b.path("src/aurora_tree_sitter.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_tab_manager_module = b.addModule("aurora_tab_manager", .{
    //     .root_source_file = b.path("src/aurora_tab_manager.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Modules archived - not used by essential tests
    // const aurora_text_renderer_module = b.addModule("aurora_text_renderer", .{
    //     .root_source_file = b.path("src/aurora_text_renderer.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const aurora_filter_module = b.addModule("aurora_filter", .{
    //     .root_source_file = b.path("src/aurora_filter.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const aurora_vcs_module = b.addModule("aurora_vcs", .{
    //     .root_source_file = b.path("src/aurora_vcs.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const dag_core_module = b.addModule("dag_core", .{
    //     .root_source_file = b.path("src/dag_core.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const aurora_grainbank_module = b.addModule("aurora_grainbank", .{
    //     .root_source_file = b.path("src/aurora_grainbank.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_crash_module = b.addModule("aurora_crash", .{
    //     .root_source_file = b.path("src/aurora_crash.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_editor_module = b.addModule("aurora_editor", .{
    //     .root_source_file = b.path("src/aurora_editor.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Modules archived - not used by essential tests
    // const dream_browser_parser_module = b.addModule("dream_browser_parser", .{
    //     .root_source_file = b.path("src/dream_browser_parser.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const dream_browser_renderer_module = b.addModule("dream_browser_renderer", .{
    //     .root_source_file = b.path("src/dream_browser_renderer.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const dream_browser_dag_integration_module = b.addModule("dream_browser_dag_integration", .{
    //     .root_source_file = b.path("src/dream_browser_dag_integration.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const grain_aurora_module = b.addModule("grain_aurora", .{
    //     .root_source_file = b.path("src/grain_aurora.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_live_preview_module = b.addModule("aurora_live_preview", .{
    //     .root_source_file = b.path("src/aurora_live_preview.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "aurora_editor", .module = aurora_editor_module },
    //         .{ .name = "aurora_dag_integration", .module = aurora_dag_integration_module },
    //         .{ .name = "dream_browser_dag_integration", .module = dream_browser_dag_integration_module },
    //         .{ .name = "dag_core", .module = dag_core_module },
    //         .{ .name = "dream_browser_parser", .module = dream_browser_parser_module },
    //         .{ .name = "dream_browser_renderer", .module = dream_browser_renderer_module },
    //         .{ .name = "grain_buffer", .module = grain_buffer_module },
    //         .{ .name = "grain_aurora", .module = grain_aurora_module },
    //     },
    // });

    // Aurora GLM-4.6 module (for test imports)
    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_glm46_module = b.addModule("aurora_glm46", .{
    //     .root_source_file = b.path("src/aurora_glm46.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_glm46_provider_module = b.addModule("aurora_glm46_provider", .{
    //     .root_source_file = b.path("src/aurora_glm46_provider.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "aurora_ai_provider", .module = aurora_ai_provider_module },
    //         .{ .name = "aurora_glm46", .module = aurora_glm46_module },
    //     },
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_cocoa_module = b.addModule("aurora_cocoa", .{
    //     .root_source_file = b.path("src/aurora_cocoa.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Test references archived aurora_editor module
    // const editor_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/113_aurora_editor_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_editor", .module = aurora_editor_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Test references archived aurora_lsp module
    // const lsp_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/117_aurora_lsp_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_lsp", .module = aurora_lsp_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Test references archived aurora_ai_provider module
    // const ai_provider_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/118_aurora_ai_provider_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_ai_provider", .module = aurora_ai_provider_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Test references archived aurora_ai_transforms module
    // const ai_transforms_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/119_aurora_ai_transforms_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_ai_transforms", .module = aurora_ai_transforms_module },
    //         },
    //     }),
    // });

    // TEMPORARILY DISABLED: const dag_integration_test_file = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/120_aurora_dag_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "aurora_dag_integration", .module = aurora_dag_integration_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });

    // ARCHIVED 2026-01-13: Test references archived aurora_folding module
    // const folding_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/121_aurora_folding_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_folding", .module = aurora_folding_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Test references archived aurora_tree_sitter module
    // const tree_sitter_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/122_aurora_tree_sitter_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_tree_sitter", .module = aurora_tree_sitter_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Test references archived aurora_tab_manager module
    // const tab_manager_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/123_aurora_tab_manager_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_tab_manager", .module = aurora_tab_manager_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Tests reference archived aurora modules
    // const text_renderer_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/124_aurora_text_renderer_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_text_renderer", .module = aurora_text_renderer_module },
    //         },
    //     }),
    // });

    // const filter_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/125_aurora_filter_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_filter", .module = aurora_filter_module },
    //         },
    //     }),
    // });

    // const vcs_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/126_aurora_vcs_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_vcs", .module = aurora_vcs_module },
    //         },
    //     }),
    // });

    // const grainbank_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/127_aurora_grainbank_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_grainbank", .module = aurora_grainbank_module },
    //             .{ .name = "dag_core", .module = dag_core_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Test references archived aurora_crash module
    // const crash_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/128_aurora_crash_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_crash", .module = aurora_crash_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const dream_browser_viewport_module = b.addModule("dream_browser_viewport", .{
    //     .root_source_file = b.path("src/dream_browser_viewport.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_cross_integration_module = b.addModule("aurora_cross_integration", .{
    //     .root_source_file = b.path("src/aurora_cross_integration.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "aurora_editor", .module = aurora_editor_module },
    //         .{ .name = "dream_browser_viewport", .module = dream_browser_viewport_module },
    //     },
    // });

    // ARCHIVED 2026-01-13: Test references archived dream_browser_viewport module
    // const viewport_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/114_dream_browser_viewport_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "dream_browser_viewport", .module = dream_browser_viewport_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Module archived - not used by essential tests
    // const aurora_unified_ide_module = b.addModule("aurora_unified_ide", .{
    //     .root_source_file = b.path("src/aurora_unified_ide.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "aurora_editor", .module = aurora_editor_module },
    //         .{ .name = "aurora_layout", .module = aurora_layout_module },
    //         .{ .name = "dream_browser_parser", .module = dream_browser_parser_module },
    //         .{ .name = "dream_browser_renderer", .module = dream_browser_renderer_module },
    //         .{ .name = "dream_browser_viewport", .module = dream_browser_viewport_module },
    //         .{ .name = "grain_aurora", .module = grain_aurora_module },
    //         .{ .name = "aurora_grainbank", .module = aurora_grainbank_module },
    //         .{ .name = "dag_core", .module = dag_core_module },
    //         .{ .name = "dream_browser_dag_integration", .module = dream_browser_dag_integration_module },
    //         .{ .name = "aurora_live_preview", .module = aurora_live_preview_module },
    //         .{ .name = "grain_buffer", .module = grain_buffer_module },
    //     },
    // });

    // ARCHIVED 2026-01-13: Test references archived dream_browser_parser module
    // const parser_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/115_dream_browser_parser_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "dream_browser_parser", .module = dream_browser_parser_module },
    //         },
    //     }),
    // });

    const route_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/grain_route.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const orchestrator_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/grain_orchestrator.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const riscv_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/riscv_sys.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // ARCHIVED 2026-01-17: Test file not found - outputs_desc_order.zig doesn't exist
    // const outputs_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/unit/outputs_desc_order.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     }),
    // });

    // ARCHIVED 2026-01-13: Test references archived grain_carry_core module
    // const grain_carry_core_validation_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/108_grain_carry_core_validation_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Test references archived grain_carry_core module
    // const grain_carry_core_crypto_auth_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/109_grain_carry_core_crypto_auth_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Tests reference archived grain_carry_core module
    // const grain_carry_core_email_jwt_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/110_grain_carry_core_email_jwt_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // const grain_carry_core_style_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/111_grain_carry_core_style_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // const grain_carry_core_style_ffi_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/112_grain_carry_core_style_ffi_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // const grain_carry_core_api_client_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/113_grain_carry_core_api_client_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // const grain_carry_core_api_endpoints_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/114_grain_carry_core_api_endpoints_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // const grain_carry_core_api_models_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/115_grain_carry_core_api_models_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // const grain_carry_core_api_validation_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/116_grain_carry_core_api_validation_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // const grain_carry_core_api_handlers_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/117_grain_carry_core_api_handlers_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Test references archived grain_carry_core module
    // const grain_carry_core_api_middleware_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/118_grain_carry_core_api_middleware_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    // ARCHIVED 2026-01-13: Test references archived grain_carry_core module
    // const grain_carry_core_api_integration_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/119_grain_carry_core_api_integration_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    //         },
    //     }),
    // });

    const graindaemon_cli = b.addExecutable(.{
        .name = "graindaemon",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/graindaemon_cli.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const graindaemon_step = b.step("graindaemon", "Run the Graindaemon CLI");
    const run_graindaemon = b.addRunArtifact(graindaemon_cli);
    graindaemon_step.dependOn(&run_graindaemon.step);

    const aurora_preprocessor = b.addExecutable(.{
        .name = "aurora_preprocessor",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/aurora_preprocessor.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const aurora_assets_step = b.step("aurora-assets", "Run Aurora preprocessor stub");
    const _run_aurora_assets = b.addRunArtifact(aurora_preprocessor);
    _run_aurora_assets.addArg("sample.aurora");
    aurora_assets_step.dependOn(&_run_aurora_assets.step);

    const extract_outputs = b.addExecutable(.{
        .name = "extract_outputs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/extract_outputs.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(extract_outputs);
    const extract_step = b.step("extract-outputs", "Count '**Cursor**' markers in export");
    const run_extract = b.addRunArtifact(extract_outputs);
    run_extract.addArg("--help");
    extract_step.dependOn(&run_extract.step);

    // ARCHIVED 2026-01-13 03:22:03 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Grain Style: Print build progress for visibility.
    // std.debug.print("[build] Creating tahoe executable...\n", .{});
    // 
    // const tahoe_app = b.addExecutable(.{
    //     .name = "tahoe",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/tahoe_app.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "kernel_vm", .module = kernel_vm_module },
    //             .{ .name = "basin_kernel", .module = basin_kernel_module },
    //             .{ .name = "sbi", .module = sbi_module },
    //         },
    //         // Grain Style: Zig is strict by default - all safety checks enabled.
    //         // No need for additional flags - Zig catches all errors at compile time.
    //     }),
    // });
    // 
    // std.debug.print("[build] Adding C wrapper source: src/platform/macos_tahoe/objc_wrapper.c\n", .{});
    // // Add C wrapper for objc_msgSend to handle calling convention properly.
    // tahoe_app.addCSourceFiles(.{
    //     .files = &.{"src/platform/macos_tahoe/objc_wrapper.c"},
    //     .flags = &.{},
    // });
    // 
    // std.debug.print("[build] Linking macOS frameworks: AppKit, Foundation, CoreGraphics, QuartzCore\n", .{});
    // // Link macOS frameworks: AppKit and Foundation for Cocoa bridge, CoreGraphics for drawing, QuartzCore for CALayer.
    // tahoe_app.linkFramework("AppKit");
    // tahoe_app.linkFramework("Foundation");
    // tahoe_app.linkFramework("CoreGraphics");
    // tahoe_app.linkFramework("QuartzCore");
    // 
    // std.debug.print("[build] Installing tahoe artifact...\n", .{});
    // b.installArtifact(tahoe_app);
    // 
    // std.debug.print("[build] Creating tahoe build and run steps...\n", .{});
    // 
    // // Separate build step: just compile, don't run.
    // const tahoe_build_step = b.step("tahoe-build", "Build the macOS Tahoe Aurora GUI (without running)");
    // tahoe_build_step.dependOn(b.getInstallStep());
    // 
    // // Run step: build and then run the app.
    // const tahoe_step = b.step("tahoe", "Build and run the macOS Tahoe Aurora GUI");
    // const run_tahoe = b.addRunArtifact(tahoe_app);
    // tahoe_step.dependOn(&run_tahoe.step);

    // ARCHIVED 2026-01-13 03:22:03 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Grain Skate executable
    // std.debug.print("[build] Creating grain_skate executable...\n", .{});

    // const grain_skate_app = b.addExecutable(.{
    //     .name = "grain_skate",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/grain_skate_main.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_skate", .module = grain_skate_module },
    //             .{ .name = "events", .module = events_module },
    //         },
    //     }),
    // });

    // std.debug.print("[build] Adding C wrapper source: src/platform/macos_tahoe/objc_wrapper.c\n", .{});
    // // Add C wrapper for objc_msgSend to handle calling convention properly.
    // grain_skate_app.addCSourceFiles(.{
    //     .files = &.{"src/platform/macos_tahoe/objc_wrapper.c"},
    //     .flags = &.{},
    // });

    // std.debug.print("[build] Linking macOS frameworks: AppKit, Foundation, CoreGraphics, QuartzCore\n", .{});
    // // Link macOS frameworks: AppKit and Foundation for Cocoa bridge, CoreGraphics for drawing, QuartzCore for CALayer.
    // grain_skate_app.linkFramework("AppKit");
    // grain_skate_app.linkFramework("Foundation");
    // grain_skate_app.linkFramework("CoreGraphics");
    // grain_skate_app.linkFramework("QuartzCore");

    // std.debug.print("[build] Installing grain_skate artifact...\n", .{});
    // b.installArtifact(grain_skate_app);

    // std.debug.print("[build] Creating grain_skate build and run steps...\n", .{});

    // // Separate build step: just compile, don't run.
    // const grain_skate_build_step = b.step("grain-skate-build", "Build the macOS Grain Skate application (without running)");
    // grain_skate_build_step.dependOn(b.getInstallStep());

    // // Run step: build and then run the app.
    // const grain_skate_step = b.step("grain-skate", "Build and run the macOS Grain Skate application");
    // const run_grain_skate = b.addRunArtifact(grain_skate_app);
    // grain_skate_step.dependOn(&run_grain_skate.step);
    // run_tahoe.step.dependOn(b.getInstallStep());
    // 
    // std.debug.print("[build] Tahoe build configuration complete.\n", .{});
    // std.debug.print("[build] Use 'zig build tahoe-build' to compile without running.\n", .{});
    // std.debug.print("[build] Use 'zig build tahoe' to compile and run (will block until app quits).\n", .{});

    const test_step = b.step("test", "Run Ray plan tests");
    const run_ray_tests = b.addRunArtifact(ray_tests);
    test_step.dependOn(&run_ray_tests.step);
    const run_nostr_tests = b.addRunArtifact(nostr_tests);
    test_step.dependOn(&run_nostr_tests.step);
    const run_contract_tests = b.addRunArtifact(contracts_tests);
    test_step.dependOn(&run_contract_tests.step);
    const run_mmt_tests = b.addRunArtifact(mmt_tests);
    test_step.dependOn(&run_mmt_tests.step);
    const run_cdn_tests = b.addRunArtifact(cdn_tests);
    test_step.dependOn(&run_cdn_tests.step);
    const run_lattice_tests = b.addRunArtifact(lattice_tests);
    test_step.dependOn(&run_lattice_tests.step);
    // ARCHIVED 2026-01-13: Test references archived file
    // const run_prompts_tests = b.addRunArtifact(prompts_tests);
    // test_step.dependOn(&run_prompts_tests.step);
    const run_dm_tests = b.addRunArtifact(dm_tests);
    test_step.dependOn(&run_dm_tests.step);
    const run_loop_tests = b.addRunArtifact(loop_tests);
    test_step.dependOn(&run_loop_tests.step);
    const run_daemon_tests = b.addRunArtifact(daemon_tests);
    test_step.dependOn(&run_daemon_tests.step);
    const run_buffer_tests = b.addRunArtifact(buffer_tests);
    test_step.dependOn(&run_buffer_tests.step);
    const run_loom_tests = b.addRunArtifact(loom_tests);
    test_step.dependOn(&run_loom_tests.step);
    // TEMPORARILY DISABLED: const _run_aurora_tests = b.addRunArtifact(aurora_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&run_aurora_tests.step);
    // ARCHIVED 2026-01-13: Tests reference archived modules
    // const run_text_renderer_tests = b.addRunArtifact(text_renderer_tests);
    // test_step.dependOn(&run_text_renderer_tests.step);
    // const run_lsp_tests = b.addRunArtifact(lsp_tests);
    // test_step.dependOn(&run_lsp_tests.step);
    // const run_editor_tests = b.addRunArtifact(editor_tests);
    // test_step.dependOn(&run_editor_tests.step);
    // const run_ai_provider_tests = b.addRunArtifact(ai_provider_tests);
    // test_step.dependOn(&run_ai_provider_tests.step);
    // const run_glm46_provider_tests = b.addRunArtifact(glm46_provider_tests);
    // test_step.dependOn(&run_glm46_provider_tests.step);
    // const run_ai_transforms_tests = b.addRunArtifact(ai_transforms_tests);
    // test_step.dependOn(&run_ai_transforms_tests.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_layout module
    // const run_layout_tests = b.addRunArtifact(layout_tests);
    // test_step.dependOn(&run_layout_tests.step);
    // ARCHIVED 2026-01-13: Tests reference archived modules
    // const run_editor_test_file = b.addRunArtifact(editor_test_file);
    // test_step.dependOn(&run_editor_test_file.step);
    // const run_viewport_tests = b.addRunArtifact(viewport_tests);
    // test_step.dependOn(&run_viewport_tests.step);
    // ARCHIVED 2026-01-13: Test references archived dream_browser_parser module
    // const run_parser_tests = b.addRunArtifact(parser_tests);
    // test_step.dependOn(&run_parser_tests.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_lsp module
    // const run_lsp_test_file = b.addRunArtifact(lsp_test_file);
    // test_step.dependOn(&run_lsp_test_file.step);
    // ARCHIVED 2026-01-13: Tests reference archived modules
    // const run_ai_provider_test_file = b.addRunArtifact(ai_provider_test_file);
    // test_step.dependOn(&run_ai_provider_test_file.step);
    // const run_ai_transforms_test_file = b.addRunArtifact(ai_transforms_test_file);
    // test_step.dependOn(&run_ai_transforms_test_file.step);
    // TEMPORARILY DISABLED: const _run_dag_integration_test_file = b.addRunArtifact(dag_integration_test_file);
    // TEMPORARILY DISABLED: test_step.dependOn(&run_dag_integration_test_file.step);
    // ARCHIVED 2026-01-13: Test references archived module
    // const run_folding_test_file = b.addRunArtifact(folding_test_file);
    // test_step.dependOn(&run_folding_test_file.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_tree_sitter module
    // const run_tree_sitter_test_file = b.addRunArtifact(tree_sitter_test_file);
    // test_step.dependOn(&run_tree_sitter_test_file.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_tab_manager module
    // const run_tab_manager_test_file = b.addRunArtifact(tab_manager_test_file);
    // test_step.dependOn(&run_tab_manager_test_file.step);
    // ARCHIVED 2026-01-13: Tests reference archived aurora modules
    // const run_text_renderer_test_file = b.addRunArtifact(text_renderer_test_file);
    // test_step.dependOn(&run_text_renderer_test_file.step);
    // const run_filter_test_file = b.addRunArtifact(filter_test_file);
    // test_step.dependOn(&run_filter_test_file.step);
    // const run_vcs_test_file = b.addRunArtifact(vcs_test_file);
    // test_step.dependOn(&run_vcs_test_file.step);
    // const run_grainbank_test_file = b.addRunArtifact(grainbank_test_file);
    // test_step.dependOn(&run_grainbank_test_file.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_crash module
    // const run_crash_test_file = b.addRunArtifact(crash_test_file);
    // test_step.dependOn(&run_crash_test_file.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_live_preview module
    // const live_preview_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/129_aurora_live_preview_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_live_preview", .module = aurora_live_preview_module },
    //         },
    //     }),
    // });
    // ARCHIVED 2026-01-13: Test references archived module
    // const run_live_preview_test_file = b.addRunArtifact(live_preview_test_file);
    // test_step.dependOn(&run_live_preview_test_file.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_glm46_provider module
    // const glm46_provider_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/130_aurora_glm46_provider_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_glm46_provider", .module = aurora_glm46_provider_module },
    //             .{ .name = "aurora_ai_provider", .module = aurora_ai_provider_module },
    //         },
    //     }),
    // });
    // const run_glm46_provider_test_file = b.addRunArtifact(glm46_provider_test_file);
    // test_step.dependOn(&run_glm46_provider_test_file.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_glm46 module
    // const glm46_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/131_aurora_glm46_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_glm46", .module = aurora_glm46_module },
    //         },
    //     }),
    // });
    // const run_glm46_test_file = b.addRunArtifact(glm46_test_file);
    // test_step.dependOn(&run_glm46_test_file.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_cocoa module
    // const cocoa_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/132_aurora_cocoa_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_cocoa", .module = aurora_cocoa_module },
    //         },
    //     }),
    // });
    // const run_cocoa_test_file = b.addRunArtifact(cocoa_test_file);
    // test_step.dependOn(&run_cocoa_test_file.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_cross_integration module
    // const cross_integration_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/133_aurora_cross_integration_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_cross_integration", .module = aurora_cross_integration_module },
    //         },
    //     }),
    // });
    // const run_cross_integration_test_file = b.addRunArtifact(cross_integration_test_file);
    // test_step.dependOn(&run_cross_integration_test_file.step);
    // ARCHIVED 2026-01-13: Test references archived aurora_unified_ide module
    // const unified_ide_test_file = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/134_aurora_unified_ide_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "aurora_unified_ide", .module = aurora_unified_ide_module },
    //         },
    //     }),
    // });
    // const run_unified_ide_test_file = b.addRunArtifact(unified_ide_test_file);
    // test_step.dependOn(&run_unified_ide_test_file.step);
    const run_route_tests = b.addRunArtifact(route_tests);
    test_step.dependOn(&run_route_tests.step);
    const run_orchestrator_tests = b.addRunArtifact(orchestrator_tests);
    test_step.dependOn(&run_orchestrator_tests.step);
    const run_riscv_tests = b.addRunArtifact(riscv_tests);
    test_step.dependOn(&run_riscv_tests.step);
    
    // RISC-V Compliance Validation Test Suite
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const riscv_compliance_validation_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/riscv_compliance_validation_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_riscv_compliance_validation_tests = b.addRunArtifact(riscv_compliance_validation_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_riscv_compliance_validation_tests.step);
    
    // Syscall Combination Integration Tests (Phase 1)
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const syscall_combination_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/149_syscall_combination_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_syscall_combination_tests = b.addRunArtifact(syscall_combination_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_syscall_combination_tests.step);
    
    // Edge Case Integration Tests (Phase 2)
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const edge_case_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/150_edge_case_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_edge_case_tests = b.addRunArtifact(edge_case_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_edge_case_tests.step);
    
    // x86_64 JIT Emit Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const x86_64_jit_emit_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/154_x86_64_jit_emit_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_x86_64_jit_emit_tests = b.addRunArtifact(x86_64_jit_emit_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_x86_64_jit_emit_tests.step);
    
    // x86_64 JIT Translation Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const x86_64_jit_translation_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/155_x86_64_jit_translation_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_x86_64_jit_translation_tests = b.addRunArtifact(x86_64_jit_translation_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_x86_64_jit_translation_tests.step);
    
    // Stress Integration Tests (Phase 3)
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const stress_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/151_stress_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_stress_tests = b.addRunArtifact(stress_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_stress_tests.step);
    
    // Error Handling Integration Tests (Phase 4)
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const error_handling_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/152_error_handling_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_error_handling_integration_tests = b.addRunArtifact(error_handling_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_error_handling_integration_tests.step);
    
    // Syscall Performance Profiler Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const syscall_performance_profiler_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/143_syscall_performance_profiler_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_syscall_performance_profiler_tests = b.addRunArtifact(syscall_performance_profiler_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_syscall_performance_profiler_tests.step);
    
    // Syscall Performance Benchmark Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const syscall_performance_benchmark_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/144_syscall_performance_benchmark_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_syscall_performance_benchmark_tests = b.addRunArtifact(syscall_performance_benchmark_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_syscall_performance_benchmark_tests.step);
    
    // ARCHIVED 2026-01-17: Test file not found - outputs_desc_order.zig doesn't exist
    // const run_outputs_tests = b.addRunArtifact(outputs_tests);
    // test_step.dependOn(&run_outputs_tests.step);
    // ARCHIVED 2026-01-13: Tests reference archived grain_carry_core module
    // const run_grain_carry_core_validation_tests = b.addRunArtifact(grain_carry_core_validation_tests);
    // test_step.dependOn(&run_grain_carry_core_validation_tests.step);
    // const run_grain_carry_core_crypto_auth_tests = b.addRunArtifact(grain_carry_core_crypto_auth_tests);
    // test_step.dependOn(&run_grain_carry_core_crypto_auth_tests.step);
    // const run_grain_carry_core_email_jwt_tests = b.addRunArtifact(grain_carry_core_email_jwt_tests);
    // test_step.dependOn(&run_grain_carry_core_email_jwt_tests.step);
    // const run_grain_carry_core_style_tests = b.addRunArtifact(grain_carry_core_style_tests);
    // test_step.dependOn(&run_grain_carry_core_style_tests.step);
    // const run_grain_carry_core_style_ffi_tests = b.addRunArtifact(grain_carry_core_style_ffi_tests);
    // test_step.dependOn(&run_grain_carry_core_style_ffi_tests.step);
    // const run_grain_carry_core_api_client_tests = b.addRunArtifact(grain_carry_core_api_client_tests);
    // test_step.dependOn(&run_grain_carry_core_api_client_tests.step);
    // const run_grain_carry_core_api_endpoints_tests = b.addRunArtifact(grain_carry_core_api_endpoints_tests);
    // test_step.dependOn(&run_grain_carry_core_api_endpoints_tests.step);
    // const run_grain_carry_core_api_models_tests = b.addRunArtifact(grain_carry_core_api_models_tests);
    // test_step.dependOn(&run_grain_carry_core_api_models_tests.step);
    // const run_grain_carry_core_api_validation_tests = b.addRunArtifact(grain_carry_core_api_validation_tests);
    // test_step.dependOn(&run_grain_carry_core_api_validation_tests.step);
    // const run_grain_carry_core_api_handlers_tests = b.addRunArtifact(grain_carry_core_api_handlers_tests);
    // test_step.dependOn(&run_grain_carry_core_api_handlers_tests.step);
    // ARCHIVED 2026-01-13: Test references archived grain_carry_core module
    // const run_grain_carry_core_api_middleware_tests = b.addRunArtifact(grain_carry_core_api_middleware_tests);
    // test_step.dependOn(&run_grain_carry_core_api_middleware_tests.step);
    // ARCHIVED 2026-01-13: Test references archived grain_carry_core module
    // const run_grain_carry_core_api_integration_tests = b.addRunArtifact(grain_carry_core_api_integration_tests);
    // test_step.dependOn(&run_grain_carry_core_api_integration_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_carry_core_api_middleware_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/120_grain_carry_core_api_middleware_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_grain_carry_core_api_middleware_integration_tests = b.addRunArtifact(grain_carry_core_api_middleware_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_grain_carry_core_api_middleware_integration_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_carry_core_api_route_registration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/121_grain_carry_core_api_route_registration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_grain_carry_core_api_route_registration_tests = b.addRunArtifact(grain_carry_core_api_route_registration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_grain_carry_core_api_route_registration_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_carry_core_api_handler_adapters_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/122_grain_carry_core_api_handler_adapters_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_grain_carry_core_api_handler_adapters_tests = b.addRunArtifact(grain_carry_core_api_handler_adapters_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_grain_carry_core_api_handler_adapters_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_carry_core_auth_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/123_grain_carry_core_auth_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_grain_carry_core_auth_integration_tests = b.addRunArtifact(grain_carry_core_auth_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_grain_carry_core_auth_integration_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_carry_core_api_integration_pipeline_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/123_grain_carry_core_api_integration_pipeline_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_grain_carry_core_api_integration_pipeline_tests = b.addRunArtifact(grain_carry_core_api_integration_pipeline_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_grain_carry_core_api_integration_pipeline_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_carry_core_api_auth_service_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/124_grain_carry_core_api_auth_service_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_grain_carry_core_api_auth_service_integration_tests = b.addRunArtifact(grain_carry_core_api_auth_service_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_grain_carry_core_api_auth_service_integration_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_carry_core_websocket_client_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/125_grain_carry_core_websocket_client_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_grain_carry_core_websocket_client_tests = b.addRunArtifact(grain_carry_core_websocket_client_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_grain_carry_core_websocket_client_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_carry_core_api_http_client_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/127_grain_carry_core_api_http_client_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_grain_carry_core_api_http_client_integration_tests = b.addRunArtifact(grain_carry_core_api_http_client_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_grain_carry_core_api_http_client_integration_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_carry_core_oauth_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/128_grain_carry_core_oauth_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_grain_carry_core_oauth_tests = b.addRunArtifact(grain_carry_core_oauth_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_grain_carry_core_oauth_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_carry_core_database_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/129_grain_carry_core_database_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_carry_core", .module = grain_carry_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_grain_carry_core_database_integration_tests = b.addRunArtifact(grain_carry_core_database_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_grain_carry_core_database_integration_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_004_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/004_fuzz.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_004_step = b.step("fuzz-004", "Run 004 fuzz tests for RISC-V VM");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     fuzz_004_step.dependOn(&fuzz_004_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_005_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/005_fuzz.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "sbi", .module = sbi_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_005_step = b.step("fuzz-005", "Run 005 fuzz tests for SBI + kernel syscall integration");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     fuzz_005_step.dependOn(&fuzz_005_tests.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_006_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/006_fuzz.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_006_run = b.addRunArtifact(fuzz_006_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_006_step = b.step("fuzz-006", "Run 006 fuzz tests for memory management foundation");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     fuzz_006_step.dependOn(&fuzz_006_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_007_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/007_fuzz.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_007_run = b.addRunArtifact(fuzz_007_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_007_step = b.step("fuzz-007", "Run 007 fuzz tests for file system foundation");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     fuzz_007_step.dependOn(&fuzz_007_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_006_simple_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/006_simple_at_commit.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_006_simple_run = b.addRunArtifact(fuzz_006_simple_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_006_simple_step = b.step("fuzz-006-simple", "Run simple 006 test at commit 0d618a3");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     fuzz_006_simple_step.dependOn(&fuzz_006_simple_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/011_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const integration_run = b.addRunArtifact(integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const integration_step = b.step("integration-test", "Run integration tests for VM-kernel layer");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     integration_step.dependOn(&integration_run.step);

    // RISC-V64 userspace target (for compiling userspace programs).
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const userspace_target = std.Target.Query{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .cpu_arch = .riscv64,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .os_tag = .freestanding,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .abi = .none,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     };
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const integration_run = b.addRunArtifact(integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const integration_step = b.step("integration-test", "Run integration tests for VM-kernel layer");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     integration_step.dependOn(&integration_run.step);

    // RISC-V64 userspace target (for compiling userspace programs).
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const userspace_target = std.Target.Query{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .cpu_arch = .riscv64,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .os_tag = .freestanding,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .abi = .none,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     };
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //     const userspace_resolved = b.resolveTargetQuery(userspace_target);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // 
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // Userspace stdlib module (for userspace programs - must use userspace target).
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //     const userspace_stdlib_module = b.addModule("userspace_stdlib", .{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         .root_source_file = b.path("src/userspace/stdlib.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //     });

    // Userspace args module (for argument parsing in utilities).
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const userspace_args_module = b.addModule("userspace_args", .{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_source_file = b.path("src/userspace/utils/args.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //     });

    // Hello World userspace executable (RISC-V64).
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const hello_world_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .name = "hello_world",
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("examples/hello_world.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     hello_world_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const hello_world_install = b.addInstallArtifact(hello_world_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const hello_world_step = b.step("hello-world", "Build Hello World userspace program for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     hello_world_step.dependOn(&hello_world_install.step);

    // Framebuffer Demo userspace executable (RISC-V64).
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fb_demo_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .name = "fb_demo",
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("src/userspace/fb_demo.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const fb_demo_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .name = "fb_demo",
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("src/userspace/fb_demo.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     fb_demo_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fb_demo_install = b.addInstallArtifact(fb_demo_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fb_demo_step = b.step("fb-demo", "Build Framebuffer Demo userspace program for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     fb_demo_step.dependOn(&fb_demo_install.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const hello_world_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/012_hello_world_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const hello_world_tests_run = b.addRunArtifact(hello_world_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const hello_world_tests_step = b.step("hello-world-test", "Test Hello World program in VM");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     hello_world_tests_step.dependOn(&hello_world_tests_run.step);
    // Make hello-world-test depend on hello-world being built first.
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     hello_world_tests_step.dependOn(&hello_world_install.step);

    // Framebuffer Demo tests.
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fb_demo_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/013_fb_demo_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fb_demo_tests_run = b.addRunArtifact(fb_demo_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fb_demo_tests_step = b.step("fb-demo-test", "Test Framebuffer Demo program in VM");
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     fb_demo_tests_step.dependOn(&fb_demo_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     fb_demo_tests_step.dependOn(&fb_demo_install.step);

    // Kernel and VM tests
    // Framebuffer module (needed by kernel integration test)
    const framebuffer_module = b.addModule("framebuffer", .{
        .root_source_file = b.path("src/kernel/framebuffer.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const framebuffer_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/framebuffer_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "framebuffer", .module = framebuffer_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const framebuffer_tests_run = b.addRunArtifact(framebuffer_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&framebuffer_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const framebuffer_syscall_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/framebuffer_syscall_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "framebuffer", .module = framebuffer_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const framebuffer_syscall_tests_run = b.addRunArtifact(framebuffer_syscall_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&framebuffer_syscall_tests_run.step);

    const kernel_integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/014_kernel_integration_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "kernel_vm", .module = kernel_vm_module },
                .{ .name = "basin_kernel", .module = basin_kernel_module },
                .{ .name = "framebuffer", .module = framebuffer_module },
            },
        }),
    });
    const kernel_integration_tests_run = b.addRunArtifact(kernel_integration_tests);
    test_step.dependOn(&kernel_integration_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const dirty_region_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/015_dirty_region_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "framebuffer", .module = framebuffer_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const dirty_region_tests_run = b.addRunArtifact(dirty_region_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&dirty_region_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const error_handling_unit_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/016_error_handling_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const error_handling_unit_tests_run = b.addRunArtifact(error_handling_unit_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&error_handling_unit_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const performance_monitoring_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/017_performance_monitoring_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const performance_monitoring_tests_run = b.addRunArtifact(performance_monitoring_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&performance_monitoring_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const state_persistence_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/018_state_persistence_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const state_persistence_tests_run = b.addRunArtifact(state_persistence_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&state_persistence_tests_run.step);

    const timer_driver_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/020_timer_driver_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const timer_driver_tests_run = b.addRunArtifact(timer_driver_tests);
    test_step.dependOn(&timer_driver_tests_run.step);

    const interrupt_controller_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/021_interrupt_controller_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const interrupt_controller_tests_run = b.addRunArtifact(interrupt_controller_tests);
    test_step.dependOn(&interrupt_controller_tests_run.step);

    const process_scheduler_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/022_process_scheduler_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const process_scheduler_tests_run = b.addRunArtifact(process_scheduler_tests);
    test_step.dependOn(&process_scheduler_tests_run.step);

    const ipc_channel_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/023_ipc_channel_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const ipc_channel_tests_run = b.addRunArtifact(ipc_channel_tests);
    test_step.dependOn(&ipc_channel_tests_run.step);

    const process_elf_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/024_process_elf_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
                .{ .name = "kernel_vm", .module = kernel_vm_module },
            },
        }),
    });
    const process_elf_tests_run = b.addRunArtifact(process_elf_tests);
    test_step.dependOn(&process_elf_tests_run.step);

    const kernel_process_enumeration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/075_kernel_process_enumeration_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const kernel_process_enumeration_tests_run = b.addRunArtifact(kernel_process_enumeration_tests);
    test_step.dependOn(&kernel_process_enumeration_tests_run.step);

    const kernel_log_reading_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/076_kernel_log_reading_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const kernel_log_reading_tests_run = b.addRunArtifact(kernel_log_reading_tests);
    test_step.dependOn(&kernel_log_reading_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const cpu_time_tracking_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/077_cpu_time_tracking_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const cpu_time_tracking_tests_run = b.addRunArtifact(cpu_time_tracking_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&cpu_time_tracking_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const memory_usage_tracking_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/078_memory_usage_tracking_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const memory_usage_tracking_tests_run = b.addRunArtifact(memory_usage_tracking_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&memory_usage_tracking_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const enhanced_sysinfo_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/079_enhanced_sysinfo_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const enhanced_sysinfo_tests_run = b.addRunArtifact(enhanced_sysinfo_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&enhanced_sysinfo_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const process_priority_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/080_process_priority_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const process_priority_tests_run = b.addRunArtifact(process_priority_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&process_priority_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const process_group_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/081_process_group_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const process_group_tests_run = b.addRunArtifact(process_group_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&process_group_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const signal_session_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/083_signal_session_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const signal_session_tests_run = b.addRunArtifact(signal_session_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&signal_session_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const process_group_stats_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/084_process_group_stats_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const process_group_stats_tests_run = b.addRunArtifact(process_group_stats_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&process_group_stats_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const process_group_limits_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/085_process_group_limits_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const process_group_limits_tests_run = b.addRunArtifact(process_group_limits_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&process_group_limits_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const storage_filesystem_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/025_storage_filesystem_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const storage_filesystem_tests_run = b.addRunArtifact(storage_filesystem_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&storage_filesystem_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const keyboard_mouse_driver_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/026_keyboard_mouse_driver_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const keyboard_mouse_driver_tests_run = b.addRunArtifact(keyboard_mouse_driver_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&keyboard_mouse_driver_tests_run.step);

    // Memory module for memory allocator tests
    const memory_module = b.addModule("memory", .{
        .root_source_file = b.path("src/kernel/memory.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ARCHIVED 2026-01-13 03:22:03 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Window module for window tests (defined before use in fuzz_003_tests)
    // const window_module = b.addModule("window", .{
    //     .root_source_file = b.path("src/platform/macos_tahoe/window.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "events", .module = events_module },
    //     },
    // });
    
    const memory_allocator_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/027_memory_allocator_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
                .{ .name = "memory", .module = memory_module },
            },
        }),
    });
    const memory_allocator_tests_run = b.addRunArtifact(memory_allocator_tests);
    test_step.dependOn(&memory_allocator_tests_run.step);

    // Boot module for boot sequence tests (defined before use, after basin_kernel)
    // Note: boot.zig is imported by basin_kernel.zig, so we can't create a separate module
    // Instead, we'll use relative imports in the test
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const boot_sequence_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/028_boot_sequence_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const boot_sequence_tests_run = b.addRunArtifact(boot_sequence_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&boot_sequence_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const trap_handler_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/029_trap_handler_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const trap_handler_tests_run = b.addRunArtifact(trap_handler_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&trap_handler_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const process_execution_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/041_process_execution_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const process_execution_tests_run = b.addRunArtifact(process_execution_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&process_execution_tests_run.step);

    const scheduler_integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/042_scheduler_integration_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "kernel_vm", .module = kernel_vm_module },
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const scheduler_integration_tests_run = b.addRunArtifact(scheduler_integration_tests);
    test_step.dependOn(&scheduler_integration_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const program_segment_loading_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/048_program_segment_loading_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "elf_parser", .module = elf_parser_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const program_segment_loading_tests_run = b.addRunArtifact(program_segment_loading_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&program_segment_loading_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const resource_cleanup_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/049_resource_cleanup_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const resource_cleanup_tests_run = b.addRunArtifact(resource_cleanup_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&resource_cleanup_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const channel_send_recv_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/050_channel_send_recv_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const channel_send_recv_tests_run = b.addRunArtifact(channel_send_recv_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&channel_send_recv_tests_run.step);

    const comprehensive_userspace_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/051_comprehensive_userspace_execution_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const comprehensive_userspace_tests_run = b.addRunArtifact(comprehensive_userspace_tests);
    test_step.dependOn(&comprehensive_userspace_tests_run.step);

    const terminal_kernel_integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/047_terminal_kernel_integration_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "kernel_vm", .module = kernel_vm_module },
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const terminal_kernel_integration_tests_run = b.addRunArtifact(terminal_kernel_integration_tests);
    test_step.dependOn(&terminal_kernel_integration_tests_run.step);

    // ARCHIVED 2026-01-13 03:45:41 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Grain Terminal tests
    // const grain_terminal_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/045_grain_terminal_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_terminal", .module = grain_terminal_module },
    //         },
    //     }),
    // });
    // const grain_terminal_tests_run = b.addRunArtifact(grain_terminal_tests);
    // test_step.dependOn(&grain_terminal_tests_run.step);

    // ARCHIVED 2026-01-13 03:45:41 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // const grain_terminal_ui_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/046_grain_terminal_ui_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_terminal", .module = grain_terminal_module },
    //             .{ .name = "grain_buffer", .module = grain_buffer_module },
    //             // .{ .name = "macos_window", .module = window_module_for_terminal },
    //         },
    //     }),
    // });
    // const grain_terminal_ui_tests_run = b.addRunArtifact(grain_terminal_ui_tests);
    // test_step.dependOn(&grain_terminal_ui_tests_run.step);

    // ARCHIVED 2026-01-13 03:45:41 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // const grain_terminal_advanced_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/047_grain_terminal_advanced_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_terminal", .module = grain_terminal_module },
    //         },
    //     }),
    // });
    // const grain_terminal_advanced_tests_run = b.addRunArtifact(grain_terminal_advanced_tests);
    // test_step.dependOn(&grain_terminal_advanced_tests_run.step);

    // ARCHIVED 2026-01-13 03:45:41 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // const grain_skate_core_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/048_grain_skate_core_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "grain_skate", .module = grain_skate_module },
    //         },
    //     }),
    // });
    // const grain_skate_core_tests_run = b.addRunArtifact(grain_skate_core_tests);
    // test_step.dependOn(&grain_skate_core_tests_run.step);

    // ARCHIVED 2026-01-13 03:45:41 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // const grain_skate_social_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/051_grain_skate_social_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_social_tests_run = b.addRunArtifact(grain_skate_social_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_social_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_graph_viz_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/054_grain_skate_graph_viz_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_graph_viz_tests_run = b.addRunArtifact(grain_skate_graph_viz_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_graph_viz_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_modal_editor_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/058_grain_skate_modal_editor_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "events", .module = events_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_modal_editor_tests_run = b.addRunArtifact(grain_skate_modal_editor_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_modal_editor_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_app_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/055_grain_skate_app_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_app_tests_run = b.addRunArtifact(grain_skate_app_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_app_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_editor_renderer_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/059_grain_skate_editor_renderer_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_editor_renderer_tests_run = b.addRunArtifact(grain_skate_editor_renderer_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_editor_renderer_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_line_buffer_adapter_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/121_grain_skate_line_buffer_adapter_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_line_buffer_adapter_tests_run = b.addRunArtifact(grain_skate_line_buffer_adapter_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_line_buffer_adapter_tests_run.step);

    // TEMPORARILY DISABLED: const grain_skate_editor_dag_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/122_grain_skate_editor_dag_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_skate", .module = grain_skate_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_skate_editor_dag_integration_tests_run = b.addRunArtifact(grain_skate_editor_dag_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_skate_editor_dag_integration_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_temporal_graph_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/123_grain_skate_temporal_graph_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_temporal_graph_tests_run = b.addRunArtifact(grain_skate_temporal_graph_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_temporal_graph_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_ai_insights_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/124_grain_skate_ai_insights_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_ai_insights_tests_run = b.addRunArtifact(grain_skate_ai_insights_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_ai_insights_tests_run.step);

    // TEMPORARILY DISABLED: const grain_skate_slc_dag_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/125_grain_skate_slc_dag_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_skate", .module = grain_skate_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_skate_slc_dag_integration_tests_run = b.addRunArtifact(grain_skate_slc_dag_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_skate_slc_dag_integration_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const shared_font_renderer_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/060_shared_font_renderer_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "shared", .module = shared_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const shared_font_renderer_tests_run = b.addRunArtifact(shared_font_renderer_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&shared_font_renderer_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_graph_renderer_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/056_grain_skate_graph_renderer_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_graph_renderer_tests_run = b.addRunArtifact(grain_skate_graph_renderer_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_graph_renderer_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_window_graph_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/057_grain_skate_window_graph_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_window_graph_tests_run = b.addRunArtifact(grain_skate_window_graph_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_window_graph_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_bracket_matching_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/073_grain_skate_bracket_matching_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_skate", .module = grain_skate_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_skate_bracket_matching_tests_run = b.addRunArtifact(grain_skate_bracket_matching_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_skate_bracket_matching_tests_run.step);

    // TEMPORARILY DISABLED: const grain_court_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/049_grain_court_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_court", .module = grain_court_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_court_tests_run = b.addRunArtifact(grain_court_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_court_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_silo_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/050_grain_silo_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_silo", .module = grain_silo_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_silo_tests_run = b.addRunArtifact(grain_silo_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_silo_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_compositor_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/052_grain_core_compositor_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_tiling_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/053_grain_core_tiling_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_compositor_tests_run = b.addRunArtifact(grain_core_compositor_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_compositor_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    // const grain_core_tiling_tests_run = b.addRunArtifact(grain_core_tiling_tests);
    // test_step.dependOn(&grain_core_tiling_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_layout_generator_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/056_grain_core_layout_generator_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_layout_generator_tests_run = b.addRunArtifact(grain_core_layout_generator_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_layout_generator_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_workspace_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/057_grain_core_workspace_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_workspace_tests_run = b.addRunArtifact(grain_core_workspace_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_workspace_tests_run.step);
    const kernel_boot_jit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/058_kernel_boot_jit_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "kernel_vm", .module = kernel_vm_module },
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const kernel_boot_jit_tests_run = b.addRunArtifact(kernel_boot_jit_tests);
    test_step.dependOn(&kernel_boot_jit_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_performance_timing_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/059_jit_performance_timing_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_performance_timing_tests_run = b.addRunArtifact(jit_performance_timing_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&jit_performance_timing_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_hot_path_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/060_jit_hot_path_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_hot_path_tests_run = b.addRunArtifact(jit_hot_path_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&jit_hot_path_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_code_size_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/061_jit_code_size_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_code_size_tests_run = b.addRunArtifact(jit_code_size_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&jit_code_size_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_slt_instructions_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/071_jit_slt_instructions_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "sbi", .module = sbi_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_slt_instructions_tests_run = b.addRunArtifact(jit_slt_instructions_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&jit_slt_instructions_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_block_chaining_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/072_jit_block_chaining_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_block_chaining_tests_run = b.addRunArtifact(jit_block_chaining_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&jit_block_chaining_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_block_invalidation_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/073_jit_block_invalidation_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_block_invalidation_tests_run = b.addRunArtifact(jit_block_invalidation_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&jit_block_invalidation_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_compilation_threshold_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/074_jit_compilation_threshold_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const jit_compilation_threshold_tests_run = b.addRunArtifact(jit_compilation_threshold_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&jit_compilation_threshold_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_memory_stats_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/062_vm_memory_stats_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_memory_stats_tests_run = b.addRunArtifact(vm_memory_stats_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_memory_stats_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_instruction_stats_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/063_vm_instruction_stats_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_instruction_stats_tests_run = b.addRunArtifact(vm_instruction_stats_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_instruction_stats_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_syscall_stats_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/064_vm_syscall_stats_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_syscall_stats_tests_run = b.addRunArtifact(vm_syscall_stats_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_syscall_stats_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_execution_flow_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/065_vm_execution_flow_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_execution_flow_tests_run = b.addRunArtifact(vm_execution_flow_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_execution_flow_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_stats_aggregator_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/066_vm_stats_aggregator_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_stats_aggregator_tests_run = b.addRunArtifact(vm_stats_aggregator_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_stats_aggregator_tests_run.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_branch_stats_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/067_vm_branch_stats_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_branch_stats_tests_run = b.addRunArtifact(vm_branch_stats_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_branch_stats_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_register_stats_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/068_vm_register_stats_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_register_stats_tests_run = b.addRunArtifact(vm_register_stats_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_register_stats_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_instruction_perf_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/069_vm_instruction_perf_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_instruction_perf_tests_run = b.addRunArtifact(vm_instruction_perf_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_instruction_perf_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_stats_export_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/070_vm_stats_export_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_stats_export_tests_run = b.addRunArtifact(vm_stats_export_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_stats_export_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_state_inspection_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/072_vm_state_inspection_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_state_inspection_tests_run = b.addRunArtifact(vm_state_inspection_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_state_inspection_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_execution_control_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/073_vm_execution_control_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_execution_control_tests_run = b.addRunArtifact(vm_execution_control_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_execution_control_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_debug_command_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/074_vm_debug_command_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_debug_command_tests_run = b.addRunArtifact(vm_debug_command_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_debug_command_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_instruction_trace_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/075_vm_instruction_trace_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_instruction_trace_tests_run = b.addRunArtifact(vm_instruction_trace_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_instruction_trace_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_checkpoint_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/076_vm_checkpoint_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_checkpoint_tests_run = b.addRunArtifact(vm_checkpoint_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_checkpoint_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_optimization_hints_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/077_vm_optimization_hints_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_optimization_hints_tests_run = b.addRunArtifact(vm_optimization_hints_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_optimization_hints_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_benchmark_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/078_vm_benchmark_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_benchmark_tests_run = b.addRunArtifact(vm_benchmark_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_benchmark_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_memory_protection_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/079_vm_memory_protection_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const vm_memory_protection_tests_run = b.addRunArtifact(vm_memory_protection_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&vm_memory_protection_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_layout_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/053_grain_core_layout_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_layout_tests_run = b.addRunArtifact(grain_core_layout_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_layout_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_framebuffer_renderer_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/054_grain_core_framebuffer_renderer_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_framebuffer_renderer_tests_run = b.addRunArtifact(grain_core_framebuffer_renderer_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_framebuffer_renderer_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_input_handler_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/055_grain_core_input_handler_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_input_handler_tests_run = b.addRunArtifact(grain_core_input_handler_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_input_handler_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_input_routing_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/056_grain_core_input_routing_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_input_routing_tests_run = b.addRunArtifact(grain_core_input_routing_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_input_routing_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_decorations_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/058_grain_core_window_decorations_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_decorations_tests_run = b.addRunArtifact(grain_core_window_decorations_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_decorations_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_keyboard_shortcuts_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/059_grain_core_keyboard_shortcuts_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_keyboard_shortcuts_tests_run = b.addRunArtifact(grain_core_keyboard_shortcuts_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_keyboard_shortcuts_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_runtime_config_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/060_grain_core_runtime_config_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_runtime_config_tests_run = b.addRunArtifact(grain_core_runtime_config_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_runtime_config_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_desktop_shell_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/061_grain_core_desktop_shell_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_desktop_shell_tests_run = b.addRunArtifact(grain_core_desktop_shell_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_desktop_shell_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_application_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/062_grain_core_application_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_application_tests_run = b.addRunArtifact(grain_core_application_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_application_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_launcher_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/063_grain_core_launcher_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_launcher_integration_tests_run = b.addRunArtifact(grain_core_launcher_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_launcher_integration_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_resize_drag_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/064_grain_core_window_resize_drag_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_resize_drag_tests_run = b.addRunArtifact(grain_core_window_resize_drag_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_resize_drag_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_snapping_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/065_grain_core_window_snapping_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_snapping_tests_run = b.addRunArtifact(grain_core_window_snapping_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_snapping_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_switching_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/066_grain_core_window_switching_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_switching_tests_run = b.addRunArtifact(grain_core_window_switching_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_switching_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_state_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/067_grain_core_window_state_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_state_tests_run = b.addRunArtifact(grain_core_window_state_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_state_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_preview_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/068_grain_core_window_preview_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_preview_tests_run = b.addRunArtifact(grain_core_window_preview_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_preview_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_visual_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/069_grain_core_window_visual_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_visual_tests_run = b.addRunArtifact(grain_core_window_visual_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_visual_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_stacking_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/070_grain_core_window_stacking_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_stacking_tests_run = b.addRunArtifact(grain_core_window_stacking_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_stacking_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_opacity_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/071_grain_core_window_opacity_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_opacity_tests_run = b.addRunArtifact(grain_core_window_opacity_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_opacity_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_animation_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/072_grain_core_window_animation_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_animation_tests_run = b.addRunArtifact(grain_core_window_animation_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_animation_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_constraints_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/074_grain_core_window_constraints_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_constraints_tests_run = b.addRunArtifact(grain_core_window_constraints_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_constraints_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_grouping_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/075_grain_core_window_grouping_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_grouping_tests_run = b.addRunArtifact(grain_core_window_grouping_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_grouping_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_focus_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/076_grain_core_window_focus_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_focus_tests_run = b.addRunArtifact(grain_core_window_focus_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_focus_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_effects_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/077_grain_core_window_effects_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_effects_tests_run = b.addRunArtifact(grain_core_window_effects_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_effects_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_drag_drop_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/078_grain_core_window_drag_drop_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_drag_drop_tests_run = b.addRunArtifact(grain_core_window_drag_drop_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_drag_drop_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_tiling_config_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/079_grain_core_tiling_config_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_tiling_config_tests_run = b.addRunArtifact(grain_core_tiling_config_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_tiling_config_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_rules_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/080_grain_core_window_rules_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_rules_tests_run = b.addRunArtifact(grain_core_window_rules_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_rules_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_events_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/081_grain_core_window_events_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_events_tests_run = b.addRunArtifact(grain_core_window_events_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_events_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_session_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/082_grain_core_window_session_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_window_session_tests_run = b.addRunArtifact(grain_core_window_session_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_window_session_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_lock_screen_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/083_grain_core_lock_screen_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_lock_screen_tests_run = b.addRunArtifact(grain_core_lock_screen_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_lock_screen_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_notification_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/084_grain_core_notification_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_notification_tests_run = b.addRunArtifact(grain_core_notification_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_notification_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_clipboard_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/085_grain_core_clipboard_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_clipboard_tests_run = b.addRunArtifact(grain_core_clipboard_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_clipboard_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_app_launcher_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/086_grain_core_app_launcher_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_app_launcher_tests_run = b.addRunArtifact(grain_core_app_launcher_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_app_launcher_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_system_tray_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/087_grain_core_system_tray_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_system_tray_tests_run = b.addRunArtifact(grain_core_system_tray_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_system_tray_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_power_management_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/088_grain_core_power_management_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_power_management_tests_run = b.addRunArtifact(grain_core_power_management_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_power_management_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_display_management_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/089_grain_core_display_management_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_display_management_tests_run = b.addRunArtifact(grain_core_display_management_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_display_management_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_settings_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/090_grain_core_settings_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_settings_manager_tests_run = b.addRunArtifact(grain_core_settings_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_settings_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_theme_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/091_grain_core_theme_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_theme_manager_tests_run = b.addRunArtifact(grain_core_theme_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_theme_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_screen_capture_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/092_grain_core_screen_capture_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_screen_capture_tests_run = b.addRunArtifact(grain_core_screen_capture_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_screen_capture_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_file_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/093_grain_core_file_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_file_manager_tests_run = b.addRunArtifact(grain_core_file_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_file_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_resource_monitor_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/094_grain_core_resource_monitor_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_resource_monitor_tests_run = b.addRunArtifact(grain_core_resource_monitor_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_resource_monitor_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_network_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/095_grain_core_network_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_network_manager_tests_run = b.addRunArtifact(grain_core_network_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_network_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_process_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/096_grain_core_process_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_process_manager_tests_run = b.addRunArtifact(grain_core_process_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_process_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_system_logger_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/097_grain_core_system_logger_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_system_logger_tests_run = b.addRunArtifact(grain_core_system_logger_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_system_logger_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_kernel_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/098_grain_core_kernel_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_kernel_integration_tests_run = b.addRunArtifact(grain_core_kernel_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_kernel_integration_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_security_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/099_grain_core_security_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_security_manager_tests_run = b.addRunArtifact(grain_core_security_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_security_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_service_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/100_grain_core_service_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_service_manager_tests_run = b.addRunArtifact(grain_core_service_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_service_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_backup_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/101_grain_core_backup_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_backup_manager_tests_run = b.addRunArtifact(grain_core_backup_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_backup_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_http_client_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/122_grain_core_http_client_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_http_client_tests_run = b.addRunArtifact(grain_core_http_client_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_http_client_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_update_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/102_grain_core_update_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_update_manager_tests_run = b.addRunArtifact(grain_core_update_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_update_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_package_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/103_grain_core_package_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_package_manager_tests_run = b.addRunArtifact(grain_core_package_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_package_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_health_monitor_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/104_grain_core_health_monitor_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_health_monitor_tests_run = b.addRunArtifact(grain_core_health_monitor_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_health_monitor_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_process_supervision_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/105_grain_core_process_supervision_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_process_supervision_tests_run = b.addRunArtifact(grain_core_process_supervision_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_process_supervision_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_system_metrics_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/106_grain_core_system_metrics_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_system_metrics_tests_run = b.addRunArtifact(grain_core_system_metrics_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_system_metrics_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_system_diagnostics_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/107_grain_core_system_diagnostics_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_system_diagnostics_tests_run = b.addRunArtifact(grain_core_system_diagnostics_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_system_diagnostics_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_notes_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/108_grain_workspace_notes_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_workspace", .module = grain_workspace_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_notes_tests_run = b.addRunArtifact(grain_workspace_notes_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_workspace_notes_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_monitor_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_workspace_monitor_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_workspace", .module = grain_workspace_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_monitor_tests_run = b.addRunArtifact(grain_workspace_monitor_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_workspace_monitor_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_package_manager_ui_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/111_grain_workspace_package_manager_ui_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_workspace", .module = grain_workspace_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_package_manager_ui_tests_run = b.addRunArtifact(grain_workspace_package_manager_ui_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_workspace_package_manager_ui_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_file_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/112_grain_workspace_file_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_workspace", .module = grain_workspace_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_file_manager_tests_run = b.addRunArtifact(grain_workspace_file_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_workspace_file_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_devtools_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/114_grain_workspace_devtools_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_workspace", .module = grain_workspace_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_devtools_tests_run = b.addRunArtifact(grain_workspace_devtools_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_workspace_devtools_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_text_editor_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/115_grain_workspace_text_editor_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_workspace", .module = grain_workspace_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_text_editor_tests_run = b.addRunArtifact(grain_workspace_text_editor_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_workspace_text_editor_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_components_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/116_grain_workspace_components_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_workspace", .module = grain_workspace_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_workspace_components_tests_run = b.addRunArtifact(grain_workspace_components_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_workspace_components_tests_run.step);

    // Dream Browser Components tests
    // TEMPORARILY DISABLED: const dream_browser_components_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/136_dream_browser_components_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "dream_browser_components", .module = dream_browser_components_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _dream_browser_components_tests_run = b.addRunArtifact(dream_browser_components_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&dream_browser_components_tests_run.step);

    // Grain Database tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_storage_engine_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_database_storage_engine_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_storage_engine_tests_run = b.addRunArtifact(grain_database_storage_engine_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_storage_engine_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_index_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_database_index_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_index_tests_run = b.addRunArtifact(grain_database_index_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_index_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_wal_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_database_wal_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_wal_tests_run = b.addRunArtifact(grain_database_wal_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_wal_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_transaction_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_database_transaction_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_transaction_tests_run = b.addRunArtifact(grain_database_transaction_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_transaction_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_relational_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_database_relational_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_relational_tests_run = b.addRunArtifact(grain_database_relational_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_relational_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_query_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_database_query_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_query_tests_run = b.addRunArtifact(grain_database_query_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_query_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_graph_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_database_graph_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_graph_tests_run = b.addRunArtifact(grain_database_graph_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_graph_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_fulltext_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_database_fulltext_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_fulltext_tests_run = b.addRunArtifact(grain_database_fulltext_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_fulltext_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_api_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_database_api_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_api_tests_run = b.addRunArtifact(grain_database_api_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_api_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_api_server_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_core_api_server_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_api_server_tests_run = b.addRunArtifact(grain_core_api_server_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_api_server_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_middleware_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/111_grain_core_middleware_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_middleware_tests_run = b.addRunArtifact(grain_core_middleware_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_middleware_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_json_helpers_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/110_grain_core_json_helpers_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_json_helpers_tests_run = b.addRunArtifact(grain_core_json_helpers_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_json_helpers_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_connection_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/112_grain_core_connection_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_connection_manager_tests_run = b.addRunArtifact(grain_core_connection_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_connection_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_api_server_network_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/113_grain_core_api_server_network_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_api_server_network_tests_run = b.addRunArtifact(grain_core_api_server_network_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_api_server_network_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_auth_service_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/114_grain_core_auth_service_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_auth_service_tests_run = b.addRunArtifact(grain_core_auth_service_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_auth_service_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_network_stack_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/115_grain_core_network_stack_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_network_stack_tests_run = b.addRunArtifact(grain_core_network_stack_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_network_stack_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_websocket_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/116_grain_core_websocket_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_websocket_tests_run = b.addRunArtifact(grain_core_websocket_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_websocket_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_dns_resolver_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/117_grain_core_dns_resolver_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_dns_resolver_tests_run = b.addRunArtifact(grain_core_dns_resolver_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_dns_resolver_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_file_storage_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/118_grain_core_file_storage_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_file_storage_tests_run = b.addRunArtifact(grain_core_file_storage_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_file_storage_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_wal_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/119_grain_core_wal_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_wal_manager_tests_run = b.addRunArtifact(grain_core_wal_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_wal_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_index_manager_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/120_grain_core_index_manager_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_core_index_manager_tests_run = b.addRunArtifact(grain_core_index_manager_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_core_index_manager_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_integration_os_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/109_grain_database_integration_os_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_integration_os_tests_run = b.addRunArtifact(grain_database_integration_os_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_integration_os_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_auth_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/113_grain_database_auth_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_auth_integration_tests_run = b.addRunArtifact(grain_database_auth_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_auth_integration_tests_run.step);

    // Grain Database Persistence Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_persistence_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/114_grain_database_persistence_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_core", .module = grain_core_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_persistence_tests_run = b.addRunArtifact(grain_database_persistence_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_persistence_tests_run.step);

    // Grain Database Storage Persistence Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_storage_persistence_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/115_grain_database_storage_persistence_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_storage_persistence_tests_run = b.addRunArtifact(grain_database_storage_persistence_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_storage_persistence_tests_run.step);

    // Grain Database Record Serialization Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_record_serialization_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/116_grain_database_record_serialization_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_record_serialization_tests_run = b.addRunArtifact(grain_database_record_serialization_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_record_serialization_tests_run.step);

    // Grain Database Index Entry Serialization Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_index_entry_serialization_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/117_grain_database_index_entry_serialization_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_index_entry_serialization_tests_run = b.addRunArtifact(grain_database_index_entry_serialization_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_index_entry_serialization_tests_run.step);

    // Grain Database Index Persistence Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_index_persistence_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/118_grain_database_index_persistence_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_index_persistence_tests_run = b.addRunArtifact(grain_database_index_persistence_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_index_persistence_tests_run.step);

    // Grain Database Multi-Page Record Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_multi_page_record_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/119_grain_database_multi_page_record_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_multi_page_record_tests_run = b.addRunArtifact(grain_database_multi_page_record_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_multi_page_record_tests_run.step);

    // Grain Database Backup Restore Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_backup_restore_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/120_grain_database_backup_restore_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_backup_restore_tests_run = b.addRunArtifact(grain_database_backup_restore_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_backup_restore_tests_run.step);

    // Grain Database End-to-End Persistence Recovery Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_persistence_recovery_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/121_grain_database_persistence_recovery_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_persistence_recovery_tests_run = b.addRunArtifact(grain_database_persistence_recovery_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_persistence_recovery_tests_run.step);

    // Grain Database Network Integration Tests
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_network_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/122_grain_database_network_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_network_integration_tests_run = b.addRunArtifact(grain_database_network_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_network_integration_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_slc_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/123_grain_database_slc_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_slc_integration_tests_run = b.addRunArtifact(grain_database_slc_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_slc_integration_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_user_storage_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/124_grain_database_user_storage_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "grain_database", .module = grain_database_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     grain_database_user_storage_tests.root_module.addImport("grain_database", grain_database_module);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const grain_database_user_storage_tests_run = b.addRunArtifact(grain_database_user_storage_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&grain_database_user_storage_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executables archived - focus on kernel
    // RISC-V Logo Display Program
    // const riscv_logo_exe = b.addExecutable(.{
    //     .name = "riscv_logo",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("examples/riscv_logo.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // const riscv_logo_exe = b.addExecutable(.{
    //     .name = "riscv_logo",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("examples/riscv_logo.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //             .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //         },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     //     }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     // });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     riscv_logo_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const riscv_logo_install = b.addInstallArtifact(riscv_logo_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const riscv_logo_step = b.step("riscv-logo", "Build RISC-V logo display program for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     riscv_logo_step.dependOn(&riscv_logo_install.step);

    // Build-essential utilities: cat
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cat_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "cat",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/cat.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cat_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "cat",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/cat.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     cat_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cat_install = b.addInstallArtifact(cat_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cat_step = b.step("cat", "Build cat utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     cat_step.dependOn(&cat_install.step);

    // Build-essential utilities: echo
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const echo_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "echo",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/echo.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const echo_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "echo",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/echo.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     echo_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const echo_install = b.addInstallArtifact(echo_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const echo_step = b.step("echo", "Build echo utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     echo_step.dependOn(&echo_install.step);

    // Build-essential utilities: ls
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ls_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "ls",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/ls.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ls_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "ls",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/ls.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     ls_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ls_install = b.addInstallArtifact(ls_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ls_step = b.step("ls", "Build ls utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     ls_step.dependOn(&ls_install.step);

    // Build-essential utilities: mkdir
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const mkdir_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "mkdir",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/mkdir.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const mkdir_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "mkdir",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/mkdir.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     mkdir_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const mkdir_install = b.addInstallArtifact(mkdir_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const mkdir_step = b.step("mkdir", "Build mkdir utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     mkdir_step.dependOn(&mkdir_install.step);

    // Build-essential utilities: rm
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const rm_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "rm",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/rm.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const rm_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "rm",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/rm.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     rm_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const rm_install = b.addInstallArtifact(rm_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const rm_step = b.step("rm", "Build rm utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     rm_step.dependOn(&rm_install.step);

    // Build-essential utilities: cp
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cp_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "cp",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/cp.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cp_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "cp",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/cp.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     cp_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cp_install = b.addInstallArtifact(cp_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cp_step = b.step("cp", "Build cp utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     cp_step.dependOn(&cp_install.step);

    // Build-essential utilities: mv
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const mv_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "mv",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/mv.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const mv_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "mv",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/core/mv.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     mv_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const mv_install = b.addInstallArtifact(mv_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const mv_step = b.step("mv", "Build mv utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     mv_step.dependOn(&mv_install.step);

    // Build-essential utilities: grep
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const grep_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "grep",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/text/grep.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const grep_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "grep",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/text/grep.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     grep_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const grep_install = b.addInstallArtifact(grep_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const grep_step = b.step("grep", "Build grep utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     grep_step.dependOn(&grep_install.step);

    // Build-essential utilities: sed
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const sed_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "sed",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/text/sed.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const sed_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "sed",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/text/sed.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     sed_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const sed_install = b.addInstallArtifact(sed_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const sed_step = b.step("sed", "Build sed utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     sed_step.dependOn(&sed_install.step);

    // Build-essential utilities: awk
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const awk_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "awk",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/text/awk.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const awk_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "awk",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/utils/text/awk.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     awk_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const awk_install = b.addInstallArtifact(awk_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const awk_step = b.step("awk", "Build awk utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     awk_step.dependOn(&awk_install.step);

    // Build-essential utilities: cc (C compiler wrapper)
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cc_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "cc",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/build-tools/cc.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cc_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "cc",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/build-tools/cc.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     cc_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cc_install = b.addInstallArtifact(cc_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const cc_step = b.step("cc", "Build cc utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     cc_step.dependOn(&cc_install.step);

    // Build-essential utilities: ld (linker wrapper)
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ld_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "ld",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/build-tools/ld.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ld_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "ld",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/build-tools/ld.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     ld_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ld_install = b.addInstallArtifact(ld_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ld_step = b.step("ld", "Build ld utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     ld_step.dependOn(&ld_install.step);

    // Build-essential utilities: ar (archive utility)
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ar_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "ar",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/build-tools/ar.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ar_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "ar",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/build-tools/ar.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     ar_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ar_install = b.addInstallArtifact(ar_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const ar_step = b.step("ar", "Build ar utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     ar_step.dependOn(&ar_install.step);

    // Build-essential utilities: make (build automation)
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const make_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "make",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/build-tools/make.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const make_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "make",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/build-tools/make.zig"),
            // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - incomplete test block
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             // .target = userspace_resolved,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_stdlib", .module = userspace_stdlib_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "userspace_args", .module = userspace_args_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     make_exe.setLinkerScript(b.path("linker_scripts/userspace.ld"));
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const make_install = b.addInstallArtifact(make_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const make_step = b.step("make", "Build make utility for RISC-V64");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     make_step.dependOn(&make_install.step);

    // Build-essential utilities: build all
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const build_essential_step = b.step("build-essential", "Build all build-essential utilities");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&cat_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&echo_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&ls_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&mkdir_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&rm_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&cp_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&mv_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&grep_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&sed_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&awk_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&cc_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&ld_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&ar_install.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     build_essential_step.dependOn(&make_install.step);

    // Grainscape Browser (native browser for Grain OS)
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const grainscape_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "grainscape",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/grainscape/main.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .target = target, // Host target for now
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const grainscape_install = b.addInstallArtifact(grainscape_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const grainscape_step = b.step("grainscape", "Build and run Grainscape browser");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const run_grainscape = b.addRunArtifact(grainscape_exe);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     grainscape_step.dependOn(&run_grainscape.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     run_grainscape.step.dependOn(&grainscape_install.step);

    // Grainscape TLS Demo (test TLS connectivity)
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const grainscape_tls_demo_exe = b.addExecutable(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .name = "grainscape-tls-demo",
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .root_source_file = b.path("src/userspace/grainscape/tls_demo.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //                 .{ .name = "tls", .module = tls_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const grainscape_tls_demo_install = b.addInstallArtifact(grainscape_tls_demo_exe, .{});
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const grainscape_tls_demo_step = b.step("grainscape-tls-demo", "Build and run Grainscape TLS demo");
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     const run_grainscape_tls_demo = b.addRunArtifact(grainscape_tls_demo_exe);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     grainscape_tls_demo_step.dependOn(&run_grainscape_tls_demo.step);
    // ARCHIVED 2026-01-13 03:54:03 PST: Userspace executable archived
    //     run_grainscape_tls_demo.step.dependOn(&grainscape_tls_demo_install.step);



    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const fuzz_003_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/003_fuzz.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "ray", .module = ray_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "window", .module = window_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const run_fuzz_003_tests = b.addRunArtifact(fuzz_003_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&run_fuzz_003_tests.step);

    // Grain Bubble canvas tests
    // TEMPORARILY DISABLED: const grain_bubble_canvas_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/125_grain_bubble_canvas_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_canvas_tests_run = b.addRunArtifact(grain_bubble_canvas_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_canvas_tests_run.step);

    // Grain Bubble canvas renderer tests
    // TEMPORARILY DISABLED: const grain_bubble_canvas_renderer_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/126_grain_bubble_canvas_renderer_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_core", .module = grain_core_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_canvas_renderer_tests_run = b.addRunArtifact(grain_bubble_canvas_renderer_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_canvas_renderer_tests_run.step);

    // Grain Bubble canvas input tests
    // TEMPORARILY DISABLED: const grain_bubble_canvas_input_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/127_grain_bubble_canvas_input_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_core", .module = grain_core_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_canvas_input_tests_run = b.addRunArtifact(grain_bubble_canvas_input_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_canvas_input_tests_run.step);

    // Grain Bubble undo/redo tests
    // TEMPORARILY DISABLED: const grain_bubble_undo_redo_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/128_grain_bubble_undo_redo_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_undo_redo_tests_run = b.addRunArtifact(grain_bubble_undo_redo_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_undo_redo_tests_run.step);

    // Grain Bubble PDF export tests
    // TEMPORARILY DISABLED: const grain_bubble_export_pdf_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/129_grain_bubble_export_pdf_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_export_pdf_tests_run = b.addRunArtifact(grain_bubble_export_pdf_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_export_pdf_tests_run.step);

    // TEMPORARILY DISABLED: const grain_bubble_export_html_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/131_grain_bubble_export_html_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_export_html_tests_run = b.addRunArtifact(grain_bubble_export_html_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_export_html_tests_run.step);

    // TEMPORARILY DISABLED: const grain_bubble_export_framework_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/132_grain_bubble_export_framework_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_export_framework_tests_run = b.addRunArtifact(grain_bubble_export_framework_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_export_framework_tests_run.step);

    // TEMPORARILY DISABLED: const grain_bubble_export_slc_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/133_grain_bubble_export_slc_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_export_slc_tests_run = b.addRunArtifact(grain_bubble_export_slc_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_export_slc_tests_run.step);

    // TEMPORARILY DISABLED: const grain_bubble_silo_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/134_grain_bubble_silo_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_silo_integration_tests_run = b.addRunArtifact(grain_bubble_silo_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_silo_integration_tests_run.step);

    // TEMPORARILY DISABLED: const grain_bubble_court_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/135_grain_bubble_court_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_court_integration_tests_run = b.addRunArtifact(grain_bubble_court_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_court_integration_tests_run.step);

    // TEMPORARILY DISABLED: const grain_bubble_dag_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/136_grain_bubble_dag_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_dag_integration_tests_run = b.addRunArtifact(grain_bubble_dag_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_dag_integration_tests_run.step);

    // TEMPORARILY DISABLED: const grain_bubble_export_optimize_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/137_grain_bubble_export_optimize_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_export_optimize_tests_run = b.addRunArtifact(grain_bubble_export_optimize_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_export_optimize_tests_run.step);

    // TEMPORARILY DISABLED: const grain_bubble_export_preview_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/138_grain_bubble_export_preview_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_export_preview_tests_run = b.addRunArtifact(grain_bubble_export_preview_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_export_preview_tests_run.step);

    // TEMPORARILY DISABLED: const grain_bubble_agent_flow_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/139_grain_bubble_agent_flow_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_agent_flow_tests_run = b.addRunArtifact(grain_bubble_agent_flow_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_agent_flow_tests_run.step);

    // Grain Flow event bus tests
    // TEMPORARILY DISABLED: const grain_flow_event_bus_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/134_grain_flow_event_bus_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_event_bus_tests_run = b.addRunArtifact(grain_flow_event_bus_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_event_bus_tests_run.step);

    // Grain Flow agent coordinator tests
    // TEMPORARILY DISABLED: const grain_flow_agent_coordinator_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/135_grain_flow_agent_coordinator_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_agent_coordinator_tests_run = b.addRunArtifact(grain_flow_agent_coordinator_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_agent_coordinator_tests_run.step);

    // Grain Flow workflow engine tests
    // TEMPORARILY DISABLED: const grain_flow_workflow_engine_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/136_grain_flow_workflow_engine_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_workflow_engine_tests_run = b.addRunArtifact(grain_flow_workflow_engine_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_workflow_engine_tests_run.step);

    // Grain Flow workflow visualizer tests
    // TEMPORARILY DISABLED: const grain_flow_workflow_visualizer_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/137_grain_flow_workflow_visualizer_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_workflow_visualizer_tests_run = b.addRunArtifact(grain_flow_workflow_visualizer_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_workflow_visualizer_tests_run.step);

    // Grain Flow Workflow Templates Tests
    // TEMPORARILY DISABLED: const grain_flow_workflow_templates_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/138_grain_flow_workflow_templates_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_workflow_templates_tests_run = b.addRunArtifact(grain_flow_workflow_templates_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_workflow_templates_tests_run.step);

    // Grain Flow Workflow Metrics Tests
    // TEMPORARILY DISABLED: const grain_flow_workflow_metrics_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/139_grain_flow_workflow_metrics_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_workflow_metrics_tests_run = b.addRunArtifact(grain_flow_workflow_metrics_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_workflow_metrics_tests_run.step);

    // Grain Flow Workflow Observatory Tests
    // TEMPORARILY DISABLED: const grain_flow_workflow_observatory_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/143_grain_flow_workflow_observatory_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_workflow_observatory_tests_run = b.addRunArtifact(grain_flow_workflow_observatory_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_workflow_observatory_tests_run.step);

    // Grain Flow Workflow Scheduler Tests
    // TEMPORARILY DISABLED: const grain_flow_workflow_scheduler_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/145_grain_flow_workflow_scheduler_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_workflow_scheduler_tests_run = b.addRunArtifact(grain_flow_workflow_scheduler_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_workflow_scheduler_tests_run.step);

    // Grain Flow Core integration tests
    // TEMPORARILY DISABLED: const grain_flow_core_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/146_grain_flow_core_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_core", .module = grain_core_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_core_integration_tests_run = b.addRunArtifact(grain_flow_core_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_core_integration_tests_run.step);

    // Grain Flow realistic metrics generator tests
    // TEMPORARILY DISABLED: const grain_flow_realistic_metrics_generator_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/147_grain_flow_realistic_metrics_generator_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_realistic_metrics_generator_tests_run = b.addRunArtifact(grain_flow_realistic_metrics_generator_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_realistic_metrics_generator_tests_run.step);

    // Grain Flow Step 3 real metrics export tests
    // TEMPORARILY DISABLED: const grain_flow_step3_real_metrics_export_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/148_grain_flow_step3_real_metrics_export_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_flow_step3_real_metrics_export_tests_run = b.addRunArtifact(grain_flow_step3_real_metrics_export_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_flow_step3_real_metrics_export_tests_run.step);

    // Grain Research engine tests
    // TEMPORARILY DISABLED: const grain_research_engine_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/136_grain_research_engine_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_engine_tests_run = b.addRunArtifact(grain_research_engine_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_engine_tests_run.step);

    // Grain Research code analysis tests
    // TEMPORARILY DISABLED: const grain_research_code_analysis_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/137_grain_research_code_analysis_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_code_analysis_tests_run = b.addRunArtifact(grain_research_code_analysis_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_code_analysis_tests_run.step);

    // Grain Research workflow metrics analyzer tests
    // TEMPORARILY DISABLED: const grain_research_workflow_metrics_analyzer_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/143_grain_research_workflow_metrics_analyzer_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_workflow_metrics_analyzer_tests_run = b.addRunArtifact(grain_research_workflow_metrics_analyzer_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_workflow_metrics_analyzer_tests_run.step);

    // Grain Research insights generator tests
    // TEMPORARILY DISABLED: const grain_research_insights_generator_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/144_grain_research_insights_generator_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_insights_generator_tests_run = b.addRunArtifact(grain_research_insights_generator_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_insights_generator_tests_run.step);

    // Grain Research workflow metrics integration tests (Flow Agent sample data)
    // TEMPORARILY DISABLED: const grain_research_workflow_metrics_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/145_grain_research_workflow_metrics_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_workflow_metrics_integration_tests_run = b.addRunArtifact(grain_research_workflow_metrics_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_workflow_metrics_integration_tests_run.step);

    // Grain Research workflow metrics Step 2 validation tests
    // TEMPORARILY DISABLED: const grain_research_workflow_metrics_step2_validation_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/146_grain_research_workflow_metrics_step2_validation_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_workflow_metrics_step2_validation_tests_run = b.addRunArtifact(grain_research_workflow_metrics_step2_validation_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_workflow_metrics_step2_validation_tests_run.step);

    // Grain Research workflow metrics Step 3 validation tests (real workflow metrics)
    // TEMPORARILY DISABLED: const grain_research_workflow_metrics_step3_validation_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/149_grain_research_workflow_metrics_step3_validation_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_workflow_metrics_step3_validation_tests_run = b.addRunArtifact(grain_research_workflow_metrics_step3_validation_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_workflow_metrics_step3_validation_tests_run.step);

    // Grain Research ZON format token benchmark tests
    // TEMPORARILY DISABLED: const grain_research_zon_token_benchmark_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/150_grain_research_zon_token_benchmark_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_zon_token_benchmark_tests_run = b.addRunArtifact(grain_research_zon_token_benchmark_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_zon_token_benchmark_tests_run.step);

    // ZON Format Retrieval Accuracy Tests (Phase 2).
    // TEMPORARILY DISABLED: const grain_research_zon_retrieval_accuracy_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/151_grain_research_zon_retrieval_accuracy_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_zon_retrieval_accuracy_tests_run = b.addRunArtifact(grain_research_zon_retrieval_accuracy_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_zon_retrieval_accuracy_tests_run.step);

    // ZON Format Retrieval Serialization Tests (Phase 2).
    // TEMPORARILY DISABLED: const grain_research_zon_retrieval_serialization_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/152_grain_research_zon_retrieval_serialization_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_zon_retrieval_serialization_tests_run = b.addRunArtifact(grain_research_zon_retrieval_serialization_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_zon_retrieval_serialization_tests_run.step);

    // ZON Format Cost Savings Tests (Phase 3).
    // TEMPORARILY DISABLED: const grain_research_zon_cost_savings_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/153_grain_research_zon_cost_savings_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_zon_cost_savings_tests_run = b.addRunArtifact(grain_research_zon_cost_savings_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_zon_cost_savings_tests_run.step);

    // Integration Test Harness Tests (Priority 2).
    // TEMPORARILY DISABLED: const grain_research_integration_test_harness_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/154_grain_research_integration_test_harness_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_integration_test_harness_tests_run = b.addRunArtifact(grain_research_integration_test_harness_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_integration_test_harness_tests_run.step);

    // Integration Test Scenarios Tests (Priority 2).
    // TEMPORARILY DISABLED: const grain_research_integration_test_scenarios_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/155_grain_research_integration_test_scenarios_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_integration_test_scenarios_tests_run = b.addRunArtifact(grain_research_integration_test_scenarios_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_integration_test_scenarios_tests_run.step);

    // ZON Format Phase 4 Integration Validation Framework Tests.
    // TEMPORARILY DISABLED: const grain_research_zon_integration_validation_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/156_grain_research_zon_integration_validation_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_zon_integration_validation_tests_run = b.addRunArtifact(grain_research_zon_integration_validation_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_zon_integration_validation_tests_run.step);

    // ZON Format Phase 4 Integration Validation Tests.
    // TEMPORARILY DISABLED: const grain_research_zon_phase4_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/157_grain_research_zon_phase4_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_court", .module = grain_court_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_zon_phase4_integration_tests_run = b.addRunArtifact(grain_research_zon_phase4_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_zon_phase4_integration_tests_run.step);

    // ZON Format Phase 4 Validation Runner Tests.
    // TEMPORARILY DISABLED: const grain_research_zon_phase4_validation_runner_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/158_grain_research_zon_phase4_validation_runner_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_court", .module = grain_court_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_zon_phase4_validation_runner_tests_run = b.addRunArtifact(grain_research_zon_phase4_validation_runner_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_zon_phase4_validation_runner_tests_run.step);

    // TEMPORARILY DISABLED: const grain_research_llm_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/159_grain_research_llm_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_llm_integration_tests_run = b.addRunArtifact(grain_research_llm_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_llm_integration_tests_run.step);

    // TEMPORARILY DISABLED: const grain_research_retrieval_llm_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/160_grain_research_retrieval_llm_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_retrieval_llm_integration_tests_run = b.addRunArtifact(grain_research_retrieval_llm_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_retrieval_llm_integration_tests_run.step);

    // TEMPORARILY DISABLED: const grain_research_token_counting_adapter_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/161_grain_research_token_counting_adapter_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_court", .module = grain_court_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_token_counting_adapter_tests_run = b.addRunArtifact(grain_research_token_counting_adapter_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_token_counting_adapter_tests_run.step);

    // TEMPORARILY DISABLED: const grain_research_cost_tracking_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/162_grain_research_cost_tracking_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_research", .module = grain_research_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_court", .module = grain_court_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_research_cost_tracking_integration_tests_run = b.addRunArtifact(grain_research_cost_tracking_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_research_cost_tracking_integration_tests_run.step);

    // Syscall Verification Framework Tests (Phase 1)
    const syscall_verification_framework_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/163_syscall_verification_framework_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "kernel_vm", .module = kernel_vm_module },
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const syscall_verification_framework_tests_run = b.addRunArtifact(syscall_verification_framework_tests);
    test_step.dependOn(&syscall_verification_framework_tests_run.step);

    // Sevenos modules for End-to-End Integration Tests
    // Note: supervision is standalone library, shell files are interdependent
    const sevenos_supervision_module = b.addModule("supervision", .{
        .root_source_file = b.path("grainstore/sevenos/src/lib/supervision.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Shell module with root.zig that re-exports components
    // This allows shell files to use relative imports while providing clean module API
    const sevenos_shell_module = b.addModule("sevenos_shell", .{
        .root_source_file = b.path("grainstore/sevenos/src/shell/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "supervision", .module = sevenos_supervision_module },
        },
    });

    // End-to-End Integration Tests (Full Stack: VM → Kernel → Init System → Shell)
    const end_to_end_integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/164_end_to_end_integration_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "kernel_vm", .module = kernel_vm_module },
                .{ .name = "basin_kernel", .module = basin_kernel_module },
                .{ .name = "supervision", .module = sevenos_supervision_module },
                .{ .name = "sevenos_shell", .module = sevenos_shell_module },
            },
        }),
    });
    // Link libc for supervision.zig execve syscall
    end_to_end_integration_tests.linkLibC();
    const end_to_end_integration_tests_run = b.addRunArtifact(end_to_end_integration_tests);
    test_step.dependOn(&end_to_end_integration_tests_run.step);

    // Grain Bubble component tests
    // TEMPORARILY DISABLED: const grain_bubble_component_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/130_grain_bubble_component_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_component_tests_run = b.addRunArtifact(grain_bubble_component_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_component_tests_run.step);

    // Grain Bubble workspace integration tests
    // TEMPORARILY DISABLED: const grain_bubble_workspace_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/141_grain_bubble_workspace_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_workspace", .module = grain_workspace_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_workspace_integration_tests_run = b.addRunArtifact(grain_bubble_workspace_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_workspace_integration_tests_run.step);

    // Grain Bubble async integration tests
    // TEMPORARILY DISABLED: const grain_bubble_async_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/142_grain_bubble_async_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: .{ .name = "grain_flow", .module = grain_flow_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_async_integration_tests_run = b.addRunArtifact(grain_bubble_async_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_async_integration_tests_run.step);

    // Grain Bubble aurora integration tests
    // TEMPORARILY DISABLED: const grain_bubble_aurora_integration_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/143_grain_bubble_aurora_integration_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "grain_bubble", .module = grain_bubble_module },
    // TEMPORARILY DISABLED: .{ .name = "dream_browser_components", .module = dream_browser_components_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _grain_bubble_aurora_integration_tests_run = b.addRunArtifact(grain_bubble_aurora_integration_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&grain_bubble_aurora_integration_tests_run.step);

    // File system kernel verification test
    const file_system_kernel_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/097_file_system_kernel_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const file_system_kernel_tests_run = b.addRunArtifact(file_system_kernel_tests);
    test_step.dependOn(&file_system_kernel_tests_run.step);

    // Nostr protocol kernel verification test
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const nostr_protocol_kernel_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/092_nostr_protocol_kernel_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const nostr_protocol_kernel_tests_run = b.addRunArtifact(nostr_protocol_kernel_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&nostr_protocol_kernel_tests_run.step);

    // DAG operations kernel verification test
    // TEMPORARILY DISABLED: const dag_operations_kernel_tests = b.addTest(.{
    // TEMPORARILY DISABLED: .root_module = b.createModule(.{
    // TEMPORARILY DISABLED: .root_source_file = b.path("tests/095_dag_operations_kernel_test.zig"),
    // TEMPORARILY DISABLED: .target = target,
    // TEMPORARILY DISABLED: .optimize = optimize,
    // TEMPORARILY DISABLED: .imports = &.{
    // TEMPORARILY DISABLED: .{ .name = "basin_kernel", .module = basin_kernel_module },
    // TEMPORARILY DISABLED: },
    // TEMPORARILY DISABLED: }),
    // TEMPORARILY DISABLED: });
    // TEMPORARILY DISABLED: const _dag_operations_kernel_tests_run = b.addRunArtifact(dag_operations_kernel_tests);
    // TEMPORARILY DISABLED: test_step.dependOn(&dag_operations_kernel_tests_run.step);

    // File system integration test (VM integration)
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const file_system_integration_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/098_file_system_integration_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const file_system_integration_tests_run = b.addRunArtifact(file_system_integration_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&file_system_integration_tests_run.step);

    // Performance benchmark verification test
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const performance_benchmark_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/100_performance_benchmark_verification_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_vm", .module = kernel_vm_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const performance_benchmark_tests_run = b.addRunArtifact(performance_benchmark_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&performance_benchmark_tests_run.step);

    // Cross-platform compatibility tests (Phase 6.4)
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const cross_platform_compatibility_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/101_cross_platform_compatibility_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "kernel_platform", .module = kernel_platform_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const cross_platform_compatibility_tests_run = b.addRunArtifact(cross_platform_compatibility_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&cross_platform_compatibility_tests_run.step);

    // Interrupt and exception abstraction tests (Phase 6.4)
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const interrupt_exception_abstraction_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/102_interrupt_exception_abstraction_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const interrupt_exception_abstraction_tests_run = b.addRunArtifact(interrupt_exception_abstraction_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&interrupt_exception_abstraction_tests_run.step);

    // ARCHIVED 2026-01-13 03:22:03 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Vantage adaptation host interface tests (Priority 1)
    // const vantage_adaptation_host_interface_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/103_vantage_adaptation_host_interface_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "basin_kernel", .module = basin_kernel_module },
    //         },
    //     }),
    // });
    // const vantage_adaptation_host_interface_tests_run = b.addRunArtifact(vantage_adaptation_host_interface_tests);
    // test_step.dependOn(&vantage_adaptation_host_interface_tests_run.step);

    // ARCHIVED 2026-01-13 03:22:03 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Vantage adaptation JIT integration tests (Priority 1)
    // const vantage_adaptation_jit_integration_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/104_vantage_adaptation_jit_integration_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "basin_kernel", .module = basin_kernel_module },
    //         },
    //     }),
    // });
    // const vantage_adaptation_jit_integration_tests_run = b.addRunArtifact(vantage_adaptation_jit_integration_tests);
    // test_step.dependOn(&vantage_adaptation_jit_integration_tests_run.step);

    // ARCHIVED 2026-01-13 03:22:03 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Vantage adaptation VM statistics tests (Priority 1)
    // const vantage_adaptation_vm_statistics_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/105_vantage_adaptation_vm_statistics_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "basin_kernel", .module = basin_kernel_module },
    //         },
    //     }),
    // });
    // const vantage_adaptation_vm_statistics_tests_run = b.addRunArtifact(vantage_adaptation_vm_statistics_tests);
    // test_step.dependOn(&vantage_adaptation_vm_statistics_tests_run.step);

    // ARCHIVED 2026-01-13 03:22:03 PST: macOS Tahoe/Vantage deployment - commented out until x86 Framework tasks complete
    // Vantage adaptation full integration tests (Priority 1)
    // const vantage_adaptation_full_integration_tests = b.addTest(.{
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("tests/106_vantage_adaptation_full_integration_test.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "basin_kernel", .module = basin_kernel_module },
    //         },
    //     }),
    // });
    // const vantage_adaptation_full_integration_tests_run = b.addRunArtifact(vantage_adaptation_full_integration_tests);
    // test_step.dependOn(&vantage_adaptation_full_integration_tests_run.step);

    const kernel_stats_aggregator_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/110_kernel_stats_aggregator_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "basin_kernel", .module = basin_kernel_module },
            },
        }),
    });
    const kernel_stats_aggregator_tests_run = b.addRunArtifact(kernel_stats_aggregator_tests);
    test_step.dependOn(&kernel_stats_aggregator_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const kernel_stats_health_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/112_kernel_stats_health_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const kernel_stats_health_tests_run = b.addRunArtifact(kernel_stats_health_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&kernel_stats_health_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const get_resource_usage_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/113_get_resource_usage_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const get_resource_usage_tests_run = b.addRunArtifact(get_resource_usage_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&get_resource_usage_tests_run.step);

    // Set resource limit tests (Priority 1)
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const set_resource_limit_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/118_set_resource_limit_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const set_resource_limit_tests_run = b.addRunArtifact(set_resource_limit_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&set_resource_limit_tests_run.step);

    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const syscall_timeout_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/117_syscall_timeout_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .imports = &.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //                 .{ .name = "basin_kernel", .module = basin_kernel_module },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             },
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const syscall_timeout_tests_run = b.addRunArtifact(syscall_timeout_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&syscall_timeout_tests_run.step);

    // Graincard format validation test
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const graincard_format_validation_tests = b.addTest(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         .root_module = b.createModule(.{
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .root_source_file = b.path("tests/152_graincard_format_validation_test.zig"),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .target = target,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //             .optimize = optimize,
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //         }),
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     });
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     const graincard_format_validation_tests_run = b.addRunArtifact(graincard_format_validation_tests);
    // ARCHIVED 2026-01-13 03:54:03 PST: Test archived - not essential for kernel/x86 Framework
    //     test_step.dependOn(&graincard_format_validation_tests_run.step);
}

