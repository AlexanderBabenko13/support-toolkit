# Network.ps1 — диагностика сети

function Get-NetworkInfo {
    param(
        [switch]$NoPause
    )

    Write-ToolkitLog 'Диагностика: информация о сети — начало'

    Add-ReportLine ''
    Add-ReportLine '===== NETWORK INFO ====='

    try {
        $configs = Get-CimInstance Win32_NetworkAdapterConfiguration |
            Where-Object { $_.IPEnabled -eq $true }

        foreach ($cfg in $configs) {
            Add-ReportLine ''
            Add-ReportLine "Adapter  : $($cfg.Description)"
            Add-ReportLine "IPv4     : $($cfg.IPAddress -join ', ')"
            Add-ReportLine "Mask     : $($cfg.IPSubnet -join ', ')"
            Add-ReportLine "Gateway  : $($cfg.DefaultIPGateway -join ', ')"
            Add-ReportLine "DNS      : $($cfg.DNSServerSearchOrder -join ', ')"
            Add-ReportLine "DHCP     : $($cfg.DHCPEnabled)"
        }

        Write-ToolkitLog 'Диагностика: информация о сети — завершено'
    }
    catch {
        Add-ReportLine "Network info ERROR: $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: информация о сети — ошибка: $($_.Exception.Message)"
    }

    if (-not $NoPause) {
        Wait-Enter
    }
}

function Test-NetworkTarget {
    Write-ToolkitLog 'Диагностика: проверка адреса или порта — начало'

    Add-ReportLine ''
    Add-ReportLine '===== CONNECTION TEST ====='

    $target = Read-Host 'Введи адрес или IP для проверки'
    if ([string]::IsNullOrWhiteSpace($target)) {
        Add-ReportLine 'Адрес не указан.'
        Write-ToolkitLog 'Диагностика: проверка связи — адрес не указан'
        Wait-Enter
        return
    }

    $portInput = Read-Host 'Введи порт, например 443. Можно оставить пустым для ping'

    try {
        if ([string]::IsNullOrWhiteSpace($portInput)) {
            Add-ReportLine "Ping test: $target"
            $ping = Test-Connection -ComputerName $target -Count 4 -ErrorAction Stop

            foreach ($item in $ping) {
                Add-ReportLine "Reply from $($item.Address): $($item.ResponseTime) ms"
            }

            Write-ToolkitLog "Диагностика: ping $target — завершено"
        }
        else {
            $port = [int]$portInput
            Add-ReportLine "TCP test: $target port $port"

            $result = Test-NetConnection -ComputerName $target -Port $port -InformationLevel Detailed

            Add-ReportLine "ComputerName     : $($result.ComputerName)"
            Add-ReportLine "RemoteAddress    : $($result.RemoteAddress)"
            Add-ReportLine "RemotePort       : $($result.RemotePort)"
            Add-ReportLine "TcpTestSucceeded : $($result.TcpTestSucceeded)"
            Add-ReportLine "PingSucceeded    : $($result.PingSucceeded)"

            Write-ToolkitLog "Диагностика: TCP $target`:$port — завершено (TcpTestSucceeded=$($result.TcpTestSucceeded))"
        }
    }
    catch {
        Add-ReportLine "Connection test ERROR: $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: проверка связи — ошибка: $($_.Exception.Message)"
    }

    Wait-Enter
}

function Get-ExternalIpInfo {
    param(
        [switch]$NoPause
    )

    Write-ToolkitLog 'Диагностика: внешний IP — начало'

    Add-ReportLine ''
    Add-ReportLine '===== EXTERNAL IP ====='

    try {
        $response = Invoke-RestMethod -Uri 'https://api.ipify.org?format=json' -TimeoutSec 15 -ErrorAction Stop
        $externalIp = $response.ip

        if ([string]::IsNullOrWhiteSpace($externalIp)) {
            Add-ReportLine 'Внешний IP не получен: пустой ответ сервиса.'
            Write-ToolkitLog 'Диагностика: внешний IP — пустой ответ'
        }
        else {
            Add-ReportLine "Внешний IP : $externalIp"
            Write-ToolkitLog "Диагностика: внешний IP — $externalIp"
        }
    }
    catch {
        Add-ReportLine 'Не удалось определить внешний IP.'
        Add-ReportLine 'Возможные причины: нет доступа в интернет, блокировка исходящего HTTPS или недоступен сервис api.ipify.org.'
        Add-ReportLine "Ошибка     : $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: внешний IP — ошибка: $($_.Exception.Message)"
    }

    if (-not $NoPause) {
        Wait-Enter
    }
}

