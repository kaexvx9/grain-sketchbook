# Private Zen Office Design: Grain OS Integration

**Date**: 2025-12-30  
**Author**: Glow G2 (Grain Free Agent)  
**Focus**: Complete private zen office design with 4K laser projector, motorized standing/sitting desk, and open-hardware split keyboard  
**Context**: Petaluma collaborative space private office, Grain OS integration, sustainable materials

---

## Executive Summary

This document outlines a complete **private zen office design** that integrates:

1. **4K Laser Projector**: Open-hardware 4K projector with Grain OS Core Compositor integration
2. **Motorized Standing/Sitting Desk**: Open-hardware motorized desk (standing to lotus position)
3. **Open-Hardware Split Keyboard**: Ergonomic split keyboard (Kinesis-compatible, patent-free design)
4. **Sustainable Materials**: USA-grown/dollar-using-country ecological materials
5. **Zen Design Philosophy**: Minimalist, sustainable, repairable, open-source

**Key Specifications**:
- **Desk Height Range**: 28" (standing) to 8" (lotus position floor sitting)
- **Keyboard**: Split ergonomic, Cherry Silent Red MX switches, tenting kit
- **Projector**: 4K UHD (3840x2160), open-hardware, Grain OS integrated
- **Materials**: Sustainable wood (USA-grown hardwoods, bamboo), ecological finishes
- **Design**: Open hardware, repairable, modular

**Design Philosophy**:
- **Zen Minimalism**: Clean, uncluttered, focused workspace
- **Sustainability**: Ecological materials, repairable design, long-lasting
- **Open Source**: All design files, firmware, and documentation open
- **Grain OS Native**: Full integration with Grain OS ecosystem
- **Ergonomic Excellence**: Standing, sitting, floor sitting (lotus position)

---

## Office Layout & Design Philosophy

### Zen Office Principles

**Minimalism**:
- Clean, uncluttered workspace
- Essential items only
- Hidden cable management
- Natural materials and finishes

**Sustainability**:
- USA-grown hardwoods (oak, maple, walnut)
- Bamboo (rapidly renewable)
- Ecological finishes (natural oils, water-based)
- Repairable, modular design
- Long-lasting components

**Ergonomics**:
- Multiple working positions (standing, sitting, floor sitting)
- Adjustable desk height (28" to 8")
- Split keyboard (reduces strain)
- Projector display (reduces eye strain)
- Natural lighting integration

**Open Source**:
- All design files open (CAD, 3D models)
- All firmware open (desk controller, keyboard)
- All documentation open
- Repairable and modifiable

---

## Component 1: 4K Laser Projector

**Reference**: See `docs/zyx/open_hardware_4k_laser_projector_grain_os_2025-12-30.md` for complete design.

**Integration into Zen Office**:
- **Mounting**: Ceiling mount (minimal footprint)
- **Display**: Large wall projection (minimal desk clutter)
- **Control**: Grain OS integrated (desktop control)
- **Aesthetics**: Minimalist enclosure design

**Key Features**:
- 4K UHD resolution (3840x2160)
- RGB laser light source
- Open-hardware design
- Grain OS Core Compositor integration
- 3D printable enclosure

**Cost**: $1,500-$6,000 (depending on components)

---

## Component 2: Motorized Standing/Sitting Desk

### Design Overview

**Height Range**:
- **Maximum**: 28" (standing position)
- **Minimum**: 8" (lotus position floor sitting)
- **Range**: 20" total adjustment
- **Increments**: 0.1" precision

**Desktop Dimensions**:
- **Width**: 60" (standard) or 72" (wide)
- **Depth**: 30" (standard) or 36" (deep)
- **Thickness**: 1.5" (solid wood)

**Load Capacity**: 200 lbs (desktop + equipment)

---

### Sustainable Materials

#### Desktop Material Options

**Option A: USA-Grown Hardwood** ⭐⭐⭐⭐⭐

**Recommended Species**:
- **Oak** (White Oak, Red Oak): Durable, beautiful grain
- **Maple** (Hard Maple, Soft Maple): Light color, smooth finish
- **Walnut** (Black Walnut): Rich color, premium appearance
- **Cherry** (Black Cherry): Warm color, fine grain

