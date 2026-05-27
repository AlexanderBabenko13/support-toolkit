# ==========================================================
# SupportToolkit.ps1 — launcher
# v0.4 — network extended
# ==========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$Script:ToolkitRoot = $PSScriptRoot

$srcFiles = @(
    'Core.ps1'
    'Report.ps1'
    'System.ps1'
    'Disk.ps1'
    'Network.ps1'
    'Dns.ps1'
    'Services.ps1'
    'Menu.ps1'
)

foreach ($file in $srcFiles) {
    $path = Join-Path $Script:ToolkitRoot 'src' $file
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Error "Не найден файл модуля: $path"
        exit 1
    }

    . $path
}

Initialize-Toolkit
Write-ToolkitLog "Запуск SupportToolkit v$($Script:ToolkitVersion) (PS $($PSVersionTable.PSVersion))"

Show-Menu
