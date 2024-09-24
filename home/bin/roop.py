#!/usr/bin/env python3

from PIL import Image
import os
import sys
import roop.globals
from roop.utilities import is_image
import shutil
import subprocess

import roop.core
import datetime

PROMPT='parameters'
ROOT = '/tmp'
PHOTOS = '/tmp/photos/'
SOURCES = '/tmp/sources/'
TMP = '/tmp/temp.png'
OUT = '/tmp/out' # /home/flesler/Pictures/outputs/FUTURE/v3

def log(msg):
  now = datetime.datetime.now().replace(microsecond=0).isoformat()
  print(f'{now} > {msg}')

def listdir(path):
  return list(map(lambda file: os.path.join(path, file), os.listdir(path)))

def run_once(photo, source, output, dryRun, index, total):
  if os.path.exists(output):
    log(f"{output} already exists, skipping")
    return
  if dryRun:
    log(f"Simulated creation of image at {output}")
    return

  roop.globals.source_path = photo
  roop.globals.target_path = source
  roop.globals.output_path = TMP
  roop.core.start()
  if not is_image(TMP):
    log(f"ERROR: Failed to generate {output}!")
    return

  image = Image.open(source)
  if PROMPT in image.info:
    # Copy the Stable Diffusion prompt
    subprocess.call(['mogrify', '-set', PROMPT, image.info[PROMPT], TMP])
  shutil.move(TMP, output)
  log(f"({index}/{total}) Created image at {output}")

def run_many(photos, sources, out, dryRun, loopback):
  total = len(photos) * len(sources)
  index = 0
  for source in sources:
    if not is_image(source):
      index += len(photos)
      continue
    for photo in photos:
      index += 1
      if not is_image(photo):
        continue
      if not is_image(source):
        # In case it's deleted mid run
        continue
      p=os.path.basename(photo).split('.')[0]
      s=os.path.basename(source).split('.')[0]
      output=f"{out}/{s}-{p}.png"
      run_once(photo, source, output, dryRun, index, total)

      if not loopback:
        continue
      loopbackOutput = output.replace('.png', '-lb.png')
      run_once(photo, output, loopbackOutput, dryRun, index, total)

def run():
  photos = listdir(PHOTOS)
  sources = listdir(SOURCES)
  out = OUT
  dryRun = False
  loopback = False
  enhance = True
  i = 1
  argv = sys.argv
  while i < len(argv):
    arg = argv[i]
    i+=1
    if arg == '-p':
      match = argv[i]
      i+=1
      if os.path.exists(match):
        photos = listdir(match)
      else:
        photos = list(filter(lambda p: match in p, photos))
    elif arg == '-s':
      match = argv[i]
      i+=1
      if os.path.exists(match):
        sources = listdir(match)
      else:
        sources = list(filter(lambda s: match in s, sources))
    elif arg == '-o':
      out = argv[i]
      i+=1
    elif arg == '-D':
      dryRun = True
    elif arg == '-E':
      enhance = False
    elif arg == '-L':
      loopback = True
    else:
      quit(f'ERROR: Unknown option "{arg}"')

  photos = sorted(photos)
  sources = sorted(sources)

  sys.argv = argv[0:1]
  roop.core.parse_args()
  roop.globals.headless = True
  roop.globals.many_faces = True
  roop.globals.execution_threads = 3
  roop.globals.frame_processors = ['face_swapper']
  if enhance:
    roop.globals.frame_processors.append('face_enhancer')

  os.makedirs(out, exist_ok=True)
  run_many(photos, sources, out, dryRun, loopback)

if __name__ == '__main__':
  run()