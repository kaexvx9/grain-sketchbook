#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="$ROOT/zig-out/bin/grain-rv64"

if [ ! -f "$KERNEL" ]; then
  echo "kernel image missing. run 'zig build kernel-rv64' first." >&2
  exit 1
fi

gdb-multiarch \
  -ex "set arch riscv:rv64" \
  -ex "file $KERNEL" \
  -ex "target remote :1234"
