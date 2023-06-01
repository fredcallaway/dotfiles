#!/usr/bin/env python3.10

import asyncio
import iterm2

import re
import os
import sys

sys.path.insert(0, '/Users/fred/Library/Application Support/iTerm2/Scripts')
from lib import *

from iterm2 import Point

async def main(connection):
    app = await iterm2.async_get_app(connection)

    @iterm2.RPC
    async def lazygit():
        await singleton(connection, 'lazygit', cd=True)
    await lazygit.async_register(connection)

    @iterm2.RPC
    async def htop():
        await singleton(connection, '/usr/local/bin/htop')
    await htop.async_register(connection)

    @iterm2.RPC
    async def open_sublime():
        window = app.current_window
        project = await window.async_get_variable('user.project')
        if project:
            target = f"/Users/fred/sublime-projects/{project}.sublime-workspace"
        else:
            1
            target = await app.current_window.current_tab.current_session.async_get_variable('path')
        os.system(f'subl "{target}"')
    await open_sublime.async_register(connection)

    @iterm2.RPC
    async def copy_line():
        window = app.current_window
        tab = window.current_tab
        session = tab.current_session
        screen = await session.async_get_screen_contents()

        # Select the screen contents. Note that selection "y" coordinates include
        # overflow, which is lines that have been lost because scrollback history
        # exceeded its limit. These coordinates are consistent across scroll events,
        # although they may refer to no-longer-visible lines.
        line_info = await session.async_get_line_info()
        (height, history, overflow, first) = (
            line_info.mutable_area_height,
            line_info.scrollback_buffer_height,
            line_info.overflow,
            line_info.first_visible_line_number)

        # start = iterm2.Point(0, first + overflow + height - 1)
        cursor = screen.cursor_coord

        coordRange = iterm2.CoordRange(Point(0, cursor.y), Point(0, cursor.y+1))
        windowedCoordRange = iterm2.WindowedCoordRange(coordRange)
        sub = iterm2.SubSelection(windowedCoordRange, iterm2.SelectionMode.CHARACTER, False)
        selection = iterm2.Selection([sub])
        text = await session.async_get_selection_text(selection)
        text = text.strip()
        regex = '(' + ')|('.join((
            r'In \[\d+\]: ',
            r'julia> ',
            r'R> ',
            r'.* pkg> ',
            r'shell> ',
            r'r\$> ?',
            r'\#\!> ?',
            r'❯ ',
        )) + ')'
        text = re.sub(regex, '', text)
        with open('/tmp/clip', 'w') as f:
            f.write(text)

        # os.system(f'''pbcopy <<'EOF'\n{text}\nEOF''')
        os.system(f'''cat /tmp/clip | pbcopy''')
    await copy_line.async_register(connection)

    # async with iterm2.CustomControlSequenceMonitor(connection, "zebra", r'(\w+) ?(.*)') as mon:
    #     while True:
    #         match = await mon.async_get()
    #         cmd = match.group(1)
    #         args = match.group(2).split(' ')
    #         print(cmd, args)
    #         if cmd == 'lazygit':
    #             await lazygit()
    #         if cmd == 'htop':
    #             await htop()
    #         if cmd == 'project':
    #             await activate_project()


# This instructs the script to run the "main" coroutine and to keep running even after it returns.
iterm2.run_forever(main)
