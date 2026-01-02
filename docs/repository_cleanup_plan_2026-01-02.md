# Repository Cleanup Plan: Archaeology Organization

**Date**: 2026-01-02  
**Agent**: Grain Basin Kernel Agent (3a)  
**Status**: Ready for Execution  
**Purpose**: Clean up repository, archive historical files, maintain active work visible

---

## Philosophy: "Does It Spark Joy?"

**Keep Active**: Current work, recent coordination (last 2-3 weeks), active references  
**Archive**: Historical value, completed work, old coordination (older than 2 weeks)  
**Remove**: Duplicates, temporary files, build artifacts (git history preserves)

---

## Cleanup Categories

### 1. Session Summaries → Archive

**Location**: `docs/kernel/session_summary_*.md`  
**Action**: Move to `archaeology/docs/kernel/session_summaries/`

**Files**:
- `docs/kernel/session_summary_2026-01-02-100345-pst.md` (current session)

**Rationale**: Session summaries are historical records, not active references. Keep in archaeology for future reference.

---

### 2. Old Agent Communications → Archive

**Location**: `docs/agent-communications/*2025-*.md`  
**Action**: Move files older than 2 weeks to `archaeology/docs/agent-communications/2025-archive/`

**Criteria**:
- Files from 2025 (older than 2 weeks from today: 2026-01-02)
- Completed coordination work
- Superseded by newer documents

**Keep Active** (2026-01-02 and recent):
- Files from 2026-01-01 and 2026-01-02
- Active coordination documents
- Critical path coordination

**Rationale**: Recent coordination is active, older coordination is historical.

---

### 3. Old Agent Prompts → Archive

**Location**: `docs/*_agent_*_prompt.md`  
**Action**: Move superseded prompts to `archaeology/docs/legacy_prompts/`

**Files to Archive** (if superseded):
- Old agent prompts that have been replaced
- Prompts for agents that have been renamed
- Prompts for completed phases

**Keep Active**:
- Current agent prompts
- Active reference prompts

**Rationale**: Old prompts are historical, current prompts are active references.

---

### 4. Old Coordination Documents → Archive

**Location**: `docs/core-coordination/`  
**Action**: Move completed/superseded coordination to `archaeology/docs/legacy_coordination/`

**Criteria**:
- Completed coordination work
- Superseded by newer coordination documents
- Historical status updates

**Keep Active**:
- Current coordination documents
- Active system integration plans
- Recent coordination summaries

---

### 5. Root Directory Cleanup

**Action**: Remove temporary files and build artifacts

**Files to Remove** (if they exist):
- `build.zig.backup`
- `build.zig.old2`
- `test_*.zig` (temporary test files)
- `lib*.a` (build artifacts, should be in zig-out/)
- Executables in root (should be in zig-out/)

**Rationale**: Build artifacts and temporary files clutter the root directory.

---

## Implementation Plan

### Phase 1: Create Archaeology Structure
1. Create `archaeology/docs/kernel/session_summaries/`
2. Create `archaeology/docs/agent-communications/2025-archive/`
3. Create `archaeology/docs/legacy_prompts/` (if not exists)
4. Create `archaeology/docs/legacy_coordination/` (if not exists)

### Phase 2: Archive Session Summaries
1. Move `docs/kernel/session_summary_*.md` to archaeology
2. Document move in archaeology README

### Phase 3: Archive Old Agent Communications
1. Identify files from 2025 (older than 2 weeks)
2. Move to `archaeology/docs/agent-communications/2025-archive/`
3. Keep 2026 files active

### Phase 4: Archive Old Prompts
1. Identify superseded agent prompts
2. Move to `archaeology/docs/legacy_prompts/`
3. Keep current prompts active

### Phase 5: Root Directory Cleanup
1. Remove backup files
2. Remove temporary test files
3. Remove build artifacts
4. Update `.gitignore` if needed

### Phase 6: Verification
1. Verify no broken references
2. Update documentation if needed
3. Commit with clear organization message

---

## Benefits

1. **Clarity**: Only active files visible, easier to navigate
2. **Maintenance**: Less clutter, easier to find what you need
3. **History**: Git preserves everything, archaeology keeps it organized
4. **Joy**: Clean, purposeful organization sparks joy! ✨

---

## Files to Keep Active (Spark Joy) ✨

**Root**:
- `build.zig`, `build.zig.zon`, `readme.md`, `changelog.md`
- Active scripts and tools

**Docs Root**:
- `grain_style.md`, `gratitude.md`, `don_juan_matus_warriors_way.md`
- `plan.md`, `tasks.md`
- Active reference documents

**Agent Communications**:
- Files from 2026-01-01 and 2026-01-02
- Active coordination documents
- Critical path coordination

---

## Files to Archive (Historical Value) 📦

**Move to `archaeology/`**:
- Session summaries
- Old agent communications (2025, older than 2 weeks)
- Superseded agent prompts
- Completed coordination work

---

## Files to Remove (No Joy) 🗑️

**Delete** (git history preserves):
- Backup files (`.backup`, `.old*`)
- Temporary test files
- Build artifacts (should be gitignored)
- Duplicate files

---

**Status**: Ready for execution  
**Next Step**: Execute Phase 1 (Create Archaeology Structure)

