import os
import sys
import re
from functools import wraps
import traceback
import asyncio
import iterm2
import json

WINDOW_IDS = {}

FIFO_PATH = "/tmp/iterm_fifo"
if not os.path.exists(FIFO_PATH):
    os.mkfifo(FIFO_PATH)


import logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("/tmp/iterm.log"),
        logging.StreamHandler()
    ]
)

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

async def get_window(app, project, file_name=None):
    window = app.get_window_by_id(WINDOW_IDS.get(project))
    if window != None:
        return window
    print('looking for window...')
    for window in app.windows:
        try:
            status = await window.current_tab.current_session.async_get_variable('tmuxStatusLeft')
        except:
            pass
        else:
            this_project = status[2:-3] if status else None  # e.g.  "[ main ]"
            if this_project == project:
                WINDOW_IDS[project] = window.window_id
                print('  found it!')
                return window

async def get_tab(app, file_name):
    if app.current_window:
        for tab in app.current_window.tabs:
            # could try getting a more specific variable here
            title = await tab.async_get_variable('title')
            if title[2:] == file_name:
                return tab

def project_name(session):
    print('session_name is ', session.name)
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


class Commander(object):
    """Runs commands"""
    def __init__(self, connection, app, vars_):
        self.vars = vars_
        self.connection = connection
        self.app = app
        self.project = self.vars.get('project_base_name', 'main')
        self.folder = self.vars.get('folder', '~')
        self.file_name = self.vars.get('file_name', None)
        self.file_path = self.vars.get('file_path', None)


    async def focus(self, focus_tab=True):
        window = await get_window(self.app, self.project)
        if window is None:
            return
        await window.async_activate()

        if self.file_name is not None:
            tab = await get_tab(self.app, self.file_name)
            if tab:
                await tab.async_activate()

    async def start_repl(self):
        # await self.start_term()
        self.file = self.vars['file']
        file, extension = self.vars['file_name'], self.vars['file_extension']
        self.cmd = {
            'jl': 'jl',
            'r': 'radian',
            'rmd': 'radian',
            'py': 'ipython'
        }.get(extension.lower(), None)

        window = await get_window(self.app, self.project)
        if window is None:
            print("No Terminal Found")
            return

        tmux = await get_tmux(self.connection, self.project)
        tab = await window.async_create_tmux_tab(tmux)
        await tab.async_set_title(self.file_name)
        await tab.current_session.async_send_text(f"cd \'{self.file_path}\' && {self.cmd}\n")

    async def send_text(self, text):
        window = await get_window(self.app, self.project)
        if window is None:
            return
        session = window.current_tab.current_session
        await session.async_send_text(text + '\n')
        await window.async_activate()
        1

    async def start_term(self):
        window = await get_window(self.app, self.project)
        if window is None:
            window = await create_window(self.connection, self.project, self.folder)
        await window.async_activate()
        await self.app.async_activate()

    async def close_term(self):
        for session in self.app.buried_sessions:
            if project_name(session) == self.project:
                logging.info('CloseTerm: found session')
                try:
                    await session.async_close()
                except:
                    print('Unable to close session')
                return

    async def lazy_git(self):
        cmd = f"zsh -ic 'cd \"{self.folder}\" && lazygit'"
        window = await get_window(self.app, self.project)
        if window is None:
            await iterm2.Window.async_create(self.connection, command=cmd)
        else:
            # check if already exists and activate
            lg_tab = None
            for tab in window.tabs:
                for session in tab.sessions:
                    if (await session.async_get_variable("user.lazygit")):
                        lg_tab = tab
                        break
            if lg_tab is None:
                tab = await window.async_create_tab(command=cmd)
                await tab.current_session.async_set_variable("user.lazygit", True)
                await tab.async_activate()

        await self.app.async_activate()



def read_message():
    with open(FIFO_PATH, 'r') as f:
        return json.load(f)

async def main(connection):
    app = await iterm2.async_get_app(connection)

    while True:
        msg = read_message()
        command = msg['command']
        print(command)
        commander = Commander(connection, app, msg['vars'])
        handler = {
            'TermFocus': commander.focus,
            'StartTerm': commander.start_term,
            'CloseTerm': commander.close_term,
            'StartRepl': commander.start_repl,
            'TermSendText': commander.send_text,
            'LazyGit': commander.lazy_git,
        }.get(command, None)
        if handler:
            await handler(**msg['kws'])
        else:
            print('No handler for', command)

iterm2.run_forever(main)
