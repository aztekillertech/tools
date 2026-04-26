<#
.SYNOPSIS
    Script definitivo de optimización gaming + instalador automático de drivers, programas y utilidades.
    Estilo AZTEKILLERTECH para Windows 10/11.
.NOTES
    Autor: AZTEKILLERTECH
    Web: https://aztekillertech.net
    Requiere: PowerShell como Administrador.
#>

# ==============================================
# VERIFICAR ADMINISTRADOR
# ==============================================
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ EJECUTA COMO ADMINISTRADOR (clic derecho > PowerShell como Admin)" -ForegroundColor Red
    pause; exit
}

# ==============================================
# CONFIGURACIÓN DE COLORES Y ESTILOS
# ==============================================
$colores = @{
    titulo   = "Magenta"
    borde    = "DarkMagenta"
    opcion   = "Cyan"
    pregunta = "Yellow"
    exito    = "Green"
    error    = "Red"
    info     = "Blue"
    advertencia = "DarkYellow"
    web      = "Yellow"
}

# Funciones de estilo
function Write-Border {
    Write-Host ("╔" + "═" * 78 + "╗") -ForegroundColor $colores.borde
}
function Write-Separator {
    Write-Host ("╠" + "═" * 78 + "╣") -ForegroundColor $colores.borde
}
function Write-Bottom {
    Write-Host ("╚" + "═" * 78 + "╝") -ForegroundColor $colores.borde
}
function Write-Centered {
    param([string]$texto, [string]$color = $colores.titulo)
    $espacios = [math]::Floor((78 - $texto.Length) / 2)
    Write-Host ("║" + " " * $espacios + $texto + " " * (78 - $espacios - $texto.Length) + "║") -ForegroundColor $color
}

function Mostrar-Banner {
    Clear-Host
    Write-Border
    Write-Centered "    █████╗ ███████╗████████╗███████╗ ██████╗██╗  ██╗" $colores.titulo
    Write-Centered "   ██╔══██╗╚══███╔╝╚══██╔══╝██╔════╝██╔════╝██║  ██║" $colores.titulo
    Write-Centered "   ███████║  ███╔╝    ██║   █████╗  ██║     ███████║" $colores.titulo
    Write-Centered "   ██╔══██║ ███╔╝     ██║   ██╔══╝  ██║     ██╔══██║" $colores.titulo
    Write-Centered "   ██║  ██║███████╗   ██║   ███████╗╚██████╗██║  ██║" $colores.titulo
    Write-Centered "   ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝" $colores.titulo
    Write-Separator
    Write-Centered "         GAMING OPTIMIZER + ULTIMATE UTILITIES" $colores.opcion
    Write-Centered "                 by AZTEKILLERTECH" $colores.info
    Write-Bottom
    Write-Host ""
    # Mostrar la web destacada
    Write-Host "  🌐 Visita mi sitio web: " -NoNewline -ForegroundColor $colores.web
    Write-Host "www.aztekillertech.net" -ForegroundColor $colores.web -BackgroundColor DarkBlue
    Write-Host "  (En tu navegador, abre esta dirección para más guías y herramientas)" -ForegroundColor $colores.advertencia
    Write-Host ""
}

# ==============================================
# FUNCIONES PRINCIPALES
# ==============================================
function Preguntar($mensaje) {
    Write-Host "  ⚡ $mensaje" -ForegroundColor $colores.pregunta
    $resp = Read-Host "  ¿Aplicar? (S/N)"
    return ($resp -eq 'S' -or $resp -eq 's')
}

