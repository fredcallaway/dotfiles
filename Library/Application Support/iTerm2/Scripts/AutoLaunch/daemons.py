#!/usr/bin/env python3.10

import asyncio
import iterm2
from iterm2 import Point

import re
import os
import sys
sys.path.insert(0, '/usr/local/lib/miniconda3/lib/python3.7/site-packages/')
import jstyleson as json

async def create_window(connection, project, folder=None, ssh=None):
    if folder is None:
        with open(f'/Users/fred/sublime-projects/{project}.sublime-project') as f:
            conf = json.load(f)
            folder = conf['folders'][0]['path']

    print(f'create_window({connection}, {project})')
    tmux = '/usr/local/bin/tmux'
    if ssh in ('g1', 'g2', 'scotty'):
        tmux = '~/bin/tmux'
    folder = os.path.expanduser(folder).replace(' ','\\ ')
    cmd = rf'''
        {tmux} -CC new-session -A -s {project} "cd {folder} && /bin/zsh --login -ic '~/bin/lf'"
    '''.strip()
    print('command', cmd)
        # {tmux} -CC new-session -A -s {project}
    if ssh:
        cmd = f"ssh -t {ssh} '{cmd}'"

    app = await iterm2.async_get_app(connection)
    window = await iterm2.Window.async_create(connection, command=cmd, profile='tmuxconn')
    # await window.current_tab.async_set_title(project)
    # await window.async_set_title(project)
    await window.async_set_variable('user.project', project)
    return window

async def get_window(connection, project):
    app = await iterm2.async_get_app(connection)
    for window in app.windows:
        this_project = await window.async_get_variable('user.project')
        if this_project == project:
            return window

async def singleton(connection, cmd, id_=None, cd=False):
    if id_ is None:
        id_ = cmd
    app = await iterm2.async_get_app(connection)
    cmd = f"zsh -ic '{cmd}'"
    window = app.current_window

    if window is None:
        await iterm2.Window.async_create(connection, command=cmd)
    else:
        # check if already exists
        lg_tab = None
        for tab in window.tabs:
            for session in tab.sessions:
                if (await session.async_get_variable(f"user.{id_}")):
                    lg_tab = tab
                    break
        # or create new window
        if lg_tab is None:
            if cd:
                path = await app.current_window.current_tab.current_session.async_get_variable('path')
                cmd = f'cd {path} && {cmd}'
            lg_tab = await window.async_create_tab(command=cmd)
            await lg_tab.current_session.async_set_variable(f"user.{id_}", True)

        await lg_tab.async_activate()




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
        print('before:', text)
        text = text.strip()
        regex = '(' + ')|('.join((
            r'In \[\d+\]: ',
            r'julia> ',
            r'.* pkg> ',
            r'shell> ',
            r'r\$> ?',
            r'\#\!> ?',
            r'❯ ',
        )) + ')'
        text = re.sub(regex, '', text)
        print('after sub:', text)
        with open('/tmp/clip', 'w') as f:
            f.write(text)

        # os.system(f'''pbcopy <<'EOF'\n{text}\nEOF''')
        os.system(f'''cat /tmp/clip | pbcopy''')

    await copy_line.async_register(connection)

    async with iterm2.CustomControlSequenceMonitor(connection, "zebra", r'(\w+) ?(.*)') as mon:
        while True:
            match = await mon.async_get()
            cmd = match.group(1)
            args = match.group(2).split(' ')
            print(cmd, args)
            if cmd == 'lazygit':
                await lazygit()
            if cmd == 'htop':
                await htop()
            if cmd == 'project':
                project = args[0]
                window = await get_window(connection, project)
                if window:
                    await window.async_activate()
                else:
                    await create_window(connection, project)



# This instructs the script to run the "main" coroutine and to keep running even after it returns.
iterm2.run_forever(main)
