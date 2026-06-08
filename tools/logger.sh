#!/bin/bash
# OffSec Assistant — Logger de sesion con control DLP
# Se ejecuta automaticamente despues de cada comando Bash via hook de Claude Code.
# El output que se escribe al log ya esta sanitizado: IPs, hostnames y credenciales
# reales son reemplazados por tokens antes de persistir en disco.

set -euo pipefail

# Resolver ruta base del proyecto (funciona en host y en Docker)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFSEC_HOME="${OFFSEC_HOME:-$(dirname "$SCRIPT_DIR")}"

LOGS_DIR="$OFFSEC_HOME/logs"
mkdir -p "$LOGS_DIR"

LOG_FILE="$LOGS_DIR/session_$(date +%Y-%m-%d).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DLP_SANITIZER="$OFFSEC_HOME/tools/sanitizer.py"

# Capturar el JSON del hook antes de hacer cualquier otra cosa
INPUT=$(cat)

# ── Extraer CMD y OUTPUT del JSON del hook ───────────────────────────────────
CMD=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', 'N/A'))
except Exception:
    print('N/A')
" 2>/dev/null)

# Truncar OUTPUT a 2000 chars antes de sanitizar (evita trabajo innecesario)
OUTPUT=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    out = str(data.get('tool_response', {}).get('output', ''))
    print(out[:2000])
except Exception:
    print('N/A')
" 2>/dev/null)

# ── DLP: detectar engagement activo y sanitizar ──────────────────────────────
# Tomar el directorio de engagement mas recientemente modificado que tenga dlp-map.json
ACTIVE_ENGAGEMENT=""
if [ -d "$OFFSEC_HOME/findings" ]; then
    # ls -dt ordena por fecha de modificacion descendente (mas reciente primero)
    while IFS= read -r dir; do
        if [ -f "$dir/dlp-map.json" ]; then
            ACTIVE_ENGAGEMENT="$dir"
            break
        fi
    done < <(ls -dt "$OFFSEC_HOME/findings"/????-??-??_* 2>/dev/null)
fi

DLP_ACTIVE=false
if [ -n "$ACTIVE_ENGAGEMENT" ] && command -v python3 &>/dev/null && [ -f "$DLP_SANITIZER" ]; then
    CMD_SAFE=$(printf '%s' "$CMD" \
        | python3 "$DLP_SANITIZER" "$ACTIVE_ENGAGEMENT" 2>/dev/null) \
        && DLP_ACTIVE=true || CMD_SAFE="$CMD"

    OUTPUT_SAFE=$(printf '%s' "$OUTPUT" \
        | python3 "$DLP_SANITIZER" "$ACTIVE_ENGAGEMENT" 2>/dev/null) \
        || OUTPUT_SAFE="$OUTPUT"
else
    CMD_SAFE="$CMD"
    OUTPUT_SAFE="$OUTPUT"
fi

# ── Escribir entrada al log de sesion ────────────────────────────────────────
{
    echo "[$TIMESTAMP]"
    if $DLP_ACTIVE; then
        echo "DLP: $(basename "$ACTIVE_ENGAGEMENT")"
    fi
    echo "CMD: $CMD_SAFE"
    echo "OUT: $OUTPUT_SAFE"
    echo "---"
} >> "$LOG_FILE"
