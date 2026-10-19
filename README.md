# nitroshell

A Kali Linux style theme for [Oh My Zsh](https://ohmyz.sh/): a two-line prompt, syntax highlighting, autosuggestions and handy key bindings.

```
┌───(user@host)-[~/projects/myapp]
└─$
```

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Updating](#updating)
- [Configuration](#configuration)
- [Key bindings](#key-bindings)
- [Project structure](#project-structure)
- [Uninstalling](#uninstalling)
- [License](#license)

## Features

- **Two prompt modes**: a two-line Kali style prompt (default) and a one-line `user@host:~/path$`.
- **Git in the prompt**: branch and repository status (off by default).
- **Proxy indicator**: when `https_proxy`, `http_proxy` or `all_proxy` is set in the environment, the prompt shows `[proxy]` (the address is not shown).
- **Python virtualenv** name next to the path, without breaking the prompt frame.
- **Root** is highlighted in red and gets `#` instead of `$`.
- **Shortened long paths**: from 6 levels deep, the first directory, `…` and the last 4 are shown.
- **Syntax highlighting** ([zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)) with its own color scheme.
- **Autosuggestions** ([zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)) based on history and completion.
- **Automatic plugin installation**: plugins that are not found on the system are downloaded to `~/.zsh/`.
- **Colored output** of `ls`, `grep`, `diff`, `ip`, `pacman`, `less` and Tab completion lists.
- **Shell conveniences**: `cd` by directory name alone, history shared between sessions, numeric file sorting, `#` comments in interactive mode.
- **`nitroshell` command**: an interactive menu (arrow keys and Enter) with settings and updating; also available as `nitroshell config [section]`, `nitroshell update` and `nitroshell version`.
- **Aliases**: `ll`, `la`, `l`, `dc` (`docker compose`), `history` (full history).

## Requirements

- **Zsh**
- **Oh My Zsh**
- **git**: to install the theme and download plugins
- **curl**: to run the installer

## Installation

1. Install Oh My Zsh (if it is not installed yet):

    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```

2. Install `nitroshell`:

    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/skrine525/nitroshell/refs/heads/main/install.sh)"
    ```

    The script:
    - checks the dependencies (zsh, git, Oh My Zsh) and tells you what to install if something is missing;
    - clones the repository to `~/.zsh/nitroshell` and links the theme into `~/.oh-my-zsh/custom/themes/`;
    - sets `ZSH_THEME="nitroshell"` in `~/.zshrc` (a copy of the original is saved to `~/.zshrc.pre-nitroshell` first).

3. To show git information in the prompt, enable the `git` plugin in `~/.zshrc`:

    ```bash
    plugins=(git)
    ```

4. Restart the shell:

    ```bash
    exec zsh
    ```

## Updating

Run `nitroshell` and choose **Update**, or run it directly:

```bash
nitroshell update
```

The update resets the installation to the latest `main`, so it refuses to run if the repository has local changes or is on another branch. `nitroshell version` shows the installed version.

> User settings are stored in `config/config.zsh`, which git does not track, so updating does not affect them.

## Configuration

Settings are stored in `~/.zsh/nitroshell/config/config.zsh`. The file is created automatically on the first start, is ignored by git and is not touched by updates. When a new version of the theme adds options, they are appended to the file with their default values.

A different path can be set with the `NITROSHELL_CONFIG_FILE` variable in `~/.zshrc` (before Oh My Zsh is loaded).

| Option | Values | Default | Description |
|---|---|---|---|
| `USE_SYNTAX_HIGHLIGHTING` | `yes` / `no` | `yes` | Syntax highlighting |
| `AUTO_DOWNLOAD_SYNTAX_HIGHLIGHTING_PLUGIN` | `yes` / `no` | `yes` | Download the highlighting plugin if it is missing |
| `USE_ZSH_AUTOSUGGESTIONS` | `yes` / `no` | `yes` | Autosuggestions |
| `AUTO_DOWNLOAD_ZSH_AUTOSUGGESTIONS_PLUGIN` | `yes` / `no` | `yes` | Download the suggestions plugin if it is missing |
| `PROMPT_MODE` | `twoline` / `oneline` | `twoline` | Prompt mode |
| `NEWLINE_BEFORE_PROMPT` | `yes` / `no` | `yes` | Empty line before every prompt except the first one |
| `SHOW_GIT` | `yes` / `no` | `no` | Show git (branch and status) in the prompt |
| `SHOW_PROXY` | `yes` / `no` | `yes` | Show in the prompt that a proxy is set in the shell |
| `SHOW_VENV` | `yes` / `no` | `yes` | Show the active Python virtualenv |
| `PROXY_HTTP`, `PROXY_HTTPS`, `PROXY_ALL` | proxy address | empty | Addresses that `Ctrl+P` and the menu switch on and off, e.g. `http://user:pass@host:3128` or `socks5://host:2080`; each one fills `http_proxy`/`HTTP_PROXY`, `https_proxy`/`HTTPS_PROXY` and `all_proxy`/`ALL_PROXY` respectively |
| `REQUIRE_PROXY_FOR` | space-separated commands | empty | Commands that refuse to start until a proxy is set in the shell |

The list can be edited interactively: run `nitroshell`, choose **Settings**, then **Commands that require a proxy** (`Enter` on a command does nothing, `d` deletes the highlighted one, `+ Add command` adds a new one; changes apply immediately). Example: forbid running `claude` and `codex` without a proxy:

```bash
REQUIRE_PROXY_FOR="claude codex"
```

Only the presence of a proxy variable in the environment is checked, not whether the proxy works. The protection applies only to commands started from an interactive zsh: `command claude`, a full path, scripts and IDEs bypass it.

The proxy addresses are edited in `nitroshell` → **Settings** → **Proxy addresses** (`Enter` turns the highlighted row into a text field right there: `Enter` applies, `Esc` cancels, `Ctrl+U` clears the text; `d` clears the address) or from **Proxy** in the main menu (`Ctrl+O`) while none is set. The first address you enter switches the proxy on. Once it is set, `Ctrl+P` (or that menu item) switches the proxy on and off in the current shell only: the on/off state is not saved, a new terminal starts with the proxy off, and `exec zsh` keeps it as it was. Without addresses `Ctrl+P` still switches off a proxy that comes from the environment (for example from `.zshrc`) and switches it back on; if there is none it only shows a hint.

The prompt mode (**Settings** → **Prompt mode**, switches on `Enter`) and what is shown in the prompt (**Settings** → **Prompt display**) are written to `config/config.zsh` automatically, so your choice is kept between sessions.

## Key bindings

| Key | Action |
|---|---|
| `Ctrl+P` | Switch the configured proxy on or off (the `switch-proxy` command does the same) |
| `Ctrl+O` | Open the nitroshell menu: proxy switch, settings (prompt mode, prompt display: git, proxy, Python venv; proxy addresses; proxy commands) and update |
| `Ctrl+←` / `Ctrl+→` | Move one word back or forward |
| `Ctrl+Del` | Delete the next word |
| `Ctrl+U` | Delete everything up to the beginning of the line |
| `Home` / `End` | Beginning and end of the line |
| `Delete` | Delete the character under the cursor |
| `PgUp` / `PgDn` | Beginning and end of the history |
| `Shift+Tab` | Undo the last action |
| `Space` | Expand history (`!!` and the like) as you type |

## Project structure

```
nitroshell.zsh-theme   # entry point: loads the modules from lib/
lib/                   # modules: options, shell, proxy, prompt, plugins, environment,
                       #          menu, settings, command, aliases
config/config.zsh      # your settings (created on first start, ignored by git)
install.sh             # installer and updater
VERSION                # current version
```

## Uninstalling

1. Switch back to your previous theme in `~/.zshrc` (for example, `ZSH_THEME="robbyrussell"`). The original file is saved as `~/.zshrc.pre-nitroshell`.
2. Remove the theme and the repository:

    ```bash
    rm ~/.oh-my-zsh/custom/themes/nitroshell.zsh-theme
    rm -rf ~/.zsh/nitroshell
    ```

3. Optionally, remove the automatically downloaded plugins:

    ```bash
    rm -rf ~/.zsh/zsh-syntax-highlighting ~/.zsh/zsh-autosuggestions
    ```

## License

[MIT](LICENSE)
