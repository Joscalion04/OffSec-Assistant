#!/bin/bash
# OffSec Assistant — Logger de sesión
# Se ejecuta automáticamente después de cada comando Bash via hook

LOGS_DIR="/home/joseph/Documents/OffSec/OffSec-Assistant/logs"
mkdir -p "$LOGS_DIR"

LOG_FILE="$LOGS_DIR/session_$(date +%Y-%m-%d).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Lee el input del hook (Claude Code pasa JSON por stdin)
INPUT=$(cat)

# Extrae el comando ejecutado
CMD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    cmd = data.get('tool_input', {}).get('command', 'N/A')
    print(cmd)
except:
    print('N/A')
" 2>/dev/null)

# Extrae el output (primeros 500 chars para no inflar el log)
OUTPUT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    out = data.get('tool_response', {}).get('output', '')
    print(str(out)[:500])
except:
    print('N/A')
" 2>/dev/null)

# Escribe al log
cat >> "$LOG_FILE" << LOGENTRY
[$TIMESTAMP]
CMD: $CMD
OUT: $OUTPUT
---
LOGENTRY

