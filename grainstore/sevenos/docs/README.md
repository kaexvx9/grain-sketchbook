# sevenos Documentation

## Project Goals

Unify sixos (NixOS without systemd) with NixOS 25.11 minimal.

## References

- [sixos repository](https://codeberg.org/amjoseph/sixos) - cloned to `~/codeberg/amjoseph/sixos/`
- [sixos 38C3 talk](https://media.ccc.de/v/38c3-sixos-a-nix-os-without-systemd)
- [NixOS 25.11 nixpkgs](https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.zip)
- Framework 16 unification analysis document

## Repository Setup

The sixos repository is stored externally and grainmirrored into this project:

- **External Location**: `~/codeberg/amjoseph/sixos/` (separate git repository)
- **Mirror Location**: `grainstore/sevenos/sixos/` (grainmirror, not git submodule)

This approach avoids git submodule complexity in the xy-mathematics monorepo.

## Architecture

- **Base**: NixOS 25.11 minimal
- **Init System**: S6 (S6-linux-init, S6-SVC, S6-RC)
- **Bootloader**: systemd-boot (per Grain Style recommendation)
- **Target**: QEMU/KVM VM on Framework 16 Ubuntu 24.04 LTS host

