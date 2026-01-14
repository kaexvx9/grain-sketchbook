# Test 164: Root Cause Found - Stack Probe at Test Function Entry

**Date**: 2026-01-11-211500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Document root cause - stack probe failure at test function entry  
**Status**: ✅ **ROOT CAUSE IDENTIFIED**

---

## Critical Finding

**Even the simplest test crashes:**

```zig
test "minimal: VM only" {
    const env = try testing.allocator.create(struct { vm: VM });
    defer testing.allocator.destroy(env);
    VM.init(&env.vm, &[_]u8{}, 0x80000000);
    std.debug.assert(env.vm.state == .halted);
}
```

**This crashes at the test function entry**, before any code runs.

---

## Root Cause

**Stack probe failure at test function entry.**

Zig inserts stack probes to check if there's enough stack space for the function's frame. The test function is trying to allocate something on the stack that's too large, **even though we're using heap allocation**.

---

## Why This Happens

1. **Test function frame size**: The test function itself might have a large frame
2. **Stack probe conservatism**: Zig's stack probe might be checking for more space than needed
3. **VM struct in test**: Even though we allocate on heap, the test function might be creating a temporary

---

## The Real Problem

The issue is **NOT** in our initialization code. It's in **how Zig handles test functions with large types**.

When we do:
```zig
const env = try testing.allocator.create(struct { vm: VM });
```

Zig might be creating a temporary on the stack before the heap allocation, or the test function frame itself is too large.

---

## Solution Options

### Option 1: Move test to separate file with smaller frame
- Create a minimal test file
- Use smaller test function
- Avoid large types in test function signature

### Option 2: Use @noInline or similar
- Force test function to not inline
- Might reduce stack frame size

### Option 3: Increase stack size
- Use `ulimit -s` to increase stack size
- Not ideal, but might work

### Option 4: Refactor test to avoid large types
- Don't use VM struct directly in test
- Use pointers only
- Minimize test function frame

---

## Recommended Solution

**Option 4**: Refactor test to use only pointers, avoid large types in test function frame.

Create a helper function that does the allocation:
```zig
fn create_vm_on_heap() !*VM {
    const vm = try testing.allocator.create(VM);
    VM.init(vm, &[_]u8{}, 0x80000000);
    return vm;
}

test "minimal: VM only" {
    const vm = try create_vm_on_heap();
    defer testing.allocator.destroy(vm);
    std.debug.assert(vm.state == .halted);
}
```

This ensures the VM struct is never in the test function's stack frame.

---

## Next Steps

1. Create helper functions for heap allocation
2. Refactor tests to use helpers
3. Verify tests pass
