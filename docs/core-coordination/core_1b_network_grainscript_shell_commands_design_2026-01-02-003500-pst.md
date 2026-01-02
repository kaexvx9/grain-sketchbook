# Core 1b Network Agent: Grainscript Shell Network Commands Design

**Date**: 2026-01-02-003500-pst  
**Agent**: Core 1b Network Agent (L2 Sub-Agent)  
**Parent Agent**: Core 1 Subcore Agent (Agent 1, L1 Subcore)  
**Status**: 🆕 **DESIGN DOCUMENT** — Prepared for Grainscript Shell (1e) integration  
**Voice**: Glow G2 (calm, solution-focused, forward-looking)

---

## Executive Summary

This document designs the network commands integration for Grainscript Shell (1e). This is preparation work that can proceed independently while waiting for Grainscript Shell architecture. The design will be refined during coordination with Agent 1e.

**Goal**: Enable Grainscript Shell to execute network commands (ping, curl, wget, netstat, ifconfig) using Network Agent services.

**Status**: Design prepared, ready for coordination when Agent 1e architecture available.

---

## Network Commands to Implement

### 1. `ping` - Network Connectivity Test

**Purpose**: Test network connectivity to a host

**Usage**: `ping <hostname_or_ip> [count]`

**Implementation**:
- Use `network_stack` for socket operations
- Use `ip_address` for IP address parsing
- Send ICMP echo requests (or TCP connection test if ICMP unavailable)
- Display round-trip time and packet loss

**Network Agent Modules Used**:
- `src/grain_core/network_stack.zig` - Socket operations
- `src/grain_core/ip_address.zig` - IP address parsing

**Grain Style Requirements**:
- Bounded timeout (MAX_PING_TIMEOUT)
- Bounded packet count (MAX_PING_COUNT)
- Explicit u32/u64 types
- ≤ 70 lines per function

---

### 2. `curl` - HTTP Client Command

**Purpose**: Make HTTP requests from shell

**Usage**: `curl [options] <url>`

**Options** (basic set):
- `-X <method>` - HTTP method (GET, POST, PUT, DELETE)
- `-H <header>` - Add custom header
- `-d <data>` - Request body data
- `-o <file>` - Output to file
- `-v` - Verbose output

**Implementation**:
- Use `http_client` for HTTP requests
- Use `dns_resolver` for hostname resolution
- Parse URL and extract host, port, path
- Display response status and body

**Network Agent Modules Used**:
- `src/grain_core/http_client.zig` - HTTP client
- `src/grain_core/dns_resolver.zig` - DNS resolution
- `src/grain_core/ip_address.zig` - URL parsing

**Grain Style Requirements**:
- Bounded URL length (MAX_URL_LEN)
- Bounded header count (MAX_HEADERS)
- Bounded response size (MAX_RESPONSE_SIZE)
- Explicit u32/u64 types
- ≤ 70 lines per function

---

### 3. `wget` - File Download Command

**Purpose**: Download files from HTTP/HTTPS URLs

**Usage**: `wget <url> [output_file]`

**Implementation**:
- Use `http_client.download_file()` method
- Use `file_transfer` integration for file operations
- Display download progress
- Handle chunked transfer encoding

**Network Agent Modules Used**:
- `src/grain_core/http_client.zig` - HTTP client with file transfer
- `src/grain_core/chunked_transfer.zig` - Chunked transfer support
- `src/grain_core/file_transfer_handlers.zig` - File transfer integration

**Grain Style Requirements**:
- Bounded file size (MAX_DOWNLOAD_SIZE)
- Bounded URL length (MAX_URL_LEN)
- Explicit u32/u64 types
- ≤ 70 lines per function

---

### 4. `netstat` - Network Statistics

**Purpose**: Display network connection statistics

**Usage**: `netstat [options]`

**Options** (basic set):
- `-a` - Show all connections
- `-t` - Show TCP connections
- `-u` - Show UDP connections
- `-n` - Show numerical addresses

**Implementation**:
- Use `network_stack` for socket enumeration
- Use `network_manager` for interface statistics
- Display connection state, local/remote addresses, ports

**Network Agent Modules Used**:
- `src/grain_core/network_stack.zig` - Socket operations
- `src/grain_core/network_manager.zig` - Network interface management
- `src/grain_core/ip_address.zig` - IP address formatting

**Grain Style Requirements**:
- Bounded connection count (MAX_CONNECTIONS)
- Explicit u32/u64 types
- ≤ 70 lines per function

---

### 5. `ifconfig` - Interface Configuration (Optional)

**Purpose**: Display and configure network interfaces

**Usage**: `ifconfig [interface] [options]`

**Implementation**:
- Use `network_manager` for interface enumeration
- Use `ip_address` for IP address formatting
- Display interface status, addresses, MTU

**Network Agent Modules Used**:
- `src/grain_core/network_manager.zig` - Interface management
- `src/grain_core/ip_address.zig` - IP address formatting

**Grain Style Requirements**:
- Bounded interface count (MAX_INTERFACES)
- Explicit u32/u64 types
- ≤ 70 lines per function

