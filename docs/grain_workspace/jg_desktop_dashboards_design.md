# JG Desktop Dashboards Design Document

**Date**: 2025-12-31-051000-pst  
**Agent**: Grain Workspace Agent (8th Agent)  
**Status**: Design Document — Desktop Dashboard Architecture  
**Voice**: Grain Glow G2 (positive, first-principles, helpful, succinct yet complete)

---

## Executive Summary

This document outlines the comprehensive design for **5 desktop dashboard applications** for the JG Housing Program (Job Guarantee Housing Program). These dashboards integrate with Grainbank MMT, Silo storage, Flow workflows, Court LLM planning, and Research analytics to provide project managers, task coordinators, inventory managers, supply chain coordinators, and architects with powerful desktop tools for managing JG housing construction projects.

**Dashboard Applications**:
1. **Project Management Dashboard** — Project lifecycle management, site coordination, phase tracking
2. **Task Assignment Interface** — Worker-task matching, time logging, quality verification
3. **Inventory Management Interface** — Material tracking, batch traceability, quality certification
4. **Supply Chain Visualization** — Transportation tracking, route optimization, facility management
5. **3D Architectural Viewer** — Site planning, building modeling, material takeoffs, energy analysis

**Core Technologies**:
- **Component API**: `DesktopComponentAPI` from `src/grain_workspace/components.zig`
- **Silo Integration**: Storage schemas for `jg_project:*`, `jg_task:*`, `jg_inventory:*`, `jg_supply_chain:*`, `jg_architect:*`
- **Grainbank Integration**: MMT dollar creation, account crediting, payment processing
- **Flow Integration**: Workflow orchestration for task dependencies and supply chain routes
- **Court Integration**: LLM-assisted planning, optimization, and analysis
- **Research Integration**: Analytics, reporting, and optimization features

---

## Architecture Overview

### Component Structure

All 5 dashboards use the `DesktopComponentAPI` structure with component variants:

```zig
// Base component structure
pub const Component = struct {
    id: u32,
    name: [MAX_COMPONENT_NAME_LEN]u8,
    name_len: u32,
    state: ComponentState,  // normal, hover, active, disabled, focused
    size: ComponentSize,    // small, medium, large
    theme: ComponentTheme,  // light, dark, high_contrast
};

// Component state variants
pub const ComponentState = enum(u8) {
    normal,
    hover,
    active,
    disabled,
    focused,
};

// Component size variants
pub const ComponentSize = enum(u8) {
    small,
    medium,
    large,
};

// Component theme variants
pub const ComponentTheme = enum(u8) {
    light,
    dark,
    high_contrast,
};
```

### Dashboard Component Groups

Each dashboard defines its own component group structure following the pattern established in `FileManagerComponents`, `TextEditorComponents`, and `TerminalComponents`:

```zig
// Example: Project Management Dashboard Components
pub const ProjectDashboardComponents = struct {
    project_list: Component,
    project_details: Component,
    phase_timeline: Component,
    budget_panel: Component,
    status_bar: Component,
    
    pub fn init() ProjectDashboardComponents {
        // Initialize all components with IDs, names, defaults
    }
    
    pub fn set_theme_all(self: *ProjectDashboardComponents, theme: ComponentTheme) void {
        // Set theme for all components
    }
    
    pub fn set_size_all(self: *ProjectDashboardComponents, size: ComponentSize) void {
        // Set size for all components
    }
};
```

### Data Flow Architecture

**Data Sources**:
- **Silo**: Primary storage for all JG module data
- **Grainbank**: Account balances, payment history, wage calculations
- **Flow**: Workflow state, task dependencies, route status
- **Court**: LLM suggestions, optimization recommendations
- **Research**: Analytics data, reports, insights

**Update Patterns**:
- **Polling**: Periodic data refresh (every 5-30 seconds based on dashboard type)
- **Event-Driven**: Real-time updates via Flow Agent Event Bus for critical state changes
- **User-Triggered**: Manual refresh buttons, filter changes, search queries

**State Management**:
- Local state for UI interactions (selected items, filters, view modes)
- Cached data from Silo/Grainbank/Flow with TTL (time-to-live) for performance
- Optimistic updates for user actions (create, update, delete) with rollback on error

---

## Dashboard 1: Project Management Dashboard

### Purpose

Manage JG housing construction projects from planning to completion. Track project phases, budgets, worker assignments, and completion status.

### Key Features

**Project List View**:
- Table/list of all projects with key metrics (phase, units, budget, completion %)
- Filter by phase, region, status
- Sort by name, start date, completion date, budget
- Search by project name or location
- Pagination for large project lists

**Project Details View**:
- Project information (name, location, description)
- Phase timeline with current phase indicator
- Budget tracking (allocated, spent, remaining)
- Unit tracking (planned, completed, occupied)
- Worker assignment summary
- Quality metrics and inspection status
- Related tasks, inventory items, supply chain routes

**Phase Timeline**:
- Visual timeline showing all project phases
- Current phase highlighted
- Phase transition buttons (with approval workflow)
- Phase history with timestamps and notes

**Budget Panel**:
- Total budget allocated
- Budget spent (by category: materials, labor, equipment, administration)
- Budget remaining
- Spending trends (chart/graph)
- Alerts for budget overruns

