# sevenos

**NixOS 25.11 minimal + sixos unification**

Inspired by tropical zodiac Venus Libra.

A unification of sixos (NixOS without systemd) with NixOS 25.11 minimal,
using S6 supervision suite instead of systemd.

## Project Structure

- `sixos/` - sixos repository (git submodule)
- `nixpkgs/` - NixOS 25.11 nixpkgs source
- `config/` - Unified configuration files
- `services/` - Service definitions (systemd → S6 conversions)
- `docs/` - Documentation and planning

## Goals

- Unify sixos S6 approach with NixOS 25.11 minimal
- Replace systemd with S6 (S6-linux-init, S6-SVC, S6-RC)
- Maintain Grain Style principles: minimalism, simplicity, explicit configuration
- Create working VM environment for Framework 16 development

