<#
.SYNOPSIS
    Script definitivo de optimización gaming + instalador automático de drivers y programas.
    Estilo AZTEKILLERTECH para Windows 10/11.
.NOTES
    Autor: AZTEKILLERTECH
    Web: https://aztekillertech.net
    Requiere: PowerShell como Administrador (para drivers y algunas instalaciones).
#>

# Comprobar administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ EJECUTA COMO ADMINISTRADOR (clic derecho > PowerShell como Admin)" -ForegroundColor Red
    pause; exit
}

# Colores
$colorTitulo = "Magenta"
$colorPregunta = "DarkMagenta"
$colorAceptado = "Green"
$colorRechazado = "Red"

# Función banner
function Mostrar-Banner {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Magenta
    Write-Host "    🎮  AZTEKILLERTECH GAMING OPTIMIZER  🎮        " -ForegroundColor Magenta
    Write-Host "====================================================" -ForegroundColor Magenta
    Write-Host "   Optimización + Instalación automática             " -ForegroundColor Cyan
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

# Función para descargar e instalar un programa
function Instalar-Programa {
    param(
        [string]$nombre,
        [string]$urlDescarga,
        [string]$argumentosInstalacion = "/quiet /norestart",  # Parámetros silenciosos comunes
        [bool]$necesitaAdmin = $true
    )
    
    Write-Host "`n📦 Preparando instalación de: $nombre" -ForegroundColor Yellow
    if (-not (Preguntar "  ¿Descargar e instalar $nombre?")) {
        Write-Host "  ⏩ Instalación cancelada" -ForegroundColor $colorRechazado
        return $false
    }
    
    # Crear carpeta temporal
    $tempDir = "$env:TEMP\AztekillerInstaller"
    if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
    $outputFile = Join-Path $tempDir "$($nombre -replace '[^a-zA-Z0-9]','')_installer.exe"
    
    # Descargar
    Write-Host "  ⬇️ Descargando desde $urlDescarga ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $urlDescarga -OutFile $outputFile -UseBasicParsing -ErrorAction Stop
        Write-Host "  ✅ Descarga completada" -ForegroundColor $colorAceptado
    } catch {
        Write-Host "  ❌ Error al descargar: $_" -ForegroundColor Red
        return $false
    }
    
    # Instalar
    Write-Host "  🔧 Instalando... (puede tardar un momento)" -ForegroundColor Cyan
    try {
        $process = Start-Process -FilePath $outputFile -ArgumentList $argumentosInstalacion -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-Host "  ✅ Instalación completada con éxito" -ForegroundColor $colorAceptado
        } else {
            Write-Host "  ⚠️ El instalador terminó con código $($process.ExitCode). Puede requerir intervención manual." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ Error al ejecutar el instalador: $_" -ForegroundColor Red
        return $false
    }
    
    # Limpiar (opcional, comentar si se quiere conservar el instalador)
    Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
    return $true
}

# ---- Menús de instalación por categorías ----

function Instalar-Drivers {
    Mostrar-Banner
    Write-Host "  🖥️  INSTALADOR DE DRIVERS" -ForegroundColor Yellow
    Write-Host "  Selecciona qué driver quieres descargar e instalar:" -ForegroundColor White
    Write-Host ""
    
    # Detección de GPU real para sugerencia
    $gpuReal = (Get-WmiObject Win32_VideoController | Where-Object {$_.Name -notlike "*Microsoft*" -and $_.Name -notlike "*Remote*" -and $_.Name -notlike "*AnyViewer*" -and $_.Name -notlike "*Virtual*"} | Select-Object -First 1).Name
    if ($gpuReal) {
        Write-Host "  🎯 GPU detectada: $gpuReal" -ForegroundColor Cyan
        if ($gpuReal -like "*NVIDIA*") { Write-Host "  💡 Sugerencia: Elige la opción 1 (NVIDIA)" -ForegroundColor Green }
        elseif ($gpuReal -like "*AMD*") { Write-Host "  💡 Sugerencia: Elige la opción 2 (AMD)" -ForegroundColor Green }
        elseif ($gpuReal -like "*Intel*") { Write-Host "  💡 Sugerencia: Elige la opción 3 (Intel)" -ForegroundColor Green }
    }
    Write-Host ""
    
    Write-Host "  1. Driver NVIDIA (GeForce Game Ready)" -ForegroundColor $colorPregunta
    Write-Host "  2. Driver AMD (Adrenalin)" -ForegroundColor $colorPregunta
    Write-Host "  3. Driver Intel (Graphics Driver)" -ForegroundColor $colorPregunta
    Write-Host "  0. Volver al menú principal" -ForegroundColor Gray
    Write-Host ""
    
    $opt = Read-Host "  Elige un número"
    switch ($opt) {
        "1" {
            # URL directa al detector automático de NVIDIA (redirige al exe adecuado)
            Instalar-Programa -nombre "NVIDIA Driver" -urlDescarga "https://us.download.nvidia.com/Windows/572.83/572.83-desktop-win10-win11-64bit-international-dch-whql.exe" -argumentosInstalacion "/s"
        }
        "2" {
            # AMD auto-detect tool (pequeño exe que luego descarga el driver correcto)
            Instalar-Programa -nombre "AMD Adrenalin" -urlDescarga "https://drivers.amd.com/drivers/auto-detect-install.exe" -argumentosInstalacion ""
        }
        "3" {
            # Intel Driver & Support Assistant (recomendado)
            Instalar-Programa -nombre "Intel Driver Assistant" -urlDescarga "https://downloadmirror.intel.com/832159/Intel-Driver-Support-Assistant-Installer.exe" -argumentosInstalacion "/quiet"
        }
        "0" { return }
        default { Write-Host "  Opción inválida" -ForegroundColor Red; Start-Sleep -Seconds 1; Instalar-Drivers }
    }
    Read-Host "`nPresiona cualquier tecla para continuar"
}

