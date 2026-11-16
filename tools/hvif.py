# Copyright 2026 RenkuOS contributors.
# SPDX-License-Identifier: MIT
#
# Reads and writes Haiku Vector Icon Format (HVIF) data, enough to add shapes
# to an existing icon and to preview it.

import struct

STYLE_SOLID = 1
STYLE_GRADIENT = 2
STYLE_SOLID_NO_ALPHA = 3
STYLE_GRAY = 4
STYLE_GRAY_NO_ALPHA = 5

PATH_CLOSED = 1 << 1
PATH_COMMANDS = 1 << 2
PATH_NO_CURVES = 1 << 3

SHAPE_TRANSFORM = 1 << 1
SHAPE_LOD = 1 << 3
SHAPE_TRANSFORMERS = 1 << 4
SHAPE_TRANSLATION = 1 << 5


class Reader:
  def __init__(self, data):
    self.data = data
    self.pos = 0

  def u8(self):
    v = self.data[self.pos]
    self.pos += 1
    return v

  def take(self, n):
    v = self.data[self.pos:self.pos + n]
    self.pos += n
    return v

  def coord(self):
    b = self.u8()
    if b & 0x80:
      return (((b & 0x7f) << 8) | self.u8()) / 102.0 - 128.0
    return b - 32.0


def read_style(r):
  start = r.pos
  kind = r.u8()
  color = None
  if kind == STYLE_SOLID:
    color = tuple(r.take(4))
  elif kind == STYLE_SOLID_NO_ALPHA:
    color = tuple(r.take(3)) + (255,)
  elif kind == STYLE_GRAY:
    g, a = r.take(2)
    color = (g, g, g, a)
  elif kind == STYLE_GRAY_NO_ALPHA:
    g = r.u8()
    color = (g, g, g, 255)
  elif kind == STYLE_GRADIENT:
    r.u8()  # gradient type
    flags = r.u8()
    stops = r.u8()
    if flags & (1 << 1):
      r.take(6 * 3)
    colors = []
    for _ in range(stops):
      r.u8()  # offset
      if flags & (1 << 4):  # grays
        g = r.u8()
        a = 255 if flags & (1 << 2) else r.u8()
        colors.append((g, g, g, a))
      elif flags & (1 << 2):  # no alpha
        colors.append(tuple(r.take(3)) + (255,))
      else:
        colors.append(tuple(r.take(4)))
    color = colors[len(colors) // 2]
  else:
    raise ValueError('unknown style %d' % kind)
  return r.data[start:r.pos], color


def read_path(r):
  start = r.pos
  flags = r.u8()
  count = r.u8()
  points = []
  if flags & PATH_NO_CURVES:
    for _ in range(count):
      points.append((r.coord(), r.coord()))
  elif flags & PATH_COMMANDS:
    commands = r.take((count + 3) // 4)
    x = y = 0.0
    for i in range(count):
      command = (commands[i // 4] >> ((i % 4) * 2)) & 3
      if command == 0:  # horizontal line
        x = r.coord()
      elif command == 1:  # vertical line
        y = r.coord()
      elif command == 2:  # line
        x, y = r.coord(), r.coord()
      else:  # curve
        x, y = r.coord(), r.coord()
        r.coord(), r.coord(), r.coord(), r.coord()
      points.append((x, y))
  else:
    for _ in range(count):
      x, y = r.coord(), r.coord()
      r.coord(), r.coord(), r.coord(), r.coord()
      points.append((x, y))
  return r.data[start:r.pos], points


def read_shape(r):
  start = r.pos
  kind = r.u8()
  if kind != 10:
    raise ValueError('unknown shape %d' % kind)
  style = r.u8()
  paths = [r.u8() for _ in range(r.u8())]
  flags = r.u8()
  if flags & SHAPE_TRANSFORM:
    r.take(6 * 3)
  elif flags & SHAPE_TRANSLATION:
    r.coord(), r.coord()
  if flags & SHAPE_LOD:
    r.take(2)
  if flags & SHAPE_TRANSFORMERS:
    for _ in range(r.u8()):
      t = r.u8()
      if t == 20:
        r.take(6 * 3)
      elif t == 21:
        r.take(3)
      elif t == 22:
        r.take(9 * 3)
      elif t == 23:
        r.take(3)
      else:
        raise ValueError('unknown transformer %d' % t)
  return r.data[start:r.pos], style, paths


def parse(data):
  r = Reader(data)
  if r.take(4) != b'ncif':
    raise ValueError('not an HVIF icon')
  styles = [read_style(r) for _ in range(r.u8())]
  paths = [read_path(r) for _ in range(r.u8())]
  shapes = [read_shape(r) for _ in range(r.u8())]
  if r.pos != len(data):
    raise ValueError('%d bytes left' % (len(data) - r.pos))
  return styles, paths, shapes


def encode_coord(v):
  if v == int(v) and -32 <= v <= 95:
    return bytes([int(v) + 32])
  n = int(round((v + 128.0) * 102))
  return bytes([0x80 | (n >> 8), n & 0xff])


def solid_style(r, g, b, a=255):
  return bytes([STYLE_SOLID, r, g, b, a])


def polygon_path(points):
  out = bytes([PATH_CLOSED | PATH_NO_CURVES, len(points)])
  for x, y in points:
    out += encode_coord(x) + encode_coord(y)
  return out


def shape(style_index, path_index):
  return bytes([10, style_index, 1, path_index, 0])


def build(styles, paths, shapes):
  out = b'ncif' + bytes([len(styles)]) + b''.join(styles)
  out += bytes([len(paths)]) + b''.join(paths)
  out += bytes([len(shapes)]) + b''.join(shapes)
  return out
