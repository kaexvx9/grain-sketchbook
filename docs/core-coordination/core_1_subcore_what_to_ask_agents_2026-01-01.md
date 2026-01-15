# Core 1 Subcore: What to Ask Each Agent

**Date**: 2026-01-01-081614-pst  
**Agent**: Grain Core 1 Subcore Agent (L1 Subcore)  
**Purpose**: Clear list of specific questions to ask each agent

---

## Immediate: Network ↔ Storage Integration

### From 1b. Network Agent (L2 Sub-Agent)

**Status**: Network Agent has already responded with integration design ✅

**What Core 1 Subcore Still Needs to Know**:

1. **Integration Questions for Storage Agent**:
   - Network Agent has 4 specific questions for Storage Agent:
     - File ID format (UUID string, integer, or path?)
     - File ID to path mapping API
     - File size retrieval API
     - File write/read operation details
   
   **Action**: Forward Network Agent's questions to Storage Agent (1c)

2. **Timeline Confirmation**:
   - ⏳ When can Network Agent begin implementation?
   - ⏳ How long will implementation take?
   - ⏳ Are there any blockers?

**Questions to Ask Network Agent**:
1. "Do you have any blockers preventing you from starting integration work?"
2. "What's your estimated timeline for completing the integration?"
3. "Do you need any additional information from Storage Agent beyond the 4 questions you've already asked?"

---

### From 1c. Storage Agent (L2 Sub-Agent)

**Status**: Storage Agent has provided comprehensive information ✅

**What Core 1 Subcore Needs to Know**:

1. **Answer Network Agent's 4 Questions**:
   - ⏳ **Question 1**: File ID format - What format should `file_id` be? (UUID string, integer, or use file path directly?)
   - ⏳ **Question 2**: File ID to path mapping - Does Storage Agent have an API to map `file_id` to file path? What's the signature?
   - ⏳ **Question 3**: File size retrieval - What API should Network Agent use to get file size?
   - ⏳ **Question 4**: File write/read operations - Confirm `IntegratedFileIO.write_file()` and `read_file()` signatures, and how to get user_id/group_id from HTTP request?

2. **Clarifications** (if needed):
   - ⏳ Any concerns about Network Agent's proposed integration approach?
   - ⏳ Any additional requirements or constraints?

**Questions to Ask Storage Agent**:
1. "Can you answer Network Agent's 4 integration questions?" (see `core_1b_network_storage_integration_questions.md`)
2. "Do you have any concerns about Network Agent's integration design?"
3. "Is there anything else Network Agent needs to know?"

---

## This Week: Parallel Development Prompt

### From All Non-Core, Non-Aurora Agents

**What Core 1 Subcore Needs to Know** (6 categories):

1. **Parallel Development Ideas**:
   - ⏳ How can your agent work in parallel with Core and Aurora system work?
   - ⏳ What opportunities exist for parallel work?
   - ⏳ How can your agent complement Core/Aurora work?

2. **Design Ideas**:
   - ⏳ Design patterns that enhance Core/Aurora capabilities
   - ⏳ APIs or interfaces that make Core/Aurora work easier
   - ⏳ Features that boost Core/Aurora system performance or usability
   - ⏳ Integration opportunities that create synergies

3. **Vantage Compatibility**:
   - ⏳ How can your agent ensure Vantage compatibility (ARM64, x86_64 AMD, x86_64 Intel, including legacy hardware)?
   - ⏳ Design patterns that work for both macOS Vantage and NixOS Vantage
   - ⏳ APIs that abstract platform differences
   - ⏳ Testing strategies that validate Vantage compatibility

4. **Vantage Secondary Output Pipeline (RISC-V to x86_64)**:
   - ⏳ Design patterns that work for all architectures (including legacy Intel hardware)
   - ⏳ APIs that abstract architecture differences
   - ⏳ Testing strategies for all target architectures
   - ⏳ Contributions to NixOS support
   - ⏳ Legacy hardware compatibility considerations

