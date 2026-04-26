<#
.SYNOPSIS
    Script definitivo de optimización gaming + instalador de drivers/programas.
    Estilo AZTEKILLERTECH para Windows 10/11.
.NOTES
    Autor: AZTEKILLERTECH
    Web: https://aztekillertech.net
    Ejecutar como Administrador.
#>

# Comprobar administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ EJECUTA COMO ADMINISTRADOR (clic derecho > PowerShell como Admin)" -ForegroundColor Red
    pause; exit
}

# Colores personalizados (ahora válidos para ConsoleColor)
$colorTitulo = "Magenta"
$colorPregunta = "DarkMagenta"
$colorAceptado = "Green"
$colorRechazado = "Red"

# Función para dibujar banner
function Mostrar-Banner {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Magenta
    Write-Host "    🎮  AZTEKILLERTECH GAMING OPTIMIZER  🎮        " -ForegroundColor Magenta
    Write-Host "====================================================" -ForegroundColor Magenta
    Write-Host "   Optimización extrema + Instalador de drivers     " -ForegroundColor Cyan
    Write-Host "   Elige una opción del menú                        " -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Magenta
    Write-Host ""
}

# Función para preguntar Sí/No
function Preguntar($mensaje) {
    Write-Host $mensaje -ForegroundColor $colorPregunta
    $resp = Read-Host "  ¿Aplicar? (S/N)"
    return ($resp -eq 'S' -or $resp -eq 's')
}

# Función para abrir URL en navegador
function Abrir-URL($url) {
    Start-Process $url
    Write-Host "  🌐 Abriendo enlace: $url" -ForegroundColor Cyan
}

# Función para detectar GPU real (ignorando drivers virtuales como AnyViewer)
function Detectar-GPU-Real {
    $gpuReal = Get-WmiObject Win32_VideoController | Where-Object {
        $_.Name -notlike "*Microsoft*" -and 
        $_.Name -notlike "*Remote*" -and 
        $_.Name -notlike "*AnyViewer*" -and 
        $_.Name -notlike "*Virtual*"
    } | Select-Object -First 1
    if ($gpuReal) {
        return $gpuReal.Name
    } else {
        return "No detectada (genérica)"
    }
}

# Menú de instalación de programas y drivers
function Instalar-Programas {
    Mostrar-Banner
    Write-Host "  📦 INSTALADOR DE DRIVERS Y PROGRAMAS GAMING" -ForegroundColor Yellow
    Write-Host "  Selecciona qué quieres descargar/instalar:" -ForegroundColor White
    Write-Host ""
    
    # Detectar GPU real
    $gpuReal = Detectar-GPU-Real
    Write-Host "  🖥️  GPU principal detectada: $gpuReal" -ForegroundColor Cyan
    Write-Host ""
    
    # Lista de programas (nombre, URL, tipo)
    $programas = @(
        @{Nombre="🎮 NVIDIA GeForce Experience / Driver"; URL="https://www.nvidia.com/download/index.aspx"; Tipo="Driver NVIDIA"},
        @{Nombre="🟥 AMD Adrenalin Edition"; URL="https://www.amd.com/es/support"; Tipo="Driver AMD"},
        @{Nombre="💠 Intel Driver & Support Assistant"; URL="https://www.intel.com/content/www/us/en/support/detect.html"; Tipo="Driver Intel"},
        @{Nombre="📊 MSI Afterburner (Overclock/Monitoreo)"; URL="https://www.msi.com/Landing/afterburner/graphics-cards"; Tipo="Utilidad"},
        @{Nombre="🎧 Discord (Comunicación)"; URL="https://discord.com/download"; Tipo="Programa"},
        @{Nombre="🛒 Steam (Tienda de juegos)"; URL="https://store.steampowered.com/about/"; Tipo="Programa"},
        @{Nombre="🔧 CPU-Z (Información del sistema)"; URL="https://www.cpuid.com/softwares/cpu-z.html"; Tipo="Utilidad"},
        @{Nombre="📈 GPU-Z (Información gráfica)"; URL="https://www.techpowerup.com/gpuz/"; Tipo="Utilidad"},
        @{Nombre="🌡️ HWMonitor (Temperaturas)"; URL="https://www.cpuid.com/softwares/hwmonitor.html"; Tipo="Utilidad"},
        @{Nombre="⚙️ O&O ShutUp10 (Privacidad/rendimiento)"; URL="https://www.oo-software.com/en/shutup10"; Tipo="Optimización"},
        @{Nombre="📦 Visual C++ Redistributables (Todo en uno)"; URL="https://github.com/abbodi1406/vcredist/releases"; Tipo="Requerido"}
    )
    
    $i = 1
    foreach ($prog in $programas) {
        Write-Host "  $i. $($prog.Nombre)" -ForegroundColor $colorPregunta
        $i++
    }
    Write-Host "  0. Volver al menú principal" -ForegroundColor Gray
    Write-Host ""
    
    $seleccion = Read-Host "  Elige un número"
    if ($seleccion -eq "0") { return }
    
    if ($seleccion -match "^\d+$" -and [int]$seleccion -ge 1 -and [int]$seleccion -le $programas.Count) {
        $elegido = $programas[[int]$seleccion - 1]
        Write-Host "  Abriendo descarga de: $($elegido.Nombre)" -ForegroundColor Yellow
        Abrir-URL $elegido.URL
        Write-Host "  Presiona cualquier tecla para volver..." -ForegroundColor Gray
        pause
        Instalar-Programas
    } else {
        Write-Host "  Opción no válida" -ForegroundColor Red
        Start-Sleep -Seconds 1
        Instalar-Programas
    }
}

