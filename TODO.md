# TODO

Что можно сделать в проекте.

## Ошибки

- [ ] `RPROMPT="$(git_prompt_info)"` в режиме `oneline` вычисляется один раз при `configure_prompt`; нужны одинарные кавычки: `RPROMPT='$(git_prompt_info)'`
- [ ] Плагины подключаются несколькими `if` подряд, а не `elif`: при наличии в нескольких путях загрузятся дважды (syntax-highlighting и autosuggestions)
- [ ] Сообщение `git not found` для syntax-highlighting стоит не в той ветке (после клонирования, а не при проверке git)
- [ ] Разная `ZSH_AUTOSUGGEST_STRATEGY` у автоскачанного плагина (`completion`) и у остальных (`completion history`)
- [x] `install.sh`: ошибка `git fetch` не проверяется, `reset --hard` стирает локальные правки
- [x] `install.sh`: не создаётся `~/.oh-my-zsh/custom/themes/`, если каталога нет
- [x] `update-theme` запускает скрипт через `| sh`, хотя шебанг `zsh`
- [x] README: опечатка в URL установки (`main//install.sh`)
- [ ] `NEWLINE_BEFORE_PROMPT` объявлена, но не используется

## Улучшения

- [x] Вынести пользовательские опции в `config.zsh` (вне git), сохранять `Ctrl+P` / `Ctrl+O`
- [ ] Описать в README горячие клавиши, опции и зависимость от плагина `git`
- [ ] Добавить лицензию
- [ ] Навести порядок: хвостовые пробелы, отступ у `CL_CYAN`, лишние пустые строки