**Integration Points**:
- **Silo**: `jg_project:*` keys for project data
- **Grainbank**: Budget tracking, payment history
- **Task Tracker**: Worker assignments, task completion
- **Inventory**: Material requirements and usage
- **Supply Chain**: Material delivery status
- **3D Architect**: Design status and material takeoffs

### Component Structure

```zig
pub const ProjectDashboardComponents = struct {
    project_list: Component,        // ID: 100
    project_details: Component,     // ID: 101
    phase_timeline: Component,      // ID: 102
    budget_panel: Component,        // ID: 103
    status_bar: Component,          // ID: 104
    filter_panel: Component,        // ID: 105
    search_bar: Component,          // ID: 106
};
```

### User Workflows

**View Projects**:
1. User opens Project Management Dashboard
2. Dashboard loads project list from Silo
3. User can filter, sort, search projects
4. User clicks on project to view details
5. Dashboard loads project details, phase timeline, budget panel

**Update Project Phase**:
1. User selects project in details view
2. User clicks "Advance Phase" button on phase timeline
3. Dashboard validates phase transition (checks prerequisites)
4. Dashboard sends update to Silo via Core Agent
5. Dashboard updates UI optimistically
6. If error, rollback UI and show error message

**Monitor Budget**:
1. Dashboard polls Grainbank for budget updates every 10 seconds
2. Budget panel displays current spending vs. allocated
3. If spending > 90% of allocated, show warning alert
4. User can drill down into spending by category
5. User can view spending trends chart

---

## Dashboard 2: Task Assignment Interface

### Purpose

Assign tasks to JG workers, track task progress, log time, and verify quality. Match worker skills to task requirements.

### Key Features

**Task List View**:
- Table/list of all tasks with status, priority, assigned worker
- Filter by status, priority, project, task type, skill requirement
- Sort by priority, due date, created date
- Search by task name or description
- Group by project, status, or assigned worker

**Task Details View**:
- Task information (name, description, type, status, priority)
- Skill requirements and assigned worker skills match
- Estimated vs. actual hours
- Time logging (start/stop timer, manual entry)
- Quality verification (score, notes, photos)
- Dependencies (blocks, blocked by)
- Related project, inventory items, supply chain routes

**Worker Matching**:
- List of available workers with skills
- Skill match score for each worker
- Worker availability (current task load, schedule)
- Assign worker to task (with approval workflow)

**Time Logging**:
- Start/stop timer for active tasks
- Manual time entry (hours, minutes)
- Time validation (check against estimated hours)
- Automatic wage calculation trigger (via Grainbank integration)

**Quality Verification**:
- Quality score input (1-10 scale)
- Quality notes (text input)
- Photo upload (link to photo storage)
- Quality approval workflow

**Integration Points**:
- **Silo**: `jg_task:*` keys for task data
- **Grainbank**: Time logging triggers wage payments
- **Project Manager**: Task-to-project relationships
- **Inventory**: Material requirements for tasks
- **Flow**: Task dependency workflows
- **Court**: LLM-assisted worker-task matching suggestions

### Component Structure

```zig
pub const TaskAssignmentComponents = struct {
    task_list: Component,           // ID: 110
    task_details: Component,        // ID: 111
    worker_matching: Component,     // ID: 112
    time_logging: Component,        // ID: 113
    quality_verification: Component, // ID: 114
    status_bar: Component,          // ID: 115
    filter_panel: Component,        // ID: 116
    search_bar: Component,          // ID: 117
};
```

### User Workflows

**Assign Task to Worker**:
1. User selects task in task list
2. Task details view shows skill requirements
3. User clicks "Find Workers" button
4. Dashboard queries Silo for workers with matching skills
5. Worker matching panel shows available workers with match scores
6. User selects worker and clicks "Assign"
7. Dashboard sends assignment to Silo via Core Agent
8. Dashboard updates UI (task status → assigned)
9. Flow Agent receives task assignment event and updates workflows

**Log Time for Task**:
1. User selects task in task list
2. Task details view shows time logging panel
3. User clicks "Start Timer" button (or enters time manually)
4. Dashboard tracks time locally (start/stop timer)
5. User clicks "Save Time" button
6. Dashboard sends time log to Silo via Core Agent
7. Dashboard triggers Grainbank wage calculation
8. Dashboard updates UI (actual hours, estimated wage)

**Verify Task Quality**:
1. User selects completed task in task list
2. Task details view shows quality verification panel
3. User enters quality score (1-10), notes, photos
4. User clicks "Submit Quality Verification"
5. Dashboard sends verification to Silo via Core Agent
6. Dashboard updates UI (task status → verified)
7. Flow Agent receives quality verification event and updates workflows

---

## Dashboard 3: Inventory Management Interface

### Purpose

Track renewable materials from cultivation through processing to construction use. Manage inventory levels, batch traceability, and quality certification.

### Key Features

**Inventory List View**:
- Table/list of all inventory items with material type, quantity, location
- Filter by material type, location, quality certification, batch
- Sort by quantity, location, expiration date
- Search by material type, batch ID, supplier
- Group by material type, location, or supplier

**Inventory Details View**:
- Material information (type, batch ID, quantity, unit, location)
- Quality certification (organic, fair trade, structural grade, etc.)
- Cultivation/harvest/processing dates
- Expiration date and alerts
- Supplier cooperative information
- Cost per unit and total value
- Usage history (what tasks/projects used this material)
- Related supply chain routes

