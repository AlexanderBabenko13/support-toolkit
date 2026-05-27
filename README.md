# SupportToolkit

PowerShell-утилита для L2 поддержки.

**Версия:** 0.6 (local config)

## Цель проекта

Собрать безопасный набор диагностических инструментов для инженера поддержки:

- информация о системе и дисках;
- информация о сети и DNS;
- проверка адресов, портов и разрешения имён;
- статус критичных служб;
- сессионный отчёт и экспорт в файл;
- логирование действий;
- дальнейшее расширение под VPN, RDP, Proxy, Outlook, printers и AD.

## Принципы

1. Скрипт не меняет настройки системы — только чтение и запись отчётов/логов в каталог `reports/`.
2. По умолчанию только диагностика (read-only).
3. Все действия меню и диагностик пишутся в лог сессии.
4. Код разбит на функции в `src/`.
5. Без сторонних модулей.
6. Совместимость с PowerShell 7.
7. Вывод и сообщения на русском языке.

## Запуск

```powershell
cd путь\к\SupportToolkit
.\SupportToolkit.ps1
```

Требуется PowerShell 7+.

## Структура

```text
SupportToolkit/
  SupportToolkit.ps1    # launcher — подключает src/ и запускает меню
  src/
    Core.ps1            # версия, пути, инициализация
    Report.ps1          # буфер отчёта, лог, экспорт
    System.ps1          # информация о системе
    Disk.ps1            # локальные диски
    Network.ps1         # сеть, ping/TCP
    Dns.ps1             # DNS-настройки и разрешение имён
    Services.ps1        # критичные службы
    Menu.ps1            # главное меню
  reports/              # отчёты TXT и логи (в git не коммитятся)
  docs/
    AI_WORKFLOW.md
  tests/                # зарезервировано под тесты
  README.md
  .gitignore
```

## Меню (v0.6)

### Система

| Пункт | Действие |
|-------|----------|
| 1 | Информация о системе |
| 2 | Диски (размер, свободное место, %) |
| 7 | Критичные службы (только статус) |

### Сеть и DNS

| Пункт | Действие |
|-------|----------|
| 3 | Информация о сети |
| 4 | DNS информация (серверы, suffix search list) |
| 5 | Проверка DNS-имени (A / AAAA / CNAME) |
| 6 | Проверка адреса или порта (ping / TCP) |

### Отчётность

| Пункт | Действие |
|-------|----------|
| 10 | Последние ошибки Event Log (System/Application, Level 2/3, максимум 20 на журнал) |
| 11 | Экспорт отчёта в HTML |
| 12 | Быстрый отчёт (без ввода, без долгих проверок) |
| 13 | Проверка адресов из локального конфига |

### Отчёт

| Пункт | Действие |
|-------|----------|
| 8 | Экспорт отчёта сессии в TXT |
| 9 | Очистить буфер отчёта |
| 0 | Выход |

## Диагностики v0.3

| Функция | Описание | Команды |
|---------|----------|---------|
| `Get-DiskInfo` | Локальные диски, размер, свободное место, % | `Get-CimInstance Win32_LogicalDisk` |
| `Get-DnsInfo` | DNS на активных адаптерах, suffix search list | `Get-DnsClientServerAddress`, `Get-DnsClientGlobalSetting` |
| `Test-DnsResolution` | Разрешение имени пользователем | `Resolve-DnsName` |
| `Get-ServiceHealth` | Spooler, Dnscache, LanmanWorkstation, LanmanServer, Winmgmt, EventLog | `Get-Service` (без запуска/остановки) |

DNS-кэш **не** очищается. Службы **не** перезапускаются.

## Диагностики v0.6 (local config)

| Функция | Описание | Команды |
|---------|----------|---------|
| `Get-RecentEventErrors` | Последние ошибки/предупреждения из System и Application | `Get-WinEvent` (только чтение) |
| `Export-HtmlReport` | Экспорт текущего сессионного отчёта в HTML | `Out-File` (без внешних CSS/JS) |
| `Invoke-QuickReport` | Быстрый сбор отчёта без вопросов пользователю | вызов диагностик без `Wait-Enter` |
| `Test-ConfiguredEndpoints` | Проверка endpoint-ов из `config/endpoints.local.json` | `Test-NetConnection` (только чтение) |
| `Import-ToolkitEndpoints` | Импорт и валидация endpoint-ов из `config/endpoints.local.json` | `Get-Content` + `ConvertFrom-Json` |

HTML-отчёты: `reports/SupportToolkit_Report_YYYYMMDD_HHmmss.html`

## Локальный конфиг endpoint-ов (v0.6)

Для быстрой проверки адресов инженером поддержки используйте локальный файл:

- `config/endpoints.local.json`

Файл **не попадает в GitHub** (добавлен в `.gitignore`) и **не создаётся автоматически**.

### Пример структуры

Создай `config/endpoints.local.json` по примеру `config/endpoints.example.json`, например:

```json
{
  "Endpoints": [
    {
      "Name": "Example HTTPS",
      "Host": "example.com",
      "Port": 443
    }
  ]
}
```

Поле `Endpoints` — массив объектов. Для каждого объекта нужны поля `Name`, `Host`, `Port`.

## Сессионный отчёт

Каждая диагностика **добавляет** блок в общий буфер. Экспорт (п. 8) сохраняет весь накопленный буфер в один файл.

Файлы отчётов: `reports/SupportToolkit_Report_YYYYMMDD_HHmmss.txt`

## Логирование

Действия записываются в: `reports/SupportToolkit_YYYYMMDD.log`

В лог попадают: запуск/выход, выбор пункта меню, начало и завершение диагностик, экспорт и очистка буфера.

## Что меняется на диске

Единственные изменения — каталог `reports/` (если его нет), файлы отчёта и лога. Настройки ОС, сеть, DNS-кэш, службы и реестр не изменяются.
