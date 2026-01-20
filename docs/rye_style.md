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

Put this way, style is more than readability, and readability is table stakes, a means to an end
rather than an end in itself.

> "...in programming, style is not something to pursue directly. Style is necessary only where
> understanding is missing." ─ [Let Over
> Lambda](https://letoverlambda.com/index.cl/guest/chap1.html)

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

Contrary to popular belief, simplicity is also not the first attempt but the hardest revision. It's
easy to say "let's do something simple", but to do that in practice takes thought, multiple passes,
many sketches, and still we may have to ["throw one
away"](https://en.wikipedia.org/wiki/The_Mythical_Man-Month).

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
  that all executions that should be bounded are bounded. Use **only a minimum of excellent
  abstractions** but only if they make the best sense of the domain.

- **Put a limit on everything** because, in reality, this is what we expect—everything has a limit.
  All loops and all queues must have a fixed upper bound. This follows the
  ["fail-fast"](https://en.wikipedia.org/wiki/Fail-fast) principle.

- Use explicitly-sized types like `u32` for everything, avoid architecture-specific `usize`.

- **Assertions detect programmer errors.** The assertion density of the code must average a minimum
  of two assertions per function.

  - **Assert all function arguments and return values, pre/postconditions and invariants.** A
    function must not operate blindly on data it has not checked.

  - **[Pair assertions](https://tigerbeetle.com/blog/2023-12-27-it-takes-two-to-contract).** For
    every property you want to enforce, try to find at least two different code paths where an
    assertion can be added.

  - Split compound assertions: prefer `assert(a); assert(b);` over `assert(a and b);`.

  - Use single-line `if` to assert an implication: `if (a) assert(b)`.

  - **Assert the relationships of compile-time constants** as a sanity check.

  - **The golden rule of assertions is to assert the _positive space_ that you do expect AND to
    assert the _negative space_ that you do not expect.**

- All memory must be statically allocated at startup. **No memory may be dynamically allocated (or
  freed and reallocated) after initialization.** This is the Garden Allocation philosophy.

- Declare variables at the **smallest possible scope**.

- Restrict the length of function bodies. We enforce a **hard limit of 64 lines per function**
  (2^6, binary-aligned). This is enforced by the Rye compiler.

- All errors must be handled. An [analysis of production failures](https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf) found that 92% of catastrophic failures were due to incorrect error handling.

- **Always motivate, always say why. Never forget to say why.** For public functions, Rye requires
  a `/// Why:` doc comment. This is enforced by the compiler.

Beyond these rules:

- Compound conditions that evaluate multiple booleans make it difficult for the reader to verify
  that all cases are handled. Split compound conditions into simple conditions using nested
  `if/else` branches.

- Negations are not easy! State invariants positively:

  ```rye
  if (index < length) {
      // The invariant holds.
  } else {
      // The invariant doesn't hold.
  }
  ```

- Whenever your program has to interact with external entities, **don't do things directly in
  reaction to external events**. Instead, your program should run at its own pace.

- **Explicitly pass options to library functions at the call site, instead of relying on defaults**.

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

Splitting code into functions requires taste. Some rules of thumb:

* Good function shape is often the inverse of an hourglass: a few parameters, a simple return
  type, and a lot of meaty logic between the braces.
* Centralize control flow. When splitting a large function, try to keep all switch/if
  statements in the "parent" function, and move non-branchy logic fragments to helper functions.
  ["Push `if`s up and `for`s down"](https://matklad.github.io/2023/11/15/push-ifs-up-and-fors-down.html).
* Similarly, centralize state manipulation. Let the parent function keep all relevant state in
  local variables, and use helpers to compute what needs to change. Keep leaf functions pure.

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

## Performance

> "The lack of back-of-the-envelope performance sketches is the root of all evil." — Rivacindela
> Hudsoni

- Think about performance from the outset, from the beginning. **The best time to solve performance
  is in the design phase.**
- Perform back-of-the-envelope sketches with respect to the four resources (network, disk, memory,
  CPU) and their two main characteristics (bandwidth, latency).
- Optimize for the slowest resources first (network, disk, memory, CPU) in that order.
- Distinguish between the control plane and data plane.
- Amortize costs by batching accesses.
- Let the CPU be a sprinter doing the 100m. Be predictable. Don't force the CPU to zig zag.
- Be explicit. Minimize dependence on the compiler to do the right thing for you.
- Extract hot loops into stand-alone functions with primitive arguments without `self`.

## Developer Experience

> "There are only two hard things in Computer Science: cache invalidation, naming things, and
> off-by-one errors." — Phil Karlton

### Naming Things

- **Get the nouns and verbs just right.** Great names are the essence of great code.
- **Use `rye_case` for function, variable, and file names.** rye_case is identical to snake_case.
- Do not abbreviate variable names.
- Use proper capitalization for acronyms (`VSRState`, not `VsrState`).
- Add units or qualifiers to variable names, put them last: `latency_ms_max` not `max_latency_ms`.
- Infuse names with meaning: `gpa: Allocator` and `arena: Allocator` are better than 
  `allocator: Allocator`.
- When choosing related names, try hard to find names with the same number of characters so that
  related variables all line up in the source.
- When a single function calls out to a helper function, prefix the helper name with the calling
  function name: `read_sector()` and `read_sector_callback()`.
- Callbacks go last in the list of parameters.
- _Order_ matters for readability. Put important things near the top. The `main` function goes first.
- **Write descriptive commit messages** that inform and delight the reader.
- Don't forget to say why. Code alone is not documentation.
- Don't forget to say how.
- Comments are sentences, with a space after the slash, with a capital letter and a full stop.

### Cache Invalidation

- Don't duplicate variables or take aliases to them.
- If you don't mean a function argument to be copied, pass as `*const`.
- Construct larger structs _in-place_ by passing an _out pointer_ during initialization.
- **Shrink the scope** to minimize the number of variables at play.
- Calculate or check variables close to where/when they are used. **Don't introduce variables before
  they are needed.**
- Use simpler function signatures and return types to reduce dimensionality.
- Ensure that functions run to completion without suspending.
- Be on your guard for **[buffer bleeds](https://en.wikipedia.org/wiki/Heartbleed)**.
- Use newlines to **group resource allocation and deallocation**.

### Off-By-One Errors

- **The usual suspects for off-by-one errors are casual interactions between an `index`, a `count`
  or a `size`.** To go from an `index` to a `count` you need to add one. To go from a `count` to a
  `size` you need to multiply by the unit.

- Show your intent with respect to division. Use `@divExact()`, `@divFloor()` or `div_ceil()`.

### Style By The Numbers

- Run `rye fmt`.
- Use 4 spaces of indentation.
- **Hard limit all line lengths to at most 128 columns** (2^7, binary-aligned).
- **Hard limit all function bodies to at most 64 lines** (2^6, binary-aligned).
- Add braces to the `if` statement unless it fits on a single line.

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

## Accretion Over Breakage

Following Rich Hickey's insight from "Spec-ulation": **breaking changes are broken**.

We reject Semantic Versioning's premise that major version bumps make breakage acceptable. Instead:

| Don't | Do |
|-------|-----|
| Break a function | Create `foo2` or `new_ns.foo` |
| Remove a function | Create new namespace without it |
| Require more args | Create new function with new name |
| Provide less return | Create new function with new name |
| Bump major version | Give birth to a new name |

**Why?** Because "you might be screwed" is worse than "you are screwed." Major version bumps say
nothing about *what* broke. You might as well change the name entirely.

### Chronological Versioning

Rye uses **chronological versioning** instead of semantic versioning:

```
YYYYMMDD.HHMMSS.variant
20260120.0945.basin
```

This conveys:
- **When** it was released (absolute, not relative)
- **Causality** (later timestamps came after earlier ones)
- **No false promises** about compatibility

### The Tend Philosophy

Our "Tend" philosophy (see `docs/rye/0002-tend-supervisor-vision.md`) aligns perfectly:

- **Stewardship over ownership**: Tend to your users, don't abandon them
- **Garden allocation**: Plots grow, they don't shrink
- **Toroidal topology**: No edges means no breaking boundaries
- **Names are precious**: One-syllable names are rare—make them endure

### Accretion in Practice

```rye
// BAD: Breaking change
pub fn parse(input: []const u8) !Ast { ... }
// Later: "we need options now"
pub fn parse(input: []const u8, opts: Options) !Ast { ... } // BREAKS CALLERS

// GOOD: Accretion
pub fn parse(input: []const u8) !Ast { ... }
// Later: new function with new name
pub fn parse_with_opts(input: []const u8, opts: Options) !Ast { ... } // GROWS API
```

Maven Central never breaks because it's "an accreting collection of immutable things." 
Rye aspires to the same: **grow forever, break never**.

## The Last Stage

At the end of the day, keep trying things out, have fun, and remember—Rye is hardy grain that grows
in harsh conditions. Our kernel runs on bare metal. Our compiler enforces our style. Our path has
heart.

---

**now == next + 1**

---

## Attribution

This document is adapted from [GrainStyle](grain_style.md), which is heavily inspired by
[TigerBeetle's TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md).
We stand on the shoulders of giants.
