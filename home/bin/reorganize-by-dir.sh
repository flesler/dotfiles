#!/bin/bash

set -euo pipefail

SRC_ROOT=.
DST_ROOT=$1

if [[ ! -d "$DST_ROOT" ]]; then
  echo "Destination root directory '$DST_ROOT' does not exist. Creating it."
  mkdir -p "$DST_ROOT"
fi

# Find files in source root recursively (ignore dirs, symlinks etc)
# For each file:
# - extract extension (lowercase, or "no_ext" if none)
# - mkdir -p destination folder DST_ROOT/extension
# - move file to that folder, preserving filename

find "$SRC_ROOT" -type f | while IFS= read -r file; do
  filename=$(basename "$file")
  ext="${filename##*.}"
  # if no extension or ext == filename (means no dot)
  if [[ "$ext" == "$filename" ]]; then
    ext="no_ext"
  else
    # lowercase ext
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  fi

  dst_dir="$DST_ROOT/$ext"
  mkdir -p "$dst_dir"

  # If file with same name exists in destination, rename by adding a counter
  dst_file="$dst_dir/$filename"
  if [[ -e "$dst_file" ]]; then
    base="${filename%.*}"
    ext_part="${filename##*.}"
    if [[ "$ext_part" == "$filename" ]]; then
      ext_part=""
    else
      ext_part=".$ext_part"
    fi

    i=1
    while [[ -e "$dst_dir/${base}_$i$ext_part" ]]; do
      ((i++))
    done
    dst_file="$dst_dir/${base}_$i$ext_part"
  fi

  mv "$file" "$dst_file"
done

echo "Sorting completed."
