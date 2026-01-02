# TIMESTAMP SPECIFICATION - UNIFIED PRINTOUT
## Ready for Copy-Paste Distribution to All Agents

**START_TIMESTAMP_SPECIFICATION**

---

# Timestamp Specification - Multi-Agent Prompt
## Unified Standard for All Agents and Sub-Agents

**Document Created:** 2026-01-01-230301-pst  
**Version:** 1.0  
**Status:** MANDATORY FOR ALL AGENTS

---

## Executive Summary

This document establishes the **mandatory timestamp format** for all agents (L1: 1-12) and sub-agents (L2: 1a-1d, 2a-2c, 3a-3d, 1e) working on the Grain OS development project. All timestamps must follow the specified format consistently across all artifacts: documents, filenames, git commits, code comments, logs, and any other timestamped content.

**Format:** `yyyy-mm-dd-hhmmss-pst`  
**Example:** `2026-01-01-230301-pst`  
**Timezone:** Always use PST (Pacific Standard Time), even during PDT (Pacific Daylight Time)

---

## Mandatory Timestamp Format

### Format Specification

```
Format: yyyy-mm-dd-hhmmss-pst
```

**Components:**
- `yyyy`: 4-digit year
- `mm`: 2-digit month (01-12)
- `dd`: 2-digit day (01-31)
- `hhmmss`: 6-digit time (24-hour format, no colons)
  - `hh`: 2-digit hour (00-23)
  - `mm`: 2-digit minute (00-59)
  - `ss`: 2-digit second (00-59)
- `pst`: Always use "pst" suffix (even during PDT)

### Command to Generate Timestamp

**Always use this command:**
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

**Why this command:**
- `TZ=America/Los_Angeles` ensures correct timezone handling (automatically handles PST/PDT)
- Always outputs "pst" suffix regardless of actual daylight saving time
- Consistent format across all systems

### Examples

**Valid timestamps:**
- `2026-01-01-230301-pst` (January 1, 2026, 11:03:01 PM PST)
- `2026-12-31-000000-pst` (December 31, 2026, 12:00:00 AM PST)
- `2026-06-15-143022-pst` (June 15, 2026, 2:30:22 PM PST)

**Invalid timestamps (DO NOT USE):**
- `2026-01-01-23:03:01-pst` (colons in time)
- `2026-1-1-230301-pst` (single-digit month/day)
- `2026-01-01-230301-PST` (uppercase)
- `2026-01-01-230301-pdt` (using pdt)
- `2026-01-01T23:03:01-pst` (ISO format with T)
- `2026-01-01-230301` (missing pst suffix)

---

## Usage Requirements by Artifact Type

### 1. Document Filenames

**Format:** `[document_name]_[timestamp].md`

**Examples:**
- `coordination_summary_2026-01-01-230301-pst.md`
- `agent_3b_vm_runtime_spec_2026-01-01-143022-pst.md`
- `integration_test_results_2026-01-01-091500-pst.md`

**Rules:**
- Timestamp at end of filename (before extension)
- Use underscores to separate components
- Always include timestamp for versioned documents

### 2. Git Commit Messages

**Format:** Include timestamp in commit message body

**Examples:**
```
feat: Add VM runtime initialization

Timestamp: 2026-01-01-230301-pst
Component: Agent 3b (VM Runtime)
```

```
fix: Resolve kernel memory leak

Timestamp: 2026-01-01-143022-pst
Component: Agent 3a (Basin Kernel)
Issue: #123
```

**Rules:**
- Include timestamp in commit message body (not subject line)
- Use format: `Timestamp: yyyy-mm-dd-hhmmss-pst`
- Always include component/agent identifier

### 3. Code Comments

**Format:** Use timestamp in significant code changes

**Examples:**
```c
// Updated: 2026-01-01-230301-pst
// Agent: 3a (Basin Kernel)
// Change: Optimized memory allocation
void* allocate_memory(size_t size) {
    // ...
}
```

```rust
// Timestamp: 2026-01-01-143022-pst
// Agent: 3b (VM Runtime)
// Feature: Added VM snapshot support
impl VMRuntime {
    // ...
}
```

