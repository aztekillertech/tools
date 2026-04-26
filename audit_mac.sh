#!/bin/bash

DESKTOP="$HOME/Desktop"
LOG="$DESKTOP/Reporte_AztekIllerTech.txt"

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
    echo "  $1"
    opciones=("YES" "NO")
    seleccion=0
    while true; do
        for i in 0 1; do
            if [ $i -eq $seleccion ]; then
                echo "  >> ${opciones[$i]} <<"
            else
                echo "     ${opciones[$i]}"
            fi
        done
        read -rsn1 key
        case "$key" in
            A) seleccion=0 ;;
            B) seleccion=1 ;;
            "") 
                if [ $seleccion -eq 0 ]; then return 0
                else return 1
                fi ;;
        esac
        echo -e "\033[3A"
    done
}

clear
echo "REPORTE AZTEKILLERTECH - $(date)" > "$LOG"

banner
echo "  AUDITORIA Y OPTIMIZACION PRO - MAC"
echo "  Usa flechas ARRIBA/ABAJO y ENTER para elegir"
separador

# 1. AUDITORIA DE SEGURIDAD
if preguntar "Ejecutar auditoria de seguridad completa?"; then

    titulo "PUERTOS ABIERTOS"
    puertos_riesgo=(21 22 23 25 53 80 110 135 139 443 445 1433 3306 3389 4444 5900 6379 8080 27017)
    while IFS= read -r linea; do
        puerto=$(echo "$linea" | grep -oE '\.\d+$' | tr -d '.')
        for pr in "${puertos_riesgo[@]}"; do
            if [ "$puerto" = "$pr" ]; then
                log "  $linea  <-- REVISAR"
                continue 2
            fi
        done
        log "  $linea"
    done < <(netstat -an | grep LISTEN)

    titulo "CONEXIONES ACTIVAS A INTERNET"
    netstat -an | grep ESTABLISHED | while IFS= read -r linea; do
        log "  $linea"
    done

    titulo "FIREWALL"
    estado=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
    log "$estado"

    titulo "USUARIOS DEL SISTEMA"
    dscl . list /Users | grep -v '^_' | while read -r usuario; do
        log "  $usuario"
    done

    titulo "ACTUALIZACIONES PENDIENTES"
    softwareupdate -l 2>&1 | grep -E "\*|No new" | while IFS= read -r linea; do
        log "  $linea"
    done

    titulo "APPS EN ARRANQUE AUTOMATICO"
    ls ~/Library/LaunchAgents/ 2>/dev/null | while IFS= read -r linea; do
        log "  $linea"
    done
fi

# 2. LIMPIAR TEMPORALES
if preguntar "Limpiar archivos temporales?"; then
    titulo "LIMPIEZA DE TEMPORALES"
    rutas=("$TMPDIR" "$HOME/Library/Caches" "/Library/Caches")
    total=0
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
    df -h | grep -E "^/dev" | while IFS= read -r linea; do
        log "  $linea"
    done
fi

# 4. CAMARA Y MICROFONO
if preguntar "Ver apps con acceso a camara y microfono?"; then
    titulo "ACCESO A CAMARA Y MICROFONO"
    log "  Abriendo preferencias de privacidad..."
    log "  Ve a: Sistema > Privacidad y seguridad > Camara / Microfono"
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
fi

# 5. TOP PROCESOS
if preguntar "Ver top procesos por CPU y RAM?"; then
    titulo "TOP 10 PROCESOS POR CPU"
    ps aux --sort=-%cpu 2>/dev/null | head -11 | tail -10 | while IFS= read -r linea; do
        log "  $linea"
    done
    titulo "TOP 10 PROCESOS POR RAM"
    ps aux --sort=-%mem 2>/dev/null | head -11 | tail -10 | while IFS= read -r linea; do
        log "  $linea"
    done
fi

# 6. ERRORES DEL SISTEMA
if preguntar "Ver errores recientes del sistema?"; then
    titulo "ERRORES RECIENTES (ultimas 24 horas)"
    log "$(log show --predicate 'eventMessage contains "error"' --last 24h 2>/dev/null | head -20)"
fi

# 7. INFORMACION DEL SISTEMA
if preguntar "Ver informacion general del sistema?"; then
    titulo "INFORMACION DEL SISTEMA"
    log "Modelo: $(system_profiler SPHardwareDataType | grep 'Model Name' | awk -F': ' '{print $2}')"
    log "Procesador: $(system_profiler SPHardwareDataType | grep 'Chip\|Processor Name' | awk -F': ' '{print $2}' | head -1)"
    log "RAM: $(system_profiler SPHardwareDataType | grep 'Memory' | awk -F': ' '{print $2}')"
    log "macOS: $(sw_vers -productName) $(sw_vers -productVersion)"
    log "Nombre del equipo: $(hostname)"
    log "Uptime: $(uptime | awk '{print $3,$4}' | tr -d ',')"
fi

echo ""
banner
echo "  Gracias por usar AztekIllerTech"
echo "  Reporte guardado en: $LOG"
echo "  aztekillertech.net"
separador
echo ""