**Specifications**:
- **Source**: USA-grown, sustainably harvested
- **Thickness**: 1.5" solid wood
- **Finish**: Natural oil (linseed, tung) or water-based polyurethane
- **Edge**: Live edge (optional) or straight edge
- **Price**: $500-$2,000 (depending on species and size)

**Suppliers**:
- Local sawmills (USA-grown hardwoods)
- Sustainable forestry certified suppliers
- Reclaimed wood (recycled, repurposed)

**Option B: Bamboo** ⭐⭐⭐⭐

**Specifications**:
- **Source**: Rapidly renewable, sustainable
- **Type**: Strand-woven bamboo (strongest)
- **Thickness**: 1.5" solid bamboo
- **Finish**: Natural oil or water-based finish
- **Price**: $300-$1,000

**Note**: Most bamboo is not USA-grown, but is sustainable and ecological.

**Recommendation**: **USA-Grown Hardwood** (Oak or Maple) for sustainability and durability.

---

#### Frame Materials

**Steel Frame** (Open Hardware):
- **Material**: Powder-coated steel (ecological finish)
- **Design**: Open-source frame design
- **Finish**: Low-VOC powder coating
- **Repairable**: Standard steel, replaceable parts

**Wood Legs** (Optional):
- **Material**: USA-grown hardwood (matching desktop)
- **Design**: Solid wood legs (sustainable)
- **Finish**: Natural oil (matching desktop)

---

### Motorized Lift System

**Open-Hardware Design**:
- **Actuators**: Linear actuators (dual motor system)
- **Control**: Open-source motor controller
- **Power**: 24V DC, 5A per motor (120W total)
- **Precision**: 0.1" height increments
- **Speed**: 1" per second (adjustable)

**Components**:
1. **Linear Actuators**: 20" stroke, 200 lb capacity each
   - **Price**: $100-$200 each (2 required)
   - **Availability**: Standard linear actuators (commodity)

2. **Motor Controller**: Open-source controller board
   - **Microcontroller**: ESP32 or RISC-V SBC
   - **Interface**: USB, Bluetooth, or WiFi
   - **Control**: Height presets, manual adjustment
   - **Price**: $50-$100 (DIY) or $150-$300 (commercial)

3. **Power Supply**: 24V, 10A (240W)
   - **Price**: $50-$100

4. **Control Interface**: 
   - **Physical**: Up/down buttons, height display
   - **Software**: Grain OS integration (desktop app)
   - **Presets**: Standing, sitting, lotus position

**Total Motor System Cost**: $400-$800

---

### Frame Design (Open Hardware)

**3D Printable Parts**:
- Motor mounts
- Actuator mounts
- Control panel housing
- Cable management

**Steel Frame** (CNC or laser cut):
- Frame brackets
- Cross braces
- Mounting points

**Design Files**:
- CAD files (FreeCAD, OpenSCAD)
- STL files (3D printable parts)
- DXF files (steel frame cutting)

---

### Assembly Instructions

**Phase 1: Frame Assembly**
1. Cut steel frame components (CNC or laser cut)
2. Weld or bolt frame together
3. Install linear actuators
4. Install motor controller
5. Install power supply

**Phase 2: Desktop Installation**
1. Prepare desktop (sand, finish)
2. Mount desktop to frame
3. Install cable management
4. Test motor system

**Phase 3: Control Integration**
1. Install control interface
2. Calibrate height sensors
3. Set presets (standing, sitting, lotus)
4. Integrate with Grain OS (optional)

---

### Grain OS Integration

**Desk Control App** (Grain OS):
- Height adjustment (up/down)
- Preset positions (standing, sitting, lotus)
- Height display
- Auto-adjustment (scheduled height changes)

