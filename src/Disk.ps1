# Disk.ps1 — диагностика локальных дисков (read-only)

function Get-DiskInfo {
    param(
        [switch]$NoPause
    )

    Write-ToolkitLog 'Диагностика: диски — начало'

    Add-ReportLine ''
    Add-ReportLine '===== DISK INFO ====='

    try {
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3'

        if (-not $disks) {
            Add-ReportLine 'Локальные диски не найдены.'
            Write-ToolkitLog 'Диагностика: диски — диски не найдены'
            if (-not $NoPause) {
                Wait-Enter
            }
            return
        }

        foreach ($disk in $disks) {
            $sizeGb = [math]::Round($disk.Size / 1GB, 2)
            $freeGb = [math]::Round($disk.FreeSpace / 1GB, 2)
            $pctFree = if ($disk.Size -gt 0) {
                [math]::Round(100 * $disk.FreeSpace / $disk.Size, 1)
            }
            else {
                0
            }

            $label = if ([string]::IsNullOrWhiteSpace($disk.VolumeName)) { '(без метки)' } else { $disk.VolumeName }

            Add-ReportLine ''
            Add-ReportLine "Диск     : $($disk.DeviceID)"
            Add-ReportLine "Метка    : $label"
            Add-ReportLine "ФС       : $($disk.FileSystem)"
            Add-ReportLine "Размер   : $sizeGb GB"
            Add-ReportLine "Свободно : $freeGb GB ($pctFree %)"
        }

        Write-ToolkitLog "Диагностика: диски — завершено ($(@($disks).Count) дисков)"
    }
    catch {
        Add-ReportLine "Disk info ERROR: $($_.Exception.Message)"
        Write-ToolkitLog "Диагностика: диски — ошибка: $($_.Exception.Message)"
    }

    if (-not $NoPause) {
        Wait-Enter
    }
}
