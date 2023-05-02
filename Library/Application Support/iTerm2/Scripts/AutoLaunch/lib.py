import asyncio
import iterm2

import re
import os
import sys

from fnmatch import fnmatch

WINDOW_IDS = {}
SINGLETON_TABS = {}

import logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("/tmp/iterm.log"),
        logging.StreamHandler()
    ]
)
from ast import literal_eval

async def activate_project(connection, project):
    app = await iterm2.async_get_app(connection)
    window = await get_window(app, project)
    if window:
        print('if window')
        await window.async_activate()
    else:
        print('else')
        with open(f"/Users/fred/sublime-projects/{project}.sublime-project") as f:
            folder = literal_eval(f.read())['folders'][0]['path']
        await create_window(connection, project, folder=folder)
    await app.async_activate()


async def create_window(connection, project, folder='~', ssh=None):
    tmux = '/usr/local/bin/tmux'
    if ssh in ('g1', 'g2', 'scotty'):
        tmux = '~/bin/tmux'
    folder = os.path.expanduser(folder).replace(' ','\\ ')
    cmd = rf'''
        {tmux} -CC new-session -A -s {project} 'cd {folder}; zsh --login'
    '''.strip()
    logging.info(f'create_window: {cmd}')
    if ssh:
        cmd = f"ssh -t {ssh} '{cmd}'"

    logging.info(f'create_window: {cmd}')
    window = await iterm2.Window.async_create(connection, command=cmd, profile='tmuxconn')
    WINDOW_IDS[project] = window.window_id
    return window

async def create_bare_window(connection, folder=None):
    window = await iterm2.Window.async_create(connection)
    if folder is not None:
        folder = os.path.expanduser(folder)
        await window.current_tab.current_session.async_send_text(f"cd '{folder}'\n")
        app = await iterm2.async_get_app(connection)
        await app.async_activate()
    return window

async def get_window(app, project, file_name=None):
    window = app.get_window_by_id(WINDOW_IDS.get(project))
    if window != None:
        return window
    logging.info('looking for window...')
    for window in app.windows:
        try:
            status = await window.current_tab.current_session.async_get_variable('tmuxStatusLeft')
        except:
            pass
        else:
            this_project = status[2:-3] if status else None  # e.g.  "[ main ]"
            if this_project == project:
                WINDOW_IDS[project] = window.window_id
                logging.info('  found it!')
                return window

async def get_tab(app, file_name):
    if app.current_window:
        for tab in app.current_window.tabs:
            # could try getting a more specific variable here
            title = await tab.async_get_variable('title')
            # if title[2:] == file_name:
            if fnmatch(file_name, title[2:]):
                return tab

def project_name(session):
    logging.info('session_name is %s', session.name)
    match = re.search(r'new-session -A -s ([\w_-]+)', session.name)
    if match:
        return match.group(1)

async def get_tmux(connection, project):
    # get tmux connection
    tmux_conns = await iterm2.async_get_tmux_connections(connection)
    for conn in tmux_conns:
        this_project = await conn.async_send_command("display-message -p '#S'")
        if this_project == project:
            return conn

    raise Exception("Could not find tmux connection for " + project)


async def singleton(connection, cmd, id_=None, cd=False, project=None):
    app = await iterm2.async_get_app(connection)

    if cd:
        if cd is True:
            cd = await app.current_window.current_tab.current_session.async_get_variable('path')
        cmd = f'cd "{cd}" && {cmd}'

    if id_ is None:
        id_ = cmd

    tab = app.get_tab_by_id(SINGLETON_TABS.get(id_))
    if not tab:
        if project:
            window = get_window(app, project)
        else:
            window = app.current_window
        if window is None:
            await iterm2.Window.async_create(connection, command=f"zsh -ic '{cmd}'")
            tab = window.current_tab
        else:
            tab = await window.async_create_tab(command=f"zsh -ic '{cmd}'")
        SINGLETON_TABS[id_] = tab.tab_id
        # await lg_tab.current_session.async_set_variable(f"user.{id_}", True)
    await tab.async_activate()

    await tab.async_activate()
    return
