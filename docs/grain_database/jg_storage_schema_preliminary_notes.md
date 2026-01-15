# JG Project Storage Schema: Preliminary Design Notes

**Date**: 2025-12-30-100000-pst  
**Agent**: Grain Silo Agent (Database)  
**Status**: Preliminary Design — Ready for Core Agent Coordination  
**Reference**: 
- JG Project Design: `docs/zyx/grainbank_mmt_job_guarantee_housing_program_2025-12-28-232324-pst.md`
- Skate Agent Knowledge Graph: `docs/grain_skate/jg_knowledge_graph_structure.md`
- Payment/Vault/Bank Storage Schema (reference pattern): `docs/grain_database/payment_vault_storage_schema.md`

---

## Overview

This document provides preliminary storage schema design notes for all 8 JG (Job Guarantee) project modules. The design follows the same pattern as Payment/Vault/Bank storage schema and SLC integration helpers, with key-value storage, JSON-encoded data structures, and storage helper APIs.

**JG Modules**:
1. **Grain JG Project Manager** (`jg_project`) — Project lifecycle management
2. **Grain JG Task Tracker** (`jg_task`) — Task assignment and completion tracking
3. **Grain JG Inventory Manager** (`jg_inventory`) — Material tracking from cultivation to construction
4. **Grain JG Supply Chain** (`jg_supply_chain`) — Transportation and logistics tracking
5. **Grain JG 3D Architect** (`jg_architect`) — 3D architectural planning and visualization
6. **Grain JG Worker** (`jg_worker`) — Worker data and profiles
7. **Grain JG Cooperative** (`jg_cooperative`) — Cooperative organization data
8. **Grain JG Housing** (`jg_housing`) — Housing project data and resident allocation

**Timeline**: Storage schema design (Months 1-3), implementation (Months 1-3)

---

## Design Principles

**Key-Value Storage Pattern**:
- All data stored as key-value pairs in Silo Agent database
- Key format: `{prefix}:{type}:{identifier}` (e.g., `jg_project:project:{project_id}`)
- Value format: JSON-encoded data structures
- Follows Payment/Vault/Bank storage schema pattern

**Helper Functions**:
- Storage helpers similar to Payment/Vault/Bank and SLC integration helpers
- Full CRUD operations (store, get, update, delete)
- List and count operations
- Pagination support for large datasets
- Search functionality
- Batch operations for bulk loading
- Validation helpers for identifiers

**Grain Style Compliance**:
- `grain_case` function names
- Explicit `u32`/`u64` types (not `usize`/`isize`)
- Bounded allocations (`MAX_` constants)
- Minimum 2 assertions per function
- Max 70 lines per function
- Max 103 characters per line

**Integration with Skate Agent Knowledge Graph**:
- Storage keys align with Skate Agent's knowledge graph node types
- Material nodes: `jg_material:{material_id}` (from Skate Agent)
- Worker nodes: `jg_worker:{worker_id}` (shared with JG Worker module)
- Project nodes: `jg_project:project:{project_id}` (shared with JG Project Manager)
- Task nodes: `jg_task:task:{task_id}` (shared with JG Task Tracker)

---

## Module 1: Grain JG Project Manager (`jg_project`)

### Key Formats

**Projects**:
- Key format: `jg_project:project:{project_id}`
- `project_id`: u32, unique identifier for project
- Example: `jg_project:project:12345`

**Project Phases**:
- Key format: `jg_project:phase:{project_id}:{phase}`
- `project_id`: u32, project identifier
- `phase`: ProjectPhase enum (planning, site_preparation, foundation, framing, enclosure, systems_installation, finishing, inspection, move_in, completed)
- Example: `jg_project:phase:12345:foundation`

**Project Budgets**:
- Key format: `jg_project:budget:{project_id}`
- `project_id`: u32, project identifier
- Example: `jg_project:budget:12345`

### Data Structures

