#!/usr/bin/env bash
# SCP files to QEMU guest via port forwarding
# Usage: ./scripts/scp_to_qemu.sh <local_file> [remote_path]
# Example: ./scripts/scp_to_qemu.sh my_script.sh /tmp/my_script.sh

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <local_file> [remote_path]" >&2
  echo "Example: $0 my_script.sh /tmp/my_script.sh" >&2
  exit 1
fi

LOCAL_FILE="$1"
REMOTE_PATH="${2:-/tmp/$(basename "$LOCAL_FILE")}"

if [ ! -f "$LOCAL_FILE" ]; then
  echo "Error: File not found: $LOCAL_FILE" >&2
  exit 1
fi

# QEMU user mode networking forwards host port 2222 to guest port 22
# Note: This requires SSH server running in the guest
# For now, we'll use the shared directory approach instead
echo "Note: Direct SCP requires SSH server in guest kernel."
echo "Using shared directory method instead..."
echo ""
echo "Copying to shared directory:"
echo "  Source: $LOCAL_FILE"
echo "  Destination: $(dirname "$0")/../qemu_shared/$(basename "$LOCAL_FILE")"
echo ""
echo "In QEMU guest, access via: /mnt/shared/$(basename "$LOCAL_FILE")"
echo ""

SHARED_DIR="$(dirname "$0")/../qemu_shared"
mkdir -p "$SHARED_DIR"
cp "$LOCAL_FILE" "$SHARED_DIR/$(basename "$LOCAL_FILE")"

echo "✅ File copied to shared directory!"
echo "   Access in guest: /mnt/shared/$(basename "$LOCAL_FILE")"
