# Network.ps1 — диагностика сети

function Get-NetworkInfo {
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

    Wait-Enter
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

function Get-RouteInfo {
    Write-ToolkitLog 'Диагностика: маршруты — начало'

    Add-ReportLine ''
    Add-ReportLine '===== ROUTE INFO (IPv4) ====='

    try {
        $routes = Get-NetRoute -AddressFamily IPv4 -ErrorAction Stop |
            Sort-Object RouteMetric, DestinationPrefix

        if (-not $routes) {
            Add-ReportLine 'IPv4-маршруты не найдены.'
            Write-ToolkitLog 'Диагностика: маршруты — маршруты не найдены'
            Wait-Enter
            return
        }

        foreach ($route in $routes) {
            Add-ReportLine ''
            Add-ReportLine "Назначение : $($route.DestinationPrefix)"
            Add-ReportLine "NextHop    : $($route.NextHop)"
            Add-ReportLine "Интерфейс  : $($route.InterfaceAlias)"
            Add-ReportLine "Метрика    : $($route.RouteMetric)"
        }

        Write-ToolkitLog "Диагностика: маршруты — завершено ($(@($routes).Count) маршрутов)"
    }
    catch {
        Add-ReportLine "Route info ERROR: $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: маршруты — ошибка: $($_.Exception.Message)"
    }

    Wait-Enter
}

function Get-ExternalIpInfo {
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

    Wait-Enter
}

function Get-ProxyInfo {
    Write-ToolkitLog 'Диагностика: прокси — начало'

    Add-ReportLine ''
    Add-ReportLine '===== PROXY INFO ====='

    Add-ReportLine ''
    Add-ReportLine '--- WinHTTP (netsh winhttp show proxy) ---'

    try {
        $winhttpOutput = netsh winhttp show proxy 2>&1

        if ($LASTEXITCODE -ne 0 -and $null -eq $winhttpOutput) {
            Add-ReportLine 'Не удалось получить настройки WinHTTP.'
            Write-ToolkitLog 'Диагностика: прокси — WinHTTP: пустой вывод'
        }
        else {
            foreach ($line in @($winhttpOutput)) {
                Add-ReportLine $line.ToString()
            }
        }
    }
    catch {
        Add-ReportLine "WinHTTP ERROR: $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: прокси — WinHTTP ошибка: $($_.Exception.Message)"
    }

    Add-ReportLine ''
    Add-ReportLine '--- Пользовательский прокси (Internet Settings, HKCU) ---'

    try {
        $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        $settings = Get-ItemProperty -Path $regPath -ErrorAction Stop

        $proxyEnabled = if ($null -ne $settings.ProxyEnable) { $settings.ProxyEnable -eq 1 } else { $false }
        $proxyServer = if ($settings.ProxyServer) { $settings.ProxyServer } else { '(не задан)' }
        $proxyOverride = if ($settings.ProxyOverride) { $settings.ProxyOverride } else { '(не задан)' }
        $autoConfigUrl = if ($settings.AutoConfigURL) { $settings.AutoConfigURL } else { '(не задан)' }
        $autoDetect = if ($null -ne $settings.AutoDetect) { $settings.AutoDetect -eq 1 } else { $false }

        Add-ReportLine "ProxyEnable   : $proxyEnabled"
        Add-ReportLine "ProxyServer   : $proxyServer"
        Add-ReportLine "ProxyOverride : $proxyOverride"
        Add-ReportLine "AutoConfigURL : $autoConfigUrl"
        Add-ReportLine "AutoDetect    : $autoDetect"

        Write-ToolkitLog 'Диагностика: прокси — завершено'
    }
    catch {
        Add-ReportLine "Proxy registry ERROR: $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: прокси — ошибка реестра: $($_.Exception.Message)"
    }

    Wait-Enter
}

function Test-CommonEndpoints {
    Write-ToolkitLog 'Диагностика: проверка типовых адресов — начало'

    Add-ReportLine ''
    Add-ReportLine '===== COMMON ENDPOINTS TEST ====='

    $endpoints = @(
        @{ Host = 'ya.ru'; Port = 443 }
        @{ Host = 'google.com'; Port = 443 }
        @{ Host = 'github.com'; Port = 443 }
        @{ Host = 'microsoft.com'; Port = 443 }
    )

    $previousProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    try {
        foreach ($endpoint in $endpoints) {
            $label = '{0}:{1}' -f $endpoint.Host, $endpoint.Port
            Add-ReportLine ''
            Add-ReportLine "Проверка : $label"

            try {
                $result = Test-NetConnection -ComputerName $endpoint.Host -Port $endpoint.Port -WarningAction SilentlyContinue -ErrorAction Stop

                Add-ReportLine "TcpTestSucceeded : $($result.TcpTestSucceeded)"
                Write-ToolkitLog "Диагностика: $label — TcpTestSucceeded=$($result.TcpTestSucceeded)"
            }
            catch {
                Add-ReportLine "TcpTestSucceeded : False"
                Add-ReportLine "Ошибка           : $($_.Exception.Message)"
                Write-ToolkitLog "Диагностика: $label — ошибка: $($_.Exception.Message)"
            }
        }

        Write-ToolkitLog 'Диагностика: проверка типовых адресов — завершено'
    }
    finally {
        $ProgressPreference = $previousProgress
    }

    Wait-Enter
}