**Project Value** (JSON):
```json
{
  "project_id": 12345,
  "project_name": "Toledo Hempcrete Community",
  "site_location": "Toledo, OH",
  "phase": "foundation",
  "units_planned": 50,
  "units_completed": 0,
  "workers_assigned": 12,
  "start_date": "2025-01-15T00:00:00Z",
  "target_completion_date": "2026-06-30T00:00:00Z",
  "actual_completion_date": null,
  "budget_allocated": 5000000,
  "budget_spent": 250000,
  "created_at": "2024-12-01T00:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

**Project Phase Value** (JSON):
```json
{
  "project_id": 12345,
  "phase": "foundation",
  "started_at": "2025-12-15T00:00:00Z",
  "target_completion": "2026-01-15T00:00:00Z",
  "actual_completion": null,
  "tasks_completed": 5,
  "tasks_total": 12,
  "status": "in_progress"
}
```

**Project Budget Value** (JSON):
```json
{
  "project_id": 12345,
  "budget_allocated": 5000000,
  "budget_spent": 250000,
  "budget_by_category": {
    "materials": 1500000,
    "labor": 2000000,
    "equipment": 500000,
    "infrastructure": 1000000
  },
  "last_updated": "2025-12-30T10:00:00Z"
}
```

### Storage Helper API (Preliminary)

**JgProjectStorage Helper**:
```zig
pub const JgProjectStorage = struct {
    storage_engine: *storage_engine.StorageEngine,
    
    // Initialize project storage
    pub fn init(storage: *storage_engine.StorageEngine) JgProjectStorage;
    
    // Store project
    pub fn store_project(
        self: *JgProjectStorage,
        project_id: u32,
        project_data: []const u8, // JSON-encoded JgProject
    ) !u64;
    
    // Retrieve project
    pub fn get_project(
        self: *JgProjectStorage,
        project_id: u32,
    ) ?*storage_engine.Record;
    
    // Update project
    pub fn update_project(
        self: *JgProjectStorage,
        project_id: u32,
        project_data: []const u8,
    ) !void;
    
    // List projects by phase
    pub fn list_projects_by_phase(
        self: *JgProjectStorage,
        phase: ProjectPhase,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // Search projects by location
    pub fn search_projects_by_location(
        self: *JgProjectStorage,
        location_pattern: []const u8,
        limit: u32,
    ) ![]*storage_engine.Record;
    
    // Batch store projects
    pub fn batch_store_projects(
        self: *JgProjectStorage,
        projects: []const ProjectData,
    ) !void;
};
```

### Integration Points

- **Skate Agent**: Project relationship mapping (`project:{project_id}` nodes)
- **Grainbank**: Budget tracking and payment processing
- **Grain JG Task Tracker**: Task-to-project relationships
- **Grain JG Inventory**: Material requirements and ordering
- **Grain JG 3D Architect**: Design-to-project relationships

---

## Module 2: Grain JG Task Tracker (`jg_task`)

### Key Formats

**Tasks**:
- Key format: `jg_task:task:{task_id}`
- `task_id`: u32, unique identifier for task
- Example: `jg_task:task:67890`

**Task Assignments**:
- Key format: `jg_task:assignment:{task_id}:{worker_id}`
- `task_id`: u32, task identifier
- `worker_id`: u32, worker identifier
- Example: `jg_task:assignment:67890:11111`

**Task Dependencies**:
- Key format: `jg_task:dependency:{task_id}:{depends_on_task_id}`
- `task_id`: u32, task identifier
- `depends_on_task_id`: u32, prerequisite task identifier
- Example: `jg_task:dependency:67890:54321`

### Data Structures

**Task Value** (JSON):
```json
{
  "task_id": 67890,
  "project_id": 12345,
  "task_name": "Foundation Pour - Building A",
  "task_type": "foundation_work",
  "assigned_worker_id": 11111,
  "skill_requirements": ["carpentry", "masonry"],
  "status": "in_progress",
  "priority": "high",
  "estimated_hours": 40,
  "actual_hours": 25,
  "created_at": "2025-12-15T00:00:00Z",
  "started_at": "2025-12-20T08:00:00Z",
  "completed_at": null,
  "quality_score": null,
  "dependencies": [54321, 54322]
}
```

**Task Assignment Value** (JSON):
```json
{
  "task_id": 67890,
  "worker_id": 11111,
  "role": "lead_carpenter",
  "assigned_at": "2025-12-18T00:00:00Z",
  "hours_worked": 25,
  "wage_rate": 22,
  "status": "in_progress"
}
```

**Task Dependency Value** (JSON):
```json
{
  "task_id": 67890,
  "depends_on_task_id": 54321,
  "dependency_type": "must_complete",
  "created_at": "2025-12-15T00:00:00Z"
}
```

### Storage Helper API (Preliminary)

**JgTaskStorage Helper**:
```zig
pub const JgTaskStorage = struct {
    storage_engine: *storage_engine.StorageEngine,
    
    // Initialize task storage
    pub fn init(storage: *storage_engine.StorageEngine) JgTaskStorage;
    
    // Store task
    pub fn store_task(
        self: *JgTaskStorage,
        task_id: u32,
        task_data: []const u8, // JSON-encoded JgTask
    ) !u64;
    
    // Retrieve task
    pub fn get_task(
        self: *JgTaskStorage,
        task_id: u32,
    ) ?*storage_engine.Record;
    
    // List tasks by project
    pub fn list_tasks_by_project(
        self: *JgTaskStorage,
        project_id: u32,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // List tasks by status
    pub fn list_tasks_by_status(
        self: *JgTaskStorage,
        status: TaskStatus,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // List tasks by worker
    pub fn list_tasks_by_worker(
        self: *JgTaskStorage,
        worker_id: u32,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // Search tasks by skill requirements
    pub fn search_tasks_by_skill(
        self: *JgTaskStorage,
        skill: SkillType,
        limit: u32,
    ) ![]*storage_engine.Record;
    
    // Batch store tasks
    pub fn batch_store_tasks(
        self: *JgTaskStorage,
        tasks: []const TaskData,
    ) !void;
};
```

### Integration Points

- **Skate Agent**: Task relationship mapping (`task:{task_id}` nodes)
- **Grainbank**: Time logging triggers wage payments
- **Grain JG Project Manager**: Task-to-project relationships
- **Grain JG Inventory**: Material requirements for tasks
- **Grain JG Worker**: Worker skill matching
- **Flow Agent**: Workflow orchestration for task dependencies

---

## Module 3: Grain JG Inventory Manager (`jg_inventory`)

### Key Formats

**Inventory Items**:
- Key format: `jg_inventory:item:{item_id}`
- `item_id`: u32, unique identifier for inventory item
- Example: `jg_inventory:item:22222`

**Material Batches**:
- Key format: `jg_inventory:batch:{batch_id}`
- `batch_id`: u32, unique identifier for material batch
- Example: `jg_inventory:batch:33333`

**Material Locations**:
- Key format: `jg_inventory:location:{location_id}:{material_type}`
- `location_id`: u32, location identifier
- `material_type`: MaterialType enum
- Example: `jg_inventory:location:44444:hempcrete_block`

### Data Structures

**Inventory Item Value** (JSON):
```json
{
  "item_id": 22222,
  "material_type": "hempcrete_block",
  "batch_id": 33333,
  "quantity": 5000,
  "unit": "blocks",
  "location": "Toledo Processing Facility - Warehouse A",
  "quality_certification": "structural_grade",
  "cultivation_date": "2025-03-15T00:00:00Z",
  "harvest_date": "2025-07-15T00:00:00Z",
  "processing_date": "2025-08-01T00:00:00Z",
  "expiration_date": null,
  "supplier_cooperative_id": 55555,
  "cost_per_unit": 5,
  "created_at": "2025-08-01T00:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

**Material Batch Value** (JSON):
```json
{
  "batch_id": 33333,
  "material_type": "hempcrete_block",
  "source_cooperative_id": 55555,
  "cultivation_date": "2025-03-15T00:00:00Z",
  "harvest_date": "2025-07-15T00:00:00Z",
  "processing_date": "2025-08-01T00:00:00Z",
  "total_quantity": 5000,
  "unit": "blocks",
  "quality_certification": "structural_grade",
  "traceability_code": "HEMP-2025-0333",
  "created_at": "2025-08-01T00:00:00Z"
}
```

**Material Location Value** (JSON):
```json
{
  "location_id": 44444,
  "location_name": "Toledo Processing Facility - Warehouse A",
  "material_type": "hempcrete_block",
  "current_quantity": 5000,
  "unit": "blocks",
  "capacity": 10000,
  "reorder_point": 2000,
  "last_updated": "2025-12-30T10:00:00Z"
}
```

### Storage Helper API (Preliminary)

**JgInventoryStorage Helper**:
```zig
pub const JgInventoryStorage = struct {
    storage_engine: *storage_engine.StorageEngine,
    
    // Initialize inventory storage
    pub fn init(storage: *storage_engine.StorageEngine) JgInventoryStorage;
    
    // Store inventory item
    pub fn store_item(
        self: *JgInventoryStorage,
        item_id: u32,
        item_data: []const u8, // JSON-encoded InventoryItem
    ) !u64;
    
    // Retrieve inventory item
    pub fn get_item(
        self: *JgInventoryStorage,
        item_id: u32,
    ) ?*storage_engine.Record;
    
    // List items by material type
    pub fn list_items_by_material_type(
        self: *JgInventoryStorage,
        material_type: MaterialType,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // List items by location
    pub fn list_items_by_location(
        self: *JgInventoryStorage,
        location: []const u8,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // Search items by quality certification
    pub fn search_items_by_certification(
        self: *JgInventoryStorage,
        certification: QualityCertification,
        limit: u32,
    ) ![]*storage_engine.Record;
    
    // Batch store items
    pub fn batch_store_items(
        self: *JgInventoryStorage,
        items: []const ItemData,
    ) !void;
};
```

### Integration Points

- **Skate Agent**: Material knowledge graph (`material:{material_id}` nodes)
- **Grain JG Supply Chain**: Material flow tracking
- **Grain JG Task Tracker**: Material requirements for tasks
- **Grainbank**: Material purchase payments to cooperatives
- **Grain JG 3D Architect**: Material requirements from designs

---

## Module 4: Grain JG Supply Chain (`jg_supply_chain`)

### Key Formats

**Supply Chain Routes**:
- Key format: `jg_supply_chain:route:{route_id}`
- `route_id`: u32, unique identifier for route
- Example: `jg_supply_chain:route:66666`

**Processing Facilities**:
- Key format: `jg_supply_chain:facility:{facility_id}`
- `facility_id`: u32, unique identifier for facility
- Example: `jg_supply_chain:facility:77777`

**Transportation Events**:
- Key format: `jg_supply_chain:transport:{route_id}:{event_id}`
- `route_id`: u32, route identifier
- `event_id`: u32, event identifier
- Example: `jg_supply_chain:transport:66666:88888`

### Data Structures

**Supply Chain Route Value** (JSON):
```json
{
  "route_id": 66666,
  "source_location": "Oregon Hemp Farm",
  "destination_location": "Toledo Processing Facility",
  "material_type": "hemp_raw",
  "quantity": 100,
  "unit": "tons",
  "transport_mode": "truck",
  "estimated_duration_hours": 48,
  "actual_duration_hours": null,
  "carbon_footprint_kg": 500,
  "status": "scheduled",
  "scheduled_departure": "2026-01-15T08:00:00Z",
  "actual_departure": null,
  "scheduled_arrival": "2026-01-17T08:00:00Z",
  "actual_arrival": null,
  "created_at": "2025-12-30T10:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

**Processing Facility Value** (JSON):
```json
{
  "facility_id": 77777,
  "facility_name": "Toledo Hempcrete Production Facility",
  "location": "Toledo, OH",
  "facility_type": "hempcrete_production",
  "capacity_per_day": 1000,
  "current_utilization": 750,
  "materials_processed": ["hemp_raw", "hemp_processed"],
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

**Transportation Event Value** (JSON):
```json
{
  "route_id": 66666,
  "event_id": 88888,
  "event_type": "departure",
  "location": "Oregon Hemp Farm",
  "timestamp": "2026-01-15T08:00:00Z",
  "driver_id": 99999,
  "vehicle_id": "TRUCK-001",
  "notes": "Loaded 100 tons hemp_raw"
}
```

### Storage Helper API (Preliminary)

**JgSupplyChainStorage Helper**:
```zig
pub const JgSupplyChainStorage = struct {
    storage_engine: *storage_engine.StorageEngine,
    
    // Initialize supply chain storage
    pub fn init(storage: *storage_engine.StorageEngine) JgSupplyChainStorage;
    
    // Store route
    pub fn store_route(
        self: *JgSupplyChainStorage,
        route_id: u32,
        route_data: []const u8, // JSON-encoded SupplyChainRoute
    ) !u64;
    
    // Retrieve route
    pub fn get_route(
        self: *JgSupplyChainStorage,
        route_id: u32,
    ) ?*storage_engine.Record;
    
    // List routes by status
    pub fn list_routes_by_status(
        self: *JgSupplyChainStorage,
        status: RouteStatus,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // List routes by material type
    pub fn list_routes_by_material(
        self: *JgSupplyChainStorage,
        material_type: MaterialType,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // Search routes by location
    pub fn search_routes_by_location(
        self: *JgSupplyChainStorage,
        location: []const u8,
        limit: u32,
    ) ![]*storage_engine.Record;
    
    // Batch store routes
    pub fn batch_store_routes(
        self: *JgSupplyChainStorage,
        routes: []const RouteData,
    ) !void;
};
```

### Integration Points

- **Grain JG Inventory**: Material movement tracking
- **Grain JG Project Manager**: Material delivery to construction sites
- **Flow Agent**: Transportation workflow orchestration
- **Grainbank**: Transportation payment processing

---

## Module 5: Grain JG 3D Architect (`jg_architect`)

### Key Formats

**Architectural Designs**:
- Key format: `jg_architect:design:{design_id}`
- `design_id`: u32, unique identifier for design
- Example: `jg_architect:design:101010`

**Site Layouts**:
- Key format: `jg_architect:layout:{site_id}`
- `site_id`: u32, unique identifier for site
- Example: `jg_architect:layout:202020`

**Material Requirements**:
- Key format: `jg_architect:material_req:{design_id}:{material_type}`
- `design_id`: u32, design identifier
- `material_type`: MaterialType enum
- Example: `jg_architect:material_req:101010:hempcrete_block`

### Data Structures

**Architectural Design Value** (JSON):
```json
{
  "design_id": 101010,
  "project_id": 12345,
  "design_name": "Toledo Hempcrete Community - Phase 1",
  "design_style": "vernacular_townhouse",
  "building_count": 10,
  "total_units": 50,
  "total_square_feet": 50000,
  "material_requirements": [
    {
      "material_type": "hempcrete_block",
      "quantity": 50000,
      "unit": "blocks",
      "estimated_cost": 250000
    },
    {
      "material_type": "laminated_bamboo_lumber",
      "quantity": 10000,
      "unit": "linear_feet",
      "estimated_cost": 150000
    }
  ],
  "energy_efficiency_score": 85,
  "walkability_score": 90,
  "design_status": "construction_documents",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

**Site Layout Value** (JSON):
```json
{
  "site_id": 202020,
  "project_id": 12345,
  "total_acres": 10,
  "building_footprint_acres": 2,
  "green_space_acres": 5,
  "canal_length_feet": 2000,
  "street_length_feet": 3000,
  "fruit_tree_count": 100,
  "public_space_count": 3,
  "walkability_radius_feet": 1320,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

**Material Requirement Value** (JSON):
```json
{
  "design_id": 101010,
  "material_type": "hempcrete_block",
  "quantity": 50000,
  "unit": "blocks",
  "estimated_cost": 250000,
  "allocated_quantity": 0,
  "fulfilled_quantity": 0,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

### Storage Helper API (Preliminary)

**JgArchitectStorage Helper**:
```zig
pub const JgArchitectStorage = struct {
    storage_engine: *storage_engine.StorageEngine,
    
    // Initialize architect storage
    pub fn init(storage: *storage_engine.StorageEngine) JgArchitectStorage;
    
    // Store design
    pub fn store_design(
        self: *JgArchitectStorage,
        design_id: u32,
        design_data: []const u8, // JSON-encoded ArchitecturalDesign
    ) !u64;
    
    // Retrieve design
    pub fn get_design(
        self: *JgArchitectStorage,
        design_id: u32,
    ) ?*storage_engine.Record;
    
    // List designs by project
    pub fn list_designs_by_project(
        self: *JgArchitectStorage,
        project_id: u32,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // List designs by status
    pub fn list_designs_by_status(
        self: *JgArchitectStorage,
        status: DesignStatus,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // Search designs by style
    pub fn search_designs_by_style(
        self: *JgArchitectStorage,
        style: DesignStyle,
        limit: u32,
    ) ![]*storage_engine.Record;
    
    // Batch store designs
    pub fn batch_store_designs(
        self: *JgArchitectStorage,
        designs: []const DesignData,
    ) !void;
};
```

### Integration Points

- **Grain JG Project Manager**: Design-to-project relationships
- **Grain JG Inventory**: Material requirements from designs
- **Grain JG Task Tracker**: Construction tasks from design elements
- **Workspace Agent**: 3D visualization in desktop apps
- **Court Agent**: LLM-assisted design optimization

---

## Module 6: Grain JG Worker (`jg_worker`)

### Key Formats

**Workers**:
- Key format: `jg_worker:worker:{worker_id}`
- `worker_id`: u32, unique identifier for worker
- Example: `jg_worker:worker:11111`

**Worker Skills**:
- Key format: `jg_worker:skill:{worker_id}:{skill_type}`
- `worker_id`: u32, worker identifier
- `skill_type`: SkillType enum
- Example: `jg_worker:skill:11111:carpentry`

**Worker Certifications**:
- Key format: `jg_worker:certification:{worker_id}:{certification_id}`
- `worker_id`: u32, worker identifier
- `certification_id`: u32, certification identifier
- Example: `jg_worker:certification:11111:22222`

### Data Structures

**Worker Value** (JSON):
```json
{
  "worker_id": 11111,
  "name": "John Smith",
  "email": "john.smith@jg.gov",
  "phone": "+1-555-0123",
  "address": "123 Main St, Toledo, OH",
  "hire_date": "2025-01-15T00:00:00Z",
  "base_wage_rate": 20,
  "current_project_id": 12345,
  "total_hours_worked": 1200,
  "total_earnings": 24000,
  "created_at": "2025-01-15T00:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

**Worker Skill Value** (JSON):
```json
{
  "worker_id": 11111,
  "skill_type": "carpentry",
  "proficiency_level": "advanced",
  "years_experience": 5,
  "certified": true,
  "last_verified": "2025-12-01T00:00:00Z",
  "created_at": "2025-01-15T00:00:00Z"
}
```

**Worker Certification Value** (JSON):
```json
{
  "worker_id": 11111,
  "certification_id": 22222,
  "certification_type": "osha_30",
  "issued_date": "2024-06-01T00:00:00Z",
  "expiration_date": "2027-06-01T00:00:00Z",
  "issuing_authority": "OSHA",
  "certification_number": "OSHA-30-2024-001",
  "created_at": "2024-06-01T00:00:00Z"
}
```

### Storage Helper API (Preliminary)

**JgWorkerStorage Helper**:
```zig
pub const JgWorkerStorage = struct {
    storage_engine: *storage_engine.StorageEngine,
    
    // Initialize worker storage
    pub fn init(storage: *storage_engine.StorageEngine) JgWorkerStorage;
    
    // Store worker
    pub fn store_worker(
        self: *JgWorkerStorage,
        worker_id: u32,
        worker_data: []const u8, // JSON-encoded Worker
    ) !u64;
    
    // Retrieve worker
    pub fn get_worker(
        self: *JgWorkerStorage,
        worker_id: u32,
    ) ?*storage_engine.Record;
    
    // List workers by project
    pub fn list_workers_by_project(
        self: *JgWorkerStorage,
        project_id: u32,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // Search workers by skill
    pub fn search_workers_by_skill(
        self: *JgWorkerStorage,
        skill: SkillType,
        proficiency_level: ProficiencyLevel,
        limit: u32,
    ) ![]*storage_engine.Record;
    
    // Search workers by certification
    pub fn search_workers_by_certification(
        self: *JgWorkerStorage,
        certification_type: CertificationType,
        limit: u32,
    ) ![]*storage_engine.Record;
    
    // Batch store workers
    pub fn batch_store_workers(
        self: *JgWorkerStorage,
        workers: []const WorkerData,
    ) !void;
};
```

### Integration Points

- **Skate Agent**: Worker skill network (`worker:{worker_id}` nodes)
- **Grainbank**: Worker account management, wage payments
- **Grain JG Task Tracker**: Worker skill matching
- **Grain JG Project Manager**: Worker assignment to projects

---

## Module 7: Grain JG Cooperative (`jg_cooperative`)

### Key Formats

**Cooperatives**:
- Key format: `jg_cooperative:coop:{cooperative_id}`
- `cooperative_id`: u32, unique identifier for cooperative
- Example: `jg_cooperative:coop:55555`

**Cooperative Members**:
- Key format: `jg_cooperative:member:{cooperative_id}:{worker_id}`
- `cooperative_id`: u32, cooperative identifier
- `worker_id`: u32, worker identifier
- Example: `jg_cooperative:member:55555:11111`

**Cooperative Accounts**:
- Key format: `jg_cooperative:account:{cooperative_id}`
- `cooperative_id`: u32, cooperative identifier
- Example: `jg_cooperative:account:55555`

### Data Structures

**Cooperative Value** (JSON):
```json
{
  "cooperative_id": 55555,
  "cooperative_name": "Toledo Hemp Growers Cooperative",
  "cooperative_type": "hemp_farm",
  "location": "Toledo, OH",
  "founded_date": "2024-01-01T00:00:00Z",
  "member_count": 25,
  "total_equity": 500000,
  "governance_structure": "democratic",
  "profit_sharing_model": "equal_distribution",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

**Cooperative Member Value** (JSON):
```json
{
  "cooperative_id": 55555,
  "worker_id": 11111,
  "member_since": "2024-01-15T00:00:00Z",
  "equity_share": 20000,
  "voting_rights": true,
  "role": "member",
  "created_at": "2024-01-15T00:00:00Z"
}
```

**Cooperative Account Value** (JSON):
```json
{
  "cooperative_id": 55555,
  "account_balance": 150000,
  "currency": "USD",
  "total_revenue": 500000,
  "total_expenses": 350000,
  "profit_distributed": 100000,
  "last_updated": "2025-12-30T10:00:00Z"
}
```

### Storage Helper API (Preliminary)

**JgCooperativeStorage Helper**:
```zig
pub const JgCooperativeStorage = struct {
    storage_engine: *storage_engine.StorageEngine,
    
    // Initialize cooperative storage
    pub fn init(storage: *storage_engine.StorageEngine) JgCooperativeStorage;
    
    // Store cooperative
    pub fn store_cooperative(
        self: *JgCooperativeStorage,
        cooperative_id: u32,
        cooperative_data: []const u8, // JSON-encoded Cooperative
    ) !u64;
    
    // Retrieve cooperative
    pub fn get_cooperative(
        self: *JgCooperativeStorage,
        cooperative_id: u32,
    ) ?*storage_engine.Record;
    
    // List cooperatives by type
    pub fn list_cooperatives_by_type(
        self: *JgCooperativeStorage,
        cooperative_type: CooperativeType,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // Search cooperatives by location
    pub fn search_cooperatives_by_location(
        self: *JgCooperativeStorage,
        location: []const u8,
        limit: u32,
    ) ![]*storage_engine.Record;
    
    // Batch store cooperatives
    pub fn batch_store_cooperatives(
        self: *JgCooperativeStorage,
        cooperatives: []const CooperativeData,
    ) !void;
};
```

### Integration Points

- **Grainbank**: Cooperative account management, profit distribution
- **Grain JG Inventory**: Cooperative material sourcing
- **Grain JG Supply Chain**: Cooperative material delivery
- **Grain JG Task Tracker**: Cooperative worker task assignment

---

## Module 8: Grain JG Housing (`jg_housing`)

### Key Formats

**Housing Units**:
- Key format: `jg_housing:unit:{unit_id}`
- `unit_id`: u32, unique identifier for housing unit
- Example: `jg_housing:unit:303030`

**Resident Allocations**:
- Key format: `jg_housing:resident:{unit_id}:{resident_id}`
- `unit_id`: u32, unit identifier
- `resident_id`: u32, resident identifier
- Example: `jg_housing:resident:303030:404040`

**Rent-to-Own Equity**:
- Key format: `jg_housing:equity:{unit_id}:{resident_id}`
- `unit_id`: u32, unit identifier
- `resident_id`: u32, resident identifier
- Example: `jg_housing:equity:303030:404040`

### Data Structures

**Housing Unit Value** (JSON):
```json
{
  "unit_id": 303030,
  "project_id": 12345,
  "building_number": "Building A",
  "unit_number": "A-101",
  "square_feet": 800,
  "bedrooms": 2,
  "bathrooms": 1,
  "unit_type": "townhouse",
  "construction_status": "completed",
  "move_in_date": null,
  "rent_to_own_price": 120000,
  "monthly_rent": 600,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

**Resident Allocation Value** (JSON):
```json
{
  "unit_id": 303030,
  "resident_id": 404040,
  "allocation_date": "2026-07-01T00:00:00Z",
  "move_in_date": null,
  "allocation_status": "pending",
  "rent_to_own_enrolled": true,
  "created_at": "2025-12-30T10:00:00Z"
}
```

**Rent-to-Own Equity Value** (JSON):
```json
{
  "unit_id": 303030,
  "resident_id": 404040,
  "total_purchase_price": 120000,
  "equity_accumulated": 0,
  "monthly_payment": 600,
  "payments_made": 0,
  "equity_percentage": 0,
  "projected_ownership_date": "2041-07-01T00:00:00Z",
  "created_at": "2025-12-30T10:00:00Z",
  "updated_at": "2025-12-30T10:00:00Z"
}
```

### Storage Helper API (Preliminary)

**JgHousingStorage Helper**:
```zig
pub const JgHousingStorage = struct {
    storage_engine: *storage_engine.StorageEngine,
    
    // Initialize housing storage
    pub fn init(storage: *storage_engine.StorageEngine) JgHousingStorage;
    
    // Store housing unit
    pub fn store_unit(
        self: *JgHousingStorage,
        unit_id: u32,
        unit_data: []const u8, // JSON-encoded HousingUnit
    ) !u64;
    
    // Retrieve housing unit
    pub fn get_unit(
        self: *JgHousingStorage,
        unit_id: u32,
    ) ?*storage_engine.Record;
    
    // List units by project
    pub fn list_units_by_project(
        self: *JgHousingStorage,
        project_id: u32,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // List units by status
    pub fn list_units_by_status(
        self: *JgHousingStorage,
        status: ConstructionStatus,
        limit: u32,
        offset: u32,
    ) ![]*storage_engine.Record;
    
    // Search units by resident
    pub fn search_units_by_resident(
        self: *JgHousingStorage,
        resident_id: u32,
        limit: u32,
    ) ![]*storage_engine.Record;
    
    // Batch store units
    pub fn batch_store_units(
        self: *JgHousingStorage,
        units: []const UnitData,
    ) !void;
};
```

### Integration Points

- **Grain JG Project Manager**: Unit completion tracking
- **Grainbank**: Rent-to-own equity tracking, rent payments
- **Grain JG Task Tracker**: Systems installation tasks
- **Grain JG Inventory**: Systems components (solar, geothermal, etc.)

---

## Integration with Skate Agent Knowledge Graph

### Key Alignment

**Material Knowledge Graph**:
- Skate Agent nodes: `material:{material_id}` → Silo Agent keys: `jg_inventory:item:{item_id}`
- Skate Agent nodes: `material:hemp_raw` → Silo Agent keys: `jg_inventory:item:{item_id}` (with `material_type: "hemp_raw"`)

**Worker Skill Network**:
- Skate Agent nodes: `worker:{worker_id}` → Silo Agent keys: `jg_worker:worker:{worker_id}`
- Skate Agent nodes: `skill:{skill_type}` → Silo Agent keys: `jg_worker:skill:{worker_id}:{skill_type}`

**Project Relationship Mapping**:
- Skate Agent nodes: `project:{project_id}` → Silo Agent keys: `jg_project:project:{project_id}`
- Skate Agent nodes: `task:{task_id}` → Silo Agent keys: `jg_task:task:{task_id}`

### Data Synchronization

**Bidirectional Updates**:
- When Silo Agent stores project data, Skate Agent can create/update knowledge graph nodes
- When Skate Agent creates material relationships, Silo Agent can update inventory relationships
- When Silo Agent stores worker skills, Skate Agent can update worker skill network

**Query Patterns**:
- Skate Agent queries knowledge graph for relationships → Silo Agent provides data for nodes
- Silo Agent queries storage for entities → Skate Agent provides relationship context

---

## Questions for Core Agent Coordination

### Module Requirements

1. **Data Structure Validation**:
   - Are the JSON schemas for each module aligned with Core Agent's Zig struct definitions?
   - Do we need to adjust any field names or types?
   - Are there additional fields we should include?

2. **Key Format Confirmation**:
   - Are the key formats (`jg_project:project:{project_id}`, etc.) acceptable?
   - Should we use different prefixes or patterns?
   - Do we need to align with any existing key format conventions?

3. **Storage Helper API Design**:
   - Are the storage helper API patterns (CRUD, pagination, search, batch) sufficient?
   - Do we need additional helper functions for specific use cases?
   - Should we follow the exact same pattern as Payment/Vault/Bank storage helpers?

4. **Integration Points**:
   - Are the integration points with Grainbank, Flow Agent, Court Agent, etc. correctly identified?
   - Do we need additional integration points?
   - Are there any cross-module relationships we should handle differently?

5. **Skate Agent Knowledge Graph Alignment**:
   - Are the key alignments between Silo Agent storage and Skate Agent knowledge graph correct?
   - Do we need to adjust any key formats for better integration?
   - How should we handle bidirectional data synchronization?

6. **Timeline and Priorities**:
   - What is the priority order for implementing storage helpers for each module?
   - Should we implement all 8 modules in parallel or sequentially?
   - Are there any dependencies between modules that affect implementation order?

7. **Data Access Patterns**:
   - What are the most common query patterns for each module?
   - Do we need to optimize for specific access patterns?
   - Should we create additional indexes for specific queries?

8. **Encryption and Security**:
   - Do any JG modules require encryption (similar to Grain Passwords)?
   - Are there sensitive data fields that need special handling?
   - Should we implement audit logging for certain operations?

---

## Next Steps

1. **Core Agent Coordination** (IMMEDIATE):
   - Review this preliminary design document
   - Answer coordination questions
   - Confirm data structures and key formats
   - Approve storage helper API designs

2. **Finalize Storage Schema Design** (After Core Agent Coordination):
   - Update data structures based on Core Agent feedback
   - Finalize key formats
   - Complete storage helper API designs
   - Document integration patterns

3. **Begin Implementation** (Months 1-3):
   - Priority 1: `jg_project`, `jg_task` (project and task management)
   - Priority 2: `jg_inventory`, `jg_supply_chain` (material and logistics tracking)
   - Priority 3: `jg_architect`, `jg_worker`, `jg_cooperative`, `jg_housing` (3D planning, worker data, cooperatives, housing)

4. **Integration Testing**:
   - Test storage helpers with Core Agent modules
   - Test integration with Skate Agent knowledge graph
   - Test integration with Grainbank, Flow Agent, Court Agent, etc.

---

**Last Updated**: 2025-12-30-100000-pst  
**Agent**: Grain Silo Agent (Database)  
**Status**: Preliminary Design — Ready for Core Agent Coordination