# Función de optimización (con colores corregidos)
function Optimizar-Sistema {
    Mostrar-Banner
    Write-Host "  🚀 INICIANDO OPTIMIZACIÓN DE FPS" -ForegroundColor Yellow
    Write-Host "  Responde S (Sí) o N (No) a cada ajuste`n" -ForegroundColor White
    
    # 1. Plan energía
    if (Preguntar "⚡ ¿Cambiar plan de energía a ALTO RENDIMIENTO?") {
        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-Host "  ✅ Plan Alto Rendimiento activado" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    # 2. Core Parking
    if (Preguntar "🧠 ¿Desactivar Core Parking? (usa todos los núcleos)") {
        powercfg -setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 0
        powercfg -setactive scheme_current
        Write-Host "  ✅ Core Parking desactivado" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    # 3. Servicios
    if (Preguntar "🛑 ¿Desactivar servicios en segundo plano (telemetría, indexador)?") {
        $servicios = @("DiagTrack","WSearch","SysMain","dmwappushservice","MapsBroker","XblAuthManager")
        foreach ($svc in $servicios) {
            Stop-Service $svc -Force -ErrorAction SilentlyContinue
            Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "  ✅ Desactivado: $svc" -ForegroundColor $colorAceptado
        }
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    # 4. Efectos visuales
    if (Preguntar "🎨 ¿Desactivar efectos visuales? (más FPS)") {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
        Write-Host "  ✅ Efectos desactivados" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    # 5. Prioridad juegos
    if (Preguntar "🎯 ¿Dar prioridad máxima a juegos?") {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -ErrorAction SilentlyContinue
        Write-Host "  ✅ Prioridad a juegos aplicada" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    # 6. MPO
    if (Preguntar "🖥️ ¿Desactivar MPO? (soluciona tirones)") {
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 5 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ MPO desactivado" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    # 7. Notificaciones
    if (Preguntar "🔕 ¿Desactivar notificaciones y sugerencias?") {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWord
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord
        Write-Host "  ✅ Notificaciones desactivadas" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    # 8. Tareas programadas
    if (Preguntar "📅 ¿Desactivar tareas de telemetría?") {
        $tareas = @("\Microsoft\Windows\Application Experience\*","\Microsoft\Windows\Customer Experience Improvement Program\*","\Microsoft\Windows\DiskDiagnostic\*")
        foreach ($tarea in $tareas) {
            Get-ScheduledTask -TaskPath $tarea -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
            Write-Host "  ✅ Tareas desactivadas: $tarea" -ForegroundColor $colorAceptado
        }
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    # 9. Limpieza
    if (Preguntar "🗑️ ¿Ejecutar limpieza de archivos temporales?") {
        CleanMgr /sagerun:1 -ErrorAction SilentlyContinue
        Write-Host "  ✅ Limpieza ejecutada" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    # 10. Pagefile
    $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    if ($ramGB -ge 16) {
        if (Preguntar "💾 Tienes $ramGB GB RAM. ¿Desactivar Pagefile? (solo 32GB+)") {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Value "" -Type MultiString
            Write-Host "  ✅ Pagefile desactivado" -ForegroundColor $colorAceptado
        } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    } else {
        Write-Host "  ⏩ Pagefile: tienes $ramGB GB, no recomendado" -ForegroundColor Gray
    }
    
    Write-Host "`n  ✅ Optimización completada. REINICIA para aplicar cambios." -ForegroundColor Green
    pause
}

# --- MENÚ PRINCIPAL ---
do {
    Mostrar-Banner
    Write-Host "  🎯 SELECCIONA UNA OPCIÓN:" -ForegroundColor Yellow
    Write-Host "  1. 🚀 Optimizar FPS (recomendado para juegos)" -ForegroundColor Cyan
    Write-Host "  2. 📦 Instalar drivers y programas gaming" -ForegroundColor Cyan
    Write-Host "  0. ❌ Salir" -ForegroundColor Gray
    Write-Host ""
    $menu = Read-Host "  Elige [1,2,0]"
    
    switch ($menu) {
        "1" { Optimizar-Sistema }
        "2" { Instalar-Programas }
        "0" { Write-Host "  Hasta luego, visita aztekillertech.net" -ForegroundColor Magenta; break }
        default { Write-Host "  Opción inválida" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($menu -ne "0")
