# Grain RISC-V Boot Notes

- Baseline chain: OpenSBI ➝ U-Boot ➝ Linux/Grain payload on StarFive/
  SiFive hardware.
- Framework / DC-ROMA boards ship with vendor firmware; coreboot + EDK2
  ports are emerging, so GRUB-compatible images remain useful.
- Future experiments: author Zig SBI payloads and Rust hand-off stages.
  Track prototypes here before wiring them into `grain conduct`.
