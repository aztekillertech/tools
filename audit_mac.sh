#!/bin/bash

DESKTOP="$HOME/Desktop"
LOG="$DESKTOP/Reporte_AztekIllerTech_Mac.txt"
OS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
ARCH=$(uname -m)

separador() {
    echo "  <<<<  AZTEKILLERTECH  >>>>"
}

titulo() {
    echo ""
    separador
    echo "  $1"
    separador
    echo "" >> "$LOG"
    echo "<<<< AZTEKILLERTECH >>>>" >> "$LOG"
    echo "  $1" >> "$LOG"
    echo "<<<< AZTEKILLERTECH >>>>" >> "$LOG"
}

log() {
    echo "$1"
    echo "$1" >> "$LOG"
}

banner() {
    echo ""
    separador
    echo "        AZTEKILLERTECH"
    echo "        Tu aliado de confianza en tecnologia"
    echo "        aztekillertech.net"
    separador
    echo ""
}

preguntar() {
    echo ""
    echo "  $1 (s/n)"
    read -r respuesta
    case "$respuesta" in
        [ssSyY]*) return 0 ;;
        *) return 1 ;;
    esac
}

clear
echo "REPORTE AZTEKILLERTECH MAC - $(date)" > "$LOG"
log "macOS: $(sw_vers -productName) $OS_VERSION | Arquitectura: $ARCH"

banner
echo "  AUDITORIA Y OPTIMIZACION PRO - MAC"
echo "  Responde s (si) o n (no) en cada opcion"
separador

# 1. AUDITORIA DE SEGURIDAD
if preguntar "Ejecutar auditoria de seguridad completa?"; then

    titulo "INFORMACION DEL SISTEMA"
    log "Modelo:      $(system_profiler SPHardwareDataType 2>/dev/null | grep 'Model Name' | awk -F': ' '{print $2}')"
    log "Chip:        $(system_profiler SPHardwareDataType 2>/dev/null | grep -E 'Chip|Processor Name' | head -1 | awk -F': ' '{print $2}')"
    log "RAM:         $(system_profiler SPHardwareDataType 2>/dev/null | grep 'Memory:' | awk -F': ' '{print $2}')"
    log "macOS:       $(sw_vers -productName) $(sw_vers -productVersion)"
    log "Equipo:      $(hostname)"
    log "Arquitectura: $ARCH"
    log "Uptime:      $(uptime | sed 's/.*up //' | sed 's/,.*//')"

    titulo "PUERTOS ABIERTOS"
    puertos_riesgo=(21 22 23 25 53 80 110 135 139 443 445 1433 3306 3389 4444 5900 6379 8080 27017)
    if [ "$OS_VERSION" -ge 12 ] 2>/dev/null; then
        netstat -anp tcp 2>/dev/null | grep LISTEN | while IFS= read -r linea; do
            puerto=$(echo "$linea" | awk '{print $4}' | grep -oE '[0-9]+$')
            alerta=""
            for pr in "${puertos_riesgo[@]}"; do
                if [ "$puerto" = "$pr" ]; then alerta="  <-- REVISAR"; fi
            done
            log "  Puerto $puerto$alerta"
        done
    else
        netstat -an 2>/dev/null | grep LISTEN | while IFS= read -r linea; do
            log "  $linea"
        done
    fi

    titulo "CONEXIONES ACTIVAS A INTERNET"
    netstat -anp tcp 2>/dev/null | grep ESTABLISHED | while IFS= read -r linea; do
        log "  $linea"
    done

    titulo "FIREWALL"
    if [ "$OS_VERSION" -ge 15 ] 2>/dev/null; then
        estado=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
    else
        estado=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
    fi
    if echo "$estado" | grep -q "enabled"; then
        log "Firewall: ACTIVO"
    else
        log "Firewall: DESACTIVADO <-- RIESGO"
    fi

    titulo "USUARIOS DEL SISTEMA"
    dscl . list /Users 2>/dev/null | grep -v '^_' | while read -r usuario; do
        ultimo=$(last "$usuario" 2>/dev/null | head -1 | awk '{print $4,$5,$6,$7}')
        if [ -z "$ultimo" ]; then ultimo="Nunca"; fi
        log "  $usuario | Ultimo login: $ultimo"
    done

    titulo "APPS EN ARRANQUE AUTOMATICO"
    encontrados=0
    for dir in "$HOME/Library/LaunchAgents" "/Library/LaunchAgents" "/Library/LaunchDaemons"; do
        if [ -d "$dir" ]; then
            while IFS= read -r archivo; do
                log "  $archivo"
                encontrados=$((encontrados + 1))
            done < <(ls "$dir" 2>/dev/null)
        fi
    done
    if [ "$encontrados" -eq 0 ]; then log "Sin apps en arranque automatico."; fi

    titulo "ACTUALIZACIONES PENDIENTES"
    log "Buscando actualizaciones..."
    softwareupdate -l 2>&1 | grep -E "\*|recommended|No new" | while IFS= read -r linea; do
        log "  $linea"
    done