**Batch Traceability**:
- Batch ID lookup
- Full traceability chain (cultivation → harvest → processing → construction)
- Batch history (movements, usage, quality checks)
- Batch photos and documentation

**Quality Certification**:
- List of quality certifications per material
- Certification status (pending, approved, expired)
- Certification documentation (links, photos)
- Certification alerts (expiring soon, expired)

**Inventory Alerts**:
- Low stock alerts (below reorder point)
- Expiration alerts (expiring within 30 days)
- Quality alerts (failed quality checks)
- Stockout alerts (zero inventory)

**Integration Points**:
- **Silo**: `jg_inventory:*` keys for inventory data
- **Supply Chain**: Material flow tracking
- **Task Tracker**: Material requirements for tasks
- **Grainbank**: Material purchase payments to cooperatives
- **Project Manager**: Material usage by project
- **Court**: LLM-assisted inventory optimization suggestions

### Component Structure

```zig
pub const InventoryManagementComponents = struct {
    inventory_list: Component,      // ID: 120
    inventory_details: Component,   // ID: 121
    batch_traceability: Component,  // ID: 122
    quality_certification: Component, // ID: 123
    alerts_panel: Component,        // ID: 124
    status_bar: Component,          // ID: 125
    filter_panel: Component,        // ID: 126
    search_bar: Component,          // ID: 127
};
```

### User Workflows

**Track Material Usage**:
1. User selects inventory item in inventory list
2. Inventory details view shows usage history
3. User can see which tasks/projects used this material
4. User can drill down into usage details (quantity, date, task ID)
5. Dashboard updates inventory quantity automatically when materials are used

**Check Batch Traceability**:
1. User enters batch ID in search bar
2. Dashboard queries Silo for batch traceability chain
3. Batch traceability panel shows full chain (cultivation → harvest → processing → construction)
4. User can view batch history, photos, documentation
5. User can see which projects/tasks used this batch

**Manage Quality Certification**:
1. User selects inventory item in inventory list
2. Inventory details view shows quality certification panel
3. User can view existing certifications, add new certifications, update certification status
4. User uploads certification documentation (photos, PDFs)
5. Dashboard sends certification update to Silo via Core Agent
6. Dashboard updates UI (certification status, alerts)

---

## Dashboard 4: Supply Chain Visualization

### Purpose

Track materials from cultivation sites through processing facilities to construction sites. Visualize supply chain routes, optimize transportation, and manage facility capacity.

### Key Features

**Route Map View**:
- Interactive map showing supply chain routes
- Source locations (cultivation sites, processing facilities)
- Destination locations (construction sites, warehouses)
- Route lines with status indicators (planned, in transit, delivered, delayed)
- Click on route to view details

**Route List View**:
- Table/list of all routes with status, material type, quantity, duration
- Filter by status, material type, source, destination, transport mode
- Sort by scheduled departure, estimated duration, carbon footprint
- Search by route ID, source, destination
- Group by status, material type, or transport mode

**Route Details View**:
- Route information (source, destination, material type, quantity)
- Transport mode (truck, rail, barge, electric vehicle, local delivery)
- Schedule (scheduled departure, estimated arrival, actual departure/arrival)
- Duration (estimated vs. actual)
- Carbon footprint calculation
- Status updates and history
- Related inventory items, tasks, projects

**Facility Management**:
- List of processing facilities with capacity, utilization, materials processed
- Facility details (name, location, type, capacity, current utilization)
- Capacity alerts (high utilization, over capacity)
- Facility schedule and availability

**Carbon Footprint Tracking**:
- Carbon footprint per route (kg CO2)
- Carbon footprint by transport mode
- Carbon footprint trends (chart/graph)
- Carbon reduction recommendations (Court LLM suggestions)

**Integration Points**:
- **Silo**: `jg_supply_chain:*` keys for supply chain data
- **Inventory**: Material movement tracking
- **Project Manager**: Material delivery to construction sites
- **Flow**: Transportation workflow orchestration
- **Grainbank**: Transportation payment processing
- **Court**: LLM-assisted route optimization suggestions

### Component Structure

```zig
pub const SupplyChainComponents = struct {
    route_map: Component,           // ID: 130
    route_list: Component,          // ID: 131
    route_details: Component,       // ID: 132
    facility_management: Component, // ID: 133
    carbon_tracking: Component,     // ID: 134
    status_bar: Component,          // ID: 135
    filter_panel: Component,        // ID: 136
    search_bar: Component,          // ID: 137
};
```

### User Workflows

**Track Material Delivery**:
1. User selects route in route list (or clicks on route in map)
2. Route details view shows route information, schedule, status
3. Dashboard polls Silo for route status updates every 5 seconds
4. If route status changes (in transit → delivered), dashboard updates UI
5. Dashboard triggers inventory update (material received at destination)
6. Dashboard triggers task update (material available for task)

**Optimize Route**:
1. User selects route in route list
2. Route details view shows current route information
3. User clicks "Optimize Route" button (triggers Court LLM optimization)
4. Dashboard sends route optimization request to Court Agent
5. Court Agent returns optimized route suggestions
6. Dashboard displays optimized route options (duration, carbon footprint, cost)
7. User selects optimized route and clicks "Apply"
8. Dashboard sends route update to Silo via Core Agent
9. Dashboard updates UI (route schedule, estimated duration, carbon footprint)

