# Repository Archive Bundles

These archives were created for Arweave blockchain storage as part of patent application preparation.

## Archive Files

- `xy-mathematics-YYYY-MM-DD-HHMMSS-pst.tar.gz` - TAR.GZ compressed archive
- `xy-mathematics-YYYY-MM-DD-HHMMSS-pst.zip` - ZIP compressed archive
- `*.sha256` - SHA-256 checksum files for verification

## Verification

Verify archive integrity using the SHA-256 checksums:

```bash
sha256sum -c *.sha256
```

## Contents

Archives include:
- All source code (`src/`, `grainstore/`, etc.)
- All documentation (`docs/`)
- All configuration files
- All test files (`tests/`)
- All other repository contents

Excluded:
- `.git/` directory (git history)
- `zig-cache/` (build artifacts)
- `zig-out/` (build artifacts)
- `node_modules/` (if present)
- `archive_bundles/` (archive directory itself)

## Purpose

These archives will be uploaded to Arweave for permanent, immutable storage as part of patent application preparation for:
- Toroidal ML Synthesis whitepaper
- Silicon Torus HPC Hardware Proposal whitepaper

Created: 2026-01-03 (PST)