5. **Dispatch Software Objectives**:
   - ⏳ Features that support first-responder systems
   - ⏳ APIs for real-time dispatch systems
   - ⏳ Touch-screen interface support
   - ⏳ Vehicle integration support
   - ⏳ Data management and reporting for dispatch systems

6. **Spiritual Protection Vision Alignment**:
   - ⏳ How does your agent's work serve others?
   - ⏳ How does your agent enhance freedom?
   - ⏳ How does your agent support protection through engagement?
   - ⏳ How does your agent contribute to the transformation of reality?

**Response Format**: Use the format in `docs/agent-communications/non_core_aurora_parallel_development_prompt_2026-01-01-081614-pst.md`

**Response Deadline**: 2026-01-08-081614-pst (1 week)

**Questions to Ask**:
1. "Can you provide responses to the parallel development prompt by 2026-01-08?"
2. "Do you have any questions about the prompt or requirements?"

---

## This Week: Timestamp Memory Setup

### From All L2 Sub-Agents (1a, 1b, 1c, 1d)

**What Core 1 Subcore Needs to Know**:

1. **Confirmation**:
   - ⏳ Have you set the Cursor memory for timestamp format?
   - ⏳ Can you generate a test timestamp to verify it's working?

**Questions to Ask**:
1. "Have you set the timestamp memory in Cursor?"
2. "Can you generate a test timestamp to confirm it's working?"

---

## Summary: Specific Questions by Agent

### 1b. Network Agent (L2 Sub-Agent) - HIGH PRIORITY

**Questions**:
1. "Do you have any blockers preventing you from starting integration work?"
2. "What's your estimated timeline for completing the integration?"
3. "Do you need any additional information from Storage Agent beyond the 4 questions you've already asked?"

**Action**: These are follow-up questions after Network Agent's initial response.

---

### 1c. Storage Agent (L2 Sub-Agent) - HIGH PRIORITY

**Questions** (Network Agent's 4 questions):
1. **File ID Format**: What format should `file_id` be in the download endpoint? (string, UUID, integer, or use file path directly?)
2. **File ID to Path Mapping**: Does Storage Agent have an API to map `file_id` to file path? What's the API signature?
3. **File Size Retrieval**: What API should Network Agent use to get file size? (`get_file_size(file_path)` or `get_file_size_by_id(file_id)`?)
4. **File Write/Read Operations**: 
   - Confirm `IntegratedFileIO.write_file()` and `read_file()` signatures
   - How should Network Agent get `user_id`/`group_id` from HTTP request?
   - Does Storage Agent support chunked reading for large files?

**Action**: Forward Network Agent's questions document to Storage Agent and ask for answers.

---

### All Non-Core, Non-Aurora Agents - MEDIUM PRIORITY

**Questions**:
1. "Can you provide responses to the parallel development prompt by 2026-01-08?"
2. "Do you have any questions about the prompt or requirements?"

**Action**: Share the parallel development prompt document and ask for responses.

---

### All L2 Sub-Agents (1a, 1b, 1c, 1d) - LOW PRIORITY

**Questions**:
1. "Have you set the timestamp memory in Cursor?"
2. "Can you generate a test timestamp to confirm it's working?"

**Action**: Share the timestamp memory setup document and ask for confirmation.

---

## Priority Order

### Today (HIGH PRIORITY)

1. **Ask Storage Agent (1c)**: Answer Network Agent's 4 integration questions
2. **Ask Network Agent (1b)**: Timeline and blocker confirmation

### This Week (MEDIUM PRIORITY)

3. **Ask All Non-Core, Non-Aurora Agents**: Provide parallel development responses
4. **Ask All L2 Sub-Agents**: Confirm timestamp memory setup

---

**Date**: 2026-01-01-081614-pst  
**Status**: ✅ Questions Documented  
**Next Action**: Ask Storage Agent to answer Network Agent's 4 integration questions
