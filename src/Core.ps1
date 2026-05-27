# Core.ps1 — версия, пути, инициализация, общие утилиты

$Script:ToolkitVersion = '0.4'
$Script:ReportsPath = Join-Path $Script:ToolkitRoot 'reports'

function Initialize-Toolkit {
    if (-not (Test-Path -LiteralPath $Script:ReportsPath)) {
        New-Item -ItemType Directory -Path $Script:ReportsPath -Force | Out-Null
    }

    $Script:Report = [System.Collections.Generic.List[string]]::new()
}

function Wait-Enter {
    Write-Host ''
    Read-Host 'Нажми Enter для продолжения'
}

function Show-Header {
    Clear-Host
    Write-Host '==========================================='
    Write-Host " SupportToolkit v$($Script:ToolkitVersion)"
    Write-Host ' Диагностика для линии поддержки'
    Write-Host '==========================================='
    Write-Host ''
}
