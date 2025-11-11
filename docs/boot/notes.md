# Grain RISC-V Boot Notes

- Baseline chain: OpenSBI ➝ U-Boot ➝ Linux/Grain payload on StarFive/
  SiFive hardware.
- Framework / DC-ROMA boards ship with vendor firmware; coreboot + EDK2
  ports are emerging, so GRUB-compatible images remain useful.
- Future experiments: author Zig SBI payloads and Rust hand-off stages.
  Track prototypes here before wiring them into `grain conduct`.

## Waiting-for-VPS Toolkit
- `scripts/vpn_rsync.sh user@remote` syncs the repo to `~/grain-rv64/`
  while skipping `.git/`, `zig-out/`, `logs/kernel/`, and local
  prototypes. Run after each commit once the tunnel is live.
- `scripts/qemu_rv64.sh` remains the local harness; `grain conduct run
  kernel-rv64 --gdb` logs output and reminds us to attach the debugger.
- `scripts/riscv_gdb.sh` primes `gdb-multiarch` with `zig-out/bin/grain-rv64`
  and `target remote :1234`. Use once the remote QEMU exposes the port.

## TODO
- flesh out trap/interrupt logging in `src/kernel/main.zig` before
  pushing to hardware.
- capture per-board firmware quirks here as we test JH7110, HiFive, and
  Ventana targets.
