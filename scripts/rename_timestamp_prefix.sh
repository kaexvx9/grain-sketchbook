#!/bin/bash
# Script to rename files with timestamp suffix to timestamp prefix
# Usage: ./scripts/rename_timestamp_prefix.sh

set -e

cd "$(dirname "$0")/.."

find docs/agent-communications docs/architecture/decisions -name "*2026-01-02*.md" -type f | while read file; do
  basename=$(basename "$file")
  dirname=$(dirname "$file")
  
  # Extract timestamp pattern: YYYY-MM-DD-HHMMSS-pst
  if [[ $basename =~ ^(.+)_(2026-01-02-[0-9]{6}-pst)\.md$ ]]; then
    name_part="${BASH_REMATCH[1]}"
    timestamp="${BASH_REMATCH[2]}"
    # Create new filename with timestamp prefix
    new_name="${timestamp}_${name_part}.md"
    new_path="$dirname/$new_name"
    
    # Only rename if different
    if [ "$basename" != "$new_name" ]; then
      echo "Renaming: $file -> $new_path"
      git mv "$file" "$new_path"
    fi
  elif [[ $basename =~ ^(.+)-(2026-01-02-[0-9]{6}-pst)\.md$ ]]; then
    # Handle format: name-YYYY-MM-DD-HHMMSS-pst.md
    name_part="${BASH_REMATCH[1]}"
    timestamp="${BASH_REMATCH[2]}"
    # Create new filename with timestamp prefix
    new_name="${timestamp}_${name_part}.md"
    new_path="$dirname/$new_name"
    
    # Only rename if different
    if [ "$basename" != "$new_name" ]; then
      echo "Renaming: $file -> $new_path"
      git mv "$file" "$new_path"
    fi
  fi
done

echo "Done renaming files with timestamp prefix"

