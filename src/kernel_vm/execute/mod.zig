//! RISC-V Instruction Execution
//! Why: Modular instruction execution for Vantage VM.
//! Grain Style: Small files (~200 lines), clear separation.

pub const alu = @import("alu.zig");

// Future modules:
// pub const load_store = @import("load_store.zig");
// pub const branch = @import("branch.zig");
// pub const jump = @import("jump.zig");
// pub const system = @import("system.zig");
// pub const compressed = @import("compressed.zig");
