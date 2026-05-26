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

    Wait-Enter
}

function Export-Report {
    if ($Script:Report.Count -eq 0) {
        Write-Host 'Отчёта пока нет. Сначала выполни диагностику.'
        Write-ToolkitLog 'Экспорт отчёта: буфер пуст'
        Wait-Enter
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

    Wait-Enter
}