**Implementation**:
```zig
// Desk control interface (Grain OS)
pub const DeskController = struct {
    current_height: f32,  // inches
    min_height: f32,      // 8" (lotus)
    max_height: f32,     // 28" (standing)
    presets: [3]f32,      // standing, sitting, lotus
    
    pub fn move_to_height(self: *DeskController, height: f32) void {
        // Move desk to specified height
    }
    
    pub fn move_to_preset(self: *DeskController, preset: DeskPreset) void {
        // Move to preset position
    }
};

pub const DeskPreset = enum(u8) {
    standing,  // 28"
    sitting,   // 24"
    lotus,     // 8"
};
```

---

### Total Desk Cost

**Desktop** (USA-grown hardwood): $500-$2,000
**Frame & Motors**: $400-$800
**Control System**: $50-$300
**Finishing**: $100-$200
**Assembly**: DIY or $500-$1,000 (professional)

**Total**: $1,050-$4,300

---

## Component 3: Open-Hardware Split Keyboard

### Design Overview

**Design Philosophy**: Patent-free split keyboard design inspired by open-source projects (ErgoDox, Iris, Dactyl) while avoiding Kinesis patents.

**Key Features**:
- **Split Design**: Two separate halves (adjustable separation)
- **Ergonomic Layout**: Columnar staggered layout (reduces strain)
- **Cherry MX Switches**: Cherry Silent Red MX (quiet, comfortable)
- **Tenting Kit**: Adjustable tenting (optional, 3D printable)
- **Open Hardware**: All design files open (PCB, case, firmware)

**Kinesis Patent Avoidance**:
- **Avoid**: Specific Kinesis split mechanism patents (US 7,828,489, 8,289,684)
- **Use**: Open-source designs (ErgoDox, Iris) as reference
- **Design**: Columnar staggered layout (different from Kinesis)
- **Mechanism**: Standard split keyboard design (not Kinesis-specific)

---

### Keyboard Specifications

**Layout**:
- **Left Half**: 5x6 keys (30 keys)
- **Right Half**: 5x6 keys (30 keys)
- **Total**: 60 keys (standard layout)
- **Optional**: Thumb clusters (additional keys)

**Switches**:
- **Type**: Cherry Silent Red MX
- **Characteristics**: Linear, quiet, 45g actuation
- **Compatibility**: Cherry MX compatible (hot-swappable)

**Keycaps**:
- **Profile**: DSA or OEM profile
- **Material**: PBT (durable, ecological)
- **Layout**: QWERTY (customizable)

---

### Open-Hardware Design

**Reference Designs** (Open Source):
1. **ErgoDox**: Well-known open-source split keyboard
2. **Iris Rev. 5**: 4x6 columnar staggered layout
3. **Dactyl**: Curved, ergonomic design
4. **Bastard Keyboards**: Open-source ergonomic keyboards

**Our Design** (Patent-Free):
- **Layout**: Columnar staggered (5x6 per half)
- **Case**: 3D printable (PLA/PETG)
- **PCB**: Open-source PCB design (KiCad)
- **Firmware**: QMK or ZMK (open-source keyboard firmware)

---

### Component Selection

#### PCB (Printed Circuit Board)

**Design**: Open-source PCB (KiCad)
- **Layout**: Columnar staggered (5x6 per half)
- **Switches**: Cherry MX compatible (hot-swappable sockets)
- **Microcontroller**: RP2040 (Raspberry Pi Pico) or Pro Micro
- **Connectivity**: USB-C (left half), TRRS cable (right half)

**Options**:
1. **Custom PCB**: Design in KiCad, order from JLCPCB or similar
   - **Price**: $50-$100 (2 PCBs, left + right)
   - **Time**: 2-4 weeks (manufacturing)

2. **Open-Source PCB**: Use ErgoDox or Iris PCB design (modified)
   - **Price**: $30-$80 (2 PCBs)
   - **Time**: 2-4 weeks (manufacturing)

**Recommendation**: **Custom PCB** (KiCad design, patent-free layout)

---

#### Case (3D Printable)

**Design**: Open-source 3D model (FreeCAD, OpenSCAD)
- **Material**: PLA or PETG (3D printable)
- **Thickness**: 3-4mm (rigid, durable)
- **Features**: 
  - Switch plate integration
  - USB-C cutout
  - TRRS cable routing
  - Tenting kit mounts

