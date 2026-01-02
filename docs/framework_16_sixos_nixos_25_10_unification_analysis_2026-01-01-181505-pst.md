# Framework 16: sixos + NixOS 25.10 Minimal Unification Analysis

**Date**: 2026-01-01-181505-pst  
**Context**: Framework 16 (x86_64 AMD, 64GB RAM) running Ubuntu 24.04 LTS host  
**Purpose**: Analyze feasibility of unifying sixos (NixOS without systemd) with NixOS 25.10 minimal for first VM

**Repository**: https://codeberg.org/amjoseph/sixos  
**Reference**: [Adam Joseph's sixos talk at 38C3](https://www.youtube.com/watch?v=gSW3YJ8uyBI&t=2308s)

---

## Executive Summary

**Recommendation**: **EXPLORE sixos + NixOS 25.10 Minimal Unification** — High potential value for Grain Style alignment

**Rationale**:
1. **sixos Philosophy**: NixOS without systemd, using S6 supervision suite — aligns with Grain Style minimalism and avoids systemd monoculture
2. **NixOS 25.10 Minimal**: Latest stable NixOS with minimal base system
3. **Grain Style Alignment**: S6 init system is minimal, simple, explicit — better than systemd for Grain Style principles
4. **VM Context**: Perfect for first VM on Ubuntu host — establishes minimal, systemd-free foundation

**Key Benefits**:
- ✅ Avoids systemd monoculture (philosophical alignment with Grain Style)
- ✅ S6 init system is minimal, simple, explicit (Grain Style alignment)
- ✅ NixOS declarative configuration (reproducible, version-controlled)
- ✅ NixOS 25.10 minimal base (latest stable, minimal footprint)
- ✅ VM isolation (doesn't affect Ubuntu host)

**Challenges**:
- ⚠️ sixos is proof-of-concept (may need adaptation for NixOS 25.10)
- ⚠️ Integration complexity (unifying sixos approach with NixOS 25.10)
- ⚠️ Service definitions (may need to adapt services for S6)
- ⚠️ Documentation (less documentation than standard NixOS)

---

## What is sixos?

### Overview

**sixos** is a NixOS-based operating system that replaces systemd with the S6 supervision suite. It was created by Adam Joseph as a proof-of-concept to demonstrate that NixOS can work without systemd.

**Key Characteristics**:
- **NixOS-based**: Built on 95% of existing Nixpkgs (most applications work out of the box)
- **S6 Init System**: Uses S6 supervision suite instead of systemd
- **Minimal**: Simpler, more focused than systemd
- **Proof-of-Concept**: Designed as "build one to throw away" — provides lessons and code for future developers

**Repository**: https://codeberg.org/amjoseph/sixos

---

## sixos Architecture (from 38C3 Talk)

### Three-Layer Architecture

1. **Owner Boot**: Bootloader based on Coreboot
   - Immutable kernel stored on write-protected SPI flash
   - True full-disk encryption (no unencrypted ESP partition)
   - **Note**: For VM context, we'd use EFI Stub or systemd-boot instead

2. **Infusions**: Lightweight alternative to NixOS module system
   - Uses "algebraic laws" for merging configurations
   - Simpler to override complex package sets (like Python)
   - **Potential Value**: Could simplify NixOS configuration

3. **sixos (OS Layer)**: NixOS without systemd
   - Every service (called a "Target") is a standard Nix derivation
   - Uses same powerful overriding tools as packages
   - S6-linux-init for PID 1
   - S6-SVC for supervision
   - S6-RC for dependency management

### Technical Implementation

**Service Management**:
- `S6-linux-init`: PID 1 (replaces systemd)
- `S6-SVC`: Service supervision
- `S6-RC`: Dependency management

**Security**:
- Eliminates traditional setuid wrappers
- Uses `S6-sudo` for privileged commands
- Only one setuid binary: `doas` (from OpenBSD)

**Console Multiplexing**:
- Uses `abduco` to multiplex video and serial consoles
- Ensures recovery is always possible via serial

---

## NixOS 25.10 Minimal

### What is NixOS 25.10 Minimal?

**NixOS 25.10** is the latest stable NixOS release (as of 2026-01-01).

**Minimal Installation**:
- Minimal base system (no GUI, minimal packages)
- Linux kernel 6.18.2 (or latest stable)
- Standard NixOS declarative configuration
- Uses systemd by default (standard NixOS)

**Key Features**:
- Declarative configuration (`configuration.nix`)
- Reproducible builds
- Version-pinned dependencies
- Easy to recreate and version control

---

## Unification Analysis: sixos + NixOS 25.10 Minimal

### Feasibility Assessment

**✅ Highly Feasible**:
1. **NixOS Base**: Both are NixOS-based, share same foundation
2. **Nixpkgs Compatibility**: sixos uses 95% of existing Nixpkgs — most packages work
3. **Service Definitions**: Services can be adapted from systemd to S6
4. **VM Context**: VM isolation makes experimentation safe

**⚠️ Challenges**:
1. **Version Compatibility**: sixos may target older NixOS version — need to adapt for NixOS 25.10
2. **Service Migration**: Need to convert systemd services to S6 services
3. **Module System**: May need to adapt sixos "Infusions" approach or use standard NixOS modules
4. **Documentation**: Less documentation than standard NixOS

### Unification Approach

**Option A: Adapt sixos for NixOS 25.10** (Recommended)

**Steps**:
1. **Clone sixos repository**: `git clone https://codeberg.org/amjoseph/sixos.git`
2. **Analyze sixos structure**: Understand how it replaces systemd with S6
3. **Adapt for NixOS 25.10**: Update sixos configuration for NixOS 25.10 minimal
4. **Create unified configuration**: Combine sixos S6 approach with NixOS 25.10 minimal base
5. **Test in VM**: Build and test in QEMU/KVM VM on Ubuntu host

**Benefits**:
- Leverages sixos's proven approach (S6 integration)
- Maintains NixOS 25.10 minimal base
- Can adapt and improve as needed

**Timeline**: 1-2 weeks (depending on complexity)

---

**Option B: Build from scratch using sixos principles** (More work, more control)

**Steps**:
1. **Start with NixOS 25.10 minimal**: Begin with standard NixOS 25.10 minimal
2. **Remove systemd**: Disable systemd in NixOS configuration
3. **Add S6**: Integrate S6 supervision suite (S6-linux-init, S6-SVC, S6-RC)
4. **Create service definitions**: Convert systemd services to S6 services
5. **Test in VM**: Build and test in QEMU/KVM VM

**Benefits**:
- Full control over implementation
- Can adapt specifically for NixOS 25.10
- Learn from sixos but build custom solution

**Timeline**: 2-4 weeks (more work, but more control)

---

## Grain Style Alignment

### Why sixos + NixOS 25.10 Aligns with Grain Style

**1. Minimalism**:
- ✅ S6 init system is minimal (smaller than systemd)
- ✅ NixOS 25.10 minimal base (minimal footprint)
- ✅ Avoids systemd monoculture (philosophical alignment)

**2. Simplicity**:
- ✅ S6 is simpler than systemd (focused on supervision, not everything)
- ✅ Explicit service definitions (clear, declarative)
- ✅ No hidden behavior (S6 is transparent)

**3. Explicit Configuration**:
- ✅ NixOS declarative configuration (`configuration.nix`)
- ✅ S6 service definitions (explicit, clear)
- ✅ Version-controlled (reproducible)

**4. Minimal Dependencies**:
- ✅ S6 is minimal (fewer dependencies than systemd)
- ✅ NixOS 25.10 minimal base (minimal packages)
- ✅ Avoids systemd dependency (monoculture concern)

**5. Safety**:
- ✅ S6 supervision (process monitoring, automatic restart)
- ✅ Fail-fast (S6 detects failures quickly)
- ✅ Explicit limits (bounded operations)

**Grain Style Alignment Score**: **9/10** (Excellent alignment)

---

## Implementation Plan for Framework 16 VM

### Phase 1: Research and Analysis (Week 1)

**Steps**:
1. **Clone sixos repository**:
   ```bash
   git clone https://codeberg.org/amjoseph/sixos.git
   cd sixos
   ```

2. **Analyze sixos structure**:
   - Review how sixos replaces systemd with S6
   - Understand service definitions
   - Review "Infusions" module system approach
   - Study S6 integration patterns

3. **Review NixOS 25.10 minimal**:
   - Understand NixOS 25.10 minimal base
   - Review systemd services that need conversion
   - Identify dependencies and requirements

4. **Create unification plan**:
   - Document how to adapt sixos for NixOS 25.10
   - Identify services to convert (systemd → S6)
   - Plan configuration structure

**Deliverables**:
- Analysis document
- Unification plan
- Service conversion list

---

### Phase 2: Unification Implementation (Weeks 2-3)

**Steps**:
1. **Create unified configuration**:
   - Start with NixOS 25.10 minimal base
   - Integrate sixos S6 approach
   - Adapt for NixOS 25.10 compatibility

2. **Convert services**:
   - Convert essential services from systemd to S6
   - Create S6 service definitions
   - Test service startup and supervision

3. **Build unified system**:
   - Build NixOS 25.10 with S6 init system
   - Test in VM environment
   - Fix compatibility issues

4. **Documentation**:
   - Document unified configuration
   - Create service conversion guide
   - Document S6 service definitions

**Deliverables**:
- Unified NixOS 25.10 + S6 configuration
- Working VM image
- Documentation

---

### Phase 3: VM Setup and Testing (Week 4)

**Steps**:
1. **Create VM on Ubuntu host**:
   - Set up QEMU/KVM VM on Ubuntu 24.04 LTS
   - Install unified NixOS 25.10 + S6 system
   - Configure bootloader (EFI Stub or systemd-boot)

2. **Test functionality**:
   - Test boot process (S6 init system)
   - Test service management (S6-SVC, S6-RC)
   - Test essential services (network, SSH, etc.)
   - Test development tools (Zig, git, build tools)

3. **Verify Grain Style compliance**:
   - Verify minimalism (small footprint)
   - Verify simplicity (clear configuration)
   - Verify explicit configuration (declarative)
   - Verify minimal dependencies (no systemd)

4. **Documentation**:
   - Document VM setup process
   - Document S6 service management
   - Document troubleshooting guide

**Deliverables**:
- Working VM on Ubuntu host
- Test results
- Documentation

---

## Benefits of sixos + NixOS 25.10 Unification

### Technical Benefits

1. **Minimal Init System**:
   - S6 is smaller and simpler than systemd
   - Focused on supervision (not everything)
   - Better resource utilization

2. **Avoids Systemd Monoculture**:
   - No systemd dependency
   - Reduces monoculture risk
   - More control over system behavior

3. **NixOS Declarative Configuration**:
   - Reproducible builds
   - Version-controlled configuration
   - Easy to recreate and share

4. **VM Isolation**:
   - Safe experimentation
   - Doesn't affect Ubuntu host
   - Easy to recreate if needed

### Grain Style Benefits

1. **Minimalism**: S6 + NixOS 25.10 minimal = minimal footprint
2. **Simplicity**: S6 is simpler than systemd
3. **Explicit Configuration**: NixOS declarative + S6 explicit
4. **Minimal Dependencies**: No systemd dependency
5. **Safety**: S6 supervision provides process monitoring

---

## Challenges and Mitigation

### Challenge 1: Version Compatibility

**Issue**: sixos may target older NixOS version, need to adapt for NixOS 25.10

**Mitigation**:
- Analyze sixos codebase for NixOS version dependencies
- Adapt sixos configuration for NixOS 25.10
- Test compatibility incrementally

---

### Challenge 2: Service Migration

**Issue**: Need to convert systemd services to S6 services

**Mitigation**:
- Start with essential services only
- Use sixos service definitions as reference
- Create conversion guide for common services
- Test each service conversion

---

### Challenge 3: Documentation

**Issue**: Less documentation than standard NixOS

**Mitigation**:
- Document as we go
- Create service conversion guide
- Document S6 service definitions
- Share knowledge with team

---

### Challenge 4: Integration Complexity

**Issue**: Unifying sixos with NixOS 25.10 may be complex

**Mitigation**:
- Start simple (essential services only)
- Test incrementally
- Use VM for safe experimentation
- Iterate and improve

---

## Recommended Approach

### Primary Recommendation: Adapt sixos for NixOS 25.10

**Why**:
1. **Leverages Proven Approach**: sixos has already solved S6 integration
2. **Faster Implementation**: Adapt existing code rather than build from scratch
3. **Learning Opportunity**: Understand sixos approach, then adapt
4. **VM Safety**: Safe to experiment in VM

**Steps**:
1. Clone sixos repository
2. Analyze sixos structure and approach
3. Adapt for NixOS 25.10 minimal
4. Test in VM on Ubuntu host
5. Document and iterate

**Timeline**: 2-4 weeks (depending on complexity and testing)

---

## Alternative: Standard NixOS 25.10 Minimal (Fallback)

**If unification is too complex**:

**Fallback Option**: Use standard NixOS 25.10 minimal with systemd

**Benefits**:
- ✅ Well-documented
- ✅ Stable and tested
- ✅ Easy to set up
- ✅ Full NixOS ecosystem support

**Trade-offs**:
- ⚠️ Systemd dependency (monoculture concern)
- ⚠️ Less aligned with Grain Style minimalism
- ⚠️ Larger footprint than S6

**When to Use**: If sixos unification proves too complex or time-consuming

---

## Conclusion

**Recommendation**: **EXPLORE sixos + NixOS 25.10 Minimal Unification**

**Why**:
1. **Grain Style Alignment**: S6 init system aligns better with Grain Style than systemd
2. **Philosophical Alignment**: Avoids systemd monoculture
3. **Technical Benefits**: Minimal, simple, explicit
4. **VM Safety**: Safe to experiment in VM
5. **Learning Opportunity**: Understand S6 integration, adapt for our needs

**Implementation**:
- Start with research and analysis (Week 1)
- Implement unification (Weeks 2-3)
- Test in VM (Week 4)
- Document and iterate

**Success Criteria**:
- ✅ Working NixOS 25.10 + S6 VM on Ubuntu host
- ✅ Essential services running (network, SSH, development tools)
- ✅ Grain Style compliance verified
- ✅ Documentation complete

**Next Steps**:
1. Clone sixos repository and analyze
2. Create detailed unification plan
3. Begin implementation
4. Test in VM on Framework 16 Ubuntu host

---

**Date**: 2026-01-01-181505-pst  
**Status**: ✅ **UNIFICATION ANALYSIS COMPLETE** — Ready for implementation exploration  
**Next Steps**: Clone sixos repository, analyze structure, create detailed unification plan
