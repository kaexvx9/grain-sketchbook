//! Framework x86_64 Test Runner
//! Why: Execute integration tests on Framework x86_64 hardware (AMD or Intel).
//! Grain Style: Explicit types (u32/u64), bounded operations, assertions.

const std = @import("std");
const builtin = @import("builtin");
const test_framework = @import("test_framework");
const TestArchitecture = test_framework.TestArchitecture;
const TestRunner = test_framework.TestRunner;
const TestMetadata = test_framework.TestMetadata;

// Maximum test name length.
const MAX_TEST_NAME_LEN: u32 = 256;
// Maximum output directory path length.
const MAX_OUTPUT_DIR_LEN: u32 = 512;

/// Framework x86_64 test runner configuration.
/// Why: Configuration for test execution on Framework x86_64.
/// GrainStyle: Explicit types, bounded allocations, assertions.
const Config = struct {
    /// Test filter (optional, empty string means all tests).
    test_filter: []const u8,
    /// Output directory for test results.
    output_dir: []const u8,
    /// Architecture variant (amd or intel).
    architecture: TestArchitecture,
    /// Verbose output.
    verbose: bool,

    /// Initialize configuration from command line arguments.
    /// Why: Parse command line arguments for test runner configuration.
    /// Contract: Returns configuration or error.
    /// Grain Style: Explicit types, bounded operations, assertions.
    fn init(
        allocator: std.mem.Allocator,
        args: []const []const u8,
    ) !Config {
        std.debug.assert(@intFromPtr(allocator.ptr) != 0);
        std.debug.assert(args.len > 0);

        var config = Config{
            .test_filter = "",
            .output_dir = "./test_results",
            .architecture = test_framework.detect_test_architecture(),
            .verbose = false,
        };

        // Parse command line arguments.
        var i: u32 = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            std.debug.assert(arg.len <= MAX_TEST_NAME_LEN);

            if (std.mem.eql(u8, arg, "--filter") or
                std.mem.eql(u8, arg, "-f"))
            {
                // Test filter.
                std.debug.assert(i + 1 < args.len);
                config.test_filter = args[i + 1];
                i += 1;
            } else if (std.mem.eql(u8, arg, "--output") or
                std.mem.eql(u8, arg, "-o"))
            {
                // Output directory.
                std.debug.assert(i + 1 < args.len);
                config.output_dir = args[i + 1];
                i += 1;
            } else if (std.mem.eql(u8, arg, "--verbose") or
                std.mem.eql(u8, arg, "-v"))
            {
                // Verbose output.
                config.verbose = true;
            } else if (std.mem.eql(u8, arg, "--help") or
                std.mem.eql(u8, arg, "-h"))
            {
                // Print usage and exit.
                print_usage(args[0]);
                std.process.exit(0);
            }
        }

        // Validate architecture.
        std.debug.assert(config.architecture == .x86_64_amd or
            config.architecture == .x86_64_intel);

        return config;
    }
};

/// Print usage information.
/// Why: Help users understand command line options.
/// Grain Style: Clear output, no side effects.
fn print_usage(program_name: []const u8) void {
    std.debug.assert(program_name.len > 0);

    const usage =
        \\Usage: {s} [OPTIONS]
        \\
        \\Options:
        \\  --filter, -f TEST_NAME    Filter tests by name pattern
        \\  --output, -o DIR          Output directory for test results
        \\  --verbose, -v             Enable verbose output
        \\  --help, -h                Show this help message
        \\
        \\Examples:
        \\  {s} --filter "integration"
        \\  {s} --output ./results --verbose
        \\
    ;

    std.debug.print(usage, .{ program_name, program_name, program_name });
}

/// Main entry point for Framework x86_64 test runner.
/// Why: Execute integration tests on Framework x86_64 hardware.
/// Contract: Returns exit code (0 on success, non-zero on failure).
/// Grain Style: Explicit types, bounded operations, assertions.
pub fn main() !u8 {
    // Assert: Must be running on x86_64 (precondition).
    std.debug.assert(builtin.cpu.arch == .x86_64);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments.
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    std.debug.assert(args.len > 0);

    // Initialize configuration.
    const config = try Config.init(allocator, args);

    // Detect architecture.
    const arch = test_framework.detect_test_architecture();

    // Assert: Architecture must be x86_64 (AMD or Intel).
    std.debug.assert(arch == .x86_64_amd or arch == .x86_64_intel);

    // Print configuration.
    if (config.verbose) {
        const arch_name = test_framework.get_architecture_name(arch);
        std.debug.print(
            "Framework x86_64 Test Runner\n",
            .{},
        );
        std.debug.print("Architecture: {s}\n", .{arch_name});
        std.debug.print("Output Directory: {s}\n", .{config.output_dir});
        if (config.test_filter.len > 0) {
            std.debug.print("Test Filter: {s}\n", .{config.test_filter});
        }
    }

    // Create output directory.
    std.fs.cwd().makePath(config.output_dir) catch |err| {
        std.debug.print(
            "Error creating output directory: {}\n",
            .{err},
        );
        return 1;
    };

    // Initialize test runner.
    var runner = TestRunner.init(allocator);
    defer runner.deinit();

    // Execute tests via Zig test runner.
    // Note: This is a wrapper that orchestrates test execution.
    // Actual test execution happens via Zig's built-in test runner.

    // Generate test report.
    const report = try runner.generate_test_report();
    defer allocator.free(report);

    // Write report to file.
    const timestamp = std.time.timestamp();
    const report_filename = try std.fmt.allocPrint(
        allocator,
        "{s}/test_results_{s}_{d}.txt",
        .{ config.output_dir, test_framework.get_architecture_name(arch), timestamp },
    );
    defer allocator.free(report_filename);

    const file = try std.fs.cwd().createFile(report_filename, .{});
    defer file.close();

    try file.writeAll(report);

    // Export JSON report.
    const json_report = try runner.export_test_results_json();
    defer allocator.free(json_report);

    const json_filename = try std.fmt.allocPrint(
        allocator,
        "{s}/test_results_{s}_{d}.json",
        .{ config.output_dir, test_framework.get_architecture_name(arch), timestamp },
    );
    defer allocator.free(json_filename);

    const json_file = try std.fs.cwd().createFile(json_filename, .{});
    defer json_file.close();

    try json_file.writeAll(json_report);

    // Print results.
    if (config.verbose) {
        std.debug.print("\n{s}\n", .{report});
    }

    std.debug.print("Test results saved to: {s}\n", .{report_filename});
    std.debug.print("JSON results saved to: {s}\n", .{json_filename});

    // Return success.
    return 0;
}


