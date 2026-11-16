# Copyright 2026 RenkuOS contributors.
# SPDX-License-Identifier: MIT
#
# Adds a "+" badge to the top right corner of an HVIF icon (Terminal's, for
# TerminalJ+): a dark outline and an orange fill, drawn over the icon.
#
# Usage: add_plus.py <in.hvif> <out.hvif>
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hvif

CENTER = (53.0, 12.0)


def plus(length, thickness):
    cx, cy = CENTER
    a, t = length / 2.0, thickness / 2.0
    return [(cx - t, cy - a), (cx + t, cy - a), (cx + t, cy - t),
            (cx + a, cy - t), (cx + a, cy + t), (cx + t, cy + t),
            (cx + t, cy + a), (cx - t, cy + a), (cx - t, cy + t),
            (cx - a, cy + t), (cx - a, cy - t), (cx - t, cy - t)]


def main():
    data = open(sys.argv[1], 'rb').read()
    styles, paths, shapes = hvif.parse(data)
    styles = [raw for raw, _ in styles]
    paths = [raw for raw, _ in paths]
    shapes = [raw for raw, _, _ in shapes]

    outline_style = len(styles)
    styles.append(hvif.solid_style(40, 40, 40))
    fill_style = len(styles)
    styles.append(hvif.solid_style(242, 101, 34))  # the orange of RenkuOS
    outline_path = len(paths)
    paths.append(hvif.polygon_path(plus(22, 10)))
    fill_path = len(paths)
    paths.append(hvif.polygon_path(plus(18, 6)))
    shapes.append(hvif.shape(outline_style, outline_path))
    shapes.append(hvif.shape(fill_style, fill_path))

    open(sys.argv[2], 'wb').write(hvif.build(styles, paths, shapes))


if __name__ == '__main__':
    main()
