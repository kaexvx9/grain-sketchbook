const std = @import("std");
const grainvalidate = @import("grainvalidate");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // VM modules to validate
    const targets = [_][]const u8{
        "src/kernel_vm/vm.zig",
        "src/kernel_vm/jit.zig",
        "src/kernel_vm/integration.zig",
        "src/kernel_vm/host_interface.zig",
        "src/kernel_vm/host_macos.zig",
        "src/kernel_vm/loader.zig",
        "src/kernel_vm/arch.zig",
        "src/kernel_vm/sbi.zig",
        "src/kernel_vm/serial.zig",
        "src/kernel_vm/syscall.zig",
        "src/kernel_vm/performance.zig",
        "src/kernel_vm/instruction_stats.zig",
        "src/kernel_vm/memory_stats.zig",
        "src/kernel_vm/syscall_stats.zig",
        "src/kernel_vm/exception_stats.zig",
        "src/kernel_vm/branch_stats.zig",
        "src/kernel_vm/register_stats.zig",
        "src/kernel_vm/instruction_perf.zig",
        "src/kernel_vm/execution_flow.zig",
        "src/kernel_vm/stats_aggregator.zig",
        "src/kernel_vm/stats_export.zig",
        "src/kernel_vm/debug_interface.zig",
        "src/kernel_vm/debug_command.zig",
        "src/kernel_vm/state_inspection.zig",
        "src/kernel_vm/execution_control.zig",
        "src/kernel_vm/instruction_trace.zig",
        "src/kernel_vm/checkpoint.zig",
        "src/kernel_vm/state_snapshot.zig",
        "src/kernel_vm/optimization_hints.zig",
        "src/kernel_vm/memory_protection.zig",
        "src/kernel_vm/error_log.zig",
        "src/kernel_vm/benchmark.zig",
        "src/kernel_vm/benchmark_jit.zig",
        "src/kernel_vm/vm_aarch64.zig",
        "src/kernel_vm/test.zig",
        "src/kernel_vm/kernel_vm.zig",
    };

    var failure = false;
    var total_violations: u32 = 0;
    var total_functions: u32 = 0;
    var total_lines: u32 = 0;

    for (targets) |path| {
        var file = std.fs.cwd().openFile(path, .{}) catch |err| {
            std.log.warn("Could not open {s}: {s}", .{ path, @errorName(err) });
            continue;
        };
        defer file.close();

        const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
        defer allocator.free(contents);

        const result = try grainvalidate.validate(
            allocator,
            contents,
            grainvalidate.default_config,
        );
        defer grainvalidate.free_result(allocator, result);

        total_functions += result.total_functions;
        total_lines += result.total_lines;

        if (!result.compliant) {
            failure = true;
            total_violations += @intCast(result.violations.len);
            std.log.err("{s}: {d} violations (functions: {d}, lines: {d})", .{ path, result.violations.len, result.total_functions, result.total_lines });

            for (result.violations) |violation| {
                std.log.err("  line {d}: {s}", .{ violation.line, violation.message });
            }
        } else {
            std.log.info("{s}: compliant (functions: {d}, lines: {d})", .{ path, result.total_functions, result.total_lines });
        }
    }

    std.log.info("\nSummary: {d} violations across {d} functions, {d} total lines", .{ total_violations, total_functions, total_lines });

    if (failure) {
        return error.ValidationFailed;
    }
}