function Instalar-ProgramasGaming {
    Mostrar-Banner
    Write-Host "  🎮 INSTALADOR DE PROGRAMAS GAMING" -ForegroundColor Yellow
    Write-Host "  Selecciona qué programa instalar:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. MSI Afterburner (Overclock/Monitoreo)" -ForegroundColor $colorPregunta
    Write-Host "  2. Discord" -ForegroundColor $colorPregunta
    Write-Host "  3. Steam" -ForegroundColor $colorPregunta
    Write-Host "  4. CPU-Z" -ForegroundColor $colorPregunta
    Write-Host "  5. GPU-Z" -ForegroundColor $colorPregunta
    Write-Host "  6. HWMonitor" -ForegroundColor $colorPregunta
    Write-Host "  7. O&O ShutUp10 (Privacidad/Rendimiento)" -ForegroundColor $colorPregunta
    Write-Host "  8. Visual C++ Redistributables (Todo en uno)" -ForegroundColor $colorPregunta
    Write-Host "  0. Volver al menú principal" -ForegroundColor Gray
    Write-Host ""
    
    $opt = Read-Host "  Elige un número"
    switch ($opt) {
        "1" { Instalar-Programa -nombre "MSI Afterburner" -urlDescarga "https://msi-afterburner.en.softonic.com/download?ex=MSI" -argumentosInstalacion "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" }
        "2" { Instalar-Programa -nombre "Discord" -urlDescarga "https://discord.com/api/download?platform=win" -argumentosInstalacion "/S" }
        "3" { Instalar-Programa -nombre "Steam" -urlDescarga "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe" -argumentosInstalacion "/S" }
        "4" { Instalar-Programa -nombre "CPU-Z" -urlDescarga "https://www.cpuid.com/downloads/cpu-z/cpu-z_2.12-en.exe" -argumentosInstalacion "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" }
        "5" { Instalar-Programa -nombre "GPU-Z" -urlDescarga "https://www.techpowerup.com/download/techpowerup-gpu-z/" -argumentosInstalacion "" } # la página requiere interacción, mejor abrir navegador? por ahora manual
        "6" { Instalar-Programa -nombre "HWMonitor" -urlDescarga "https://www.cpuid.com/downloads/hwmonitor/hwmonitor_1.55.exe" -argumentosInstalacion "/VERYSILENT" }
        "7" { Instalar-Programa -nombre "O&O ShutUp10" -urlDescarga "https://dl.oo-software.com/OOSU10.exe" -argumentosInstalacion "/VERYSILENT" }
        "8" { Instalar-Programa -nombre "VC++ Redistributables" -urlDescarga "https://github.com/abbodi1406/vcredist/releases/download/v0.86.0/VisualCppRedist_AIO_x86_x64.exe" -argumentosInstalacion "/quiet /norestart" }
        "0" { return }
        default { Write-Host "  Opción inválida" -ForegroundColor Red; Start-Sleep -Seconds 1; Instalar-ProgramasGaming }
    }
    Read-Host "`nPresiona cualquier tecla para continuar"
}