**Manage Facility Capacity**:
1. User selects facility in facility management panel
2. Facility details view shows capacity, utilization, schedule
3. Dashboard polls Silo for facility utilization updates every 10 seconds
4. If utilization > 90%, dashboard shows warning alert
5. User can view facility schedule, adjust capacity, add processing slots
6. Dashboard sends facility update to Silo via Core Agent

---

## Dashboard 5: 3D Architectural Viewer

### Purpose

3D architectural planning and visualization for traditional urbanism housing projects. View site layouts, building models, material takeoffs, and energy efficiency analysis.

### Key Features

**3D Viewer**:
- Interactive 3D rendering of site layout and buildings
- Camera controls (pan, zoom, rotate, orbit)
- Layer toggles (buildings, infrastructure, canals, fruit trees, etc.)
- Measurement tools (distance, area, volume)
- Material visualization (color-coded by material type)

**Site Layout View**:
- 2D/3D site plan showing building footprint, green space, canals, streets
- Building count, unit count, total square feet
- Walkability radius visualization
- Fruit tree and public space markers
- Infrastructure overlay (fiber, water, canals)

**Building Model View**:
- 3D building models (traditional urbanism styles: neoclassical chateau, vernacular townhouse, timber frame, stone village, brick rowhouse, mixed traditional)
- Building details (units, square feet, material requirements)
- Material takeoff (quantity per material type)
- Structural elements (walls, floors, roofs, foundations)
- Systems overlay (electrical, plumbing, HVAC, fiber)

**Material Takeoff Panel**:
- List of material requirements (material type, quantity, unit, estimated cost)
- Material breakdown by building, by phase, by system
- Material cost estimation (total, per unit, per square foot)
- Material availability check (inventory integration)
- Material ordering workflow (trigger supply chain route)

**Energy Efficiency Analysis**:
- Energy efficiency score (1-10 scale)
- Passive thermal mass analysis
- Solar orientation analysis
- Energy consumption estimates
- Energy optimization recommendations (Court LLM suggestions)

**Design Status Tracking**:
- Design status (concept, schematic, design development, construction documents, approved, under construction, completed)
- Design revision history
- Design approval workflow
- Design-to-project relationship

**Integration Points**:
- **Silo**: `jg_architect:*` keys for design data
- **Project Manager**: Design-to-project relationships
- **Inventory**: Material requirements from designs, material availability
- **Task Tracker**: Construction tasks from design elements
- **Supply Chain**: Material ordering from material takeoffs
- **Court**: LLM-assisted design optimization suggestions
- **Research**: Energy efficiency analysis, walkability analysis

### Component Structure

```zig
pub const ArchitecturalViewerComponents = struct {
    viewer_3d: Component,           // ID: 140
    site_layout: Component,         // ID: 141
    building_model: Component,      // ID: 142
    material_takeoff: Component,    // ID: 143
    energy_analysis: Component,     // ID: 144
    design_status: Component,       // ID: 145
    status_bar: Component,          // ID: 146
    layer_controls: Component,      // ID: 147
    measurement_tools: Component,   // ID: 148
};
```

### User Workflows

**View Site Layout**:
1. User selects project in project list (or opens design directly)
2. Dashboard loads design data from Silo
3. 3D viewer renders site layout (buildings, infrastructure, canals, fruit trees)
4. User can pan, zoom, rotate camera
5. User can toggle layers (buildings, infrastructure, canals, fruit trees)
6. User can measure distances, areas, volumes

**Generate Material Takeoff**:
1. User selects building or design in 3D viewer
2. Dashboard calculates material requirements (material type, quantity, unit)
3. Material takeoff panel displays material requirements
4. Dashboard checks inventory for material availability
5. If materials available, user can trigger material ordering workflow
6. Dashboard sends material order to supply chain (creates route)

**Optimize Design**:
1. User selects design in design status panel
2. User clicks "Optimize Design" button (triggers Court LLM optimization)
3. Dashboard sends design optimization request to Court Agent
4. Court Agent returns optimization suggestions (material efficiency, energy efficiency, cost reduction)
5. Dashboard displays optimization suggestions
6. User reviews suggestions and applies changes
7. Dashboard sends design update to Silo via Core Agent
8. Dashboard updates UI (design revision, material takeoff, energy efficiency score)

**Analyze Energy Efficiency**:
1. User selects building or design in 3D viewer
2. Dashboard calculates energy efficiency metrics (passive thermal mass, solar orientation, energy consumption)
3. Energy analysis panel displays energy efficiency score and breakdown
4. Dashboard generates energy optimization recommendations (Court LLM suggestions)
5. User reviews recommendations and applies changes
6. Dashboard updates energy efficiency score

---

## Component API Integration

### Component Group Structure

Each dashboard defines its component group following the pattern established in `FileManagerComponents`, `TextEditorComponents`, and `TerminalComponents`:

