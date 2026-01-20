# RyeStyle Exceptions

This document lists functions that are exempt from the 64-line function limit.

## Exempt Functions (2)

| Function | Lines | File | Reason |
|----------|-------|------|--------|
| `kmain` | 309 | main.zig | Inline assembly REPL workaround for Zig codegen issues |
| `handle_syscall` | 95 | basin_kernel.zig | Syscall dispatch switch statement (87 arms) |

## Rationale

These functions represent core kernel infrastructure that cannot be easily decomposed:

1. **kmain**: Uses extensive inline assembly to work around Zig's RISC-V freestanding codegen bugs. Refactoring would reintroduce the bugs.

2. **handle_syscall**: A large switch statement dispatching to 87 syscall handlers. The switch is the most readable form for this pattern. The validation and profiling logic has been extracted; only the dispatch table remains.

## Compliance

With these 2 exemptions:
- 58 files checked
- 2 functions exempt (documented above)
- 0 line length errors
- 0 missing Why errors
- **97%+ RyeStyle compliant**
