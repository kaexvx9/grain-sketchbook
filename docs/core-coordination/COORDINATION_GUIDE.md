# Two-Agent Coordination Pattern: Complete Guide

**Date**: 2026-01-23-160000-pst  
**Purpose**: Complete guide for Core 1 and Vantage 3 Subcore coordination

---

## Overview

This coordination pattern enables two Cursor CLI agents to work in parallel:
- **Core 1 Subcore**: Top-down Rye Style conversion (Terminal 1)
- **Vantage 3 Subcore**: Bottom-up Rye compiler fork development (Terminal 2)

Both agents share context, coordinate progress, and communicate through a structured system.

---

## Quick Start

### Terminal 1: Core 1 Subcore

```bash
cd /home/xy/ry
./docs/core-coordination/setup-core1-agent.sh
```

The script will:
- Display current status
- Show key files and documentation
- Provide the agent prompt to use with Cursor CLI

### Terminal 2: Vantage 3 Subcore

```bash
cd /home/xy/codeberg/ryelang/rye
/home/xy/ry/docs/core-coordination/setup-vantage3-agent.sh
```

The script will:
- Display current status
- Show key files and documentation
- Provide the agent prompt to use with Cursor CLI

---

## File Structure

```
docs/core-coordination/
├── shared-context.md              # Shared context for both agents
├── core1-progress.md              # Core 1 progress tracking
├── vantage3-progress.md           # Vantage 3 progress tracking
├── core1-agent-context.md         # Core 1 full context
├── vantage3-agent-context.md      # Vantage 3 full context
├── setup-core1-agent.sh           # Core 1 setup script
├── setup-vantage3-agent.sh        # Vantage 3 setup script
├── agent-messages/                # Direct communication channel
│   └── README.md                  # Message format guide
└── COORDINATION_GUIDE.md          # This file
```

---

## Coordination System

### 1. Shared Context

**File**: `docs/core-coordination/shared-context.md`

**Purpose**: Single source of truth for:
- Rye Style constraints
- Basin kernel goals
- Repository structure
- Coordination pattern
- Timeline and integration points

**Usage**: Both agents should read this file at the start of each session.

---

### 2. Progress Tracking

**Core 1**: `docs/core-coordination/core1-progress.md`  
**Vantage 3**: `docs/core-coordination/vantage3-progress.md`

**Purpose**: Track current status, completed work, and next steps.

**Usage**:
- Each agent updates their own progress file
- Both agents read each other's progress file
- Update when completing modules/phases

---

### 3. Agent Context Files

**Core 1**: `docs/core-coordination/core1-agent-context.md`  
**Vantage 3**: `docs/core-coordination/vantage3-agent-context.md`

**Purpose**: Complete context for each agent including:
- Role and responsibilities
- Current status
- Workflow
- Success criteria

**Usage**: Reference when starting a new session or when context is needed.

---

### 4. Communication Channel

**Directory**: `docs/core-coordination/agent-messages/`

**Purpose**: Direct agent-to-agent communication.

**Message Format**: `YYYY-MM-DD-HHMMSS-pst_agent-name_message-type.md`

**Message Types**:
- `status-update` - Progress or status update
- `question` - Question for the other agent
- `coordination-request` - Request for coordination on shared work
- `blocking-issue` - Issue that blocks progress
- `integration-ready` - Ready for integration work
- `general` - General communication

**Usage**:
- Create a message file when you need to communicate
- Check the directory regularly for new messages
- Archive completed messages to `archive/` subdirectory

---

## Workflow

### Starting a Session

1. **Read Shared Context**
   ```bash
   cat docs/core-coordination/shared-context.md
   ```

2. **Check Your Progress**
   - Core 1: `cat docs/core-coordination/core1-progress.md`
   - Vantage 3: `cat docs/core-coordination/vantage3-progress.md`

3. **Check Other Agent's Progress**
   - Core 1: `cat docs/core-coordination/vantage3-progress.md`
   - Vantage 3: `cat docs/core-coordination/core1-progress.md`

