# Aurora Agent: JG Project Requirements Summary

**Date**: 2025-12-31-050600-pst  
**Agent**: Grain Aurora IDE Dream Browser Agent  
**Status**: Requirements Summary — JG Project UI Components  
**Voice**: Grain Glow G2 (positive, first-principles, helpful, succinct yet complete)

---

## Executive Summary

This document summarizes Aurora Agent's responsibilities for the **Grainbank MMT Job Guarantee (JG) Housing Program** UI components implementation. Aurora Agent is responsible for building browser-based UI components for 3D visualization, dashboards, and mobile interfaces (Months 7-12).

**Program Vision**: Build beautiful, affordable, sustainable housing using fastest-growing renewable materials (hemp, bamboo, timber, rammed earth) through a federal Job Guarantee program that creates jobs, builds communities, and restores traditional urbanism principles.

**Aurora Agent Scope**: Browser-based UI components for JG project applications, integrated with Dream Browser Component API and coordinated with Workspace Agent (desktop dashboards), Bubble Agent (component design patterns), and Carry Agent (mobile app integration).

---

## JG Project Overview

### Program Goals

1. **MMT Foundation**: Direct Treasury/Fed dollar creation via Grainbank (no taxation required for funding)
2. **Job Guarantee**: Living wage employment for anyone seeking work ($18-22/hour, regionally adjusted)
3. **Sustainable Materials**: Hemp, bamboo, timber, rammed earth, stone, clay (fastest-growing, renewable, fair-trade)
4. **Traditional Urbanism**: Walled towns, canals, mixed-use, walkable, human-scaled, productive landscapes
5. **Modern Infrastructure**: Private baths, secure fiber ethernet, passive thermal mass, graywater recycling
6. **Fair Trade Cooperatives**: Worker-owned farms, regional processing, democratic governance

### Core JG Modules (Other Agents)

- **Core Agent**: Grainbank MMT integration, JG module foundation (Months 1-6)
- **Silo Agent**: Storage schemas for all JG modules (Months 1-3)
- **Workspace Agent**: Desktop dashboards (Months 3-8)
- **Court Agent**: LLM planning (design optimization, supply chain optimization, policy analysis) (Months 4-12)
- **Flow Agent**: Workflow orchestration (Months 4-10)
- **Research Agent**: Analysis & optimization (Months 6-12)
- **Carry Agent**: Mobile apps (Months 6-12)
- **Bubble Agent**: UI components (design patterns, animations, component variants) (Months 7-12)
- **Skate Agent**: Knowledge graph (Months 5-12)
- **Vantage Agent**: Kernel support (as needed)

### JG Module Data Structures

**Key Modules for UI Components**:

1. **Grain JG Project Manager** (`grain_jg_project`): Project lifecycle, site selection, construction phases, quality assurance, resident allocation
2. **Grain JG Task Tracker** (`grain_jg_task`): Task assignment, worker skill matching, progress tracking, time logging, quality verification
3. **Grain JG Inventory Manager** (`grain_jg_inventory`): Material tracking, cultivation, processing, inventory levels, quality certification, batch tracking
4. **Grain JG Supply Chain** (`grain_jg_supply_chain`): Material sourcing, cooperative coordination, transportation, regional hubs, logistics
5. **Grain JG Architecture Planner** (`grain_jg_architecture`): 3D design, site layouts, material quantity calculations, energy efficiency, building codes

---

## Aurora Agent Responsibilities

**Timeline**: Months 7-12  
**Priority**: **HIGH** — JG Project UI Components

### Phase 1: 3D Visualization Components (Months 7-9)

**Objective**: Build browser-based 3D visualization components for architectural planning, site layouts, material quantities, and energy efficiency analysis.

#### Components Required

1. **3D Architectural Visualization Components**:
   - Building structure visualization (walls, roofs, foundations, windows, doors)
   - Material type visualization (hempcrete, LBL, CLT, rammed earth, brick, stone)
   - Construction phase visualization (planning, foundation, framing, enclosure, finishing)
   - Multi-story building visualization
   - Building code compliance visualization (fire safety, accessibility, structural integrity)

2. **Site Layout Visualization Components**:
   - Site plan visualization (property boundaries, building footprints, roads, canals, walls)
   - Community layout visualization (mixed-use zones, walkable neighborhoods, productive landscapes)
   - Material staging area visualization
   - Worker flow visualization (construction site traffic patterns)
   - Utility infrastructure visualization (fiber ethernet, water, graywater, power)

