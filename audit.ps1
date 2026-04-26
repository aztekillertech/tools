$LOG = "$HOME\Desktop\Reporte_Auditoria.txt"
$linea = "=" * 60

function Titulo($texto, $color = "Cyan") {
    Write-Host "`n$linea" -ForegroundColor $color
    Write-Host "  $texto" -ForegroundColor $color
    Write-Host "$linea" -ForegroundColor $color
    Add-Content $LOG "`n$linea`n  $texto`n$linea"
}

function Log($msg, $color = "White") {
    Write-Host $msg -ForegroundColor $color
    Add-Content $LOG $msg
}

$puertosRiesgo  = @(21,22,23,25,53,80,110,135,139,443,445,1433,3306,3389,4444,5900,6379,8080,27017)
$procesosAlerta = @("nc","ncat","wscript","cscript","mshta","regsvr32","rundll32")
$rutasSosp      = @("appdata\roaming","c:\temp","windows\temp","programdata")

"AUDITORIA AZTEKILLERTECH - $(Get-Date)" | Out-File $LOG -Encoding UTF8

Titulo "PUERTOS ABIERTOS"
Get-NetTCPConnection -State Listen | Sort-Object LocalPort | ForEach-Object {
    $proc   = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name
    $alerta = if ($puertosRiesgo -contains $_.LocalPort) { " <-- REVISAR" } else { "" }
    $msg    = "Puerto $($_.LocalPort) | $proc$alerta"
    Log $msg (if ($alerta) { "Yellow" } else { "Gray" })
}

Titulo "CONEXIONES A INTERNET"
$conex = Get-NetTCPConnection -State Established | Where-Object {
    $_.RemoteAddress -notmatch "^(127\.|::1|0\.0\.0\.0)"
}
if ($conex) {
    $conex | ForEach-Object {
        $proc   = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name
        $alerta = if ($procesosAlerta -contains $proc) { " <-- ALERTA CRITICA" } else { "" }
        $msg    = "$proc | $($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort)$alerta"
        Log $msg (if ($alerta) { "Red" } else { "White" })
    }
} else { Log "Sin conexiones activas." "Gray" }

Titulo "FIREWALL"
Get-NetFirewallProfile | ForEach-Object {
    $msg = "Perfil: $($_.Name) | $(if ($_.Enabled) { 'ACTIVO' } else { 'DESACTIVADO <-- RIESGO' })"
    Log $msg (if ($_.Enabled) { "Green" } else { "Red" })
}

Titulo "USUARIOS LOCALES"
Get-LocalUser | ForEach-Object {
    $msg = "$($_.Name) | $(if ($_.Enabled) { 'ACTIVO' } else { 'deshabilitado' }) | Ultimo login: $(if ($_.LastLogon) { $_.LastLogon } else { 'Nunca' })"
    Log $msg (if ($_.Enabled) { "White" } else { "DarkGray" })
}

Titulo "STARTUP"
$sosp = 0
Get-CimInstance Win32_StartupCommand | ForEach-Object {
    $ruta = $_.Command.ToLower()
    if ($rutasSosp | Where-Object { $ruta -like "*$_*" }) {
        Log "[ALERTA] Ruta sospechosa: $($_.Command)" "Red"
        $sosp++
    }
}
if ($sosp -eq 0) { Log "Sin entradas sospechosas." "Green" }

Titulo "ACTUALIZACIONES PENDIENTES"
try {
    $updates = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0").Updates
    if ($updates.Count -eq 0) { Log "Sin actualizaciones pendientes." "Green" }
    else { $updates | ForEach-Object { Log "  - $($_.Title)" "Yellow" } }
} catch { Log "No se pudo verificar." "DarkGray" }

Titulo "TOP 5 PROCESOS POR CPU"
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | ForEach-Object {
    Log "$($_.Name) | CPU: $([math]::Round($_.CPU,1))s | RAM: $([math]::Round($_.WorkingSet64/1MB,1)) MB" "Gray"
}

Write-Host "`nReporte guardado en: $LOG" -ForegroundColor Green
