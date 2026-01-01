# NixOS VM Setup for Framework 16

This directory contains the setup for running NixOS 25.11 in a QEMU/KVM virtual machine on Ubuntu 24.04 LTS (Framework 16).

## Files

- `iso/nixos-minimal-25.11.iso` - NixOS 25.11 minimal installation ISO (1.5GB)
- `iso/nixos-minimal.sha256` - SHA256 checksum file
- `disk/nixos-vm.qcow2` - Virtual disk image (40GB, sparse)
- `configuration.nix` - NixOS configuration template with development tools
- `launch_nixos_vm.sh` - Script to launch the NixOS VM

## Quick Start

1. **Launch the VM**:
   ```bash
   ./launch_nixos_vm.sh
   ```

2. **Install NixOS**:
   - Boot from the ISO (should happen automatically)
   - Follow the NixOS installation guide: https://nixos.org/manual/nixos/stable/#sec-installation
   - Copy `configuration.nix` to `/etc/nixos/configuration.nix` in the VM
   - Run `nixos-install` and `nixos-rebuild switch`

3. **After Installation**:
   - Remove `-cdrom $ISO_FILE` line from `launch_nixos_vm.sh` (or change boot order)
   - SSH access: `ssh -p 2222 xy@localhost` (after configuration)

## VM Configuration

- **Memory**: 8GB RAM
- **CPU**: 4 cores (host passthrough)
- **Disk**: 40GB qcow2 format (sparse, grows as needed)
- **Network**: User-mode networking with SSH port forward (host:2222 -> guest:22)
- **Display**: GTK (can be changed to VNC or SDL)

## Next Steps

After NixOS is installed, you can:
- Clone the `xy-mathematics` repository
- Set up development environment (already in configuration.nix)
- Optionally set up Alpine Linux as a nested guest for musl libc testing

## References

- Framework 16 Virtualization Strategy: `docs/framework_16_alpine_nixos_virtualization_recommendation_2026-01-01-134931-pst.md`
- NixOS Manual: https://nixos.org/manual/nixos/stable/