3. **Material Quantity Visualization Components**:
   - Material quantity calculations (tons, cubic yards, linear feet, square feet, blocks, bricks, boards)
   - Batch tracking visualization (cultivation date, harvest date, processing date, expiration date)
   - Material flow visualization (from cultivation → processing → construction)
   - Regional sourcing visualization (cooperative locations, transportation routes)
   - Inventory level visualization (reorder points, stock levels, quality certifications)

4. **Energy Efficiency Visualization Components**:
   - Thermal mass visualization (passive heating/cooling, insulation, thermal bridges)
   - Energy performance visualization (heating/cooling loads, ventilation, natural lighting)
   - Carbon sequestration visualization (hemp, bamboo, timber carbon storage)
   - Embodied energy visualization (material production, transportation, construction energy)
   - Life cycle assessment visualization (LCA metrics, environmental impact)

#### Integration Requirements

- **Dream Browser Component API**: Use `dream_browser_components.zig` for component structure (state/size/theme variants)
- **WebGL/Canvas**: Use WebGL for 3D rendering (optional Canvas fallback)
- **API Integration**: Integrate with JG module APIs (Core Agent, Month 6+)
  - `grain_jg_project`: Project data, construction phases, site locations
  - `grain_jg_architecture`: 3D design data, material quantities, energy efficiency calculations
  - `grain_jg_inventory`: Material tracking, batch data, quality certifications
- **Bubble Agent Coordination**: Use Bubble Agent's design patterns and animations for 3D visualization components

#### Technical Requirements

- **Grain Style**: `grain_case` naming, `u32`/`u64` types, bounded allocations, assertions, max 70 lines per function
- **Component Structure**: Follow Dream Browser Component API patterns (NavigationComponents, AddressBarComponents, TabComponents, BrowserViewComponents)
- **Rendering**: WebGL primary (3D), Canvas optional (2D overlays), DOM for UI controls
- **Performance**: Optimize for large 3D models, efficient rendering, smooth animations
- **Accessibility**: Keyboard navigation, screen reader support, ARIA labels

---

### Phase 2: Dashboard Components (Months 10-11)

**Objective**: Build browser-based dashboard components for project management, task tracking, inventory management, and supply chain visualization.

#### Components Required

1. **Project Management Dashboard Components**:
   - Project overview cards (project status, units planned/completed, workers assigned, budget)
   - Construction phase timeline (planning → site prep → foundation → framing → enclosure → finishing → inspection → move-in → completed)
   - Site selection map (location, boundaries, community context)
   - Budget tracking charts (allocated vs spent, payment history, wage payments)
   - Quality assurance indicators (inspection status, quality scores, verification status)

2. **Task Tracking Dashboard Components**:
   - Task list views (pending, assigned, in progress, completed, verified, failed)
   - Worker assignment interface (skill matching, task assignment, time logging)
   - Task dependency graphs (task relationships, workflow visualization, critical path)
   - Progress charts (task completion rates, time estimates vs actual, quality scores)
   - Task detail views (task information, worker information, quality verification)

3. **Inventory Management Dashboard Components**:
   - Inventory level charts (material types, quantities, reorder points, stock levels)
   - Material flow diagrams (cultivation → processing → construction → use)
   - Batch tracking tables (batch IDs, cultivation dates, harvest dates, processing dates, quality certifications)
   - Regional sourcing maps (cooperative locations, material origins, transportation routes)
   - Quality certification badges (organic, fair trade, sustainable forestry, structural grade, fire rated, moisture resistant)

4. **Supply Chain Visualization Components**:
   - Supply chain network diagrams (cooperatives, regional hubs, transportation routes)
   - Material sourcing maps (hemp farms, bamboo forests, timber sources, clay pits, stone quarries)
   - Logistics tracking (material transportation, delivery schedules, inventory transfers)
   - Cooperative coordination interface (fair trade cooperatives, worker-owned farms, regional processing)
   - Regional hub management (equipment, training, operations, regional administration)

#### Integration Requirements

