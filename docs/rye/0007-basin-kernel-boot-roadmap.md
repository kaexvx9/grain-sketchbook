# Basin Kernel Boot Roadmap: From Toroidal UI to Running Shell

**Date**: 2026-01-20
**Status**: Planning
**Builds On**: 0005-toroidal-dag-ui-architecture.md (Phase 4 Complete)

---

## Overview

With the toroidal DAG UI architecture complete (Phases 1-4), the next goal is getting the Basin kernel to boot on Framework x86_64 with a working Grainscript shell.

---

## Current State

### Completed (Phases 1-4)

| Phase | Components | Lines |
|-------|------------|-------|
| 1. Core Types | toroidal.ry | 177 |
| 2. DAG Core | dag_toroidal.ry, dag_toroidal_adapter.ry | 559 |
| 3. UI Integration | realidream_toroidal_integration.ry | 284 |
| 4. Kernel Integration | basin_kernel_syscalls_ui.ry, grainscript_ui_bindings.ry, ui_event_loop.ry | 1,158 |

**Total**: 67 Rye modules, 16,305 lines, **333/333 tests passing**

### Blocking Issues (RESOLVED)

~~9 kernel integration tests fail with signal 11/6 (stack overflow)~~
- **Fixed**: Added `init_in_place()` for heap allocation
- **Fixed**: Corrected syscall routing for process syscalls (1-4)
- **Fixed**: All array bounds and memory leak issues resolved

---

## Phase 5: Kernel Boot Path

### 5.1 Fix Kernel Test Infrastructure

**Problem**: `BasinKernel.init()` creates a massive struct on the stack.

**Solution Options**:

1. **Heap allocation in tests** (Short-term)
   - Use `std.heap.page_allocator` to allocate kernel
   - Requires adding `deinit()` for cleanup

2. **Lazy initialization** (Medium-term)
   - Initialize subsystems on-demand
   - Reduce initial memory footprint

3. **Static kernel singleton** (Long-term)
   - Single global kernel instance
   - Matches freestanding deployment model

### 5.2 Wire Event Loop to Kernel (COMPLETE)

Connected `ui_event_loop.ry` to `basin_kernel.ry`:
- Added `ui_loop: UiEventLoop` field to `BasinKernel`
- Added `tick()` method for main kernel loop
- Added `queue_input_event()` for input routing
- Added `get_ui_stats()` and `get_ui_loop()` for access

Previous implementation plan (now complete):

```rye
/// In basin_kernel.ry
const ui_event_loop = @import("ui_event_loop.zig");

pub const BasinKernel = struct {
    // ... existing fields ...
    ui_loop: ui_event_loop.EventLoop,
    
    pub fn init() BasinKernel {
        return BasinKernel{
            // ...
            .ui_loop = ui_event_loop.EventLoop.init(),
        };
    }
    
    /// Why: Main kernel loop with UI event processing.
    pub fn run(self: *BasinKernel) noreturn {
        self.ui_loop.start();
        while (true) {
            // 1. Process hardware interrupts
            self.interrupt_controller.process_pending();
            
            // 2. Run scheduler
            self.scheduler.tick();
            
            // 3. Process UI events
            const current_ns = self.timer.read_ns();
            _ = self.ui_loop.tick(current_ns);
            
            // 4. Yield to next process
            self.scheduler.yield();
        }
    }
};
```

### 5.3 Connect Grainscript to UI (COMPLETE)

Created `ui_builtins.zig` with 9 UI functions:
- `ui_create_window()`, `ui_add_label()`, `ui_add_button()`
- `ui_add_input()`, `ui_add_list()`, `ui_set_text()`, `ui_get_text()`
- `ui_poll_event()`, `ui_available()`

Made `Interpreter.add_builtin()` public and auto-register UI builtins.

Previous implementation plan (now complete):

