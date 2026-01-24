# Vantage 3: Wayland Protocol Bounds Constants - Finalized

**Date**: 2026-01-23-181500-pst  
**Status**: ✅ **FINALIZED**

---

## Overview

Finalized bounds constants for Wayland protocol implementation based on deep analysis of protocol specification and Rye Style requirements.

---

## Bounds Constants

### Message-Level Bounds

#### MAX_MESSAGE_SIZE
- **Value**: `65535` (u32)
- **Rationale**: 
  - Wayland wire format enforces 16-bit message size field (max 2^16 - 1 = 65,535 bytes)
  - Intrinsic protocol limit, cannot be exceeded
  - Matches wire format specification exactly
- **Usage**: Validate message size during parsing

#### MAX_STRING_LENGTH
- **Value**: `65536` (u32) = 64KB
- **Rationale**:
  - Protocol allows up to 4GB strings (u32 length field)
  - 64KB is reasonable for protocol strings (interface names, error messages)
  - Matches message size limit for consistency
  - Prevents memory exhaustion attacks
- **Usage**: Validate string length in message parsing

#### MAX_ARRAY_SIZE
- **Value**: `65536` (u32) = 64KB
- **Rationale**:
  - Protocol allows up to 4GB arrays (u32 size field)
  - 64KB matches message size limit (arrays are part of messages)
  - Prevents memory exhaustion attacks
  - Reasonable for protocol data structures
- **Usage**: Validate array size in message parsing

#### MAX_FDS_PER_MESSAGE
- **Value**: `8` (u32)
- **Rationale**:
  - Protocol doesn't specify limit, but file descriptors are limited by OS
  - 8 is reasonable for typical Wayland operations (shared memory, data transfer)
  - Prevents resource exhaustion
  - Matches common Wayland implementation patterns
- **Usage**: Validate file descriptor count in message parsing

### Object-Level Bounds

#### MAX_OBJECTS_PER_CLIENT
- **Value**: `1024` (u32) - **EXISTING**
- **Rationale**: Already defined in `grain_core/wayland/protocol.zig`
- **Usage**: Limit objects per client connection

#### MAX_CLIENTS
- **Value**: `64` (u32) - **EXISTING**
- **Rationale**: Already defined in `grain_core/wayland/protocol.zig`
- **Usage**: Limit concurrent client connections

### Surface-Level Bounds

#### MAX_SURFACE_WIDTH
- **Value**: `8192` (u32) - **EXISTING**
- **Rationale**: Already defined in `grain_core/wayland/protocol.zig`
- **Usage**: Limit surface width in pixels

#### MAX_SURFACE_HEIGHT
- **Value**: `8192` (u32) - **EXISTING**
- **Rationale**: Already defined in `grain_core/wayland/protocol.zig`
- **Usage**: Limit surface height in pixels

### Interface Name Bounds

#### MAX_INTERFACE_NAME_LENGTH
- **Value**: `64` (u32) - **EXISTING**
- **Rationale**: Already defined in `InterfaceName.data: [64]u8`
- **Usage**: Limit interface name length

---

## Implementation Strategy

### Message Parsing Bounds Checking

1. **Message Header Validation**:
   - Verify message size ≤ MAX_MESSAGE_SIZE (enforced by wire format, but validate explicitly)
   - Verify object ID in valid range

2. **String Argument Validation**:
   - Read length field (u32)
   - Verify length ≤ MAX_STRING_LENGTH
   - Verify length ≤ remaining message bytes
   - Read string data with bounds checking

3. **Array Argument Validation**:
   - Read size field (u32)
   - Verify size ≤ MAX_ARRAY_SIZE
   - Verify size ≤ remaining message bytes
   - Read array data with bounds checking

4. **File Descriptor Validation**:
   - Count FDs in message
   - Verify count ≤ MAX_FDS_PER_MESSAGE
   - Validate FD validity

### Error Handling

- **Bounds Violations**: Report protocol error, close connection
- **Memory Errors**: Report out-of-memory error, close connection
- **Invalid Data**: Report protocol error, close connection

---

## Constants Summary

```zig
// Message-level bounds
pub const MAX_MESSAGE_SIZE: u32 = 65535;        // Wire format limit
pub const MAX_STRING_LENGTH: u32 = 65536;       // 64KB
pub const MAX_ARRAY_SIZE: u32 = 65536;          // 64KB
pub const MAX_FDS_PER_MESSAGE: u32 = 8;         // Reasonable limit

// Object-level bounds (existing)
pub const MAX_OBJECTS_PER_CLIENT: u32 = 1024;   // Existing
pub const MAX_CLIENTS: u32 = 64;                 // Existing

// Surface-level bounds (existing)
pub const MAX_SURFACE_WIDTH: u32 = 8192;        // Existing
pub const MAX_SURFACE_HEIGHT: u32 = 8192;       // Existing

// Interface name bounds (existing)
pub const MAX_INTERFACE_NAME_LENGTH: u32 = 64;  // Existing (InterfaceName.data)
```

---

## Rationale Summary

### Why These Values?

1. **MAX_MESSAGE_SIZE (65535)**: Intrinsic wire format limit, cannot be changed
2. **MAX_STRING_LENGTH (64KB)**: 
   - Reasonable for protocol strings
   - Matches message size limit
   - Prevents memory exhaustion
3. **MAX_ARRAY_SIZE (64KB)**:
   - Matches message size limit (arrays are part of messages)
   - Prevents memory exhaustion
   - Reasonable for protocol data
4. **MAX_FDS_PER_MESSAGE (8)**:
   - Reasonable for typical operations
   - Prevents resource exhaustion
   - Matches common patterns

### Trade-offs

- **Stricter Limits**: More secure, but may reject valid Wayland clients
- **Looser Limits**: More compatible, but less secure
- **Chosen Values**: Balance between security and compatibility

---

## Next Steps

1. ✅ **Bounds Constants Finalized** — This document
2. 🚧 **Extend Existing Code** — Add new constants to `grain_core/wayland/protocol.zig`
3. 🚧 **Implement Message Parser** — With bounds checking
4. 🚧 **Test Implementation** — Verify bounds are enforced
5. 🚧 **Document Usage** — Examples and patterns

---

**Status**: ✅ **FINALIZED** — Constants defined, ready for implementation

---

**Date**: 2026-01-23-181500-pst  
**Agent**: Vantage 3 Subcore (Rye Compiler Fork Development)
