# Agent Messages Directory

**Purpose**: Direct communication channel between Core 1 Subcore and Vantage 3 Subcore

---

## Message Format

**Filename**: `YYYY-MM-DD-HHMMSS-pst_agent-name_message-type.md`

**Agent Names**:
- `core1` - Core 1 Subcore
- `vantage3` - Vantage 3 Subcore

**Message Types**:
- `status-update` - Progress or status update
- `question` - Question for the other agent
- `coordination-request` - Request for coordination on shared work
- `blocking-issue` - Issue that blocks progress
- `integration-ready` - Ready for integration work
- `general` - General communication

---

## Example Messages

### Status Update
```
# Status Update: Phase 2 Complete

**From**: Vantage 3 Subcore  
**Date**: 2026-01-23-170000-pst  
**Type**: status-update

Phase 2 is now 100% complete. All RISC-V freestanding fixes verified in kernel.
Moving to Phase 3 stdlib implementation.
```

### Question
```
# Question: Rye Style Function Limit

**From**: Core 1 Subcore  
**Date**: 2026-01-23-171000-pst  
**Type**: question

When refactoring functions > 64 lines, should helper functions be private or public?
Does the 64-line limit apply to helper functions as well?
```

### Coordination Request
```
# Coordination Request: Shared Documentation Update

**From**: Vantage 3 Subcore  
**Date**: 2026-01-23-172000-pst  
**Type**: coordination-request

I need to update `docs/rye/0014-toroidal-garden-stdlib-spec.md` with Phase 3 completion details.
Can Core 1 review before I commit?
```

---

## Best Practices

1. **Be Specific**: Include file paths, line numbers, and clear descriptions
2. **Reference Context**: Link to relevant documentation or progress files
3. **Update Progress**: After sending a message, update your progress file
4. **Check Regularly**: Both agents should check this directory regularly
5. **Archive Old Messages**: Move completed messages to `archive/` subdirectory

---

**Status**: ✅ **ACTIVE** — Use this directory for agent-to-agent communication
