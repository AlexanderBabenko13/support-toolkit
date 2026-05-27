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
