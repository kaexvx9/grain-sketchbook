# Grain Handbook — Glow G2 Edition

## 12 Roadmap
1. Replace Tahoe Sandbox stubs with a thin Cocoa shim that gives Aurora a
   native macOS window (traffic lights + menu) while keeping Zig memory
   explicit. Also document that the same Aurora engine compiles without
   Cocoa on Framework 13/16 and other hosts.
2. Use the Framework 16 (Ubuntu) for QEMU testing until the Framework 13
   RISC-V mainboard arrives, then repeat on-device; VPS becomes optional.
3. Implement Grain Pottery kiln orchestration and GrainVault secrets
   wiring.
4. Harden Graindaemon transport backends (TCP, debug) and expose CLI
   toggles.
5. Document deterministic single-copy recovery steps and automate them in
   Grain Conductor.
6. Expand TigerBank bounded retry tests and publish Jepsen-aligned
   assertions.
