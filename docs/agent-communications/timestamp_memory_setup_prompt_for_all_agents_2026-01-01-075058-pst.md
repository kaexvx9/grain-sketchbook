# Timestamp Memory Setup Prompt: For All Agents and Sub-Agents

**Date**: 2026-01-01-075058-pst  
**Purpose**: Prompt for all agents and sub-agents to set Cursor memories for accurate timestamp generation  
**Scope**: All L1 agents, L1 subcores, and L2 sub-agents

---

## Instructions for All Agents

**Copy this entire prompt and follow the instructions below to set your Cursor memory for accurate timestamp generation.**

---

## Why This Matters

We've identified that timestamp calculations have been inaccurate across agents. To ensure consistency and accuracy, **all agents and sub-agents must set a Cursor memory** that ensures timestamps are always generated correctly using Los Angeles/Pacific Time (America/Los_Angeles timezone).

---

## Required Cursor Memory Content

**Memory Title**: Timestamp Format - Los Angeles/Pacific Time

**Memory Content** (copy this exactly):

```
TIMESTAMP FORMAT: Always use yyyy-mm-dd-hhmmss-pst format for Los Angeles/Pacific Time (America/Los_Angeles timezone).

Command to generate: TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"

Use this format for:
- New documents (coordination docs, plans, tasks, proposals, etc.)
- Code edits with timestamps
- Git commit messages
- Filenames with timestamps

Format: yyyy-mm-dd-hhmmss-pst (e.g., 2026-01-01-075058-pst)
Always use TZ=America/Los_Angeles to ensure correct Pacific Time zone.
Always use "pst" in format string (even during PDT daylight saving time).

Location: Sonoma County, Northern California (Pacific Time zone)
```

---

## How to Set This Memory in Cursor

### Step 1: Open Cursor Settings
1. Open Cursor
2. Go to **Settings** (or press `Cmd+,` on macOS / `Ctrl+,` on Windows/Linux)
3. Navigate to **Features** → **AI** → **Memories** (or search for "Memories" in settings)

### Step 2: Add New Memory
1. Click **"Add Memory"** or **"New Memory"** button
2. **Title**: Enter `Timestamp Format - Los Angeles/Pacific Time`
3. **Content**: Paste the memory content from above
4. Click **Save** or **Add**

### Step 3: Verify Memory is Set
1. Confirm the memory appears in your memories list
2. The memory should be active and available to the AI assistant

---

## When to Use This Timestamp Format

**Always use this format when**:
- ✅ Creating new documents (coordination docs, plans, tasks, proposals, etc.)
- ✅ Updating document dates or "Last Updated" fields
- ✅ Creating filenames that include timestamps
- ✅ Adding timestamps to code comments or documentation
- ✅ Including timestamps in git commit messages
- ✅ Any other place where you need to record the current date/time

**Examples**:

### Document Header
```markdown
**Date**: 2026-01-01-075058-pst
**Last Updated**: 2026-01-01-075058-pst
```

### Filename
```
core_agent_coordination_plan_2026-01-01-075058-pst.md
```

### Code Comment
```zig
// Created: 2026-01-01-075058-pst
// Last Modified: 2026-01-01-075058-pst
```

---

## How to Generate Timestamps

### Method 1: Terminal Command (Recommended)
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

**Output Example**: `2026-01-01-075058-pst`

**CRITICAL**: Always include `TZ=America/Los_Angeles` to ensure correct Pacific Time zone, regardless of your system's timezone settings.

### Method 2: Ask Cursor AI
After setting the memory, you can ask Cursor AI:
- "What's the current timestamp in the correct format?"
- "Generate a timestamp for a new document"
- "What time is it in Pacific Time format?"

The AI will use your memory to generate the correct timestamp.

---

## Format Details

**Format**: `yyyy-mm-dd-hhmmss-pst`

