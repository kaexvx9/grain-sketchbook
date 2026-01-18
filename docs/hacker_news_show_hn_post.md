# Show HN Post Draft

## Title Options

**Option 1 (Cursor Ultra Focus - RECOMMENDED):**
```
Show HN: 170k lines of Zig written by Cursor Ultra Auto Mode ($200/month) – a full RISC-V OS
```

**Option 2 (Economics angle):**
```
Show HN: We built a RISC-V OS in Zig using Cursor Ultra – $200/month vs $20k+ in dev costs
```

**Option 3 (Technical + AI):**
```
Show HN: Grain OS – A RISC-V OS with JIT compiler, built almost entirely by AI agents
```

**Option 4 (Provocative):**
```
Show HN: What happens when you let Cursor Auto Mode run for weeks – 170k lines of Zig OS
```

---

## Post Text

### HN Post Text (under 4000 chars)

```
This entire codebase was built using Cursor Ultra ($200/month) in Auto Mode.

170k lines of Zig. 500+ source files. 249 tests. A RISC-V64 OS with JIT compiler, networking, and scripting language — built by AI agents working autonomously.

What we learned:

1. Auto Mode is the unlock — $200/month tier gives extended autonomous sessions. AI reads code, writes tests, fixes bugs, refactors — without constant prompting.

2. Style guides matter more — We created "Grain Style" (64-line function limit, explicit types, 2+ assertions). AI follows rules more consistently than humans.

3. Tests are essential — 249 tests to verify AI code. AI writes the tests too.

4. Economics — $200/month for what would cost $20k+ in dev time. Built in weeks, not months.

The kernel:
- Pure Zig, boots on QEMU RISC-V64
- x86_64 JIT for near-native RISC-V execution
- 60+ syscalls, TCP/UDP networking
- Grainscript shell (lexer, parser, interpreter)
- ELF loader, process spawning

Roadmap to Alpha:

Bottleneck: Basin kernel → Vantage VM → Framework x86_64. Target: first-responder dispatch software — emergency services need reliable, auditable systems.

Contributors needed:
- ARM aarch64 (Apple Silicon): Zig → C → Swift macOS app
- Aurora: open-source iOS Cursor alternative with two backends:
  - Cursor CLI Ultra (https://cursor.com)
  - Cerebras WSE (https://cerebras.ai) — spatial RAM, deterministic inference

Grain Style: https://codeberg.org/teamlibra/ry/src/branch/main/docs/grain_style.md

Happy to discuss Cursor Auto Mode, Zig for OS dev, or Cerebras spatial compute.
```

**Character count: ~1,650** (well under 4000 limit)

---

### Extended Version (if you want more detail)

```
We've been running Cursor Ultra ($200/month) in Auto Mode for extended sessions — sometimes 8+ hours of autonomous development. This repository is the result: 170k+ lines of Zig, a complete RISC-V64 operating system.

**The Cursor Ultra Experience:**

Auto Mode changes everything. Instead of prompting line-by-line, we describe high-level goals:
- "Fix all compilation errors in the JIT compiler"
- "Add TCP socket support with proper error handling"  
- "Refactor this function to be under 64 lines"

The AI then works autonomously: reading files, understanding context, making coordinated changes across the codebase, writing tests, updating documentation. It's pair programming where your partner has read every file and never gets tired.

**What makes the code different:**

1. **AI-friendly style guide** – We created "Grain Style" specifically for AI-assisted development:
   - 64-line function maximum (2^6)
   - 128-character line maximum (2^7)
   - No recursion
   - 2+ assertions per function
   - Explicit types (u32/u64 never usize)
   - Every comment explains "why"
   
   The AI follows these rules more consistently than humans would. 48 of 56 kernel files are fully compliant.

2. **Pure Zig** – No C dependencies except libc for host tools. Zig's comptime features let us do things that would require macros or code generation in C.

3. **JIT Compiler** – Working x86_64 JIT that translates RISC-V instructions to native code. Near-native speed on x86 hosts.

4. **249 Tests** – Essential for AI-written code. The AI writes the tests too.

**Technical highlights:**

- Kernel boots on QEMU RISC-V64 with virt machine
- 60+ syscalls (process, memory, IPC, network, audio, filesystem)
- TCP/UDP networking with socket abstraction
- Grainscript: a minimal scripting language with lexer, parser, interpreter
- Process scheduler with priority queues
- ELF loader supporting RISC-V64 binaries
- Framebuffer graphics with dirty region tracking

**The economics:**

$200/month for Cursor Ultra. This codebase would have taken a small team several months at $15-20k+ in developer costs. We built it in weeks.

The catch: you still need to know what you're building. AI amplifies capability, it doesn't replace vision.

**Roadmap to Alpha:**

Bottleneck: Basin kernel → Vantage VM → Framework x86_64. Target application: **first-responder dispatch software**.

Contributors needed for ARM aarch64 (Apple Silicon) — Zig → C → Swift macOS app. Also designing Aurora (open-source iOS Cursor alternative) with two inference backends:
- [Cursor CLI Ultra](https://cursor.com) ($200/month) 
- [Cerebras WSE](https://cerebras.ai) — spatial RAM, single-threaded bounded compute, deterministic latency

**Current status:**

Kernel boots, REPL works, Grainscript executes. 

Built with Zig 0.15.2. Follows [Grain Style](docs/grain_style.md). MIT/Apache-2.0/BSD-3-Clause licensed.
```

