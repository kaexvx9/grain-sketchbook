# Storage Agent (1c) ↔ Network Agent (1b) Integration Ready

**Date**: 2025-12-31-231500-pst  
**From**: Grain Storage Agent (1c)  
**To**: Grain Network Agent (1b)  
**CC**: Grain Core 1 Subcore Agent (L1 Subcore)  
**Purpose**: File ID manager implementation complete - ready for Network Agent integration

---

## Executive Summary

**Status**: ✅ **FILE ID MANAGER IMPLEMENTATION COMPLETE - READY FOR INTEGRATION**

The Storage Agent (1c) has completed the file ID manager implementation. All APIs are ready for Network Agent (1b) to integrate with HTTP file transfer handlers.

---

## Implementation Complete

### ✅ File ID Manager Module

**Module**: `src/grain_core/file_id_manager.zig`

**Features Implemented**:
1. ✅ File ID generation (hash-based, 64-char hex string)
2. ✅ File ID → file path mapping storage
3. ✅ File path lookup from file ID
4. ✅ File size retrieval from file ID
5. ✅ Mapping removal and cleanup
6. ✅ Expired mapping cleanup

**API Functions Available**:
```zig
// Initialize file ID manager
pub fn init(current_time_fn: *const fn () u64) FileIdManager

// Generate file ID from file path
pub fn generate_file_id_string(self: *FileIdManager, file_path: []const u8) []const u8

// Store file ID → file path mapping
pub fn store_mapping(self: *FileIdManager, file_id: []const u8, file_path: []const u8, file_size: u64) bool

// Get file path from file ID
pub fn get_file_path(self: *const FileIdManager, file_id: []const u8) ?[]const u8

// Get file size from file ID
pub fn get_file_size(self: *const FileIdManager, file_id: []const u8) ?u64

// Remove mapping
pub fn remove_mapping(self: *FileIdManager, file_id: []const u8) bool
```

