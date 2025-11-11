#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="$ROOT/out/kernel/grain-rv64.bin"

if [ ! -f "$KERNEL" ]; then
  echo "Kernel image not found at $KERNEL" >&2
  exit 1
fi

qemu-system-riscv64 \
  -machine virt \
  -cpu rv64 \
  -m 512M \
  -nographic \
  -bios default \
  -kernel "$KERNEL" \
  -serial mon:stdio \
  -monitor telnet:127.0.0.1:5555,server,nowait
