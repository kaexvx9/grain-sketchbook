# Timestamp Generation Guide

**Why**: Ensure all timestamps in documentation are generated live from the current system time, not hardcoded placeholder values.

---

## Quick Reference

### Headers and Filename Prefixes
```bash
# Format: yyyy-mm-dd-hhmmss-pst (with dashes, lowercase)
date +"%Y-%m-%d-%H%M%S-pst"
# Example: 2026-01-23-160529-pst
```

### Versioning (Rye Style Chronological)
```bash
# Format: YYYYMMDD.HHMMSS.variant (no dashes, dots, uppercase)
date +"%Y%m%d.%H%M%S"
# Example: 20260123.160529.basin
```

### Generate Datetime
```bash
# Format: YYYY-MM-DD HH:MM:SS TZ
date +"%Y-%m-%d %H:%M:%S %Z"
```

### Helper Script
```bash
./docs/core-coordination/generate-timestamp.sh
```

---

## Usage in Documentation

### In Markdown Files
Always use the current timestamp when updating documentation:

```bash
# Get current timestamp
CURRENT_TS=$(date +"%Y-%m-%d-%H%M%S-pst")

# Update file
sed -i "s/OLD_TIMESTAMP/$CURRENT_TS/g" file.md
```

### In Commit Messages
Timestamps in commit messages should reflect when the work was done, using:
```bash
date +"%Y-%m-%d-%H%M%S-pst"
```

---

## Patterns

### Headers and Filenames
**Format**: `yyyy-mm-dd-hhmmss-pst` (with dashes, lowercase)
- Use for: Document headers, filename prefixes, "Last Updated" fields
- Command: `date +"%Y-%m-%d-%H%M%S-pst"`
- Example: `2026-01-23-160529-pst`

**Always generate timestamps dynamically**:
- Never hardcode timestamps like `2026-01-23-270000-pst` (invalid time)
- Always use `date +"%Y-%m-%d-%H%M%S-pst"` command
- Update timestamps when modifying documents

### Versioning (Rye Style)
**Format**: `YYYYMMDD.HHMMSS.variant` (no dashes, dots, uppercase)
- Use for: Chronological versioning per Rye Style
- Command: `date +"%Y%m%d.%H%M%S"` (add variant manually)
- Example: `20260123.160529.basin`
- See: `docs/rye_style.md` section on Chronological Versioning

---

## Examples

### Update Progress File
```bash
CURRENT_TS=$(date +"%Y-%m-%d-%H%M%S-pst")
sed -i "s/\*\*Last Updated\*\*: .*/\*\*Last Updated\*\*: $CURRENT_TS/" \
    docs/core-coordination/vantage3-progress.md
```

### Create New Document
```bash
CURRENT_TS=$(date +"%Y-%m-%d-%H%M%S-pst")
cat > new-doc.md <<EOF
# Document Title

**Date**: $CURRENT_TS
...
EOF
```

---

**Remember**: Timestamps should always reflect real current time, not placeholders.