**Breakdown**:
- `yyyy` = 4-digit year (e.g., 2026)
- `mm` = 2-digit month (01-12)
- `dd` = 2-digit day (01-31)
- `hhmmss` = 2-digit hour (00-23) + 2-digit minute (00-59) + 2-digit second (00-59)
- `pst` = Always use "pst" (even during PDT daylight saving time)

**Example**: `2026-01-01-075058-pst`
- Year: 2026
- Month: 01 (January)
- Day: 01
- Time: 07:50:58 (7:50:58 AM)
- Timezone: PST (Pacific Standard Time)

---

## Important Notes

### Time Zone Handling
- **PST (Pacific Standard Time)**: UTC-8 (winter, typically November-March)
- **PDT (Pacific Daylight Time)**: UTC-7 (summer, typically March-November)
- **Format String**: Always use "pst" in the format string, even during PDT
- **System Handling**: The `TZ=America/Los_Angeles` setting automatically handles PST/PDT transitions

### Location
- **Location**: Sonoma County, Northern California
- **Time Zone**: Pacific Time (America/Los_Angeles)
- **Why**: This is the project's primary location, and all timestamps should be consistent with this timezone

### Accuracy
- **Always use the command**: Don't manually calculate timestamps
- **Always use TZ=America/Los_Angeles**: Ensures correct timezone regardless of system settings
- **Verify before using**: Run the command to get the current timestamp

---

## Verification

### Test Your Memory is Working

1. **Set the memory** (follow steps above)
2. **Ask Cursor AI**: "What's the current timestamp in Pacific Time format?"
3. **Verify the format**: Should match `yyyy-mm-dd-hhmmss-pst`
4. **Compare with command**: Run `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"` in terminal
5. **They should match**: The AI's response should match the terminal output

### Common Issues

**Issue**: AI generates wrong timezone
- **Solution**: Make sure the memory is set correctly and includes `TZ=America/Los_Angeles`

**Issue**: AI generates wrong format
- **Solution**: Check that the memory content includes the exact format specification

**Issue**: Timestamp is off by hours
- **Solution**: Verify you're using `TZ=America/Los_Angeles` in the command, not your system timezone

---

## For Agent Coordinators

**If you're coordinating multiple agents or sub-agents**:

1. **Share this prompt** with all agents/sub-agents under your coordination
2. **Verify they've set the memory** by asking them to generate a test timestamp
3. **Check their documents** to ensure timestamps are in the correct format
4. **Remind agents** to use the timestamp format when creating new documents

---

## Reference Document

For detailed reference information, see:
- `docs/timestamp_format_reference.md` - Complete timestamp format reference

---

## Action Items

**For All Agents and Sub-Agents**:

1. ⏳ **Read this prompt** (you're doing this now)
2. ⏳ **Set Cursor memory** using the instructions above
3. ⏳ **Verify memory works** by asking Cursor AI for a timestamp
4. ⏳ **Use the format** for all new documents and code files going forward
5. ⏳ **Update existing documents** if you notice incorrect timestamps

**Timeline**: Complete this setup **immediately** (within your next work session)

---

## Summary

**What to Do**:
1. Set Cursor memory with the exact content provided above
2. Always use `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"` to generate timestamps
3. Use the format `yyyy-mm-dd-hhmmss-pst` for all new documents and code files

**Why**:
- Ensures accuracy and consistency across all agents
- Prevents timezone calculation errors
- Maintains proper documentation standards

**When**:
- Every time you create a new document
- Every time you update a document's date
- Every time you need a timestamp in code or documentation

---

**Date**: 2026-01-01-075058-pst  
**Status**: Prompt Ready for Distribution  
**Next Steps**: All agents and sub-agents set Cursor memories and begin using the format

---

## Quick Reference Card

**Command**:
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

**Format**: `yyyy-mm-dd-hhmmss-pst`

**Example**: `2026-01-01-075058-pst`

**Memory Title**: `Timestamp Format - Los Angeles/Pacific Time`

**Use For**: All new documents, code files, git commits, filenames with timestamps

---

**Copy this entire document and share with all agents and sub-agents under your coordination.**
