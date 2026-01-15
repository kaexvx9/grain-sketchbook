# Timestamp Format Reference: Los Angeles/Pacific Time

**Purpose**: Reference for generating timestamps in all documents and code edits  
**Time Zone**: Los Angeles/Pacific Time (America/Los_Angeles)  
**Location**: Sonoma County, Northern California

---

## Timestamp Format

**Format**: `yyyy-mm-dd-hhmmss-pst`

**Example**: `2025-12-31-221841-pst`

**Format Breakdown**:
- `yyyy` = 4-digit year (e.g., 2025)
- `mm` = 2-digit month (01-12)
- `dd` = 2-digit day (01-31)
- `hhmmss` = 2-digit hour (00-23) + 2-digit minute (00-59) + 2-digit second (00-59)
- `pst` = Always use "pst" (even during PDT daylight saving time, use "pst" in the format)

---

## Command to Generate Timestamp

```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

**CRITICAL**: Always use `TZ=America/Los_Angeles` to ensure correct Pacific Time zone, regardless of system timezone settings.

---

## When to Use

Use this timestamp format for:
- ✅ Creating new documents (coordination docs, plans, tasks, proposals, etc.)
- ✅ Code edits that include timestamps
- ✅ Git commit messages with timestamps
- ✅ Filenames that include timestamps
- ✅ Document headers with "Date" or "Last Updated" fields

---

## Examples

### Document Header
```markdown
**Date**: 2025-12-31-221841-pst
**Last Updated**: 2025-12-31-221841-pst
```

### Filename
```
core_agent_coordination_plan_2025-12-31-221841-pst.md
```

### Git Commit Message
```
feat: add new feature

Timestamp: 2025-12-31-221841-pst
```

---

## Time Zone Notes

- **PST (Pacific Standard Time)**: UTC-8 (winter, typically November-March)
- **PDT (Pacific Daylight Time)**: UTC-7 (summer, typically March-November)
- **Format String**: Always use "pst" in the format string, even during PDT
- **System Handling**: The `TZ=America/Los_Angeles` setting automatically handles PST/PDT transitions

---

## Verification

To verify the current timestamp:
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

Expected output format: `2025-12-31-221841-pst`

---

**Last Updated**: 2025-12-31-221841-pst
