#!/usr/bin/env python3
import sys
# heading = sys.argv[1]
heading = '##'
for line in sys.stdin:
    if line.startswith('- '):
        print(heading, line[2:], end='')
    elif line.startswith('    '):
        print(line[4:], end='')
    else:
        print(line, end='')