# Configuration file for ipython.

c = get_config()

# from IPython.core.pylabtools import backends
# backends['qt'] = 'module://itermplot'

#from IPython.core.shellapp import backend_keys
#backend_keys.append('iterm2')

# c.TerminalIPythonApp.pylab = 'tk'
# c.InlineBackend.figure_format = 'svg'


# from IPython.core.pylabtools import backends
# backends['qt'] = 'module://itermplot'

# # from IPython.core.shellapp import backend_keys
# # backend_keys.append('qt')

# c.TerminalIPythonApp.pylab = 'qt'

c.InteractiveShellApp.extensions = ['autoreload']
c.InteractiveShellApp.exec_lines = ['%autoreload 2']
c.InteractiveShellApp.exec_lines.append('print("Warning: disable autoreload in ipython_config.py to improve performance.")')
c.TerminalInteractiveShell.confirm_exit = False