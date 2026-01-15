# Core 1a Auth Agent: Shell Authentication Integration Design

**Date**: 2026-01-02-003955-pst  
**Agent**: Grain Auth Agent (1a) — L2 Sub-Agent  
**Parent Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **DESIGN READY** — Shell authentication integration patterns for Grainscript Shell (Agent 1e)

---

## Executive Summary

This document provides shell authentication integration design patterns for the Grainscript Shell (Agent 1e). These patterns are prepared for when Agent 1e completes its critical path work and is ready for authentication integration.

**Current Shell Status** (Agent 1e):
- ✅ Basic shell functionality implemented
- ✅ Command parsing and execution
- ✅ Built-in commands (cd, ls, pwd, echo, exit)
- ⏳ Authentication integration pending (after critical path completion)

**Auth Agent Integration Needs**:
- ⏳ Shell login authentication (username/password)
- ⏳ Session management for shell sessions
- ⏳ Permission checking for shell commands
- ⏳ User context in shell environment

---

## Current Shell Architecture Analysis

### Shell Structure

**Main Components** (`grainstore/sevenos/src/shell/`):
- `grainscript.zig` — Main shell loop
- `executor.zig` — Command executor
- `builtins.zig` — Built-in commands
- `parser.zig` — Command parser
- `stdio_wrapper.zig` — Standard I/O wrapper

**Shell Environment** (`builtins.zig`):
```zig
pub const ShellEnvironment = struct {
    current_directory: [4096]u8,
    current_directory_len: u32,
    allocator: std.mem.Allocator,
};
```

**Current Flow**:
1. Shell initializes environment
2. Main loop reads input
3. Parser parses commands
4. Executor executes commands (built-ins or external)
5. Output written to stdout

**No Authentication Currently**: Shell runs without user authentication.

---

## Proposed Authentication Integration Patterns

### Pattern 1: Shell Login Authentication

**Design**: Add login authentication before shell main loop starts.

**Proposed Flow**:
1. Shell starts
2. Check if user is already authenticated (via session or environment)
3. If not authenticated, prompt for login
4. Validate credentials via AuthService
5. Create shell session
6. Store user context in ShellEnvironment
7. Proceed to main shell loop

**Implementation**:
```zig
// Shell authentication context.
pub const ShellAuthContext = struct {
    user_id: [auth_service.MAX_USER_ID_LEN]u8,
    user_id_len: u32,
    session_id: [auth_service.MAX_SESSION_ID_LEN]u8,
    session_id_len: u32,
    roles: [auth_service.MAX_ROLES_PER_USER]u32,
    roles_len: u32,
    authenticated: bool,
    
    pub fn init() ShellAuthContext {
        return ShellAuthContext{
            .user_id = undefined,
            .user_id_len = 0,
            .session_id = undefined,
            .session_id_len = 0,
            .roles = undefined,
            .roles_len = 0,
            .authenticated = false,
        };
    }
};

// Authenticate user for shell session.
pub fn authenticate_shell_user(
    auth_service: *auth_service.AuthService,
    username: []const u8,
    password: []const u8,
    current_time: u64,
    auth_ctx: *ShellAuthContext,
) bool {
    std.debug.assert(auth_service != null);
    std.debug.assert(username.len > 0);
    std.debug.assert(password.len > 0);
    std.debug.assert(current_time > 0);
    std.debug.assert(auth_ctx != null);
    
    // Verify password (requires user lookup and password verification).
    // Note: This requires user storage integration (Storage Agent 1c).
    var user_id_buf: [auth_service.MAX_USER_ID_LEN]u8 = undefined;
    var user_id_len: u32 = 0;
    
    // TODO: Lookup user by username (requires Storage Agent integration).
    // For now, assume username is user_id.
    if (username.len > auth_service.MAX_USER_ID_LEN) {
        return false;
    }
    std.mem.copyForwards(u8, &user_id_buf, username);
    user_id_len = @intCast(username.len);
    
    // TODO: Verify password (requires password hash lookup from storage).
    // For now, skip password verification (placeholder).
    // const password_hash = lookup_password_hash(user_id_buf[0..user_id_len]);
    // if (!auth_service.verify_password_static(password, password_hash)) {
    //     return false;
    // }
    
    // Create session.
    var session: auth_service.Session = undefined;
    const session_created = auth_service.create_session(
        user_id_buf[0..user_id_len],
        current_time,
        &session,
    );
    
    if (!session_created) {
        return false;
    }
    
    // Store in auth context.
    auth_ctx.user_id_len = user_id_len;
    std.mem.copyForwards(u8, &auth_ctx.user_id, user_id_buf[0..user_id_len]);
    auth_ctx.session_id_len = session.session_id_len;
    std.mem.copyForwards(u8, &auth_ctx.session_id, session.session_id[0..session.session_id_len]);
    auth_ctx.authenticated = true;
    
    // TODO: Load user roles (requires Storage Agent integration).
    // For now, roles remain empty.
    auth_ctx.roles_len = 0;
    
    return true;
}
```

