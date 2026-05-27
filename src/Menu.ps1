# Menu.ps1 — главное меню

function Show-Menu {
    while ($true) {
        Show-Header

        $bufferLines = $Script:Report.Count
        Write-Host "Строк в буфере отчёта: $bufferLines"
        Write-Host ''

        Write-Host '--- Система ---'
        Write-Host '1. Информация о системе'
        Write-Host '2. Диски'
        Write-Host '7. Критичные службы'
        Write-Host ''
        Write-Host '--- Сеть и DNS ---'
        Write-Host '3. Информация о сети'
        Write-Host '4. DNS информация'
        Write-Host '5. Проверка DNS-имени'
        Write-Host '6. Проверка адреса или порта'
        Write-Host ''
        Write-Host '--- Отчётность ---'
        Write-Host '10. Последние ошибки Event Log'
        Write-Host '11. Экспорт отчёта в HTML'
        Write-Host '12. Быстрый отчёт'
        Write-Host '13. Проверка адресов из локального конфига'
        Write-Host ''
        Write-Host '--- Отчёт ---'
        Write-Host '8. Экспорт отчёта сессии в TXT'
        Write-Host '9. Очистить буфер отчёта'
        Write-Host '0. Выход'
        Write-Host ''

        $choice = Read-Host 'Выбери пункт'

        switch ($choice) {
            '1' {
                Write-ToolkitLog 'Меню: пункт 1 — информация о системе'
                Get-SystemInfo
            }
            '2' {
                Write-ToolkitLog 'Меню: пункт 2 — диски'
                Get-DiskInfo
            }
            '3' {
                Write-ToolkitLog 'Меню: пункт 3 — информация о сети'
                Get-NetworkInfo
            }
            '4' {
                Write-ToolkitLog 'Меню: пункт 4 — DNS информация'
                Get-DnsInfo
            }
            '5' {
                Write-ToolkitLog 'Меню: пункт 5 — проверка DNS-имени'
                Test-DnsResolution
            }
            '6' {
                Write-ToolkitLog 'Меню: пункт 6 — проверка адреса или порта'
                Test-NetworkTarget
            }
            '7' {
                Write-ToolkitLog 'Меню: пункт 7 — критичные службы'
                Get-ServiceHealth
            }
            '10' {
                Write-ToolkitLog 'Меню: пункт 10 — последние ошибки Event Log'
                Get-RecentEventErrors
            }
            '11' {
                Write-ToolkitLog 'Меню: пункт 11 — экспорт отчёта в HTML'
                Export-HtmlReport
            }
            '12' {
                Write-ToolkitLog 'Меню: пункт 12 — быстрый отчёт'
                Invoke-QuickReport
            }
            '13' {
                Write-ToolkitLog 'Меню: пункт 13 — проверка адресов из локального конфига'
                Test-ConfiguredEndpoints
            }
            '8' {
                Write-ToolkitLog 'Меню: пункт 8 — экспорт отчёта'
                Export-Report
            }
            '9' {
                Write-ToolkitLog 'Меню: пункт 9 — очистить буфер отчёта'
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
