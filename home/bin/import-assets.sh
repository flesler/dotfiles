#!/bin/bash

root=$1
# Copy in a directory structure by YEAR/MONTH/DAY & Optimize
for f in $(find . -type f | grep -i -e .MP4 -e .MOV); do # -e .JPG -e .JPEG -e .PNG -e .GIF -e .MP4 -e .MOV); do
  date=$(exif --tag "Date and Time" "$f" 2>/dev/null | grep "Value:" | sed 's/  Value: //' | sed -r 's/ .*//' | sed 's/:/\//g')
  if [[ -z "$date" ]]; then
    date=$(stat "$f" | grep "Modify:" | sed 's/Modify: //' | sed -r 's/ .*//' | sed 's/-/\//g')
    if [[ -z "$date" ]]; then
      echo "FAILED: $f: $date"
      continue
    fi
  fi
  dir=$root/$date
  # mkdir -p $dir
  # Lower case extension
  filename=$(basename $f | sed -r 's/\.([A-Z0-9]{3,4})$/.\L\1/')
  dest=$dir/$filename
  tmpfile=$root/$filename
  # tmpfile=$f
  if [ -f "$dest" ]; then
    echo "Skipped! $f to $dest"
  elif [[ "$filename" = *".jpg" ]] || [[ "$filename" = *".jpeg" ]]; then
    echo "Optimizing JPG $f to $dest"
    jpegoptim -pP -m90 $f --stdout > "$dest"
  elif [[ "$filename" = *".png" ]]; then
    echo "Optimizing PNG $f to $dest"
    optipng -preserve -quiet -o2 -out "$dest" "$f"
  elif [[ "$filename" = *".mov" ]]; then
    dest="$dest.mp4"
    if [ -f "$dest" ]; then
      echo "Skipped! $f to $dest"
    else
      echo "Optimizing MOV $f to $dest"
      # ffmpeg -y -loglevel error -i "$f" -codec copy "$dest"
      # cp "$f" "$tmpfile"
      # ffmpeg -y -loglevel error -i "$tmpfile" -vcodec libx264 -crf 28 -preset faster -tune film "$dest"
    fi
  elif [[ "$filename" = *".mp4" ]]; then
    echo "Optimizing MP4 $f to $dest"
    # cp "$f" "$tmpfile"
    # ffmpeg -y -loglevel error -i "$tmpfile" -vcodec libx264 -crf 28 -preset faster -tune film "$dest"
  else
    echo "Copying $f to $dest"
    cp "$f" "$dest"
  fi
  # rm -f $tmpfile
done
