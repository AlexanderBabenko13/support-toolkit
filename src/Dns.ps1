# Dns.ps1 — диагностика DNS (read-only, без очистки кэша)

function Get-DnsInfo {
    Write-ToolkitLog 'Диагностика: DNS информация — начало'

    Add-ReportLine ''
    Add-ReportLine '===== DNS INFO ====='

    try {
        $globalDns = Get-DnsClientGlobalSetting

        Add-ReportLine '--- Глобальные настройки DNS ---'
        Add-ReportLine "Suffix search list : $($globalDns.SuffixSearchList -join ', ')"
        Add-ReportLine "Use devolution     : $($globalDns.UseDevolution)"
        Add-ReportLine "Use suffix search  : $($globalDns.UseSuffixSearchList)"

        Add-ReportLine ''
        Add-ReportLine '--- DNS-серверы (активные адаптеры) ---'

        $activeIndexes = @(Get-NetAdapter -ErrorAction Stop |
            Where-Object { $_.Status -eq 'Up' } |
            Select-Object -ExpandProperty InterfaceIndex)

        $dnsByAdapter = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object {
                $activeIndexes -contains $_.InterfaceIndex -and
                $_.ServerAddresses -and
                $_.ServerAddresses.Count -gt 0
            }

        if (-not $dnsByAdapter) {
            Add-ReportLine 'На активных адаптерах DNS-серверы не заданы.'
        }
        else {
            foreach ($entry in $dnsByAdapter) {
                Add-ReportLine ''
                Add-ReportLine "Адаптер  : $($entry.InterfaceAlias)"
                Add-ReportLine "DNS IPv4 : $($entry.ServerAddresses -join ', ')"
            }
        }

        Write-ToolkitLog 'Диагностика: DNS информация — завершено'
    }
    catch {
        Add-ReportLine "DNS info ERROR: $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: DNS информация — ошибка: $($_.Exception.Message)"
    }

    Wait-Enter
}

function Test-DnsResolution {
    Write-ToolkitLog 'Диагностика: проверка DNS-имени — начало'

    Add-ReportLine ''
    Add-ReportLine '===== DNS RESOLUTION TEST ====='

    $hostName = Read-Host 'Введи имя хоста для проверки DNS'
    if ([string]::IsNullOrWhiteSpace($hostName)) {
        Add-ReportLine 'Имя хоста не указано.'
        Write-ToolkitLog 'Диагностика: проверка DNS-имени — имя не указано'
        Wait-Enter
        return
    }

    Add-ReportLine "Запрос   : $hostName"

    try {
        $records = Resolve-DnsName -Name $hostName -ErrorAction Stop
        $targetTypes = @('A', 'AAAA', 'CNAME')
        $found = $false

        foreach ($record in $records) {
            if ($record.Type -notin $targetTypes) {
                continue
            }

            $found = $true

            switch ($record.Type) {
                'A' {
                    Add-ReportLine "A        : $($record.IPAddress)"
                }
                'AAAA' {
                    Add-ReportLine "AAAA     : $($record.IPAddress)"
                }
                'CNAME' {
                    Add-ReportLine "CNAME    : $($record.NameHost)"
                }
            }
        }

        if (-not $found) {
            Add-ReportLine 'Записи A/AAAA/CNAME не найдены (есть другие типы записей).'
        }

        Write-ToolkitLog "Диагностика: проверка DNS-имени $hostName — завершено"
    }
    catch {
        Add-ReportLine "DNS resolve ERROR: $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: проверка DNS-имени $hostName — ошибка: $($_.Exception.Message)"
    }

    Wait-Enter
}