```rye
// In grainscript/interpreter.ry
const ui = @import("grainscript_ui_bindings.zig");

/// Why: Built-in UI functions for Grainscript.
pub const UiBuiltins = struct {
    app: ui.UiApp,
    
    /// gs: window = ui.create_window()
    pub fn create_window(self: *UiBuiltins) ?u32 {
        const handle = self.app.create_window() orelse return null;
        return handle.raw();
    }
    
    /// gs: label = ui.add_label(window, "Hello")
    pub fn add_label(self: *UiBuiltins, parent: u32, text: []const u8) ?u32 {
        const parent_handle = ui.UiHandle.from_raw(parent, .container);
        const handle = self.app.add_label(parent_handle, text) orelse return null;
        return handle.raw();
    }
    
    /// gs: ui.on_click(button, handler)
    pub fn on_click(self: *UiBuiltins, target: u32, callback: ui.EventCallback) bool {
        const handle = ui.UiHandle.from_raw(target, .button);
        return self.app.on_click(handle, callback, null);
    }
};
```

### 5.4 Grainscript Shell UI (COMPLETE)

Created `examples/shell.gs` - a basic shell UI demonstrating:
- Window creation with ui_create_window()
- Output list with ui_add_list()
- Input field with ui_add_input()
- Event polling with ui_poll_event()
- Command processing (help, clear, exit, echo)
- Expression evaluation with eval()

Example shell UI code:

```grainscript
// shell.gr - Grainscript shell with UI

let window = ui.create_window()
let output = ui.add_list(window)
let input = ui.add_input(window, "grainscript> ")

ui.on_text_change(input, fn(event) {
    if event.key == "Enter" {
        let line = ui.get_text(input)
        let result = eval(line)
        ui.add_label(output, result)
        ui.set_text(input, "")
    }
})

ui.run()
```

---

## Phase 6: Framework x86_64 Target

### 6.1 Vantage VM for x86_64 (COMPLETE)

Created `src/kernel_vm/x86_64.zig` with:

- [x] x86_64 instruction encoding (Prefix, Opcode structs)
- [x] x86_64 register mapping (Register enum, RegisterFile struct)
- [x] x86_64 calling convention (CallingConvention struct)
- [x] x86_64 syscall interface (Syscall enum, syscall_regs)
- [x] ModRM/SIB/REX encoding helpers
- [x] RFLAGS bit definitions
- [x] Unit tests for all components

### 6.2 Bootloader

- [ ] UEFI or BIOS boot
- [ ] Load kernel ELF
- [ ] Set up page tables
- [ ] Jump to kernel entry

### 6.3 Hardware Drivers

For Framework laptop:

- [ ] UART/serial console
- [ ] PS/2 keyboard (or USB HID)
- [ ] Framebuffer graphics
- [ ] Basic timer

---

## Implementation Order

1. **Fix test infrastructure** - ✅ COMPLETE (333/333 tests passing)
2. **Wire event loop** - ✅ COMPLETE (BasinKernel.tick() with UI)
3. **Add UI builtins** - ✅ COMPLETE (9 UI functions in Grainscript)
4. **Create shell UI** - ✅ COMPLETE (examples/shell.gs)
5. **Vantage x86_64** - ✅ COMPLETE (x86_64.zig with registers, opcodes, syscalls)
6. **Boot on Framework** - Create bootloader and hardware drivers

---

## Success Criteria

- [x] All kernel integration tests pass (333/333)
- [x] Grainscript shell runs with UI (examples/shell.gs)
- [ ] Basin kernel boots on Framework x86_64
- [ ] Interactive REPL on real hardware

---

## Summary

The toroidal DAG UI architecture is complete. The path forward is:

1. Fix kernel test infrastructure (stack overflow)
2. Integrate event loop into kernel main loop
3. Expose UI API to Grainscript
4. Port Vantage VM to x86_64
5. Boot on Framework hardware

The architecture is sound. The remaining work is integration and porting.
