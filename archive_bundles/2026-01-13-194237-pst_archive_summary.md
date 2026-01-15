# Archive Summary

**Git Commit**: `4eafdca`  
**Date**: 2026-01-13-194200-pst  
**Previous Archive**: 2026-01-13-194107-pst (commit `26a1a51`)  
**Summary SHA256**: `fa27c3635896501cfcf88207e781da0c85c518e9f120d7894ff1e49411ab1a7b`

---

## Archive Contents

This archive bundle includes:
- All source code (`src/`, `grainstore/`, etc.)
- All documentation (`docs/`)
- All configuration files
- All test files (`tests/`)
- All other repository contents
- **The commit that created the previous archive bundle** (commit `4eafdca` - "archive: add recursive Arweave bundle")

## Recursive Archive Process

This archive is created recursively - it includes the commit (`4eafdca`) that created the previous archive bundle (`2026-01-13-194107-pst`). This demonstrates the self-referential nature of the archive process where each archive contains the commit that created the previous archive.

## Excluded

- `.git/` directory (git history)
- `.zig-cache/` (build artifacts)
- `zig-out/` (build artifacts)
- `node_modules/` (if present)
- `archive_bundles/*.tar.gz` and `archive_bundles/*.zip` (archive files themselves)
- Archive SHA256 and summary files are included

## Purpose

These archives will be uploaded to Arweave for permanent, immutable storage as part of patent application preparation for:
- Toroidal ML Synthesis whitepaper
- Silicon Torus HPC Hardware Proposal whitepaper
- Oregon MMT Vegan Permaculture Housing Proposal

## Verification

Verify archive integrity using the SHA-256 checksums:
```bash
sha256sum -c *.sha256
```

---

**Created**: 2026-01-13-194200-pst  
**Archive Commit**: `4eafdca`  
**Previous Archive Commit**: `26a1a51`
