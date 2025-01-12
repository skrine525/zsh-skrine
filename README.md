# skrine-zsh

## Требования

- **Zsh** — необходим для работы конфигураций.

## Установка

1. Установите `oh-my-zsh` (если он еще не установлен):

    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```

2. Установите `skrine-zsh`:

    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/skrine525/zsh-skrine/refs/heads/main//install.sh)"
    ```

3. После установки добавьте строку для использования темы `skrine-theme` в файл конфигурации `.zshrc`:

    ```bash
    ZSH_THEME="skrine-theme"
    ```

## Как обновить

Для обновления выполните команду:

```bash
update-theme
```
