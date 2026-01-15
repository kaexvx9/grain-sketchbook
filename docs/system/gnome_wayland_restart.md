# Restarting GNOME Desktop Environment on Wayland

**Date**: 2026-01-15  
**Desktop**: GNOME on Wayland  
**Purpose**: Refresh desktop environment after changes (e.g., desktop file updates)

---

## Methods to Restart GNOME on Wayland

### Method 1: Alt+F2 Restart Command (Does NOT work on Wayland)

⚠️ **Note**: The `r` restart command is **NOT available on Wayland sessions**. This method only works on X11.

If you're on Wayland, use Method 2 (logout/login) or Method 3 (systemd) instead.

---

### Method 2: Log Out and Log Back In (Safest)

1. Click the system menu (top right corner)
2. Click your user name/account
3. Click **"Log Out"** or **"Sign Out"**
4. Log back in

This is the safest method and ensures all changes are properly applied.

---

### Method 3: Restart User Session (Systemd)

```bash
# Restart the user session
systemctl --user restart gnome-session-manager

# Or restart the entire user session
loginctl terminate-user $USER
```

**Note**: The second command will log you out completely, so save your work first.

---

### Method 4: Kill and Restart GNOME Shell (Advanced)

```bash
# Kill GNOME Shell (it will auto-restart)
killall -SIGQUIT gnome-shell

# Or force restart
killall gnome-shell
```

**Warning**: This may cause a brief black screen. Save your work first.

---

### Method 5: Reload Desktop Database Only (For Desktop File Changes)

If you only updated desktop files, you may just need to refresh the database:

```bash
# Update desktop database
update-desktop-database ~/.local/share/applications
sudo update-desktop-database

# Then use Method 1 (Alt+F2, type 'r') to refresh
```

---

## Recommended Approach for Desktop File Changes (Wayland)

After updating Brave browser launchers on Wayland:

1. **Update desktop database**:
   ```bash
   sudo update-desktop-database
   ```

2. **Restart GNOME Shell** (choose one):
   - **Option A**: Log out and log back in (safest, Method 2)
   - **Option B**: Restart user session: `systemctl --user restart gnome-session-manager`
   - **Option C**: Kill GNOME Shell: `killall -SIGQUIT gnome-shell`

3. **Verify**: Check your application menu - the duplicate should be gone.

---

## Troubleshooting

### If Alt+F2 doesn't work:
- Try typing `restart` instead of `r`
- Check if you're actually on Wayland: `echo $XDG_SESSION_TYPE`
- Try Method 2 (log out/in) instead

### If changes don't appear:
- Make sure you ran `update-desktop-database`
- Try logging out and back in (Method 2)
- Check if desktop files are in correct locations

### To check if you're on Wayland:
```bash
echo $XDG_SESSION_TYPE
# Should output: wayland
```

---

## Quick Reference (Wayland)

**⚠️ Alt+F2 restart does NOT work on Wayland**

**Safest**: Log out and log back in  
**Quick**: `systemctl --user restart gnome-session-manager`  
**For desktop files**: `sudo update-desktop-database` then logout/login
