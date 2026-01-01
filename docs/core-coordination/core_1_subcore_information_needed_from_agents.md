# Core 1 Subcore: Information Needed from Agents

**Date**: 2026-01-01-093745-pst  
**Purpose**: Clear checklist of what Core 1 Subcore needs to know from each agent/sub-agent group  
**For**: Core 1 Subcore Agent (L1 Subcore Coordinator)

---

## Information Needed by Group

### From L2 Sub-Agents (1a, 1b, 1c, 1d)

#### From Network Agent (1b) - ✅ Storage ↔ Network Integration COMPLETE

**Status**: ✅ **INTEGRATION 100% COMPLETE** - Ready for Testing

**What's Already Known**:
- ✅ Storage ↔ Network integration implementation complete
- ✅ HTTP server endpoints implemented (POST /api/files/upload, GET /api/files/{id}/download, GET /api/files/{transfer_id}/progress)
- ✅ HTTP client methods implemented (upload_file, download_file)
- ✅ Integration helpers available
- ✅ All modules ready and integrated

**Still Need to Know** (for testing/next steps):

1. **Test Execution Status**:
   - Has end-to-end testing been completed?
   - Are there any test failures or issues discovered?
   - What test results do you have?

2. **Production Readiness**:
   - Is the integration ready for production use?
   - Are there any remaining issues or concerns?
   - What's needed before production deployment?

3. **Auth Agent Integration Readiness** (for middleware):
   - When will you be ready for Auth ↔ Network middleware integration?
   - What's your current priority/availability?
   - Any blockers preventing middleware work?

---

#### From Auth Agent (1a) - ✅ Auth ↔ Network Integration READY

**Status**: ✅ **MIDDLEWARE INTEGRATION READY** — Detailed response provided

**Response Document**: `docs/agent-communications/core_1a_auth_middleware_readiness_response_2026-01-01-085326-pst.md`

**Answers**:

1. **Middleware Readiness**: ✅ **READY NOW**
   - Can begin middleware integration immediately
   - Current priority: **HIGH** — Middleware integration is top priority
   - Bandwidth: **100% AVAILABLE** — Ready to focus on middleware work

2. **Middleware API Design**: ✅ **PATTERNS DEFINED**
   - Preferred pattern: Context-based middleware (Option A)
   - Function signature: `fn middleware(request, response, ctx) bool`
   - Context includes: `AuthService`, `current_time`, `user_id`, `roles`
   - 5 middleware functions needed: JWT auth, CSRF, rate limiting, RBAC, API key

3. **Integration Requirements**: ✅ **DOCUMENTED**
   - AuthService instance passed via middleware context
   - Current time generated once per request
   - User context (user_id, roles) stored in request context
   - Error format: `{"error": "error_type", "message": "description"}`
   - Performance: JWT < 1ms, rate limiting < 0.1ms

4. **Timeline**: ✅ **READY TO BEGIN**
   - Can start API contract design **TODAY**
   - Week 1: API contract design
   - Week 2-3: Implementation
   - Week 4: Integration testing
   - Total: 4 weeks to production-ready middleware

**Questions for Network Agent (1b)**:
- How should `AuthService` instance be passed to middleware?
- How should request context be structured for handlers?
- What's the preferred middleware execution order?
- What error response format is preferred?

**Action Needed**: Facilitate middleware API contract design session between Auth Agent (1a) and Network Agent (1b)

---

#### From Storage Agent (1c) - ✅ Integration COMPLETE

**Status**: ✅ **STORAGE ↔ NETWORK INTEGRATION 100% COMPLETE**

**What's Already Known**:
- ✅ File Transfer API implemented and integrated
- ✅ MIME Type Detection integrated
- ✅ All integration requirements met
- ✅ Integration implementation complete

**Still Need to Know** (if any issues arise):
- Test execution results (if any failures)
- Any post-integration issues or concerns
- Production readiness status

---

#### From Compositor Agent (1d) - General Coordination

**Questions** (for general coordination):

1. **Current Status**:
   - What's your current phase/status?
   - What are you working on now?
   - Any blockers or dependencies?

2. **Integration Readiness**:
   - When will you be ready for Compositor ↔ Storage integration (workspace state)?
   - What workspace state persistence features do you need?
   - What's your timeline for workspace state integration?

3. **Coordination Needs**:
   - Do you need any architecture decisions from Core 1 Subcore?
   - Are there any coordination requests you have?
   - How can Core 1 Subcore support your work?

---

### From Non-Core, Non-Aurora Agents (Parallel Development Prompt)

**Questions** (via the parallel development prompt - responses due 2026-01-08):

1. **Parallel Development Ideas**:
   - How can your agent work in parallel with Core and Aurora system work?
   - What opportunities exist for parallel work?
   - How can your agent complement Core/Aurora work?

2. **Design Ideas**:
   - What design patterns enhance Core/Aurora capabilities?
   - What APIs/interfaces make Core/Aurora work easier?
   - What features boost Core/Aurora performance/usability?

3. **Vantage Compatibility**:
   - How can your agent ensure Vantage compatibility (ARM64, x86_64 AMD, x86_64 Intel, including legacy hardware)?
   - What design patterns work for macOS Vantage and NixOS Vantage?
   - What APIs abstract platform differences?

4. **Dispatch Software Support**:
   - How can your agent support first-responder systems?
   - What features/APIs can you provide for real-time dispatch systems?
   - How can your agent support touch-screen interfaces?
   - What contributions can you make to vehicle integration?

**Response Format**: Already provided in parallel development prompt document  
**Deadline**: 2026-01-08-081614-pst (1 week)

---

### From Vantage 3 Subcore L2 Sub-Agents (via Parallel Development Prompt)

**Special Focus Questions**:

