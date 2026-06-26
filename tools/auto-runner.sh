#!/bin/bash
# OffSec Assistant — Motor de ejecucion autonoma con live feed
# Uso: auto-runner.sh <engagement> <fase> <target>

ENGAGEMENT="$1"
FASE="$2"
TARGET="$3"
export TARGET
DATE=$(date +%Y-%m-%d)

# Resolver ruta base: respeta OFFSEC_HOME si ya esta definida (Docker la inyecta),
# si no, deriva la ruta desde la ubicacion del propio script (funciona en host y CI)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFSEC_HOME="${OFFSEC_HOME:-$(dirname "$SCRIPT_DIR")}"
ENGAGEMENT_DIR=$(find "$OFFSEC_HOME/findings" -maxdepth 1 -type d -name "*${ENGAGEMENT}*" | head -1)
LIVEFEED_DIR="$OFFSEC_HOME/logs/livefeed"
LIVEFEED_FILE="$LIVEFEED_DIR/${DATE}_${ENGAGEMENT}_${FASE}.log"
DLP_SANITIZER="$OFFSEC_HOME/tools/sanitizer.py"

mkdir -p "$LIVEFEED_DIR"

# ── DLP: inicializar mapa desde scope.md al arrancar ─────────────────────────
# El mapa se crea una sola vez por engagement; si ya existe, no hace nada nuevo
if command -v python3 &>/dev/null && [ -f "$DLP_SANITIZER" ] && [ -n "$ENGAGEMENT_DIR" ]; then
    python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" --init 2>/dev/null
fi

# ── DLP: sanitizar texto antes de que llegue al agente ───────────────────────
# Si el sanitizador no está disponible, devuelve el texto sin cambios (degradacion suave)
sanitize_log() {
    local text="$1"
    if command -v python3 &>/dev/null && [ -f "$DLP_SANITIZER" ] && [ -n "$ENGAGEMENT_DIR" ]; then
        printf '%s' "$text" | python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" 2>/dev/null
    else
        printf '%s' "$text"
    fi
}

# ── Logging — terminal con color + archivo sin codigos ANSI ──────────────────
log() {
    local LEVEL="$1"
    local MSG="$2"
    local TIME
    TIME=$(date '+%H:%M:%S')

    case "$LEVEL" in
        "START")    ICON="[START]" ; COLOR="\033[0;36m"  ;;
        "DONE")     ICON="[DONE] " ; COLOR="\033[0;32m"  ;;
        "FIND")     ICON="[FIND] " ; COLOR="\033[0;33m"  ;;
        "CRITICAL") ICON="[CRIT] " ; COLOR="\033[0;31m"  ;;
        "THINK")    ICON="[THINK]" ; COLOR="\033[0;35m"  ;;
        "SKIP")     ICON="[SKIP] " ; COLOR="\033[0;37m"  ;;
        "PHASE")    ICON="[PHASE]" ; COLOR="\033[1;34m"  ;;
        "PLAN")     ICON="[PLAN] " ; COLOR="\033[1;37m"  ;;
        "CONFIRM")  ICON="[CONF] " ; COLOR="\033[1;31m"  ;;
        "SUMMARY")  ICON="[SUM]  " ; COLOR="\033[1;32m"  ;;
        *)          ICON="[INFO] " ; COLOR="\033[0m"      ;;
    esac

    RESET="\033[0m"

    # DLP: sanitizar el mensaje antes de escribirlo al livefeed
    # Los niveles PHASE y PLAN generalmente no contienen datos sensibles,
    # pero se sanitizan igual por consistencia
    local SAFE_MSG
    SAFE_MSG=$(sanitize_log "$MSG")

    # Terminal con color (dato sanitizado)
    echo -e "${COLOR}[${TIME}] ${ICON} ${LEVEL}\t${SAFE_MSG}${RESET}"

    # Archivo de livefeed sin codigos ANSI (dato sanitizado)
    echo "[${TIME}] ${ICON} ${LEVEL}	${SAFE_MSG}" >> "$LIVEFEED_FILE"
}

# ── Ejecucion de comandos con logging sanitizado ──────────────────────────────
run_cmd() {
    local DESC="$1"
    local CMD="$2"
    local OUTFILE="$3"

    log "START" "$DESC"

    # DLP: el comando puede contener IPs/hostnames reales — sanitizar para el log
    local SAFE_CMD
    SAFE_CMD=$(sanitize_log "$CMD")
    log "START" "CMD: $SAFE_CMD"

    # La ejecucion real usa los valores originales (el sanitizador no los altera)
    if [ -n "$OUTFILE" ]; then
        eval "$CMD" > "$OUTFILE" 2>&1
    else
        eval "$CMD" 2>&1
    fi

    local EXIT=$?
    if [ $EXIT -eq 0 ]; then
        log "DONE" "$DESC completado"
    else
        log "FIND" "$DESC termino con codigo $EXIT — revisar output"
    fi
    return $EXIT
}

export -f log
export -f run_cmd
export -f sanitize_log
export LIVEFEED_FILE
export ENGAGEMENT_DIR
export DLP_SANITIZER
export OFFSEC_HOME

echo "$LIVEFEED_FILE"
