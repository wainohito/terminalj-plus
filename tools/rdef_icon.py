# Copyright 2026 RenkuOS contributors.
# SPDX-License-Identifier: MIT
#
# Writes the vector_icon resource of an rdef file as an HVIF file, for the
# BEOS:ICON attribute that Tracker and the Deskbar show.
#
# Usage: rdef_icon.py <in.rdef> <out.hvif>
import re
import sys

text = open(sys.argv[1], encoding='utf-8').read()
icon = re.search(r'resource vector_icon \{(.*?)\};', text, re.S).group(1)
data = bytes.fromhex(''.join(re.findall(r'\$"([0-9A-Fa-f]+)"', icon)))
open(sys.argv[2], 'wb').write(data)