#### From 3b. VM Runtime Agent (L2):
1. **JIT Compilation Design**:
   - How can you design JIT to support ARM64, x86_64 AMD, and x86_64 Intel (including legacy hardware)?
   - What architecture abstractions can you create for AMD vs Intel x86_64?
   - How can you optimize for real-time dispatch systems (including legacy hardware)?
   - What NixOS integration patterns can you use?

2. **Legacy Hardware Support**:
   - How can you ensure compatibility with older Intel x86_64 hardware?
   - What are the key differences between AMD and Intel x86_64 for JIT translation?
   - What performance considerations are there for legacy hardware?

#### From 3c. System Integration Agent (L2):
1. **Testing Strategy**:
   - How can you test ARM64, x86_64 AMD, and x86_64 Intel architectures (including legacy hardware)?
   - What NixOS integration patterns can you validate?
   - How can you test real-time dispatch systems (including legacy hardware)?
   - How can you validate compatibility with older Intel x86_64 hardware?

---

## Information Collection Workflow

### For Immediate Needs (Network Agent - Storage Integration)

1. **Forward coordination message** to Network Agent (1b)
2. **Ask the questions above** (or wait for their response to coordination message)
3. **Document their responses** in coordination doc
4. **Make integration decisions** based on their responses
5. **Facilitate integration work** between Storage and Network Agents

### For Parallel Development Prompt Responses

1. **Share parallel development prompt** with all non-Core, non-Aurora agents
2. **Wait for responses** (deadline: 2026-01-08)
3. **Review responses** when received
4. **Synthesize findings** and identify opportunities
5. **Create implementation plans** based on responses

### For General Coordination (Auth, Compositor Agents)

1. **Review their coordination docs** regularly (weekly/bi-weekly)
2. **Ask questions** as needed via coordination messages
3. **Document responses** in Core 1 Subcore coordination doc
4. **Make architecture decisions** based on information gathered

---

## Quick Reference: Where to Find Information

### L2 Sub-Agent Coordination Documents
- **Auth Agent (1a)**: `docs/core-coordination/core_1a_auth_coordination.md`
- **Network Agent (1b)**: `docs/core-coordination/core_1b_network_coordination.md`
- **Storage Agent (1c)**: `docs/core-coordination/core_1c_storage_coordination.md`
- **Compositor Agent (1d)**: `docs/core-coordination/core_1d_compositor_coordination.md`

### Storage ↔ Network Integration Documents
- **Storage Agent Request**: `docs/core-coordination/core_1c_storage_network_coordination_summary.md`
- **Network Agent Response**: `docs/core-coordination/core_1b_network_storage_integration_response.md` (if exists)
- **Integration Status**: Check coordination docs for latest status

### Parallel Development Prompt
- **Prompt Document**: `docs/agent-communications/non_core_aurora_parallel_development_prompt_2026-01-01-081614-pst.md`
- **Responses**: Review agent coordination docs after 2026-01-08

---

## Priority Order for Information Collection

### ⚠️ HIGH PRIORITY (Do This Week)

1. **Auth Agent (1a) - Middleware Integration** ⚠️ **CURRENT PRIORITY**
   - Review coordination doc for current status
   - Assess middleware integration readiness
   - Plan Auth ↔ Network integration timeline
   - Get answers to middleware readiness questions

2. **Network Agent (1b) - Test Results** (if not already known)
   - Check test execution status for Storage ↔ Network integration
   - Review any test results or issues
   - Confirm production readiness

3. **Compositor Agent (1d) - General Status**
   - Review coordination doc for current status
   - Assess workspace state integration readiness
   - Plan Compositor ↔ Storage integration timeline

### MEDIUM PRIORITY (This Week)

4. **Share Parallel Development Prompt**
   - Distribute to all non-Core, non-Aurora agents
   - Set deadline expectations (2026-01-08)

### LOWER PRIORITY (After Responses Received)

5. **Review Parallel Development Responses**
   - After 2026-01-08 deadline
   - Synthesize findings
   - Create implementation plans

---

## Summary

**What Core 1 Subcore Still Needs to Know** (Updated 2026-01-01):

1. ✅ **Storage ↔ Network Integration**: **COMPLETE** - No longer needed
2. **From Auth Agent (1a)**: ⚠️ **CURRENT PRIORITY** - Middleware readiness, API design preferences, timeline for Auth ↔ Network integration
3. **From Network Agent (1b)**: Test execution results, production readiness for Storage ↔ Network integration
4. **From Compositor Agent (1d)**: Current status, integration readiness, workspace state requirements
5. **From Non-Core Agents**: Parallel development ideas, design contributions, Vantage compatibility, dispatch support (via prompt responses - deadline: 2026-01-08)

**How to Get This Information**:
- **L2 Sub-Agents**: Read coordination docs, ask questions directly
- **Non-Core Agents**: Responses due 2026-01-08 from parallel development prompt

**Current Priority**: Focus on Auth Agent (1a) middleware integration planning - Storage ↔ Network integration is complete

---

**Last Updated**: 2026-01-01-093745-pst (Updated: Storage ↔ Network integration marked complete)  
**Status**: Active checklist for Core 1 Subcore coordination

---

## Recent Updates (2026-01-01)

### ✅ Storage ↔ Network Integration: COMPLETE

**Status Change**: Storage ↔ Network integration is now **100% COMPLETE**
- ✅ HTTP server endpoints implemented
- ✅ HTTP client methods implemented  
- ✅ Integration helpers available
- ✅ Ready for testing

**Impact**: No longer need integration readiness questions from Network Agent (1b) for Storage integration - integration is done!

**Next Steps**: 
- Check test execution status
- Plan Auth ↔ Network middleware integration (new priority)
