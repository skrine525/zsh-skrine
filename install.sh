#!/bin/bash

REPO_URL="https://github.com/skrine525/zsh-skrine"
DEST_DIR="$HOME/.zsh-skrine"

# Проверяем, существует ли папка
if [ -d "$DEST_DIR" ]; then
    echo "Папка $DEST_DIR уже существует, выполняем rebase..."
    
    # Переходим в папку репозитория
    cd "$DEST_DIR" || exit 1

    # Получаем последние изменения и выполняем rebase
    git fetch origin
    git rebase origin/dev
else
    echo "Папка $DEST_DIR не существует, клонируем репозиторий..."
    git clone "$REPO_URL" "$DEST_DIR"
    git checkout dev
fi

echo "Репозиторий успешно обновлен или клонирован в $DEST_DIR"
