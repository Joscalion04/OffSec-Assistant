#!/bin/bash
# OffSec Assistant — Motor de ejecución autónoma con live feed
# Uso: auto-runner.sh <engagement> <fase> <target>

ENGAGEMENT="$1"
FASE="$2"
TARGET="$3"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
DATE=$(date +%Y-%m-%d)

OFFSEC_HOME="/home/joseph/Documents/OffSec/OffSec-Assistant"
ENGAGEMENT_DIR=$(find "$OFFSEC_HOME/findings" -maxdepth 1 -type d -name "*${ENGAGEMENT}*" | head -1)
LIVEFEED_DIR="$OFFSEC_HOME/logs/livefeed"
LIVEFEED_FILE="$LIVEFEED_DIR/${DATE}_${ENGAGEMENT}_${FASE}.log"

mkdir -p "$LIVEFEED_DIR"

# Función principal de logging — terminal + archivo simultáneo
log() {
    local LEVEL="$1"
    local MSG="$2"
    local TIME=$(date '+%H:%M:%S')

    case "$LEVEL" in
        "START")    ICON="🔍" ; COLOR="\033[0;36m"  ;;  # cyan
        "DONE")     ICON="✅" ; COLOR="\033[0;32m"  ;;  # verde
        "FIND")     ICON="⚠️ " ; COLOR="\033[0;33m"  ;;  # amarillo
        "CRITICAL") ICON="🔴" ; COLOR="\033[0;31m"  ;;  # rojo
        "THINK")    ICON="🧠" ; COLOR="\033[0;35m"  ;;  # magenta
        "SKIP")     ICON="⏭️ " ; COLOR="\033[0;37m"  ;;  # gris
        "PHASE")    ICON="📍" ; COLOR="\033[1;34m"  ;;  # azul bold
        "PLAN")     ICON="📋" ; COLOR="\033[1;37m"  ;;  # blanco bold
        "CONFIRM")  ICON="🛑" ; COLOR="\033[1;31m"  ;;  # rojo bold
        "SUMMARY")  ICON="📊" ; COLOR="\033[1;32m"  ;;  # verde bold
        *)          ICON="ℹ️ " ; COLOR="\033[0m"     ;;
    esac

    RESET="\033[0m"

    # Terminal con color
    echo -e "${COLOR}[${TIME}] ${ICON} ${LEVEL}\t${MSG}${RESET}"

    # Archivo sin códigos de color
    echo "[${TIME}] ${ICON} ${LEVEL}	${MSG}" >> "$LIVEFEED_FILE"
}

# Ejecuta un comando, loguea inicio/fin/output
run_cmd() {
    local DESC="$1"
    local CMD="$2"
    local OUTFILE="$3"

    log "START" "$DESC"
    log "START" "CMD: $CMD"

    if [ -n "$OUTFILE" ]; then
        eval "$CMD" > "$OUTFILE" 2>&1
    else
        eval "$CMD" 2>&1
    fi

    local EXIT=$?
    if [ $EXIT -eq 0 ]; then
        log "DONE" "$DESC completado"
    else
        log "FIND" "$DESC terminó con código $EXIT — revisar output"
    fi
    return $EXIT
}

export -f log
export -f run_cmd
export LIVEFEED_FILE
export ENGAGEMENT_DIR

echo "$LIVEFEED_FILE"
