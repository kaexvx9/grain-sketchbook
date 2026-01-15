#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $(basename "$0") user@remote" >&2
  exit 1
fi

REMOTE="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${REMOTE}:~/grain-rv64"

rsync -az --delete \
  --exclude='.git/' \
  --exclude='zig-out/' \
  --exclude='logs/kernel/' \
  --exclude='prototypes/' \
  "$ROOT/" "$DEST/"