function Instalar-Programa {
    param(
        [string]$nombre,
        [string]$urlDescarga,
        [string]$argumentosInstalacion = "",
        [string]$TipoInstalador = "exe",  # exe, msi, portable, web
        [bool]$esWeb = $false
    )
    
    Write-Host "`n  📦 Preparando instalación de: $nombre" -ForegroundColor $colores.info
    if (-not (Preguntar "  ¿Descargar e instalar $nombre?")) {
        Write-Host "  ⏩ Instalación cancelada" -ForegroundColor $colores.error
        return $false
    }
    
    if ($esWeb) {
        Write-Host "  🌐 Abriendo página web oficial para $nombre" -ForegroundColor $colores.advertencia
        Start-Process $urlDescarga
        return $true
    }
    
    $tempDir = "$env:TEMP\AztekillerInstaller"
    if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
    
    $extension = if ($urlDescarga -like "*.msi") { "msi" } elseif ($urlDescarga -like "*.exe") { "exe" } else { "installer" }
    $outputFile = Join-Path $tempDir "$($nombre -replace '[^a-zA-Z0-9]','')_installer.$extension"
    
    Write-Host "  ⬇️ Descargando..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $urlDescarga -OutFile $outputFile -UseBasicParsing -ErrorAction Stop
        if ((Get-Item $outputFile).Length -eq 0) { throw "Archivo descargado vacío." }
        Write-Host "  ✅ Descarga completada ($([math]::Round((Get-Item $outputFile).Length / 1MB, 2)) MB)" -ForegroundColor $colores.exito
    } catch {
        Write-Host "  ❌ Error de descarga: $_" -ForegroundColor $colores.error
        return $false
    }
    
    if ($TipoInstalador -eq "portable") {
        $installPath = "${env:ProgramFiles}\$nombre"
        if (-not (Test-Path $installPath)) { New-Item -ItemType Directory -Path $installPath -Force | Out-Null }
        Copy-Item $outputFile -Destination "$installPath\$nombre.exe" -Force
        Write-Host "  ✅ $nombre instalado como portable en $installPath" -ForegroundColor $colores.exito
        return $true
    }
    
    Write-Host "  🔧 Instalando..." -ForegroundColor Cyan
    try {
        if ($TipoInstalador -eq "msi") {
            $proceso = Start-Process "msiexec.exe" -ArgumentList "/i `"$outputFile`" $argumentosInstalacion /quiet /norestart" -Wait -PassThru -NoNewWindow
        } else {
            $proceso = Start-Process -FilePath $outputFile -ArgumentList $argumentosInstalacion -Wait -PassThru -NoNewWindow
        }
        
        if ($proceso.ExitCode -eq 0) {
            Write-Host "  ✅ Instalación completada con éxito" -ForegroundColor $colores.exito
        } else {
            Write-Host "  ⚠️ Instalador terminó con código $($proceso.ExitCode). Revisa manualmente." -ForegroundColor $colores.advertencia
        }
    } catch {
        Write-Host "  ❌ Error al ejecutar: $_" -ForegroundColor $colores.error
        return $false
    }
    return $true
}

# ==============================================
# MENÚ DE INSTALACIÓN POR CATEGORÍAS
# ==============================================

function Instalar-Drivers {
    Mostrar-Banner
    Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colores.borde
    Write-Host "  ║                    🖥️  INSTALADOR DE DRIVERS  🖥️                     ║" -ForegroundColor $colores.titulo
    Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colores.borde
    Write-Host ""
    $gpuReal = (Get-WmiObject Win32_VideoController | Where-Object {$_.Name -notlike "*Microsoft*" -and $_.Name -notlike "*Remote*" -and $_.Name -notlike "*AnyViewer*"} | Select-Object -First 1).Name
    if ($gpuReal) { Write-Host "  🎯 GPU detectada: $gpuReal" -ForegroundColor Cyan }
    Write-Host ""
    Write-Host "  1. NVIDIA Game Ready Driver" -ForegroundColor $colores.opcion
    Write-Host "  2. AMD Adrenalin Edition" -ForegroundColor $colores.opcion
    Write-Host "  3. Intel Driver & Support Assistant" -ForegroundColor $colores.opcion
    Write-Host "  0. Volver" -ForegroundColor Gray
    $opt = Read-Host "`n  Elige"
    switch ($opt) {
        "1" { Instalar-Programa -nombre "NVIDIA Driver" -urlDescarga "https://us.download.nvidia.com/Windows/572.83/572.83-desktop-win10-win11-64bit-international-dch-whql.exe" -argumentosInstalacion "/s" }
        "2" { Instalar-Programa -nombre "AMD Auto-Detect" -urlDescarga "https://drivers.amd.com/drivers/auto-detect-install.exe" -argumentosInstalacion "" }
        "3" { Instalar-Programa -nombre "Intel Driver Assistant" -urlDescarga "https://downloadmirror.intel.com/832159/Intel-Driver-Support-Assistant-Installer.exe" -argumentosInstalacion "/quiet" }
        "0" { return }
    }
    Read-Host "`nPresiona cualquier tecla"
}

function Instalar-ProgramasGaming {
    Mostrar-Banner
    Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colores.borde
    Write-Host "  ║                    🎮 PROGRAMAS GAMING  🎮                          ║" -ForegroundColor $colores.titulo
    Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colores.borde
    Write-Host ""
    $programas = @(
        @{Num=1; Nombre="MSI Afterburner"; URL="https://msi-afterburner.en.softonic.com/download?ex=MSI"; Args="/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"; Tipo="exe"},
        @{Num=2; Nombre="Discord"; URL="https://discord.com/api/download?platform=win"; Args="/S"; Tipo="exe"},
        @{Num=3; Nombre="Steam"; URL="https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"; Args="/S"; Tipo="exe"},
        @{Num=4; Nombre="CPU-Z"; URL="https://www.cpuid.com/downloads/cpu-z/cpu-z_2.12-en.exe"; Args="/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"; Tipo="exe"},
        @{Num=5; Nombre="GPU-Z"; URL="https://www.techpowerup.com/download/techpowerup-gpu-z/"; Args=""; Tipo="web"},
        @{Num=6; Nombre="HWMonitor"; URL="https://www.cpuid.com/downloads/hwmonitor/hwmonitor_1.55.exe"; Args="/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"; Tipo="exe"},
        @{Num=7; Nombre="O&O ShutUp10"; URL="https://dl.oo-software.com/OOSU10.exe"; Args="/VERYSILENT"; Tipo="exe"},
        @{Num=8; Nombre="Visual C++ AIO"; URL="https://github.com/abbodi1406/vcredist/releases/download/v0.86.0/VisualCppRedist_AIO_x86_x64.exe"; Args="/quiet /norestart"; Tipo="exe"}
    )
    foreach ($p in $programas) { Write-Host ("  {0}. {1}" -f $p.Num, $p.Nombre) -ForegroundColor $colores.opcion }
    Write-Host "  0. Volver" -ForegroundColor Gray
    $opt = Read-Host "`n  Elige"
    if ($opt -eq "0") { return }
    $sel = $programas | Where-Object { $_.Num -eq [int]$opt }
    if ($sel) {
        if ($sel.Tipo -eq "web") { Instalar-Programa -nombre $sel.Nombre -urlDescarga $sel.URL -esWeb $true }
        else { Instalar-Programa -nombre $sel.Nombre -urlDescarga $sel.URL -argumentosInstalacion $sel.Args -TipoInstalador $sel.Tipo }
    }
    Read-Host "`nPresiona cualquier tecla"
}

function Instalar-Navegadores {
    Mostrar-Banner
    Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colores.borde
    Write-Host "  ║                    🌐 NAVEGADORES  🌐                               ║" -ForegroundColor $colores.titulo
    Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colores.borde
    Write-Host ""
    $navegadores = @(
        @{Num=1; Nombre="Firefox"; URL="https://download.mozilla.org/?product=firefox-latest&os=win64&lang=es-ES"; Args="/S"; Tipo="exe"},
        @{Num=2; Nombre="Opera GX"; URL="https://net.geo.opera.com/opera_gx?os=windows&channel=stable"; Args="/silent"; Tipo="exe"},
        @{Num=3; Nombre="Google Chrome"; URL="https://dl.google.com/chrome/install/latest/chrome_installer.exe"; Args="/silent /install"; Tipo="exe"},
        @{Num=4; Nombre="Brave"; URL="https://github.com/brave/brave-browser/releases/download/v1.74.51/BraveBrowserStandaloneSilentSetup.exe"; Args="/S"; Tipo="exe"},
        @{Num=5; Nombre="Mullvad Browser"; URL="https://cdn.mullvad.net/browser/13.5.5/mullvad-browser-win64-13.5.5.exe"; Args="/S"; Tipo="exe"},
        @{Num=6; Nombre="Tor Browser"; URL="https://www.torproject.org/dist/torbrowser/13.5.6/torbrowser-install-win64-13.5.6_ALL.exe"; Args="/S"; Tipo="exe"}
    )
    foreach ($n in $navegadores) { Write-Host ("  {0}. {1}" -f $n.Num, $n.Nombre) -ForegroundColor $colores.opcion }
    Write-Host "  0. Volver" -ForegroundColor Gray
    $opt = Read-Host "`n  Elige"
    if ($opt -eq "0") { return }
    $sel = $navegadores | Where-Object { $_.Num -eq [int]$opt }
    if ($sel) { Instalar-Programa -nombre $sel.Nombre -urlDescarga $sel.URL -argumentosInstalacion $sel.Args -TipoInstalador $sel.Tipo }
    Read-Host "`nPresiona cualquier tecla"
}

function Instalar-Documentos {
    Mostrar-Banner
    Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colores.borde
    Write-Host "  ║                    📄 HERRAMIENTAS PARA DOCUMENTOS  📄              ║" -ForegroundColor $colores.titulo
    Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colores.borde
    Write-Host ""
    $docs = @(
        @{Num=1; Nombre="Adobe Acrobat Reader DC"; URL="https://get.adobe.com/reader/download/?installer=Reader_DC_2022.001.20169_ES_X9_64"; Args="/sAll /rs"; Tipo="exe"},
        @{Num=2; Nombre="Calibre"; URL="https://download.calibre-ebook.com/7.29.0/calibre-64bit-7.29.0.msi"; Args=""; Tipo="msi"},
        @{Num=3; Nombre="Joplin"; URL="https://github.com/laurent22/joplin/releases/download/v3.1.24/Joplin-Setup-3.1.24.exe"; Args="/S"; Tipo="exe"},
        @{Num=4; Nombre="Obsidian"; URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.7.7/Obsidian-1.7.7.exe"; Args="/S"; Tipo="exe"},
        @{Num=5; Nombre="PDF24 Creator"; URL="https://download.pdf24.org/pdf24-creator-11.24.0.msi"; Args=""; Tipo="msi"},
        @{Num=6; Nombre="PDF-XChange Editor"; URL="https://www.tracker-software.com/downloads/PDFXEdit_x64.msi"; Args=""; Tipo="msi"},
        @{Num=7; Nombre="WinMerge"; URL="https://github.com/winmerge/winmerge/releases/download/v2.16.42/WinMerge-2.16.42-x64-Setup.exe"; Args="/S"; Tipo="exe"},
        @{Num=8; Nombre="WinRAR"; URL="https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-623.exe"; Args="/S"; Tipo="exe"}
    )
    foreach ($d in $docs) { Write-Host ("  {0}. {1}" -f $d.Num, $d.Nombre) -ForegroundColor $colores.opcion }
    Write-Host "  0. Volver" -ForegroundColor Gray
    $opt = Read-Host "`n  Elige"
    if ($opt -eq "0") { return }
    $sel = $docs | Where-Object { $_.Num -eq [int]$opt }
    if ($sel) { Instalar-Programa -nombre $sel.Nombre -urlDescarga $sel.URL -argumentosInstalacion $sel.Args -TipoInstalador $sel.Tipo }
    Read-Host "`nPresiona cualquier tecla"
}

function Instalar-Utilidades {
    Mostrar-Banner
    Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colores.borde
    Write-Host "  ║                    🛠️  UTILIDADES AVANZADAS  🛠️                      ║" -ForegroundColor $colores.titulo
    Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colores.borde
    Write-Host ""
    Write-Host "  Selecciona la utilidad a instalar (descarga automática):`n" -ForegroundColor Cyan
    
    $utilidades = @(
        @{Num=1;  Nombre="Everything Search"; URL="https://www.voidtools.com/Everything-1.4.1.1026.x64.zip"; Args=""; Tipo="portable"},
        @{Num=2;  Nombre="Rufus (USB Boot)"; URL="https://github.com/pbatard/rufus/releases/download/v4.6/rufus-4.6.exe"; Args=""; Tipo="portable"},
        @{Num=3;  Nombre="Display Driver Uninstaller (DDU)"; URL="https://www.wagnardsoft.com/DDU/download"; Args=""; Tipo="web"},
        @{Num=4;  Nombre="Bulk Crap Uninstaller"; URL="https://github.com/Klocman/Bulk-Crap-Uninstaller/releases/download/v5.8/BCUninstaller_5.8_portable.zip"; Args=""; Tipo="portable"},
        @{Num=5;  Nombre="CrystalDiskInfo"; URL="https://sourceforge.net/projects/crystaldiskinfo/files/9.3.2/CrystalDiskInfo9_3_2.exe/download"; Args="/VERYSILENT"; Tipo="exe"},
        @{Num=6;  Nombre="HWInfo"; URL="https://www.hwinfo.com/files/hwinfo640_install.exe"; Args="/VERYSILENT"; Tipo="exe"},
        @{Num=7;  Nombre="FanControl"; URL="https://github.com/Rem0o/FanControl.Releases/releases/download/V210/FanControl.zip"; Args=""; Tipo="portable"},
        @{Num=8;  Nombre="OpenRGB"; URL="https://openrgb.org/releases/OpenRGB_0.9_Windows_64_b5f46e3.zip"; Args=""; Tipo="portable"},
        @{Num=9;  Nombre="WizTree (espacio en disco)"; URL="https://diskanalyzer.com/files/wiztree_4_21_portable.zip"; Args=""; Tipo="portable"},
        @{Num=10; Nombre="SpaceSniffer"; URL="http://www.uderzo.it/downloads/SpaceSniffer_1.3.0.2_portable.zip"; Args=""; Tipo="portable"},
        @{Num=11; Nombre="LockHunter"; URL="https://lockhunter.com/downloads/LockHunter%20x64%20Setup.exe"; Args="/VERYSILENT"; Tipo="exe"},
        @{Num=12; Nombre="Malwarebytes Free"; URL="https://data-cdn.mbamupdates.com/v1/mbam-setup-consumer/MBSetup.exe"; Args="/VERYSILENT"; Tipo="exe"},
        @{Num=13; Nombre="KeePassXC"; URL="https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.msi"; Args=""; Tipo="msi"},
        @{Num=14; Nombre="AutoHotkey"; URL="https://www.autohotkey.com/download/ahk-v2.exe"; Args="/S"; Tipo="exe"},
        @{Num=15; Nombre="qBittorrent"; URL="https://sourceforge.net/projects/qbittorrent/files/qbittorrent-win64/qbittorrent-4.6.7/qbittorrent_4.6.7_x64_setup.exe/download"; Args="/S"; Tipo="exe"},
        @{Num=16; Nombre="Syncthing (sincronización)"; URL="https://github.com/syncthing/syncthing/releases/download/v1.27.12/syncthing-windows-amd64-v1.27.12.zip"; Args=""; Tipo="portable"},
        @{Num=17; Nombre="Parsec (streaming gaming)"; URL="https://builds.parsecgaming.com/package/parsec-windows.exe"; Args="/S"; Tipo="exe"},
        @{Num=18; Nombre="Process Lasso"; URL="https://bitsum.com/files/processlassosetup64.exe"; Args="/VERYSILENT"; Tipo="exe"},
        @{Num=19; Nombre="TranslucentTB"; URL="https://github.com/TranslucentTB/TranslucentTB/releases/download/2024.1/TranslucentTB.x64.zip"; Args=""; Tipo="portable"},
        @{Num=20; Nombre="Windhawk (mods Windows)"; URL="https://github.com/ramensoftware/windhawk/releases/download/v2.3.1/windhawk_setup.exe"; Args="/S"; Tipo="exe"}
    )
    
    foreach ($u in $utilidades) { Write-Host ("  {0,2}. {1}" -f $u.Num, $u.Nombre) -ForegroundColor $colores.opcion }
    Write-Host "  0. Volver" -ForegroundColor Gray
    $opt = Read-Host "`n  Elige"
    if ($opt -eq "0") { return }
    $sel = $utilidades | Where-Object { $_.Num -eq [int]$opt }
    if ($sel) {
        if ($sel.Tipo -eq "web") { Instalar-Programa -nombre $sel.Nombre -urlDescarga $sel.URL -esWeb $true }
        else { Instalar-Programa -nombre $sel.Nombre -urlDescarga $sel.URL -argumentosInstalacion $sel.Args -TipoInstalador $sel.Tipo }
    }
    Read-Host "`nPresiona cualquier tecla"
}

function Optimizar-Sistema {
    Mostrar-Banner
    Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colores.borde
    Write-Host "  ║                    🚀 OPTIMIZACIÓN DE RENDIMIENTO 🚀                 ║" -ForegroundColor $colores.titulo
    Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colores.borde
    Write-Host ""
    Write-Host "  Responde S (Sí) o N (No) a cada ajuste:`n" -ForegroundColor Cyan
    
    if (Preguntar "⚡ ¿Plan de energía ALTO RENDIMIENTO?") { powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null; Write-Host "  ✅ Aplicado" -ForegroundColor Green } else { Write-Host "  ⏩ Omitido" }
    if (Preguntar "🧠 ¿Desactivar Core Parking?") { powercfg -setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 0; powercfg -setactive scheme_current; Write-Host "  ✅ Aplicado" } else { Write-Host "  ⏩ Omitido" }
    if (Preguntar "🛑 ¿Desactivar servicios molestos?") { @("DiagTrack","WSearch","SysMain","dmwappushservice","MapsBroker","XblAuthManager") | ForEach-Object { Stop-Service $_ -Force -EA 0; Set-Service $_ -StartupType Disabled -EA 0; Write-Host "  ✅ $_" -ForegroundColor Green } } else { Write-Host "  ⏩ Omitido" }
    if (Preguntar "🎨 ¿Desactivar efectos visuales?") { Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -EA 0; Write-Host "  ✅ Aplicado" } else { Write-Host "  ⏩ Omitido" }
    if (Preguntar "🎯 ¿Prioridad máxima a juegos?") { Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -EA 0; Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -EA 0; Write-Host "  ✅ Aplicado" } else { Write-Host "  ⏩ Omitido" }
    if (Preguntar("🖥️ ¿Desactivar MPO (tirones GPU)?")) { New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 5 -Type DWord -Force -EA 0; Write-Host "  ✅ Aplicado" } else { Write-Host "  ⏩ Omitido" }
    if (Preguntar("🔕 ¿Desactivar notificaciones?")) { New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force | Out-Null; @("SubscribedContent-338387Enabled","SilentInstalledAppsEnabled") | ForEach-Object { Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name $_ -Value 0 -EA 0 }; Write-Host "  ✅ Aplicado" } else { Write-Host "  ⏩ Omitido" }
    if (Preguntar("📅 ¿Desactivar telemetría programada?")) { @("\Microsoft\Windows\Application Experience\*","\Microsoft\Windows\Customer Experience Improvement Program\*","\Microsoft\Windows\DiskDiagnostic\*") | ForEach-Object { Get-ScheduledTask -TaskPath $_ -EA 0 | Disable-ScheduledTask -EA 0 }; Write-Host "  ✅ Aplicado" } else { Write-Host "  ⏩ Omitido" }
    if (Preguntar("🗑️ ¿Limpiar temporales?")) { CleanMgr /sagerun:1 -EA 0; Write-Host "  ✅ Ejecutado" } else { Write-Host "  ⏩ Omitido" }
    
    $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    if ($ramGB -ge 16) { if (Preguntar("💾 ¿Desactivar Pagefile? (solo 32GB+ RAM)")) { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Value "" -EA 0; Write-Host "  ✅ Aplicado" } else { Write-Host "  ⏩ Omitido" } }
    
    Write-Host "`n  ✅ Optimización completada. REINICIA para aplicar cambios." -ForegroundColor Green
    pause
}

# ==============================================
# MENÚ PRINCIPAL
# ==============================================
do {
    Mostrar-Banner
    Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $colores.borde
    Write-Host "  ║                          🎯 MENÚ PRINCIPAL 🎯                       ║" -ForegroundColor $colores.titulo
    Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $colores.borde
    Write-Host ""
    Write-Host "  ║  1. 🚀 Optimizar FPS (recomendado)" -ForegroundColor $colores.opcion
    Write-Host "  ║  2. 🖥️  Instalar Drivers (GPU/CPU)" -ForegroundColor $colores.opcion
    Write-Host "  ║  3. 🎮 Instalar Programas Gaming" -ForegroundColor $colores.opcion
    Write-Host "  ║  4. 🌐 Instalar Navegadores" -ForegroundColor $colores.opcion
    Write-Host "  ║  5. 📄 Instalar Herramientas Documentos" -ForegroundColor $colores.opcion
    Write-Host "  ║  6. 🛠️  Instalar Utilidades Avanzadas" -ForegroundColor $colores.opcion
    Write-Host "  ║  0. ❌ Salir" -ForegroundColor Gray
    Write-Host ""
    $menu = Read-Host "  Elige [1-6,0]"
    
    switch ($menu) {
        "1" { Optimizar-Sistema }
        "2" { Instalar-Drivers }
        "3" { Instalar-ProgramasGaming }
        "4" { Instalar-Navegadores }
        "5" { Instalar-Documentos }
        "6" { Instalar-Utilidades }
        "0" { Write-Host "  Hasta luego, visita www.aztekillertech.net" -ForegroundColor Magenta; break }
        default { Write-Host "  Opción inválida" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($menu -ne "0")