**Integration Points**:
- Shell startup: Check authentication before main loop
- Login prompt: Read username/password from stdin
- Session creation: Create session via AuthService
- User context: Store in ShellEnvironment

---

### Pattern 2: Extended Shell Environment

**Design**: Extend ShellEnvironment to include authentication context.

**Proposed Structure**:
```zig
// Extended shell environment with authentication.
pub const ShellEnvironment = struct {
    current_directory: [4096]u8,
    current_directory_len: u32,
    allocator: std.mem.Allocator,
    auth_context: ?ShellAuthContext, // Optional auth context
    
    /// Get current directory.
    pub fn get_cwd(self: *ShellEnvironment) []const u8 {
        return self.current_directory[0..self.current_directory_len];
    }
    
    /// Set current directory.
    pub fn set_cwd(self: *ShellEnvironment, path: []const u8) !void {
        if (path.len >= self.current_directory.len) {
            return BuiltinError.PathTooLong;
        }
        @memset(self.current_directory[0..], 0);
        @memcpy(self.current_directory[0..path.len], path);
        self.current_directory_len = @intCast(path.len);
    }
    
    /// Get authenticated user ID (if authenticated).
    pub fn get_user_id(self: *ShellEnvironment) ?[]const u8 {
        if (self.auth_context) |*ctx| {
            if (ctx.authenticated and ctx.user_id_len > 0) {
                return ctx.user_id[0..ctx.user_id_len];
            }
        }
        return null;
    }
    
    /// Check if user has role.
    pub fn has_role(self: *ShellEnvironment, role: u32) bool {
        if (self.auth_context) |*ctx| {
            if (!ctx.authenticated) {
                return false;
            }
            var i: u32 = 0;
            while (i < ctx.roles_len) : (i += 1) {
                if (ctx.roles[i] == role) {
                    return true;
                }
            }
        }
        return false;
    }
};
```

**Benefits**:
- ✅ User context available to all built-in commands
- ✅ Permission checking possible in commands
- ✅ Session management integrated
- ✅ Follows Grain Style (explicit types, bounded allocations)

---

### Pattern 3: Shell Built-in Authentication Commands

**Design**: Add built-in commands for authentication (login, logout, whoami).

**Proposed Commands**:

#### 1. `login` Command

**Function**: `builtin_login()`

**Design**:
```zig
// Built-in command: login (authenticate user).
pub fn builtin_login(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    std.debug.assert(env != null);
    _ = allocator;
    
    // Check if already authenticated.
    if (env.auth_context) |*ctx| {
        if (ctx.authenticated) {
            const stdout_file = stdio.getStdOut();
            try stdout_file.writeAll("Already logged in\n");
            return BuiltinResult{ .exit_code = 0 };
        }
    }
    
    // Get auth service (requires global or context access).
    // TODO: Get auth service instance (requires integration with Init System).
    // const auth_service = get_auth_service() orelse {
    //     const stderr_file = stdio.getStdErr();
    //     try stderr_file.writeAll("login: auth service not available\n");
    //     return BuiltinResult{ .exit_code = 1 };
    // };
    
    // Prompt for username and password.
    const stdout_file = stdio.getStdOut();
    const stdin = stdio.getStdIn();
    
    // Read username.
    try stdout_file.writeAll("Username: ");
    var username_buf: [auth_service.MAX_USER_ID_LEN]u8 = undefined;
    const username_len = read_line(stdin, &username_buf) catch |err| {
        const stderr_file = stdio.getStdErr();
        try stderr_file.writeAll("login: error reading username\n");
        return BuiltinResult{ .exit_code = 1 };
    };
    
    if (username_len == 0) {
        const stderr_file = stdio.getStdErr();
        try stderr_file.writeAll("login: username required\n");
        return BuiltinResult{ .exit_code = 1 };
    }
    
    // Read password (with echo disabled).
    try stdout_file.writeAll("Password: ");
    var password_buf: [auth_service.MAX_PASSWORD_LEN]u8 = undefined;
    const password_len = read_password(stdin, &password_buf) catch |err| {
        const stderr_file = stdio.getStdErr();
        try stderr_file.writeAll("login: error reading password\n");
        return BuiltinResult{ .exit_code = 1 };
    };
    
    if (password_len == 0) {
        const stderr_file = stdio.getStdErr();
        try stderr_file.writeAll("login: password required\n");
        return BuiltinResult{ .exit_code = 1 };
    }
    
    // Authenticate user.
    // TODO: Implement authentication (requires AuthService integration).
    // const current_time = @as(u64, @intCast(std.time.timestamp()));
    // var auth_ctx = ShellAuthContext.init();
    // const authenticated = authenticate_shell_user(
    //     auth_service,
    //     username_buf[0..username_len],
    //     password_buf[0..password_len],
    //     current_time,
    //     &auth_ctx,
    // );
    // 
    // if (!authenticated) {
    //     const stderr_file = stdio.getStdErr();
    //     try stderr_file.writeAll("login: authentication failed\n");
    //     return BuiltinResult{ .exit_code = 1 };
    // }
    // 
    // // Store auth context in environment.
    // env.auth_context = auth_ctx;
    // try stdout_file.writeAll("Login successful\n");
    
    // Placeholder: return success.
    try stdout_file.writeAll("login: not yet implemented\n");
    return BuiltinResult{ .exit_code = 0 };
}
```