- **Dream Browser Component API**: Use `dream_browser_components.zig` for component structure
- **Workspace Agent Coordination**: Integrate with Workspace Agent desktop dashboards (Months 3-8)
- **API Integration**: Integrate with JG module APIs (Core Agent, Month 6+)
  - `grain_jg_project`: Project data, construction phases, budget tracking
  - `grain_jg_task`: Task data, worker assignments, progress tracking
  - `grain_jg_inventory`: Inventory data, material tracking, batch data
  - `grain_jg_supply_chain`: Supply chain data, cooperative coordination, logistics
- **Bubble Agent Coordination**: Use Bubble Agent's design patterns and animations for dashboard components

#### Technical Requirements

- **Grain Style**: `grain_case` naming, `u32`/`u64` types, bounded allocations, assertions, max 70 lines per function
- **Component Structure**: Follow Dream Browser Component API patterns
- **Rendering**: DOM primary (charts, tables, cards), Canvas optional (diagrams, maps), WebGL optional (3D visualizations)
- **Data Visualization**: Charts (line, bar, pie, area), maps (site maps, regional maps), diagrams (flow charts, dependency graphs)
- **Performance**: Optimize for large datasets, efficient rendering, smooth updates
- **Accessibility**: Keyboard navigation, screen reader support, ARIA labels, color contrast

---

### Phase 3: Mobile UI Components (Month 12)

**Objective**: Build browser-based mobile UI components for worker mobile apps, resident mobile apps, and cooperative mobile apps.

#### Components Required

1. **Worker Mobile App UI Components**:
   - Task assignment interface (pending tasks, assigned tasks, task details, skill requirements)
   - Time logging interface (clock in/out, hours worked, wage calculation)
   - Task progress tracking (task status, quality verification, completion status)
   - Worker profile (skills, certifications, wage rate, work history)
   - Communication interface (team messages, project updates, notifications)

2. **Resident Mobile App UI Components**:
   - Housing application interface (application form, eligibility check, application status)
   - Move-in coordination interface (move-in date, unit assignment, key pickup)
   - Resident portal (rent payments, rent-to-own equity, maintenance requests, community events)
   - Unit information (unit details, building information, neighborhood context)
   - Community engagement interface (community meetings, cooperative governance, feedback)

3. **Cooperative Mobile App UI Components**:
   - Cooperative dashboard (cooperative profile, member directory, financial overview)
   - Material sales interface (material listings, pricing, orders, deliveries)
   - Worker management interface (worker assignments, time tracking, wage payments)
   - Quality certification interface (certification submission, quality tracking, compliance)
   - Regional coordination interface (regional hub communication, logistics, equipment sharing)

#### Integration Requirements

- **Dream Browser Component API**: Use `dream_browser_components.zig` for component structure
- **Carry Agent Coordination**: Integrate with Carry Agent mobile apps (Months 6-12)
- **API Integration**: Integrate with JG module APIs (Core Agent, Month 6+)
  - `grain_jg_task`: Task data, worker assignments, time logging
  - `grain_jg_project`: Project data, resident allocation, move-in coordination
  - `grainbank`: Wage payments, rent payments, rent-to-own equity, financial transactions
  - `grain_jg_inventory`: Material sales, inventory management, quality certification
- **Bubble Agent Coordination**: Use Bubble Agent's design patterns and animations for mobile UI components

#### Technical Requirements

- **Grain Style**: `grain_case` naming, `u32`/`u64` types, bounded allocations, assertions, max 70 lines per function
- **Component Structure**: Follow Dream Browser Component API patterns
- **Rendering**: DOM primary (mobile-friendly UI), responsive design, touch-friendly interactions
- **Performance**: Optimize for mobile devices, efficient rendering, smooth scrolling, offline support (if needed)
- **Accessibility**: Touch accessibility, screen reader support, ARIA labels, mobile-friendly UI patterns

---

## Coordination Requirements

### Core Agent (Months 7-12)

**Coordination Type**: API Contracts for JG Modules

**What Aurora Agent Needs**:
- JG module API contracts (project manager, task tracker, inventory manager, supply chain, architecture planner)
- Data structure definitions (project data, task data, inventory data, supply chain data, architecture data)
- API endpoints (REST or other protocols)
- Authentication/authorization (service-to-service authentication patterns)

**What Aurora Agent Provides**:
- UI component requirements (data display, user interactions, visualization needs)
- Integration feedback (API usability, data format needs, performance requirements)

**Timeline**: Coordinate when Core Agent completes Phase 3 (Month 6), then ongoing coordination during implementation (Months 7-12)

---

### Workspace Agent (Months 7-8)