4. **Check for Messages**
   ```bash
   ls -lt docs/core-coordination/agent-messages/ | head -5
   ```

5. **Start Working**
   - Use the prompt from the setup script
   - Reference your agent context file as needed

---

### During Work

1. **Update Progress Regularly**
   - When completing modules/phases
   - When encountering blockers
   - When status changes significantly

2. **Coordinate When Needed**
   - Create a message if you need to communicate
   - Check for messages periodically
   - Update shared documentation carefully

3. **Prevent Conflicts**
   - Core 1 works in `/home/xy/ry/src/grain_skate/` (monorepo)
   - Vantage 3 works in `/home/xy/codeberg/ryelang/rye` (external repo)
   - Shared docs in `/home/xy/ry/docs/` (monorepo)
   - Check other agent's progress before updating shared docs

---

### Ending a Session

1. **Update Your Progress File**
   - Current status
   - Completed work
   - Next steps

2. **Send Status Update** (if significant progress)
   - Create a message in `agent-messages/`
   - Type: `status-update`

3. **Commit Changes** (if applicable)
   - Core 1: Commit in monorepo
   - Vantage 3: Commit in external repo

---

## Best Practices

### Context Sharing
- ✅ Always read shared context at session start
- ✅ Update progress files regularly
- ✅ Check other agent's progress before major changes
- ❌ Don't assume the other agent knows your current status

### Communication
- ✅ Be specific (file paths, line numbers, clear descriptions)
- ✅ Reference relevant documentation
- ✅ Update progress after sending messages
- ✅ Check messages directory regularly
- ❌ Don't send vague or unclear messages

### Conflict Prevention
- ✅ Work in separate directories (monorepo vs external repo)
- ✅ Check other agent's progress before updating shared docs
- ✅ Use messages for coordination on shared work
- ❌ Don't modify files the other agent is actively working on

### Progress Tracking
- ✅ Update progress when completing work
- ✅ Include specific details (module names, phase numbers)
- ✅ Note blockers or issues
- ❌ Don't leave progress files stale

---

## Integration Point

**Timeline**: Week 9+ (when Phase 3 stdlib is complete)

**What Happens**:
- Core 1 will have Rye Style compliant code ready
- Vantage 3 will have stable Rye compiler with basic stdlib
- Smooth transition from Zig compiler to Rye compiler

**Preparation**:
- Core 1: Continue converting modules, ensure Rye Style compliance
- Vantage 3: Complete Phase 2/3, test with Basin kernel
- Both: Monitor progress, coordinate through messages

---

## Troubleshooting

### Agent Can't Find Files
- Check working directory matches setup script
- Verify file paths are absolute or relative to working directory
- Core 1: `/home/xy/ry`
- Vantage 3: `/home/xy/codeberg/ryelang/rye`

### Progress Files Out of Sync
- Read the other agent's progress file
- Check for recent messages
- Update your progress file with current status

### Communication Issues
- Check `agent-messages/` directory for new messages
- Verify message format matches README
- Create a new message if needed

### Context Confusion
- Re-read `shared-context.md`
- Check your agent context file
- Review recent progress updates

---

## Success Criteria

✅ Coordination pattern works when:
- Both agents can work independently without conflicts
- Both agents are aware of shared context (Rye Style, Basin goals)
- Progress updates are synchronized
- Coordination documents stay current
- No file conflicts or overwrites
- Both agents can reference each other's work

---

## Next Steps

1. **Run Setup Scripts**
   - Terminal 1: `./docs/core-coordination/setup-core1-agent.sh`
   - Terminal 2: `./docs/core-coordination/setup-vantage3-agent.sh`

2. **Start Working**
   - Use the prompts provided by the setup scripts
   - Reference agent context files as needed

3. **Monitor Progress**
   - Update progress files regularly
   - Check for messages periodically
   - Coordinate when needed

---

**Status**: ✅ **READY** — Two-agent coordination pattern is set up and ready to use

**Last Updated**: 2026-01-23-160000-pst
