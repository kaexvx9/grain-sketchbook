xy-mathematics
grain os development
risc-v kernel + vm + aurora ide

we build a minimal, safety-first operating system in pure zig,
targeting risc-v64 hardware. grain basin kernel runs in a virtual
machine with jit acceleration, displayed in grain aurora ide on
macos tahoe 26.3 beta.

our path leads from vm development to native risc-v hardware:
framework x86_64 ubuntu on one end, toroidal risc-v hardware r&d
on the other. we design for repairability, modularity, and long-
term sustainability. risc-v unifies both directions.

current status:
- jit compiler: complete (risc-v -> aarch64, risc-v -> x86_64)
- vantage integration: complete
- kernel boot: implementing
- sevenos init system: phases 1-6 complete
- grainscript shell: step 4 ready

architecture:
framework x86_64 ubuntu (native host)
grain vantage (risc-v -> x86_64 jit)
grain basin kernel (risc-v64)
grain sevenos (nixos-based init system)

we follow grain style: explicit limits, patient discipline, code
that teaches. every line crafted to last, every decision made with
care for the next thirty years. we measure success not in features
shipped, but in code that lasts. we build for thirty years, not
thirty days. each decision made with care for the long term.

the kernel is our foundation, the vm our bridge between development
and deployment. we write in zig for safety, for clarity, for the
future. risc-v is our target, framework x86 our goal, repairability
our promise.

we work with 24 agents (12 l1 + 12 l2) in parallel, coordinated
through recursive prompt patterns. each agent follows grain style,
each contribution serves the whole. collaboration is sacred.

we maintain two repositories: hot (codeberg) for active development,
cold (arweave) for permanent archival. codeberg enables iteration,
arweave preserves forever. both serve different purposes, both
essential.

for advanced programmers: see docs/archive/2026-01-04-174950-pst_
grain_os_advanced_introduction.md for complete introduction. this
document includes agent architecture, toroidal research inspiration,
spiritual philosophy, recursion prompts, hot/cold repository strategy,
archive links, licenses, and twitter proof (sha3-512 hash in header).

twitter proof: the sha3-512 hash in the introduction document header
proves synergy between @kae3g_ (twitter) and teamcarry11/xy-mathematics
(codeberg). post this hash on twitter to verify account ownership and
repository authenticity. the hash is: 3fd948cafeab3edb64d2a73f48c9703
864d8237af27aaf91f4d2c4e13b6542c1abaab948cba966bf9b0bc1666fbc0ec1b
d6ed750276972a2aa3928810be0fc2a

we are teamcarry11, the wisdom carriers who preserve knowledge and
pour it forward. the star guides us, showing where external knowledge
meets internal practice. we carry water not to hoard, but to share.

this is not a sprint. this is a marathon. we build for the long
term, we code for the ages. every function a lesson, every module a
chapter in the book of understanding. the work continues, one commit
at a time, one function at a time, one lesson at a time.

keaton dunsford
email: kj3x39@gmail.com
github: @kae3g
twitter: @kae3g_
instagram: @risc.love