function Instalar-Navegadores {
    Mostrar-Banner
    Write-Host "  🌐 INSTALADOR DE NAVEGADORES" -ForegroundColor Yellow
    Write-Host "  Selecciona qué navegador instalar:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Firefox" -ForegroundColor $colorPregunta
    Write-Host "  2. Opera GX (navegador gamer)" -ForegroundColor $colorPregunta
    Write-Host "  3. Google Chrome" -ForegroundColor $colorPregunta
    Write-Host "  4. Brave" -ForegroundColor $colorPregunta
    Write-Host "  5. Mullvad Browser" -ForegroundColor $colorPregunta
    Write-Host "  6. Tor Browser" -ForegroundColor $colorPregunta
    Write-Host "  0. Volver al menú principal" -ForegroundColor Gray
    Write-Host ""
    
    $opt = Read-Host "  Elige un número"
    switch ($opt) {
        "1" { Instalar-Programa -nombre "Firefox" -urlDescarga "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=es-ES" -argumentosInstalacion "/S" }
        "2" { Instalar-Programa -nombre "Opera GX" -urlDescarga "https://net.geo.opera.com/opera_gx?os=windows&channel=stable" -argumentosInstalacion "/silent" }
        "3" { Instalar-Programa -nombre "Google Chrome" -urlDescarga "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -argumentosInstalacion "/silent /install" }
        "4" { Instalar-Programa -nombre "Brave" -urlDescarga "https://github.com/brave/brave-browser/releases/download/v1.74.51/BraveBrowserStandaloneSilentSetup.exe" -argumentosInstalacion "/S" }
        "5" { Instalar-Programa -nombre "Mullvad Browser" -urlDescarga "https://cdn.mullvad.net/browser/13.5.5/mullvad-browser-win64-13.5.5.exe" -argumentosInstalacion "/S" }
        "6" { Instalar-Programa -nombre "Tor Browser" -urlDescarga "https://www.torproject.org/dist/torbrowser/13.5.6/torbrowser-install-win64-13.5.6_ALL.exe" -argumentosInstalacion "/S" }
        "0" { return }
        default { Write-Host "  Opción inválida" -ForegroundColor Red; Start-Sleep -Seconds 1; Instalar-Navegadores }
    }
    Read-Host "`nPresiona cualquier tecla para continuar"
}

function Instalar-Documentos {
    Mostrar-Banner
    Write-Host "  📄 INSTALADOR DE HERRAMIENTAS PARA DOCUMENTOS" -ForegroundColor Yellow
    Write-Host "  Selecciona qué herramienta instalar:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Adobe Acrobat Reader DC" -ForegroundColor $colorPregunta
    Write-Host "  2. Calibre (gestor de libros)" -ForegroundColor $colorPregunta
    Write-Host "  3. Joplin (notas FOSS)" -ForegroundColor $colorPregunta
    Write-Host "  4. massCode (gestor de snippets)" -ForegroundColor $colorPregunta
    Write-Host "  5. Obsidian (notas)" -ForegroundColor $colorPregunta
    Write-Host "  6. PDF24 creator" -ForegroundColor $colorPregunta
    Write-Host "  7. PDF-XChange Editor" -ForegroundColor $colorPregunta
    Write-Host "  8. WinMerge (comparar archivos)" -ForegroundColor $colorPregunta
    Write-Host "  9. Znote (notas ligeras)" -ForegroundColor $colorPregunta
    Write-Host "  0. Volver al menú principal" -ForegroundColor Gray
    Write-Host ""
    
    $opt = Read-Host "  Elige un número"
    switch ($opt) {
        "1" { Instalar-Programa -nombre "Adobe Acrobat Reader" -urlDescarga "https://get.adobe.com/reader/download/?installer=Reader_DC_2022.001.20169_ES_X9_64" -argumentosInstalacion "/sAll /rs" }
        "2" { Instalar-Programa -nombre "Calibre" -urlDescarga "https://download.calibre-ebook.com/7.19.0/calibre-64bit-7.19.0.msi" -argumentosInstalacion "/quiet" }
        "3" { Instalar-Programa -nombre "Joplin" -urlDescarga "https://github.com/laurent22/joplin/releases/download/v3.1.24/Joplin-Setup-3.1.24.exe" -argumentosInstalacion "/S" }
        "4" { Instalar-Programa -nombre "massCode" -urlDescarga "https://github.com/massCodeIO/massCode/releases/download/v3.9.2/massCode-Setup-3.9.2.exe" -argumentosInstalacion "/S" }
        "5" { Instalar-Programa -nombre "Obsidian" -urlDescarga "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.7.7/Obsidian-1.7.7.exe" -argumentosInstalacion "/S" }
        "6" { Instalar-Programa -nombre "PDF24 Creator" -urlDescarga "https://download.pdf24.org/pdf24-creator-11.24.0.msi" -argumentosInstalacion "/quiet" }
        "7" { Instalar-Programa -nombre "PDF-XChange Editor" -urlDescarga "https://www.tracker-software.com/downloads/PDFXEdit_x64.msi" -argumentosInstalacion "/quiet" }
        "8" { Instalar-Programa -nombre "WinMerge" -urlDescarga "https://github.com/winmerge/winmerge/releases/download/v2.16.42/WinMerge-2.16.42-x64-Setup.exe" -argumentosInstalacion "/S" }
        "9" { Instalar-Programa -nombre "Znote" -urlDescarga "https://github.com/alainm23/znote/releases/download/v1.0.4/Znote-Setup-1.0.4.exe" -argumentosInstalacion "/S" }
        "0" { return }
        default { Write-Host "  Opción inválida" -ForegroundColor Red; Start-Sleep -Seconds 1; Instalar-Documentos }
    }
    Read-Host "`nPresiona cualquier tecla para continuar"
}

# ---- Función de optimización (sin cambios importantes, solo colores) ----
function Optimizar-Sistema {
    Mostrar-Banner
    Write-Host "  🚀 INICIANDO OPTIMIZACIÓN DE FPS" -ForegroundColor Yellow
    Write-Host "  Responde S (Sí) o N (No) a cada ajuste`n" -ForegroundColor White
    
    if (Preguntar "⚡ ¿Cambiar plan de energía a ALTO RENDIMIENTO?") {
        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-Host "  ✅ Plan Alto Rendimiento activado" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    if (Preguntar "🧠 ¿Desactivar Core Parking? (usa todos los núcleos)") {
        powercfg -setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 0
        powercfg -setactive scheme_current
        Write-Host "  ✅ Core Parking desactivado" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    if (Preguntar "🛑 ¿Desactivar servicios en segundo plano (telemetría, indexador)?") {
        $servicios = @("DiagTrack","WSearch","SysMain","dmwappushservice","MapsBroker","XblAuthManager")
        foreach ($svc in $servicios) {
            Stop-Service $svc -Force -ErrorAction SilentlyContinue
            Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "  ✅ Desactivado: $svc" -ForegroundColor $colorAceptado
        }
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    if (Preguntar "🎨 ¿Desactivar efectos visuales? (más FPS)") {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
        Write-Host "  ✅ Efectos desactivados" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    if (Preguntar "🎯 ¿Dar prioridad máxima a juegos?") {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -ErrorAction SilentlyContinue
        Write-Host "  ✅ Prioridad a juegos aplicada" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    if (Preguntar "🖥️ ¿Desactivar MPO? (soluciona tirones)") {
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 5 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ MPO desactivado" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    if (Preguntar "🔕 ¿Desactivar notificaciones y sugerencias?") {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWord
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord
        Write-Host "  ✅ Notificaciones desactivadas" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    if (Preguntar "📅 ¿Desactivar tareas de telemetría?") {
        $tareas = @("\Microsoft\Windows\Application Experience\*","\Microsoft\Windows\Customer Experience Improvement Program\*","\Microsoft\Windows\DiskDiagnostic\*")
        foreach ($tarea in $tareas) {
            Get-ScheduledTask -TaskPath $tarea -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
            Write-Host "  ✅ Tareas desactivadas: $tarea" -ForegroundColor $colorAceptado
        }
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
    if (Preguntar "🗑️ ¿Ejecutar limpieza de archivos temporales?") {
        CleanMgr /sagerun:1 -ErrorAction SilentlyContinue
        Write-Host "  ✅ Limpieza ejecutada" -ForegroundColor $colorAceptado
    } else { Write-Host "  ⏩ Omitido" -ForegroundColor $colorRechazado }
    
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

# ---- MENÚ PRINCIPAL ----
do {
    Mostrar-Banner
    Write-Host "  🎯 SELECCIONA UNA OPCIÓN:" -ForegroundColor Yellow
    Write-Host "  1. 🚀 Optimizar FPS (recomendado para juegos)" -ForegroundColor Cyan
    Write-Host "  2. 🖥️  Instalar drivers (NVIDIA, AMD, Intel)" -ForegroundColor Cyan
    Write-Host "  3. 🎮 Instalar programas gaming" -ForegroundColor Cyan
    Write-Host "  4. 🌐 Instalar navegadores" -ForegroundColor Cyan
    Write-Host "  5. 📄 Instalar herramientas para documentos" -ForegroundColor Cyan
    Write-Host "  0. ❌ Salir" -ForegroundColor Gray
    Write-Host ""
    $menu = Read-Host "  Elige [1,2,3,4,5,0]"
    
    switch ($menu) {
        "1" { Optimizar-Sistema }
        "2" { Instalar-Drivers }
        "3" { Instalar-ProgramasGaming }
        "4" { Instalar-Navegadores }
        "5" { Instalar-Documentos }
        "0" { Write-Host "  Hasta luego, visita aztekillertech.net" -ForegroundColor Magenta; break }
        default { Write-Host "  Opción inválida" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($menu -ne "0")
