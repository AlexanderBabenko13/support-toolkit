# Report.ps1 — сессионный отчёт, логирование, экспорт

function Get-ToolkitLogPath {
    $date = Get-Date -Format 'yyyyMMdd'
    Join-Path $Script:ReportsPath "SupportToolkit_$date.log"
}

function Write-ToolkitLog {
    param(
        [string]$Message
    )

    try {
        if (-not (Test-Path -LiteralPath $Script:ReportsPath)) {
            New-Item -ItemType Directory -Path $Script:ReportsPath -Force | Out-Null
        }

        $line = '{0} | {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
        Add-Content -LiteralPath (Get-ToolkitLogPath) -Value $line -Encoding UTF8
    }
    catch {
        Write-Host "Не удалось записать лог: $($_.Exception.Message)"
    }
}

function Add-ReportLine {
    param(
        [string]$Text
    )

    $Script:Report.Add($Text) | Out-Null
    Write-Host $Text
}

function Clear-Report {
    $Script:Report.Clear()
}

function Clear-ReportBuffer {
    param(
        [switch]$NoPause
    )

    if ($Script:Report.Count -eq 0) {
        Write-Host 'Буфер отчёта уже пуст.'
        Write-ToolkitLog 'Очистка буфера: буфер уже был пуст'
    }
    else {
        $count = $Script:Report.Count
        Clear-Report
        Write-Host "Буфер отчёта очищен (удалено строк: $count)."
        Write-ToolkitLog "Очистка буфера: удалено строк — $count"
    }

    if (-not $NoPause) {
        Wait-Enter
    }
}

function Export-Report {
    param(
        [switch]$NoPause
    )

    if ($Script:Report.Count -eq 0) {
        Write-Host 'Отчёта пока нет. Сначала выполни диагностику.'
        Write-ToolkitLog 'Экспорт отчёта: буфер пуст'
        if (-not $NoPause) {
            Wait-Enter
        }
        return
    }

    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $fileName = "SupportToolkit_Report_$timestamp.txt"
        $path = Join-Path $Script:ReportsPath $fileName

        $header = @(
            'SupportToolkit Report'
            "Version: $($Script:ToolkitVersion)"
            "Computer: $env:COMPUTERNAME"
            "User: $env:USERNAME"
            "Time: $(Get-Date)"
            "Lines: $($Script:Report.Count)"
            ''
        )

        $content = $header + $Script:Report
        $content | Out-File -LiteralPath $path -Encoding utf8

        Write-Host 'Отчёт сохранён:'
        Write-Host $path
        Write-ToolkitLog "Экспорт отчёта: $path ($($Script:Report.Count) строк)"
    }
    catch {
        Write-Host "Ошибка экспорта отчёта: $($_.Exception.Message)"
        Write-ToolkitLog "Экспорт отчёта: ошибка — $($_.Exception.Message)"
    }

    if (-not $NoPause) {
        Wait-Enter
    }
}

