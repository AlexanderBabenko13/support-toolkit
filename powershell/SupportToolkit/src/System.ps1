# System.ps1 — диагностика системы

function Get-SystemInfo {
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

    Wait-Enter
}
