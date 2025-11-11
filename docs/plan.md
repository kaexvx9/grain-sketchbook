# Grain Aurora GUI Plan — TigerStyle Execution

## 1. Bundle Pipeline (macOS Tahoe)
- Add `tools/macos_bundle.zig` to package Ray/GrainAurora as a `.app`.
- Expose via `zig build mac-app` and `grain conduct make mac-app`.

## 2. GrainAurora Framework
- New module `src/grain_aurora.zig` defining component structs, node tree,
  deterministic reconcile.
- Component lifecycle: `init`, `render`, `event`, `teardown` (no hidden
  allocations).

## 3. Routing Layer
- `src/grain_route.zig`: map Nostr `npub` multi-path segments → component
  entry points (static array of routes, referential transparency).
- Persist last route snapshot in GrainBuffer read-only segments.

## 4. Template Preprocessor
- `tools/aurora_preprocessor.zig` transforms `.aurora` markup into Zig
  modules; deterministic codegen, no runtime eval.

## 5. RISC-V Syscall Boundary
- `src/riscv_sys.zig` defines syscall stubs used by GrainAurora so the
  same interface works on the future monolith kernel.

## 6. Tahoe Moonglow Windowing
- Expand `src/tahoe_window.zig` with River-like tiling, Moonglow keyboard
  maps, integration hooks for GrainAurora view roots.

## 7. GrainOrchestrator
- `src/grain_orchestrator.zig` coordinates Graindaemon, GrainAurora,
  Cursor CLI, Ghostty, Claude Code, and bounded retry policy.

## 8. Brewfile Bundle Modules
- Extend `grain conduct brew` to emit versioned bundle definitions with
  semantic + Holocene-Vedic versions into `docs/BREW_LOCK.zig`.

## 9. Letta Agent Spec
- Mirror Letta agent manifests (tools, memory, persona) in
  `src/grain_orchestrator.zig` and `docs/doc.md`.
- Provide `grain orchestrator deploy` command for declarative agent
  provisioning.

## 10. Asset Pipeline & Tests
- `zig build aurora-assets` compiles templates to Zig and bundles static
  data.
- Add Matklad-style snapshot tests under `tests/ui/` plus route fuzzing in
  `tests-experiments/002.md`.

## 11. Documentation Sync
- Update `docs/ray.md`, `docs/doc.md`, and `docs/outputs.md` after each
  milestone.
- Log prompts in `docs/prompts.md` with descending IDs.
