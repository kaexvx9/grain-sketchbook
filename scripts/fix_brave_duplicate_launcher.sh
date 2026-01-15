#!/bin/bash
# Fix duplicate Brave browser launchers

echo "=== Brave Browser Launcher Fix ==="
echo ""

# Check which files exist
BRAVE_OLD="/usr/share/applications/brave-browser.desktop"
BRAVE_NEW="/usr/share/applications/com.brave.Browser.desktop"

if [ ! -f "$BRAVE_OLD" ] && [ ! -f "$BRAVE_NEW" ]; then
    echo "No Brave launchers found. Exiting."
    exit 1
fi

echo "Found launchers:"
[ -f "$BRAVE_OLD" ] && echo "  - $BRAVE_OLD (older format)"
[ -f "$BRAVE_NEW" ] && echo "  - $BRAVE_NEW (newer format, should be hidden)"
echo ""

# Check modification dates
if [ -f "$BRAVE_OLD" ] && [ -f "$BRAVE_NEW" ]; then
    OLD_DATE=$(stat -c "%y" "$BRAVE_OLD" 2>/dev/null)
    NEW_DATE=$(stat -c "%y" "$BRAVE_NEW" 2>/dev/null)
    echo "Modification dates:"
    echo "  Old: $OLD_DATE"
    echo "  New: $NEW_DATE"
    echo ""
    
    # Determine which is actually newer
    if [ "$NEW_DATE" \> "$OLD_DATE" ]; then
        echo "✓ $BRAVE_NEW is newer (by modification date)"
        NEWER_FILE="$BRAVE_NEW"
        OLDER_FILE="$BRAVE_OLD"
    else
        echo "✓ $BRAVE_OLD is newer (by modification date)"
        NEWER_FILE="$BRAVE_OLD"
        OLDER_FILE="$BRAVE_NEW"
    fi
    echo ""
fi

# Check NoDisplay flag
if [ -f "$BRAVE_NEW" ]; then
    if grep -q "NoDisplay=true" "$BRAVE_NEW"; then
        echo "✓ $BRAVE_NEW has NoDisplay=true (should be hidden)"
        echo "  If you're still seeing it, the desktop environment may not be respecting NoDisplay"
        echo ""
    fi
fi

echo "=== Recommended Solution ==="
echo ""
echo "Option 1: Hide the older launcher (safest)"
echo "  Add NoDisplay=true to $BRAVE_OLD"
echo ""
echo "Option 2: Remove the older launcher"
echo "  sudo rm $BRAVE_OLD"
echo "  (Note: May affect default browser settings)"
echo ""
echo "Option 3: Keep both but ensure NoDisplay works"
echo "  Update desktop database: sudo update-desktop-database"
echo ""

# Offer to apply Option 1 (safest)
read -p "Apply Option 1 (add NoDisplay=true to older launcher)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$BRAVE_OLD" ]; then
        # Check if NoDisplay already exists
        if grep -q "^NoDisplay=" "$BRAVE_OLD"; then
            # Update existing line
            sudo sed -i 's/^NoDisplay=.*/NoDisplay=true/' "$BRAVE_OLD"
            echo "✓ Updated NoDisplay in $BRAVE_OLD"
        else
            # Add new line before [Desktop Action] section
            sudo sed -i '/^\[Desktop Action new-window\]/i NoDisplay=true' "$BRAVE_OLD"
            echo "✓ Added NoDisplay=true to $BRAVE_OLD"
        fi
        sudo update-desktop-database
        echo "✓ Updated desktop database"
        echo ""
        echo "Done! The older launcher should now be hidden."
        echo "You may need to log out and back in for changes to take effect."
    else
        echo "Older launcher not found. Nothing to do."
    fi
else
    echo "No changes made. Run this script again when ready."
fi
