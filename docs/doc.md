# Grain Handbook — Glow G2 Edition

## 12 Roadmap
1. Replace Tahoe Sandbox stubs with the thinnest possible Cocoa shim:
   `NSApplication`/`NSWindow` host the view, but Aurora owns the RGBA buffer.
   Document how the same engine runs headless on Framework 13/16 later.
2. Defer QEMU testing until Framework 13 or VPS is ready; meanwhile keep
   notes in `docs/boot/notes.md` and focus on macOS Tahoe Aurora work.
3. Implement Grain Pottery kiln orchestration and GrainVault secrets
   wiring.
4. Harden Graindaemon transport backends (TCP, debug) and expose CLI
   toggles.
5. Document deterministic single-copy recovery steps and automate them in
   Grain Conductor.
6. Expand TigerBank bounded retry tests and publish Jepsen-aligned
   assertions.
