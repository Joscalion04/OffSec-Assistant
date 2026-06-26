#!/bin/bash
# OffSec Assistant — Librería de helpers compartidos
# Sourcea este archivo al inicio de cada script: source "$(dirname "$0")/lib.sh"

# ── Exit codes estándar ───────────────────────────────────────────────────────
# shellcheck disable=SC2034  # Usados por scripts que sourcean esta librería
readonly EXIT_OK=0
readonly EXIT_ERR=1
readonly EXIT_SCOPE=2
readonly EXIT_TOOL=3
readonly EXIT_ENGAGEMENT=4
readonly EXIT_INTERRUPTED=130

# ── Colores ───────────────────────────────────────────────────────────────────
_LIB_RED='\033[0;31m'
_LIB_YEL='\033[0;33m'
_LIB_CYN='\033[0;36m'
_LIB_RST='\033[0m'

# ── die: error fatal con código de salida ─────────────────────────────────────
# Uso: die <exit_code> "mensaje"
die() {
    local code="${1:-$EXIT_ERR}"
    local msg="${2:-Error desconocido}"
    echo -e "${_LIB_RED}[ERROR]${_LIB_RST} ${msg}" >&2
    exit "$code"
}

# ── warn: advertencia no fatal ────────────────────────────────────────────────
warn() {
    echo -e "${_LIB_YEL}[WARN]${_LIB_RST} $1" >&2
}

# ── info: mensaje informativo ─────────────────────────────────────────────────
info() {
    echo -e "${_LIB_CYN}[INFO]${_LIB_RST} $1"
}

# ── require_tool: abortar si una herramienta no está instalada ────────────────
# Uso: require_tool <herramienta> ["hint de instalación"]
require_tool() {
    local tool="$1"
    local hint="${2:-}"
    if ! command -v "$tool" &>/dev/null; then
        local msg="Herramienta requerida no encontrada: ${tool}"
        [ -n "$hint" ] && msg="${msg} — ${hint}"
        die "$EXIT_TOOL" "$msg"
    fi
}

# ── check_tool: verificar sin abortar (retorna 0 si existe, 1 si no) ─────────
check_tool() {
    command -v "$1" &>/dev/null
}

# ── require_engagement: resolver y validar directorio del engagement ──────────
# Uso: ENGAGEMENT_DIR=$(require_engagement "<nombre>" ["<offsec_home>"])
# Sale con EXIT_ENGAGEMENT si no se encuentra. Imprime el path si existe.
require_engagement() {
    local engagement="$1"
    local home="${2:-${OFFSEC_HOME:-$(pwd)}}"
    local dir
    dir=$(find "$home/findings" -maxdepth 1 -type d -name "*${engagement}*" 2>/dev/null | head -1)
    if [ -z "$dir" ]; then
        die "$EXIT_ENGAGEMENT" \
            "Engagement '${engagement}' no encontrado en ${home}/findings/"
    fi
    echo "$dir"
}

# ── require_args: validar número mínimo de argumentos posicionales ────────────
# Uso: require_args <n_minimo> "uso: script.sh <arg1> <arg2>" "$@"
require_args() {
    local count="$1"
    local usage="$2"
    shift 2
    if [ "$#" -lt "$count" ]; then
        die "$EXIT_ERR" "Argumentos insuficientes. Uso: ${usage}"
    fi
}
