import sys
sys.path.insert(0, '../')
from lib import *

import json

FIFO_PATH = "/tmp/iterm_fifo"
if not os.path.exists(FIFO_PATH):
    os.mkfifo(FIFO_PATH)

def read_message():
    with open(FIFO_PATH, 'r') as f:
        return json.load(f)


class SublimeCommand(object):
    """Runs commands sent from sublime."""
    def __init__(self, connection, app):
        self.connection = connection
        self.app = app

    async def run(self, msg):
        self.vars = msg['vars']
        command = msg['command']

        self.project = self.vars.get('project_base_name', 'main')
        self.folder = self.vars.get('folder', '~')
        self.file_name = self.vars.get('file_name', None)
        self.file_path = self.vars.get('file_path', None)

        logging.info(f'SublimeCommand: {command}')
        handler = {
            'TermFocus': self.focus,
            'StartTerm': self.start_term,
            'CloseTerm': self.close_term,
            'StartRepl': self.start_repl,
            'TermSendText': self.send_text,
            'LazyGit': self.lazygit,
        }.get(command, None)
        if handler:
            try:
                await handler(**msg['kws'])
            except iterm2.rpc.RPCException:
                logging.info("RPCException")
        else:
            logging.info('No handler for ' + command)

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
            logging.info("No Terminal Found")
            return

        tmux = await get_tmux(self.connection, self.project)
        tab = await window.async_create_tmux_tab(tmux)
        await tab.async_set_title(self.file_name)
        await tab.current_session.async_send_text(f"cd \'{self.file_path}\' && {self.cmd}\n")

    async def send_text(self, text):
        window = await get_window(self.app, self.project)
        if window is None:
            logging.warning("couldn't find a window")
            return
        session = window.current_tab.current_session
        # logging.info("sending text: " + text)
        await session.async_send_text(text + '\n')
        await window.async_activate()

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
                    logging.info('Unable to close session')
                return

    async def lazygit(self):
        id_ = 'lazygit_' + self.folder.replace(' ', '')
        await singleton(self.connection, 'lazygit', cd=self.folder)

        # cmd = f"zsh -ic 'cd \"{self.folder}\" && lazygit'"
        # await singleton(self.connection, cmd, id_)



async def main(connection):
    logging.info('start sublime listener')
    app = await iterm2.async_get_app(connection)

    while True:
        try:
            msg = read_message()
        except json.decoder.JSONDecodeError:
            logging.info("JSON decoding error")
            continue

        if 'vars' in msg:
            await SublimeCommand(connection, app).run(msg)
        else:
            if msg['command'] == 'project':
                await activate_project(connection, msg['kws']['project'])


iterm2.run_forever(main)
1