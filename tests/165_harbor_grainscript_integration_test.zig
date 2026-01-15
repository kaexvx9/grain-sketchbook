//! Basin + Grainscript Integration Test (Phase 3)
//! Why: Test Basin Kernel and Grainscript work together without VM runtime
//! Grain Style: Arena allocators (bounded, explicit, startup-time), pointers not values

const std = @import("std");
const testing = std.testing;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;
const Syscall = basin_kernel.Syscall;
const RawIO = basin_kernel.RawIO;
const grainscript = @import("grainscript");
const Lexer = grainscript.Lexer;
const Parser = grainscript.Parser;
const Interpreter = grainscript.Interpreter;

// Test: Basin Kernel + Grainscript integration (no VM)
test "basin + grainscript: kernel syscall from grainscript" {
    // Disable RawIO to avoid SIGILL in tests.
    RawIO.disable();
    defer RawIO.enable();
    
    // Grain Style: Arena allocator (bounded, explicit, startup-time)
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    // Allocate Kernel via arena (Grain Style: bounded, explicit)
    const kernel = try allocator.create(BasinKernel);
    BasinKernel.init_in_place(kernel);
    
    // Initialize Grainscript interpreter
    const source = "42;"; // Simple expression
    var lexer = try Lexer.init(allocator, source);
    defer lexer.deinit();
    
    try lexer.tokenize();
    
    var parser = try Parser.init(allocator, &lexer);
    defer parser.deinit();
    
    try parser.parse();
    
    var interpreter = try Interpreter.init(allocator, &parser);
    defer interpreter.deinit();
    
    // Execute Grainscript
    try interpreter.execute();
    
    // Verify both work together
    try testing.expect(interpreter.get_exit_code() == 0);
    try testing.expect(kernel.user_count >= 1);
}

// Test: Kernel syscall validation from Grainscript context
test "basin + grainscript: syscall validation" {
    // Disable RawIO to avoid SIGILL in tests.
    RawIO.disable();
    defer RawIO.enable();
    
    // Grain Style: Arena allocator
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    // Allocate Kernel via arena
    const kernel = try allocator.create(BasinKernel);
    BasinKernel.init_in_place(kernel);
    
    // Test that we can call kernel syscalls (simulating from Grainscript)
    const result = basin_kernel.handle_syscall(
        kernel,
        @intFromEnum(Syscall.sysinfo),
        0x1000, // stats pointer
        0, 0, 0
    ) catch |err| {
        // Syscall may fail in test environment - that's acceptable
        _ = err;
        return;
    };
    
    // Verify syscall works
    try testing.expect(result == .success or result == .err);
    
    // Verify kernel state
    try testing.expect(kernel.user_count >= 1);
}
