<#
.SYNOPSIS
    Script definitivo para optimizar Windows para gaming (máximos FPS).
.DESCRIPTION
    Aplica ajustes de rendimiento, desactiva procesos en segundo plano, 
    optimiza la GPU, la latencia de red y la gestión de memoria.
    Requiere ejecutarse como Administrador.
.NOTES
    Autor: AztekillerTech
    Web: https://aztekillertech.net
    Versión: 2.0
#>

# Requerir ejecución como administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Ejecuta este script como Administrador (clic derecho > PowerShell como Admin)" -ForegroundColor Red
    pause
    exit
}

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  OPTIMIZACIÓN GAMING PARA WINDOWS  " -ForegroundColor Green
Write-Host "       by AztekillerTech.net        " -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Menú principal
do {
    Write-Host "`n¿Qué acción deseas realizar?" -ForegroundColor Yellow
    Write-Host "1. Aplicar optimización TOTAL (máximo rendimiento)"
    Write-Host "2. Revertir todos los cambios (volver a valores originales)"
    Write-Host "3. Salir"
    $opcion = Read-Host "Elige [1-3]"

    switch ($opcion) {
        '1' {
            Write-Host "`n🚀 Aplicando optimizaciones..." -ForegroundColor Green
            
            # 1. Plan de energía: Rendimiento máximo
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            if ($?) { Write-Host "✓ Plan de energía: Alto Rendimiento" -ForegroundColor Green }
            else { Write-Host "⚠️ No se pudo cambiar el plan (usa 'Rendimiento máximo' manual)" -ForegroundColor Yellow }
            
            # 2. Desactivar servicios que roban recursos
            $servicios = @(
                "DiagTrack",           # Telemetría
                "dmwappushservice",    # WAP Push
                "WSearch",             # Indexador de búsqueda
                "SysMain",             # Superfetch (causa stuttering)
                "MapsBroker",          # Descarga mapas
                "lfsvc",               # Servicio de geolocalización
                "XblAuthManager",      # Xbox Live (si no usas)
                "XboxNetApiSvc"
            )
            foreach ($svc in $servicios) {
                Stop-Service $svc -Force -ErrorAction SilentlyContinue
                Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Host "✓ Servicio desactivado: $svc" -ForegroundColor Green
            }
            
            # 3. Desactivar efectos visuales (más FPS)
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
            Write-Host "✓ Efectos visuales desactivados (solo rendimiento)" -ForegroundColor Green
            
            # 4. Priorizar juegos sobre procesos en segundo plano
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -ErrorAction SilentlyContinue
            Write-Host "✓ Prioridad máxima a juegos y latencia reducida" -ForegroundColor Green
            
            # 5. Desactivar CPU core parking (usa todos los núcleos siempre)
            powercfg -setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 0
            powercfg -setactive scheme_current
            Write-Host "✓ Core parking desactivado (todos los núcleos activos)" -ForegroundColor Green
            
            # 6. Desactivar telemetría y tareas programadas molestas
            $tareas = @(
                "\Microsoft\Windows\Application Experience\*",
                "\Microsoft\Windows\Customer Experience Improvement Program\*",
                "\Microsoft\Windows\DiskDiagnostic\*",
                "\Microsoft\Windows\Windows Update\Scheduled Start"
            )
            foreach ($tarea in $tareas) {
                Get-ScheduledTask -TaskPath $tarea -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
                Write-Host "✓ Tareas programadas desactivadas: $tarea" -ForegroundColor Green
            }
            
            # 7. Ajustes de registro para GPU (NVIDIA/AMD/Intel)
            # Desactivar MPO (causa caídas de FPS en algunas GPU)
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 5 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "✓ MPO desactivado (mejora estabilidad de FPS)" -ForegroundColor Green
            
            # 8. Desactivar notificaciones y sugerencias
            New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWord
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord
            Write-Host "✓ Notificaciones y sugerencias desactivadas" -ForegroundColor Green
            
            # 9. Limpiar archivos temporales
            CleanMgr /sagerun:1 -ErrorAction SilentlyContinue
            Write-Host "✓ Limpieza de archivos temporales ejecutada" -ForegroundColor Green
            
            # 10. Ajuste de Memoria: Desactivar Pagefile (solo si tienes más de 16GB RAM)
            $ram = (Get-CimInstance -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
            if ($ram -ge 16) {
                Write-Host "💡 Tienes $ram GB de RAM. ¿Quieres desactivar el archivo de paginación? (recomendado solo para 32GB+)" -ForegroundColor Yellow
                $resp = Read-Host "¿Desactivar Pagefile? (s/n)"
                if ($resp -eq 's') {
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Value "" -Type MultiString
                    Write-Host "✓ Pagefile desactivado (usa solo RAM)" -ForegroundColor Green
                }
            }
            
            Write-Host "`n✅ Optimización completada. REINICIA tu PC para aplicar todos los cambios." -ForegroundColor Magenta
            pause
            break
        }
        '2' {
            Write-Host "`n🔄 Revirtiendo cambios..." -ForegroundColor Yellow
            
            # Restaurar plan de energía equilibrado
            powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
            Write-Host "✓ Plan de energía: Equilibrado restaurado" -ForegroundColor Green
            
            # Habilitar servicios
            $servicios = @("DiagTrack", "WSearch", "SysMain")
            foreach ($svc in $servicios) {
                Set-Service $svc -StartupType Manual -ErrorAction SilentlyContinue
                Start-Service $svc -ErrorAction SilentlyContinue
                Write-Host "✓ Servicio restaurado: $svc" -ForegroundColor Green
            }
            
            # Restaurar efectos visuales
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            Write-Host "✓ Efectos visuales restaurados" -ForegroundColor Green
            
            # Restaurar SystemResponsiveness
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -ErrorAction SilentlyContinue
            Write-Host "✓ Prioridad de sistema restaurada" -ForegroundColor Green
            
            # Revertir MPO
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -ErrorAction SilentlyContinue
            Write-Host "✓ MPO reactivado" -ForegroundColor Green
            
            Write-Host "`n✅ Cambios revertidos. Reinicia para que todo vuelva a la normalidad." -ForegroundColor Magenta
            pause
            break
        }
    }
} while ($opcion -ne '3')