**Rules:**
- Use for significant changes, not every line
- Include agent identifier
- Brief description of change

### 4. Log Files

**Format:** Include timestamp in log entries

**Examples:**
```
[2026-01-01-230301-pst] [Agent 3b] VM initialized successfully
[2026-01-01-230302-pst] [Agent 3c] System integration started
[2026-01-01-230303-pst] [Agent 1e] Shell session started
```

**Rules:**
- Timestamp at start of log entry
- Include agent identifier
- Consistent format across all logs

### 5. Configuration Files

**Format:** Include timestamp in configuration metadata

**Examples:**
```yaml
# Configuration generated: 2026-01-01-230301-pst
# Agent: 3c (System Integration)
system:
  services:
    - name: vm-runtime
      enabled: true
```

**Rules:**
- Timestamp in header comment
- Include agent identifier
- Document generation time

### 6. Test Results

**Format:** Include timestamp in test output

**Examples:**
```
Test Run: 2026-01-01-230301-pst
Agent: 3a (Basin Kernel)
Tests: 150 passed, 2 failed
Duration: 45.2s
```

**Rules:**
- Timestamp in test header
- Include agent identifier
- Test statistics

---

## Agent-Specific Instructions

### L1 Subcores (Agents 1, 2, 3)

**Responsibilities:**
- Ensure all sub-agents follow timestamp format
- Coordinate timestamp usage across subcore
- Validate timestamps in integration points
- Document timestamp usage in subcore documentation

**Agent 1 (Core 1 Subcore):**
- Coordinate Agents 1a-1d and 1e
- Ensure timestamp consistency in core services
- Validate timestamps in service logs

**Agent 2 (Aurora 2 Subcore):**
- Coordinate Agents 2a-2c
- Ensure timestamp format in API responses
- Validate timestamps in interface logs

**Agent 3 (Vantage 3 Subcore):**
- Coordinate Agents 3a-3d
- Ensure timestamp format in kernel logs
- Validate timestamps in system integration

### L2 Sub-Agents (1a-1d, 2a-2c, 3a-3d, 1e)

**Responsibilities:**
- Use timestamp format in all artifacts
- Include agent identifier with timestamps
- Coordinate with parent L1 agent
- Report timestamp format issues immediately

**Agent 1e (Grainscript Shell):**
- Use timestamps in shell command history
- Include timestamps in script execution logs
- Format timestamps in shell output when requested

**Agents 3a-3d (Vantage 3 components):**
- Use timestamps in kernel logs (3a)
- Include timestamps in VM runtime logs (3b)
- Format timestamps in system integration logs (3c)
- Use timestamps in init system logs (3d)

### L1 Standalone Agents (Agents 4-12)

**Responsibilities:**
- Use timestamp format in all artifacts
- Include agent identifier with timestamps
- Coordinate with System Integration (Agent 3c)
- Maintain timestamp consistency

**Special Requirements:**
- Each agent must document timestamp usage in their component
- Report any timestamp format issues to coordination
- Ensure timestamps are compatible with system integration

---

## Common Mistakes to Avoid

### ❌ DO NOT:

1. **Use different timezone formats**
   - ❌ `2026-01-01-230301-UTC`
   - ❌ `2026-01-01-230301-GMT`
   - ✅ `2026-01-01-230301-pst`

2. **Use colons in time component**
   - ❌ `2026-01-01-23:03:01-pst`
   - ✅ `2026-01-01-230301-pst`

3. **Use single-digit months/days**
   - ❌ `2026-1-1-230301-pst`
   - ✅ `2026-01-01-230301-pst`

4. **Use uppercase PST**
   - ❌ `2026-01-01-230301-PST`
   - ✅ `2026-01-01-230301-pst`

5. **Use PDT instead of PST**
   - ❌ `2026-06-15-143022-pdt`
   - ✅ `2026-06-15-143022-pst`

6. **Omit timezone suffix**
   - ❌ `2026-01-01-230301`
   - ✅ `2026-01-01-230301-pst`