```zig
// Example: Project Dashboard Components
pub const ProjectDashboardComponents = struct {
    project_list: Component,
    project_details: Component,
    phase_timeline: Component,
    budget_panel: Component,
    status_bar: Component,
    filter_panel: Component,
    search_bar: Component,
    
    pub fn init() ProjectDashboardComponents {
        var components = ProjectDashboardComponents{
            .project_list = Component{
                .id = 100,
                .name = "project_list",
                .name_len = 12,
                .state = .normal,
                .size = .medium,
                .theme = .light,
            },
            // ... initialize other components
        };
        return components;
    }
    
    pub fn set_theme_all(self: *ProjectDashboardComponents, theme: ComponentTheme) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.project_list.theme = theme;
        self.project_details.theme = theme;
        // ... set theme for all components
    }
    
    pub fn set_size_all(self: *ProjectDashboardComponents, size: ComponentSize) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.project_list.size = size;
        self.project_details.size = size;
        // ... set size for all components
    }
};
```

### Unified Dashboard Component API

All 5 dashboards are integrated into a unified `JgDashboardComponentAPI` structure:

```zig
pub const JgDashboardComponentAPI = struct {
    project_dashboard: ProjectDashboardComponents,
    task_assignment: TaskAssignmentComponents,
    inventory_management: InventoryManagementComponents,
    supply_chain: SupplyChainComponents,
    architectural_viewer: ArchitecturalViewerComponents,
    
    pub fn init() JgDashboardComponentAPI {
        var api = JgDashboardComponentAPI{
            .project_dashboard = ProjectDashboardComponents.init(),
            .task_assignment = TaskAssignmentComponents.init(),
            .inventory_management = InventoryManagementComponents.init(),
            .supply_chain = SupplyChainComponents.init(),
            .architectural_viewer = ArchitecturalViewerComponents.init(),
        };
        return api;
    }
    
    pub fn set_theme_all(self: *JgDashboardComponentAPI, theme: ComponentTheme) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.project_dashboard.set_theme_all(theme);
        self.task_assignment.set_theme_all(theme);
        self.inventory_management.set_theme_all(theme);
        self.supply_chain.set_theme_all(theme);
        self.architectural_viewer.set_theme_all(theme);
    }
    
    pub fn set_size_all(self: *JgDashboardComponentAPI, size: ComponentSize) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.project_dashboard.set_size_all(size);
        self.task_assignment.set_size_all(size);
        self.inventory_management.set_size_all(size);
        self.supply_chain.set_size_all(size);
        self.architectural_viewer.set_size_all(size);
    }
};
```

### Component ID Ranges

Each dashboard uses a distinct ID range to avoid conflicts:

- **Project Dashboard**: IDs 100-109
- **Task Assignment**: IDs 110-119
- **Inventory Management**: IDs 120-129
- **Supply Chain**: IDs 130-139
- **Architectural Viewer**: IDs 140-149

---

## API Contracts from Core Agent

### Silo Storage API

**Storage Keys**:
- `jg_project:*` — Project data (project_id, name, location, phase, budget, units, etc.)
- `jg_task:*` — Task data (task_id, project_id, name, status, assigned_worker, time_logged, etc.)
- `jg_inventory:*` — Inventory data (item_id, material_type, batch_id, quantity, location, quality, etc.)
- `jg_supply_chain:*` — Supply chain data (route_id, source, destination, material_type, status, carbon_footprint, etc.)
- `jg_architect:*` — Architectural design data (design_id, project_id, design_name, material_requirements, energy_score, etc.)

**Storage Helpers** (implemented by Core Agent):
- `JgProjectStorage` — Project CRUD operations (`create_project()`, `get_project()`, `update_project()`, `delete_project()`, `list_projects()`)
- `JgTaskStorage` — Task CRUD operations (`create_task()`, `get_task()`, `update_task()`, `delete_task()`, `list_tasks()`)
- `JgInventoryStorage` — Inventory CRUD operations (`create_inventory_item()`, `get_inventory_item()`, `update_inventory_item()`, `delete_inventory_item()`, `list_inventory_items()`)
- `JgSupplyChainStorage` — Supply chain CRUD operations (`create_route()`, `get_route()`, `update_route()`, `delete_route()`, `list_routes()`)
- `JgArchitectStorage` — Design CRUD operations (`create_design()`, `get_design()`, `update_design()`, `delete_design()`, `list_designs()`)

**Storage Query API**:
- `query_projects(filter: ProjectFilter, sort: ProjectSort, limit: u32, offset: u32) -> []JgProject`
- `query_tasks(filter: TaskFilter, sort: TaskSort, limit: u32, offset: u32) -> []JgTask`
- `query_inventory(filter: InventoryFilter, sort: InventorySort, limit: u32, offset: u32) -> []InventoryItem`
- `query_routes(filter: RouteFilter, sort: RouteSort, limit: u32, offset: u32) -> []SupplyChainRoute`
- `query_designs(filter: DesignFilter, sort: DesignSort, limit: u32, offset: u32) -> []ArchitecturalDesign`

### Grainbank API

**Account Operations**:
- `get_account_balance(account_id: u32) -> u64` — Get account balance
- `get_account_history(account_id: u32, limit: u32, offset: u32) -> []Transaction` — Get transaction history
- `get_project_budget(project_id: u32) -> ProjectBudget` — Get project budget (allocated, spent, remaining)
- `get_worker_wages(worker_id: u32, start_date: u64, end_date: u64) -> []WagePayment` — Get worker wage history

