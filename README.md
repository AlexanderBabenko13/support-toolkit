# SupportToolkit

PowerShell-утилита для L2 поддержки.

**Версия:** 0.8

## Цель проекта

Собрать безопасный набор диагностических инструментов для инженера поддержки:

- информация о системе;
- информация о дисках;
- информация о сети и DNS;
- проверка адресов, портов и разрешения имён;
- статус критичных служб;
- последние ошибки Event Log;
- быстрый отчёт;
- экспорт отчёта в TXT и HTML;
- логирование действий;
- проверка endpoint-ов из локального конфига;
- portable-сборка в один файл для передачи коллегам.

## Принципы

1. Скрипт не меняет настройки системы.
2. По умолчанию только диагностика, read-only.
3. Единственная запись на диск - отчёты, логи и артефакты сборки.
4. Все действия меню и диагностик пишутся в лог сессии.
5. Код разбит на функции в `src/`.
6. Без сторонних модулей.
7. Совместимость с PowerShell 7.
8. Вывод и сообщения на русском языке.
9. Локальные endpoint-ы не публикуются в GitHub.

## Требования

- Windows 10/11;
- PowerShell 7+;
- запуск от администратора не обязателен, но для части диагностик может дать больше данных.

## Запуск из исходников

```powershell
cd D:\Projects\SupportToolkit
pwsh -NoProfile -File .\SupportToolkit.ps1
```

## Быстрый отчёт

```powershell
pwsh -NoProfile -File .\SupportToolkit.ps1 -QuickReport
```

## Portable-сборка

Сборка portable-версии выполняется командой:

```powershell
pwsh -NoProfile -File .\build\Build-SingleFile.ps1
```

После сборки появляются файлы:

```text
dist\package\SupportToolkit.ps1
dist\SupportToolkit_v0.8.zip
```

Готовый архив для передачи коллегам:

```text
dist\SupportToolkit_v0.8.zip
```

Артефакты `dist/` не коммитятся в Git.

## Запуск portable-версии

```powershell
cd D:\Projects\SupportToolkit\dist\package
pwsh -NoProfile -File .\SupportToolkit.ps1
```

Быстрый отчёт portable-версии:

```powershell
pwsh -NoProfile -File .\SupportToolkit.ps1 -QuickReport
```

## Структура проекта

```text
SupportToolkit/
  SupportToolkit.ps1              # launcher, подключает src/ и запускает меню
  src/
    Core.ps1                      # версия, пути, инициализация
    Report.ps1                    # буфер отчёта, лог, экспорт
    System.ps1                    # информация о системе
    Disk.ps1                      # локальные диски
    Network.ps1                   # сеть, ping/TCP, внешний IP
    Dns.ps1                       # DNS-настройки и разрешение имён
    Services.ps1                  # критичные службы
    Menu.ps1                      # главное меню
  build/
    Build-SingleFile.ps1          # сборка portable-версии
  config/
    endpoints.example.json        # пример локального конфига
    endpoints.local.json          # локальный файл, не попадает в Git
  reports/                        # отчёты TXT/HTML и логи, не коммитятся
  docs/
    AI_WORKFLOW.md
    RELEASE_NOTES.md
  tests/                          # зарезервировано под тесты
  dist/                           # артефакты сборки, не коммитятся
  README.md
  .gitignore
```

## Меню v0.8

### Система

| Пункт | Действие |
|------:|----------|
| 1 | Информация о системе |
| 2 | Диски |
| 3 | Критичные службы |
| 4 | Последние ошибки Event Log |

### Сеть и DNS

| Пункт | Действие |
|------:|----------|
| 5 | Информация о сети |
| 6 | DNS информация |
| 7 | Проверка DNS-имени |
| 8 | Проверка адреса или порта |
| 9 | Проверка адресов из локального конфига |

### Отчёт

| Пункт | Действие |
|------:|----------|
| 10 | Быстрый отчёт |
| 11 | Экспорт отчёта сессии в TXT |
| 12 | Экспорт отчёта в HTML |
| 13 | Очистить буфер отчёта |
| 0 | Выход |

## Основные функции

| Функция | Описание |
|---------|----------|
| `Get-SystemInfo` | Информация о системе, пользователе, ОС и аптайме |
| `Get-DiskInfo` | Локальные диски, размер, свободное место и процент |
| `Get-ServiceHealth` | Статус критичных служб |
| `Get-RecentEventErrors` | Последние ошибки и предупреждения из System/Application |
| `Get-NetworkInfo` | Информация о сетевых адаптерах |
| `Get-DnsInfo` | DNS-серверы и suffix search list |
| `Test-DnsResolution` | Проверка разрешения DNS-имени |
| `Test-NetworkTarget` | Проверка ping или TCP-порта |
| `Import-ToolkitEndpoints` | Импорт endpoint-ов из локального JSON |
| `Test-ConfiguredEndpoints` | Проверка endpoint-ов из локального конфига |
| `Invoke-QuickReport` | Быстрый сбор отчёта без ручного ввода |
| `Export-Report` | Экспорт сессионного отчёта в TXT |
| `Export-HtmlReport` | Экспорт сессионного отчёта в HTML |

## Локальный конфиг endpoint-ов

Для быстрой проверки адресов инженером поддержки используется локальный файл:

```text
config\endpoints.local.json
```

Файл не попадает в GitHub и не создаётся автоматически.

Создай его по примеру:

```text
config\endpoints.example.json
```

Пример:

```json
{
  "Endpoints": [
    {
      "Name": "Example HTTPS",
      "Host": "example.com",
      "Port": 443
    },
    {
      "Name": "Yandex HTTPS",
      "Host": "ya.ru",
      "Port": 443
    }
  ]
}
```

Поле `Endpoints` - массив объектов. Для каждого объекта нужны поля:

- `Name`;
- `Host`;
- `Port`.

## Сессионный отчёт

Каждая диагностика добавляет блок в общий буфер отчёта. Экспорт сохраняет весь накопленный буфер.

TXT-отчёты:

```text
reports\SupportToolkit_Report_YYYYMMDD_HHmmss.txt
```

HTML-отчёты:

```text
reports\SupportToolkit_Report_YYYYMMDD_HHmmss.html
```

## Логирование

Действия записываются в файл:

```text
reports\SupportToolkit_YYYYMMDD.log
```

В лог попадают:

- запуск;
- выход;
- выбор пункта меню;
- начало и завершение диагностик;
- экспорт отчёта;
- очистка буфера.

## Что меняется на диске

Скрипт может создавать:

```text
reports/
dist/
```

`reports/` используется для отчётов и логов.

`dist/` используется для portable-сборки.

Настройки ОС, сеть, DNS-кэш, службы и реестр не изменяются.

## Что не делает скрипт

SupportToolkit не выполняет:

- сброс DNS-кэша;
- перезапуск служб;
- изменение реестра;
- изменение сетевых настроек;
- установку программ;
- изменение GPO;
- изменение AD;
- отправку данных наружу.

## Git workflow

Работа ведётся через ветки:

```text
main
feature/*
```

Типовой цикл:

```powershell
git checkout main
git pull
git checkout -b feature/name

# изменения

git status
git add .
git commit -m "Message"
git push -u origin feature/name
```

После этого создаётся Pull Request в `main`.

## Release Notes

История изменений хранится в:

```text
docs\RELEASE_NOTES.md
```
