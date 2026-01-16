# Ubuntu Font Scaling Modes

**Date**: 2026-01-16  
**Desktop**: GNOME on Wayland  
**Purpose**: Document font scaling settings for different display configurations

---

## Font Scaling Modes

### Monitor Mode
**Use case**: External monitor at coworking space or desk setup  
**Font scaling factor**: `1.0`  
**Command to apply**:
```bash
gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
```

**Date saved**: 2026-01-16  
**Context**: Smaller font size optimized for larger external monitor viewing distance

---

### Laptop Mode
**Use case**: Framework laptop screen, coffee shop, portable use  
**Font scaling factor**: `1.0` (default)  
**Command to apply**:
```bash
gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
```

**Date saved**: 2026-01-16  
**Context**: Standard font size for laptop screen viewing distance

---

## Quick Reference

**Check current setting**:
```bash
gsettings get org.gnome.desktop.interface text-scaling-factor
```

**Set to Monitor Mode**:
```bash
gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
```

**Set to Laptop Mode**:
```bash
gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
```

**Note**: Changes apply immediately, no restart required.

---

## Notes

- Default GNOME font scaling factor is `1.0`
- Values can range from `0.5` (smaller) to `3.0` (larger)
- Adjust based on display size, viewing distance, and personal preference
- Settings persist across sessions