**Payment Operations**:
- `calculate_wage_payment(worker_id: u32, hours_worked: u32, wage_rate: u64) -> u64` — Calculate wage payment
- `process_wage_payment(worker_id: u32, hours_worked: u32, wage_rate: u64) -> PaymentResult` — Process wage payment
- `process_material_payment(cooperative_id: u32, material_type: MaterialType, quantity: u64, unit_price: u64) -> PaymentResult` — Process material payment
- `process_transportation_payment(route_id: u32, cost: u64) -> PaymentResult` — Process transportation payment

**Budget Tracking**:
- `get_project_spending(project_id: u32, category: SpendingCategory, start_date: u64, end_date: u64) -> u64` — Get project spending by category
- `get_project_spending_trends(project_id: u32, period: TimePeriod) -> []SpendingDataPoint` — Get spending trends

### Flow Agent API

**Workflow Operations**:
- `get_workflow_state(workflow_id: u32) -> WorkflowState` — Get workflow state
- `get_task_dependencies(task_id: u32) -> []u32` — Get task dependencies (blocks, blocked by)
- `get_route_workflow(route_id: u32) -> WorkflowState` — Get route workflow state
- `trigger_workflow_event(workflow_id: u32, event_type: WorkflowEventType, data: []const u8) -> WorkflowResult` — Trigger workflow event

**Event Bus Integration**:
- Subscribe to workflow events via Flow Agent Event Bus
- Receive real-time updates for workflow state changes
- Publish workflow events (task assignment, task completion, route status change, etc.)

### Court Agent API

**LLM Planning Operations**:
- `optimize_route(route: SupplyChainRoute) -> []RouteOptimizationSuggestion` — Get route optimization suggestions
- `match_worker_to_task(task: JgTask, workers: []Worker) -> []WorkerMatchSuggestion` — Get worker-task matching suggestions
- `optimize_design(design: ArchitecturalDesign) -> []DesignOptimizationSuggestion` — Get design optimization suggestions
- `analyze_inventory(inventory_items: []InventoryItem) -> InventoryAnalysis` — Get inventory analysis and recommendations

**Planning Assistance**:
- `suggest_material_quantities(design: ArchitecturalDesign, material_type: MaterialType) -> MaterialQuantitySuggestion` — Get material quantity suggestions
- `suggest_supply_chain_routes(source: Location, destination: Location, material_type: MaterialType, quantity: u64) -> []RouteSuggestion` — Get supply chain route suggestions
- `analyze_energy_efficiency(design: ArchitecturalDesign) -> EnergyEfficiencyAnalysis` — Get energy efficiency analysis

### Research Agent API

**Analytics Operations**:
- `get_project_analytics(project_id: u32, period: TimePeriod) -> ProjectAnalytics` — Get project analytics
- `get_task_analytics(task_id: u32, period: TimePeriod) -> TaskAnalytics` — Get task analytics
- `get_inventory_analytics(material_type: MaterialType, period: TimePeriod) -> InventoryAnalytics` — Get inventory analytics
- `get_supply_chain_analytics(period: TimePeriod) -> SupplyChainAnalytics` — Get supply chain analytics

**Reporting Operations**:
- `generate_project_report(project_id: u32, report_type: ReportType, format: ReportFormat) -> Report` — Generate project report
- `generate_budget_report(project_id: u32, period: TimePeriod, format: ReportFormat) -> Report` — Generate budget report
- `generate_worker_report(worker_id: u32, period: TimePeriod, format: ReportFormat) -> Report` — Generate worker report

---

## Integration Points with Other Agents

### Silo Agent Integration

**Storage Schema Design** (Months 1-3):
- Silo Agent designs storage schemas for all JG modules
- Workspace Agent reviews schemas and provides feedback
- Storage helpers implemented by Core Agent using Silo storage schemas

**Data Synchronization**:
- Dashboard polls Silo for data updates (every 5-30 seconds based on dashboard type)
- Real-time updates via Flow Agent Event Bus for critical state changes
- Optimistic updates for user actions with rollback on error

### Flow Agent Integration

**Workflow Orchestration** (Months 4-10):
- Task dependency workflows (task assignment, task completion, quality verification)
- Supply chain transportation workflows (route creation, route status updates, delivery confirmation)
- Project phase transition workflows (phase approval, phase completion)
- Material ordering workflows (material takeoff → supply chain route creation)

**Event Bus Integration**:
- Subscribe to workflow events for real-time dashboard updates
- Publish workflow events for user actions (task assignment, task completion, route status change)

### Court Agent Integration

**LLM Planning Features** (Months 4-12):
- Route optimization suggestions (supply chain dashboard)
- Worker-task matching suggestions (task assignment dashboard)
- Design optimization suggestions (architectural viewer)
- Inventory optimization suggestions (inventory management dashboard)
- Energy efficiency analysis (architectural viewer)

**Planning Assistance**:
- Material quantity suggestions (architectural viewer)
- Supply chain route suggestions (supply chain dashboard)
- Quality verification recommendations (task assignment dashboard)

### Research Agent Integration

**Analytics Features** (Months 6-12):
- Project analytics (project management dashboard)
- Task analytics (task assignment dashboard)
- Inventory analytics (inventory management dashboard)
- Supply chain analytics (supply chain dashboard)
- Energy efficiency analytics (architectural viewer)

