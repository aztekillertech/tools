$LOG = "$HOME\Desktop\Reporte_Auditoria.txt"
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

$pr = @(21,22,23,25,53,80,110,135,139,443,445,1433,3306,3389,4444,5900,6379,8080,27017)
$pa = @("nc","ncat","wscript","cscript","mshta","regsvr32","rundll32")

"AUDITORIA AZTEKILLERTECH - $(Get-Date)" | Out-File $LOG -Encoding UTF8

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

Titulo "STARTUP" "Cyan"
$n = 0
Get-CimInstance Win32_StartupCommand | ForEach-Object {
    $r = $_.Command.ToLower()
    if ($r -like "*appdata\roaming*" -or $r -like "*c:\temp*" -or $r -like "*windows\temp*") {
        Log "[ALERTA] $($_.Command)" "Red"
        $n++
    }
}
if ($n -eq 0) { Log "Sin entradas sospechosas." "Green" }

Titulo "ACTUALIZACIONES PENDIENTES" "Cyan"
try {
    $updates = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0").Updates
    if ($updates.Count -eq 0) { Log "Sin actualizaciones pendientes." "Green" }
    else { $updates | ForEach-Object { Log "  - $($_.Title)" "Yellow" } }
} catch { Log "No se pudo verificar." "DarkGray" }

Titulo "TOP 5 PROCESOS POR CPU" "Cyan"
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | ForEach-Object {
    Log "$($_.Name) | CPU: $([math]::Round($_.CPU,1))s | RAM: $([math]::Round($_.WorkingSet64/1MB,1)) MB" "Gray"
}

Write-Host "`nReporte guardado en: $LOG" -ForegroundColor Green
