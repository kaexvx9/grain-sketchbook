# Vantage 3: Protocol Naming Analysis

**Date**: 2026-01-23-181500-pst  
**Status**: 🚧 **ANALYSIS IN PROGRESS**

---

## Question

Should we use a different name for our Rye-adapted Wayland protocol implementation?

---

## Context

### Current Situation
- **Decision**: Adapt Wayland protocol with explicit Rye Style bounds
- **Existing Code**: Uses "wayland" in paths and module names
- **Adaptations**: Adding explicit bounds (MAX_STRING_LENGTH, MAX_ARRAY_SIZE, etc.)
- **Compatibility**: Wire format compatible, but stricter bounds than standard Wayland

### Similar Decision Pattern
- **Tend Garden**: Innovated new allocator (vs adapting Linux kernel)
- **This Protocol**: Adapting Wayland but with significant Rye Style constraints

---

## Naming Options

### Option 1: Keep "Wayland" Name
**Pros**:
- ✅ Clear compatibility indication
- ✅ Existing code already uses "wayland"
- ✅ MIT licensed, can use name
- ✅ Developers familiar with Wayland will understand

**Cons**:
- ⚠️ May imply full Wayland compatibility (we have stricter bounds)
- ⚠️ Doesn't indicate Rye-specific adaptations
- ⚠️ Could confuse users expecting standard Wayland behavior

**Verdict**: **MAYBE** — Works but doesn't emphasize Rye-specific nature

---

### Option 2: "Rye Wayland" or "Wayland-Rye"
**Pros**:
- ✅ Indicates Rye-specific adaptation
- ✅ Maintains Wayland connection for familiarity
- ✅ Clear that it's based on Wayland

**Cons**:
- ⚠️ Still uses "Wayland" name (may have branding concerns)
- ⚠️ Longer name

**Verdict**: **GOOD** — Clear and descriptive

---

### Option 3: New Name (Rye-Native)
**Examples**:
- **"Grain Protocol"** (matches Grain OS)
- **"Basin Protocol"** (matches Basin kernel)
- **"Rye Display Protocol"** (RDP - but conflicts with Remote Desktop Protocol)
- **"Rye Window Protocol"** (RWP)
- **"Skate Protocol"** (matches Skate application)
- **"Vantage Protocol"** (matches Vantage development)

**Pros**:
- ✅ Fully Rye-native identity
- ✅ No Wayland branding concerns
- ✅ Emphasizes innovation and Rye Style principles
- ✅ Follows pattern of Tend garden (innovated, not adapted)

**Cons**:
- ⚠️ Loses Wayland familiarity
- ⚠️ Requires renaming existing code
- ⚠️ May imply incompatibility (even though wire format is compatible)

**Verdict**: **STRONG** — Most aligned with Rye philosophy

---

### Option 4: Hybrid Approach
**Name**: "Grain Protocol" (or similar)  
**Subtitle/Description**: "Wayland-compatible with Rye Style bounds"

**Pros**:
- ✅ Rye-native name
- ✅ Still indicates Wayland compatibility
- ✅ Clear about adaptations

**Cons**:
- ⚠️ Longer description needed

**Verdict**: **BEST** — Best of both worlds

---

## Recommendation

### ✅ **Option 4: "Grain Protocol"**

**Rationale**:
1. **Rye-Native Identity**: "Grain" matches Grain OS, emphasizes Rye ecosystem
2. **Innovation Signal**: Like Tend garden, shows we're innovating, not just adapting
3. **Wayland Compatibility**: Can document as "Wayland wire-format compatible with Rye Style bounds"
4. **Clear Differentiation**: Makes it clear this is Rye-specific, not standard Wayland
5. **Future-Proof**: If we diverge further, name already reflects independence

**Implementation**:
- Rename `grain_core/wayland/` → `grain_core/grain_protocol/`
- Update module names and imports
- Document as "Grain Protocol (Wayland wire-format compatible)"
- Keep MIT license attribution for Wayland protocol design

---

## Alternative: "Basin Protocol"

**Consideration**: Basin is the kernel, Grain is the OS. Since this is for the OS/GUI layer, "Grain Protocol" makes more sense.

---

## Migration Plan (if renaming)

1. **Create new directory**: `grain_core/grain_protocol/`
2. **Copy and update code**: Move protocol.zig, update comments
3. **Update imports**: Change all `@import("wayland/protocol.zig")` references
4. **Update documentation**: Reflect new name
5. **Keep old directory temporarily**: For reference during migration
6. **Remove old directory**: After migration complete

---

## Decision Factors

### Key Questions:
1. **Do we want to emphasize Rye innovation?** → Yes → New name
2. **Do we want Wayland compatibility to be obvious?** → Can document it
3. **Do we want to avoid Wayland branding?** → New name avoids it
4. **Is renaming effort worth it?** → Yes, if it clarifies our approach

---

## Final Recommendation

### ✅ **"Grain Protocol"**

**Full Name**: "Grain Protocol (Wayland wire-format compatible)"  
**Short Name**: "Grain Protocol" or "grain_protocol"

**Why**:
- Matches Grain OS naming
- Emphasizes Rye-native innovation
- Still indicates Wayland compatibility in documentation
- Follows Tend garden pattern (innovated, not just adapted)
- Clear differentiation from standard Wayland

---

**Status**: 🚧 **ANALYSIS COMPLETE** — Recommendation: "Grain Protocol"

---

**Date**: 2026-01-23-181500-pst  
**Agent**: Vantage 3 Subcore (Rye Compiler Fork Development)