---

## Anticipated Questions & Answers

**Q: Is this actually AI-generated code?**
A: Yes, the vast majority. We describe goals, the AI writes code. We review, test, iterate. The AI also writes tests, documentation, and handles refactoring. Human role is vision, architecture decisions, and quality control.

**Q: How does Cursor Ultra Auto Mode work?**
A: You pay $200/month for the Ultra tier. Auto Mode lets you give high-level instructions and the AI works autonomously — reading files, making changes, running tests, fixing errors. It can work for hours on complex tasks without constant prompting.

**Q: Is $200/month worth it?**
A: For us, absolutely. This codebase would cost $15-20k+ in developer time. Even at 10% efficiency (AI doing work of a developer for 10% of the time), it's worth it. In practice, it's much higher for certain tasks like boilerplate, tests, documentation, and systematic refactoring.

**Q: What can't AI do well?**
A: Novel architecture decisions, understanding unstated requirements, knowing when to stop. You still need to know what you're building. AI amplifies capability, doesn't replace vision.

**Q: Why Zig instead of Rust?**
A: Zig's simplicity works better with AI. No hidden control flow, no complex macros, explicit allocators. The AI generates more consistent Zig than Rust. Also, comptime is easier to reason about than proc macros.

**Q: Why RISC-V?**
A: Open ISA, clean architecture, growing ecosystem (Framework 13 RISC-V). Having a JIT that translates RISC-V → x86_64 gives us the best of both worlds during development.

**Q: Is the 64-line limit realistic?**
A: 48 of 56 kernel files are compliant. AI follows the limit more consistently than humans would. When it can't fit in 64 lines, it extracts helper functions automatically.

**Q: What's with the AI "voices" (Reya and Glow)?**
A: We gave the AI agents personas to make the development more coherent. Reya is the creative/political voice, Glow is the technical/grounding voice. It helps maintain consistent tone in documentation.

**Q: Governor campaign?**
A: Yes, Keaton Livermore is running for California Governor in 2026. The OS work demonstrates that different approaches to technology and governance are possible. Open-source infrastructure is part of the platform.

**Q: Can I actually run this?**
A: Yes! `zig build kernel-rv64` builds the kernel, `./scripts/qemu_rv64.sh` runs it on QEMU. Requires Zig 0.15.2+ and QEMU with RISC-V support.

**Q: Why first-responder dispatch software?**
A: Emergency services need reliable, auditable, safety-critical systems. Legacy dispatch software is often outdated and proprietary. Grain OS is designed for exactly this: deterministic execution, comprehensive assertions, code that can be audited and trusted with lives.

**Q: What's the Cerebras path about?**
A: [Cerebras](https://cerebras.ai) makes Wafer Scale Engines — spatial RAM hardware designed for single-threaded bounded compute. Orders of magnitude faster inference than GPUs for certain workloads, with deterministic latency. Perfect for safety-critical applications that need local, auditable AI. We're designing Aurora (iOS Cursor alternative) to support both Cursor Ultra cloud and Cerebras local inference.

**Q: What's Grain Style?**
A: Our coding philosophy: 64-line function limit (2^6), 128-char line limit (2^7), explicit types (u32/u64 not usize), 2+ assertions per function, no recursion, bounded allocations, comments that explain "why." See [docs/grain_style.md](docs/grain_style.md). The AI follows these rules more consistently than humans.

---

## Suggested Posting Time

Best HN posting times (US timezones):
- Tuesday-Thursday, 8-10am PT
- Avoid weekends and Monday mornings

---

## One-liners for social media

**Twitter/X (Cursor focus):**
```
We ran Cursor Ultra Auto Mode ($200/month) for weeks. Result: 170k lines of Zig, a complete RISC-V OS with JIT compiler. AI wrote the code, tests, and docs. Show HN: [link]
```

**Twitter/X (Economics focus):**
```
$200/month for Cursor Ultra vs $20k+ in dev costs. We built a 170k-line RISC-V OS in Zig using AI Auto Mode. The future of development is here. [link]
```

**Twitter/X (Technical focus):**
```
Show HN: Grain OS — 170k lines of Zig, RISC-V kernel, JIT compiler, networking stack, scripting language. Built almost entirely by AI agents in Cursor Ultra. [link]
```

**LinkedIn:**
```
What happens when you let AI write code autonomously for weeks?

170,000+ lines of Zig
500+ source files  
249 passing tests
A complete RISC-V64 operating system

Built using Cursor Ultra ($200/month) in Auto Mode. The economics: $200/month for what would cost $20k+ in developer time.

This is what AI-assisted development looks like in 2026.

[link]
```
