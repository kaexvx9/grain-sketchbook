# Shell Service Configuration Template

**Date**: 2026-01-03-075315-pst  
**Agent**: Grain sevenos Init System Agent (3d)  
**Target**: Grain Grainscript Shell Agent (1e)  
**Purpose**: Service configuration template for Grainscript Shell service

---

## Service Configuration Template

### Example: Grainscript Shell Service

**File**: `/etc/sevenos/services.conf`

**Configuration Entry**:
```
grainscript_shell:/usr/bin/grainscript_shell:/home/user:always:
```

**Parsed Format** (ServiceConfig struct):
- **name**: `"grainscript_shell"`
- **command**: `["/usr/bin/grainscript_shell"]`
- **working_dir**: `"/home/user"` (optional, can be empty)
- **restart_policy**: `RestartPolicy.always`
- **dependencies**: `[]` (empty, no dependencies)

---

## Configuration Format Details

### Service Configuration Format

**Format**: `name:command:working_dir:restart_policy:dependencies`

**Fields**:
1. **name** (required): Service name (max 64 characters)
   - Must be unique
   - Alphanumeric and underscores only
   - Example: `grainscript_shell`

2. **command** (required): Command to execute (space-separated)
   - First element is executable path
   - Remaining elements are arguments
   - Max 512 characters total
   - Example: `/usr/bin/grainscript_shell` or `/usr/bin/grainscript_shell --interactive`

3. **working_dir** (optional): Working directory (max 256 characters)
   - Can be empty (uses current directory)
   - Absolute path recommended
   - Example: `/home/user` or empty

4. **restart_policy** (required): Restart policy
   - Options: `always`, `never`, `on_failure`, `on_success`
   - Default: `always`
   - Example: `always`

5. **dependencies** (optional): Comma-separated service names (max 16)
   - Can be empty (no dependencies)
   - Service names must exist
   - Example: `network,storage` or empty

---

## ServiceConfig Struct Reference

**Location**: `grainstore/sevenos/src/lib/supervision.zig`

```zig
pub const ServiceConfig = struct {
    name: []const u8,
    command: []const []const u8,
    working_dir: []const u8,
    restart_policy: RestartPolicy = .always,
    dependencies: []const []const u8,
    max_restarts: u32 = 10,
    restart_delay_ms: u32 = 1000,
    environment: ?[]const []const u8 = null,
    
    pub fn validate(self: *const ServiceConfig) !void;
};
```

**Fields**:
- **name**: Service name (required, max 64 chars)
- **command**: Command array (required, first element is executable)
- **working_dir**: Working directory (optional, can be empty)
- **restart_policy**: Restart policy (default: `.always`)
- **dependencies**: Dependency array (optional, can be empty)
- **max_restarts**: Maximum restart count (default: 10)
- **restart_delay_ms**: Restart delay in milliseconds (default: 1000)
- **environment**: Environment variables (optional, not yet implemented)

---

## Examples

### Example 1: Basic Shell Service

**Configuration**:
```
grainscript_shell:/usr/bin/grainscript_shell:/home/user:always:
```

**ServiceConfig**:
- name: `"grainscript_shell"`
- command: `["/usr/bin/grainscript_shell"]`
- working_dir: `"/home/user"`
- restart_policy: `RestartPolicy.always`
- dependencies: `[]`

---

### Example 2: Shell Service with Dependencies

**Configuration**:
```
grainscript_shell:/usr/bin/grainscript_shell:/home/user:always:network,storage
```

**ServiceConfig**:
- name: `"grainscript_shell"`
- command: `["/usr/bin/grainscript_shell"]`
- working_dir: `"/home/user"`
- restart_policy: `RestartPolicy.always`
- dependencies: `["network", "storage"]`

---

### Example 3: Shell Service with Arguments

**Configuration**:
```
grainscript_shell:/usr/bin/grainscript_shell --interactive:/home/user:always:
```

**ServiceConfig**:
- name: `"grainscript_shell"`
- command: `["/usr/bin/grainscript_shell", "--interactive"]`
- working_dir: `"/home/user"`
- restart_policy: `RestartPolicy.always`
- dependencies: `[]`

---

### Example 4: Shell Service (Minimal)

**Configuration**:
```
grainscript_shell:/usr/bin/grainscript_shell:::always:
```

**ServiceConfig**:
- name: `"grainscript_shell"`
- command: `["/usr/bin/grainscript_shell"]`
- working_dir: `""` (empty, uses current directory)
- restart_policy: `RestartPolicy.always`
- dependencies: `[]`

---

## Restart Policy Options

**RestartPolicy enum**:
- `always`: Always restart when service exits
- `never`: Never restart (one-shot services)
- `on_failure`: Restart only on failure (non-zero exit code)
- `on_success`: Restart only on success (zero exit code)

**Recommendation for Shell Service**: `always` (shell should always be available)

---

## Validation

**ServiceConfig.validate()** checks:
- Service name is non-empty (max 64 chars)
- Command is non-empty (first element is executable path)
- Working directory is valid path (if specified)
- Restart policy is valid
- Dependencies count is within limit (max 16)
- Service name is alphanumeric + underscores

**Usage**:
```zig
const config = ServiceConfig{ /* ... */ };
try config.validate();
```

---

## Integration Notes

**For Agent 1e (Shell)**:
- Use this template to create shell service configuration
- Service name: `grainscript_shell` (or your preferred name)
- Command: Path to your shell executable
- Working directory: Optional, can be empty
- Restart policy: `always` (recommended for interactive shell)
- Dependencies: Optional, add if shell depends on other services

**For Agent 3d (Init System)**:
- This template shows the expected format
- Shell service will be loaded and managed like any other service
- Shell service can be started/stopped/restarted via service management commands

---

**Last Updated**: 2026-01-03-075315-pst  
**Agent**: Grain sevenos Init System Agent (3d)  
**Status**: ✅ Service configuration template ready for shell integration