7. **Use system local time without TZ**
   - ❌ `date +"%Y-%m-%d-%H%M%S-pst"` (without TZ=)
   - ✅ `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`

8. **Mix timestamp formats**
   - ❌ Using ISO format in some places, custom format in others
   - ✅ Always use `yyyy-mm-dd-hhmmss-pst` format

---

## Integration with Grain Style Principles

### Consistency
- **Principle:** Uniform timestamp format across all components
- **Implementation:** All agents use identical format and generation command
- **Verification:** Automated checks ensure format compliance

### Clarity
- **Principle:** Timestamps must be unambiguous and readable
- **Implementation:** Human-readable format with clear timezone indicator
- **Verification:** Format is self-documenting

### Traceability
- **Principle:** All artifacts must be traceable to creation time
- **Implementation:** Timestamps in all significant artifacts
- **Verification:** Timestamp presence checked in code review

### Automation
- **Principle:** Reduce manual errors through automation
- **Implementation:** Standard command for timestamp generation
- **Verification:** Scripts validate timestamp format

---

## Verification Checklist

### For All Agents

Before submitting any work, verify:

- [ ] All document filenames include timestamp in correct format
- [ ] All git commits include timestamp in message body
- [ ] Significant code changes include timestamp in comments
- [ ] All log entries use correct timestamp format
- [ ] Configuration files include generation timestamp
- [ ] Test results include timestamp in header
- [ ] Timestamp generated using: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
- [ ] Timestamp format is: `yyyy-mm-dd-hhmmss-pst`
- [ ] Timezone suffix is always "pst" (lowercase)
- [ ] Agent identifier included with timestamps where applicable

### For L1 Subcore Agents (1, 2, 3)

Additionally verify:

- [ ] All sub-agents are using correct timestamp format
- [ ] Timestamp format documented in subcore documentation
- [ ] Integration points validate timestamp format
- [ ] Subcore coordination includes timestamp validation

### For L2 Sub-Agents (1a-1d, 2a-2c, 3a-3d, 1e)

Additionally verify:

- [ ] Parent L1 agent has reviewed timestamp usage
- [ ] Timestamps compatible with subcore integration
- [ ] Agent-specific timestamp requirements documented

### For L1 Standalone Agents (4-12)

Additionally verify:

- [ ] Timestamps compatible with System Integration (Agent 3c)
- [ ] Timestamp usage documented in component documentation
- [ ] No conflicts with other agents' timestamp usage

---

## Quick Reference

### Generate Timestamp
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

### Format Pattern
```
yyyy-mm-dd-hhmmss-pst
```

### Example Output
```
2026-01-01-230301-pst
```

### Validation Regex
```regex
^\d{4}-\d{2}-\d{2}-\d{6}-pst$
```

### Common Use Cases

**Document filename:**
```bash
filename_$(TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst").md
```

**Git commit:**
```bash
git commit -m "feat: Add feature

Timestamp: $(TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst")
Component: Agent X"
```

**Code comment:**
```bash
# Updated: $(TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst")
```

**Log entry:**
```bash
echo "[$(TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst")] [Agent X] Message"
```

---

## Enforcement and Compliance

### Automated Checks
- Pre-commit hooks validate timestamp format
- CI/CD pipelines check timestamp compliance
- Documentation generators validate timestamps

### Manual Review
- Code reviews include timestamp format check
- Documentation reviews verify timestamp usage
- Integration tests validate timestamp consistency

### Reporting Issues
- Report timestamp format violations immediately
- Document any exceptions (with justification)
- Update this specification if format needs modification

### Consequences of Non-Compliance
- Work may be rejected until timestamp format corrected
- Repeated violations require coordination review
- Format inconsistencies delay integration

---

**END_TIMESTAMP_SPECIFICATION**

---

**Document Status:** MANDATORY FOR ALL AGENTS  
**Distribution:** All L1 Agents (1-12), All L2 Sub-Agents (1a-1d, 2a-2c, 3a-3d, 1e)  
**Last Updated:** 2026-01-01-230301-pst  
**Quick Command:** `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`

