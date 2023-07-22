#!/bin/bash
set -e

dryrun=
force=
open=
gfpgan=1
photo_filter=""
source_filter=""

while [ $# -gt 0 ]; do
  case $1 in
    -D) dryrun=1 ;;
    -F) force=1 ;;
    -O) open=1 ;;
    -E) gfpgan=0 ;;
    -p) photo_filter=$2; shift ;;
    -s) source_filter=$2; shift ;;
    *) echo "Unknown option '$1'"; exit 1
  esac
  shift
done

# Must in the shell
# conda activate roop

# So the weights (gfpgan) are saved in /roop/
cd /media/flesler/Extra/Code/roop/

# No spaces
rename 's/ /-/g' /tmp/{sources,photos}/*

photos=$(ls /tmp/photos/*.* | grep -ie "$photo_filter")
sources=$(ls /tmp/sources/*.* | grep -ie "$source_filter")
tmp=/tmp/temp.png
out=/tmp/out

function render() {
  local photo=$1
  local source=$2
  local processor=$3
  local output=$4

  if [ "$force" = "" ] && [ -f $output ]; then
    echo "$output already exists, skipping"
    return
  fi
  if [ ! -f $photo ] || [ ! -f $source ]; then
    echo "Either the photo or source is missing, skipping"
    return
  fi
  echo "Generating $output"
  if [ "$dryrun" = "1" ]; then
    return
  fi
  rm -f $tmp

  local command="python run.py --source $photo --target $source --output $tmp --many-faces --frame-processor $processor"
  echo $command
  $command

  if [ ! -f $tmp ] || cmp -s $source $tmp; then
    local err="Failed to generate $output"
    echo $err
    notify-send -t 2000 "Roop: $err"
    return
  fi
  mkdir -p $(dirname $output)
  mv $tmp $output
  if [ "$open" = "1" ]; then
    xdg-open $output
  fi
}

for source in $sources; do
  for photo in $photos; do
    p=$(basename $photo | cut -d. -f1)
    s=$(basename $source | cut -d. -f1)
    path=$s-$p.png

    if [ "$gfpgan" = "1" ]; then
      # The 2 steps in one go
      render $photo $source "face_swapper face_enhancer" $out/gfpgan/$path
      continue
    fi

    raw=$out/raw/$path
    render $photo $source face_swapper $raw
    if [ "$gfpgan" = "1" ]; then
      render $raw $raw face_enhancer $out/gfpgan/$path
    fi
  done
done

notify-send -t 2000 "Roop: Finished!"
cd -