function Export-HtmlReport {
    param(
        [switch]$NoPause
    )

    Write-ToolkitLog 'Экспорт отчёта: HTML — начало'

    if ($Script:Report.Count -eq 0) {
        Write-Host 'Отчёта пока нет. Сначала выполни диагностику.'
        Write-ToolkitLog 'Экспорт отчёта: HTML — буфер пуст'
        if (-not $NoPause) {
            Wait-Enter
        }
        return
    }

    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $fileName = "SupportToolkit_Report_$timestamp.html"
        $path = Join-Path $Script:ReportsPath $fileName

        $title = 'SupportToolkit Report'
        $metaLines = @(
            "Версия: $($Script:ToolkitVersion)"
            "Компьютер: $env:COMPUTERNAME"
            "Пользователь: $env:USERNAME"
            "Дата: $(Get-Date)"
            "Строк в отчёте: $($Script:Report.Count)"
        )

        $escapedTitle = [System.Net.WebUtility]::HtmlEncode($title)
        $escapedMeta = ($metaLines | ForEach-Object { [System.Net.WebUtility]::HtmlEncode($_) }) -join "`n"

        $bodyLines = foreach ($line in $Script:Report) {
            [System.Net.WebUtility]::HtmlEncode($line)
        }

        $html = @()
        $html += '<!doctype html>'
        $html += '<html lang="ru">'
        $html += '<head>'
        $html += '  <meta charset="utf-8" />'
        $html += "  <title>$escapedTitle</title>"
        $html += '  <style>'
        $html += '    body { font-family: Segoe UI, Arial, sans-serif; font-size: 13px; margin: 16px; color: #111; }'
        $html += '    h1 { font-size: 18px; margin: 0 0 8px 0; }'
        $html += '    .meta { white-space: pre-wrap; margin: 0 0 16px 0; color: #333; }'
        $html += '    pre { white-space: pre-wrap; word-break: break-word; padding: 12px; border: 1px solid #ddd; background: #fafafa; }'
        $html += '  </style>'
        $html += '</head>'
        $html += '<body>'
        $html += "  <h1>$escapedTitle</h1>"
        $html += ('  <div class="meta">' + $escapedMeta + '</div>')
        $html += '  <pre>'
        $html += ($bodyLines -join "`n")
        $html += '  </pre>'
        $html += '</body>'
        $html += '</html>'

        $html | Out-File -LiteralPath $path -Encoding utf8

        Write-Host 'HTML-отчёт сохранён:'
        Write-Host $path
        Write-ToolkitLog "Экспорт отчёта: HTML — $path ($($Script:Report.Count) строк)"
    }
    catch {
        Write-Host "Ошибка экспорта HTML-отчёта: $($_.Exception.Message)"
        Write-ToolkitLog "Экспорт отчёта: HTML — ошибка: $($_.Exception.Message)"
    }

    if (-not $NoPause) {
        Wait-Enter
    }
}

function Invoke-QuickReport {
    param(
        [switch]$NoPause
    )

    Write-ToolkitLog 'Быстрый отчёт: запуск — начало'

    Clear-Report
    Add-ReportLine ''
    Add-ReportLine '===== QUICK REPORT ====='
    Add-ReportLine "Время     : $(Get-Date)"
    Add-ReportLine "Компьютер : $env:COMPUTERNAME"
    Add-ReportLine "Пользователь: $env:USERNAME"
    Add-ReportLine "Версия    : $($Script:ToolkitVersion)"

    try {
        Get-SystemInfo -NoPause
        Get-DiskInfo -NoPause
        Get-NetworkInfo -NoPause
        Get-DnsInfo -NoPause
        Get-ServiceHealth -NoPause
        Get-ExternalIpInfo -NoPause

        Write-ToolkitLog 'Быстрый отчёт: сбор данных — завершено'
    }
    catch {
        Add-ReportLine "Quick report ERROR: $($_.Exception.Message)"
        Write-ToolkitLog "Быстрый отчёт: ошибка при сборе — $($_.Exception.Message)"
    }

    Write-Host ''
    Write-Host 'Быстрый отчёт собран.'
    Write-Host 'Экспортировать отчёт?'

    $exportTxt = Read-Host 'TXT (y/n)'
    if ($exportTxt -match '^(y|Y|д|Д)$') {
        Write-ToolkitLog 'Быстрый отчёт: экспорт TXT по запросу пользователя'
        Export-Report -NoPause
    }

    $exportHtml = Read-Host 'HTML (y/n)'
    if ($exportHtml -match '^(y|Y|д|Д)$') {
        Write-ToolkitLog 'Быстрый отчёт: экспорт HTML по запросу пользователя'
        Export-HtmlReport -NoPause
    }

    Write-ToolkitLog 'Быстрый отчёт: завершение'

    if (-not $NoPause) {
        Wait-Enter
    }
}
