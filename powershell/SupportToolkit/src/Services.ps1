# Services.ps1 — статус критичных служб (read-only)

function Get-ServiceHealth {
    Write-ToolkitLog 'Диагностика: критичные службы — начало'

    Add-ReportLine ''
    Add-ReportLine '===== SERVICE HEALTH ====='

    $criticalServices = @(
        'Spooler'
        'Dnscache'
        'LanmanWorkstation'
        'LanmanServer'
        'Winmgmt'
        'EventLog'
    )

    try {
        foreach ($serviceName in $criticalServices) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

            if ($null -eq $service) {
                Add-ReportLine "$serviceName : не найдена"
                continue
            }

            Add-ReportLine "$($service.Name) : $($service.Status) ($($service.DisplayName))"
        }

        Write-ToolkitLog 'Диагностика: критичные службы — завершено'
    }
    catch {
        Add-ReportLine "Service health ERROR: $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: критичные службы — ошибка: $($_.Exception.Message)"
    }

    Wait-Enter
}
