# System.ps1 — диагностика системы

function Get-SystemInfo {
    param(
        [switch]$NoPause
    )

    Write-ToolkitLog 'Диагностика: информация о системе — начало'

    Add-ReportLine ''
    Add-ReportLine '===== SYSTEM INFO ====='
    Add-ReportLine "Computer : $env:COMPUTERNAME"
    Add-ReportLine "User     : $env:USERNAME"
    Add-ReportLine "Domain   : $env:USERDOMAIN"
    Add-ReportLine "PS       : $($PSVersionTable.PSVersion)"

    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $lastBoot = $os.LastBootUpTime
        $uptime = (Get-Date) - $lastBoot

        Add-ReportLine "OS       : $($os.Caption)"
        Add-ReportLine "Version  : $($os.Version)"
        Add-ReportLine "Boot     : $lastBoot"
        Add-ReportLine "Uptime   : $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
        Write-ToolkitLog 'Диагностика: информация о системе — завершено'
    }
    catch {
        Add-ReportLine "OS info  : ERROR $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: информация о системе — ошибка: $($_.Exception.Message)"
    }

    if (-not $NoPause) {
        Wait-Enter
    }
}

function Get-RecentEventErrors {
    param(
        [switch]$NoPause
    )

    Write-ToolkitLog 'Диагностика: последние ошибки Event Log — начало'

    Add-ReportLine ''
    Add-ReportLine '===== RECENT EVENT ERRORS (System/Application) ====='
    Add-ReportLine 'Уровни: Error (2) и Warning (3). Максимум 20 событий на журнал.'

    $logs = @('System', 'Application')

    foreach ($logName in $logs) {
        Add-ReportLine ''
        Add-ReportLine "--- Журнал: $logName ---"

        try {
            $events = Get-WinEvent -FilterHashtable @{ LogName = $logName; Level = 2, 3 } -MaxEvents 20 -ErrorAction Stop

            if (-not $events) {
                Add-ReportLine 'События не найдены.'
                continue
            }

            foreach ($ev in $events) {
                $message = $ev.Message
                if ([string]::IsNullOrWhiteSpace($message)) {
                    $message = '(без текста сообщения)'
                }

                $maxLen = 300
                if ($message.Length -gt $maxLen) {
                    $message = $message.Substring(0, $maxLen) + '...'
                }

                Add-ReportLine ''
                Add-ReportLine "TimeCreated      : $($ev.TimeCreated)"
                Add-ReportLine "LogName          : $($ev.LogName)"
                Add-ReportLine "ProviderName     : $($ev.ProviderName)"
                Add-ReportLine "Id               : $($ev.Id)"
                Add-ReportLine "LevelDisplayName : $($ev.LevelDisplayName)"
                Add-ReportLine "Message          : $message"
            }

            Write-ToolkitLog "Диагностика: Event Log ($logName) — завершено ($(@($events).Count) событий)"
        }
        catch {
            Add-ReportLine "Event log ERROR: $($_.Exception.Message)"
            Write-ToolkitLog "Диагностика: Event Log ($logName) — ошибка: $($_.Exception.Message)"
        }
    }

    Write-ToolkitLog 'Диагностика: последние ошибки Event Log — завершено'

    if (-not $NoPause) {
        Wait-Enter
    }
}
