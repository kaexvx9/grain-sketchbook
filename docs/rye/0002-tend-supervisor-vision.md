# Tend: The Rye Supervisor Vision

**Date**: 2025-01-18  
**Status**: Vision Document  
**Relationship**: Core philosophy for Rye resource management  

## The Word

**Tend** - one syllable, from Old English *tendan*:

1. To care for with attention and presence
2. To watch over, to attend to
3. To incline toward a particular state
4. To offer, to extend

## Philosophy

Traditional systems programming treats resources as objects to be **acquired** and **released**. This transactional framing leads to:

- Reference counting (who holds the last pointer?)
- Garbage collection (automated violence against forgotten objects)
- Use-after-free (abandonment trauma)
- Memory leaks (resources left to decay)

Rye's Tend philosophy reframes resource management as **stewardship**:

| Transactional | Tend |
|---------------|------|
| Allocate/Free | Receive/Release |
| Own/Disown | Tend/Entrust |
| Reference count | Explicit custody |
| Garbage collect | Graceful completion |
| Leak | Unattended (compiler error) |

## Core Principles

### 1. Finite Capacity, Conscious Acceptance

Every tender has bounded capacity:

```rye
const MAX_PROCESSES: u32 = 16;
processes: [MAX_PROCESSES]Process,
```

This is not a limitation to work around. It is **acceptance of finitude** - the acknowledgment that attention is scarce and must be allocated deliberately.

### 2. Explicit Presence

Every tended resource declares its existence:

```rye
pub const Process = struct {
    allocated: bool,  // Am I present?
    // ...
};
```

There is no ambiguity about what exists. The tender knows exactly what is in their care at all times. This mirrors **sati** (mindfulness) - continuous awareness of what is.

### 3. Declared Purpose

Every public act of tending states its intention:

```rye
/// Why: Track process execution order and state management.
pub fn find_next_runnable(self: *Scheduler, procs: []const Process, max: u32) u64
```

No action proceeds without **sankalpa** (intention-setting). The `/// Why:` comment is not documentation - it is a vow.

### 4. Transparent Cost

Every operation's cost is visible at the call site:

```rye
// No hidden allocations
// No hidden reference counting
// No hidden background threads
const id = self.create_socket(owner);  // O(n) scan of bounded table
```

This is **satya** (truthfulness) in code - the system cannot deceive about what it does.

### 5. Graceful Release

Resources complete their purpose and are released cleanly:

```rye
pub fn close_socket(self: *TcpSocketManager, id: u64) bool {
    const sock = self.get_socket(id) orelse return false;
    sock.state = .closed;
    sock.allocated = false;  // Graceful release
    return true;
}
```

There is no violence in this ending - no dangling pointers wondering where their referent went. The resource completes and the slot becomes available for new purpose.

### 6. Non-Harm Through Constraint

The 64-line function limit, 128-character line limit, and mandatory assertions are **vows of ahimsa** (non-violence):

- Functions too long to understand can hide harm
- Lines too long to see can hide complexity
- Unchecked assumptions can cause undefined behavior

By constraining expression, Rye prevents the gestures that lead to violence.

## The Tender Pattern

A **Tender** is a manager of bounded resources with explicit lifecycle:

```rye
pub const ProcessTender = struct {
    entries: [MAX]Process,
    initialized: bool,

    /// Why: Set up tender state.
    pub fn init() ProcessTender { ... }

    /// Why: Receive a new process into care.
    pub fn receive(self: *ProcessTender, ...) ?u64 { ... }

    /// Why: Find a process by identity.
    pub fn find(self: *ProcessTender, id: u64) ?*Process { ... }

    /// Why: Release a process that has completed.
    pub fn release(self: *ProcessTender, id: u64) bool { ... }

    /// Why: Enumerate all processes in care.
    pub fn enumerate(self: *ProcessTender, ids: []u64) u32 { ... }
};
```

The naming reflects the philosophy:
- `receive` not `create` - we don't create from nothing; we receive into care
- `release` not `destroy` - we don't destroy; we release back to availability
- `find` not `get` - we seek what we tend, with awareness it may not be present
- `enumerate` not `list` - we account for all in our care

## Application to Existing Modules

The Basin kernel already embodies Tend philosophy. The 49 production Rye modules (7,080 lines) demonstrate:

| Module | Tend Pattern |
|--------|--------------|
| `scheduler.ry` | Tends process execution order |
| `memory.ry` | Tends page allocation |
| `tcp_socket.ry` | Tends network connections |
| `audio.ry` | Tends audio devices |
| `storage.ry` | Tends files and directories |
| `channel.ry` | Tends IPC message passing |
| `process_group.ry` | Tends process group membership |

## For Spiritual Practitioners

### Mystics

The kernel is a **mandala** - a bounded universe you can hold in mind. Unlike Linux's 30+ million lines, Basin's ~15,000 lines invite contemplation. Every syscall is a ritual with declared purpose. Every resource has explicit custody.

The `/// Why:` comments form a **sutra** - a thread of intentions running through the codebase. Reading them in sequence reveals the kernel's dharma (purpose).

### Ahimsa Protectors

Traditional systems programming accepts:
- Buffer overflows (violence to memory)
- Race conditions (violence through confusion)  
- Undefined behavior (violence through unpredictability)
- Resource leaks (violence through abandonment)

Tend's constraints are **vows**:
- Bounded tables → no overflow possible
- Single-threaded design → no races
- Explicit assertions → no undefined assumptions
- `allocated: bool` → no abandoned resources

The kernel cannot accidentally harm because the language **prevents the gestures of harm**.

## Relationship to Rye

Tend is not a separate module - it is the **soul** of RyeStyle. The compiler enforces:

1. **Line limits** → Functions small enough to tend consciously
2. **Why comments** → Every public action declares intention
3. **Static allocation** → Finite capacity, explicit presence

Future Rye versions may add:
- `tender` keyword for manager structs
- Built-in `receive`/`release` lifecycle
- Compile-time verification of bounded capacity
- Static analysis for "unattended" resources

## See Also

- `docs/rye/0001-rye-language-vision.md` - Rye language overview
- `docs/rye_style.md` - RyeStyle constraints
- `src/kernel/*.ry` - 49 production modules demonstrating Tend
