# ==========================================================
# Build-SingleFile.ps1
# Сборка SupportToolkit в portable-версию
# ==========================================================

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$srcOrder = @(
    'Core.ps1',
    'Report.ps1',
    'System.ps1',
    'Disk.ps1',
    'Network.ps1',
    'Dns.ps1',
    'Services.ps1',
    'Menu.ps1'
)

$srcPath = Join-Path $ProjectRoot 'src'
$corePath = Join-Path $srcPath 'Core.ps1'
$distPath = Join-Path $ProjectRoot 'dist'
$packagePath = Join-Path $distPath 'package'
$outFile = Join-Path $packagePath 'SupportToolkit.ps1'

$configSourcePath = Join-Path $ProjectRoot 'config\endpoints.example.json'
$configTargetDir = Join-Path $packagePath 'config'
$configTargetPath = Join-Path $configTargetDir 'endpoints.example.json'

if (-not (Test-Path -LiteralPath $corePath)) {
    throw "Не найден Core.ps1: $corePath"
}

$coreContent = Get-Content -LiteralPath $corePath -Raw -Encoding UTF8
$version = 'unknown'

if ($coreContent -match "\`$Script:ToolkitVersion\s*=\s*'([^']+)'") {
    $version = $Matches[1]
}

if (Test-Path -LiteralPath $packagePath) {
    Remove-Item -LiteralPath $packagePath -Recurse -Force
}

New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
New-Item -ItemType Directory -Path $configTargetDir -Force | Out-Null

$buildTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$lines = [System.Collections.Generic.List[string]]::new()

$lines.Add('# ==========================================================') | Out-Null
$lines.Add('# SupportToolkit.ps1') | Out-Null
$lines.Add('# Portable single-file build') | Out-Null
$lines.Add("# Version: $version") | Out-Null
$lines.Add("# Generated: $buildTime") | Out-Null
$lines.Add('# ==========================================================') | Out-Null
$lines.Add('') | Out-Null
$lines.Add('param(') | Out-Null
$lines.Add('    [switch]$QuickReport') | Out-Null
$lines.Add(')') | Out-Null
$lines.Add('') | Out-Null
$lines.Add('Set-StrictMode -Version Latest') | Out-Null
$lines.Add('$ErrorActionPreference = ''Continue''') | Out-Null
$lines.Add('$Script:ToolkitRoot = $PSScriptRoot') | Out-Null
$lines.Add('') | Out-Null

foreach ($file in $srcOrder) {
    $path = Join-Path $srcPath $file

    if (-not (Test-Path -LiteralPath $path)) {
        throw "Не найден файл модуля: $path"
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8

    $lines.Add('') | Out-Null
    $lines.Add('# ==========================================================') | Out-Null
    $lines.Add("# BEGIN: src/$file") | Out-Null
    $lines.Add('# ==========================================================') | Out-Null
    $lines.Add($content.TrimEnd()) | Out-Null
    $lines.Add('# ==========================================================') | Out-Null
    $lines.Add("# END: src/$file") | Out-Null
    $lines.Add('# ==========================================================') | Out-Null
}

$lines.Add('') | Out-Null
$lines.Add('Initialize-Toolkit') | Out-Null
$lines.Add('Write-ToolkitLog "Запуск SupportToolkit v$($Script:ToolkitVersion) portable (PS $($PSVersionTable.PSVersion))"') | Out-Null
$lines.Add('') | Out-Null
$lines.Add('if ($QuickReport) {') | Out-Null
$lines.Add('    Write-ToolkitLog ''Параметр запуска: -QuickReport''') | Out-Null
$lines.Add('    Invoke-QuickReport') | Out-Null
$lines.Add('}') | Out-Null
$lines.Add('else {') | Out-Null
$lines.Add('    Show-Menu') | Out-Null
$lines.Add('}') | Out-Null

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($outFile, ($lines -join [Environment]::NewLine), $utf8NoBom)

if (Test-Path -LiteralPath $configSourcePath) {
    Copy-Item -LiteralPath $configSourcePath -Destination $configTargetPath -Force
}

$readmePath = Join-Path $packagePath 'README_RUN.md'

$readmeLines = @(
    '# SupportToolkit portable',
    '',
    '## Запуск меню',
    '',
    '```powershell',
    'pwsh -NoProfile -File .\SupportToolkit.ps1',
    '```',
    '',
    '## Быстрый отчёт',
    '',
    '```powershell',
    'pwsh -NoProfile -File .\SupportToolkit.ps1 -QuickReport',
    '```',
    '',
    '## Локальные endpoint-проверки',
    '',
    'Для своих адресов создай файл:',
    '',
    '```text',
    'config\endpoints.local.json',
    '```',
    '',
    'Можно взять пример из:',
    '',
    '```text',
    'config\endpoints.example.json',
    '```',
    '',
    'Файл endpoints.local.json не должен попадать в GitHub.'
)

[System.IO.File]::WriteAllText($readmePath, ($readmeLines -join [Environment]::NewLine), $utf8NoBom)

$zipPath = Join-Path $distPath "SupportToolkit_v$version.zip"

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

$packageItems = Join-Path $packagePath '*'
Compress-Archive -Path $packageItems -DestinationPath $zipPath -Force

Write-Host 'Сборка готова:'
Write-Host $outFile
Write-Host $zipPath