**Coordination Type**: Component API Integration

**What Aurora Agent Needs**:
- Component API design patterns (component structure, state/size/theme variants)
- Desktop dashboard component requirements (component types, integration patterns)
- Shared component library (if applicable)

**What Aurora Agent Provides**:
- Browser-based component implementations (Dream Browser Component API)
- Integration examples (how browser components integrate with desktop dashboards)

**Timeline**: Coordinate during overlap period (Months 7-8) when both agents are working on dashboard components

---

### Bubble Agent (Months 7-12)

**Coordination Type**: Component Design Patterns

**What Aurora Agent Needs**:
- Design patterns for 3D visualization components (layout, styling, interactions)
- Design patterns for dashboard components (charts, tables, cards, maps)
- Design patterns for mobile UI components (mobile-friendly UI, touch interactions)
- Animation patterns (transitions, interactions, visual feedback)
- Component variant patterns (state/size/theme variants)

**What Aurora Agent Provides**:
- Browser-based component implementations (Dream Browser Component API)
- Integration examples (how browser components use Bubble Agent design patterns)

**Timeline**: Ongoing coordination during implementation (Months 7-12)

---

### Carry Agent (Month 12)

**Coordination Type**: Mobile UI Component Integration

**What Aurora Agent Needs**:
- Mobile app API contracts (worker app, resident app, cooperative app)
- Mobile UI component requirements (component types, integration patterns)
- Mobile app architecture (native vs web, offline support, push notifications)

**What Aurora Agent Provides**:
- Browser-based mobile UI components (Dream Browser Component API)
- Integration examples (how browser components integrate with mobile apps)

**Timeline**: Coordinate during mobile UI component implementation (Month 12)

---

## Implementation Plan

### Preparation Phase (Months 1-6)

**Aurora Agent Actions**:
- ✅ Review JG project design document (`docs/zyx/grainbank_mmt_job_guarantee_housing_program_2025-12-28-232324-pst.md`)
- ✅ Review JG project responsibilities (Core Agent coordination plan, 2025-12-29-105655-pst)
- ✅ Coordinate with Bubble Agent on component API design (IMMEDIATE, BLOCKING) ✅ Complete (2025-12-30-123545-pst)
- ⏳ Coordinate with Core Agent on API contracts for JG modules (when Core Agent completes Phase 3, Month 6)
- ⏳ Review Workspace Agent desktop dashboard requirements (Months 3-8)
- ⏳ Plan JG-specific UI component architecture

### Phase 1: 3D Visualization Components (Months 7-9)

**Tasks**:
- [ ] Coordinate with Core Agent on JG module API contracts (architecture planner, project manager, inventory manager)
- [ ] Coordinate with Bubble Agent on 3D visualization component design patterns
- [ ] Design 3D architectural visualization components
- [ ] Design site layout visualization components
- [ ] Design material quantity visualization components
- [ ] Design energy efficiency visualization components
- [ ] Implement 3D visualization components (Dream Browser Component API)
- [ ] Add comprehensive tests
- [ ] Update documentation

**Deliverables**:
- 3D visualization component module (`src/dream_browser_jg_3d_visualization.zig`)
- Component API integration (Dream Browser Component API)
- Tests (`tests/dream_browser_jg_3d_visualization_test.zig`)
- Documentation (component usage, integration guide)

### Phase 2: Dashboard Components (Months 10-11)

**Tasks**:
- [ ] Coordinate with Core Agent on JG module API contracts (project manager, task tracker, inventory manager, supply chain)
- [ ] Coordinate with Workspace Agent on desktop dashboard component integration
- [ ] Coordinate with Bubble Agent on dashboard component design patterns
- [ ] Design project management dashboard components
- [ ] Design task tracking dashboard components
- [ ] Design inventory management dashboard components
- [ ] Design supply chain visualization components
- [ ] Implement dashboard components (Dream Browser Component API)
- [ ] Integrate with Workspace Agent desktop dashboards
- [ ] Add comprehensive tests
- [ ] Update documentation

**Deliverables**:
- Dashboard component module (`src/dream_browser_jg_dashboard.zig`)
- Component API integration (Dream Browser Component API)
- Workspace Agent integration (desktop dashboard integration)
- Tests (`tests/dream_browser_jg_dashboard_test.zig`)
- Documentation (component usage, integration guide)

### Phase 3: Mobile UI Components (Month 12)

