#!/usr/bin/env python
import datetime
import numpy as np
import os
import os.path as osp
import glob
import cv2
import insightface
from insightface.app import FaceAnalysis
from insightface.data import get_image as ins_get_image
import sys

assert insightface.__version__>='0.7'

# python extract_faces.py /tmp/ /tmp/face1.jpg /tmp/face2.png

if __name__ == '__main__':
    app = FaceAnalysis(name='buffalo_l')
    app.prepare(ctx_id=0, det_size=(640, 640))
    swapper = insightface.model_zoo.get_model('models/inswapper_128.onnx', download=True, download_zip=True)

    dest = sys.argv[1]
    os.makedirs(dest, exist_ok=True)

    sources = sys.argv[2:]
    for source in sources:
      if not os.path.isfile(source):
        continue
      print('Processing source: ' + source)
      src = cv2.imread(source)
      filename = source.split('/').pop()
      faces = app.get(src)
      for i, face in enumerate(faces):
          path = filename
          if i > 0:
            path = path.replace('.', '-' + str(i) + '.')
          out = os.path.join(dest, path)
          if os.path.exists(out):
            print('Face already found, skipping: ' + out)
            continue
          img, _ = swapper.get(src, face, face, paste_back=False)
          cv2.imwrite(out, img)
          print('Saved face at: ' + out)