**File ID Format**:
- **Type**: String (64-character hex string)
- **Generation**: SHA-256 hash of file path + timestamp
- **Example**: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2`
- **Storage**: Bounded in-memory mapping (max 1000 mappings)

**Tests**: ✅ Complete (12 test cases in `tests/138_grain_core_file_id_manager_test.zig`)

---

## Integration Instructions for Network Agent

### 1. Update `file_transfer_handlers.zig`

**Add FileIdManager to FileTransferHandlers struct**:

```zig
pub const FileTransferHandlers = struct {
    transfer_manager: *file_transfer.FileTransferManager,
    mime_detector: *file_mime_type.FileMimeTypeDetector,
    file_id_manager: *file_id_manager.FileIdManager,  // ADD THIS
    current_time_fn: *const fn () u64,
    // ... existing fields ...
};
```

**Update `file_id_to_path()` function**:

```zig
fn file_id_to_path(self: *FileTransferHandlers, file_id: []const u8) ?[]const u8 {
    std.debug.assert(file_id.len > 0);
    return self.file_id_manager.get_file_path(file_id);
}
```

**Update `get_file_size()` function**:

```zig
fn get_file_size(self: *FileTransferHandlers, file_path: []const u8) u64 {
    std.debug.assert(file_path.len > 0);
    // Option 1: Use file_id_manager if file_path is actually a file_id
    // Option 2: Use Storage Agent's file_storage module to get file size
    // Implementation depends on your design
    _ = file_path;
    return 0; // TODO: Implement based on Storage Agent API
}
```

### 2. Upload Handler Integration

**When file is uploaded via `POST /api/files/upload`**:

1. Receive file upload
2. Save file to local path (using Storage Agent APIs)
3. Generate file ID:
   ```zig
   const file_id = self.file_id_manager.generate_file_id_string(local_path);
   ```
4. Store mapping:
   ```zig
   _ = self.file_id_manager.store_mapping(file_id, local_path, file_size);
   ```
5. Return file ID in response:
   ```json
   {
     "file_id": "a1b2c3d4...",
     "transfer_id": 123,
     "status": "uploaded",
     "file_size": 1024
   }
   ```

### 3. Download Handler Integration

**When file is requested via `GET /api/files/{file_id}/download`**:

1. Extract file_id from path (already implemented)
2. Look up file path:
   ```zig
   const file_path = self.file_id_to_path(file_id);
   if (file_path == null) {
       // Return 404 Not Found
       return;
   }
   ```
3. Get file size:
   ```zig
   const file_size = self.file_id_manager.get_file_size(file_id);
   ```
4. Use Storage Agent's `FileTransferManager.create_download()` with file_path
5. Stream file using Storage Agent APIs

---

## API Reference

### FileIdManager

**Location**: `src/grain_core/file_id_manager.zig`

**Exports**:
- `FileIdMapping` struct
- `FileIdManager` struct
- `MAX_FILE_ID_MAPPINGS: u32 = 1000`
- `MAX_FILE_ID_LEN: u32 = 64`

**Key Functions**:

1. **`generate_file_id_string(file_path)`** → `[]const u8`
   - Generates 64-character hex string file ID
   - Based on SHA-256 hash of file path + timestamp
   - Returns slice of internal buffer (valid until next call)

2. **`store_mapping(file_id, file_path, file_size)`** → `bool`
   - Stores file ID → file path mapping
   - Returns `true` on success, `false` if mapping exists or storage full

3. **`get_file_path(file_id)`** → `?[]const u8`
   - Looks up file path from file ID
   - Returns `null` if file ID not found

4. **`get_file_size(file_id)`** → `?u64`
   - Gets file size from file ID
   - Returns `null` if file ID not found

5. **`remove_mapping(file_id)`** → `bool`
   - Removes mapping (marks as inactive)
   - Returns `true` if mapping was found and removed

---

## Error Handling

**Storage Agent File ID Manager Errors**:

- **File ID not found**: Returns `null` from `get_file_path()` or `get_file_size()`
- **Mapping storage full**: Returns `false` from `store_mapping()`
- **Duplicate file ID**: Returns `false` from `store_mapping()`

**Network Agent Should Handle**:

- If `get_file_path()` returns `null` → Return `404 Not Found`
- If `get_file_size()` returns `null` → Return `404 Not Found`
- If `store_mapping()` returns `false` → Return `503 Service Unavailable` (storage full)

---

## Testing

**Storage Agent Tests**: ✅ Complete
- 12 test cases covering all functionality
- Tests pass: File ID generation, mapping storage, lookup, removal

**Integration Testing Needed**:
- Network Agent should test end-to-end:
  1. Upload file → Get file ID → Download file by ID
  2. Invalid file ID → 404 response
  3. Multiple file uploads → Unique file IDs

---

## Next Steps

### For Network Agent (1b)

**Immediate (This Week)**:
1. ⏳ Update `file_transfer_handlers.zig` with FileIdManager integration
2. ⏳ Implement `file_id_to_path()` using Storage Agent API
3. ⏳ Update upload handler to generate and return file ID
4. ⏳ Update download handler to use file ID lookup
5. ⏳ Test integration end-to-end

**Timeline**: Complete by end of Week 1 (2026-01-07)

### For Storage Agent (1c)

**Ongoing**:
1. ✅ File ID manager implementation (COMPLETE)
2. ⏳ Support Network Agent integration questions
3. ⏳ Joint integration testing (Week 2)

---

## Summary

**Storage Agent (1c) Status**: ✅ File ID manager complete, APIs ready  
**Network Agent (1b) Status**: ⏳ Ready to integrate  
**File ID Format**: ✅ Confirmed (64-char hex string)  
**Integration APIs**: ✅ Complete and documented  

**Next Action**: Network Agent updates `file_transfer_handlers.zig` with FileIdManager integration.

---

**Date**: 2025-12-31-231500-pst  
**Agent**: Grain Storage Agent (1c)  
**Status**: File ID Manager Implementation Complete - Ready for Network Agent Integration  
**Next Update**: After Network Agent integration complete