---

## Shell Integration Architecture

### Command Interface Design

**Proposed Shell Command Interface**:
```zig
// Network command execution interface
pub const NetworkCommand = struct {
    name: []const u8,
    execute: fn(args: []const []const u8, stdout: anytype, stderr: anytype) u8,
    help: []const u8,
};

// Command registration
pub fn register_network_commands(shell: *Shell) void {
    shell.register_command(NetworkCommand{
        .name = "ping",
        .execute = ping_command,
        .help = "Test network connectivity",
    });
    // ... other commands
}
```

**Integration Points**:
- Shell command parser (from Agent 1e)
- Shell command executor (from Agent 1e)
- Shell stdio (from Agent 1e)

---

### Command Implementation Structure

**Proposed Structure**:
```
grainstore/sevenos/src/shell/commands/
├── network_commands.zig      # Network command registration
├── ping.zig                   # Ping command implementation
├── curl.zig                   # Curl command implementation
├── wget.zig                   # Wget command implementation
├── netstat.zig                # Netstat command implementation
└── ifconfig.zig               # Ifconfig command implementation (optional)
```

**Each Command Module**:
- Implements command execution function
- Follows Grain Style strictly
- Uses Network Agent modules
- Provides help text
- Handles errors gracefully

---

## Integration Approach

### Step 1: Review Grainscript Shell Architecture

**What We Need**:
- Shell command parser interface
- Shell command executor interface
- Shell stdio interface
- Command registration API

**Timeline**: When Agent 1e architecture available

---

### Step 2: Design API Contract

**What We Need**:
- Agree on command interface structure
- Agree on error handling approach
- Agree on stdio integration
- Plan command registration

**Timeline**: During coordination with Agent 1e

---

### Step 3: Implementation

**Network Agent Side**:
1. Implement network command modules
2. Implement command registration
3. Integrate with shell command parser
4. Create command tests

**Shell Agent Side** (coordination needed):
1. Provide command parser interface
2. Provide command executor interface
3. Provide stdio interface
4. Integrate network commands

**Timeline**: 2-4 weeks after API contract agreed

---

### Step 4: Testing

**Integration Tests**:
- Test each network command independently
- Test command error handling
- Test command output formatting
- Test command integration with shell

**Timeline**: After implementation complete

---

## Design Considerations

### Grain Style Compliance

**All Functions**:
- ≤ 70 lines (`grain validate-70`)
- ≤ 100 characters per line (`grainwrap-100`)
- Explicit `u32`/`u64` types (no `usize`/`isize`)
- Minimum 2 assertions per function
- Bounded allocations with MAX_ constants

**Command Implementation**:
- Bounded argument parsing
- Bounded output formatting
- Bounded error messages
- Explicit error handling

---

### User Experience

**Command Output**:
- Clear, readable output
- Error messages that are helpful
- Progress indicators for long operations
- Consistent formatting

**Error Handling**:
- Graceful error messages
- Exit codes (0 = success, non-zero = error)
- Clear error descriptions

---

## Coordination Points

### With Grainscript Shell (1e)

**API Contract Design**:
- Command interface structure
- Command registration API
- stdio integration
- Error handling approach

**Implementation Coordination**:
- Command implementation
- Shell integration
- Testing approach

**Timeline**: When Agent 1e architecture available

---

### With Core 1 Subcore

**Coordination Facilitation**:
- Facilitate coordination with Agent 1e
- Review and approve API contracts
- Coordinate integration timeline

**Check-In**: Will check in before starting integration work

---

## Next Steps

### Immediate (Independent Work)

1. **Refine Design Document**:
   - Add more detail to command implementations
   - Design command interface structure
   - Plan error handling approach

2. **Prepare for Coordination**:
   - List questions for Grainscript Shell Agent
   - Prepare integration scenarios
   - Design test cases

3. **Continue Network Services Development**:
   - Work on other network services independently
   - Framework x86 adaptation as needed

---

### After Coordination

1. **Implement Commands**:
   - Implement agreed-upon command interface
   - Integrate with shell command parser
   - Create command tests

2. **Create Integration Tests**:
   - Test each network command
   - Test command error handling
   - Test shell integration

3. **Document Integration**:
   - Document command API contracts
   - Document integration patterns
   - Update coordination documents

---

## Summary

**Status**: ✅ **DESIGN DOCUMENT PREPARED** — Ready for Grainscript Shell coordination

**Current State**:
- Design document created
- Network commands designed
- Integration approach planned
- Ready for coordination when Agent 1e architecture available

**Next Steps**:
- Await Grainscript Shell architecture
- Refine design based on coordination feedback
- Implement after API contracts agreed

**No Blockers**: Design work can proceed independently, implementation blocked on Agent 1e architecture

---

**Date**: 2026-01-02-003500-pst  
**Agent**: Core 1b Network Agent (L2 Sub-Agent)  
**Parent Agent**: Core 1 Subcore Agent (Agent 1, L1 Subcore)  
**Status**: ✅ **DESIGN DOCUMENT PREPARED** — Ready for Grainscript Shell coordination

---

