#!/bin/zsh

# nitroshell: the Oh My Zsh theme entry point. The code lives in lib/*.zsh.
# The modules are sourced from here, at the top level, on purpose: a plugin or
# a typeset sourced from inside a function would get its variables local to it.

# repository root (this file may be reached through a symlink)
NITROSHELL_DIR=${0:A:h}

# the order matters: options first, the command and the Ctrl+O key last
for nitroshell_module in options shell proxy prompt plugins environment menu settings command aliases; do
    . "$NITROSHELL_DIR/lib/$nitroshell_module.zsh"
done
unset nitroshell_module
