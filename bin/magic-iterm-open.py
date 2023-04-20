#!/usr/bin/python
# http://stackoverflow.com/questions/18847600/terminal-open-editor-by-click-on-stacktrace-line

import sys
from subprocess import call

def log(*args):
    with open('~/bin/log.txt') as f:
        print(*args, file=f)

log('start')
log(sys.argv)

assert False

if len(sys.argv) > 2:

    pathToSubl = "~/bin/"

    filename, linenum = sys.argv[1], sys.argv[2]
    rest = "" if len(sys.argv) < 4 else sys.argv[3]

    if not filename.endswith('.py'):
        # I believe this approximates iTerm's default
        call(['/usr/bin/open', filename])
    else:
        newLinenum = linenum
        if not str.isdigit(linenum):
            line = linenum.split(",")
            if len(line) > 1:
                newLinenum = filter(str.isdigit, line[1])

        command = ["{0}subl".format(pathToSubl),
                   "--add",  # If you'd like to add to your current sublime project
                   "{0}:{1}".format(filename, newLinenum)]

        call(command)
