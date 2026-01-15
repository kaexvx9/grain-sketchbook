#!/bin/bash
# Script to investigate duplicate Brave browser launchers

echo "=== Finding Brave Browser Launchers ==="
echo ""

# Find all Brave desktop files
echo "1. Searching for Brave desktop files..."
BRAVE_FILES=$(find /usr/share/applications ~/.local/share/applications -name "*brave*" -o -name "*Brave*" 2>/dev/null)

if [ -z "$BRAVE_FILES" ]; then
    echo "   No Brave desktop files found in standard locations."
    echo "   Trying broader search..."
    BRAVE_FILES=$(find /usr/share/applications ~/.local/share/applications -name "*.desktop" -exec grep -l -i "brave" {} \; 2>/dev/null)
fi

if [ -z "$BRAVE_FILES" ]; then
    echo "   Still no files found. Checking if Brave is installed..."
    echo ""
    echo "2. Checking installed packages:"
    dpkg -l | grep -i brave || echo "   No Brave packages found via dpkg"
    echo ""
    echo "3. Checking executable locations:"
    which brave brave-browser 2>/dev/null || echo "   Brave executable not in PATH"
    echo ""
    echo "4. Checking /opt directory:"
    find /opt -maxdepth 3 -name "*brave*" -o -name "*Brave*" 2>/dev/null | head -5 || echo "   Nothing found in /opt"
    exit 1
fi

echo "   Found the following files:"
echo "$BRAVE_FILES" | while read file; do
    echo "   - $file"
done
echo ""

# Check details of each file
echo "=== Comparing Launcher Files ==="
echo ""

for file in $BRAVE_FILES; do
    echo "--- $file ---"
    echo "Modified: $(ls -lh "$file" | awk '{print $6, $7, $8}')"
    echo "Executable: $(grep "^Exec=" "$file" | head -1)"
    echo "Name: $(grep "^Name=" "$file" | head -1)"
    echo "Version: $(grep "^Version=" "$file" | head -1 || echo "Not specified")"
    echo ""
done

# Determine which is newer
echo "=== Recommendation ==="
echo ""

LATEST=$(echo "$BRAVE_FILES" | xargs ls -t | head -1)
echo "Newest file (by modification date): $LATEST"
echo ""

# Check if executables exist
echo "Checking if executables exist:"
for file in $BRAVE_FILES; do
    EXEC=$(grep "^Exec=" "$file" | head -1 | sed 's/^Exec=//' | sed 's/ %.*//')
    if command -v "$EXEC" >/dev/null 2>&1 || [ -f "$EXEC" ]; then
        echo "✓ $file -> $EXEC (exists)"
    else
        echo "✗ $file -> $EXEC (NOT FOUND)"
    fi
done

echo ""
echo "=== Summary ==="
echo "Keep: $LATEST"
echo ""
echo "To remove duplicates, run:"
for file in $BRAVE_FILES; do
    if [ "$file" != "$LATEST" ]; then
        if [[ "$file" == ~/.local/share/applications/* ]]; then
            echo "  rm '$file'"
        else
            echo "  sudo rm '$file'"
        fi
    fi
done
echo ""
echo "Then update desktop database:"
echo "  update-desktop-database ~/.local/share/applications"
echo "  sudo update-desktop-database"
