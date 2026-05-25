# Menu.ps1 — главное меню

function Show-Menu {
    while ($true) {
        Show-Header

        $bufferLines = $Script:Report.Count
        Write-Host "Строк в буфере отчёта: $bufferLines"
        Write-Host ''

        Write-Host '1. Информация о системе'
        Write-Host '2. Информация о сети'
        Write-Host '3. Проверка адреса или порта'
        Write-Host '4. Экспорт отчёта сессии в TXT'
        Write-Host '5. Очистить буфер отчёта'
        Write-Host '0. Выход'
        Write-Host ''

        $choice = Read-Host 'Выбери пункт'

        switch ($choice) {
            '1' {
                Write-ToolkitLog 'Меню: пункт 1 — информация о системе'
                Get-SystemInfo
            }
            '2' {
                Write-ToolkitLog 'Меню: пункт 2 — информация о сети'
                Get-NetworkInfo
            }
            '3' {
                Write-ToolkitLog 'Меню: пункт 3 — проверка адреса или порта'
                Test-NetworkTarget
            }
            '4' {
                Write-ToolkitLog 'Меню: пункт 4 — экспорт отчёта'
                Export-Report
            }
            '5' {
                Write-ToolkitLog 'Меню: пункт 5 — очистить буфер отчёта'
                Clear-ReportBuffer
            }
            '0' {
                Write-ToolkitLog 'Завершение работы'
                return
            }
            default {
                Write-Host 'Неизвестный пункт меню.'
                Write-ToolkitLog "Меню: неизвестный пункт — $choice"
                Wait-Enter
            }
        }
    }
}
