# Contributing to Grain OS (xy-mathematics)

**Date**: 2026-01-03-112400-pst  
**Voice**: Glow G2 (steadfast, calm, helpful guidance)  
**Status**: ✅ **CONTRIBUTING GUIDE READY** — Guidelines for Grain OS contributors

---

## Welcome

Thanks for your interest in contributing to Grain OS. We're building a minimal, safety-first operating system in pure Zig, targeting RISC-V hardware. Your contributions help make this project better, and we appreciate your time and effort.

This guide covers how to contribute, our development standards, and important processes. If you have questions, feel free to ask. We're here to help.

---

## Project Overview

**Grain OS** (xy-mathematics) is an operating system project focusing on:

- **Framework x86_64 Ubuntu Development**: Native development and testing on Framework hardware (x86_64 AMD), with JIT compilation from RISC-V to x86_64
- **Toroidal RISC-V Hardware R&D**: Research and development of toroidal hardware architectures, capitalizing on RISC-V for high-performance computing and machine learning synthesis
- **Basin Kernel**: Minimal RISC-V kernel with syscall interface, running in VM with JIT acceleration
- **sevenos**: NixOS-based system integration, unified with Grain OS architecture
- **Grain Style**: Explicit limits, patient discipline, code that teaches

**Current Focus**: Framework x86_64 Ubuntu development on one end, toroidal hardware RISC-V research on the other end, with RISC-V as the unifying architecture for both directions.

---

## Development Standards

### Grain Style

We follow **Grain Style** coding standards. See `docs/grain_style.md` for complete guidelines.

**Key principles**:
- Explicit limits: Use `u32`/`u64`, not `usize`/`isize`
- Patient discipline: Code written once, read many times
- Bounded allocations: Pre-allocate collections, avoid hidden allocations
- Code that teaches: Comments explain why, not what
- Safety first: Assert preconditions and postconditions (minimum 2 assertions per function)

**Format standards**:
- Line width: 128 characters (hard wrap, 2^7) — Graincard compatibility
- Function length: Max 64 lines (Grain Style `grainvalidate-64`, 2^6)
- Graincard format: 128×64 monospace teaching cards (content-only, binary-aligned, optimized for portrait 8.5×11" paper)

### Glow G2 Voice

All documentation and communications use **Glow G2 voice**:
- Masculine, steadfast, Aquarian
- Calm, acknowledging challenges while remaining upbeat and guiding
- Stoic style: steady, grounding presence
- Forward-looking and solution-focused

See `docs/zyx/glow_g2.md` for complete voice guidelines.

---

## Development Workflow

### Getting Started

1. **Fork the repository**: Create your own fork of the `xy-mathematics` repository
2. **Clone your fork**: `git clone https://codeberg.org/YOUR_USERNAME/xy-mathematics.git`
3. **Set up development environment**: Follow setup instructions in `README.md`
4. **Create a branch**: `git checkout -b your-feature-branch`

### Making Changes

1. **Follow Grain Style**: Ensure your code follows Grain Style guidelines
2. **Write tests**: Add tests for new functionality
3. **Update documentation**: Update relevant documentation as needed
4. **Commit your changes**: Use clear, descriptive commit messages

### Commit Messages

**Format**: Clear, descriptive commit messages following Grain Style principles.

**Example**:
```
feat: Add RISC-V to x86_64 JIT backend for Framework Ubuntu

- Implement x86_64 instruction encoding
- Add x86_64 register allocation
- Update VM Runtime integration
- Add tests for x86_64 JIT pipeline

Grain Style: Explicit limits, bounded allocations, 2 assertions/function
```

### Pull Requests

1. **Create a pull request**: Push your branch and create a PR on Codeberg
2. **Describe your changes**: Explain what you changed and why
3. **Reference issues**: Link to relevant issues if applicable
4. **Wait for review**: Core contributors will review your PR
5. **Address feedback**: Make requested changes and update your PR

---

## Arweave Archive and Patent Preparation

As part of our intellectual property work, we maintain permanent archives of the repository on Arweave's blockchain. These archives serve as immutable timestamps for patent application preparation.

### When to Create Archives

Archives are created:
- Before major patent application filings
- For significant milestone releases
- As needed for intellectual property protection

### Archive Creation Process

If you're asked to help with archive creation, follow these guides:

1. **Wallet Setup**: See `docs/archive/2026-01-03-112200-pst_arweave_wallet_setup_guide.md`
   - Complete beginner tutorial for setting up Arweave wallet
   - Options: Wander browser extension (recommended), Arweave.app, or command-line
   - Security best practices and budget planning

2. **Upload Process**: See `docs/archive/2026-01-03-112300-pst_arweave_upload_guide.md`
   - Step-by-step upload instructions
   - Multiple upload methods (ArDrive web interface, CLI, API)
   - Transaction ID documentation and verification

**Tools Used**:
- **Wander**: Browser extension wallet (formerly ArConnect, rebranded 2025) — https://www.wander.app/
- **ArDrive**: Web interface for uploading files to Arweave — https://ardrive.io/
- **Arweave.app**: Web-based wallet alternative

**Cost**: ~$2-5 USD per archive (typically ~500 MB per archive)

**Purpose**: Permanent, immutable archives for patent application timestamps and intellectual property protection.

---

## Architecture and Project Structure

### Core Components

- **Basin Kernel**: RISC-V kernel (`src/kernel/`)
- **VM Runtime**: RISC-V to x86_64/ARM64 JIT (`src/kernel_vm/`)
- **sevenos**: NixOS-based system integration (`grainstore/sevenos/`)
- **Core Services**: Auth, Network, Storage, Compositor (`src/core/`)
- **Aurora IDE**: Development environment (`src/aurora/`)

### Documentation Structure

- **Core Coordination**: `docs/core-coordination/` — Agent coordination documents
- **Plans**: `docs/plans/` — Development plans and roadmaps
- **Tasks**: `docs/tasks/` — Task lists and progress tracking
- **Research**: `docs/research/` — Research documents and whitepapers
- **Agent Communications**: `docs/agent-communications/` — Agent communication templates and guides

### Graincards

We use **Graincard format** (128×64 monospace teaching cards, binary-aligned) for knowledge preservation. See `docs/zyx/graincard_repo_template_103x80_2025-12-22-020323-pst.md` for format specifications.

---

## Testing

### Running Tests

```bash
zig build test
```

### Test Standards

- All new features must have tests
- Tests should be clear and well-documented
- Follow Grain Style for test code
- Integration tests for cross-component functionality

---

## Questions and Support

If you have questions or need help:

1. **Check the documentation**: Start with `README.md` and `docs/`
2. **Review Grain Style**: See `docs/grain_style.md` for coding standards
3. **Ask in issues**: Open an issue on Codeberg if you need help
4. **Coordinate with agents**: See `docs/core-coordination/` for agent coordination guidelines

---

## Code of Conduct

We maintain a respectful, inclusive development environment. Be kind, be patient, and help others learn. We're all here to build something great together.

---

## License

See `LICENSE` file for license information.

---

**Date**: 2026-01-03-112400-pst  
**Voice**: Glow G2 (steadfast, calm, helpful guidance)  
**Status**: ✅ **CONTRIBUTING GUIDE READY**

