# sevenos Setup Guide

## Prerequisites

- Git
- Nix
- Access to Codeberg repositories

## Initial Setup

### 1. Clone sixos Repository (External)

Clone the sixos repository to a separate location outside the monorepo:

```bash
mkdir -p ~/codeberg/amjoseph
cd ~/codeberg/amjoseph
git clone https://codeberg.org/amjoseph/sixos.git
```

This keeps the sixos repository as a separate git repository, avoiding submodule complexity.

### 2. Grainmirror sixos into Project

Use grainmirror to mirror the sixos repository into the sevenos project:

```bash
cd ~/xy-mathematics/grainstore/sevenos
# TODO: Add grainmirror command once grainmirror tool is available
# grainmirror ~/codeberg/amjoseph/sixos sixos
```

For now, you can manually symlink or copy:

```bash
# Temporary: manual symlink (replace with grainmirror when available)
ln -s ~/codeberg/amjoseph/sixos sixos
```

### 3. Download NixOS 25.11 nixpkgs Source

Download the NixOS 25.11 nixpkgs source:

```bash
cd ~/xy-mathematics/grainstore/sevenos
wget https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.zip
unzip 25.11.zip
mv nixpkgs-25.11 nixpkgs
```

Or clone as a separate repository:

```bash
mkdir -p ~/codeberg/nixos
cd ~/codeberg/nixos
git clone https://github.com/NixOS/nixpkgs.git --branch nixos-25.11 --depth 1
# Then grainmirror or symlink into project
```

## Project Structure

After setup:

```
grainstore/sevenos/
├── sixos/          # Grainmirror from ~/codeberg/amjoseph/sixos/
├── nixpkgs/        # NixOS 25.11 nixpkgs source
├── config/         # Unified configuration files
├── services/       # Service definitions (systemd → S6)
└── docs/           # Documentation
```

## Why External Repository + Grainmirror?

- **Avoids Git Submodule Complexity**: No submodule management in monorepo
- **Cleaner Git History**: External repos don't clutter monorepo commits
- **Flexible Updates**: Update sixos independently, then grainmirror when ready
- **Monorepo Simplicity**: xy-mathematics stays clean without submodule overhead

