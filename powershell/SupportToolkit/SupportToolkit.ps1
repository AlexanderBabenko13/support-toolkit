# ==========================================================
# SupportToolkit.ps1
# v0.1 MVP
# Инструмент диагностики для L2 поддержки
# ==========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Script:Report = New-Object System.Collections.Generic.List[string]

function Add-ReportLine {
    param(
        [string]$Text
    )

    $Script:Report.Add($Text) | Out-Null
    Write-Host $Text
}

function Wait-Enter {
    Write-Host ""
    Read-Host "Нажми Enter для продолжения"
}

function Clear-Report {
    $Script:Report.Clear()
}

function Show-Header {
    Clear-Host
    Write-Host "==========================================="
    Write-Host " SupportToolkit v0.1"
    Write-Host " Диагностика для линии поддержки"
    Write-Host "==========================================="
    Write-Host ""
}

function Get-SystemInfo {
    Clear-Report
    Add-ReportLine "===== SYSTEM INFO ====="
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
    }
    catch {
        Add-ReportLine "OS info  : ERROR $($_.Exception.Message)"
    }

    Wait-Enter
}

function Get-NetworkInfo {
    Clear-Report
    Add-ReportLine "===== NETWORK INFO ====="

    try {
        $configs = Get-CimInstance Win32_NetworkAdapterConfiguration |
            Where-Object { $_.IPEnabled -eq $true }

        foreach ($cfg in $configs) {
            Add-ReportLine ""
            Add-ReportLine "Adapter  : $($cfg.Description)"
            Add-ReportLine "IPv4     : $($cfg.IPAddress -join ', ')"
            Add-ReportLine "Mask     : $($cfg.IPSubnet -join ', ')"
            Add-ReportLine "Gateway  : $($cfg.DefaultIPGateway -join ', ')"
            Add-ReportLine "DNS      : $($cfg.DNSServerSearchOrder -join ', ')"
            Add-ReportLine "DHCP     : $($cfg.DHCPEnabled)"
        }
    }
    catch {
        Add-ReportLine "Network info ERROR: $($_.Exception.Message)"
    }

    Wait-Enter
}

function Test-NetworkTarget {
    Clear-Report
    Add-ReportLine "===== CONNECTION TEST ====="

    $target = Read-Host "Введи адрес или IP для проверки"
    if ([string]::IsNullOrWhiteSpace($target)) {
        Add-ReportLine "Адрес не указан."
        Wait-Enter
        return
    }

    $portInput = Read-Host "Введи порт, например 443. Можно оставить пустым для ping"
    
    try {
        if ([string]::IsNullOrWhiteSpace($portInput)) {
            Add-ReportLine "Ping test: $target"
            $ping = Test-Connection -ComputerName $target -Count 4 -ErrorAction Stop

            foreach ($item in $ping) {
                Add-ReportLine "Reply from $($item.Address): $($item.ResponseTime) ms"
            }
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
        }
    }
    catch {
        Add-ReportLine "Connection test ERROR: $($_.Exception.Message)"
    }

    Wait-Enter
}

function Export-Report {
    if ($Script:Report.Count -eq 0) {
        Write-Host "Отчета пока нет. Сначала выполни диагностику."
        Wait-Enter
        return
    }

    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $path = Join-Path $env:TEMP "SupportToolkit_Report_$timestamp.txt"

        $header = @(
            "SupportToolkit Report"
            "Computer: $env:COMPUTERNAME"
            "User: $env:USERNAME"
            "Time: $(Get-Date)"
            ""
        )

        $content = $header + $Script:Report
        $content | Out-File -FilePath $path -Encoding UTF8

        Write-Host "Отчет сохранен:"
        Write-Host $path
    }
    catch {
        Write-Host "Ошибка экспорта отчета: $($_.Exception.Message)"
    }

    Wait-Enter
}

function Show-Menu {
    while ($true) {
        Show-Header

        Write-Host "1. Информация о системе"
        Write-Host "2. Информация о сети"
        Write-Host "3. Проверка адреса или порта"
        Write-Host "4. Экспорт последнего отчета в TXT"
        Write-Host "0. Выход"
        Write-Host ""

        $choice = Read-Host "Выбери пункт"

        switch ($choice) {
            "1" { Get-SystemInfo }
            "2" { Get-NetworkInfo }
            "3" { Test-NetworkTarget }
            "4" { Export-Report }
            "0" { return }
            default {
                Write-Host "Неизвестный пункт меню."
                Wait-Enter
            }
        }
    }
}

Show-Menu