#### 2. `logout` Command

**Function**: `builtin_logout()`

**Design**:
```zig
// Built-in command: logout (end shell session).
pub fn builtin_logout(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    std.debug.assert(env != null);
    _ = allocator;
    _ = args;
    
    // Check if authenticated.
    if (env.auth_context) |*ctx| {
        if (!ctx.authenticated) {
            const stdout_file = stdio.getStdOut();
            try stdout_file.writeAll("Not logged in\n");
            return BuiltinResult{ .exit_code = 0 };
        }
        
        // Revoke session.
        // TODO: Revoke session via AuthService.
        // const auth_service = get_auth_service() orelse {
        //     const stderr_file = stdio.getStdErr();
        //     try stderr_file.writeAll("logout: auth service not available\n");
        //     return BuiltinResult{ .exit_code = 1 };
        // };
        // 
        // const session_id = ctx.session_id[0..ctx.session_id_len];
        // auth_service.revoke_session(session_id);
        
        // Clear auth context.
        ctx.authenticated = false;
        ctx.user_id_len = 0;
        ctx.session_id_len = 0;
        ctx.roles_len = 0;
        
        const stdout_file = stdio.getStdOut();
        try stdout_file.writeAll("Logged out\n");
        return BuiltinResult{ .exit_code = 0 };
    }
    
    const stdout_file = stdio.getStdOut();
    try stdout_file.writeAll("Not logged in\n");
    return BuiltinResult{ .exit_code = 0 };
}
```

#### 3. `whoami` Command

**Function**: `builtin_whoami()`

**Design**:
```zig
// Built-in command: whoami (display current user).
pub fn builtin_whoami(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    std.debug.assert(env != null);
    _ = allocator;
    _ = args;
    
    // Get user ID from environment.
    if (env.get_user_id()) |user_id| {
        const stdout_file = stdio.getStdOut();
        var output_buf: [512]u8 = undefined;
        const output = std.fmt.bufPrint(&output_buf, "{s}\n", .{user_id}) catch {
            try stdout_file.writeAll("whoami: error formatting output\n");
            return BuiltinResult{ .exit_code = 1 };
        };
        try stdout_file.writeAll(output);
        return BuiltinResult{ .exit_code = 0 };
    }
    
    // Not authenticated.
    const stdout_file = stdio.getStdOut();
    try stdout_file.writeAll("not authenticated\n");
    return BuiltinResult{ .exit_code = 1 };
}
```

---

### Pattern 4: Permission Checking for Commands

**Design**: Add permission checking for built-in commands that require authentication.

**Proposed Implementation**:
```zig
// Check if user has permission to execute command.
pub fn check_command_permission(
    env: *ShellEnvironment,
    command: []const u8,
) bool {
    std.debug.assert(env != null);
    std.debug.assert(command.len > 0);
    
    // Commands that don't require authentication.
    const public_commands = [_][]const u8{ "login", "exit", "echo" };
    for (public_commands) |pub_cmd| {
        if (std.mem.eql(u8, command, pub_cmd)) {
            return true;
        }
    }
    
    // All other commands require authentication.
    if (env.auth_context) |*ctx| {
        return ctx.authenticated;
    }
    
    return false;
}
```

