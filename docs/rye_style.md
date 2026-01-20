# RyeStyle

> "There are three things extremely hard: steel, a diamond, and to know one's self." — Benjamin
> Franklin

Rye's coding style is the evolution of GrainStyle for our native systems language. A collective
give-and-take at the intersection of engineering and art. Numbers and human intuition. Reason and
experience. First principles and knowledge. Precision and poetry. Just like music. A tight beat. A
rare groove. Words that rhyme and rhymes that break. Biodigital jazz. This is what we've learned
along the way. The best is yet to come.

**Attribution**: This guide stands on the shoulders of giants. See
[THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md) for full license attributions, particularly
TigerBeetle's TIGER_STYLE.md (Apache 2.0) and Rich Hickey's Clojure philosophy (EPL 1.0).

## Why Rye?

We created Rye because we need complete control over our systems language:

- **Freestanding first**: RISC-V64 freestanding is our primary target, not an afterthought. Every
  codegen path is tested against bare metal.
- **Compiler-enforced style**: 64-line function limits, 128-character lines, mandatory "why"
  comments—enforced by the compiler, not by lint. See [exceptions](ryestyle-exceptions.md).
- **No surprises**: Global variable addresses are correct. Conditionals work. Inline assembly is
  reliable. We fix bugs in hours, not months.
- **Explicit over implicit**: No hidden control flow, no hidden memory allocations, no operator
  overloading. What you see is what executes.
- **Simple over easy**: Following Rich Hickey's distinction—Rye is simple (not intertwined) even
  when it's not easy (familiar).
- **Grain-native**: Rye is designed for Grain OS. The language and the OS evolve together.

Rye inherits from Zig's excellent design while fixing the issues we encountered building the Basin
kernel. See `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md` for the bugs that motivated
Rye's creation.

## Rye vs Zig

Rye is not a replacement for Zig. It's a dialect optimized for our use case:

| Aspect | Zig | Rye |
|--------|-----|-----|
| Primary target | Linux/Windows/macOS | RISC-V64 freestanding |
| Function length | No limit | 64 lines max (enforced) |
| Line length | No limit | 128 chars max (enforced) |
| Why comments | Convention | Required for pub fn |
| Inline asm | Works mostly | Works always |
| Community | Large, general | Small, Grain-focused |

**Phase 1 (Current)**: Rye transpiles to Zig. We get Zig's backend without its frontend issues.
**Phase 2 (Future)**: Rye compiles directly to RISC-V, x86_64, AArch64.

## Why Have Style?

Another word for style is design.

> "The design is not just what it looks like and feels like. The design is how it works." — Steve
> Jobs

Our design goals are safety, performance, and developer experience. In that order. All three are
important. Good style advances these goals. Does the code make for more or less safety, performance
or developer experience? That is why we need style.

## The Path with Heart

Before we begin, there is a question that only experience can answer: **Does this path have heart?**

Any approach to coding is one of a million paths. Therefore you must always keep in mind that a
path is only a path; if you feel you should not follow it, you must not stay with it under any
conditions.

**Does this path have heart?** If it does, the path is good; if it doesn't, it is of no use. Both
paths lead nowhere; but one has a heart, the other doesn't. One makes for a joyful journey; as long
as you follow it, you are one with it. The other will make you curse your life.

For Rye, we choose the path with heart.

## On Simplicity And Elegance

Simplicity is not a free pass. It's not in conflict with our design goals.

Rather, simplicity is how we bring our design goals together, how we identify the "super idea" that
solves the axes simultaneously, to achieve something elegant.

> "Simplicity and elegance are unpopular because they require hard work and discipline to achieve" —
> Edsger Dijkstra

## Technical Debt

Rye has a "zero technical debt" policy. We do it right the first time. This is important because
the second time may not transpire, and because doing good work, that we can be proud of, builds
momentum.

> "You shall not pass!" — Gandalf

We know that what we ship is solid. We may lack crucial features, but what we have meets our design
goals.

## Safety

> "The rules act like the seat-belt in your car: initially they are perhaps a little uncomfortable,
> but after a while their use becomes second-nature and not using them becomes unimaginable." —
> Gerard J. Holzmann

