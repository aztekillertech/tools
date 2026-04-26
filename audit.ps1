$LOG = "$HOME\Desktop\Reporte_AztekIllerTech.txt"
$linea = "=" * 60

function Titulo($t, $c) {
    Write-Host "`n$linea" -ForegroundColor $c
    Write-Host "  $t" -ForegroundColor $c
    Write-Host "$linea" -ForegroundColor $c
    Add-Content $LOG "`n$linea`n  $t`n$linea"
}

function Log($m, $c) {
    Write-Host $m -ForegroundColor $c
    Add-Content $LOG $m
}

function Banner($color) {
    Write-Host ""
    Write-Host "    _       ____  ____  ____  _  __ ___  __    __    ____  ____  ____  ____  ____  _  _ " -ForegroundColor $color
    Write-Host "   /_\     (__  )(_  _)(  __)( )/ // __)(  )  (  )  (  __)(  _ \(_  _)(  __)/ ___)/ )( \" -ForegroundColor $color
    Write-Host "  //_\\     / _/   )(   ) _)  )  (( (__  )(__ )(     ) _)  )   /  )(   ) _)( (__ ) __ (" -ForegroundColor $color
    Write-Host " /     \  (____)  (__) (____)(__)(_)\___)(____)(____)(____)(__)__)(__) (____)\___)\)(_)/" -ForegroundColor $color
    Write-Host ""
    Write-Host "                    Tu aliado de confianza en tecnologia" -ForegroundColor DarkGray
    Write-Host "                         aztekillertech.net" -ForegroundColor DarkGray
    Write-Host ""
}

function Preguntar($pregunta) {
    $opciones = @("YES", "NO")
    $seleccion = 0
    while ($true) {
        Write-Host "`n  $pregunta" -ForegroundColor Yellow
        for ($i = 0; $i -lt $opciones.Count; $i++) {
            if ($i -eq $seleccion) {
                Write-Host "  >> $($opciones[$i]) <<" -ForegroundColor Green
            } else {
                Write-Host "     $($opciones[$i])" -ForegroundColor Gray
            }
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.VirtualKeyCode -eq 38) { $seleccion = 0 }
        if ($key.VirtualKeyCode -eq 40) { $seleccion = 1 }
        if ($key.VirtualKeyCode -eq 13) { return $opciones[$seleccion] -eq "YES" }
    }
}

Clear-Host
"REPORTE AZTEKILLERTECH - $(Get-Date)" | Out-File $LOG -Encoding UTF8

Banner "Magenta"

Write-Host $linea -ForegroundColor Magenta
Write-Host "  AUDITORIA Y OPTIMIZACION PRO" -ForegroundColor Magenta
Write-Host "  Usa flechas ARRIBA/ABAJO y ENTER para elegir" -ForegroundColor DarkGray
Write-Host $linea -ForegroundColor Magenta