**3D Printable Parts**:
- `case_left.stl` - Left half case
- `case_right.stl` - Right half case
- `case_bottom_left.stl` - Left half bottom
- `case_bottom_right.stl` - Right half bottom
- `tenting_kit.stl` - Tenting kit (adjustable)

**Printing**:
- **Material**: PLA or PETG (1-2 kg per half)
- **Price**: $20-$40 (materials)
- **Time**: 10-20 hours per half (3D printing)

---

#### Switches & Keycaps

**Switches**: Cherry Silent Red MX
- **Quantity**: 60 switches (30 per half)
- **Price**: $2-$3 per switch
- **Total**: $120-$180

**Keycaps**: PBT keycaps
- **Profile**: DSA or OEM
- **Layout**: QWERTY (customizable)
- **Price**: $50-$150 (full set)

**Total Switches & Keycaps**: $170-$330

---

#### Tenting Kit (Optional)

**Design**: 3D printable tenting kit
- **Material**: PLA or PETG
- **Adjustability**: 0-30 degrees (adjustable)
- **Mounting**: Screw-on or magnetic

**3D Printable Parts**:
- `tenting_legs.stl` - Adjustable tenting legs
- `tenting_mounts.stl` - Mounting brackets

**Price**: $10-$20 (materials, 3D printing)

---

### Firmware (Open Source)

**Options**:
1. **QMK** (Quantum Mechanical Keyboard): Popular open-source firmware
2. **ZMK** (Zephyr-based): Modern, wireless-friendly firmware

**Features**:
- Custom keymaps
- Layers (function keys, symbols)
- Macros
- RGB lighting (optional)

**Implementation**:
- Flash firmware to microcontroller
- Customize keymap
- Test and adjust

---

### Assembly Instructions

**Phase 1: PCB Preparation**
1. Order PCBs (JLCPCB or similar)
2. Solder hot-swappable sockets
3. Solder microcontroller
4. Solder USB-C connector
5. Test PCB (continuity, power)

**Phase 2: Case Printing**
1. 3D print case parts (left, right, bottoms)
2. Sand and finish (optional)
3. Test fit (switches, PCB)

**Phase 3: Switch Installation**
1. Install switches in PCB
2. Install keycaps
3. Test switches (actuation, feel)

**Phase 4: Final Assembly**
1. Install PCB in case
2. Install bottom plate
3. Connect halves (TRRS cable)
4. Flash firmware
5. Test keyboard

**Phase 5: Tenting Kit (Optional)**
1. 3D print tenting kit
2. Install tenting legs
3. Adjust tenting angle
4. Test comfort

---

### Total Keyboard Cost

**PCBs**: $50-$100
**Case (3D Printing)**: $40-$80
**Switches**: $120-$180
**Keycaps**: $50-$150
**Microcontroller**: $10-$20 (2x)
**Cables**: $10-$20
**Tenting Kit**: $10-$20 (optional)

**Total**: $290-$570

---

## Office Integration

### Cable Management

**Hidden Cable Routing**:
- **Desk**: Integrated cable management (desk frame)
- **Projector**: Ceiling cable routing
- **Keyboard**: USB-C cable (desk-mounted)
- **Power**: Integrated power strip (desk-mounted)

**Design**:
- Cable channels (desk frame)
- Cable clips (3D printable)
- Power strip mount (desk underside)

---

### Grain OS Integration

**Unified Control**:
- **Desk**: Height adjustment, presets
- **Projector**: Display control, brightness, focus
- **Keyboard**: Keymap customization, layers
- **Desktop**: Unified control panel

