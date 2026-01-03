# Plan/Tasks Documentation Migration Mapping

**Date**: 2026-01-03-052745-pst  
**Phase**: Phase 2 - Plan/Tasks Doc Migration  
**Status**: ✅ **MAPPING CREATED**

---

## Migration Mapping

### Plans: Old Format → New Format

#### ✅ New Format Exists (Can Archive Old)
- `plan_aurora.md` → `aurora_2_subcore_plan.md` ✅
- `plan_core.md` → `core_1_subcore_plan.md` ✅
- `plan_dream_editor.md` → `aurora_2a_dream_editor_plan.md` ✅
- `plan_dream_browser.md` → `aurora_2b_dream_browser_plan.md` ✅
- `plan_component_library.md` → `aurora_2c_component_library_plan.md` ✅

#### ⚠️ New Format Missing (Need to Create or Keep Old)
- `plan_bubble.md` → `bubble_agent_plan.md` ❌ (missing)
- `plan_carry.md` → `carry_agent_plan.md` ❌ (missing)
- `plan_database.md` → `silo_agent_plan.md` ❌ (missing - Silo is Agent 7, was database)
- `plan_workspace.md` → `workspace_agent_plan.md` ❌ (missing)
- `plan_flow.md` → `flow_agent_plan.md` ❌ (missing)
- `plan_research.md` → `research_agent_plan.md` ❌ (missing)
- `plan_court.md` → `court_agent_plan.md` ❌ (missing)
- `plan_skate.md` → `skate_agent_plan.md` ❌ (missing)
- `plan_ecological_printer_2025-12-21-152504-pst.md` → (special case, keep as-is or archive)

### Tasks: Old Format → New Format

#### ✅ New Format Exists (Can Archive Old)
- `tasks_aurora.md` → `aurora_2_subcore_tasks.md` ✅
- `tasks_core.md` → `core_1_subcore_tasks.md` ✅
- `tasks_dream_editor.md` → `aurora_2a_dream_editor_tasks.md` ✅
- `tasks_dream_browser.md` → `aurora_2b_dream_browser_tasks.md` ✅
- `tasks_component_library.md` → `aurora_2c_component_library_tasks.md` ✅

#### ⚠️ New Format Missing (Need to Create or Keep Old)
- `tasks_bubble.md` → `bubble_agent_tasks.md` ❌ (missing)
- `tasks_carry.md` → `carry_agent_tasks.md` ❌ (missing)
- `tasks_database.md` → `silo_agent_tasks.md` ❌ (missing - Silo is Agent 7, was database)
- `tasks_workspace.md` → `workspace_agent_tasks.md` ❌ (missing)
- `tasks_flow.md` → `flow_agent_tasks.md` ❌ (missing)
- `tasks_research.md` → `research_agent_tasks.md` ❌ (missing)
- `tasks_court.md` → `court_agent_tasks.md` ❌ (missing)
- `tasks_skate.md` → `skate_agent_tasks.md` ❌ (missing)

---

## Migration Strategy

### Step 1: Archive Old Format Docs with New Format Equivalents
Move these to `archaeology/docs/plans/legacy/` and `archaeology/docs/tasks/legacy/`:
- `plan_aurora.md` (has `aurora_2_subcore_plan.md`)
- `plan_core.md` (has `core_1_subcore_plan.md`)
- `plan_dream_editor.md` (has `aurora_2a_dream_editor_plan.md`)
- `plan_dream_browser.md` (has `aurora_2b_dream_browser_plan.md`)
- `plan_component_library.md` (has `aurora_2c_component_library_plan.md`)
- `tasks_aurora.md` (has `aurora_2_subcore_tasks.md`)
- `tasks_core.md` (has `core_1_subcore_tasks.md`)
- `tasks_dream_editor.md` (has `aurora_2a_dream_editor_tasks.md`)
- `tasks_dream_browser.md` (has `aurora_2b_dream_browser_tasks.md`)
- `tasks_component_library.md` (has `aurora_2c_component_library_plan.md`)

### Step 2: Mark Old Format Docs Without Equivalents as Deprecated
Add deprecation notice to these (they'll be migrated when agents create new-format docs):
- `plan_bubble.md`, `plan_carry.md`, `plan_database.md`, `plan_workspace.md`, `plan_flow.md`, `plan_research.md`, `plan_court.md`, `plan_skate.md`
- `tasks_bubble.md`, `tasks_carry.md`, `tasks_database.md`, `tasks_workspace.md`, `tasks_flow.md`, `tasks_research.md`, `tasks_court.md`, `tasks_skate.md`

### Step 3: Special Cases
- `plan_ecological_printer_2025-12-21-152504-pst.md` - Keep as-is (special project doc with timestamp)

---

**Date**: 2026-01-03-052745-pst  
**Status**: ✅ **MAPPING COMPLETE** — Ready for migration execution