**Reporting Features**:
- Project reports (project management dashboard)
- Budget reports (project management dashboard)
- Worker reports (task assignment dashboard)
- Material usage reports (inventory management dashboard)

### Bubble/Aurora Agent Integration

**UI Component Integration** (Months 7-12):
- Bubble Agent provides SLC UI components for dashboard rendering
- Aurora Agent provides Dream Browser components for web-based dashboard access
- Workspace Agent uses Component API for component structure, Bubble/Aurora agents handle rendering

**Component Coordination**:
- Workspace Agent defines component structure (Component API)
- Bubble Agent implements component rendering (SLC UI components)
- Aurora Agent implements web-based component rendering (Dream Browser components)
- Component state/size/theme variants synchronized across all agents

---

## Implementation Timeline

### Months 1-2: Planning and Design (Current Phase)

**Workspace Agent Tasks**:
- ✅ Review Core Agent's Grainbank MMT integration design
- ⏳ Review Silo Agent's storage schema designs for JG modules (when ready)
- ⏳ Design dashboard architecture and component structure (current task)
- ⏳ Plan integration points with Flow, Court, and Research agents
- ⏳ Create detailed design documents for each dashboard

**Dependencies**:
- Core Agent: Grainbank MMT integration foundation (Months 1-6) — In progress
- Silo Agent: Storage schemas for JG modules (Months 1-3) — **HIGH PRIORITY**

### Months 3-4: Foundation Implementation

**Workspace Agent Tasks**:
- Implement component structure for all 5 dashboards (`JgDashboardComponentAPI`)
- Implement basic dashboard skeletons (empty dashboards with component structure)
- Implement Silo storage integration (data loading, basic CRUD operations)
- Implement basic UI layouts (project list, task list, inventory list, route list, 3D viewer placeholder)

**Dependencies**:
- Silo Agent: Storage schemas ready (Month 3)
- Core Agent: Storage helpers ready (Month 3)

### Months 5-6: Core Functionality Implementation

**Workspace Agent Tasks**:
- Implement project management dashboard core features (project list, project details, phase timeline, budget panel)
- Implement task assignment interface core features (task list, task details, worker matching, time logging)
- Implement inventory management interface core features (inventory list, inventory details, batch traceability)
- Implement supply chain visualization core features (route list, route details, facility management)
- Implement 3D architectural viewer core features (3D viewer, site layout, building model, material takeoff)

**Dependencies**:
- Core Agent: Grainbank API ready (Month 6)
- Flow Agent: Workflow orchestration ready (Month 6)

### Months 7-8: Integration and Enhancement

**Workspace Agent Tasks**:
- Integrate Flow Agent workflows (task dependencies, supply chain routes, project phases)
- Integrate Court Agent LLM features (route optimization, worker matching, design optimization)
- Integrate Research Agent analytics (project analytics, task analytics, inventory analytics)
- Coordinate with Bubble/Aurora agents on UI component integration
- Implement advanced features (filtering, sorting, search, pagination, real-time updates)

**Dependencies**:
- Flow Agent: Workflow orchestration ready (Month 7)
- Court Agent: LLM planning features ready (Month 7)
- Research Agent: Analytics features ready (Month 7)
- Bubble/Aurora Agents: UI component integration ready (Month 7)

### Months 9-10: Testing and Refinement

**Workspace Agent Tasks**:
- Comprehensive testing (unit tests, integration tests, user acceptance tests)
- Performance optimization (data caching, query optimization, rendering optimization)
- UI/UX refinement (user feedback, accessibility improvements, responsive design)
- Documentation (user guides, API documentation, integration guides)

**Dependencies**:
- All agents: Integration complete (Month 9)

---

## Technical Specifications

### Grain Style Compliance

**All dashboard code must follow Grain Style guidelines**:
- Function names: `grain_case` (e.g., `load_project_list()`, `update_task_status()`)
- Types: Explicit `u32`/`u64` instead of `usize`/`isize`
- Bounded allocations: `MAX_PROJECT_NAME_LEN`, `MAX_TASK_NAME_LEN`, `MAX_INVENTORY_ITEMS`, etc.
- Assertions: Comprehensive assertions for all preconditions (minimum 2 per function)
- Line limits: Max 103 characters per line (`grainwrap-100`)
- Function limits: Max 70 lines per function (`grain validate-70`)
- Compiler warnings: All warnings enabled

### Module File Structure