**Implementation**:
```zig
// Zen Office Control (Grain OS)
pub const ZenOfficeController = struct {
    desk: DeskController,
    projector: ProjectorDisplay,
    keyboard: KeyboardConfig,
    
    pub fn init() ZenOfficeController {
        return ZenOfficeController{
            .desk = DeskController.init(),
            .projector = ProjectorDisplay.init(),
            .keyboard = KeyboardConfig.init(),
        };
    }
    
    // Preset: Standing position
    pub fn preset_standing(self: *ZenOfficeController) void {
        self.desk.move_to_preset(.standing);
        self.projector.set_brightness(80);
    }
    
    // Preset: Sitting position
    pub fn preset_sitting(self: *ZenOfficeController) void {
        self.desk.move_to_preset(.sitting);
        self.projector.set_brightness(70);
    }
    
    // Preset: Lotus position
    pub fn preset_lotus(self: *ZenOfficeController) void {
        self.desk.move_to_preset(.lotus);
        self.projector.set_brightness(60);
    }
};
```

---

### Lighting Integration

**Natural Lighting**:
- Window placement (if available)
- Adjustable blinds
- Natural light optimization

**Artificial Lighting**:
- LED task lighting (desk-mounted)
- Ambient lighting (room)
- Projector integration (display lighting)

---

## Bill of Materials (Complete Office)

### 4K Laser Projector

| Component | Cost |
|-----------|------|
| Controller Board | $100-$200 |
| DLP/LCoS Panel | $500-$1,500 |
| RGB Laser Module | $200-$800 |
| Optics | $160-$550 |
| Power & Cooling | $150-$250 |
| 3D Printing | $65-$160 |
| **Subtotal** | **$1,175-$3,510** |

---

### Motorized Standing/Sitting Desk

| Component | Cost |
|-----------|------|
| Desktop (USA Hardwood) | $500-$2,000 |
| Frame & Motors | $400-$800 |
| Control System | $50-$300 |
| Finishing | $100-$200 |
| Assembly | $0-$1,000 (DIY or professional) |
| **Subtotal** | **$1,050-$4,300** |

---

### Open-Hardware Split Keyboard

| Component | Cost |
|-----------|------|
| PCBs | $50-$100 |
| Case (3D Printing) | $40-$80 |
| Switches (Cherry Silent Red MX) | $120-$180 |
| Keycaps | $50-$150 |
| Microcontroller | $10-$20 |
| Cables | $10-$20 |
| Tenting Kit | $10-$20 |
| **Subtotal** | **$290-$570** |

---

### Office Accessories

| Component | Cost |
|-----------|------|
| Cable Management | $50-$100 |
| Lighting | $100-$300 |
| Power Strip | $30-$50 |
| Desk Mat | $20-$50 |
| **Subtotal** | **$200-$500** |

---

### Total Office Cost

**Minimum**: $2,715-$8,880
**Maximum**: $3,515-$12,880

**Recommended Build**: $3,000-$10,000

---

## Assembly Timeline

### Phase 1: Planning & Sourcing (Weeks 1-2)

1. **Finalize Design**:
   - Review all component designs
   - Finalize material choices
   - Source suppliers

2. **Order Components**:
   - Order desk materials (hardwood, steel)
   - Order projector components
   - Order keyboard components

3. **Prepare Workspace**:
   - Measure office space
   - Plan layout
   - Prepare assembly area

---

### Phase 2: Desk Assembly (Weeks 3-6)

1. **Desktop Preparation**:
   - Cut and finish desktop (hardwood)
   - Sand and finish
   - Install cable management

2. **Frame Assembly**:
   - Cut steel frame
   - Weld/bolt frame
   - Install motors and actuators

3. **Control System**:
   - Install motor controller
   - Install control interface
   - Calibrate height sensors

4. **Final Assembly**:
   - Mount desktop to frame
   - Test motor system
   - Set presets

---

### Phase 3: Projector Assembly (Weeks 7-10)

1. **Component Assembly**:
   - Assemble laser module
   - Assemble display module
   - Assemble optical system

2. **Enclosure**:
   - 3D print enclosure parts
   - Assemble enclosure
   - Install components

3. **Integration**:
   - Install projector (ceiling mount)
   - Connect to Grain OS
   - Calibrate display

---

### Phase 4: Keyboard Assembly (Weeks 11-12)

1. **PCB Preparation**:
   - Order PCBs
   - Solder components
   - Test PCBs