if (Preguntar "Ejecutar auditoria de seguridad completa?") {
    $pr = @(21,22,23,25,53,80,110,135,139,443,445,1433,3306,3389,4444,5900,6379,8080,27017)
    $pa = @("nc","ncat","wscript","cscript","mshta","regsvr32","rundll32")

    Titulo "PUERTOS ABIERTOS" "Cyan"
    Get-NetTCPConnection -State Listen | Sort-Object LocalPort | ForEach-Object {
        $proc = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name
        $alerta = ""
        $color = "Gray"
        if ($pr -contains $_.LocalPort) { $alerta = " <-- REVISAR"; $color = "Yellow" }
        Log "Puerto $($_.LocalPort) | $proc$alerta" $color
    }

    Titulo "CONEXIONES A INTERNET" "Cyan"
    $cx = Get-NetTCPConnection -State Established | Where-Object { $_.RemoteAddress -notmatch "^(127\.|::1|0\.0\.0\.0)" }
    if ($cx) {
        $cx | ForEach-Object {
            $proc = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name
            $alerta = ""
            $color = "White"
            if ($pa -contains $proc) { $alerta = " <-- ALERTA CRITICA"; $color = "Red" }
            Log "$proc | $($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort)$alerta" $color
        }
    } else { Log "Sin conexiones activas." "Gray" }

    Titulo "FIREWALL" "Cyan"
    Get-NetFirewallProfile | ForEach-Object {
        $estado = "ACTIVO"
        $color = "Green"
        if (-not $_.Enabled) { $estado = "DESACTIVADO <-- RIESGO"; $color = "Red" }
        Log "Perfil: $($_.Name) | $estado" $color
    }

    Titulo "USUARIOS LOCALES" "Cyan"
    Get-LocalUser | ForEach-Object {
        $estado = "deshabilitado"
        $color = "DarkGray"
        $login = "Nunca"
        if ($_.Enabled) { $estado = "ACTIVO"; $color = "White" }
        if ($_.LastLogon) { $login = $_.LastLogon }
        Log "$($_.Name) | $estado | Ultimo login: $login" $color
    }

    Titulo "ACTUALIZACIONES PENDIENTES" "Cyan"
    try {
        $updates = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0").Updates
        if ($updates.Count -eq 0) { Log "Sin actualizaciones pendientes." "Green" }
        else { $updates | ForEach-Object { Log "  - $($_.Title)" "Yellow" } }
    } catch { Log "No se pudo verificar." "DarkGray" }

    Titulo "STARTUP SOSPECHOSO" "Cyan"
    $n = 0
    Get-CimInstance Win32_StartupCommand | ForEach-Object {
        $r = $_.Command.ToLower()
        if ($r -like "*appdata\roaming*" -or $r -like "*c:\temp*" -or $r -like "*windows\temp*") {
            Log "[ALERTA] $($_.Command)" "Red"
            $n++
        }
    }
    if ($n -eq 0) { Log "Sin entradas sospechosas." "Green" }
}

if (Preguntar "Limpiar archivos temporales del sistema?") {
    Titulo "LIMPIEZA DE TEMPORALES" "Cyan"
    $rutas = @("$env:TEMP", "C:\Windows\Temp", "$env:LOCALAPPDATA\Temp")
    $totalBytes = 0
    foreach ($ruta in $rutas) {
        if (Test-Path $ruta) {
            $archivos = Get-ChildItem $ruta -Recurse -ErrorAction SilentlyContinue
            $bytes = ($archivos | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            if (-not $bytes) { $bytes = 0 }
            $totalBytes += $bytes
            Remove-Item "$ruta\*" -Recurse -Force -ErrorAction SilentlyContinue
            Log "Limpiado: $ruta ($([math]::Round($bytes/1MB,1)) MB)" "Green"
        }
    }
    Log "Total liberado: $([math]::Round($totalBytes/1MB,1)) MB" "Green"
}

if (Preguntar "Vaciar cache DNS?") {
    Titulo "CACHE DNS" "Cyan"
    Clear-DnsClientCache
    Log "Cache DNS vaciado correctamente." "Green"
}

if (Preguntar "Ver programas innecesarios en el inicio de Windows?") {
    Titulo "PROGRAMAS EN STARTUP" "Cyan"
    $innecesarios = @("Spotify","Discord","Steam","OneDrive","Skype","Teams","Zoom","EpicGamesLauncher","Canva","Medal")
    $startupItems = Get-CimInstance Win32_StartupCommand
    $encontrados = 0
    foreach ($item in $startupItems) {
        foreach ($prog in $innecesarios) {
            if ($item.Name -like "*$prog*" -or $item.Command -like "*$prog*") {
                Log "Detectado en startup: $($item.Name)" "Yellow"
                $encontrados++
            }
        }
    }
    if ($encontrados -eq 0) { Log "No se encontraron programas innecesarios." "Green" }
    else { Log "Tip: Deshabilitatlos en Administrador de Tareas > Inicio." "DarkGray" }
}

if (Preguntar "Ver espacio en disco?") {
    Titulo "ESPACIO EN DISCO" "Cyan"
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $total = [math]::Round($_.Used/1GB + $_.Free/1GB, 1)
        $usado = [math]::Round($_.Used/1GB, 1)
        $libre = [math]::Round($_.Free/1GB, 1)
        $pct = if (($_.Used + $_.Free) -gt 0) { [math]::Round(($_.Used / ($_.Used + $_.Free)) * 100) } else { 0 }
        $color = "Green"
        if ($pct -gt 80) { $color = "Yellow" }
        if ($pct -gt 90) { $color = "Red" }
        Log "Disco $($_.Name): $usado GB usados / $total GB total | $libre GB libres | $pct% usado" $color
    }
}