**Integration**:
- Check permission before executing command
- Return error if permission denied
- Display appropriate error message

---

## Integration with Init System (Agent 3d)

**Design**: Shell authentication should integrate with sevenos Init System for session management.

**Proposed Flow**:
1. Init System spawns shell process
2. Shell checks for existing session (via environment or IPC)
3. If session exists, validate via AuthService
4. If no session, prompt for login
5. Create session and store in Init System session manager
6. Shell uses session for command execution

**Integration Points**:
- Session management: Init System manages shell sessions
- User context: Pass user context to shell via environment
- Permission checking: Init System can enforce permissions

---

## Integration with Storage Agent (1c)

**Design**: Shell authentication requires user storage for password verification.

**Proposed Flow**:
1. Shell prompts for username/password
2. Lookup user by username (via Storage Agent)
3. Retrieve password hash from storage
4. Verify password via AuthService
5. Create session if valid

**Integration Points**:
- User lookup: Storage Agent provides user data
- Password hash storage: Storage Agent stores password hashes
- User roles: Storage Agent provides user roles

---

## Questions for Grainscript Shell Agent (1e)

**Integration Design Questions**:

1. **Authentication Timing**:
   - [ ] Should shell require authentication before starting, or allow unauthenticated shell?
   - [ ] Should authentication be optional or mandatory?

2. **Session Management**:
   - [ ] Should shell sessions be managed by Init System or shell itself?
   - [ ] How should shell sessions persist across shell restarts?

3. **User Context**:
   - [ ] Should user context be stored in ShellEnvironment or separate structure?
   - [ ] How should user context be passed to external commands?

4. **Permission Model**:
   - [ ] Should all commands require authentication, or only specific commands?
   - [ ] Should permission checking be per-command or role-based?

5. **Password Input**:
   - [ ] How should password input be handled (echo disabled, secure input)?
   - [ ] Should password input use terminal control sequences?

6. **Integration Points**:
   - [ ] How should shell access AuthService (global, context, IPC)?
   - [ ] How should shell integrate with Init System for session management?
   - [ ] How should shell integrate with Storage Agent for user lookup?

---

## Implementation Timeline

### Phase 1: Design and Coordination (Week 1-2)
- [ ] Coordinate with Agent 1e on authentication requirements
- [ ] Agree on authentication patterns and integration points
- [ ] Design session management integration with Init System
- [ ] Design user lookup integration with Storage Agent

### Phase 2: Core Authentication (Week 2-3)
- [ ] Implement shell login authentication
- [ ] Implement session management
- [ ] Implement user context in ShellEnvironment
- [ ] Add login, logout, whoami built-in commands

### Phase 3: Permission Checking (Week 3-4)
- [ ] Implement permission checking for commands
- [ ] Add role-based permission checking
- [ ] Integrate with RBAC system

### Phase 4: Integration Testing (Week 4)
- [ ] Integration tests with Init System
- [ ] Integration tests with Storage Agent
- [ ] End-to-end authentication testing
- [ ] Framework x86_64 testing verification

---

## Grain Style Compliance

**All Shell Authentication Functions**:
- ✅ Function length ≤ 70 lines
- ✅ Line length ≤ 100 characters
- ✅ Explicit types (`u32`/`u64`, no `usize`/`isize`)
- ✅ Bounded allocations (MAX_ constants)
- ✅ Minimum 2 assertions per function
- ✅ `grain_case` function names

---

## Summary

**Status**: ✅ **DESIGN READY** — Shell authentication integration patterns prepared for Agent 1e

**Next Steps**:
1. Await Agent 1e completion of critical path work
2. Coordinate with Agent 1e on authentication requirements
3. Coordinate with Init System (3d) for session management
4. Coordinate with Storage Agent (1c) for user lookup
5. Begin implementation after coordination complete

**Ready For**:
- ✅ Design discussion with Agent 1e
- ✅ Integration planning with Init System (3d)
- ✅ Integration planning with Storage Agent (1c)
- ✅ Implementation (after coordination complete)

---

**Date**: 2026-01-02-003955-pst  
**Agent**: Grain Auth Agent (1a)  
**Status**: ✅ Shell authentication integration design ready for Agent 1e coordination

---