function Import-ToolkitEndpoints {
    Write-ToolkitLog 'Импорт локальных эндпоинтов — начало'

    $configPath = Join-Path $Script:ToolkitRoot 'config' 'endpoints.local.json'
    Add-ReportLine ''
    Add-ReportLine '===== ЛОКАЛЬНЫЕ КОНФИГУРИРОВАННЫЕ ЭНДПОИНТЫ ====='
    Add-ReportLine "Файл конфигурации: $configPath"

    if (-not (Test-Path -LiteralPath $configPath)) {
        $msg = 'Файл config/endpoints.local.json не найден. Создай его по примеру из config/endpoints.example.json.'
        Add-ReportLine $msg
        Write-ToolkitLog 'Импорт локальных эндпоинтов: файл не найден'
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $configPath -Raw -ErrorAction Stop
        $data = $raw | ConvertFrom-Json -ErrorAction Stop

        if ($null -eq $data.Endpoints) {
            throw "В JSON не найдено поле 'Endpoints'."
        }

        $validated = @()
        $index = 0
        foreach ($ep in @($data.Endpoints)) {
            $index++

            $name = $ep.Name
            $host = $ep.Host
            $port = $ep.Port

            $missing = @()
            if ([string]::IsNullOrWhiteSpace($name)) { $missing += 'Name' }
            if ([string]::IsNullOrWhiteSpace($host)) { $missing += 'Host' }

            $portInt = $null
            if ($null -eq $port -or [string]::IsNullOrWhiteSpace([string]$port)) {
                $missing += 'Port'
            }
            else {
                try {
                    $portInt = [int]$port
                }
                catch {
                    $missing += 'Port (не число)'
                }
            }

            if ($missing.Count -gt 0) {
                $AddMsg = "Эндпоинт #${index} пропущены/некорректны поля: $($missing -join ', ')"
                Add-ReportLine $AddMsg
                Write-ToolkitLog "Импорт локальных эндпоинтов: невалидный эндпоинт #${index} ($($missing -join ', '))"
                continue
            }

            if ($portInt -lt 1 -or $portInt -gt 65535) {
                Add-ReportLine "Эндпоинт #${index}: Port вне диапазона (1..65535): $portInt"
                Write-ToolkitLog "Импорт локальных эндпоинтов: невалидный Port у эндпоинта #${index} ($portInt)"
                continue
            }

            $validated += [pscustomobject]@{
                Name = $name
                Host = $host
                Port = $portInt
            }
        }

        if ($validated.Count -eq 0) {
            Add-ReportLine 'В конфиге нет валидных эндпоинтов для проверки.'
            Write-ToolkitLog 'Импорт локальных эндпоинтов: нет валидных объектов'
            return $null
        }

        Add-ReportLine "Валидных эндпоинтов для проверки: $($validated.Count)"
        Write-ToolkitLog "Импорт локальных эндпоинтов: готово ($($validated.Count))"
        return $validated
    }
    catch {
        $err = "Ошибка чтения/валидации JSON config/endpoints.local.json: $($_.Exception.Message)"
        Add-ReportLine $err
        Write-ToolkitLog "Импорт локальных эндпоинтов: ошибка — $($_.Exception.Message)"
        return $null
    }
}

function Test-ConfiguredEndpoints {
    Write-ToolkitLog 'Диагностика: проверки эндпоинтов из локального конфига — начало'

    Add-ReportLine ''
    Add-ReportLine '===== ПРОВЕРКА ЛОКАЛЬНО КОНФИГУРИРОВАННЫХ ЭНДПОИНТОВ ====='

    try {
        $endpoints = Import-ToolkitEndpoints
        if ($null -eq $endpoints) {
            Add-ReportLine 'Проверка адресов из локального конфига отменена (нет валидных эндпоинтов).'
            Write-ToolkitLog 'Диагностика: эндпоинты из конфига — отменено'
            Wait-Enter
            return
        }

        foreach ($ep in $endpoints) {
            Add-ReportLine ''
            Add-ReportLine 'Проверка эндпоинта:'
            Add-ReportLine "Name              : $($ep.Name)"
            Add-ReportLine "Host              : $($ep.Host)"
            Add-ReportLine "Port              : $($ep.Port)"

            try {
                $result = Test-NetConnection -ComputerName $ep.Host -Port $ep.Port -ErrorAction Stop
                $tcpOk = $result.TcpTestSucceeded

                Add-ReportLine "TcpTestSucceeded : $tcpOk"
                Write-ToolkitLog "Проверка эндпоинта: $($ep.Name) TcpTestSucceeded=$tcpOk"
            }
            catch {
                Add-ReportLine "TcpTestSucceeded : False"
                Add-ReportLine "Ошибка            : $($_.Exception.Message)"
                Write-ToolkitLog "Проверка эндпоинта ERROR: $($ep.Name) — $($_.Exception.Message)"
            }
        }

        Add-ReportLine ''
        Add-ReportLine 'Проверка адресов из локального конфига завершена.'
        Write-ToolkitLog 'Диагностика: проверки эндпоинтов из локального конфига — завершено'
    }
    catch {
        Add-ReportLine "Ошибка проверки эндпоинтов из локального конфига: $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: эндпоинты из конфига — ошибка: $($_.Exception.Message)"
    }

    Wait-Enter
}