**Tasks**:
- [ ] Coordinate with Core Agent on JG module API contracts (task tracker, project manager, grainbank, inventory manager)
- [ ] Coordinate with Carry Agent on mobile app API contracts
- [ ] Coordinate with Bubble Agent on mobile UI component design patterns
- [ ] Design worker mobile app UI components
- [ ] Design resident mobile app UI components
- [ ] Design cooperative mobile app UI components
- [ ] Implement mobile UI components (Dream Browser Component API)
- [ ] Integrate with Carry Agent mobile apps
- [ ] Add comprehensive tests
- [ ] Update documentation

**Deliverables**:
- Mobile UI component module (`src/dream_browser_jg_mobile.zig`)
- Component API integration (Dream Browser Component API)
- Carry Agent integration (mobile app integration)
- Tests (`tests/dream_browser_jg_mobile_test.zig`)
- Documentation (component usage, integration guide)

---

## Dependencies

### Required Dependencies

- **Dream Browser Component API**: `src/dream_browser_components.zig` ✅ Complete
- **Core Agent HTTP Client**: Timeout/error handling ✅ Complete
- **Core Agent WebSocket Client**: Timeout/error handling ✅ Complete
- **Core Agent Service-to-Service Authentication**: Auth patterns ✅ Complete
- **Core Agent Async Pattern**: Async patterns ✅ Complete

### Pending Dependencies

- **Core Agent JG Module APIs**: API contracts (Month 6+)
- **DAG Core Error Types**: Error handling coordination (HIGH PRIORITY, pending)
- **Workspace Agent Desktop Dashboards**: Component integration (Months 3-8)
- **Bubble Agent Design Patterns**: Component design patterns (Months 7-12)
- **Carry Agent Mobile Apps**: Mobile app integration (Months 6-12)

---

## Grain Style Requirements

### Code Style

- All functions use `grain_case` naming
- Bounded allocations: Fixed-size arrays for spans and strings
- Minimum 2 assertions per function
- Max 70 lines per function
- Max 103 characters per line (graincard compatibility)
- All compiler warnings enabled
- Explicit types (`u32`/`u64`, no `usize`)

### Component Style

- Follow Dream Browser Component API patterns (component structure, state/size/theme variants)
- Use Bubble Agent design patterns (layout, styling, interactions, animations)
- Optimize for performance (efficient rendering, smooth animations, large datasets)
- Ensure accessibility (keyboard navigation, screen reader support, ARIA labels, color contrast)

---

## Success Criteria

### Phase 1: 3D Visualization Components (Months 7-9)

- ✅ 3D visualization components implemented and tested
- ✅ Component API integration complete
- ✅ Bubble Agent design patterns integrated
- ✅ Core Agent API integration complete
- ✅ Documentation complete

### Phase 2: Dashboard Components (Months 10-11)

- ✅ Dashboard components implemented and tested
- ✅ Component API integration complete
- ✅ Workspace Agent integration complete
- ✅ Bubble Agent design patterns integrated
- ✅ Core Agent API integration complete
- ✅ Documentation complete

### Phase 3: Mobile UI Components (Month 12)

- ✅ Mobile UI components implemented and tested
- ✅ Component API integration complete
- ✅ Carry Agent integration complete
- ✅ Bubble Agent design patterns integrated
- ✅ Core Agent API integration complete
- ✅ Documentation complete

---

## Next Steps

**Immediate** (Preparation Phase):
1. ⏳ Coordinate with Core Agent on API contracts for JG modules (when Core Agent completes Phase 3, Month 6)
2. ⏳ Review Workspace Agent desktop dashboard requirements (Months 3-8)
3. ⏳ Plan JG-specific UI component architecture

**Short-term** (Phase 1, Months 7-9):
1. Begin 3D visualization component implementation
2. Coordinate with Core Agent, Bubble Agent, Workspace Agent as needed
3. Complete Phase 1 deliverables

**Medium-term** (Phase 2, Months 10-11):
1. Begin dashboard component implementation
2. Integrate with Workspace Agent desktop dashboards
3. Complete Phase 2 deliverables

**Long-term** (Phase 3, Month 12):
1. Begin mobile UI component implementation
2. Integrate with Carry Agent mobile apps
3. Complete Phase 3 deliverables

---

**Status**: Requirements documented. Ready for implementation when Core Agent completes JG module foundation (Month 6+).