[NASA's Power of Ten — Rules for Developing Safety Critical
Code](https://spinroot.com/gerard/pdf/P10.pdf) will change the way you code forever. To expand:

- Use **only very simple, explicit control flow** for clarity. **Do not use recursion** to ensure
  that all executions that should be bounded are bounded.

- **Put a limit on everything** because, in reality, this is what we expect—everything has a limit.
  All loops and all queues must have a fixed upper bound.

- Use explicitly-sized types like `u32` for everything, avoid architecture-specific `usize`.

- **Assertions detect programmer errors.** The assertion density of the code must average a minimum
  of two assertions per function.

- All memory must be statically allocated at startup. **No memory may be dynamically allocated (or
  freed and reallocated) after initialization.**

- Declare variables at the **smallest possible scope**.

- Restrict the length of function bodies. We enforce a **hard limit of 64 lines per function**
  (2^6, binary-aligned). This is enforced by the Rye compiler.

- All errors must be handled.

- **Always motivate, always say why. Never forget to say why.** For public functions, Rye requires
  a `/// Why:` doc comment. This is enforced by the compiler.

## Rye-Specific Rules

### Function Length (Compiler-Enforced)

```rye
/// Kernel entry point.
/// Why: Called by bootloader after hardware init.
pub fn kmain() noreturn {
    // Maximum 64 lines in this function body.
    // The Rye compiler will reject functions longer than 64 lines.
    print_banner();
    repl_run();
    halt();
}
```

If your function exceeds 64 lines, the compiler emits:

```
error: function 'kmain' exceeds 64-line limit (has 72 lines)
 --> src/kernel/main.ry:10:1
  |
  = help: split into smaller functions
```

### Line Length (Compiler-Enforced)

All lines must be at most 128 characters. The compiler enforces this:

```
error: line exceeds 128-character limit (has 145 characters)
 --> src/kernel/uart.ry:25:1
  |
  = help: wrap the line or use shorter names
```

### Why Comments (Compiler-Enforced)

All public functions must have a `/// Why:` doc comment:

```rye
/// Initialize UART.
/// Why: Required for early boot console output before interrupts are enabled.
pub fn uart_init() void {
    // ...
}
```

Missing why comment:

```
error: public function 'uart_init' missing '/// Why:' documentation
 --> src/kernel/uart.ry:10:1
  |
  = help: add a '/// Why:' comment explaining the function's purpose
```

### Inline Assembly

Rye's inline assembly is designed to work reliably on freestanding targets:

```rye
/// Write a byte to UART.
/// Why: Direct hardware access for early boot output.
pub fn uart_putc(c: u8) void {
    asm volatile {
        lui t1, 0x10000
        sb {c}, 0(t1)
    } : : [c] "r" (c);
}
```

The assembler guarantees:
- Register constraints are honored
- No spurious clobbers
- Correct addressing for all memory models

## Performance

> "The lack of back-of-the-envelope performance sketches is the root of all evil." — Rivacindela
> Hudsoni

- Think about performance from the outset, from the beginning.
- Perform back-of-the-envelope sketches with respect to the four resources (network, disk, memory,
  CPU) and their two main characteristics (bandwidth, latency).
- Optimize for the slowest resources first (network, disk, memory, CPU) in that order.
- Amortize costs by batching accesses.
- Be explicit. Minimize dependence on the compiler to do the right thing for you.

## Developer Experience

### Naming Things

- **Get the nouns and verbs just right.**
- **Use `rye_case` for function, variable, and file names.** rye_case is identical to snake_case.
- Do not abbreviate variable names.
- Add units or qualifiers to variable names, put them last: `latency_ms_max` not `max_latency_ms`.
- **Write descriptive commit messages.**
- Don't forget to say why.

### Style By The Numbers

- Run `rye fmt`.
- Use 4 spaces of indentation.
- **Hard limit all line lengths to at most 128 columns** (2^7, binary-aligned).
- **Hard limit all function bodies to at most 64 lines** (2^6, binary-aligned).

## Graincard Constraints

Graincards are 128×64 monospace teaching cards. All Rye code should fit within these constraints:

- **Total size**: 128 characters wide × 64 lines tall
- **Rye code lines**: max 128 characters per line
- **Rye functions**: max 64 lines

## Dependencies

Rye has **a "zero dependencies" policy**, apart from the Rye toolchain. Dependencies inevitably
lead to supply chain attacks, safety and performance risk, and slow install times.

## Tooling

Our primary tool is Rye. It may not be the best for everything, but it's good enough for most
things. For scripts, write `scripts/*.ry` instead of `scripts/*.sh`.

## When to Break the Rules

These guidelines are principles, not laws. Sometimes you need to break them. When you do, document
why with a `// EXCEPTION:` comment.

```rye
// EXCEPTION: This function is 68 lines because splitting it would obscure the state machine.
// See issue #456 for discussion.
#[allow(long_function)]
fn complex_state_machine() void {
    // ...
}
```

## File Extension

Rye source files use the `.ry` extension:

```
src/
  kernel/
    main.ry
    uart.ry
    repl.ry
```

## The Last Stage

At the end of the day, keep trying things out, have fun, and remember—Rye is hardy grain that grows
in harsh conditions. Our kernel runs on bare metal. Our compiler enforces our style. Our path has
heart.

---

**now == next + 1** 🌾⚒️

---

## Attribution

This document is adapted from [GrainStyle](grain_style.md), which is heavily inspired by
[TigerBeetle's TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md).
We stand on the shoulders of giants.
