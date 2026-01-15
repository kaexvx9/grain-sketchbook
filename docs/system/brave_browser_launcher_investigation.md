# Brave Browser Launcher Investigation

**Date**: 2026-01-15  
**Issue**: Two Brave browser application launchers after `apt upgrade`  
**Goal**: Identify which launcher is newer and remove duplicate

---

## Commands to Run

### 1. Find All Brave Desktop Files

```bash
# Search system-wide
find /usr/share/applications -name "*brave*" -o -name "*Brave*" 2>/dev/null

# Search user-specific
find ~/.local/share/applications -name "*brave*" -o -name "*Brave*" 2>/dev/null

# Search all locations
find /usr/share/applications ~/.local/share/applications -name "*.desktop" -exec grep -l -i "brave" {} \; 2>/dev/null
```

### 2. Check Details of Each Launcher

For each `.desktop` file found, check:

```bash
# View contents
cat /path/to/brave-browser.desktop

# Check modification date (newer = more recent)
ls -lh /path/to/brave-browser.desktop

# Check what executable it points to
grep "^Exec=" /path/to/brave-browser.desktop
```

### 3. Check Installed Brave Packages

```bash
# Check apt packages
dpkg -l | grep -i brave

# Check installed version
apt list --installed 2>/dev/null | grep -i brave

# Check what provides the executable
which brave brave-browser
dpkg -S $(which brave-browser 2>/dev/null) 2>/dev/null
```

### 4. Check Installation Methods

```bash
# Check snap
snap list | grep -i brave

# Check flatpak
flatpak list | grep -i brave

# Check AppImage locations
find ~ -name "*brave*.AppImage" 2>/dev/null
```

### 5. Compare Launcher Files

Once you find both `.desktop` files:

```bash
# Compare modification dates
ls -lht /path/to/brave1.desktop /path/to/brave2.desktop

# Compare contents
diff /path/to/brave1.desktop /path/to/brave2.desktop

# Check which executable each points to
grep "^Exec=" /path/to/brave1.desktop /path/to/brave2.desktop
```

---

## Typical Locations

### System-wide (all users):
- `/usr/share/applications/brave-browser.desktop`
- `/usr/share/applications/brave-browser-nightly.desktop`

### User-specific:
- `~/.local/share/applications/brave-browser.desktop`
- `~/.local/share/applications/brave-browser-nightly.desktop`

### Common Executable Locations:
- `/usr/bin/brave-browser`
- `/usr/bin/brave`
- `/opt/brave.com/brave/brave-browser`
- `~/.local/bin/brave-browser`

---

## How to Identify the Newer One

1. **Check modification date**: `ls -lh` - newer file = more recent timestamp
2. **Check version in Exec line**: Look for version numbers in the Exec path
3. **Check which executable exists**: The launcher pointing to an existing/newer executable is likely correct
4. **Check package installation date**: `dpkg -l | grep brave` shows install date

---

## How to Remove Duplicate

Once you identify which is newer/correct:

### Option 1: Remove User-Specific (if duplicate of system-wide)
```bash
rm ~/.local/share/applications/brave-browser.desktop
update-desktop-database ~/.local/share/applications
```

### Option 2: Remove System-Wide (if duplicate of user-specific)
```bash
sudo rm /usr/share/applications/brave-browser.desktop
sudo update-desktop-database
```

### Option 3: Hide from Menu (keep file but hide)
Edit the `.desktop` file and add:
```
Hidden=true
```

---

## After Cleanup

```bash
# Update desktop database
update-desktop-database ~/.local/share/applications
sudo update-desktop-database

# Refresh application menu (depends on desktop environment)
# For GNOME:
killall gnome-shell  # or logout/login
# For KDE:
kbuildsycoca5
# For XFCE:
xfce4-panel -r
```

---

## Notes

- User-specific launchers (`~/.local/share/applications/`) take precedence over system-wide
- After `apt upgrade`, sometimes both old and new launchers exist
- Check which executable actually exists and works
- Keep the launcher that points to the working executable