```
src/grain_workspace/jg_dashboards/
├── dashboard_components.zig        # Component structures for all dashboards
├── project_dashboard/
│   ├── app.zig                     # Project Management Dashboard app
│   ├── project_list.zig            # Project list view
│   ├── project_details.zig         # Project details view
│   ├── phase_timeline.zig          # Phase timeline component
│   └── budget_panel.zig            # Budget panel component
├── task_assignment/
│   ├── app.zig                     # Task Assignment Interface app
│   ├── task_list.zig               # Task list view
│   ├── task_details.zig            # Task details view
│   ├── worker_matching.zig         # Worker matching component
│   ├── time_logging.zig            # Time logging component
│   └── quality_verification.zig    # Quality verification component
├── inventory_management/
│   ├── app.zig                     # Inventory Management Interface app
│   ├── inventory_list.zig          # Inventory list view
│   ├── inventory_details.zig       # Inventory details view
│   ├── batch_traceability.zig      # Batch traceability component
│   └── quality_certification.zig   # Quality certification component
├── supply_chain/
│   ├── app.zig                     # Supply Chain Visualization app
│   ├── route_map.zig               # Route map view
│   ├── route_list.zig              # Route list view
│   ├── route_details.zig           # Route details view
│   ├── facility_management.zig     # Facility management component
│   └── carbon_tracking.zig         # Carbon tracking component
├── architectural_viewer/
│   ├── app.zig                     # 3D Architectural Viewer app
│   ├── viewer_3d.zig               # 3D viewer component
│   ├── site_layout.zig             # Site layout view
│   ├── building_model.zig          # Building model view
│   ├── material_takeoff.zig        # Material takeoff component
│   └── energy_analysis.zig         # Energy analysis component
└── integration/
    ├── silo_integration.zig        # Silo storage integration
    ├── grainbank_integration.zig   # Grainbank API integration
    ├── flow_integration.zig        # Flow Agent workflow integration
    ├── court_integration.zig       # Court Agent LLM integration
    └── research_integration.zig    # Research Agent analytics integration
```

### Testing Structure

```
tests/
├── 120_jg_dashboard_components_test.zig      # Component structure tests
├── 121_jg_project_dashboard_test.zig         # Project dashboard tests
├── 122_jg_task_assignment_test.zig           # Task assignment tests
├── 123_jg_inventory_management_test.zig      # Inventory management tests
├── 124_jg_supply_chain_test.zig              # Supply chain tests
├── 125_jg_architectural_viewer_test.zig      # Architectural viewer tests
└── 126_jg_dashboard_integration_test.zig     # Integration tests
```

---

## Success Metrics

### Functional Metrics

**Dashboard Performance**:
- Data loading time < 1 second for list views (< 100 items)
- Data loading time < 2 seconds for detail views
- Real-time update latency < 500ms (via Flow Agent Event Bus)
- 3D viewer rendering FPS > 30 (for interactive navigation)

**User Experience**:
- Dashboard usability score > 8/10 (user feedback)
- Task completion time < 5 minutes for common workflows
- Error rate < 1% (user actions that fail)

### Integration Metrics

**Agent Integration**:
- Silo storage integration: 100% of data operations successful
- Grainbank API integration: 100% of payment operations successful
- Flow Agent integration: 100% of workflow operations successful
- Court Agent integration: 90%+ of LLM suggestions relevant and useful
- Research Agent integration: 100% of analytics operations successful

**Data Synchronization**:
- Data consistency: 100% (dashboard data matches Silo data)
- Real-time update delivery: 99%+ (via Flow Agent Event Bus)
- Optimistic update success rate: 95%+ (user actions succeed on first try)

---

## Next Steps

### Immediate (Months 1-2)

1. **Workspace Agent**: Complete this design document (current task) ✅
2. **Silo Agent**: Design storage schemas for all JG modules (HIGH PRIORITY)
3. **Core Agent**: Review and approve this design document
4. **Workspace Agent**: Review Silo Agent's storage schema designs
5. **Workspace Agent**: Begin component structure implementation

### Short-Term (Months 3-4)

1. **Workspace Agent**: Implement component structure for all 5 dashboards
2. **Core Agent**: Implement Silo storage helpers for JG modules
3. **Workspace Agent**: Implement basic dashboard skeletons
4. **Workspace Agent**: Implement Silo storage integration
5. **Workspace Agent**: Implement basic UI layouts

### Medium-Term (Months 5-6)

1. **Workspace Agent**: Implement core functionality for all 5 dashboards
2. **Core Agent**: Complete Grainbank API for JG modules
3. **Flow Agent**: Complete workflow orchestration for JG modules
4. **Workspace Agent**: Integrate Grainbank API and Flow Agent workflows

### Long-Term (Months 7-8)

1. **Workspace Agent**: Integrate Court Agent LLM features
2. **Workspace Agent**: Integrate Research Agent analytics
3. **Bubble/Aurora Agents**: Integrate UI component rendering
4. **Workspace Agent**: Complete advanced features and testing

---

## Questions for Coordination

1. **Silo Agent**: What storage capacity do we need for national-scale deployment (50-100 sites)?
2. **Core Agent**: What are the exact API contracts for Silo storage helpers and Grainbank operations?
3. **Flow Agent**: What are the exact workflow event types and data formats for JG modules?
4. **Court Agent**: What are the exact LLM API contracts for optimization and planning suggestions?
5. **Research Agent**: What are the exact analytics API contracts for reporting and analysis?
6. **Bubble/Aurora Agents**: What are the exact component rendering API contracts for dashboard UI?
7. **Vantage Agent**: What 3D rendering capabilities do we need for architectural visualization? (WebGL? OpenGL? Vulkan?)

---

**Date**: 2025-12-31-051000-pst  
**Agent**: Grain Workspace Agent (8th Agent)  
**Status**: Design Document Complete — Ready for Agent Coordination

This design document provides a comprehensive blueprint for implementing 5 desktop dashboard applications for the JG Housing Program. The dashboards integrate with Grainbank MMT, Silo storage, Flow workflows, Court LLM planning, and Research analytics to provide project managers, task coordinators, inventory managers, supply chain coordinators, and architects with powerful desktop tools for managing JG housing construction projects.
