# Core 1 Subcore: Immediate Action Guide

**Date**: 2026-01-01-075058-pst  
**Agent**: Grain Core 1 Subcore Agent (L1 Subcore)  
**Purpose**: Clear, step-by-step guide for immediate actions

---

## What to Do Right Now

### ⚠️ HIGH PRIORITY: Facilitate 1b Network ↔ 1c Storage Integration

**Status**: 1c. Storage Agent (L2 Sub-Agent) is **ready and waiting** for coordination.

---

## Step-by-Step Action Plan

### Step 1: Review Storage Agent's Coordination Request (15 minutes)

**Read these documents**:
1. `docs/core-coordination/core_1c_storage_status_update_for_core_1_subcore.md`
   - Quick status summary
   - What Storage Agent has ready
   - What Storage Agent needs

2. `docs/core-coordination/core_1c_storage_network_coordination_summary.md`
   - Copy-paste ready messages
   - Integration requirements
   - API documentation

**What you'll learn**:
- Storage Agent has File Transfer API ready
- Network Agent has all required modules (connection_pool, chunked_transfer, content_negotiation)
- Both agents are ready for integration

---

### Step 2: Forward Coordination Message to Network Agent (5 minutes)

**Action**: Copy and forward the coordination message to 1b. Network Agent (L2 Sub-Agent)

**Where to find it**:
- Document: `docs/core-coordination/core_1c_storage_network_coordination_summary.md`
- Section: "Message 2: To Network Agent (1b) (via Core 1 Subcore)"
- Lines: ~91-181

**What to do**:
1. Open `docs/core-coordination/core_1c_storage_network_coordination_summary.md`
2. Find "Message 2: To Network Agent (1b)"
3. Copy the entire message (from "Hello Network Agent" through the closing)
4. Forward it to Network Agent (1b) with a note: "Facilitating coordination between Storage Agent (1c) and Network Agent (1b) for HTTP file transfer integration. Storage Agent is ready and waiting."

---

### Step 3: Review Network Agent Status (10 minutes)

**Read**: `docs/core-coordination/core_1b_network_coordination.md`

**Check**:
- Is Network Agent ready for integration work?
- Are there any blockers?
- What's their current phase status?

---

### Step 4: Design Integration Architecture (2-3 hours, can be done after Step 2)

**After both agents acknowledge**, work with them to:

1. **Define HTTP Endpoints**:
   - File upload endpoint (POST/PUT)
   - File download endpoint (GET)
   - Progress tracking endpoint (GET)

2. **Design API Contracts**:
   - Request/response formats
   - Error handling
   - Status codes

3. **Plan Integration Testing**:
   - Test scenarios
   - Test data
   - Success criteria

---

## Who to Talk To

### Immediate (Today)

1. **1b. Network Agent (L2 Sub-Agent)**
   - **Action**: Forward Storage Agent's coordination request
   - **Message**: Use copy-paste message from coordination summary
   - **Purpose**: Initiate HTTP file transfer integration

### This Week

2. **1c. Storage Agent (L2 Sub-Agent)**
   - **Action**: Acknowledge their coordination request
   - **Purpose**: Confirm you're facilitating the integration

3. **Both Agents Together** (if needed)
   - **Action**: Schedule integration planning session
   - **Purpose**: Design integration architecture together

---

## What NOT to Run Yet

**Don't run code commands yet** — this is coordination/documentation work first.

**After integration architecture is designed**, then:
- Agents will implement the integration
- You'll coordinate testing
- You'll validate the integration works

---

## Quick Reference: Documents to Read

**Must Read (Today)**:
- ✅ `docs/core-coordination/core_1c_storage_status_update_for_core_1_subcore.md`
- ✅ `docs/core-coordination/core_1c_storage_network_coordination_summary.md`
- ✅ `docs/core-coordination/core_1b_network_coordination.md`

**Reference (This Week)**:
- `docs/core-coordination/core_1c_storage_network_coordination_request.md` (detailed API docs)
- `docs/core-coordination/core_1_subcore_next_steps_recommendations_2025-12-31.md` (full recommendations)

---

## Expected Timeline

**Today**:
- ✅ Review Storage Agent documents (15 min)
- ✅ Forward message to Network Agent (5 min)
- ✅ Review Network Agent status (10 min)

**This Week**:
- ✅ Network Agent acknowledges coordination request
- ✅ Both agents align on integration approach
- ✅ Integration architecture designed

**Next Week**:
- ✅ Integration implementation begins
- ✅ Integration tests planned

---

## Success Criteria

**You'll know you're on track when**:
- ✅ Network Agent has received the coordination message
- ✅ Both agents have acknowledged the integration need
- ✅ Integration architecture is being designed
- ✅ Timeline for implementation is established

---

## Other Items (Lower Priority)

### Timestamp Memory Setup
- **Status**: Document created and ready for distribution
- **Action**: Share with all L2 sub-agents (1a, 1b, 1c, 1d) when convenient
- **Priority**: Medium (can be done this week)

### Grainscript Shell Recommendation
- **Status**: Document created for Vantage 3b VM Runtime Agent
- **Action**: Vantage 3b will review when ready (future project)
- **Priority**: Low (future work)

---

## Summary: Your Next 30 Minutes

1. **Read** `docs/core-coordination/core_1c_storage_network_coordination_summary.md` (15 min)
2. **Copy** Message 2 (To Network Agent) from that document (2 min)
3. **Forward** to Network Agent (1b) with your facilitation note (3 min)
4. **Read** `docs/core-coordination/core_1b_network_coordination.md` (10 min)

**Total Time**: ~30 minutes  
**Result**: Network ↔ Storage integration coordination initiated ✅

---

**Date**: 2026-01-01-075058-pst  
**Status**: ✅ Action Guide Ready  
**Next Action**: Forward coordination message to Network Agent (1b)
