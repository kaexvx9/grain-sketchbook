//! Resource Cleanup for Process Termination
//! Why: Clean up process resources (memory, handles, channels) when process exits.

const Debug = @import("debug.zig");
const BasinKernel = @import("basin_kernel.zig").BasinKernel;
const types = @import("basin_kernel_types.zig");
const channel = @import("channel.zig");

// Use correct constants from modules.
const MAX_MAPPINGS: u32 = types.MAX_MAPPINGS;
const MAX_HANDLES: u32 = types.MAX_HANDLES;
const MAX_CHANNELS: u32 = channel.MAX_CHANNELS;

/// Clean up all resources owned by a process.
/// Why: Free memory mappings, handles, and channels when process exits.
pub fn cleanup_process_resources(kernel: *BasinKernel, process_id: u32) u32 {
    Debug.kassert(process_id != 0, "Process ID is 0", .{});

    const mappings = cleanup_process_mappings(kernel, process_id);
    const handles = cleanup_process_handles(kernel, process_id);
    const channels = cleanup_process_channels(kernel, process_id);

    return mappings + handles + channels;
}

/// Clean up memory mappings owned by a process.
/// Why: Free memory mappings when process exits.
fn cleanup_process_mappings(kernel: *BasinKernel, process_id: u32) u32 {
    var freed: u32 = 0;
    var i: u32 = 0;
    while (i < MAX_MAPPINGS) : (i += 1) {
        const m = &kernel.mappings[i];
        if (m.allocated and m.owner_process_id == process_id) {
            m.allocated = false;
            m.owner_process_id = 0;
            freed += 1;
        }
    }
    return freed;
}

/// Clean up file handles owned by a process.
/// Why: Close file handles when process exits.
fn cleanup_process_handles(kernel: *BasinKernel, process_id: u32) u32 {
    var closed: u32 = 0;
    var i: u32 = 0;
    while (i < MAX_HANDLES) : (i += 1) {
        const h = &kernel.handles[i];
        if (h.allocated and h.owner_process_id == process_id) {
            h.allocated = false;
            h.owner_process_id = 0;
            closed += 1;
        }
    }
    return closed;
}

/// Clean up IPC channels owned by a process.
/// Why: Close IPC channels when process exits.
fn cleanup_process_channels(kernel: *BasinKernel, process_id: u32) u32 {
    var closed: u32 = 0;
    var i: u32 = 0;
    while (i < MAX_CHANNELS) : (i += 1) {
        const c = &kernel.channels.channels[i];
        if (c.allocated and c.owner_process_id == process_id) {
            c.allocated = false;
            c.owner_process_id = 0;
            closed += 1;
        }
    }
    return closed;
}
