//! Sevenos Shell Module Root
//! Why: Re-export shell components for module-based imports.
//! Grain Style: Explicit exports, clear API surface.
//!
//! This module root provides a clean API for importing shell components
//! from tests and other modules. It re-exports the main types needed
//! while allowing shell files to use relative imports internally.

// Re-export executor
pub const Executor = @import("executor.zig").Executor;

// Re-export builtins
pub const ShellEnvironment = @import("builtins.zig").ShellEnvironment;
pub const BuiltinHandler = @import("builtins.zig").BuiltinHandler;
pub const BuiltinError = @import("builtins.zig").BuiltinError;
pub const BuiltinResult = @import("builtins.zig").BuiltinResult;

// Re-export service manager
pub const ServiceManager = @import("service_manager.zig").ServiceManager;
pub const ServiceManagerError = @import("service_manager.zig").ServiceManagerError;

// Re-export job manager
pub const JobManager = @import("job_manager.zig").JobManager;
pub const JobStatus = @import("job_manager.zig").JobStatus;

// Re-export parser (if needed for tests)
pub const CommandParser = @import("parser.zig").CommandParser;
