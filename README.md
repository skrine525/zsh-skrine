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
- [Uninstalling](#uninstalling)
- [License](#license)

## Features

- **Two prompt modes**: a two-line Kali style prompt (default) and a one-line `user@host:~/path$`.
- **Git in the prompt**: branch and repository status (off by default).
- **Proxy indicator**: when `https_proxy`, `http_proxy` or `all_proxy` is set in the environment, the prompt shows `[proxy host:port]` (the login and password are hidden).
- **Python virtualenv** name next to the path, without breaking the prompt frame.
- **Root** is highlighted in red and gets `#` instead of `$`.
- **Shortened long paths**: from 6 levels deep, the first directory, `…` and the last 4 are shown.
- **Syntax highlighting** ([zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)) with its own color scheme.
- **Autosuggestions** ([zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)) based on history and completion.
- **Automatic plugin installation**: plugins that are not found on the system are downloaded to `~/.zsh/`.
- **Colored output** of `ls`, `grep`, `diff`, `ip`, `pacman`, `less` and Tab completion lists.
- **Shell conveniences**: `cd` by directory name alone, history shared between sessions, numeric file sorting, `#` comments in interactive mode.
- **`nitroshell update`** command to update the theme.
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

```bash
nitroshell update
```

> User settings are stored in `config.zsh`, which git does not track, so updating does not affect them.

## Configuration

Settings are stored in `~/.zsh/nitroshell/config.zsh`. The file is created automatically on the first start, is ignored by git and is not touched by updates. When a new version of the theme adds options, they are appended to the file with their default values.

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
| `REQUIRE_PROXY_FOR` | space-separated commands | empty | Commands that refuse to start until a proxy is set in the shell |

Example: forbid running `claude` and `codex` without a proxy:

```bash
REQUIRE_PROXY_FOR="claude codex"
```

Only the presence of a proxy variable in the environment is checked, not whether the proxy works. The protection applies only to commands started from an interactive zsh: `command claude`, a full path, scripts and IDEs bypass it.

The prompt mode (`Ctrl+P`) and what is shown in the prompt (`Ctrl+O`) are written to `config.zsh` automatically, so your choice is kept between sessions.

## Key bindings

| Key | Action |
|---|---|
| `Ctrl+P` | Switch the prompt mode: one line or two |
| `Ctrl+O` | Prompt settings menu: choose what to show (git, proxy, Python venv) |
| `Ctrl+←` / `Ctrl+→` | Move one word back or forward |
| `Ctrl+Del` | Delete the next word |
| `Ctrl+U` | Delete everything up to the beginning of the line |
| `Home` / `End` | Beginning and end of the line |
| `Delete` | Delete the character under the cursor |
| `PgUp` / `PgDn` | Beginning and end of the history |
| `Shift+Tab` | Undo the last action |
| `Space` | Expand history (`!!` and the like) as you type |

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
