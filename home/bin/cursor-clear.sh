#!/bin/bash

# Clear ALL file edit history from Cursor (across all projects)
# This removes ONLY file editing history, NOT chat history or other settings

echo "🧹 Clearing ALL file edit history from Cursor..."
echo "⚠️  This will delete undo/redo history for all files in all projects"
echo ""

# Check if history directory exists
if [ ! -d ~/.config/Cursor/User/History ]; then
  echo "❌ History directory not found: ~/.config/Cursor/User/History"
  exit 1
fi

# Count total files and size before deletion
total_files=$(find ~/.config/Cursor/User/History -name '*.json' 2>/dev/null | wc -l)
total_size=$(du -sh ~/.config/Cursor/User/History 2>/dev/null | cut -f1)

echo "📊 Current state:"
echo "   📁 Files: $total_files"
echo "   💾 Size: $total_size"
echo ""

read -p "🚨 Delete ALL file edit history? This cannot be undone! (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Cancelled - nothing was deleted"
  exit 0
fi

echo ""
echo "🗑️  Deleting all file edit history..."

# Delete all JSON files in History directory (these are file edit snapshots)
deleted_count=0
for file in $(find ~/.config/Cursor/User/History -name '*.json' 2>/dev/null); do
  if rm -f "$file" 2>/dev/null; then
    ((deleted_count++))
  fi
done

# Clean up empty directories
find ~/.config/Cursor/User/History -type d -empty -delete 2>/dev/null

echo "✅ Deleted $deleted_count file edit history files"

# Show final state
if [ -d ~/.config/Cursor/User/History ]; then
  remaining_files=$(find ~/.config/Cursor/User/History -name '*.json' 2>/dev/null | wc -l)
  remaining_size=$(du -sh ~/.config/Cursor/User/History 2>/dev/null | cut -f1)
  echo "📊 After cleanup:"
  echo "   📁 Files: $remaining_files"
  echo "   💾 Size: $remaining_size"
else
  echo "📊 History directory is now empty"
fi

echo ""
echo "🎯 File edit history cleared successfully!"
echo "💡 Your chat history and settings remain untouched"
echo "🔄 Restart Cursor to see the changes" 