fi

# 2. LIMPIAR TEMPORALES
if preguntar "Limpiar archivos temporales?"; then
    titulo "LIMPIEZA DE TEMPORALES"
    rutas=("$TMPDIR" "$HOME/Library/Caches")
    for ruta in "${rutas[@]}"; do
        if [ -d "$ruta" ]; then
            tam=$(du -sh "$ruta" 2>/dev/null | cut -f1)
            rm -rf "${ruta:?}/"* 2>/dev/null
            log "Limpiado: $ruta ($tam)"
        fi
    done
    log "Limpieza completada."
fi

# 3. ESPACIO EN DISCO
if preguntar "Ver espacio en disco?"; then
    titulo "ESPACIO EN DISCO"
    df -h 2>/dev/null | grep -E "^/dev|^map" | while IFS= read -r linea; do
        log "  $linea"
    done
fi

# 4. CAMARA Y MICROFONO
if preguntar "Ver apps con acceso a camara y microfono?"; then
    titulo "ACCESO A CAMARA Y MICROFONO"
    if [ "$OS_VERSION" -ge 14 ] 2>/dev/null; then
        log "  En macOS $OS_VERSION ve a:"
        log "  Apple > Configuracion del Sistema > Privacidad y Seguridad > Camara"
        log "  Apple > Configuracion del Sistema > Privacidad y Seguridad > Microfono"
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera" 2>/dev/null
    else
        log "  Apple > Preferencias del Sistema > Seguridad y Privacidad > Privacidad > Camara"
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera" 2>/dev/null
    fi
fi

# 5. TOP PROCESOS
if preguntar "Ver top procesos por CPU y RAM?"; then
    titulo "TOP 10 PROCESOS POR CPU"
    if [ "$ARCH" = "arm64" ]; then
        ps -eo pid,comm,%cpu,%mem --sort=-%cpu 2>/dev/null | head -11 | tail -10 | while IFS= read -r linea; do
            log "  $linea"
        done
    else
        ps aux 2>/dev/null | sort -rk3 | head -10 | while IFS= read -r linea; do
            log "  $linea"
        done
    fi

    titulo "TOP 10 PROCESOS POR RAM"
    if [ "$ARCH" = "arm64" ]; then
        ps -eo pid,comm,%cpu,%mem --sort=-%mem 2>/dev/null | head -11 | tail -10 | while IFS= read -r linea; do
            log "  $linea"
        done
    else
        ps aux 2>/dev/null | sort -rk4 | head -10 | while IFS= read -r linea; do
            log "  $linea"
        done
    fi
fi

# 6. ERRORES DEL SISTEMA
if preguntar "Ver errores recientes del sistema?"; then
    titulo "ERRORES RECIENTES (ultimas 24 horas)"
    if [ "$OS_VERSION" -ge 12 ] 2>/dev/null; then
        log show --predicate 'eventMessage contains "error"' --last 24h 2>/dev/null | grep -v "^Filtering" | head -15 | while IFS= read -r linea; do
            log "  $linea"
        done
    else
        log "  Sistema antiguo - revisa /var/log/system.log manualmente"
        tail -50 /var/log/system.log 2>/dev/null | grep -i error | head -10 | while IFS= read -r linea; do
            log "  $linea"
        done
    fi
fi

echo ""
banner
echo "  Gracias por usar AztekIllerTech"
echo "  Reporte guardado en: $LOG"
echo "  aztekillertech.net"
separador
echo ""
