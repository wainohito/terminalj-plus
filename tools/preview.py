# Copyright 2026 RenkuOS contributors.
# SPDX-License-Identifier: MIT
#
# A rough preview of an HVIF icon: shapes as filled polygons through their
# points (curves, gradients and transformations are ignored).
import sys
from PIL import Image, ImageDraw
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hvif

def render(data, size=256):
    styles, paths, shapes = hvif.parse(data)
    scale = size / 64.0
    im = Image.new('RGBA', (size, size), (220, 220, 220, 255))
    for raw, style, path_indices in shapes:
        if raw[3 + len(path_indices)] & (hvif.SHAPE_TRANSLATION | hvif.SHAPE_TRANSFORM):
            continue
        layer = Image.new('RGBA', im.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer)
        for index in path_indices:
            points = [(x * scale, y * scale) for x, y in paths[index][1]]
            if len(points) > 2:
                draw.polygon(points, fill=styles[style][1])
        im = Image.alpha_composite(im, layer)
    return im

if __name__ == '__main__':
    render(open(sys.argv[1], 'rb').read()).save(sys.argv[2])