if (Preguntar "Ver apps con acceso a camara y microfono?") {
    Titulo "ACCESO A CAMARA Y MICROFONO" "Cyan"
    $regPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"
    )
    foreach ($path in $regPaths) {
        $tipo = if ($path -like "*webcam*") { "CAMARA" } else { "MICROFONO" }
        Write-Host "`n  $tipo" -ForegroundColor Yellow
        Add-Content $LOG "`n  $tipo"
        if (Test-Path $path) {
            Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object {
                $val = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).Value
                $color = "Gray"
                if ($val -eq "Allow") { $color = "Yellow" }
                Log "  $($_.PSChildName) | $val" $color
            }
        }
    }
}

if (Preguntar "Verificar telemetria activa de Windows?") {
    Titulo "TELEMETRIA DE WINDOWS" "Cyan"
    $serviciosTelemetria = @("DiagTrack","dmwappushservice","WerSvc","PcaSvc")
    foreach ($svc in $serviciosTelemetria) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            $color = "Gray"
            if ($s.Status -eq "Running") { $color = "Yellow" }
            Log "Servicio: $svc | Estado: $($s.Status)" $color
        }
    }
}

if (Preguntar "Buscar drivers con problemas?") {
    Titulo "DRIVERS CON PROBLEMAS" "Cyan"
    $drivers = Get-WmiObject Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
    if ($drivers) {
        $drivers | ForEach-Object { Log "[PROBLEMA] $($_.Name) - Codigo error: $($_.ConfigManagerErrorCode)" "Red" }
    } else { Log "No se encontraron drivers con problemas." "Green" }
}

if (Preguntar "Ver top procesos por CPU y RAM?") {
    Titulo "TOP 10 PROCESOS POR CPU" "Cyan"
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | ForEach-Object {
        $color = "Gray"
        if ($_.CPU -gt 500) { $color = "Yellow" }
        if ($_.CPU -gt 1000) { $color = "Red" }
        Log "$($_.Name) | CPU: $([math]::Round($_.CPU,1))s | RAM: $([math]::Round($_.WorkingSet64/1MB,1)) MB" $color
    }
    Titulo "TOP 5 PROCESOS POR RAM" "Cyan"
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 | ForEach-Object {
        Log "$($_.Name) | RAM: $([math]::Round($_.WorkingSet64/1MB,1)) MB" "Gray"
    }
}

if (Preguntar "Ver errores recientes del sistema?") {
    Titulo "ERRORES RECIENTES (ultimas 24 horas)" "Cyan"
    $desde = (Get-Date).AddHours(-24)
    $errores = Get-EventLog -LogName System -EntryType Error -After $desde -ErrorAction SilentlyContinue | Select-Object -First 10
    if ($errores) {
        $errores | ForEach-Object { Log "$($_.TimeGenerated) | $($_.Source) | $($_.Message.Split("`n")[0])" "Red" }
    } else { Log "Sin errores criticos en las ultimas 24 horas." "Green" }
}

Write-Host ""
Write-Host $linea -ForegroundColor Magenta
Banner "Magenta"
Write-Host "  Gracias por usar AztekIllerTech" -ForegroundColor Magenta
Write-Host "  Reporte guardado en: $LOG" -ForegroundColor Yellow
Write-Host "  aztekillertech.net" -ForegroundColor DarkGray
Write-Host $linea -ForegroundColor Magenta
Write-Host ""