2. **Case Printing**:
   - 3D print case parts
   - Finish and test fit

3. **Final Assembly**:
   - Install switches and keycaps
   - Assemble keyboard
   - Flash firmware
   - Test keyboard

---

### Phase 5: Integration & Calibration (Weeks 13-14)

1. **Office Setup**:
   - Install all components
   - Cable management
   - Lighting setup

2. **Grain OS Integration**:
   - Install desk control app
   - Install projector driver
   - Configure keyboard
   - Test unified control

3. **Calibration**:
   - Calibrate desk presets
   - Calibrate projector (color, focus)
   - Calibrate keyboard (keymap, tenting)

4. **Final Testing**:
   - Test all components
   - Test Grain OS integration
   - Fine-tune settings

---

## Open Source License

**Hardware**: CERN Open Hardware License 2.0 (CERN-OHL-2.0)
**Software**: MIT License or Apache 2.0
**Documentation**: CC-BY-SA 4.0

**Repository Structure**:
```
zen-office-design/
├── desk/
│   ├── hardware/          # Frame design, motor system
│   ├── firmware/          # Motor controller firmware
│   └── docs/             # Assembly instructions
├── keyboard/
│   ├── hardware/          # PCB design, case 3D models
│   ├── firmware/          # QMK/ZMK firmware
│   └── docs/             # Assembly instructions
├── projector/
│   └── [reference to existing design]
├── integration/
│   └── grain_os/         # Grain OS integration code
└── README.md
```

---

## Sustainability & Ecological Considerations

### Materials

**USA-Grown Hardwoods**:
- Sustainably harvested
- Local sourcing (reduced transportation)
- Long-lasting (durable)
- Natural finishes (low-VOC)

**Bamboo** (Alternative):
- Rapidly renewable
- Sustainable cultivation
- Ecological finish options

**Steel Frame**:
- Recyclable
- Powder-coated (low-VOC)
- Long-lasting

**3D Printing Materials**:
- PLA (biodegradable, plant-based)
- PETG (recyclable)
- Minimize waste (optimized designs)

---

### Repairability

**Modular Design**:
- Each component replaceable
- Standard connectors
- Open-source replacement parts

**Longevity**:
- Durable materials (hardwood, steel)
- Quality components (Cherry MX switches)
- Repairable design (no proprietary parts)

---

## Conclusion

**Private Zen Office Design** with:

1. **4K Laser Projector**: Open-hardware, Grain OS integrated
2. **Motorized Standing/Sitting Desk**: 8" to 28" range, sustainable materials
3. **Open-Hardware Split Keyboard**: Patent-free, Cherry Silent Red MX, tenting kit
4. **Sustainable Materials**: USA-grown hardwoods, ecological finishes
5. **Grain OS Integration**: Unified control, native integration

**Key Advantages**:
- ✅ **Zen Design**: Minimalist, focused, sustainable
- ✅ **Ergonomic Excellence**: Standing, sitting, floor sitting (lotus)
- ✅ **Open Source**: All design files, firmware, documentation open
- ✅ **Repairable**: Modular, standard parts, long-lasting
- ✅ **Grain OS Native**: Full integration with Grain OS ecosystem

**Total Cost**: $3,000-$10,000 (depending on material choices)

**Next Steps**: Begin Phase 1 (Planning & Sourcing), finalize material choices, order components.

---

## References & Resources

- **4K Projector Design**: `docs/zyx/open_hardware_4k_laser_projector_grain_os_2025-12-30.md`
- **Open-Source Keyboards**: ergodox.io, keeb.io, bastardkb.com
- **Sustainable Wood**: Local sawmills, sustainable forestry certified suppliers
- **Linear Actuators**: Progressive Automations, Firgelli, Amazon
- **Motor Controllers**: ESP32, Raspberry Pi Pico, open-source controllers
- **Grain OS**: github.com/teamcarry11/xy-mathematics

---

**Date**: 2025-12-30  
**Author**: Glow G2 (Grain Free Agent)  
**Status**: Complete Zen Office Design Document  
**Voice**: Positive, first-principles, helpful, succinct yet complete
